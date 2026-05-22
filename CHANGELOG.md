# Changelog

All notable changes to `myst-agentic-workflow`. Versioning: SemVer.

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
