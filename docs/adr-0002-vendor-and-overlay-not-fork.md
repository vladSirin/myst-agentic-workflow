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

Why: editing the base directly is exactly what truncated our skills and broke our links. A faithful base makes `compare-with-package.ps1` produce clean diffs against upstream, makes each sync a reviewed patch instead of archaeology, and keeps divergence confined to clearly-owned overlay files.

- **Rejected: keep editing the base in place** (status quo) — the proven cause of truncation + dangling links.
- **Rejected: full-resync to upstream HEAD** — HEAD is a disruptive restructure (renames, stub-ification, deletions, hard binds to unvendored sibling skills) we reviewed and largely declined; resyncing trades reachable vendored content for unvendored refs.

## Decision 3 — Tailoring mechanism per file type

The engine offers `copy`, `full-file-override`, `generated-block`, `append-fragment`, and `manual-only` (tracked-for-awareness, never written). We choose by the file's ownership shape:

- **Co-owned root files** (`.p4ignore`, `AGENTS.md`, `CLAUDE.md`): `append-fragment` / `generated-block`. Proven (`overlays/ue/p4ignore.fragment`).
- **Package-owned skill files** (`SKILL.md`): the faithful base is `copy`; tailoring is a **same-directory overlay companion** the base links to (e.g. `diagnosing-bugs/UE-NOTES.md`), exactly how upstream's own skills reference `./CONTEXT-FORMAT.md`. The base carries a generic, project-neutral footer pointing at same-dir addenda.
- **`full-file-override`** is reserved for skills where upstream is fundamentally wrong for us. It is a maintained fork of that one file (you stop receiving upstream improvements), so it is the last resort.

**Engine gap recorded here (verified):** `append-fragment` cannot cleanly append to a `copy`-owned skill file. Root cause: each manifest entry carries exactly one `mergeStrategy` for one `path`, so a single file cannot be both whole-file `copy` (core) and `append-fragment` (overlay) — the two strategies on one path are unexpressible. The symptom: `Get-EntryRendered` re-renders a `copy` entry as the whole template every install, so on re-install the base overwrite drops any appended fragment (it self-heals within one pass but reports perpetual drift to `compare`). Hence the same-dir-companion choice for skills. A future engine enhancement (an idempotent "copy-with-overlay-append" strategy) could allow truly inline skill tailoring; until then, companions are the supported path.

## Consequences

- **Positive**: dangling-link / truncation bug class is eliminated at the root (faithful base ships every companion). Syncs become reviewed diffs. Divergence is isolated, owned, and visible. The decision is recorded so fork/submodule stops being re-litigated.
- **Negative**: the faithful base is larger (3× fan-out of complete skills + companions → more files, manifest rows, parity rows). Each `full-file-override` is a fork to maintain. Inline skill tailoring needs a companion file (or a future engine strategy), not an in-file append.
- **Process**: every sync = `check-mattpocock-updates.ps1` → `git diff <pin> upstream/main` → adopt/adapt/reject per file (rejects recorded in `.scratch/agentic-scaffold-rejected-upstream.json`) → fold adopted changes into the faithful base → bump the pin in **both** manifests → tests → ship via `update.ps1`. A pin is still reviewed, never auto-tracked to HEAD.
- **Reversibility**: fully reversible. If upstream's shape ever converges with ours, a fork becomes viable then; nothing here forecloses it. The companion-vs-append choice (D3) is localized and changeable per skill.

## Validation

This ADR ships with a worked prototype on the `diagnosing-bugs` skill (renamed from `diagnose` to match upstream's HEAD name — upstream-inherited skills track upstream naming faithfully to avoid drift). The truncated 22-line stub is replaced with the faithful upstream **HEAD (`6eeb81b`)** 6-phase discipline (base, `copy`, all three tools, plus its `scripts/hitl-loop.template.sh` companion), and the UE5/Perforce specifics move into a `ue`-overlay companion (`diagnosing-bugs/UE-NOTES.md`) that the base links to. It demonstrates the base/overlay split end-to-end and is covered by the existing parity/init/e2e suites. Note: this skill is intentionally synced ahead of the package pin (`b8be62f`) to the HEAD name+body; the package-wide pin bump is a separate deliberate sync.
