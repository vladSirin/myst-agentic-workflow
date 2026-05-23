# Changelog

All notable changes to `myst-agentic-workflow`. Versioning: SemVer.

## [1.9.2] - 2026-05-23 — Cross-tool parity audit + automated drift detection

### Added
- **`scripts/run-parity-tests.ps1`** — verifies cross-tool parity via an
  explicit matrix listing each logical item and where it should live in
  each tool's template dir (Claude / Codex / OpenCode). Documented
  deviations are allow-listed with a one-line justification each.
  Unknown files in tool dirs (not in matrix, not deviation) fail.
- **`templates/opencode/.opencode/workflows/PlanPriority.md`** — was
  missing from OpenCode while Claude + Codex had it. Generic rule
  (don't write new plans before searching existing) that applies to
  OpenCode too. Added; manifest entry added to `manifest-template.json`.

### Documented (parity matrix + deviations)
- **3-way parity**: 9 skills, 2 workflows (AgenticWorkflow, PlanPriority),
  1 agent (radical-design-critic), 2 slash commands (update-myst-skills,
  promote-myst-skills), UE overlay's sync-build-submit command,
  myst-project's design skill + architecture-reviewer agent.
- **2-way parity (Claude + Codex, OpenCode opts out)**: perforce
  overlay workflows (ChangelistVerification, ReviewAndSubmit,
  VersionControlRule), myst-project workflows (Design/Document/Script/
  RawMaterialsProtection), angelscriptrules.
- **Tool-specific**: CLAUDE.md (Claude bible), AGENTS.md (Codex+OpenCode
  share at consumer root), OpenCode-only convenience commands
  (design, roundtable wrappers around the same-name skills).

### Why
- User asked: "are we synced between Claude, Codex and Opencode?
  If not make sure they are synced and will keep synced in the future."
- Audit found: recent v1.9.1 changes synced correctly across tools that
  had each file. But `PlanPriority.md` was missing in OpenCode -- a
  silent unintended drift never previously detected.
- The fix: explicit matrix-based parity test that makes the cross-tool
  layout legible. Future drift either fits the matrix (and passes), or
  needs an explicit deviation entry (forcing the maintainer to justify
  the asymmetry).

Tests: 172/172 across 12 suites (was 101/101 in v1.9.1; +71 parity tests).

## [1.9.1] - 2026-05-23 — Clarify .scratch/ is version-controlled (docs-only)

### Changed
- `templates/common/docs/agents/issue-tracker.md`: title renamed
  "Issue tracker: Local markdown" -> "Issue tracker: Repo markdown".
  Added an explicit "Version-control policy" section that states
  files under `.scratch/<feature-slug>/` **are version-controlled** and
  should be submitted with their related work. Distinguishes from
  genuinely local-only state (e.g., `.claude/settings.local.json`).
- `templates/{claude,codex,opencode}/.{claude,Codex,opencode}/skills/triage*`:
  description "Move local markdown issues" -> "Move issues" with an
  explicit pointer to the VC policy.
- `templates/claude/CLAUDE.md` + `templates/codex/AGENTS.md`: slash-
  command reference table line for `/triage` no longer calls the issues
  "local markdown"; clarifies they're version-controlled under
  `.scratch/`.
- `templates/opencode/.opencode/skills/to-prd/SKILL.md`: description
  "local markdown issue tracker" -> "in-repo issue tracker
  (version-controlled markdown under .scratch/)".

### Why
- User report: agents reading "local markdown" in the issue-tracker doc
  and triage skill descriptions get confused about whether `.scratch/`
  files should be submitted to Perforce. Actual practice across 15+
  CLs in the live consumer is to submit them; the word "local" in the
  framework docs read as the opposite.
- The framing "Local markdown" was originally meant in the sense
  "issues live as files in the repo rather than a remote tracker like
  Jira" -- but "local" colloquially means "not version-controlled" to
  most readers, including LLMs. Renaming + adding an explicit VC policy
  removes the ambiguity.

### Not changed
- No code, scripts, manifest schema, or templates beyond the doc-text
  edits.
- The `.scratch/` directory convention itself stays the same.
- Tests: still 101/101 across 11 suites.

## [1.9.0] - 2026-05-23 — Remove strict mode + powermode (course correction)

### Removed
- `enable-strict-mode.ps1` (was the v1.8.0 entry point)
- `enable-powermode.ps1` + `disable-powermode.ps1` (v1.8.1 batch-approval
  bypass)
- `templates/claude/.claude/scripts/hooks/block-unapproved-submit.ps1`
- `templates/claude/.claude/scripts/hooks/cleanup-approved-cl.ps1`
- `scripts/run-strict-mode-tests.ps1` (20 tests covering the removed
  feature)
- 2 hook entries in `manifest-template.json` (consumers re-installing will
  no longer pull the hook scripts)
- README sections on strict mode + powermode
- "Strict-mode hook" + "Powermode" sections in
  `ChangelistVerification.md` (perforce overlay, both Claude + Codex);
  replaced with a brief "Implementation note" linking this CHANGELOG entry

### Why
- v1.8.0 (strict mode) and v1.8.1 (powermode) were built in response to a
  user report that agents drift "from time to time" from the CL-by-CL
  HARD RULE. The mechanism was a Claude Code PreToolUse hook that blocked
  `p4 submit -c <N>` unless an approval marker file was present.
- On honest review: cost-vs-benefit was bad. Strict mode adds 3+ round-
  trips per CL (ask → approve → marker → submit) for every submit, to
  prevent ~1 wrong submit per N sessions. Powermode is a second system
  that bypasses the first system — classic over-engineering smell
  (workaround-for-the-workaround).
- Lighter alternatives that achieve ~80% of the value at ~10% of the
  complexity:
  1. Tighter workflow markdown with clearer "STOP AND ASK" language
  2. UserPromptSubmit hook that injects a 1-line reminder of active
     workflow rules every turn (no blocking; keeps rules visible)
  3. Relying on the user to interrupt the agent ("no, show me first")
- The CL-by-CL rule stays in `ChangelistVerification.md` as advisory
  guidance. It was always advisory by default; v1.9.0 just removes the
  hook layer that tried to enforce it.

### Migration for v1.8.x consumers
1. Run `enable-strict-mode.ps1 -Disable -Yes` to remove the hook wiring
   from `.claude/settings.local.json` (this script still works for
   removal even after v1.9.0 ships, until you `git pull` the package —
   keep a copy if needed).
2. After updating to v1.9.0, the hook script files in
   `.claude/scripts/hooks/` become orphan-but-tracked. Delete them
   manually (or `p4 delete` for Perforce consumers). They're no longer
   in the v1.9.0 manifest.
3. The `.claude/settings.local.json` PreToolUse + PostToolUse blocks
   referencing the now-deleted scripts will cause Claude Code to log
   "hook command not found" warnings. Remove those blocks manually or
   reset the file.

### What stays
- All other v1.x features intact: runtime-mutable hashPolicy (v1.7.0),
  init-consumer + setup/update/promote lifecycle (v1.1.0-v1.4.x),
  overlay split (v1.2.0), slash commands (v1.6.0), etc.

Tests: 101/101 across 11 suites (was 121/121 in v1.8.1; the 20 strict-mode
+ powermode test cases removed with the feature, returning to the v1.7.0
test surface plus the wrapper + init-consumer additions made since).

## [1.8.1] - 2026-05-23 — Powermode (batch-approval bypass for autonomous work)

### Added
- **Powermode** — time + count-bounded bypass for the per-CL approval gate.
  Designed for autonomous `/goal`-driven multi-CL work where the per-CL
  beat is friction without value (bugfix sprints, doc cleanups, bulk
  refactors).
- **`enable-powermode.ps1`** (top-level): writes
  `.scratch/.powermode.marker` with `submitsRemaining`, `expiresAt`,
  `reason`. Defaults: 5 submits / 60 minutes. Validates bounds (caps at
  100 submits / 8 hours, warns if exceeded). Supports `-Status` mode.
- **`disable-powermode.ps1`** (top-level): removes the marker. Idempotent.
- **Hook update**: `block-unapproved-submit.ps1` now checks powermode
  first. If active and within both limits, allows + decrements counter
  + writes back. Either limit tripping (count -> 0, or now >= expiresAt)
  deletes the marker. Per-CL approval gate remains as the fallback.
- **Visibility**: hook prints
  `POWERMODE: allowing submit of CL N (remaining: M; expires: T)` to
  stderr on each use, so it's not silent in the agent's context.

### Changed
- `ChangelistVerification.md` (perforce overlay, both Claude + Codex):
  added "Powermode (v1.8.1)" section documenting expected agent behavior
  when powermode is active (still surface CL contents; honor the user's
  trust; pause + ask if user said "do all" but powermode isn't on).
- `block-unapproved-submit.ps1`, `cleanup-approved-cl.ps1`: rename
  `$event` -> `$evt` (PowerShell automatic-variable lint warning).

### Why
- v1.8.0's per-CL gate is the right friction for normal sessions but
  wrong for `/goal`-driven autonomous work. User reported:
  "we also need a powermode that can directly commit multiple CLs
  without a user's approval, like bugfixing etc."
- Picked count + time both (vs. count only / time only / no-code-toggle)
  because both limits as belt-and-suspenders rule out the failure mode
  of forgetting to disable. Either trip = back to strict.

Tests: 121/121 across 12 suites (was 113/113 in v1.8.0). Strict-mode
suite grew from 12 to 20 tests covering: enable writes marker, allows +
decrements, exhaustion deletes marker, blocks after exhaustion, expired
marker ignored + cleaned up, disable removes marker, status reports
correctly.

## [1.8.0] - 2026-05-23 — Strict mode (CL-by-CL hook enforcement)

### Added
- **`enable-strict-mode.ps1`** top-level script: opt-in installer for
  Claude Code hooks that enforce workflow rules at the tool level (not
  just advisory). Writes/merges the hook wiring into
  `.claude/settings.local.json` (per-machine, not VC-tracked).
  Idempotent re-runs. `-Disable` removes the hooks.
- **`templates/claude/.claude/scripts/hooks/block-unapproved-submit.ps1`**:
  PreToolUse hook that blocks `p4 submit -c <N>` unless
  `.scratch/.approved-cl-<N>.marker` is present at the project root.
  Exit 2 with explanatory message to the agent on block.
- **`templates/claude/.claude/scripts/hooks/cleanup-approved-cl.ps1`**:
  PostToolUse companion. Deletes the marker file after submit so each
  approval is one-shot (can't be reused).
- `scripts/run-strict-mode-tests.ps1`: 12-test suite covering hook
  ignores non-Bash, ignores non-submit Bash, blocks unapproved submit
  with correct exit 2 + message, allows when marker present, cleanup
  removes marker, enable-strict-mode writes valid settings.local.json,
  idempotent re-runs, -Disable removes hooks.

### Changed
- `overlays/perforce/.claude/workflows/ChangelistVerification.md` (and
  Codex mirror): added "Strict-mode hook (when enabled)" section
  documenting the marker dance — what the agent should do when blocked
  (surface CL, ask user, create marker, retry submit).
- `manifest-template.json`: 2 new entries for the hook scripts (claude-only
  for now; OpenCode/Codex don't have an equivalent PreToolUse mechanism).

### Why
- Workflows were advisory: the agent reads `.claude/workflows/*.md` at
  session start, but nothing prevents bypass. Real-world agents drift —
  they submit without asking, batch CLs together, skip the review step.
  User reports this happens "from time to time."
- Claude Code hooks are the actual enforcement layer. The package now
  uses them for the single most-violated rule (CL-by-CL). Future
  versions may add hooks for the other rules.
- Opt-in via a separate script (not auto-enabled in setup.ps1) because
  hooks live in `.claude/settings.local.json` which is per-machine, not
  shared across the team. Some users may not want strict enforcement.

### What it doesn't enforce yet
- `RawMaterialsProtection` (Docs/_Raw read-only) — could add a PreToolUse
  hook on Edit/Write blocking paths under that dir. Not in v1.8.0.
- `ReviewAndSubmit` (must invoke reviewer agent before submit) — harder
  to enforce mechanically; defer.
- `AutoPlanMode` for non-trivial tasks — Claude Code has built-in plan
  mode; can't easily force via hook. Future work.

Tests: 113/113 across 12 suites (was 101/101 in v1.7.0).

## [1.7.0] - 2026-05-22 — `runtime-mutable` hashPolicy fixes opencode.json drift

### Added
- **`runtime-mutable` hashPolicy** for files tools mutate at runtime
  (canonical case: OpenCode's `opencode.json` permission block, which the
  tool rewrites in-session when a user grants a permission). Schema
  documented in `package-manifest.json`'s `hashScopeRule.runtime-mutable`.
- Semantics:
  - **Install seeds** the file from the template on first install
    (target absent).
  - **Subsequent installs never overwrite** — preserves runtime state.
  - **Preflight check 2 skips** entries with this policy — no false-positive
    hash mismatch.
  - **Compare reports `runtime-mutable`** outcome (its own bucket, not
    `downstream-edit`); does not count toward conflicts.
- `scripts/run-runtime-mutable-tests.ps1`: 6-test suite covering bootstrap
  manifest carries the policy, first install seeds, runtime mutation
  preserved across second install, compare outcome is `runtime-mutable`
  (not `downstream-edit`), preflight check 2 passes.

### Changed
- `manifest-template.json`: `opencode.json` entry now has
  `hashPolicy: "runtime-mutable"` (was `sha256`).
- `scripts/install.ps1`:
  - Dry-run analysis: reports `runtime-mutable` (file present) or
    `seed-runtime-mutable` (file absent) instead of `clean` / `DRIFT`.
  - Write phase: skip overwrite if `hashPolicy='runtime-mutable'` and file
    exists; first-install seeding still happens.
- `scripts/run-skeleton-preflight.ps1`: check 2 skips `runtime-mutable`
  entries (added to the existing skip list alongside `localOnly` and
  `self-excluded`).
- `scripts/compare-with-package.ps1`: short-circuits to
  `Outcome=runtime-mutable` for entries with the policy, bypassing the
  hash comparison.
- README: gotcha #1 (`opencode.json +w` pitfall) updated to "Resolved in
  v1.7.0" with a new "What runtime-mutable means" section.
- docs/perforce-consumer.md §5: rewritten to document the policy as the
  resolution path, plus the remaining manual-edit case.

### Why
- The `opencode.json` `+w` always-writable pitfall was the longest-running
  documented limitation (since v1.0). Preflight check 2 failed every time;
  compare reported perpetual `downstream-edit`. The friction blocked
  `update.ps1` in real-world use cases.
- Option C from the design discussion (vs. mark localOnly, mark manual-only,
  or JSON-aware partial hashing) was picked: cheapest, most extensible to
  future runtime-mutated files, keeps the entry visible in reports.

Tests: 101/101 across 11 suites (was 95/95 in v1.6.0).

## [1.6.0] - 2026-05-22 — Rename slash commands to avoid collisions

### Changed (BREAKING for v1.5.0 consumers)
- `/update`  → `/update-myst-skills`
- `/promote` → `/promote-myst-skills`

Renamed for collision-avoidance: `/update` and `/promote` are dangerously
generic — every tool ecosystem has those words attached to built-ins or
adjacent packages, and users couldn't tell at a glance which scaffold
the command would touch.

The new names follow the [mattpocock/skills](https://github.com/mattpocock/skills)
convention of suffixing with the package identifier (compare their
`/setup-matt-pocock-skills`). Verbose but unambiguous.

Internal references updated:
- 6 command files renamed (2 commands × 3 tools).
- `manifest-template.json`: 6 entries' `path` and `sourceTemplate` updated.
- Command bodies updated (their cross-references to each other).
- README slash-command reference table updated.

### Migration for v1.5.0 consumers
If you installed v1.5.0 between today and a few minutes ago and want to
upgrade cleanly:

1. Run `update.ps1` against your consumer. It picks up the renamed entries
   and writes the new files alongside the old.
2. The old `update.md` / `promote.md` files become orphan-but-tracked in
   your `.claude/commands/` etc. — delete them manually (or `p4 delete`
   if Perforce-tracked). They aren't in the v1.6.0 manifest.

Realistically nobody had v1.5.0 in production yet (it shipped <1 hour ago),
so this rename is effectively a free do-over.

Tests: still 95/95 across 10 suites.

## [1.5.0] - 2026-05-22 — `/update` and `/promote` slash commands

### Added
- Slash commands `/update` and `/promote` installed into every consumer
  across all three tools (`.claude/commands/`, `.Codex/commands/`,
  `.opencode/commands/`). Agent instructions for how to drive
  `update.ps1` / `promote.ps1` from inside Claude Code, Codex, or OpenCode.
- 6 new entries in `manifest-template.json` (2 commands × 3 tools), so
  fresh consumers get them automatically via `setup.ps1`. Existing
  consumers receive them on next `update.ps1` run.

### Why
- v1.4.0 added the PowerShell wrappers (`setup.ps1` / `update.ps1` /
  `promote.ps1`) but they only worked when a human typed them at a
  terminal. Inside an agent context, the user had to either drop to a
  shell or instruct the agent step-by-step.
- The slash commands give the agent a direct invocation path: when the
  user says "sync the scaffold" or "promote this upstream", the agent
  reads the command file and runs the right script with the right flags.

### Slash-command behavior
- `/update`: agent finds the package clone (via `package.source` in the
  consumer manifest), runs `update.ps1 -TargetRoot <this>`, surfaces the
  dry-run output, waits for user confirmation, applies the result. Maps
  preflight failure modes to actionable next steps.
- `/promote`: agent identifies modified files (via `p4 opened` /
  `git status` / asking the user), runs `promote.ps1 -TargetRoot <this>
  -Paths <files>`, surfaces the dry-run + roundtrip-verify result, waits
  for confirmation, then walks the user through the git commit/push/PR
  steps in the package.

Tests: still 95/95 across 10 suites (no test surface affected; the
slash commands are markdown instructions, not script logic).

## [1.4.1] - 2026-05-22 — Comprehensive intro README

### Changed
- `README.md` fully rewritten as a proper landing page, modelled on
  [mattpocock/skills](https://github.com/mattpocock/skills): hero with
  status badges, 60-second quickstart, six pain points (with the skills/
  scripts that solve each), categorized reference (lifecycle commands,
  skills, workflows, agents, overlays), FAQ, and known gotchas.
- Pain-points section names the actual problems this package solves:
  three-CLI drift, Bible-file corruption risk, half-installed scaffolds,
  drift detection, stuck improvements, Perforce + multi-developer chaos.

### Why
- v1.0–1.4 had a thin README that listed features. New adopters had no
  fast way to decide whether the package solved their problem.
- The mattpocock/skills README is a strong reference for this category
  of repo. Adopting that structure makes the package more discoverable
  for anyone arriving via the upstream-skills ecosystem.

Docs-only release. No code, scripts, manifest, or templates changed.

## [1.4.0] - 2026-05-22 — One-command update + promote (lifecycle complete)

### Added
- `update.ps1` at repo root: one-command upstream sync. Runs `git pull` (skip
  with `-NoPull`), runs `compare-with-package` (aborts on conflicts), dry-runs
  install, prompts (or `-Yes`), writes via `InstallJournal`. Auto-wraps in
  `-UsePerforce -Changelist new` when the consumer's manifest declares
  `versionControl='perforce'`. Tools and overlays are read from the consumer's
  manifest — no flag duplication.
- `promote.ps1` at repo root: one-command promotion of local improvements
  back to the package. Auto-infers classification per path from the
  consumer's manifest (`owner=package,overlay=core` → `reusable-core`;
  `overlay=perforce` → `perforce-overlay`; etc.). Dry-run + confirm + write.
  Explicit `-Classification` for files not yet in the manifest.
- `scripts/run-wrapper-tests.ps1`: 9-test suite covering both wrappers —
  no-op update, manifest-derived flags, classification inference, error
  on un-inferable paths, explicit-classification path.

### Changed
- `docs/install.md` sections 2-4 rewritten to lead with the one-command
  paths (`setup.ps1`, `update.ps1`, `promote.ps1`). The step-by-step
  scripts are still documented as "advanced" paths for CI integration and
  debugging — they were the only docs in v1.0/v1.1, so the rewrite resolves
  a long-standing inconsistency with the README.
- README now lists all three lifecycle commands together: setup / update /
  promote. The package's user-facing surface is exactly these three scripts
  for the common case.

Tests: 95/95 across 10 suites (was 86/86 in v1.3.0).

## [1.3.0] - 2026-05-22 — Provenance honesty

### Changed
- `README.md` adds a **Provenance** section acknowledging the package was
  extracted from a single project (`Myst_Proto`). The MIT license, generic
  core, and reusable scripts stand; the `myst-` prefix is honest about
  origin, not aspirational marketing.
- `overlays/myst-project/README.md` (new) clearly labels the overlay as a
  reference example: **adopters should not install it** unless they are
  the Myst_Proto project. Documents exactly which files are Myst-only and
  shows how to write your own project-specific overlay.

### Why
- Public MIT repo + name containing `myst-` + an `overlays/myst-project/`
  directory was an intellectually inconsistent presentation. The package
  claimed to be generic; the contents said otherwise.
- Two paths to resolve: rewrite the content to be truly generic
  (premature without a second consumer's requirements to design against),
  or be honest about provenance. v1.3.0 picks honesty.
- A future v2.0 may extract `overlays/myst-project/` to a separate repo
  once a second project adopts the package and provides real evidence
  about what's portable vs Myst-specific.

### Not changed
- No code, scripts, manifest, or templates touched.
- `setup.ps1` auto-detection already never picks `myst-project` — adopters
  have to opt in explicitly.
- 86/86 tests still green.

## [1.2.0] - 2026-05-22 — Overlay split: `perforce` vs `ue`

### Changed
- **Overlay rename**: `ue-perforce` split into two overlays:
  - `perforce/` — generic Perforce CL-by-CL workflow, review-and-submit
    protocol, version-control conventions. Applies to *any* Perforce
    consumer (film/VFX, non-UE game engines, generic enterprise Perforce
    projects).
  - `ue/` — Unreal-Engine specific: sync-build-submit commands, UE-pattern
    p4ignore fragment (`Binaries/`, `Intermediate/`, `Saved/`).
- Manifest schema overlay enum: `["core","ue-perforce","myst-project",
  "tool-capability"]` → `["core","perforce","ue","myst-project",
  "tool-capability"]`.
- `setup.ps1` auto-detection: now picks `core,perforce,ue` only when both
  `.p4ignore` AND a `*.uproject` are present (recursively up to 1 level).
  Plain Perforce projects (no .uproject) get `core,perforce` — no UE bias.

### Backward compatibility
- `init-consumer.ps1 -Overlays 'ue-perforce'` (legacy v1.0.0 – v1.1.0)
  still works; expands to `perforce,ue` at install time.
- Existing v1.x consumers (e.g., the Myst_Proto live install) keep their
  recorded `ownerOverlay='ue-perforce'` — no manifest migration required.
- `promote-from-project.ps1` accepts new classifications `perforce-overlay`
  and `ue-overlay`; the legacy `ue-perforce-overlay` is still in the
  ValidateSet but marked DEPRECATED in the help text.

### Added
- 5 new tests in `run-init-consumer-tests.ps1` covering perforce-only path
  (no UE) and the legacy `ue-perforce` alias expansion.

### Why
- v1.0.0 / v1.1.0 conflated "Perforce workflow" with "Unreal Engine on
  Perforce". A film/VFX team, a Unity team on Perforce, or any non-UE
  Perforce project hitting `setup.ps1` got UE-specific build commands and
  `.p4ignore` patterns they didn't need. The split lets each consumer pick
  exactly what applies.

Tests: 86/86 across 9 suites (was 81/81 in v1.1.0).

## [1.1.0] - 2026-05-22 — One-command install

### Added
- `setup.ps1` at repo root: one-command install for new adopters. Auto-detects
  version control (Perforce / git / filesystem), picks sensible overlay
  defaults, bootstraps the manifest, runs a dry-run, prompts before writing.
  `-Yes` skips the prompt for unattended runs.
- `scripts/init-consumer.ps1`: generates a fresh consumer's bootstrap
  scaffold-manifest from `manifest-template.json`. Filters by selected
  `-Tools` and `-Overlays`, injects the consumer's `installedProject` block,
  resolves `sourceCommit` to the package's git HEAD. Refuses to overwrite
  existing manifest unless `-Force`.
- `manifest-template.json` at repo root: canonical entry-list template
  derived from the live installed scaffold (85 entries, project-specific
  state stripped). The starting point that init-consumer copies + filters.
- `scripts/run-init-consumer-tests.ps1`: 16-test suite covering
  init-consumer round-trip and full setup.ps1 flow.
- init-consumer pre-creates marker stubs for `generated-block` /
  `append-fragment` entries (`CLAUDE.md`, `AGENTS.md`, `.p4ignore`) so
  install.ps1 can populate blocks on first write without manual file creation.

### Fixed
- `install.ps1:185` — `Where-Object` returned `$null` (not empty array) when
  no entries matched the `pending-package` filter, causing
  `PropertyNotFoundStrict` on `.Count` in strict mode. Wrapped in `@(...)`.
  Surfaced after v1.0.0 since every entry now has a real sourceCommit.

### Changed
- README install section: replaced 12-line two-step example with the
  one-command `setup.ps1` flow. Old form still documented in install.md.

## [1.0.0] - 2026-05-21 — First stable release

Plan v1.6 complete. Package is coherent and ready for adoption.

### Added
- **Marker Specification** (`scripts/lib/Markers.ps1`) with hard parsing rules:
  whole-line markers, LF normalization, UTF-8 BOM stripping, CommonMark code-fence
  exclusion, indented-code-block exclusion, refuse-to-write on ambiguity. 14/14
  pathological fixtures pass.
- **Install crash/recovery model** (`scripts/lib/InstallJournal.ps1`): exclusive
  lock, staged temps, atomic rename via `File.Replace`, transactional
  restore-from-baks across the whole set. 10/10 journal tests pass.
- **Block-scoped hashing**: `blockHash` validates only bytes between markers, not
  the whole file. Schema-level rejection of any `generated-block` /
  `append-fragment` entry carrying a whole-file `contentHash`.
- **Cross-repo drift detection** (`scripts/compare-with-package.ps1`): 4 outcomes
  (clean / downstream-edit / upstream-update / conflict) + meta-conflict detection
  for schema and overlay enumeration. 5/5 tests pass.
- **Promotion workflow** (`scripts/promote-from-project.ps1`): bidirectional
  template-rendering, roundtrip-verify, classification by 4 ownership buckets
  (`local-only` / `project-owned` / `package-core` / `overlay`). 4 promotion +
  5/5 e2e tests pass.
- **Skeleton preflight** (`scripts/run-skeleton-preflight.ps1`): 10-point
  write-mode gate. Per-target P4 detection (skips P4-dependent checks for
  filesystem-only targets).
- **Perforce integration**: `install.ps1 -UsePerforce -Changelist new` opens
  files for edit in a named CL with What/Why/Notes description.
- **Consumer documentation**: `docs/install.md` (~500 lines, full install/update/
  promote/upstream-sync guide) and `docs/perforce-consumer.md` (~300 lines,
  UE+P4 addendum with worked example).
- **Architectural Decision Record**: documents Q1-Q5 design decisions (ownership
  taxonomy, marker placement, hashing scope, variable substitution model).
- **65 tests across 8 suites**: marker fixtures (14), journal (10), manifest
  update (5), classification (16), compare (5), promote (4), promotion e2e (5),
  new-user e2e (6).

### Changed
- Manifest schema bumped to **v3** with `blockHashPolicy`, `blockHash`,
  `depotRevision`, `upstreams`, `toolCapabilities`, `baselineState`,
  self-excluded entry.
- Write mode **enabled** (was hard-disabled in 0.1.0); now preflight-gated.
- Upstream `mattpocock/skills` license: **audited as MIT** at pinned commit
  `e74f0061`. Redistribution allowed with attribution.
- README and package manifest now reflect graduation state, not skeleton phase.

### Removed
- `writeModePreconditions` list from `package-manifest.json` (all preconditions
  met).
- `phase: "skeleton"` field (no longer phase-gated).

## [0.1.0] - 2026-05-19 — Skeleton phase

### Added
- Package directory structure (`templates/`, `overlays/`, `scripts/`, `skills/`).
- `package-manifest.json` declaring manifest **schema v3**.
- Dry-run / reporting-only scripts: `install.ps1`, `diff-installed.ps1`,
  `promote-from-project.ps1`, `check-mattpocock-updates.ps1`.

### Constrained
- Write-mode install hard-disabled.
- Marker injection into co-owned files deferred.
- Template/overlay content extraction deferred.
- Upstream license audit pending.
