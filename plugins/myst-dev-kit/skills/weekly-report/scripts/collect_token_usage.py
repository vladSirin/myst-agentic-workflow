#!/usr/bin/env python3
"""Read-only collector for local Antigravity, Codex CLI, and Claude Code token usage & API-equivalent value."""

import argparse
import json
import os
import re
import sqlite3
import sys
from datetime import datetime
from pathlib import Path

from weekly_common import compute_window, is_same_or_subpath, normalize_path, parse_dt


def resolve_pricing_path(explicit_pricing: str, script_dir: Path, home_dir: Path | None = None) -> Path:
    if explicit_pricing:
        return Path(explicit_pricing)
    user_override = (home_dir or Path.home()) / ".myst" / "weekly-report-pricing.json"
    if user_override.is_file():
        return user_override
    return script_dir / "pricing.json"


def load_pricing(pricing_path: Path) -> dict:
    with open(pricing_path, "r", encoding="utf-8") as f:
        return json.load(f)


def match_pricing(model_name: str, pricing: dict) -> dict:
    m = (model_name or "").lower()
    for rule in pricing.get("rules", []):
        pat = (rule.get("pattern") or "").lower()
        if pat and pat in m:
            return rule
    return pricing.get("default", {"label": "Other / Unclassified", "input": 2.0, "cached_input": 0.2, "output": 10.0})


def extract_uris_from_field(raw_val: str) -> list[str]:
    if not raw_val:
        return []
    s = raw_val.strip()
    if s.startswith("["):
        try:
            arr = json.loads(s)
            if isinstance(arr, list):
                return [str(x) for x in arr if x]
        except Exception:
            pass
    hits = re.findall(r'file://[^\s"\'\],]+', s)
    if hits:
        return hits
    return [p.strip() for p in re.split(r"[,;\n]+", s) if p.strip()]


def load_ag_workspace_map(db_path: Path) -> tuple[dict, list[str]]:
    caveats = []
    conv_meta = {}
    if not db_path.is_file():
        return conv_meta, caveats

    con = None
    last_err = ""
    for uri in (f"file:{db_path.as_posix()}?mode=ro", f"file:{db_path.as_posix()}?mode=ro&immutable=1"):
        try:
            con = sqlite3.connect(uri, uri=True, timeout=2.0)
            rows = con.execute(
                "SELECT conversation_id, workspace_uris, parent_conversation_id FROM conversation_summaries"
            ).fetchall()
            for cid, w_raw, pid in rows:
                conv_meta[cid] = {
                    "uris": [normalize_path(u) for u in extract_uris_from_field(w_raw or "")],
                    "parent": (pid or "").strip(),
                }
            break
        except Exception as exc:
            if con is not None:
                try:
                    con.close()
                except Exception:
                    pass
                con = None
            last_err = str(exc)
    else:
        caveats.append(f"Could not read conversation_summaries.db ({last_err}); Antigravity workspace attribution skipped.")

    if con is not None:
        try:
            con.close()
        except Exception:
            pass
    return conv_meta, caveats


def ag_conv_matches_ws(conv_id: str, conv_meta: dict, ws_norm: str) -> tuple[bool, bool]:
    if not ws_norm:
        return False, False
    cur = conv_id
    seen = set()
    has_meta = False
    for _ in range(8):
        if not cur or cur in seen:
            break
        seen.add(cur)
        info = conv_meta.get(cur)
        if not info:
            break
        uris = info.get("uris") or []
        if uris:
            has_meta = True
            if any(is_same_or_subpath(u, ws_norm) for u in uris):
                return True, True
            return False, True
        cur = info.get("parent") or ""
    return False, has_meta


def make_bucket():
    return {
        "sessions_set": set(),
        "turns": 0,
        "uncached_input": 0,
        "cached_input": 0,
        "output": 0,
        "reasoning_output": 0,
        "api_equiv_usd": 0.0,
        "uncached_counterfactual_usd": 0.0,
    }


