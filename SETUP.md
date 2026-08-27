# Team Setup — AI Tooling (Claude Code + Codex + OpenCode)

How to get the Myst team's AI setup on your machine, whichever tool(s) you use.

## What you get, from where

| Layer | Delivered by | Contains |
|---|---|---|
| **Committed core** | Perforce sync (automatic) | Team `CLAUDE.md`/`AGENTS.md`, `.claude/settings.json` (hooks + marketplace registration), rules, hook scripts, team docs (`Docs/MustRead`, `Docs/agents`) |
| **Dev kit** | the `myst-dev-kit` plugin (this repo) | the skills library — delivery workflow, publication protocols, engineering/productivity skills, the vendored code-review engine |
| **Personal layer** | you, outside Perforce | `~/.claude/`, `CLAUDE.local.md`, `.claude/settings.local.json`, personal skills/plugins |

Governance is **advisory everywhere**: nothing blocks your work; the server-side
audit reports non-compliant submits to Feishu `#cl-audit` after the fact.

## Install (once per user, per tool)

- **Claude Code**: type `/plugin install myst-dev-kit@myst` into the chat box,
  then restart the session. No `marketplace add` step inside team projects — the
  committed `.claude/settings.json` pre-registers the `myst` marketplace via
  `extraKnownMarketplaces`, and that is the only thing it pre-registers (plugins
  like `context7` come from the built-in `claude-plugins-official` marketplace).
  **Nothing installs itself when you trust the repo** — there is no plugin
  prompt to accept. Outside a team project, register first:
  `claude plugin marketplace add vladSirin/myst-agentic-workflow`.
- **Codex**:

  ```
  codex plugin marketplace add vladSirin/myst-agentic-workflow
  codex plugin add myst-dev-kit@myst
  ```

  then a new session. Codex reads `AGENTS.md` natively from the synced project.
- **OpenCode**: `npx skills add vladSirin/myst-agentic-workflow` — pick the
  skills you want; they install at personal scope and OpenCode auto-scans them.
  OpenCode also reads the project's `AGENTS.md` natively.

## Update

- **Claude Code** — two steps, then restart:
  `claude plugin marketplace update myst` then
  `claude plugin update myst-dev-kit@myst`. The marketplace refresh alone moves
  nothing you have installed.
- **Codex** — one step: `codex plugin marketplace upgrade`. There is no separate
  plugin-update subcommand; the marketplace refresh replaces the install.
- **npx consumers** — re-run the add command.

What "latest" means is authoritative in the [CHANGELOG](CHANGELOG.md) head,
republished per tag on the
[Releases page](https://github.com/vladSirin/myst-agentic-workflow/releases).

## Migrating from v4

If this machine had the v4 kit (installer scripts, the dedicated clone at
`~/.myst-agentic-workflow`, generated reviewer agents):

1. Fetch `retire-legacy.ps1` from this repo and run it with `-WhatIf`
   (report-only), then without. It refuses to touch state it cannot prove
   committed and backs up configs before writing.
2. Run your tool's install one-liner above.

Details: the CHANGELOG's v5.0.0 section. Also check `CLAUDE.local.md` and
`~/.claude/CLAUDE.md` for references to commands v5 removed.

## Per-tool notes

- **Claude Code** is the fully-loaded tool: always-on rules (`.claude/rules/`),
  team hooks, and the plugin's skills.
- **Codex / OpenCode** read `AGENTS.md` (the same baseline; parity is maintained
  in the depot) plus the plugin's skills. Both spawn the review protocol's
  sub-agents natively; Codex may need `features.multi_agent_v2` enabled in
  `~/.codex/config.toml` once.
- **Opt out** (Claude): `{ "enabledPlugins": { "myst-dev-kit@myst": false } }`
  in `.claude/settings.local.json`. The committed core works regardless.

## Personal layer (never version-controlled)

- **`~/.claude/CLAUDE.md`** — global personal instructions (additive).
- **`CLAUDE.local.md`** at repo root — per-project personal instructions
  (additive; `.p4ignore`d).
- **`.claude/settings.local.json`** — personal hooks/permissions.
  ⚠ To remove a hook locally, DELETE the key — an empty array
  (`"PreToolUse": []`) is an active override that shadows team hooks.
- **`~/.claude/skills/`, `~/.agents/skills/`** — personal skills; personal scope
  overrides project scope in resolution order, so your choice always wins.
- **Codex**: `~/.codex/AGENTS.md` (additive). `AGENTS.override.md` REPLACES the
  project file — escape hatch only.
- Improved something generally useful? Push it back:
  see [CONTRIBUTING.md](CONTRIBUTING.md).

## Verify your install (1 minute)

1. Claude: `/plugin` shows `myst-dev-kit` at the current version; typing `/`
   lists dev-kit skills (`tdd`, `grilling`, `review-and-submit`...).
2. Codex: `codex plugin list` shows `myst-dev-kit@myst` installed.
3. OpenCode: `opencode debug skill` lists the skills you added.
4. Optional full check: submit a scratch CL with a tag-less description —
   expect one Feishu `#cl-audit` message, and the submit succeeds (advisory,
   never blocks).
