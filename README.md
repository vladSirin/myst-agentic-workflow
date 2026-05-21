# myst-agentic-workflow

Reusable agentic-workflow scaffolding for **Codex**, **Claude Code**, and **OpenCode**.

This is the **source of truth**. Consuming projects receive a generated, installed
copy (checked into their own version control). The package is not required at
runtime by a consumer — install once, use forever.

## What you get

- A consistent set of **agents, skills, workflows, and slash commands** across all
  three agentic CLIs, so a developer's setup looks the same in any project that
  adopts the package.
- **Block-scoped editing** of shared files (`CLAUDE.md`, `AGENTS.md`, `.p4ignore`)
  via a strict Marker Specification — the installer cannot corrupt human-authored
  content next to managed content.
- **Drift detection** (`compare-with-package.ps1`) and **promotion** of local
  improvements back upstream (`promote-from-project.ps1`).
- **Crash-safe writes** via `InstallJournal`: exclusive lock + staged temps +
  atomic rename + transactional rollback. A killed installer never leaves a
  half-installed scaffold.
- **Perforce integration** (`-UsePerforce -Changelist new`) for UE/P4 consumers;
  filesystem-only consumers run the same scripts without P4.

## Install

See [`docs/install.md`](docs/install.md) for the full guide. The TL;DR:

```powershell
$PkgRoot    = 'c:/path/to/myst-agentic-workflow'
$TargetRoot = 'c:/path/to/your-project'

# 1. Dry-run first
& "$PkgRoot/scripts/install.ps1" `
    -TargetRoot $TargetRoot -PackageRoot $PkgRoot `
    -Tools all -Overlays 'core' -Mode DryRun

# 2. If the dry-run looks right, write mode (preflight-gated)
& "$PkgRoot/scripts/install.ps1" `
    -TargetRoot $TargetRoot -PackageRoot $PkgRoot `
    -Tools all -Overlays 'core' -Mode Write
```

For Perforce/UE consumers, see [`docs/perforce-consumer.md`](docs/perforce-consumer.md).

## Layout

```
myst-agentic-workflow/
├── README.md
├── CHANGELOG.md
├── package-manifest.json          # schema v3
├── docs/                          # consumer-facing guides
│   ├── install.md                 # ~500-line install/update/promote guide
│   └── perforce-consumer.md       # UE+P4 addendum
├── templates/{common,codex,claude,opencode}/
├── overlays/{ue-perforce,myst-project}/
├── scripts/
│   ├── install.ps1                # DryRun default; Write preflight-gated
│   ├── compare-with-package.ps1   # cross-repo drift + conflict report
│   ├── diff-installed.ps1         # local drift report
│   ├── promote-from-project.ps1   # promote local improvements upstream
│   ├── check-mattpocock-updates.ps1
│   ├── run-skeleton-preflight.ps1 # 10-point write-mode gate
│   └── run-*-tests.ps1            # 8 test suites, 65 tests total
└── fixtures/                      # E2E install fixtures
```

## Status

**v1.0.0** — first stable release. 65/65 tests green across 8 suites.

- Marker Specification: implemented + 14/14 pathological fixtures pass.
- Install failure/recovery: implemented + 10/10 journal tests pass.
- Cross-repo drift detection: 4 outcomes + meta-conflict (5/5 tests).
- Promotion workflow: tracer-bullet end-to-end (4 + 5/5 tests).
- New-user fixture: 6/6 pass; install + render + compare round-trip clean.

## License

MIT. Includes content adapted from [`mattpocock/skills`](https://github.com/mattpocock/skills)
(MIT, pinned at commit `e74f0061`). Attribution preserved in adapted files.

## Contributing

This package was extracted from a live UE5/Perforce project (`Myst_Proto`) under
plan v1.6. The full design rationale is recorded in the consumer's
[`Docs/adr/0001-extract-reusable-core-decisions.md`](https://github.com/vladSirin/myst-agentic-workflow/blob/main/docs/adr-0001-extract-reusable-core-decisions.md)
(when published).

For improvements: clone, edit, run `scripts/run-*-tests.ps1`, open a PR. The
package's contract with consumers is the manifest schema (v3) and the installer
output stability — additions are welcome; breaking changes need a major bump.
