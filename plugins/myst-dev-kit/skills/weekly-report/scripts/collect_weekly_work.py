#!/usr/bin/env python3
"""Read-only VCS-agnostic weekly work collector for Perforce and Git repositories."""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from weekly_common import compute_window, is_same_or_subpath, parse_dt


def parse_offset_str(offset_str: str) -> timezone:
    m = re.match(r"^([+-])(\d{2}):?(\d{2})$", (offset_str or "").strip())
    if not m:
        return timezone.utc
    sign = -1 if m.group(1) == "-" else 1
    hours = int(m.group(2))
    mins = int(m.group(3))
    return timezone(timedelta(minutes=sign * (hours * 60 + mins)))


def run_cmd(cmd: list[str], cwd: str | None = None, timeout: int = 60) -> tuple[int, str, str]:
    env = dict(os.environ, GIT_TERMINAL_PROMPT="0", GIT_OPTIONAL_LOCKS="0")
    proc = subprocess.run(
        cmd,
        cwd=cwd,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
    )
    return proc.returncode, proc.stdout, proc.stderr


def run_cmd_checked(cmd: list[str], cwd: str | None = None, timeout: int = 60) -> str:
    rc, out, err = run_cmd(cmd, cwd=cwd, timeout=timeout)
    if rc != 0:
        detail = (err or out or "").strip()
        raise RuntimeError(f"Command failed ({rc}): {' '.join(cmd)} — {detail}")
    return out


def probe_perforce(resolved_root: str) -> dict:
    if not shutil.which("p4"):
        return {"available": False, "bound": False, "reason": "p4 CLI not found"}
    rc, out, err = run_cmd(["p4", "info"], cwd=resolved_root, timeout=15)
    if rc != 0:
        return {"available": True, "bound": False, "reason": err.strip() or "p4 info failed"}

    p4_user = None
    client_name = None
    client_root = None
    client_stream = None
    server_tz = timezone.utc
    server_offset_str = "+0000"

    for line in out.splitlines():
        if line.startswith("User name:"):
            p4_user = line.split(":", 1)[1].strip()
        elif line.startswith("Client name:"):
            client_name = line.split(":", 1)[1].strip()
        elif line.startswith("Client root:"):
            client_root = line.split(":", 1)[1].strip()
        elif line.startswith("Client stream:"):
            client_stream = line.split(":", 1)[1].strip()
        elif line.startswith("Server date:"):
            m = re.search(r"\d{4}/\d{2}/\d{2}\s+\d{2}:\d{2}:\d{2}\s+([+-]\d{4})", line)
            if m:
                server_offset_str = m.group(1)
                server_tz = parse_offset_str(server_offset_str)

    bound = bool(
        client_name
        and client_name != "*unknown*"
        and client_root
        and is_same_or_subpath(resolved_root, client_root)
    )

    return {
        "available": True,
        "bound": bound,
        "user": p4_user,
        "client": client_name,
        "client_root": client_root,
        "client_stream": client_stream,
        "server_tz": server_tz,
        "server_offset_str": server_offset_str,
    }


def probe_git(resolved_root: str) -> dict:
    if not shutil.which("git"):
        return {"available": False, "work_tree": False, "has_head": False, "has_remote": False}
    rc, out, _ = run_cmd(["git", "--no-optional-locks", "rev-parse", "--is-inside-work-tree"], cwd=resolved_root, timeout=10)
    if rc != 0 or out.strip() != "true":
        return {"available": True, "work_tree": False, "has_head": False, "has_remote": False}

    rc_head, _, _ = run_cmd(["git", "--no-optional-locks", "rev-parse", "--verify", "HEAD"], cwd=resolved_root, timeout=10)
    has_head = rc_head == 0

    _, rem_out, _ = run_cmd(["git", "--no-optional-locks", "remote"], cwd=resolved_root, timeout=10)
    remotes = [r.strip() for r in rem_out.splitlines() if r.strip()]

    _, top_out, _ = run_cmd(["git", "--no-optional-locks", "rev-parse", "--show-toplevel"], cwd=resolved_root, timeout=10)
    _, br_out, _ = run_cmd(["git", "--no-optional-locks", "rev-parse", "--abbrev-ref", "HEAD"], cwd=resolved_root, timeout=10)

    return {
        "available": True,
        "work_tree": True,
        "has_head": has_head,
        "has_remote": len(remotes) > 0,
        "remotes": remotes,
        "repo_root": top_out.strip() or None,
        "branch": br_out.strip() or None,
    }


