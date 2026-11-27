#!/usr/bin/env python3
"""Save a weekly report Markdown file into a rolling 90-day local archive and rebuild INDEX.md."""

import argparse
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timedelta
from pathlib import Path

REPORT_FILENAME_RE = re.compile(r"^.+_\d{4}-\d{2}-\d{2}_\d{4}(?:-\d{2}(?:-\d+)?)?\.md$")
REPORT_MARKER = "<!-- myst-weekly-report -->"
INDEX_HEADER = "# Weekly Report Local Archive"


def default_archive_dir() -> Path:
    env_dir = os.environ.get("MYST_WEEKLY_REPORT_DIR", "").strip()
    if env_dir:
        return Path(env_dir)
    if os.name == "nt":
        base = os.environ.get("LOCALAPPDATA", "").strip() or os.path.expanduser("~/AppData/Local")
        return Path(base) / "myst-weekly-reports"
    base = os.environ.get("XDG_CACHE_HOME", "").strip() or os.path.expanduser("~/.cache")
    return Path(base) / "myst-weekly-reports"


def _is_owned_report(path: Path) -> bool:
    if path.is_symlink() or not path.is_file() or not REPORT_FILENAME_RE.match(path.name):
        return False
    try:
        head = path.read_text(encoding="utf-8", errors="replace")[:512]
        return REPORT_MARKER in head
    except OSError:
        return False


def _ensure_owned_index(index_path: Path) -> None:
    if index_path.is_symlink():
        raise RuntimeError(f"Refusing to follow symlinked index '{index_path}'.")
    if not os.path.lexists(index_path):
        return
    if not index_path.is_file():
        raise RuntimeError(f"Refusing to overwrite non-regular index path '{index_path}'.")
    try:
        first_line = index_path.read_text(encoding="utf-8", errors="replace").splitlines()[0].strip()
    except (OSError, IndexError):
        first_line = ""
    if first_line != INDEX_HEADER:
        raise RuntimeError(
            f"Refusing to overwrite existing '{index_path}' because its ownership cannot be established "
            f"(expected first line '{INDEX_HEADER}')."
        )


def save_report(
    project: str,
    vcs: str,
    window: str,
    content: str,
    archive_dir: Path | None = None,
    retention_days: int = 90,
    now: datetime | None = None,
) -> dict:
    if not content or not content.strip():
        raise ValueError("Report content is empty.")

    target_dir = archive_dir or default_archive_dir()
    target_dir.mkdir(parents=True, exist_ok=True)
    index_path = target_dir / "INDEX.md"
    _ensure_owned_index(index_path)

    safe_project = re.sub(r"[^a-zA-Z0-9._-]", "-", project).strip("-") or "workspace"
    ts_now = now or datetime.now()

    body = content if REPORT_MARKER in content[:256] else f"{REPORT_MARKER}\n{content}"
    candidates = [
        f"{safe_project}_{ts_now.strftime('%Y-%m-%d_%H%M')}.md",
        f"{safe_project}_{ts_now.strftime('%Y-%m-%d_%H%M-%S')}.md",
        *(f"{safe_project}_{ts_now.strftime('%Y-%m-%d_%H%M-%S')}-{seq}.md" for seq in range(2, 100)),
    ]

    out_path = None
    for cand in candidates:
        cand_path = target_dir / cand
        if cand_path.is_symlink():
            continue
        try:
            with open(cand_path, "x", encoding="utf-8", newline="\n") as fh:
                fh.write(body)
            out_path = cand_path
            break
        except FileExistsError:
            continue

    if out_path is None:
        raise RuntimeError(f"Could not allocate unique archive filename in '{target_dir}'.")

    prune_cutoff = ts_now - timedelta(days=retention_days)
    pruned_files = []
    for f in target_dir.glob("*.md"):
        if f.resolve() == out_path.resolve() or not _is_owned_report(f):
            continue
        mtime = datetime.fromtimestamp(f.stat().st_mtime)
        if mtime < prune_cutoff:
            pruned_files.append(f.name)
            f.unlink()

    retained = sorted(
        (f for f in target_dir.glob("*.md") if _is_owned_report(f)),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )

    index_lines = [
        INDEX_HEADER,
        "",
        f"- **Location:** `{target_dir}`",
        f"- **Retention:** {retention_days} days (~3 months rolling auto-prune)",
        f"- **Retained Reports:** {len(retained)}",
        f"- **Last Updated:** {ts_now.strftime('%Y-%m-%d %H:%M')}",
        "",
        "| Saved | Project | File |",
        "| :--- | :--- | :--- |",
    ]

    for rf in retained:
        m = re.match(r"^(.+?)_\d{4}-\d{2}-\d{2}_\d{4}(?:-\d{2}(?:-\d+)?)?\.md$", rf.name)
        proj_col = m.group(1) if m else "unknown"
        saved_col = datetime.fromtimestamp(rf.stat().st_mtime).strftime("%Y-%m-%d %H:%M")
        index_lines.append(f"| {saved_col} | {proj_col} | [{rf.name}](./{rf.name}) |")

    _ensure_owned_index(index_path)
    index_text = "\n".join(index_lines) + "\n"
    fd, tmp_name = tempfile.mkstemp(prefix=".INDEX.", suffix=".tmp", dir=str(target_dir))
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(index_text)
        _ensure_owned_index(index_path)
        os.replace(tmp_name, str(index_path))
    except Exception:
        try:
            os.unlink(tmp_name)
        except OSError:
            pass
        raise

    return {
        "saved_path": str(out_path),
        "index_path": str(index_path),
        "archive_dir": str(target_dir),
        "retention_days": retention_days,
        "retained_count": len(retained),
        "pruned_count": len(pruned_files),
        "pruned_files": sorted(pruned_files),
        "vcs": vcs,
        "window": window,
    }


def main():
    parser = argparse.ArgumentParser(description="Save a weekly report to a rolling 90-day local archive.")
    parser.add_argument("--project", required=True)
    parser.add_argument("--vcs", required=True)
    parser.add_argument("--window", required=True)
    parser.add_argument("--content", default="")
    parser.add_argument("--content-file", default="")
    parser.add_argument("--archive-dir", default="")
    parser.add_argument("--retention-days", type=int, default=90)
    args = parser.parse_args()

    content = args.content
    if not content:
        if args.content_file:
            p = Path(args.content_file)
            if not p.is_file():
                raise SystemExit(f"Content file does not exist: {p}")
            content = p.read_text(encoding="utf-8")
        else:
            content = sys.stdin.read()

    res = save_report(
        project=args.project,
        vcs=args.vcs,
        window=args.window,
        content=content,
        archive_dir=Path(args.archive_dir) if args.archive_dir else None,
        retention_days=args.retention_days,
    )
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    print(json.dumps(res, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