def add_usage(bucket: dict, session_id: str, turns: int, uncached: int, cached: int, output: int, reasoning: int, rule: dict):
    bucket["sessions_set"].add(session_id)
    bucket["turns"] += turns
    bucket["uncached_input"] += uncached
    bucket["cached_input"] += cached
    bucket["output"] += output
    bucket["reasoning_output"] += reasoning

    r_in = float(rule.get("input", 2.0))
    r_cached = float(rule.get("cached_input", 0.2))
    r_out = float(rule.get("output", 10.0))

    cost = (uncached * r_in + cached * r_cached + output * r_out) / 1_000_000.0
    counterfactual = ((uncached + cached) * r_in + output * r_out) / 1_000_000.0
    bucket["api_equiv_usd"] += cost
    bucket["uncached_counterfactual_usd"] += counterfactual


def finalize_bucket(bucket: dict) -> dict:
    uncached = bucket["uncached_input"]
    cached = bucket["cached_input"]
    total_in = uncached + cached
    output = bucket["output"]
    total_tokens = total_in + output
    cache_hit_pct = round((cached / total_in) * 100.0, 1) if total_in > 0 else 0.0
    cost = bucket["api_equiv_usd"]
    cf = bucket["uncached_counterfactual_usd"]
    return {
        "sessions_or_convs": len(bucket["sessions_set"]),
        "turns": bucket["turns"],
        "uncached_input": uncached,
        "cached_input": cached,
        "total_input": total_in,
        "output": output,
        "reasoning_output": bucket["reasoning_output"],
        "total_tokens": total_tokens,
        "cache_hit_pct": cache_hit_pct,
        "api_equiv_usd": round(cost, 2),
        "uncached_counterfactual_usd": round(cf, 2),
        "cache_savings_usd": round(max(0.0, cf - cost), 2),
    }


class ScopeAggregator:
    def __init__(self, pricing: dict):
        self.pricing = pricing
        self.total = make_bucket()
        self.by_tool = {
            "antigravity": make_bucket(),
            "codex": make_bucket(),
            "claude_code": make_bucket(),
        }
        self.by_tier = {}

    def record(self, tool: str, session_id: str, model: str, turns: int, uncached: int, cached: int, output: int, reasoning: int):
        rule = match_pricing(model, self.pricing)
        label = rule.get("label", "Other / Unclassified")
        add_usage(self.total, session_id, turns, uncached, cached, output, reasoning, rule)
        add_usage(self.by_tool[tool], session_id, turns, uncached, cached, output, reasoning, rule)
        if label not in self.by_tier:
            self.by_tier[label] = make_bucket()
        add_usage(self.by_tier[label], session_id, turns, uncached, cached, output, reasoning, rule)

    def to_dict(self) -> dict:
        res = finalize_bucket(self.total)
        res["by_tool"] = {k: finalize_bucket(v) for k, v in self.by_tool.items()}
        tiers = []
        for label, b in self.by_tier.items():
            d = finalize_bucket(b)
            d["tier"] = label
            tiers.append(d)
        tiers.sort(key=lambda x: x["api_equiv_usd"], reverse=True)
        res["by_tier"] = tiers
        return res