def detect_vcs(resolved_root: str, p4_probe: dict, git_probe: dict, requested_vcs: str = "auto") -> str:
    if requested_vcs != "auto":
        if requested_vcs == "p4":
            if not p4_probe.get("available"):
                raise RuntimeError("p4 requested but p4 CLI not found.")
            if not p4_probe.get("bound"):
                raise RuntimeError(
                    f"p4 requested but '{resolved_root}' is not bound to the active Perforce client "
                    f"(client={p4_probe.get('client')}, client_root={p4_probe.get('client_root')})."
                )
        if requested_vcs == "git" and not git_probe.get("work_tree"):
            raise RuntimeError(f"git requested but '{resolved_root}' is not a Git work tree.")
        return requested_vcs

    p4_bound = bool(p4_probe.get("bound"))
    git_tree = bool(git_probe.get("work_tree"))
    git_head = bool(git_probe.get("has_head"))

    if p4_bound and not git_head:
        return "p4"
    if p4_bound and git_head:
        raise RuntimeError(
            f"Dual-VCS workspace detected at '{resolved_root}' (both active Perforce client and initialized Git HEAD). "
            "Resolve ownership via project instructions and pass --vcs p4 or --vcs git explicitly."
        )
    if git_tree:
        return "git"
    raise RuntimeError(
        f"No active Perforce or Git repository detected at '{resolved_root}' "
        f"(p4 bound={p4_bound}, git work_tree={git_tree})."
    )


def parse_p4_describe(text: str, server_tz: timezone, local_tz) -> dict:
    lines = text.splitlines()
    header = lines[0] if lines else ""
    local_dto = None
    local_time_str = None
    m_time = re.search(r"on (\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})", header)
    if m_time:
        dt = datetime.strptime(m_time.group(1), "%Y/%m/%d %H:%M:%S").replace(tzinfo=server_tz)
        local_dto = dt.astimezone(local_tz)
        local_time_str = local_dto.strftime("%Y-%m-%d %H:%M")

    affected_idx = -1
    for i, line in enumerate(lines):
        if re.match(r"^(Affected|Shelved) files \.\.\.", line):
            affected_idx = i
            break

    desc_end = affected_idx if affected_idx > 0 else len(lines)
    trimmed_desc = [re.sub(r"^\t", "", lines[i]) for i in range(1, desc_end)]

    title = ""
    title_idx = -1
    for i, line in enumerate(trimmed_desc):
        cand = line.strip()
        if cand:
            title = cand
            title_idx = i
            break

    tags = []
    rest = title
    while True:
        m_tag = re.match(r"^\[([^\]]+)\]\s*(.*)$", rest)
        if not m_tag:
            break
        tags.append(m_tag.group(1))
        rest = m_tag.group(2)

    ticket = None
    for line in trimmed_desc:
        m_t = re.match(r"^\s*Ticket:\s*(.+)$", line)
        if m_t:
            ticket = m_t.group(1).strip()
            break

    summary_lines = []
    in_summary = False
    for line in trimmed_desc:
        if re.match(r"^\s*(##\s*Summary|Summary:|##\s*What)\s*$", line):
            in_summary = True
            continue
        if in_summary:
            if re.match(r"^\s*(##\s+|Ticket:|Verification:|Review Record:|Key Files:|Affected files|Shelved files)", line):
                break
            t = line.strip()
            if t:
                summary_lines.append(t)

    if not summary_lines and title_idx >= 0:
        for line in trimmed_desc[title_idx + 1 :]:
            t = line.strip()
            if not t or re.match(r"^(Ticket:|Workflow:|Verification:|Review Record:|##\s+)", t):
                if t.startswith("## ") and summary_lines:
                    break
                continue
            summary_lines.append(t)
            if len(summary_lines) >= 2:
                break

    summary = re.sub(r"\s+", " ", " ".join(summary_lines)).strip()
    if len(summary) > 360:
        summary = summary[:357].rstrip() + "..."

    verify_lines = []
    in_verify = False
    for line in trimmed_desc:
        if re.match(r"^\s*(##\s*(Verification|Evidence|Review Record)|Verification:)\s*$", line):
            in_verify = True
            continue
        if in_verify:
            if re.match(r"^\s*(##\s+|Affected files|Shelved files)", line):
                break
            t = line.strip()
            if t:
                verify_lines.append(t)
    verification = re.sub(r"\s+", " ", " ".join(verify_lines)).strip()
    if len(verification) > 300:
        verification = verification[:297].rstrip() + "..."

    depot_files = []
    if affected_idx >= 0:
        for line in lines[affected_idx + 1 :]:
            m_f = re.match(r"^\.\.\.\s+(//[^#]+)#\d+", line)
            if m_f:
                depot_files.append(m_f.group(1).strip())

    return {
        "local_time": local_time_str,
        "local_dto": local_dto,
        "title": title,
        "tags": tags,
        "ticket": ticket,
        "summary": summary,
        "verification": verification,
        "file_count": len(depot_files),
        "sample_files": depot_files[:5],
    }


