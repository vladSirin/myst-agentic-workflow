## Claude Code Workspace Setup

Two layers:

**1. Committed core** — arrives with version-control sync, nothing to do:
`.claude/settings.json` (team hooks + plugin marketplace registration),
`.claude/rules/` (auto-loaded every session), `.claude/scripts/` (hook
validators), team docs (`Docs/MustRead/`, `Docs/agents/`).

**2. Dev kit** — the `myst-dev-kit` plugin, installed once per user: all team
skills, reviewer agents, and commands. Install: `setup-devkit.ps1` — the
documented path, and the only one that also covers Codex/OpenCode — or
`/plugin install myst-dev-kit@myst` as a manual fallback. No `marketplace add`
step: the committed `extraKnownMarketplaces` pre-registers the `myst`
marketplace. **Nothing installs itself when you trust the repo**; there is no
plugin prompt to accept. Full onboarding: **SETUP.md in the
myst-agentic-workflow repo**.

**Upgrading a machine set up before v4.50.0** — run
`~/.claude/plugins/marketplaces/myst/scripts/migrate-project-scope-installs.ps1`
once (dry-run by default, `-Apply` to act; it backs up first, and re-running is
safe). It drops duplicate PROJECT-scope install records, which otherwise leave
install order deciding which payload loads with nothing reporting the winner.
**Run it only AFTER this repo's `enabledPlugins` removal has synced to your
workspace** — converge earlier and the next session recreates the records you
just removed.

### Personal layer (never version-controlled)

`~/.claude/CLAUDE.md` and `CLAUDE.local.md` (additive personal instructions);
`.claude/settings.local.json` (personal hooks/permissions — to remove a hook
locally DELETE the key; an empty array is an active override that shadows team
hooks). Improvements worth sharing go back via the package's CONTRIBUTING.md
gate.
