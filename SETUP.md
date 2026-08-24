# Team Setup — AI Tooling (Claude Code + Codex + OpenCode)

How to get the Myst team's AI setup on your machine, whichever tool(s) you use.

## What you get, from where

| Layer | Delivered by | Contains |
|---|---|---|
| **Committed core** | Perforce sync (automatic) | Team `CLAUDE.md`/`AGENTS.md`, `.claude/settings.json` (hooks + marketplace registration), rules, hook scripts, team docs (`Docs/MustRead`, `Docs/agents`) |
| **Dev kit** | `myst-dev-kit` plugin / `setup-devkit.ps1` (this repo) | 30 skills, the two reviewer agents (Claude native; generated for Codex + OpenCode — see below), `sync-build-submit` + package commands, the Submit-Audit warning bridge (Codex; verified firing 2026-08-06) |
| **Personal kit** | you, outside Perforce | `~/.claude/`, `CLAUDE.local.md`, `.claude/settings.local.json`, `~/.config/opencode/`, own skills/plugins |

Governance is **advisory everywhere**: nothing blocks your work; non-compliant
submits are warned about in-session and posted to Feishu `#cl-audit` by the
server-side Submit-Audit.

The full skills catalog (all 24, with when-to-use guidance) lives in the package
README's [Reference section](README.md#reference).

## ONE command, every tool

Once per machine (and again any time you want to update — install and update are
the same run):

```powershell
git clone https://github.com/vladSirin/myst-agentic-workflow "$env:USERPROFILE\.myst-agentic-workflow"
& "$env:USERPROFILE\.myst-agentic-workflow\setup-devkit.ps1"
```

The script detects which AI CLIs are on PATH and drives each tool's NATIVE
mechanism — it never replaces the tools' own plugin managers, it saves you from
remembering three different command sets:

| Detected tool | What the script does |
|---|---|
| Claude Code | `claude plugin marketplace update myst`, then install-if-missing / `claude plugin update myst-dev-kit@myst`. Reminds you to restart the session. |
| Codex | `codex plugin marketplace add` (tolerated if registered) + `codex plugin marketplace upgrade` + always attempts `codex plugin add` (harmless when installed; fails loudly only if the list still says `not installed`), then generates the two reviewer agents as `~/.codex/agents/*.toml` (`sandbox_mode = "read-only"`). |
| OpenCode | Checks the clone out at the latest release tag, registers the 30 skills via `skills.paths` in `~/.config/opencode/opencode.json`, writes the unreal-engine MCP entry and the manual-skill ask-map, generates the two reviewer agents, then self-verifies delivery. |

One tool failing does not abort the others; the summary names any failed leg.
`-Tool claude|codex|opencode` scopes to one tool; `-Version vX.Y.Z` pins or rolls
back; `-Uninstall` removes everything the script added (the clone stays).

**Claude-only and allergic to scripts?** You never need this one: `p4 sync`, open
the project, accept the plugin prompt — that zero-touch path still works and stays
current via `claude plugin update`. The script is the unifier for updates,
multi-tool users, Codex/OpenCode agent generation, and OpenCode setup.

## Just ask the agent (fastest path)

After `p4 sync`, you don't have to remember any of this. Paste into your tool:

> **Install or update my myst dev kit (run setup-devkit.ps1 from the package
> clone, or clone it first if missing), verify the result, and tell me what I
> still have to do myself.**

Two things it **cannot** do, so expect them:

- **Restart your Claude session.** Claude loads the new version on the next
  session start; the agent will tell you, but you have to do it. (Codex applies
  upgrades in place; OpenCode reads the clone live.)
- **Approve its own commands.** You may get a permission prompt the first time.

## Per-tool notes (the mechanics under the one command)

### Claude Code

- Install: accept the trust-prompt plugin install, or `/plugin install myst-dev-kit@myst`
  (no `marketplace add` needed — the committed settings pre-register it).
