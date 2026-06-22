# Changelog

All notable changes to `myst-agentic-workflow`. Versioning: SemVer.

## [2.8.0] - 2026-06-22 — Phase B-1: vendor new skills (faithful, verbatim frontmatter)

### Added
Seven skills vendored faithfully from upstream HEAD (`6eeb81b`), verbatim
frontmatter+body (Claude/Codex byte-identical; OpenCode +`compatibility`),
companions in-dir:
- **codebase-design** (+ DEEPENING, DESIGN-IT-TWICE) — unblocks faithful tdd/ICA.
- **setup-matt-pocock-skills** (+ domain, issue-tracker-github/gitlab/local,
  triage-labels) — unblocks faithful triage/to-issues.
- **writing-great-skills** (+ GLOSSARY) — successor to write-a-skill.
- **implement**, **edit-article**, **obsidian-vault** — adopted.
- **resolving-merge-conflicts** — git base verbatim **+ a `perforce`-overlay
  `P4-NOTES.md` companion** (Claude/Codex) adapting it to Perforce text merges.
- 47 manifest entries (45 core SPDX MIT + 2 perforce), 16 parity rows.

### Notes
- Phase B-1 of the curated convergence: dependency skills first (codebase-design
  → tdd/ICA; setup-matt-pocock-skills → triage), per principle #5.
- Rejection memory updated: only `ask-matt`/`prototype` (skip) + `decision-mapping`
  (defer) remain; zoom-out/caveman/write-a-skill flagged follow-deletion (B-3).
- 13/13 suites pass (parity 169, link-check 152); install + idempotency verified.

### Changed
- **Skill format converged to upstream verbatim** (ADR-0003). `SKILL.md` is now
  upstream's YAML frontmatter (`name`/`description`/`disable-model-invocation`/
  `argument-hint`) + body — Claude/Codex byte-identical to upstream, OpenCode
  adds only `compatibility: opencode`. The house `# H1`-as-description +
  `<command-name>` convention is **dropped** (the command name is the skill
  directory name in all three tools; `<command-name>` was never a real field).
- Re-wrapped the already-merged skills to this format: `diagnosing-bugs`,
  `domain-modeling`, `grilling`, `teach`. Converted the local-only `roundtable`
  to frontmatter (content preserved; OpenCode keeps its condensed body).
- This makes "faithful" include **format** — Claude Code now gets upstream's
  user/model-invoked split natively (answers the `disable-model-invocation`
  question), and `compare-with-package.ps1` shows clean diffs vs upstream.

### Notes
- Per-tool support verified: Claude Code honors frontmatter + invocation flags
  natively (dir = command); Codex discovery is via AGENTS.md (frontmatter is
  harmless metadata); OpenCode is frontmatter-aware via opencode.json.
- Open sub-decision (Phase B): how a `ue`-overlay companion (`diagnosing-bugs/
  UE-NOTES.md`) is surfaced now that the verbatim base carries no footer pointer.
- 13/13 suites pass; install idempotent.

### Added
- **`domain-modeling`** (engineering) — active domain-model discipline, vendored
  faithfully from upstream HEAD (`6eeb81b`) with its `CONTEXT-FORMAT.md` +
  `ADR-FORMAT.md` companions in-dir (faithful architecture). Three-way.
- **`grilling`** (productivity) — relentless plan/design interview; the upstream
  successor that `grill-me`/`grill-with-docs` delegate to at HEAD. Three-way.
- **`teach`** (productivity) — stateful multi-session teaching workspace, with
  its `MISSION-FORMAT` / `RESOURCES-FORMAT` / `LEARNING-RECORD-FORMAT` /
  `GLOSSARY-FORMAT` companions in-dir. OpenCode frontmatter keeps upstream's
  `disable-model-invocation` + `argument-hint`; Claude/Codex encode
  explicit-only via `<command-name>`. Three-way.
