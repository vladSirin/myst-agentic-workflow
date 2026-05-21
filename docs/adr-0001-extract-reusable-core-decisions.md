# ADR 0001 — Extract Reusable Core: design decisions

**Status**: Accepted
**Date**: 2026-05-21
**Author**: sxc (decisions ratified via `/grill-with-docs` session on issue 07)
**Context**: Agentic-scaffold-migration package, Extract Reusable Core phase (plan v1.6 lines 804–815)
**Related**: [`plan_agentic_scaffolding_packaging_WIP.md`](../../Myst_Proto/Docs/plan_agentic_scaffolding_packaging_WIP.md), [issue 07](../../.scratch/agentic-scaffold-migration/issues/07-extract-reusable-core.md)

---

## Context

After the Skeleton phase closed (10/10 preflight green, CL 947 submitted), the Extract Reusable Core phase needed five design decisions before implementation. Each had real alternatives and meaningful consequences. This ADR records them.

## Decision 1 — CL slicing strategy

**Decision**: Tracer-bullet, 4 slices: Codex → Claude → OpenCode → Overlays. Each slice produces a working end-to-end install-and-verify cycle for one tool's content (plus any new shared common files).

**Alternatives considered**:
- **One large CL** — rejected: all-or-nothing risk; a bug in any one tool's substitution invalidates the whole submission.
- **One CL per overlay** (`common`, `codex`, `claude`, `opencode`, `myst-project`, `ue-perforce`) — rejected: too granular; no overlay is verifiable alone, the unit of verification is "a working install for at least one tool."

**Why tracer-bullet**: matches the project's existing pattern (`weapon-equip-as-refactor` ran 7 vertical issues; `MustRead_agentic_workflow.md` codifies tracer-bullet). Each slice's success criterion is concrete and falsifiable: *"re-install for this tool produces a byte-identical reproduction of the current scaffold."*

**Outcome**: 73/73 byte-identical across all 4 slices verified by `_slice1_extract.py`.

## Decision 2 — Boundary call for `CLAUDE.md` / `AGENTS.md`

**Decision**: Keep the current marker placement — block = "Workspace Setup" section only (lines 285–412 of `CLAUDE.md`, lines 5–132 of `AGENTS.md`). Pre-block project-bible content and post-block "MCP Rules" / "Project Overview" / "Directory Structure" content stay project-owned, outside the package.

**Alternatives considered**:
- **Widen** the block to include the duplicated ~25-line post-block content — rejected: trades small DRY win for larger blast radius on every install of a co-owned file.
- **Narrow** by sub-dividing the section into reusable-core + per-tool overlay regions — rejected: creates a sub-boundary that's even harder to delimit cleanly, more parser edge cases.

**Why Keep**: the pre-block content in `CLAUDE.md` is deeply project-flavored (Code Complete, Taleb, Dalio principles); packaging it would force every consumer to inherit Myst's coding philosophy. The block as marked captures the structurally parallel agentic scaffolding (workflows / agents / skills tables) that differs only by tool-name substitutions, the perfect parameterization shape.

## Decision 3 — Parameterization mechanism

**Decision**: Simple `{{var}}` substitution — exact-string replacement, no escaping, no regex, no conditionals, no engine. Implemented as `Expand-TemplateVars` in `Markers.ps1` (~5 lines).

**Alternatives considered**:
- **Full templating engine** (Handlebars / Jinja) — rejected as overkill (YAGNI). No conditionals or loops needed for the current scaffold. Adds a runtime dependency to ship/version. Can graduate to an engine later — A's substitutions remain valid in B.
- **Per-tool concrete templates** with no shared source — rejected: reproduces the very drift problem the package is trying to solve (CLAUDE.md / AGENTS.md drift in parallel by convention only).

**Variables in scope today**: one — `{{game_docs_root}}` mapped to `installedProject.gameDocsRoot`. The implementation declares the substitution map from `installedProject` fields; consuming projects override these via their installed manifest.

## Decision 4 — Review gate

**Decision**: Lightweight scoped review using `architecture-reviewer` (code-review oriented) after write-mode integration is implemented; **not** a full `radical-design-critic` re-review of the entire Extract Reusable Core phase.

**Alternatives considered**:
- **No review** — rejected: write-mode enablement crosses the report-only / modify-live boundary; the highest-blast-radius transition in the workstream. Skipping a review here would be a "skin in the game" failure.
- **Full radical-design-critic re-review** — rejected as overkill: the substantive design (schema, markers, journal) was already reviewed across 5 rounds during Skeleton. Re-reviewing template extraction wastes a critic round on mechanical work.

**Outcome**: review found 3 BLOCKING + 2 WARNING + 1 pre-existing INFO. **All 5 review findings were fixed in-session** (issue 07 work-completed section); the integration is significantly safer for the gate having existed.

## Decision 5 — Phase sequencing vs. UE/Perforce Overlay phase

**Decision**: The plan v1.6 "Add UE/Perforce Overlay" phase (lines 817–828) is **absorbed into this Extract Reusable Core work** via slice 4. No separate phase needed.

**Rationale**: slice 4 populated `overlays/ue-perforce/` with all 10 files (sync-build-submit, ChangelistVerification, ReviewAndSubmit, VersionControlRule × Codex/Claude/OpenCode, plus the `.p4ignore` fragment). The deliverable *"preserve ability to install core package without UE/Perforce assumptions"* was already verified — every slice ran `--overlays core` only and produced byte-identical results. The plan's separate-phase modeling was conservative; the work fits inside the tracer-bullet approach.

**Pattern precedent**: CL 882 absorbed the "Audit" phase (plan v1.6 line 732); this is the same pattern repeating.

**Remaining downstream phases**: "Promotion Workflow" (plan phase 4) and "Documentation and Review" (plan phase 5) remain distinct.

---

## Consequences

- **Positive**: the package now contains a faithful, parameterized representation of the live scaffold. Re-rendering reproduces disk content byte-for-byte. Write-mode is enabled for `copy` strategy with a runtime preflight gate.
- **Negative**: write-mode for `generated-block` / `append-fragment` is **gated behind issue 08** (`ManifestUpdateAction` implementation). The two highest-value write cases (`CLAUDE.md` / `AGENTS.md` block updates, `.p4ignore` fragment updates) cannot ship until that follow-up resolves.
- **Surprising for future readers**: the `{{var}}` substitution map currently has only one variable (`{{game_docs_root}}`). The Q3 decision was to use simple substitution; the small variable set is correct, not an oversight — most reusable-core content is genuinely tool-or-project-agnostic.
- **Reversibility**: the boundary call (D2) is moderately reversible — moving markers means a new CL changing the three target files and re-validating hashes. The substitution mechanism (D3) is the most reversible — graduating from `{{var}}` to a templating engine is a localized change to `Expand-TemplateVars` plus a re-run of all template renders. The slicing pattern (D1) is fully reversible after the fact — only affects how this CL was reviewed.
