# Team Setup — AI Tooling (Claude Code + Codex)

How to get the Myst team's AI setup on your machine. Two archetypes; pick yours.

## What you get, from where

| Layer | Delivered by | Contains |
|---|---|---|
| **Committed core** | Perforce sync (automatic) | Team `CLAUDE.md`/`AGENTS.md`, `.claude/settings.json` (hooks + marketplace registration), rules, hook scripts, team docs (`Docs/MustRead`, `Docs/agents`) |
| **Dev kit** | `myst-dev-kit` plugin (this repo) | 30 skills, both review agents, `sync-build-submit` + package commands, the Codex Submit-Audit warning bridge |
| **Personal kit** | you, outside Perforce | `~/.claude/`, `CLAUDE.local.md`, `.claude/settings.local.json`, own skills/plugins |

Governance is **advisory everywhere**: nothing blocks your work; non-compliant
submits are warned about in-session and posted to Feishu `#cl-audit` by the
server-side Submit-Audit.

## Standard user (sync and go)

1. `p4 sync` the project. The committed core arrives by itself.
2. Open the project in **Claude Code** and trust it. You should be prompted to
   install the `myst` marketplace / `myst-dev-kit` plugin — accept.
   **If no prompt appears** (known-flaky on some versions), it's one command:
   ```
   /plugin install myst-dev-kit@myst
   ```
   (No `marketplace add` needed — the committed settings pre-register it.)
3. Start a new session. Done. Verify with `/plugin` — `myst-dev-kit` enabled.

**Codex** (if you use it): the marketplace isn't auto-registered there — once:
```
codex plugin marketplace add vladSirin/myst-agentic-workflow
codex plugin add myst-dev-kit@myst
```
then start a new session. (`/plugins` → *Myst Team Plugins* → install works too.)
Verify with `codex plugin list` — `myst-dev-kit@myst` shows `installed, enabled`.

**Keeping Codex up to date** — one command, and it is *not* the same shape as Claude's:
```
codex plugin marketplace upgrade
```
That is the whole update. Codex has **no `plugin update` subcommand**; refreshing the
marketplace snapshot replaces the installed plugin in place — verified 4.18.0 → 4.19.0,
cache directory and all, with no follow-up `codex plugin add`. (Claude is the opposite:
`claude plugin update myst-dev-kit@myst`, and it needs a restart to take effect.)

**What Codex does and does not get.** The plugin delivers the skills, both reviewer
agents, the commands, and the Submit-Audit bridge. It does **not** give Codex the
always-on rules: Codex has no `.claude/rules/` equivalent and reads `AGENTS.md` only,
which is why every always-on rule needs an `AGENTS.md` counterpart (enforced by
`check-rule-parity.sh`). Project-level hooks are also unavailable — Codex loads hooks
from `~/.codex/hooks.json` and from installed plugins, never from a hooks file in the
repo (measured: a project `.codex/hooks.json` and a project `.agents/hooks.json` were
both ignored by a live session). Any repo-local hook a consuming project relies on is
Claude-only unless it ships through the plugin.

**Don't want the plugin?** Decline the prompt, or opt out permanently in your
`.claude/settings.local.json`:
```json
{ "enabledPlugins": { "myst-dev-kit@myst": false } }
```
The committed core (rules, hooks, audit) works regardless.

## Poweruser (bring your own kit)

Everything above, plus your personal layer — none of it touches Perforce:

- **`~/.claude/CLAUDE.md`** — global personal instructions (additive).
- **`CLAUDE.local.md`** at repo root — per-project personal instructions
  (additive; `.p4ignore`d).
- **`.claude/settings.local.json`** — personal hooks/permissions.
  ⚠ To remove a hook locally, DELETE the key — an empty array (`"PreToolUse": []`)
  is an active override that can shadow team hooks.
- **`~/.claude/skills/`** — personal skills. Note some may shadow-duplicate
  plugin skills in the skill list; harmless, but prune for clarity.
- **Codex personal layer**: `~/.codex/AGENTS.md` (additive). `AGENTS.override.md`
  REPLACES the project file — escape hatch only.
- Improved something generally useful? Push it back:
  see [CONTRIBUTING.md](CONTRIBUTING.md).

## Prerequisites & troubleshooting

- **Bash** (Git Bash/WSL) — the hooks and scripts need it.
- **GitHub access**: the marketplace repo is public today, so installs need no
  auth. If it goes private: get collaborator access + `gh auth login` once
  (plus `GITHUB_TOKEN` in your env if you want background auto-updates).
- **Plugin skills missing?** New sessions only — restart after install/update.
- **No Submit-Audit warning on a bad submit?** The warning renders as a dim
  collapsible line under the Bash call (expand it / ctrl-o). If genuinely
  absent, check your `settings.local.json` for empty hook-array overrides.
- **Feishu `#cl-audit`** is the team-visible audit trail; advisory, never blocks.

## Verify your install (2 minutes)

1. `/plugin` shows `myst-dev-kit` enabled at the current version.
2. Type `/` — dev-kit skills present (`tdd`, `grilling`, `review-and-submit`...).
3. Optional full check: submit a scratch CL with a tag-less description —
   expect ONE in-session warning + one Feishu message, and the submit succeeds.
