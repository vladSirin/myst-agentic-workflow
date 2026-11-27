---
name: weekly-report
description: "Use when the user asks to generate a VCS-agnostic (Perforce or Git) weekly team work report covering the last 7 days from the current hour, with optional local AI token usage & value estimation and a 90-day local archive."
argument-hint: "[optional: workspace, --days N, --since ..., audit, --no-tokens, --no-save]"
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
first (copy dependency: `agentic-workflow`) to resolve the target repository,
VCS ownership, and project terminology. This skill never mutates tracked files
or publishes shared state; its Git collector uses `--no-optional-locks` to avoid
index writes.

## 1. Determine scope, options, and mode

- **Target workspace**: Use the target repository root resolved via the local integration contract (or pass `--workspace <path>`).
- **VCS**: Resolve ownership via project instructions (`AGENTS.md` / `CLAUDE.md`) and workspace evidence first, then pass `--vcs p4` or `--vcs git` explicitly (`--vcs auto` refuses ambiguous dual-VCS workspaces while still handling Perforce repos with an uninitialized `.git` directory).
- **Window**: Defaults to **7 days back from the start of the current local hour** (`--days 7`). Pass `--days <N>` or `--since "YYYY-MM-DD HH:MM"` if another range is requested.
- **Mode**:
  - **`team`** (default): Executive KPI snapshot + crisp takeaways, outcome-first deliverables, active WIP readiness, token usage & compute value, and next priorities. Condenses routine repo-hygiene/retirement batches into a compact line.
  - **`audit`**: Expands older parked/shelved/unmerged WIP (`wip_older`) and `default` / working-tree details strictly bounded to `meta.window_end_local`, while keeping post-window observations (`wip_after_window`, `post_window_files_count`) separated from historical readiness.
- **Optional flags**: Skip token telemetry when `--no-tokens` is requested; skip writing to the local archive when `--no-save` is requested.
- **Language**: Match the user's requested language while keeping technical identifiers, tags, symbols, and VCS terms in English per project rules.

## 2. Collect VCS history and token usage

Run the VCS collector first with the resolved `--vcs` flag. Unless `--no-tokens` is requested, also run the token collector using both exact ISO bounds (`meta.window_start_iso` and `meta.window_end_iso`) and `--completed-count <counts.completed>`:

```bash
python scripts/collect_weekly_work.py --workspace "<path>" --vcs <p4|git>
python scripts/collect_token_usage.py --workspace "<path>" --since "<meta.window_start_iso>" --until "<meta.window_end_iso>" --completed-count <N>
```

- Never invent CLs, commits, verification results, or token counts; never expose raw internal model codenames in the report (always use the human-readable `tier` labels from `scripts/pricing.json` or `~/.myst/weekly-report-pricing.json`).
- **Completion criterion**: Every enabled collector exits `0` and parses cleanly as JSON. For the VCS collector (`collect_weekly_work.py`), verify `meta.complete` is `true` and `counts.completed == counts.completed_ids_returned == len(completed)`. If an enabled collector fails, stop and report incomplete coverage instead of archiving zero work.

## 3. Synthesize and verify returned items

- **Major Work Completed (`completed`)**: Group by feature/system workstream ordered by team impact. In `team` mode, collapse routine hygiene/retirement batches into one compact line. Account for every returned CL/commit ID in `completed`.
- **Active WIP (`wip_active`)**: Classify each active item (`pending_cl`, `branch`, `working_tree`, `stash`) by readiness using `verification`, `summary`, `shelved_count`, and `last_touched_time`.
- **Token Usage & Value Estimation** (omit when `--no-tokens` is active): Present the `workspace` breakdown (`by_tier`, cache savings, per-deliverable efficiency) plus `all_machine` total if other repos were active, and include `caveats`.

## 4. Save to the 90-day local archive (unless `--no-save`)

Pipe the finished Markdown report into `scripts/save_weekly_report.py`:

```bash
python scripts/save_weekly_report.py --project "<meta.project_name>" --vcs "<meta.vcs>" --window "<meta.window_start_local> to <meta.window_end_local>"
```

- Stores a UTF-8 report in the user's OS-local archive directory (`%LOCALAPPDATA%\myst-weekly-reports` on Windows, `~/.cache/myst-weekly-reports` on macOS/Linux, or `MYST_WEEKLY_REPORT_DIR`), using `<project>_<YYYY-MM-DD>_<HHMM>.md` as the first candidate (adding seconds/sequence suffixes on collision), auto-prunes only owned weekly-report files older than **90 days**, and updates an owned non-symlink `INDEX.md`. Always link the returned `saved_path` in the archive notice.

## 5. Present the report

When `--no-tokens` is active, omit the AI Compute / Cache Hit / Est. API-Equiv columns from the KPI snapshot and omit the `## Token Usage & Value Estimation` section.

```markdown
# Weekly Work Summary — <project_name> (<window_start_local> – <window_end_local>)

| Shipped | Active WIP | AI Compute (Workspace) | Cache Hit | Est. API-Equiv Value |
| :--- | :--- | :--- | :--- | :--- |
| **<N> CLs/commits** (`<vcs>`) | **<M> active** (<k> ready) | **<X.XM> tokens** (<Y.YM> out) | **<P>%** | **`$<V>`** (saved `$<S>` cached) |

> **Key Takeaways**
> - **<Lead Theme 1>:** <1 crisp outcome line, <= 22 words>.
> - **<Lead Theme 2>:** <1 crisp outcome line, <= 22 words>.
> - **<Lead Theme 3>:** <1 crisp outcome line, <= 22 words>.

## Major Work Completed (<N>)
...

## Active WIP & Readiness (<M>)
...

## Token Usage & Value Estimation
| Tool / Tier | Sessions / Convs | Turns | Fresh Input | Cached Input | Output | Cache Hit | Est. API-Equiv |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |

## Next Priorities / Needs From Team
1. ...
```

When archived, end with an explicit **Local Archive** notice containing clickable `file://` links to `saved_path` and `index_path`, the archive directory path, retained count, and 90-day rolling retention status.