- Update — TWO steps, then a restart (the marketplace refresh alone updates
  nothing you have installed; the plugin update without the refresh only sees the
  old snapshot):
  ```
  claude plugin marketplace update myst
  claude plugin update myst-dev-kit@myst
  ```
  What "latest" means is authoritative in ONE place: the CHANGELOG head in your
  marketplace clone (`~/.claude/plugins/marketplaces/myst/CHANGELOG.md`) — and on
  the [GitHub Releases page](https://github.com/vladSirin/myst-agentic-workflow/releases),
  which republishes each tagged version.
- Opt out: `{ "enabledPlugins": { "myst-dev-kit@myst": false } }` in
  `.claude/settings.local.json`. The committed core works regardless.

### Codex

- Install (once): `codex plugin marketplace add vladSirin/myst-agentic-workflow`,
  then `codex plugin add myst-dev-kit@myst`, new session.
- Update — ONE command, *not* the same shape as Claude's:
  ```
  codex plugin marketplace upgrade
  ```
  Codex has **no `plugin update` subcommand**; refreshing the marketplace snapshot
  replaces the installed plugin in place (verified 4.18.0 → 4.19.0).
- **What Codex gets**: the skills, the commands, the Submit-Audit bridge
  (verified firing 2026-08-06), and — via `setup-devkit.ps1` — the two reviewer
  agents generated as `~/.codex/agents/*.toml` (`sandbox_mode = "read-only"`,
  body verbatim from the shared source; ask a session to "run
  architecture-reviewer on this change" to spawn one). The inline
  `review-changes` skill remains the review fast path and the fallback whenever
  the agents are not installed.
- **What Codex does NOT get**: the always-on rules (`.claude/rules/*.md` reaches
  Claude only; Codex reads `AGENTS.md`, which is why every always-on rule has an
  `AGENTS.md` counterpart, enforced by `check-rule-parity.sh`) and project-level
  hooks (measured: repo-committed hook files are ignored; hooks reach Codex only
  through the plugin).

### OpenCode

Everything arrives via `setup-devkit.ps1` (above) plus what OpenCode reads
natively from the synced project — `AGENTS.md` (same rules baseline as Codex,
same parity guarantee). Daily use is nothing: `cd` the project, run `opencode`.
Updates: re-run the script; because `skills.paths` and the generated agents read
the dedicated clone, the tag checkout IS the update.

Known gaps, deliberate (same posture as Codex where applicable):

| Gap | Status |
|---|---|
| Blocking hooks (`check-raw-protect.sh`, `check-script-standard.sh`) and `normalize-eol.sh` do not run | Same as Codex. Server-side Submit-Audit still covers submits. A JS guard plugin (`myst-guards.mjs`, spawning the same `.claude/scripts/*.sh`) is the designed follow-up — built when a user actually trips a guard, or immediately if OpenCode's edit tool proves to flip CRLF on this P4 repo. |
| Reviewer subagents | **Delivered** — generated opencode-native files (`mode: subagent`, `permission: edit deny`) under `~/.config/opencode/agents/myst/`; spawn them as `myst/architecture-reviewer` / `myst/radical-design-critic`. The shared Claude agent files are never loaded directly. On machines that ALSO run Claude Code, OpenCode surfaces the Claude plugin's own agent copies as `myst-dev-kit:<name>` — measured resolving with `edit: true` (Claude's `tools:` string does not restrict them there), so the script ships them **disabled** in your config; use the `myst/` variants. |
| `disable-model-invocation` on the 9 designed-manual skills is ignored by OpenCode | Restored as a `permission.skill` ask-map written by the script — OpenCode asks before auto-firing a workflow-gate skill (`to-spec`, `to-tickets`, `triage`, `implement`, `handoff`, ...). |
| Slash commands | Not delivered — all 3 are maintainer/build-machine commands; nothing user-facing is lost. |
| Rules full text | `AGENTS.md` tier (native). Full `.claude/rules/*.md` auto-load costs ~9.5k tokens/session, 65% of it path-scoped rules that should not load unconditionally — available as a personal `instructions` glob in your own config if you want it anyway. |

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
- **OpenCode personal layer**: `~/.config/opencode/opencode.json` (the script
  merges around your keys and backs the file up first; a JSONC config with
  comments is never rewritten — the script prints the snippet for you to paste),
  `~/.config/opencode/AGENTS.md` (global rules, additive).
- Improved something generally useful? Push it back:
  see [CONTRIBUTING.md](CONTRIBUTING.md).

## Prerequisites & troubleshooting

- **git** — for the package clone (`setup-devkit.ps1` clones/updates it).
- **Bash** (Git Bash/WSL) — the hooks and scripts need it.
- **GitHub access**: the marketplace repo is public today, so installs need no
  auth. If it goes private: get collaborator access + `gh auth login` once
  (plus `GITHUB_TOKEN` in your env if you want background auto-updates).
- **Plugin skills missing?** New sessions only — restart after install/update.
- **OpenCode not seeing the kit?** `opencode debug skill` should list the myst
  skills and `opencode agent list` the two reviewers; if not, re-run
  `setup-devkit.ps1` (it self-verifies and names what failed).
- **No Submit-Audit warning on a bad submit?** The warning renders as a dim
  collapsible line under the Bash call (expand it / ctrl-o). If genuinely
  absent, check your `settings.local.json` for empty hook-array overrides.
- **Feishu `#cl-audit`** is the team-visible audit trail; advisory, never blocks.

## Verify your install (2 minutes)

1. Claude: `/plugin` shows `myst-dev-kit` enabled at the current version; typing
   `/` lists dev-kit skills (`tdd`, `grilling`, `review-and-submit`...).
2. Codex: `codex plugin list` shows `myst-dev-kit@myst` installed; with the
   script run, `~/.codex/agents/architecture-reviewer.toml` exists.
3. OpenCode: `opencode debug skill` lists the myst skills;
   `opencode agent list` shows `architecture-reviewer` and
   `radical-design-critic`; in the project, ask "what hard rules apply" and it
   answers from `AGENTS.md`.
4. Optional full check: submit a scratch CL with a tag-less description —
   expect ONE in-session warning + one Feishu message, and the submit succeeds.