def collect_perforce(
    p4_probe: dict,
    resolved_root: str,
    project_name: str,
    user_override: str,
    cutoff_local: datetime,
    now_local: datetime,
    git_probe: dict,
) -> dict:
    local_tz = now_local.tzinfo
    target_user = user_override or p4_probe.get("user")
    if not target_user:
        raise RuntimeError("Could not determine Perforce user from --user or p4 info.")

    client_name = p4_probe.get("client")
    if not client_name:
        raise RuntimeError("Could not determine Perforce client from p4 info.")
    client_root = p4_probe.get("client_root")
    client_stream = p4_probe.get("client_stream")

    server_tz = p4_probe["server_tz"]
    cutoff_server = cutoff_local.astimezone(server_tz)
    end_server = now_local.astimezone(server_tz)
    server_cutoff_str = cutoff_server.strftime("%Y/%m/%d:%H:%M:%S")
    server_end_str = end_server.strftime("%Y/%m/%d:%H:%M:%S")

    # Scope submitted changes strictly to the target stream/client and captured [cutoff, end] bounds.
    scope_prefix = f"{client_stream.rstrip('/')}/..." if client_stream else f"//{client_name}/..."
    sub_out = run_cmd_checked(
        ["p4", "-ztag", "-F", "%change%", "changes", "-u", target_user, "-s", "submitted", f"{scope_prefix}@{server_cutoff_str},@{server_end_str}"],
        cwd=resolved_root,
    )
    submitted_ids = [x.strip() for x in sub_out.splitlines() if x.strip().isdigit()]

    completed_list = []
    reconciled_ids = []
    for cl in submitted_ids:
        desc_out = run_cmd_checked(["p4", "describe", "-s", cl], cwd=resolved_root)
        parsed = parse_p4_describe(desc_out, server_tz, local_tz)
        if parsed["local_dto"] is not None and (parsed["local_dto"] < cutoff_local or parsed["local_dto"] > now_local):
            continue
        reconciled_ids.append(cl)
        completed_list.append(
            {
                "id": cl,
                "local_time": parsed["local_time"],
                "title": parsed["title"],
                "tags": parsed["tags"],
                "ticket": parsed["ticket"],
                "summary": parsed["summary"],
                "file_count": parsed["file_count"],
                "sample_files": parsed["sample_files"],
            }
        )

    open_all_out = run_cmd_checked(
        ["p4", "-ztag", "-F", "%change%\t%action%\t%depotFile%\t%clientFile%", "opened"],
        cwd=resolved_root,
    )
    opened_by_change: dict[str, list[dict]] = {}
    client_prefix = f"//{client_name}/"

    for row in open_all_out.splitlines():
        if not row:
            continue
        parts = row.split("\t", 3)
        if len(parts) < 4:
            continue
        chg_key, action, depot_file, client_file = (p.strip() for p in parts)

        local_path = None
        if client_root and client_file.lower().startswith(client_prefix.lower()):
            rel = client_file[len(client_prefix) :]
            local_path = os.path.join(client_root, *rel.split("/"))
        else:
            rc_w, w_out, _ = run_cmd(["p4", "-ztag", "-F", "%path%", "where", depot_file], cwd=resolved_root)
            if rc_w == 0 and w_out.strip():
                local_path = w_out.splitlines()[0].strip()

        mtime_dto = None
        mtime_str = None
        touched = False
        if local_path and os.path.exists(local_path):
            mtime_dto = datetime.fromtimestamp(os.path.getmtime(local_path), tz=local_tz)
            mtime_str = mtime_dto.strftime("%Y-%m-%d %H:%M")
            if cutoff_local <= mtime_dto <= now_local:
                touched = True

        opened_by_change.setdefault(chg_key, []).append(
            {
                "action": action,
                "depot_file": depot_file,
                "mtime_dto": mtime_dto,
                "mtime": mtime_str,
                "touched": touched,
            }
        )

    # Scope pending changes strictly to the target client workspace.
    pend_out = run_cmd_checked(
        ["p4", "-ztag", "-F", "%change%", "changes", "-u", target_user, "-c", client_name, "-s", "pending"],
        cwd=resolved_root,
    )
    pending_ids = [x.strip() for x in pend_out.splitlines() if x.strip().isdigit()]

    wip_active = []
    wip_older = []
    for cl in pending_ids:
        desc_out = run_cmd_checked(["p4", "describe", "-s", cl], cwd=resolved_root)
        parsed = parse_p4_describe(desc_out, server_tz, local_tz)

        sh_out = run_cmd_checked(["p4", "describe", "-s", "-S", cl], cwd=resolved_root)
        shelved_files = []
        in_shelved = False
        for sl in sh_out.splitlines():
            if sl.startswith("Shelved files ..."):
                in_shelved = True
                continue
            if in_shelved:
                m_sf = re.match(r"^\.\.\.\s+(//[^#]+)#\d+", sl)
                if m_sf:
                    shelved_files.append(m_sf.group(1).strip())

        opened_entries = opened_by_change.get(cl, [])
        latest_mtime = None
        touched_count = 0
        for entry in opened_entries:
            if entry["touched"]:
                touched_count += 1
            if entry["mtime_dto"] and (latest_mtime is None or entry["mtime_dto"] > latest_mtime):
                latest_mtime = entry["mtime_dto"]

        cl_in_win = parsed["local_dto"] is not None and (cutoff_local <= parsed["local_dto"] <= now_local)
        files_in_win = touched_count > 0
        touched_in_win = cl_in_win or files_in_win

        last_touched = parsed["local_dto"]
        if latest_mtime is not None and (last_touched is None or latest_mtime > last_touched):
            last_touched = latest_mtime

        item = {
            "id": cl,
            "kind": "pending_cl",
            "cl_local_time": parsed["local_time"],
            "latest_file_mtime": latest_mtime.strftime("%Y-%m-%d %H:%M") if latest_mtime else None,
            "last_touched_time": last_touched.strftime("%Y-%m-%d %H:%M") if last_touched else parsed["local_time"],
            "title": parsed["title"],
            "tags": parsed["tags"],
            "ticket": parsed["ticket"],
            "summary": parsed["summary"],
            "verification": parsed["verification"],
            "file_count": parsed["file_count"],
            "touched_files_count": touched_count,
            "shelved_count": len(shelved_files),
            "sample_files": parsed["sample_files"] or shelved_files[:5],
        }
        if touched_in_win:
            wip_active.append(item)
        else:
            wip_older.append(item)

    default_entries = opened_by_change.get("default", [])
    default_touched = []
    default_latest = None
    for entry in default_entries:
        if entry["mtime_dto"] and (default_latest is None or entry["mtime_dto"] > default_latest):
            default_latest = entry["mtime_dto"]
        if entry["touched"]:
            default_touched.append(
                {
                    "action": entry["action"],
                    "depot_file": entry["depot_file"],
                    "local_time": entry["mtime"],
                }
            )

    wip_active.sort(key=lambda x: x["last_touched_time"] or "", reverse=True)

    return {
        "meta": {
            "vcs": "p4",
            "complete": True,
            "project_name": project_name,
            "workspace_root": resolved_root,
            "user": target_user,
            "branch_or_stream": client_stream,
            "window_start_local": cutoff_local.strftime("%Y-%m-%d %H:%M"),
            "window_end_local": now_local.strftime("%Y-%m-%d %H:%M"),
            "window_start_iso": cutoff_local.isoformat(timespec="seconds"),
            "window_end_iso": now_local.isoformat(timespec="seconds"),
            "vcs_details": {
                "client": client_name,
                "scope_filespec": scope_prefix,
                "server_offset": p4_probe.get("server_offset_str"),
                "window_start_server": server_cutoff_str,
                "window_end_server": server_end_str,
                "other_vcs_detected": "git (secondary/uninitialized)" if git_probe.get("work_tree") else None,
            },
        },
        "counts": {
            "completed": len(completed_list),
            "completed_ids_returned": len(reconciled_ids),
            "wip_active": len(wip_active),
            "wip_older": len(wip_older),
            "uncommitted_or_default": len(default_entries),
        },
        "completed": completed_list,
        "wip_active": wip_active,
        "wip_older": wip_older,
        "uncommitted_or_default": {
            "kind": "default_cl",
            "opened_count": len(default_entries),
            "touched_in_window_count": len(default_touched),
            "latest_file_mtime": default_latest.strftime("%Y-%m-%d %H:%M") if default_latest else None,
            "touched_files": default_touched,
            "sample_files": [e["depot_file"] for e in default_entries[:8]],
        },
    }


