# myst-agentic-workflow

Reusable agentic-workflow scaffolding for **Codex**, **Claude Code**, and **OpenCode**.

This is the **source of truth**. Consuming projects receive a generated, installed
copy (checked into their own version control). The package is not required at
runtime by a consumer — install once, use forever.

## Provenance

This package was **extracted from a single project** — `Myst_Proto`, a UE5/Perforce
game project — and offered as a starting point for other consumers. The core
scaffolding (`templates/` + `overlays/perforce/` + `overlays/ue/`) is generic.
The repo also ships `overlays/myst-project/` as a worked example of a
project-specific overlay; **adopters should not install that overlay** unless
they ARE Myst_Proto. See [`overlays/myst-project/README.md`](overlays/myst-project/README.md).

The pragmatic framing: this is one team's reusable infrastructure, MIT-licensed
for others to adopt, fork, and adapt. It is not pretending to be a
provenance-free generic framework — the `myst-` prefix is honest about where it
came from.

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

## Three one-command lifecycle scripts

```powershell
git clone https://github.com/vladSirin/myst-agentic-workflow
$Pkg = "$PWD/myst-agentic-workflow"

# 1. First-time install (bootstrap manifest + write)
& "$Pkg/setup.ps1"   -TargetRoot c:/path/to/your-project [-Yes]

# 2. Sync upstream changes into your project
& "$Pkg/update.ps1"  -TargetRoot c:/path/to/your-project [-Yes]

# 3. Promote a local improvement back to the package
& "$Pkg/promote.ps1" -TargetRoot c:/path/to/your-project `
                     -Paths '.claude/skills/diagnose.md' [-Yes]
```

All three auto-detect what they need (overlays / tools / version control)
from the consumer's existing manifest. All three dry-run first, then prompt
before writing. `-Yes` skips the prompt for unattended runs.

For full control, the underlying scripts are exposed separately — see
[`docs/install.md`](docs/install.md) for the step-by-step paths,
[`docs/perforce-consumer.md`](docs/perforce-consumer.md) for UE/Perforce
specifics.

## Layout

```
myst-agentic-workflow/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── package-manifest.json          # schema v3 + package metadata
├── manifest-template.json         # canonical entry list for new consumers
├── setup.ps1                      # one-command first-time install
├── update.ps1                     # one-command upstream sync
├── promote.ps1                    # one-command promote local -> package
├── docs/                          # consumer-facing guides
│   ├── install.md                 # ~500-line install/update/promote guide
│   ├── perforce-consumer.md       # UE+P4 addendum
│   └── adr-0001-extract-reusable-core-decisions.md
├── templates/{common,codex,claude,opencode}/
├── overlays/{perforce,ue,myst-project}/
├── scripts/
│   ├── init-consumer.ps1          # generate bootstrap manifest from template
│   ├── install.ps1                # DryRun default; Write preflight-gated
│   ├── compare-with-package.ps1   # cross-repo drift + conflict report
│   ├── diff-installed.ps1         # local drift report
│   ├── promote-from-project.ps1   # promote local improvements upstream
│   ├── check-mattpocock-updates.ps1
│   ├── run-skeleton-preflight.ps1 # 10-point write-mode gate
│   └── run-*-tests.ps1            # 9 test suites, 81 tests total
└── fixtures/                      # E2E install fixtures
```

## Status

**v1.4.0** — three top-level lifecycle commands (`setup.ps1`, `update.ps1`, `promote.ps1`) covering install / sync / promote. Auto-derives configuration from the consumer's manifest. 95/95 tests green across 10 suites.

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
plan v1.6. The full design rationale is recorded in
[`docs/adr-0001-extract-reusable-core-decisions.md`](docs/adr-0001-extract-reusable-core-decisions.md).

For improvements: clone, edit, run `scripts/run-*-tests.ps1`, open a PR. The
package's contract with consumers is the manifest schema (v3) and the installer
output stability — additions are welcome; breaking changes need a major bump.
