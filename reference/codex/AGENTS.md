## Codex Workspace Setup

Two layers:

**1. Committed core** — arrives with version-control sync, nothing to do: this
file (the shared baseline — personal preferences go in `~/.codex/AGENTS.md`,
never here), team docs (`Docs/MustRead/`, `Docs/agents/`), `.claude/rules/`
(no auto-load under Codex — read the relevant rule file before working in its
domain).

**2. Dev kit** — the `myst-dev-kit` plugin, installed once per user: all team
skills. Install (once):

```
codex plugin marketplace add vladSirin/myst-agentic-workflow
```

then `/plugins` → Myst Team Plugins → install `myst-dev-kit` → new session.

### Personal layer (never version-controlled)

`~/.codex/AGENTS.md` (additive). `AGENTS.override.md` REPLACES the project file
entirely — escape hatch only, not for preferences. Improvements worth sharing
go back via the package's CONTRIBUTING.md gate.