def resolve_git_default_ref(resolved_root: str, has_head: bool) -> str | None:
    if not has_head:
        return None
    rc, sym_out, _ = run_cmd(["git", "--no-optional-locks", "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD"], cwd=resolved_root)
    if rc == 0 and sym_out.strip():
        return re.sub(r"^refs/remotes/", "", sym_out.strip())
    for cand in ("origin/main", "origin/master"):
        rc, _, _ = run_cmd(["git", "--no-optional-locks", "show-ref", "--verify", "--quiet", f"refs/remotes/{cand}"], cwd=resolved_root)
        if rc == 0:
            return cand
    for cand in ("main", "master"):
        rc, _, _ = run_cmd(["git", "--no-optional-locks", "show-ref", "--verify", "--quiet", f"refs/heads/{cand}"], cwd=resolved_root)
        if rc == 0:
            return cand
    return "HEAD"


def collect_git(
    git_probe: dict,
    resolved_root: str,
    project_name: str,
    user_override: str,
    cutoff_local: datetime,
    now_local: datetime,
    p4_probe: dict,
) -> dict:
    local_tz = now_local.tzinfo
    repo_root = git_probe.get("repo_root") or resolved_root
    _, u_name, _ = run_cmd(["git", "--no-optional-locks", "config", "user.name"], cwd=resolved_root)
    _, u_email, _ = run_cmd(["git", "--no-optional-locks", "config", "user.email"], cwd=resolved_root)
    u_name = u_name.strip()
    u_email = u_email.strip()

    author_filter = user_override or u_email or u_name
    display_user = user_override or (f"{u_name} <{u_email}>" if (u_name and u_email) else (u_name or u_email or "unknown"))
    default_ref = resolve_git_default_ref(resolved_root, bool(git_probe.get("has_head")))

    completed_list = []
    expected_hashes: list[str] = []
    parsed_hashes: list[str] = []
    if git_probe.get("has_head") and default_ref:
        pinned_ref = run_cmd_checked(
            ["git", "--no-optional-locks", "rev-parse", "--verify", f"{default_ref}^{{commit}}"],
            cwd=resolved_root,
        ).strip()
        since_iso = cutoff_local.isoformat(timespec="seconds")
        until_iso = now_local.isoformat(timespec="seconds")
        rev_cmd = [
            "git",
            "--no-optional-locks",
            "rev-list",
            pinned_ref,
            "--no-merges",
            f"--since={since_iso}",
            f"--until={until_iso}",
        ]
        cmd = [
            "git",
            "--no-optional-locks",
            "log",
            pinned_ref,
            "--no-merges",
            f"--since={since_iso}",
            f"--until={until_iso}",
            "--date=iso-strict",
            "--pretty=format:%H%x1f%h%x1f%ad%x1f%s%x1f%b%x1e",
        ]
        if author_filter:
            rev_cmd.append(f"--author={author_filter}")
            cmd.append(f"--author={author_filter}")

        rev_out = run_cmd_checked(rev_cmd, cwd=resolved_root)
        expected_hashes = [h.strip() for h in rev_out.splitlines() if h.strip()]

        log_out = run_cmd_checked(cmd, cwd=resolved_root)
        for rec in log_out.split("\x1e"):
            rec_clean = rec.strip("\r\n")
            if not rec_clean:
                continue
            fields = rec_clean.split("\x1f", 4)
            if len(fields) < 4:
                raise RuntimeError(f"Malformed git log record encountered: {rec_clean[:80]!r}")
            full_hash, short_hash, ad_iso, subject = (f.strip() for f in fields[:4])
            if not full_hash or not short_hash or not ad_iso:
                raise RuntimeError(f"Incomplete git log record encountered: {rec_clean[:80]!r}")
            body = fields[4] if len(fields) >= 5 else ""
            commit_dto = parse_dt(ad_iso, local_tz)
            parsed_hashes.append(full_hash)

            tags = []
            m_cc = re.match(r"^([a-zA-Z0-9_-]+)(?:\(([^)]+)\))?:\s*(.+)$", subject)
            if m_cc:
                tags.append(m_cc.group(1))
                if m_cc.group(2):
                    tags.append(m_cc.group(2))
            else:
                rest = subject
                while True:
                    m_b = re.match(r"^\[([^\]]+)\]\s*(.*)$", rest)
                    if not m_b:
                        break
                    tags.append(m_b.group(1))
                    rest = m_b.group(2)

            ticket = None
            m_t = re.search(r"(?m)^\s*(?:Ticket|Closes|Refs):\s*(.+)$", body)
            if m_t:
                ticket = m_t.group(1).strip()
            else:
                m_num = re.search(r"(#\d+)", subject)
                if m_num:
                    ticket = m_num.group(1)

            summary = re.sub(r"\s+", " ", body).strip()
            if len(summary) > 360:
                summary = summary[:357].rstrip() + "..."

            dt_out = run_cmd_checked(
                ["git", "--no-optional-locks", "diff-tree", "--no-commit-id", "--name-only", "-r", full_hash],
                cwd=resolved_root,
            )
            diff_files = [x.strip() for x in dt_out.splitlines() if x.strip()]

            completed_list.append(
                {
                    "id": short_hash,
                    "local_time": commit_dto.strftime("%Y-%m-%d %H:%M"),
                    "title": subject,
                    "tags": tags,
                    "ticket": ticket,
                    "summary": summary,
                    "file_count": len(diff_files),
                    "sample_files": diff_files[:5],
                }
            )

        if parsed_hashes != expected_hashes:
            raise RuntimeError(
                f"Git commit reconciliation mismatch: rev-list returned {len(expected_hashes)} ID(s) "
                f"but log parsed {len(parsed_hashes)} ID(s) with differing commit hashes."
            )

    st_out = run_cmd_checked(
        ["git", "--no-optional-locks", "-c", "core.quotepath=false", "status", "--porcelain=v1"],
        cwd=resolved_root,
    )
    wt_files = []
    wt_touched = []
    wt_latest = None
    for line in st_out.splitlines():
        if len(line) < 4:
            continue
        xy = line[:2].strip()
        path_part = line[3:].strip()
        if " -> " in path_part:
            path_part = path_part.split(" -> ")[-1].strip()
        path_part = path_part.strip('"')
        full_path = os.path.join(repo_root, *path_part.split("/"))

        mtime_dto = None
        mtime_str = None
        touched = False
        if os.path.exists(full_path):
            mtime_dto = datetime.fromtimestamp(os.path.getmtime(full_path), tz=local_tz)
            mtime_str = mtime_dto.strftime("%Y-%m-%d %H:%M")
            if wt_latest is None or mtime_dto > wt_latest:
                wt_latest = mtime_dto
            if cutoff_local <= mtime_dto <= now_local:
                touched = True

        entry = {"status": xy, "path": path_part, "local_time": mtime_str, "touched": touched}
        wt_files.append(entry)
        if touched:
            wt_touched.append(entry)

    wip_active = []
    wip_older = []
    if wt_files:
        wt_item = {
            "id": f"working-tree ({git_probe.get('branch')})",
            "kind": "working_tree",
            "last_touched_time": (wt_latest or now_local).strftime("%Y-%m-%d %H:%M"),
            "title": f"Working tree on '{git_probe.get('branch')}': {len(wt_files)} modified/untracked path(s)",
            "summary": "; ".join(f"{e['status']} {e['path']}" for e in wt_files[:6]),
            "verification": "",
            "file_count": len(wt_files),
            "shelved_count": 0,
            "sample_files": [e["path"] for e in wt_files[:5]],
        }
        if wt_touched:
            wip_active.append(wt_item)
        else:
            wip_older.append(wt_item)

    older_branch_total = 0
    if git_probe.get("has_head") and default_ref:
        ref_out = run_cmd_checked(
            [
                "git",
                "--no-optional-locks",
                "for-each-ref",
                f"--no-merged={default_ref}",
                "--sort=-committerdate",
                "--format=%(refname:short)\t%(committerdate:iso-strict)\t%(authorname)\t%(authoremail)\t%(subject)",
                "refs/heads",
                "refs/remotes/origin",
            ],
            cwd=resolved_root,
        )
        for rl in ref_out.splitlines():
            if not rl:
                continue
            parts = rl.split("\t", 4)
            if len(parts) < 5:
                continue
            ref_name, c_date_iso, a_name, a_email, subj = (p.strip() for p in parts)
            if ref_name in ("origin/HEAD", "origin", default_ref):
                continue

            if author_filter:
                af = author_filter.lower()
                matched = (af in a_email.lower()) or (af in a_name.lower())
                if not matched:
                    own_out = run_cmd_checked(
                        ["git", "--no-optional-locks", "log", "-n", "1", f"--author={author_filter}", f"{default_ref}..{ref_name}", "--pretty=format:%h"],
                        cwd=resolved_root,
                    )
                    matched = bool(own_out.strip())
                if not matched:
                    continue

            ahead_out = run_cmd_checked(["git", "--no-optional-locks", "rev-list", "--count", f"{default_ref}..{ref_name}"], cwd=resolved_root)
            ahead_count = int(ahead_out.strip()) if ahead_out.strip().isdigit() else 0
            if ahead_count <= 0:
                continue

            ref_dto = parse_dt(c_date_iso, local_tz)
            b_item = {
                "id": ref_name,
                "kind": "branch",
                "last_touched_time": ref_dto.strftime("%Y-%m-%d %H:%M"),
                "title": f"{ref_name} (+{ahead_count} ahead of {default_ref}): {subj}",
                "summary": f"Author: {a_name}; latest commit: {subj}",
                "verification": "",
                "file_count": ahead_count,
                "shelved_count": 0,
                "sample_files": [],
            }
            if cutoff_local <= ref_dto <= now_local:
                wip_active.append(b_item)
            else:
                older_branch_total += 1
                if older_branch_total <= 20:
                    wip_older.append(b_item)

    st_list_out = run_cmd_checked(
        ["git", "--no-optional-locks", "stash", "list", "--date=iso-strict", "--pretty=format:%gd%x1f%ad%x1f%gs"],
        cwd=resolved_root,
    )
    stashes_obj = []
    for stl in st_list_out.splitlines():
        if not stl:
            continue
        sp = stl.split("\x1f", 2)
        if len(sp) < 3:
            continue
        s_ref, s_date_iso, s_msg = (p.strip() for p in sp)
        s_dto = parse_dt(s_date_iso, local_tz)
        stashes_obj.append({"ref": s_ref, "local_time": s_dto.strftime("%Y-%m-%d %H:%M"), "message": s_msg})
        s_item = {
            "id": s_ref,
            "kind": "stash",
            "last_touched_time": s_dto.strftime("%Y-%m-%d %H:%M"),
            "title": f"{s_ref}: {s_msg}",
            "summary": s_msg,
            "verification": "",
            "file_count": 0,
            "shelved_count": 1,
            "sample_files": [],
        }
        if cutoff_local <= s_dto <= now_local:
            wip_active.append(s_item)
        else:
            wip_older.append(s_item)

    wip_active.sort(key=lambda x: x["last_touched_time"] or "", reverse=True)

    return {
        "meta": {
            "vcs": "git",
            "complete": True,
            "project_name": project_name,
            "workspace_root": resolved_root,
            "user": display_user,
            "branch_or_stream": git_probe.get("branch"),
            "window_start_local": cutoff_local.strftime("%Y-%m-%d %H:%M"),
            "window_end_local": now_local.strftime("%Y-%m-%d %H:%M"),
            "window_start_iso": cutoff_local.isoformat(timespec="seconds"),
            "window_end_iso": now_local.isoformat(timespec="seconds"),
            "vcs_details": {
                "repo_root": repo_root,
                "default_ref": default_ref,
                "author_filter": author_filter,
                "remotes": git_probe.get("remotes", []),
                "older_unmerged_branches": older_branch_total,
                "other_vcs_detected": "p4 (secondary)" if p4_probe.get("bound") else None,
            },
        },
        "counts": {
            "completed": len(completed_list),
            "completed_ids_returned": len(expected_hashes),
            "wip_active": len(wip_active),
            "wip_older": len(wip_older),
            "uncommitted_or_default": len(wt_files),
        },
        "completed": completed_list,
        "wip_active": wip_active,
        "wip_older": wip_older,
        "uncommitted_or_default": {
            "kind": "working_tree",
            "modified_count": len(wt_files),
            "touched_in_window_count": len(wt_touched),
            "latest_file_mtime": wt_latest.strftime("%Y-%m-%d %H:%M") if wt_latest else None,
            "touched_files": wt_touched[:15],
            "sample_files": [f"{e['status']} {e['path']}" for e in wt_files[:8]],
            "stashes": stashes_obj,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Collect VCS-agnostic weekly completed work and WIP.")
    parser.add_argument("--vcs", choices=("auto", "p4", "git"), default="auto")
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--since", default="")
    parser.add_argument("--until", default="")
    parser.add_argument("--user", default="")
    parser.add_argument("--workspace", default=".")
    parser.add_argument("--compact", action="store_true")
    args = parser.parse_args()

    resolved_root = str(Path(args.workspace).resolve())
    if not os.path.isdir(resolved_root):
        raise SystemExit(f"Workspace does not exist: {resolved_root}")

    project_name = Path(resolved_root).name
    cutoff_local, now_local = compute_window(days=args.days, since=args.since, until=args.until)

    p4_probe = probe_perforce(resolved_root)
    git_probe = probe_git(resolved_root)
    selected_vcs = detect_vcs(resolved_root, p4_probe, git_probe, requested_vcs=args.vcs)

    if selected_vcs == "p4":
        result = collect_perforce(p4_probe, resolved_root, project_name, args.user, cutoff_local, now_local, git_probe)
    else:
        result = collect_git(git_probe, resolved_root, project_name, args.user, cutoff_local, now_local, p4_probe)

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if args.compact:
        print(json.dumps(result, separators=(",", ":"), ensure_ascii=False))
    else:
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
