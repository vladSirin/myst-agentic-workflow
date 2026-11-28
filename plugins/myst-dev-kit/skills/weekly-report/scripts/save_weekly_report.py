#!/usr/bin/env python3
"""Save a weekly report Markdown file into a rolling 90-day local archive and rebuild INDEX.md."""

import argparse
import errno
import json
import os
import re
import sys
import tempfile
import time
from contextlib import contextmanager, suppress
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


def _ensure_owned_index(index_path: Path) -> bool:
    if not os.path.lexists(index_path):
        return False
    if index_path.is_symlink():
        raise RuntimeError(f"Refusing to follow symlinked index '{index_path}'.")
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
    return True


def _write_index_exclusive(index_path: Path, index_text: str) -> None:
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(str(index_path), flags, 0o666)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(index_text)
    except BaseException:
        with suppress(OSError):
            index_path.unlink()
        raise


@contextmanager
def _archive_lock(target_dir: Path, timeout_sec: float = 5.0):
    lock_path = target_dir / ".weekly-report.lock"
    if lock_path.is_symlink():
        raise RuntimeError(f"Refusing to follow symlinked archive lock '{lock_path}'.")

    windows = os.name == "nt"
    retry_errnos = {errno.EACCES, errno.EAGAIN, errno.EWOULDBLOCK}
    if windows:
        import msvcrt

        retry_errnos.add(errno.EDEADLK)
    else:
        import fcntl

    fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0), 0o666)
    # Unbuffered writes let a concurrent first opener retry byte initialization.
    with os.fdopen(fd, "r+b", buffering=0) as fh:
        deadline = time.monotonic() + timeout_sec
        while True:
            try:
                if windows:
                    if fh.seek(0, os.SEEK_END) == 0:
                        fh.write(b"\0")
                        fh.flush()
                    fh.seek(0)
                    msvcrt.locking(fh.fileno(), msvcrt.LK_NBLCK, 1)
                else:
                    fcntl.flock(fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except OSError as exc:
                if exc.errno not in retry_errnos:
                    raise
                if time.monotonic() >= deadline:
                    raise RuntimeError(f"Timed out waiting for archive lock '{lock_path}'.") from exc
                time.sleep(0.01)
        try:
            yield
        finally:
            with suppress(OSError):
                if windows:
                    fh.seek(0)
                    msvcrt.locking(fh.fileno(), msvcrt.LK_UNLCK, 1)
                else:
                    fcntl.flock(fh.fileno(), fcntl.LOCK_UN)


def _publish_index(index_path: Path, index_text: str) -> None:
    fd, tmp_name = tempfile.mkstemp(prefix=".INDEX.", suffix=".tmp", dir=str(index_path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(index_text)
        owned_exists = _ensure_owned_index(index_path)
        if owned_exists:
            os.replace(tmp_name, str(index_path))
        else:
            try:
                os.link(tmp_name, str(index_path))
            except (NotImplementedError, OSError) as exc:
                if isinstance(exc, OSError) and exc.errno not in (
                    errno.EPERM, errno.EOPNOTSUPP, errno.ENOTSUP, errno.EXDEV, errno.EINVAL
                ):
                    raise
                _write_index_exclusive(index_path, index_text)
    finally:
        with suppress(OSError):
            os.unlink(tmp_name)


def _rebuild_index(index_path: Path, out_path: Path, ts_now: datetime, retention_days: int) -> tuple[int, list[str]]:
    target_dir = index_path.parent
    expired_paths = []
    retained = []
    try:
        prune_cutoff = ts_now - timedelta(days=retention_days)
        saved_path = out_path.resolve()
        for path in target_dir.glob("*.md"):
            if not _is_owned_report(path):
                continue
            mtime = path.stat().st_mtime
            if path.resolve() != saved_path and datetime.fromtimestamp(mtime) < prune_cutoff:
                expired_paths.append(path)
            else:
                retained.append((mtime, path))
        retained.sort(key=lambda entry: entry[0], reverse=True)

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
        for mtime, path in retained:
            match = re.match(r"^(.+?)_\d{4}-\d{2}-\d{2}_\d{4}(?:-\d{2}(?:-\d+)?)?\.md$", path.name)
            proj_col = match.group(1) if match else "unknown"
            saved_col = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
            index_lines.append(f"| {saved_col} | {proj_col} | [{path.name}](./{path.name}) |")

        _publish_index(index_path, "\n".join(index_lines) + "\n")
    except BaseException:
        with suppress(OSError):
            out_path.unlink()
        raise

    pruned_files = []
    for path in expired_paths:
        try:
            path.unlink(missing_ok=True)
        except OSError as exc:
            print(f"Could not prune expired report '{path}': {exc}", file=sys.stderr)
        else:
            pruned_files.append(path.name)
    return len(retained), pruned_files


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
    safe_project = re.sub(r"[^a-zA-Z0-9._-]", "-", project).strip("-") or "workspace"
    body = content if REPORT_MARKER in content[:256] else f"{REPORT_MARKER}\n{content}"

    with _archive_lock(target_dir):
        _ensure_owned_index(index_path)
        ts_now = now or datetime.now()
        candidates = [
            f"{safe_project}_{ts_now.strftime('%Y-%m-%d_%H%M')}.md",
            f"{safe_project}_{ts_now.strftime('%Y-%m-%d_%H%M-%S')}.md",
            *(f"{safe_project}_{ts_now.strftime('%Y-%m-%d_%H%M-%S')}-{seq}.md" for seq in range(2, 100)),
        ]
        for cand in candidates:
            out_path = target_dir / cand
            if out_path.is_symlink():
                continue
            try:
                report_file = open(out_path, "x", encoding="utf-8", newline="\n")
            except FileExistsError:
                continue
            break
        else:
            raise RuntimeError(f"Could not allocate unique archive filename in '{target_dir}'.")

        try:
            with report_file:
                report_file.write(body)
        except BaseException:
            with suppress(OSError):
                out_path.unlink()
            raise
        retained_count, pruned_files = _rebuild_index(index_path, out_path, ts_now, retention_days)

    return {
        "saved_path": str(out_path),
        "index_path": str(index_path),
        "archive_dir": str(target_dir),
        "retention_days": retention_days,
        "retained_count": retained_count,
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
