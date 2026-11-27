---
name: weekly-report
description: "Use for a 7-day VCS-agnostic (Perforce/Git) work report with optional token usage and local archive."
argument-hint: "[optional: workspace, --days N, --since ..., audit, --no-tokens, --no-save]"
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md) (`copy dependency: agentic-workflow`) first to resolve the target repo, VCS ownership, and terminology. This skill is read-only on tracked repo state (`--no-optional-locks` in Git) and **user-invoked only** (for hosts ignoring invocation metadata like OpenCode, add `"weekly-report": "deny"` under `permission.skill` and invoke only via explicit user command).

For `audit`-mode field rules, Perforce current-vs-bounded fields, and archive lock/retention semantics, read [references/DETAILS.md](references/DETAILS.md).

## 1. Collect Data

1. Resolve target workspace, `--vcs p4|git` (Git requires `2.37+`; pass explicit `--vcs` when both exist), window (default: `--days 7` from start of current local hour, or `--days <N>` / `--since "YYYY-MM-DD HH:MM"`), and synthesis mode (`team` default; read [DETAILS.md](references/DETAILS.md) for `audit`). Skill options `--no-tokens` and `--no-save` are not script CLI flags.
2. Run `collect_weekly_work.py` first; skip `collect_token_usage.py` entirely when `--no-tokens` is set:

```bash
python scripts/collect_weekly_work.py --workspace "<path>" --vcs <p4|git>
python scripts/collect_token_usage.py --workspace "<path>" --since "<meta.window_start_iso>" --until "<meta.window_end_iso>" --completed-count <counts.completed>
```

3. **Completion gate:** Every enabled collector exits `0` with valid JSON; for VCS verify `meta.complete == true` and `counts.completed == counts.completed_ids_returned == len(completed)`. On failure, stop and report incomplete coverage instead of archiving.

## 2. Synthesize & Archive

- Reply in the user's language while keeping identifiers, tags, symbols, and VCS terms in English. Ground every ID, count, and verification note in collector output; show `tier` labels only (never internal model codenames).
- Write **3 concise Key Takeaways** (`<= 22 words` each). Group `completed` by workstream ordered by team impact (collapse routine hygiene in `team` mode) covering every ID, rate `wip_active` readiness via `verification`, `summary`, `current_shelved_count`/`shelved_count`, and `last_touched_time`, and give **numbered Next Priorities**.
- Under tokens (`--no-tokens` omits all token KPIs and sections), present `workspace` (`by_tier`, cache savings, efficiency if workspace tokens > 0), `all_machine` if broader, and `caveats`.
- Unless `--no-save`, pipe finished Markdown to a dedicated archive directory (details in [DETAILS.md](references/DETAILS.md)):

```bash
python scripts/save_weekly_report.py --project "<meta.project_name>" --vcs "<meta.vcs>" --window "<meta.window_start_local> to <meta.window_end_local>"
```

## 3. Present Report

Omit AI Compute / Cache Hit / Est. API-Equiv columns and the Token section when `--no-tokens` is active.

```markdown
# Weekly Work Summary — <project_name> (<window_start_local> – <window_end_local>)

| Shipped | Active WIP | AI Compute (Workspace) | Cache Hit | Est. API-Equiv Value |
| :--- | :--- | :--- | :--- | :--- |
| **<N> CLs/commits** (`<vcs>`) | **<M> active** (<k> ready) | **<X.XM> tokens** (<Y.YM> out) | **<P>%** | **`$<V>`** (saved `$<S>` cached) |

> **Key Takeaways**
> - **<Lead Theme>:** <1 crisp outcome line, <= 22 words>.

## Major Work Completed (<N>)
## Active WIP & Readiness (<M>)
## Token Usage & Value Estimation
| Tool / Tier | Sessions / Convs | Turns | Fresh Input | Cached Input | Output | Cache Hit | Est. API-Equiv |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |

## Next Priorities / Needs From Team
1. ...
```

If archived, end with a **Local Archive** notice containing `file://` links to `saved_path` and `index_path`, the archive directory path, retained count, and 90-day rolling retention.
