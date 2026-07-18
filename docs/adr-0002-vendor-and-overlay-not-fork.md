# ADR 0002 — Stay current with upstream by vendor-and-overlay, not fork or submodule

**Status**: Accepted

**Date**: 2026-06-21

**Context owners**: package maintainers

## Context

`myst-agentic-workflow` is a *transformed derivative* of [`mattpocock/skills`](https://github.com/mattpocock/skills), pinned at a commit recorded in `package-manifest.json` and `manifest-template.json` (`upstream.mattpocockSkills.pinnedCommit`). We carry a curated subset of upstream's skills, fanned out into three per-tool trees (`templates/claude/.claude/`, `templates/codex/.Codex/`, `templates/opencode/.opencode/`) with `{{var}}` substitution, plus a PowerShell installer, a manifest with drift detection, overlays (`core` — the base bucket — plus `perforce`, `ue`, `myst-project`, `tool-capability`), and a 12-suite test harness. None of that machinery exists upstream — we share *ideas and skill prose*, transformed, not files.

Two recurring questions forced this decision:

1. **How do we stay current with upstream without the package rotting?**
2. **Wouldn't a git fork or submodule "eliminate drift"?**

A completeness audit (2026-06-21) also exposed the cost of getting this wrong the *other* way: the original vendoring copied only each skill's `SKILL.md` and dropped its companion files, leaving load-bearing skills truncated (`diagnose` reduced to a 22-line stub) and ~9 classes of dangling intra-package links. So "how we vendor" is not academic — sloppy vendoring already cost us real content.

## Decision 1 — Vendor-and-curate, not fork

We keep the **vendor + pinned-commit + curate** model.

- **Rejected: git fork + `git merge upstream`.** A fork's merge model only works when our tree is structurally ~the same as upstream's. It is not: upstream is single-tree, we are 3-tool + placeholders + manifest, and ~80% of our repo (installer, manifest, tests, overlays) has no upstream counterpart. Every `git merge upstream/main` would conflict on essentially every file because our copies live at different paths in a different shape. A fork would *worsen* drift management, not eliminate it.
- **Rejected: git submodule.** A submodule pins a commit and checks upstream out *verbatim*. We cannot consume upstream verbatim — wrong shape, wrong place; we would still need the transform step (the actual work). It also forbids editing submodule contents (kills tailoring) and pins one whole-repo SHA all-or-nothing (kills per-file curation). It gives us only a pinned pointer, which we already have as a manifest field, while blocking the three things we need. Same reason a submodule was rejected informally in earlier discussion — we don't consume upstream as-is.
- **Rejected: "become a fork" (adopt upstream's single-tree shape + `npx` installer).** This is the only arrangement where a fork's merge actually works, but it means discarding the multi-tool fan-out, the manifest/overlay/installer system, drift detection, and the test suite — i.e. the ~80% of the repo that is the product's value.

**Key reframe:** staying current is a **curation** problem, not a **storage** problem. Fork / submodule / vendor only decide *where the pin lives* and *whether we may transform and edit*. None of them auto-decides "should we adopt upstream's restructure?" — that is a reviewed step every cycle regardless. We therefore pick the storage that permits transform + per-file curation + tailoring: vendor with a manifest.

## Decision 2 — Faithful base + overlay tailoring

The base layer is vendored **faithfully and completely** (every `SKILL.md` *and* its companion files — including non-`.md` companions like `scripts/*.sh`), in house format (Claude/Codex: `# <description>` H1 + `<command-name>` + body; OpenCode: YAML frontmatter + body). The **body prose is content-unedited**; only the per-tool wrapper differs, and (for parity) the OpenCode frontmatter `description` mirrors upstream's verbatim trigger text. Project-specific tailoring (UE5/Perforce/AAA) lives in the **overlay layer**, never by editing the base. Each base skill carries a generic, project-neutral footer pointing at same-dir addenda (any `*-NOTES.md` in the skill directory) — the overlay ships those notes.

**Faithful means name + body + architecture.** Faithfulness is not only a skill's name and prose but its *structure*: companion files keep upstream's layout — in the skill's own directory next to its `SKILL.md` (`./CONTEXT-FORMAT.md`, `./ADR-FORMAT.md`, `./AGENT-BRIEF.md`, `scripts/*.sh`, …) — **not flattened, dropped, or relocated** elsewhere in the tree. This keeps `compare-with-package.ps1` diffs clean against upstream and lets the skill resolve its own relative links wherever it installs. **Deviate from upstream's structure only with a specific, documented reason** (recorded in this ADR or the rejection memory); absent a reason, mirror upstream. The same rule covers naming — upstream-inherited skills track upstream's name (e.g. `diagnose` → `diagnosing-bugs`), accepting the breaking command change rather than letting our copy drift.

Why: editing the base directly is exactly what truncated our skills and broke our links. A faithful base makes `compare-with-package.ps1` produce clean diffs against upstream, makes each sync a reviewed patch instead of archaeology, and keeps divergence confined to clearly-owned overlay files.

- **Rejected: keep editing the base in place** (status quo) — the proven cause of truncation + dangling links.
- **Rejected: *blind, wholesale* resync to upstream HEAD** — copying HEAD as-is drops our curated subset-scope, ignores our documented deviations, and imports references to sibling skills we don't vendor. Note the nuance: *converging* to HEAD is allowed and expected **as a reviewed, curated event** (vendor the new dependencies, decide the deletions, re-apply overlays, bump the pin) — exactly how `diagnosing-bugs` reached HEAD. What's rejected is the *unreviewed* wholesale copy. "Faithful" means faithful to a **known pinned commit**, not to a moving "latest"; the pin is the controlled checkpoint we advance deliberately, not a thing we drift behind by accident.

**Known architecture drifts to reconcile** (pre-date this decision; flagged by the 2026-06-21 audit). Under "faithful means architecture", each must be either restored to upstream's same-dir layout during the re-vendor, or given a documented reason here:

- `improve-codebase-architecture` / `codebase-design` — **RESOLVED (v4.9.0)**: the live companions now sit in their skill dirs, upstream-style (`HTML-REPORT.md` in `improve-codebase-architecture/`, `DEEPENING.md` in `codebase-design/`), so the relative `SKILL.md` links resolve. The redundant `Docs/agents/ica/` copies and the two genuinely-unused docs (`LANGUAGE.md`, `INTERFACE-DESIGN.md` — referenced by nothing) were deleted.
- `grill-with-docs` — `CONTEXT-FORMAT.md` relocated to `templates/common/docs/`; `ADR-FORMAT.md` dropped entirely.
- `triage` — `AGENT-BRIEF.md` / `OUT-OF-SCOPE.md` dropped entirely.
- `tdd` — `tests.md` / `mocking.md` / `refactoring.md` / `deep-modules.md` / `interface-design.md` dropped.

## Decision 3 — Tailoring mechanism per file type

The engine offers `copy`, `full-file-override`, `generated-block`, `append-fragment`, and `manual-only` (tracked-for-awareness, never written). We choose by the file's ownership shape:

- **Co-owned root files** (`.p4ignore`, `AGENTS.md`, `CLAUDE.md`): `append-fragment` / `generated-block`. Proven (`overlays/ue/p4ignore.fragment`).
- **Package-owned skill files** (`SKILL.md`): the faithful base is `copy`; tailoring is a **same-directory overlay companion** the base links to (e.g. `diagnosing-bugs/UE-NOTES.md`), exactly how upstream's own skills reference `./CONTEXT-FORMAT.md`. The base carries a generic, project-neutral footer pointing at same-dir addenda.
- **`full-file-override`** is reserved for skills where upstream is fundamentally wrong for us. It is a maintained fork of that one file (you stop receiving upstream improvements), so it is the last resort.

**Engine gap recorded here (verified):** `append-fragment` cannot cleanly append to a `copy`-owned skill file. Root cause: each manifest entry carries exactly one `mergeStrategy` for one `path`, so a single file cannot be both whole-file `copy` (core) and `append-fragment` (overlay) — the two strategies on one path are unexpressible. The symptom: `Get-EntryRendered` re-renders a `copy` entry as the whole template every install, so on re-install the base overwrite drops any appended fragment (it self-heals within one pass but reports perpetual drift to `compare`). Hence the same-dir-companion choice for skills. A future engine enhancement (an idempotent "copy-with-overlay-append" strategy) could allow truly inline skill tailoring; until then, companions are the supported path.

## Operating principles

The rules that make "faithful vendor-and-overlay" actually hold. Decisions 1–3 establish the model; these govern day-to-day curation.

1. **Faithful = name + body + architecture** (Decision 2). Mirror upstream's command name, prose, *and* file/directory structure. Deviate only with a specific reason documented here or in the rejection memory.
2. **Sync is deliberate and curated, never a blind wholesale copy.** Advance the pin toward HEAD as a reviewed event; never auto-adopt HEAD in a way that drops subset-scope, ignores documented deviations, or imports unvendored references.
3. **Provenance is recorded, not implied.** Every vendored skill records which upstream commit it is faithful to. Per-skill divergence (e.g. a skill synced ahead of the package pin) is explicit, never silent.
4. **Completeness is part of faithful — no dangling references.** A skill may not reference a companion or sibling it doesn't ship. Enforce with a CI link-existence lint, not vigilance.
5. **Don't import what hard-binds to the unvendored.** If an upstream skill depends on a sibling we haven't vendored, either vendor that sibling too or don't adopt — never import a reference that can't resolve. This is the boundary of faithfulness.
6. **Curation is remembered.** Every reject/skip is recorded (content-hash keyed in `.scratch/agentic-scaffold-rejected-upstream.json`) so the next sync doesn't re-litigate it.
7. **Overlay isolation is one-directional.** Project specifics (UE5/Perforce/AAA) flow into overlays, never into the base. The base stays portable enough for a non-UE/non-Perforce team — that is what keeps it syncable.
8. **No change lands without green gates.** All test suites pass *and* a real install is idempotent (re-run = NO CHANGES) before merge.

Hygiene (not principles, but enforced): upstream-derived entries carry SPDX MIT attribution; the repo is CRLF — keep it.

## Consequences

- **Positive**: dangling-link / truncation bug class is eliminated at the root (faithful base ships every companion). Syncs become reviewed diffs. Divergence is isolated, owned, and visible. The decision is recorded so fork/submodule stops being re-litigated.
- **Negative**: the faithful base is larger (3× fan-out of complete skills + companions → more files, manifest rows, parity rows). Each `full-file-override` is a fork to maintain. Inline skill tailoring needs a companion file (or a future engine strategy), not an in-file append.
- **Process**: every sync = `check-mattpocock-updates.ps1` → `git diff <pin> upstream/main` → adopt/adapt/reject per file (rejects recorded in `.scratch/agentic-scaffold-rejected-upstream.json`) → fold adopted changes into the faithful base → bump the pin in **both** manifests → tests → ship via `update.ps1`. A pin is still reviewed, never auto-tracked to HEAD.
- **Reversibility**: fully reversible. If upstream's shape ever converges with ours, a fork becomes viable then; nothing here forecloses it. The companion-vs-append choice (D3) is localized and changeable per skill.

## Validation

This ADR ships with a worked prototype on the `diagnosing-bugs` skill (renamed from `diagnose` to match upstream's HEAD name — upstream-inherited skills track upstream naming faithfully to avoid drift). The truncated 22-line stub is replaced with the faithful upstream **HEAD (`6eeb81b`)** 6-phase discipline (base, `copy`, all three tools, plus its `scripts/hitl-loop.template.sh` companion), and the UE5/Perforce specifics move into a `ue`-overlay companion (`diagnosing-bugs/UE-NOTES.md`) that the base links to. It demonstrates the base/overlay split end-to-end and is covered by the existing parity/init/e2e suites. Note: this skill is intentionally synced ahead of the package pin (`b8be62f`) to the HEAD name+body; the package-wide pin bump is a separate deliberate sync.
