# templates/ (skeleton — not yet populated)

Canonical reusable content lives here. **Population is the next gated phase
(Extract Reusable Core), not part of the skeleton.**

- `common/docs/MustRead/` — single source for the human workflow guide. Installer
  transforms package-native lowercase `docs/` to the consumer's `Docs/`. There is
  no separate `MustRead` package root.
- `common/docs/agents/` — issue-tracker, triage-labels, domain, manifest schema.
- `codex/`, `claude/`, `opencode/` — thin tool wrappers generated from common
  content or declared deviations (see manifest `toolCapabilities`).

Until populated, the installer reports these as `missing package files` in dry-run.
