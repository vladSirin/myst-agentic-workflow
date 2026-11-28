# Weekly Report Reference Details

Disclosed reference for [SKILL.md](../SKILL.md).

## VCS & Audit Semantics

- **Git prerequisite:** Git `2.37+` is required because `collect_weekly_work.py` uses `--since-as-filter`. Git collection runs read-only with `--no-optional-locks`.
- **Auto-detection (`--vcs auto`):** Refuses ambiguous dual-VCS workspaces while allowing Perforce repos that contain an uninitialized `.git` directory.
- **`audit` synthesis mode:** Expands `wip_older` and `default` / working-tree details during report synthesis (`collect_weekly_work.py` has no `--audit` CLI flag). Bounds historical timestamps and sample paths to `meta.window_end_local` wherever relevant timestamps are available (changelists, branches, stashes, and file mtimes), and separates post-window observations into `wip_after_window` and `post_window_files_count`.
- **Perforce pending CL fields:** In `wip_active` and `wip_older`, `bounded_opened_files_count` counts opened paths with `mtime <= meta.window_end_local` (`sample_files` lists up to 5 of those). Fields `current_file_count`, `current_shelved_count`, and `current_shelved_sample_files` reflect current workspace state at collection time; historical shelf state is unknown.
- **Token pricing & efficiency:** Uses [../scripts/pricing.json](../scripts/pricing.json) or `~/.myst/weekly-report-pricing.json` (`tier` labels only). Omits per-deliverable efficiency when workspace token usage is zero.

## Local Archive Behavior & Limits

- **Location & naming:** Dedicated archive directory at `%LOCALAPPDATA%\myst-weekly-reports` (Windows), `~/.cache/myst-weekly-reports` (macOS/Linux), or `MYST_WEEKLY_REPORT_DIR`. Filenames start with `<project>_<YYYY-MM-DD>_<HHMM>.md` and add seconds or sequence suffixes on collision.
- **Serialization & retention:** An OS-released lock on `.weekly-report.lock` stays on disk, serializes concurrent saves, and clears on process exit or crash. Owned reports older than **90 days** are removed only after publishing the updated `INDEX.md`; if index rebuild or publication fails, the newly created report is deleted (a late interruption during temp cleanup after `os.replace` can also delete the new report and leave a broken link in `INDEX.md`).
- **Ownership boundary:** Refuses symlinked or unowned `INDEX.md` and preserves external hard links on owned refreshes. Keep external writers out of the dedicated archive directory (`os.replace` cannot defend against an external writer swapping `INDEX.md` mid-save in a shared folder). On filesystems without hard links, exclusive creation of a first `INDEX.md` can briefly expose a zero-byte file to readers or block retries until removed if the process stops before writing.
