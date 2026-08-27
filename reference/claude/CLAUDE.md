## Claude Code Workspace Setup

Two layers:

**1. Committed core** — arrives with version-control sync, nothing to do:
`.claude/settings.json` (team hooks + plugin marketplace registration),
`.claude/rules/` (auto-loaded every session), `.claude/scripts/` (hook
validators), team docs (`Docs/MustRead/`, `Docs/agents/`).

**2. Dev kit** — the `myst-dev-kit` plugin, installed once per user:
`/plugin install myst-dev-kit@myst`. No `marketplace add` step when the
committed `extraKnownMarketplaces` pre-registers the `myst` marketplace;
otherwise run `claude plugin marketplace add vladSirin/myst-agentic-workflow`
once first. **Nothing installs itself when you trust the repo**; there is no
plugin prompt to accept. Restart the session afterwards — Claude loads a new
plugin version only at session start. Migrating from v4 of the kit: see the
package CHANGELOG's v5.0.0 section.

### Personal layer (never version-controlled)

`~/.claude/CLAUDE.md` and `CLAUDE.local.md` (additive personal instructions);
`.claude/settings.local.json` (personal hooks/permissions — to remove a hook
locally DELETE the key; an empty array is an active override that shadows team
hooks). Improvements worth sharing go back via the package's CONTRIBUTING.md
gate.