- 27 manifest entries (`owner=package`, `core`, SPDX MIT) + 9 parity rows.
  Companion `.md` files are byte-faithful to upstream (verbatim, no transform).

### Notes
- **Phase A** of the curated convergence-to-HEAD program: vendor the adopted
  siblings first, because Phase-B dependents (`grill-with-docs`, `grill-me`,
  `triage`) hard-bind to `domain-modeling`/`grilling` (principle #5).
- Provenance: these track upstream HEAD (`6eeb81b`), ahead of the package pin —
  deliberate per-skill sync, recorded here.
- 13/13 suites pass (parity 122, link-check 107 resolve); install lands all
  skills + companions and is idempotent.

### Added
- **Link-existence lint** `scripts/run-linkcheck-tests.ps1` (13th test suite):
  resolves every relative companion/cross-link in skills, workflows, and
  commands against the package tree; skips consumer artifacts (`CONTEXT.md`,
  `docs/adr/*`, `Docs/*`, `{{var}}`, `/src/*`, `.scratch/*`). Makes the
  dangling-reference bug class un-reshippable (principle #4). Known not-yet-
  reconciled drifts live in an `$allow` backlog (20 entries) that shrinks as
  Phase-1 re-vendors land.
- **Rejection memory** `.scratch/agentic-scaffold-rejected-upstream.json`
  (principle #6): records skill-level keep/skip/defer decisions vs upstream
  HEAD (`6eeb81b`) so future syncs don't re-litigate them — keep
  zoom-out/caveman/write-a-skill (documented reasons); skip
  ask-matt/edit-article/obsidian-vault/resolving-merge-conflicts/implement/
  prototype/decision-mapping/codebase-design; defer writing-great-skills.
  `check-mattpocock-updates.ps1` already reads this path.

### Notes
- Guardrails for the curated convergence-to-HEAD program. All 13 suites pass.

### Added
- **ADR-0002** (`docs/adr-0002-vendor-and-overlay-not-fork.md`): records the
  decision to stay current with upstream via **vendor-and-overlay**, not a git
  fork or submodule. Staying current is a *curation* problem, not a *storage*
  problem; fork/submodule can't represent our 3-tool transform and would block
  per-file curation. Base is vendored faithfully + complete; project tailoring
  lives in overlays. Documents the engine gap that `append-fragment` can't
  idempotently append to a `copy`-owned skill file (hence same-dir companions
  for skill tailoring).
- **`ue` overlay companion** `skills/diagnosing-bugs/UE-NOTES.md` (three-way:
  Claude/Codex/OpenCode) carrying the UE5/Perforce adaptation of the diagnosis
  loop (automation specs / `-ExecCmds` headless runs / `p4` bisection / editor
  HITL into `.scratch/`). Registered in `manifest-template.json` + parity matrix.

### Changed
- **`diagnose` → `diagnosing-bugs`** (skill dir, `<command-name>` / frontmatter
  `name`, manifest paths, parity IDs, CLAUDE.md/AGENTS.md tables, AgenticWorkflow
  + MustRead refs, README). **Breaking:** the command is now `/diagnosing-bugs`.
  Rationale: upstream-inherited skills track upstream naming faithfully to avoid
  drift; upstream renamed this skill to `diagnosing-bugs` at HEAD (`6eeb81b`).

### Fixed
- **`diagnosing-bugs` restored to the faithful upstream discipline** (was a
  22-line stub that amputated the whole six-phase loop). Adopted the upstream
  **HEAD (`6eeb81b`)** version faithfully — including its improvements over our
  pin (`b8be62f`): the "tighten the loop" guidance, the **red-capable completion
  criterion** for Phase 1, and **Phase 2 "Reproduce + minimise"**. Vendored its
  `scripts/hitl-loop.template.sh` companion too (closes the dangling-companion
  defect ADR-0002 targets). First worked example of the model: faithful base in
  core (Claude/Codex `<command-name>`, OpenCode frontmatter), project specifics
  in the `ue` overlay.

### Notes
- **Provenance:** `diagnosing-bugs` is the first skill synced to upstream HEAD
  (`6eeb81b`), ahead of the package pin (`b8be62f`) which stays put until a
  deliberate full sync. This is intentional per-skill faithful tracking, not
  drift.
- Prototype validating the faithful-base + overlay split before the broader
  re-vendor. All 12 test suites pass; install lands base + companion + script and
  is idempotent.

## [2.4.2] - 2026-06-20 — Restore cross-tool parity; complete v2.4.x file bookkeeping

### Fixed
- **Parity test (`run-parity-tests.ps1`) now green (89/0).** v2.3.0 and v2.4.0
  shipped new files without registering them in the parity matrix, and v2.4.1
  retired `VersionControlRule.md` without removing its matrix row. Reconciled
  the matrix with disk:
  - Added `workflow:PreImplementationGate` (three-way: Claude/Codex/OpenCode).
  - Added `workflow:AutoPlanMode` (two-way: Claude/Codex; OpenCode `$null`
    with a deviation — it targets the Claude/Codex plan-mode capability and
    OpenCode has no equivalent).
  - Added `overlay:ue/UnrealMCPRule` (three-way, per-tool layout: Claude/Codex
    `rules/unrealmcprules.md`, OpenCode `workflows/UnrealMCPRule.md`).
  - Removed the retired `overlay:perforce/VersionControlRule` row + deviation.
- **`manifest-template.json` reconciled with disk.** v2.4.1 deleted the
  `VersionControlRule.md` sources but left two dangling `files[]` entries whose
  `sourceTemplate` pointed at the deleted files (broke `compare`/`promote`
  against the real repo). Removed both. Registered the previously-unregistered
  active files so they actually install: `PreImplementationGate.md` (3 tools)
  and `unrealmcprules.md` / `UnrealMCPRule.md` (3 tools).

### Notes
- All 12 test suites pass (182 tests).
- Known follow-up (not addressed here): the two `AutoPlanMode` entries still
  carry a placeholder `sourceTemplate` under `profiles/` (a non-existent dir),
  flagged by their `tool-capability` / `capabilityProfile` design as
  "needs rewrite before packaging." Left intact pending that rewrite.

## [2.4.1] - 2026-06-01 — Refresh workspace-setup generated block

### Fixed
- `templates/claude/CLAUDE.md` and `templates/codex/AGENTS.md` workspace-setup
  block was stale: removed the dead `VersionControlRule.md` reference (that
  workflow was deleted), added `unrealmcprules.md` (rule) and
  `PreImplementationGate.md` (workflow), and updated the skills/commands
  listings to the folder-based `<name>/SKILL.md` layout (14 skills, 7 commands).

### Removed
- `overlays/perforce/.claude/workflows/VersionControlRule.md` and
  `overlays/perforce/.Codex/workflows/VersionControlRule.md` — the workflow was
  retired; deleting the overlay source stops installs from restoring it.

## [2.4.0] - 2026-05-24 — Unreal Engine MCP rule (ue overlay)

### Added
- **`unrealmcprules.md`** (Claude rules dir) / **`UnrealMCPRule.md`**
  (OpenCode workflows dir) — a new file in the `ue` overlay that fires
  when agents are about to operate on Unreal Engine assets, Blueprints,
  levels, actors, materials, or the editor. Trigger conditions: file
  extensions (`.uasset`, `.umap`), asset paths (`/Game/...`), asset
  prefixes (`BP_`/`WBP_`/`SM_`/`MI_`/`M_`/`T_`/`A_`/`NS_`/`DA_`),
  keywords ("blueprint", "actor", "level", etc.).
- The rule's core mechanism: it tells agents the
  `mcp__unreal-engine__*` tools are **deferred** in the host harness
  (Claude Code surfaces them by name; schemas aren't preloaded), and
  to call `ToolSearch` first to load the schemas before invoking. Maps
  trigger → tool → action in a table so agents reach for MCP instead
  of falling back to `Read`/`Grep` on binary `.uasset` files.

### Why
- Surfaced during a UE_Blank_Proto session where agents repeatedly fell
  back to `Read`/`Grep` on `.uasset` files (binary; output is useless)
  instead of using the MCP tools because the MCP tools were never being
  loaded into the agent's available toolset. The rule is the bridge
  between awareness ("there's an MCP for this") and capability ("load
  the schemas, then call them").

### For consumers
- Consumers using the `ue` overlay (set during `init-consumer.ps1` or
  via `update.ps1`) get this rule automatically on next install. Other
  overlays unaffected.

## [2.3.0] - 2026-05-24 — PreImplementationGate workflow + AutoPlanMode rewrite

### Added
- **`PreImplementationGate.md`** workflow (Claude + Codex + OpenCode):
  fires when an agent is about to draft a 2+ CL implementation plan
  and verifies that the project has a PRD + ready-for-agent issue(s)
  for the work. If not, the agent STOPS and offers two options:
  (a) `/to-prd` to create one, or (b) explicit deviation noted in the
  CL description. Narrowly-scoped gate; doesn't fire on small fixes.

### Changed (BEHAVIOR CHANGE — read before upgrading)
- **`AutoPlanMode.md` rewritten** and **reclassified**. Previously the
  file was treated as a per-project reference (mergeStrategy: manual-only,
  writablePolicy: report-only, ownerOverlay: tool-capability) — the
  installer never overwrote consumer customizations. With v2.3.0 the
  file is package-canonical (mergeStrategy: copy, writablePolicy:
  installer-owned, ownerOverlay: core), so `install.ps1 -Mode Write`
  WILL overwrite any consumer-local AutoPlanMode customizations.
- The content was also rewritten to replace the previous "ANY tool,
  ZERO EXCEPTIONS" rule (which was universally ignored in practice)
  with realistic "use plan mode when X / skip when Y" triggers based
  on actual practice.

### Migration note for existing consumers
If you have a local `AutoPlanMode.md` you've customized, save a copy
before running `/update-myst-skills` to v2.3.0. The installer will
overwrite it. You can re-apply your customizations after, or fork the
file as a project-local workflow with a different name.

### Why
- Surfaced during a consumer-side workflow audit (UE_Blank_Proto CLs
  1049/1050/1051) where the AutoPlanMode rule turned out to be ignored
  by every agent (including by me, the project agent). When a rule is
  universally violated it stops being a rule. The rewrite captures what
  agents actually do: plan-mode for multi-file work, skip for reads /
  single edits / lookups inside an already-planned task.
- `PreImplementationGate` is a narrow gate addressing the pattern where
  agents collapse Discussion → Implementation, skipping PRD/Issues/
  Triage. It's advisory but specific.

## [2.2.0] - 2026-05-24 — Link DesignWorkflow + AgenticWorkflow; PlanPriority dual-search

### Changed
- **`AgenticWorkflow.md`**: added a "Scope and relationship to
  DesignWorkflow" block describing three flow shapes (game-design +
  implementation / pure code / pure game design no code). When game
  design is involved, the Discussion phase is **extended** via
  `DesignWorkflow.md`; the PRD phase here references the finalized
  design doc.
- **`PlanPriority.md`**: search now covers BOTH `{{game_docs_root}}/`
  (1a, for DesignWorkflow-shape work) and `.scratch/` (1b, for
  AgenticWorkflow-shape work). Documents how 1a and 1b sequence into
  each other instead of being parallel choices — finding one but not
  the other is a signal about pipeline position, not a sign the other
  location is wrong to look in.

### Why
- The previous shape of these two workflows looked like competing
  alternatives — DesignWorkflow routed to `{{game_docs_root}}/`,
  AgenticWorkflow routed to `.scratch/`, and a user couldn't tell which
  applied. Surfaced during a consumer-side workflow audit (UE_Blank_Proto
  CLs 1049/1050/1051). Right model: they're sequential, with
  DesignWorkflow as the extended Discussion phase when game-design
  thinking is involved.
- PlanPriority used to search only `{{game_docs_root}}/`, leaving
  `.scratch/` invisible to plan discovery. Agents picked whichever they
  saw first → drift accumulated. Dual-search closes that gap.

### Note
- This release ships only the universally-applicable subset of the
  consumer-side audit. Several related improvements (a
  `PreImplementationGate.md` workflow rule, a rewritten
  `AutoPlanMode.md`, an Unreal Engine MCP rule) remain consumer-local
  pending follow-up manifest surgery to unblock their promotion.

## [2.1.1] - 2026-05-24 — Preflight tolerates pending-CL state

### Fixed
- **Preflight check 4 (depotRevision == headRev) no longer flags
  open-for-add files as drift.** When a file is staged in a pending CL
  via `p4 add` / `p4 branch` / `p4 move/add`, its headRev is `null`
  (depot doesn't know about it yet) while the manifest may already list
  it with `depotRevision=1`. Previous behavior reported this as drift
  and refused `install.ps1 -Mode Write`.
- **Preflight check 5 (no unmanaged scaffold files) no longer flags
  open-for-delete files as unmanaged.** A file removed from the manifest
  but still open-for-delete in a pending CL is intentionally being
  removed; it remains in `p4 have` until submit. Previous behavior
  reported this as unmanaged and refused write mode.

### Why
- The v2.0.0 / v2.1.0 structural CLs (45 file deletes + 28 file adds)
  could not run through `install.ps1 -Mode Write` because preflight
  rejected them — the very state preflight exists to safeguard. Both
  CLs landed via a surgical manual `p4 add`/`p4 delete` workaround that
  bypassed the installer's atomic-rename + journal-rollback. This is
  the exact case that needs the most protection, so the gate was
  defeating its own purpose.
- Distinguishing "new-in-this-CL" / "pending-delete" from real drift
  requires consulting `p4 opened`. The fix runs that query once at
  preflight start and exempts entries with the matching pending action.

### Added
- `scripts/run-pending-opens-tests.ps1` — six scenarios:
  - A. Baseline (no opens, head matches manifest) → PASS 10/10
  - B. Pending add → PASS 10/10 (was: FAIL check 4)
  - C. Pending delete → PASS 10/10 (was: FAIL check 5)
  - D. Mixed structural CL → PASS 10/10
  - E. Real drift (no opens) → FAIL check 4 (no false negative)
  - F. Real unmanaged (no opens) → FAIL check 5 (no false negative)
- `scripts/fake-p4.ps1` — test-only p4 shim that seeds info / opened /
  have / fstat output via environment variables. Prepended to PATH for
  the duration of each test; never touches the live depot.

### Note
- The exemptions are scoped: only `add`/`branch`/`move/add` skip check
  4, and only `delete`/`move/delete` skip check 5. `edit` opens are
  unaffected (an edited file still has a real headRev that must match
  the manifest's depotRevision).

## [2.1.0] - 2026-05-23 — Match upstream skill structure: `<name>/SKILL.md`

### Changed (structural)
- **All skills restructured from flat `<name>.md` to subdirectory
  `<name>/SKILL.md`** to match upstream mattpocock/skills canonical
  format (referenced in their `.claude-plugin/plugin.json`).
- 26 Claude + Codex template files moved:
  - `templates/claude/.claude/skills/<name>.md` →
    `templates/claude/.claude/skills/<name>/SKILL.md`
  - `templates/codex/.Codex/skills/<name>.md` →
    `templates/codex/.Codex/skills/<name>/SKILL.md`
- 2 myst-project overlay files moved too:
  - `overlays/myst-project/.claude/skills/design.md` →
    `overlays/myst-project/.claude/skills/design/SKILL.md`
  - `overlays/myst-project/.Codex/skills/design.md` →
    `overlays/myst-project/.Codex/skills/design/SKILL.md`
- OpenCode was already in subdir form (`templates/opencode/.opencode/
  skills/<name>/SKILL.md`); no change for that tool.
- 28 manifest entries updated: `path` + `sourceTemplate` rewrite.
- Parity matrix updated to expect the new paths.
- 4 test paths updated in `run-init-consumer-tests.ps1` and
  `run-wrapper-tests.ps1` (referenced the old `diagnose.md` location).

### Why
- User reported `/handoff` wasn't visible in Claude Code. Upstream
  installs skills to `~/.claude/skills/<name>/SKILL.md` (subdir per
  skill, with a SKILL.md inside). Our package was writing
  `.claude/skills/<name>.md` flat — Claude Code's skill discovery
  expects the subdir form for the YAML-frontmatter style used by
  upstream's recent skills.
- Now the three tools align with each other (all use subdir form) and
  with upstream's installer pattern, so future upstream syncs are
  simpler (no format translation step).

### Note on slash commands
- Skills (in `.claude/skills/<name>/SKILL.md`) are invoked via the
  Skill tool / natural language ("use the handoff skill"). They do
  NOT appear in Claude Code's `/` dropdown.
- The `/` dropdown only shows files in `.claude/commands/`. Our 2
  slash commands (`/update-myst-skills`, `/promote-myst-skills`) and
  the `sync-build-submit` UE overlay command live there.
- If you want a productivity skill (handoff, caveman, etc.) to appear
  in `/`, that would require creating a `.claude/commands/<name>.md`
  wrapper — not done in v2.1.0; can be added if real demand surfaces.

Tests: 184/184 across 12 suites (no test count change; just paths
updated in 4 test files).

## [2.0.1] - 2026-05-23 — install.ps1 fixes (surfaced during v2.0.0 live install)

### Fixed
- **`scripts/run-skeleton-preflight.ps1` P4HeadRev**: was crashing on
  `p4 fstat` when target file didn't exist in depot (e.g., files staged
  for `p4 add` but not yet submitted). `$ErrorActionPreference='Stop'` +
  native command non-zero exit promoted to a terminating error.
  Wrapped the fstat call in try/catch with local
  `$ErrorActionPreference='Continue'`; null is now returned correctly
  for missing/unknowable head revs.
- **`scripts/install.ps1` Update-ManifestForChanges scope**: the
  scriptblock callback passed to `Complete-JournalCommit` ran in a
  scope where `Update-ManifestForChanges` (dot-sourced into install.ps1's
  script scope) wasn't visible. The new fix dot-sources
  `lib/ManifestUpdate.ps1` at the call site inside the scriptblock,
  guaranteeing the function is bound regardless of caller scope.

### Why
- Both bugs surfaced during the v2.0.0 live install against
  UE_Blank_Proto -- the first end-to-end run of `update.ps1` against
  a real Perforce consumer with new files being added (not just
  edited). The fixture tests + previous installs only exercised edits
  on existing files; new-file paths weren't covered.

### Not changed
- Same content, same skills, same parity tests. Only install.ps1 +
  preflight script behavior. 184/184 tests still pass.

## [2.0.0] - 2026-05-23 — Full upstream sync (skill philosophy shift)

### MAJOR: Philosophy shift

v1.x shipped **minimal pointer skills** — 20-30 line entry files that
mostly said "read CONTEXT.md, follow project patterns." That was a
deliberate adaptation when we extracted the package at upstream commit
`e74f0061`. The assumption was that agents would faithfully read
CONTEXT.md + domain.md + ADRs for context.

v2.0.0 adopts upstream's **rich instruction set** approach. Each skill
is now a complete, self-contained instruction set (80-150 lines) that
doesn't depend on the agent reading sibling docs to produce good output.
More resilient to weaker models, more explicit about process and
vocabulary, more aligned with upstream maintenance going forward.

### Added (4 new productivity skills)
- **`/caveman`** — Ultra-compressed communication mode. Cuts token usage
  ~75% by dropping filler while keeping technical accuracy.
- **`/grill-me`** — Interview the user relentlessly about a plan or design
  until each branch of the decision tree resolves. Lighter than
  `/grill-with-docs` (no documentation updates).
- **`/handoff`** — Compact the current conversation into a handoff doc
  so another agent can continue the work. Useful for context-limit
  scenarios and agent-to-agent transitions.
- **`/write-a-skill`** — Create new skills with proper structure,
  progressive disclosure, bundled resources.

Each shipped in 3 tool formats (Claude flat `.md`, Codex flat `.md`,
OpenCode subdir `SKILL.md`). 12 new manifest entries, 4 new parity matrix
rows (3-way parity).

### Changed (8 engineering skills upgraded)
All replaced with their upstream rich versions:
- `/diagnose` (22 → 117 lines): full reproduce → minimise → hypothesise
  → fix process
- `/grill-with-docs` (23 → 88): full grilling protocol with
  CONTEXT.md/ADR update mechanics; references new
  `Docs/agents/grill-with-docs-context-format.md`
- `/improve-codebase-architecture` (21 → 81 + 4 sibling reference files):
  full Glossary (Module/Interface/Depth/Seam/Adapter/Leverage/Locality),
  4-step Process, HTML report mechanism with Tailwind+Mermaid CDN
- `/tdd` (22 → 109): full red-green-refactor loop with good-vs-bad
  test discussion
- `/to-issues` (26 → 83): vertical-slice issue breakdown protocol
- `/to-prd` (24 → 76): PRD template + synthesis-vs-interview rules
- `/triage` (31 → 103): state-machine triage with role conventions,
  needs-info templates, agent-brief format
- `/zoom-out` (20 → 7): upstream is much smaller; we replaced our
  expanded version with theirs. **This is the one case where we lost
  content**; recoverable from git history if needed.

### Added (5 reference files)
Shared by all tools via `templates/common/docs/agents/`:
- `ica/LANGUAGE.md` — full ICA vocabulary definitions
- `ica/DEEPENING.md` — refactoring patterns (shallow → deep)
- `ica/INTERFACE-DESIGN.md` — interface design guidance
- `ica/HTML-REPORT.md` — HTML output format spec (Tailwind+Mermaid)
- `grill-with-docs-context-format.md` — CONTEXT.md template
  reference (upstream trimmed at commit `e7df78b`)

### Changed (upstream tracking)
- `package-manifest.json`: `upstream.mattpocockSkills.pinnedCommit`
  bumped from `e74f0061` to `b8be62f`. Records the new baseline for
  future `check-mattpocock-updates.ps1` runs.
- `manifest-template.json`: same bump for installed consumer alignment.

### What stayed
- Our 2 workflows (`AgenticWorkflow.md`, `PlanPriority.md`) — package-
  specific, not from upstream.
- All overlay content (`perforce`, `ue`, `myst-project`) — package-
  specific.
- All lifecycle scripts (`setup.ps1`, `update.ps1`, `promote.ps1`) and
  the manifest schema — package-specific.
- The 2 slash commands (`/update-myst-skills`, `/promote-myst-skills`)
  — package-specific.

### Migration notes for v1.x consumers
- `update.ps1` will land all the new content. Expect a large CL.
- Skill outputs will be noticeably more structured going forward
  (HTML reports for ICA, explicit process steps, vocabulary discipline).
- Custom adaptations made to v1.x skill content will be overwritten.
  If you'd customized any of the 8 upgraded skills, the changes are
  gone — capture them as PRDs / ADRs in your project before updating.

### Why a major bump
This is a deliberate philosophy switch. v1.x ships minimal pointers;
v2.0 ships rich instruction sets. Same skill names, same slash commands,
but the agent-facing content is 5x larger and more directive. Anyone
who pinned v1.x for content stability should NOT auto-update to v2.0.

Tests: 184/184 across 12 suites (was 172/172 in v1.9.2). 12 new parity
rows.

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