def collect_antigravity(
    since_dt: datetime,
    until_dt: datetime,
    local_tz,
    ws_norm: str,
    ag_root: Path,
    ws_agg: ScopeAggregator | None,
    all_agg: ScopeAggregator,
    caveats: list[str],
):
    brain_dir = ag_root / "brain"
    if not brain_dir.is_dir():
        return

    conv_meta, db_caveats = load_ag_workspace_map(ag_root / "conversation_summaries.db")
    caveats.extend(db_caveats)

    unattributed_convs = 0
    since_ts = since_dt.timestamp()

    for conv_entry in os.scandir(brain_dir):
        if not conv_entry.is_dir():
            continue
        tp = Path(conv_entry.path) / ".system_generated" / "logs" / "transcript.jsonl"
        if not tp.is_file():
            continue
        try:
            if tp.stat().st_mtime < since_ts:
                continue
        except OSError:
            continue

        conv_id = conv_entry.name
        matches_ws, has_meta = ag_conv_matches_ws(conv_id, conv_meta, ws_norm) if ws_norm else (False, False)
        conv_had_turns = False

        try:
            with open(tp, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    if '"input_tokens"' not in line:
                        continue
                    try:
                        obj = json.loads(line)
                    except Exception:
                        continue
                    ca = obj.get("created_at")
                    if not ca:
                        continue
                    try:
                        dt = parse_dt(ca, local_tz)
                    except Exception:
                        continue
                    if dt < since_dt or dt > until_dt:
                        continue

                    uncached = max(0, int(obj.get("input_tokens") or 0))
                    cached = max(0, int(obj.get("cache_read_tokens") or 0))
                    output = max(0, int(obj.get("output_tokens") or 0))
                    if uncached == 0 and cached == 0 and output == 0:
                        continue

                    model = str(obj.get("model") or "unknown")
                    conv_had_turns = True
                    all_agg.record("antigravity", conv_id, model, 1, uncached, cached, output, 0)
                    if ws_agg is not None and matches_ws:
                        ws_agg.record("antigravity", conv_id, model, 1, uncached, cached, output, 0)
        except OSError:
            continue

        if conv_had_turns and ws_norm and not has_meta:
            unattributed_convs += 1

    if unattributed_convs > 0:
        caveats.append(
            f"{unattributed_convs} Antigravity subagent/conversation transcript(s) lacked workspace metadata in conversation_summaries.db and were counted in All-Machine total only."
        )


def collect_codex(
    since_dt: datetime,
    until_dt: datetime,
    local_tz,
    ws_norm: str,
    codex_root: Path,
    ws_agg: ScopeAggregator | None,
    all_agg: ScopeAggregator,
    caveats: list[str],
):
    sessions_dir = codex_root / "sessions"
    if not sessions_dir.is_dir():
        return

    since_ts = since_dt.timestamp()
    compressed_skipped = 0

    for root, _, files in os.walk(sessions_dir):
        for fn in files:
            fpath = Path(root) / fn
            if fn.endswith(".jsonl.zst"):
                try:
                    if fpath.stat().st_mtime >= since_ts:
                        compressed_skipped += 1
                except OSError:
                    pass
                continue
            if not fn.endswith(".jsonl"):
                continue
            try:
                if fpath.stat().st_mtime < since_ts:
                    continue
            except OSError:
                continue

            cwd = ""
            model = "unknown"
            base_usage = None
            end_usage = None
            turns_in_window = 0

            try:
                with open(fpath, "r", encoding="utf-8", errors="replace") as f:
                    for line in f:
                        if '"session_meta"' in line and not cwd:
                            try:
                                obj = json.loads(line)
                                cwd = (obj.get("payload") or {}).get("cwd") or ""
                            except Exception:
                                pass
                        elif '"turn_context"' in line and model == "unknown":
                            try:
                                obj = json.loads(line)
                                model = (obj.get("payload") or {}).get("model") or "unknown"
                            except Exception:
                                pass
                        elif '"token_count"' in line:
                            try:
                                obj = json.loads(line)
                                ts = obj.get("timestamp")
                                info = (obj.get("payload") or {}).get("info")
                                if not ts or not info:
                                    continue
                                tu = info.get("total_token_usage")
                                if not tu:
                                    continue
                                dt = parse_dt(ts, local_tz)
                                if dt < since_dt:
                                    base_usage = tu
                                elif dt <= until_dt:
                                    end_usage = tu
                                    turns_in_window += 1
                            except Exception:
                                pass
            except OSError:
                continue

            if not end_usage:
                continue

            b = base_usage or {}
            d_in_total = max(0, int(end_usage.get("input_tokens") or 0) - int(b.get("input_tokens") or 0))
            d_cached = max(0, int(end_usage.get("cached_input_tokens") or 0) - int(b.get("cached_input_tokens") or 0))
            d_cached = min(d_cached, d_in_total)
            d_uncached = max(0, d_in_total - d_cached)
            d_out = max(0, int(end_usage.get("output_tokens") or 0) - int(b.get("output_tokens") or 0))
            d_reason = max(0, int(end_usage.get("reasoning_output_tokens") or 0) - int(b.get("reasoning_output_tokens") or 0))
            d_reason = min(d_reason, d_out)

            if d_in_total == 0 and d_out == 0:
                continue

            sid = str(fpath)
            turns_count = max(1, turns_in_window)
            all_agg.record("codex", sid, model, turns_count, d_uncached, d_cached, d_out, d_reason)

            if ws_agg is not None and ws_norm:
                cwd_norm = normalize_path(cwd)
                if is_same_or_subpath(cwd_norm, ws_norm):
                    ws_agg.record("codex", sid, model, turns_count, d_uncached, d_cached, d_out, d_reason)

    if compressed_skipped > 0:
        caveats.append(f"{compressed_skipped} compressed Codex .jsonl.zst session file(s) with recent mtime were not decompressed.")


def _merge_cwd(prev_cwd: str, new_cwd: str, ws_norm: str) -> str:
    if ws_norm:
        p_match = bool(prev_cwd and is_same_or_subpath(normalize_path(prev_cwd), ws_norm))
        n_match = bool(new_cwd and is_same_or_subpath(normalize_path(new_cwd), ws_norm))
        if p_match and n_match:
            return min(prev_cwd, new_cwd)
        if p_match:
            return prev_cwd
        if n_match:
            return new_cwd
    candidates = [c for c in (prev_cwd, new_cwd) if c]
    return min(candidates) if candidates else ""


def collect_claude_code(
    since_dt: datetime,
    until_dt: datetime,
    local_tz,
    ws_norm: str,
    claude_root: Path,
    ws_agg: ScopeAggregator | None,
    all_agg: ScopeAggregator,
):
    projects_dir = claude_root / "projects"
    if not projects_dir.is_dir():
        return

    since_ts = since_dt.timestamp()
    # Deduplicate real requestIds deterministically across all scanned logs,
    # invariant to file traversal order for totals, workspace attribution, and session ID.
    requests: dict[str, tuple[tuple[float, int, int, int, int, str], str, str, int, int, int, str]] = {}

    jsonl_paths = sorted(
        (Path(root) / fn for root, _, files in os.walk(projects_dir) for fn in files if fn.endswith(".jsonl")),
        key=str,
    )

    for fpath in jsonl_paths:
        try:
            if fpath.stat().st_mtime < since_ts:
                continue
        except OSError:
            continue

        session_cwd = ""
        sid = str(fpath)

        try:
            with open(fpath, "r", encoding="utf-8", errors="replace") as f:
                for idx, line in enumerate(f):
                    if '"usage"' not in line and '"cwd"' not in line:
                        continue
                    try:
                        obj = json.loads(line)
                    except Exception:
                        continue
                    if not session_cwd and obj.get("cwd"):
                        session_cwd = str(obj.get("cwd"))
                    msg = obj.get("message")
                    if not isinstance(msg, dict):
                        continue
                    usage = msg.get("usage")
                    if not isinstance(usage, dict):
                        continue
                    ts = obj.get("timestamp")
                    if not ts:
                        continue
                    try:
                        dt = parse_dt(str(ts), local_tz)
                    except Exception:
                        continue
                    if dt < since_dt or dt > until_dt:
                        continue

                    uncached = max(
                        0,
                        int(usage.get("input_tokens") or 0) + int(usage.get("cache_creation_input_tokens") or 0),
                    )
                    cached = max(0, int(usage.get("cache_read_input_tokens") or 0))
                    output = max(0, int(usage.get("output_tokens") or 0))
                    if uncached == 0 and cached == 0 and output == 0:
                        continue

                    model = str(msg.get("model") or "unknown")
                    raw_req_id = obj.get("requestId")
                    dedup_key = f"req:{raw_req_id}" if raw_req_id else f"file:{sid}:line:{idx}"
                    entry_cwd = str(obj.get("cwd") or session_cwd or "")
                    rank_key = (dt.timestamp(), uncached + cached + output, output, cached, uncached, model)

                    prev = requests.get(dedup_key)
                    if prev is None:
                        requests[dedup_key] = (rank_key, sid, model, uncached, cached, output, entry_cwd)
                    else:
                        prev_rank, prev_sid, prev_model, prev_uncached, prev_cached, prev_out, prev_cwd = prev
                        merged_sid = min(prev_sid, sid)
                        merged_cwd = _merge_cwd(prev_cwd, entry_cwd, ws_norm)
                        if rank_key > prev_rank:
                            requests[dedup_key] = (rank_key, merged_sid, model, uncached, cached, output, merged_cwd)
                        else:
                            requests[dedup_key] = (prev_rank, merged_sid, prev_model, prev_uncached, prev_cached, prev_out, merged_cwd)
        except OSError:
            continue

    for _, sid, model, uncached, cached, output, entry_cwd in requests.values():
        all_agg.record("claude_code", sid, model, 1, uncached, cached, output, 0)
        if ws_agg is not None and ws_norm:
            cwd_norm = normalize_path(entry_cwd)
            if is_same_or_subpath(cwd_norm, ws_norm):
                ws_agg.record("claude_code", sid, model, 1, uncached, cached, output, 0)


def collect_all_usage(
    since_dt: datetime,
    until_dt: datetime,
    workspace: str = "",
    pricing_path: Path | None = None,
    completed_count: int = 0,
    ag_root: Path | None = None,
    codex_root: Path | None = None,
    claude_root: Path | None = None,
) -> dict:
    local_tz = until_dt.tzinfo
    script_dir = Path(__file__).resolve().parent
    resolved_pricing = resolve_pricing_path(str(pricing_path) if pricing_path else "", script_dir)
    pricing = load_pricing(resolved_pricing)

    ws_norm = normalize_path(workspace) if workspace else ""
    ws_agg = ScopeAggregator(pricing) if ws_norm else None
    all_agg = ScopeAggregator(pricing)

    caveats = [
        "Estimated dollar values use editable reference API-equivalent rates (pricing.json) to quantify compute volume, not fixed seat/subscription billing."
    ]

    collect_antigravity(
        since_dt,
        until_dt,
        local_tz,
        ws_norm,
        ag_root or Path(os.path.expanduser("~/.gemini/antigravity")),
        ws_agg,
        all_agg,
        caveats,
    )
    collect_codex(
        since_dt,
        until_dt,
        local_tz,
        ws_norm,
        codex_root or Path(os.path.expanduser("~/.codex")),
        ws_agg,
        all_agg,
        caveats,
    )
    collect_claude_code(
        since_dt,
        until_dt,
        local_tz,
        ws_norm,
        claude_root or Path(os.path.expanduser("~/.claude")),
        ws_agg,
        all_agg,
    )

    ws_dict = ws_agg.to_dict() if ws_agg is not None else None
    all_dict = all_agg.to_dict()

    efficiency = None
    if completed_count > 0:
        basis = ws_dict if (ws_dict is not None and ws_dict["total_tokens"] > 0) else all_dict
        basis_scope = "workspace" if (ws_dict is not None and ws_dict["total_tokens"] > 0) else "all_machine"
        n = completed_count
        efficiency = {
            "scope": basis_scope,
            "completed_count": n,
            "tokens_per_deliverable": round(basis["total_tokens"] / n),
            "fresh_input_per_deliverable": round(basis["uncached_input"] / n),
            "output_tokens_per_deliverable": round(basis["output"] / n),
            "api_equiv_usd_per_deliverable": round(basis["api_equiv_usd"] / n, 2),
        }

    return {
        "meta": {
            "window_start_local": since_dt.strftime("%Y-%m-%d %H:%M"),
            "window_end_local": until_dt.strftime("%Y-%m-%d %H:%M"),
            "workspace": workspace or None,
            "currency": pricing.get("currency", "USD"),
            "pricing_file": str(resolved_pricing),
        },
        "workspace": ws_dict,
        "all_machine": all_dict,
        "efficiency": efficiency,
        "caveats": caveats,
    }


def main():
    parser = argparse.ArgumentParser(description="Collect local Antigravity, Codex CLI, and Claude Code token usage.")
    parser.add_argument("--since", default="", help="Start local timestamp (ISO or 'YYYY-MM-DD HH:MM')")
    parser.add_argument("--until", default="", help="End local timestamp (ISO or 'YYYY-MM-DD HH:MM')")
    parser.add_argument("--days", type=int, default=7, help="Rolling lookback in days from current local hour")
    parser.add_argument("--workspace", default="", help="Target workspace path for workspace-scoped attribution")
    parser.add_argument("--pricing", default="", help="Path to pricing.json")
    parser.add_argument("--completed-count", type=int, default=0, help="Completed CL/commit count for per-deliverable efficiency")
    args = parser.parse_args()

    since_dt, until_dt = compute_window(days=args.days, since=args.since, until=args.until)

    out = collect_all_usage(
        since_dt=since_dt,
        until_dt=until_dt,
        workspace=args.workspace,
        pricing_path=Path(args.pricing) if args.pricing else None,
        completed_count=args.completed_count,
    )
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    print(json.dumps(out, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
