## Claude Code Workspace Setup

Two layers:

**1. Committed core** — arrives with version-control sync, nothing to do:
`.claude/settings.json` (team hooks + plugin marketplace registration),
`.claude/rules/` (auto-loaded every session), `.claude/scripts/` (hook
validators), team docs (`Docs/MustRead/`, `Docs/agents/`).

**2. Dev kit** — the `myst-dev-kit` plugin, installed once per user: all team
skills, reviewer agents, and commands. Install: accept the plugin prompt when
trusting the repo, or `/plugin install myst-dev-kit@myst`. Full onboarding
(both archetypes): **SETUP.md in the myst-agentic-workflow repo**.

### Personal layer (never version-controlled)

`~/.claude/CLAUDE.md` and `CLAUDE.local.md` (additive personal instructions);
`.claude/settings.local.json` (personal hooks/permissions — to remove a hook
locally DELETE the key; an empty array is an active override that shadows team
hooks). Improvements worth sharing go back via the package's CONTRIBUTING.md
gate.
