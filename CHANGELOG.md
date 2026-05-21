# Changelog

All notable changes to `myst-agentic-workflow`. Versioning: SemVer.

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
