# Tool capability matrix — what the kit delivers to Claude vs Codex vs OpenCode

`myst-dev-kit` ships one tree, two plugin manifests (Claude, Codex), and one script-driven
delivery path (`setup-devkit.ps1` — which also carries the generated reviewer agents for
Codex and OpenCode, and everything OpenCode receives). The loaders differ, so **the tools
do not receive the same capabilities**, and the differences are deliberate. This file is
the record of which, and on what evidence.

`scripts/check-plugin-parity.ps1` asserts this matrix against the package tree. It verifies
*declarations and files* — what is shipped and what is claimed. It cannot verify runtime
behaviour in either host; that is what the evidence column is for.

## Evidence classes

Borrowed from the Blueprint-pin rule, because the failure mode is identical — a confident,
specific, source-derived claim that turns out to be wrong.

- **measured** — someone ran it in the live host and observed the result.
- **declared** — the manifest states it; the loader is assumed to honour its own schema.
- **convention** — no declaration; the host is assumed to discover the directory.
- **unverified** — believed, never run. Treat as a hypothesis.

> **"measured by absence" is not one of these classes.** It appeared in this table twice and
> was wrong both times: the `agents/` row asserted Codex "has no subagent mechanism" because
> no one had found one, and 4.25.0 stripped the two reviewer agents from the Codex plugin
> description on that basis — while `~/.codex/agents/` held 22 of them. Not finding a thing is
> evidence about the search, not about the thing. A negative claim needs a **control**: name
> something you *would* have found by the same method, and show that you found it. (The
> `PLUGIN_ROOT` correction in 4.26.0 is the pattern — the zero was only meaningful because
> `CODEX_HOME` returned 53 by the identical grep.) With no control, the row is `unverified`.

## The matrix

| Capability | Count | Claude | Codex | OpenCode | Evidence |
|---|---|---|---|---|---|
| `skills/` | 24 | convention (no `skills` key in `.claude-plugin/plugin.json`) | **declared** — `"skills": "./skills/"` | **declared** — `skills.paths` in the user's global `opencode.json` (written by `setup-devkit.ps1`) points at the dedicated clone's `skills/`; scanned `**/SKILL.md`, unknown frontmatter keys ignored, malformed skills log-and-skip | declared (Codex, OpenCode) / convention (Claude). OpenCode `disable-model-invocation` is NOT honoured — restored as a `permission.skill` ask-map the script writes |
| `hooks/` | 1 entry | plugin hooks load; project `.claude/settings.json` hooks **also** load | **declared** — `"hooks": "./hooks/hooks.json"`. Project-level hooks **never** load | **not delivered** — OpenCode has no shell-hook mechanism at all (its `experimental` config schema has no hook key; plugins are JS). Fallback below | **measured (2026-08-06)** — plugin hook observed firing under Codex end-to-end (see below). Project-level hooks separately measured NOT to load: `.codex/hooks.json` and `.agents/hooks.json` were each placed in a repo and a live `codex exec` run for both; neither fired. OpenCode absence: source-derived from its config schema + plugin docs (2026-08-20) |
| `commands/` | 3 | convention | convention | **not delivered, deliberate** — all 3 commands are maintainer/build-machine-facing; nothing user-facing is lost. Revisit if a user-facing command ever ships | **unverified** (Claude/Codex) — neither manifest declares `commands`, and no one has confirmed Codex discovers them. OpenCode: decision, not a discovery gap |
| `agents/` | 2 | convention — `architecture-reviewer`, `radical-design-critic` (native, `tools:` restriction intact) | **generated** — `setup-devkit.ps1` writes `~/.codex/agents/*.toml` (`name`/`description`/`developer_instructions` + `sandbox_mode = "read-only"`), body verbatim from shared source. The shared `.md` files themselves remain inert under Codex | **generated** — `setup-devkit.ps1` writes `~/.config/opencode/agents/myst/*.md` (`mode: subagent`, `permission: edit deny`, schema-valid `color`), body verbatim. The shared `.md` files are NEVER loaded directly — their `color: green|purple` violates OpenCode's color schema and a declared-key type error in the global agents dir hard-fails OpenCode machine-wide (source-traced) | Codex TOML agent schema: **declared** per official subagent docs (probed 2026-08-21; earlier local probe of codex-cli 0.147.0 found no CLI verb/config section — the CONTROL: the same probe method did find the plugin/marketplace machinery). Whether Codex accepts *plugin-delivered* agents remains **unverified** and is now moot — generation writes user config, the documented path. OpenCode generation: declared; live spawn pending the v4.41.0 verification pass |
| `scripts/` | 5 | 4 are copied into the consumer's `.claude/scripts/` by `install.ps1`; `submit-audit-bridge.sh` is **not** — it stays in the plugin and is loaded by the plugin hook loader | same split | **not delivered** — the consumer scripts are hook payloads, and OpenCode has no hook loader to run them | declared — the 4 are `sourceTemplate` entries in `manifest-template.json`; the bridge is referenced by `hooks/hooks.json` as `${CLAUDE_PLUGIN_ROOT}/scripts/…` and appears in no manifest |

## Where a capability does not reach a tool, name the fallback

A capability with no fallback is a silent hole. These are the ones that exist:

| Gap | Fallback | Where it is stated |
|---|---|---|
| Reviewer agents not installed (any tool) | the **`review-changes`** skill — runs the same architecture + design rubrics inline and ends with the literal `Verdict:` line `review-and-submit` parses. Not only a fallback: the `review-and-submit` fast path invokes it in agent-capable sessions too, so do not retire it now that the agents ARE ported (generated) for Codex/OpenCode | `review-and-submit` SKILL.md, and the Codex plugin description |
| Project hooks (Codex) | ship the hook through the plugin's own `hooks/hooks.json` instead — `${CLAUDE_PLUGIN_ROOT}` resolves under Codex (it ships that name as a compat alias). Gate a one-tool hook on the tool to **exclude**: `[ -n "${CLAUDECODE:-}" ] && exit 0` | this file; `submit-audit-bridge.sh` is the worked example |
| ALL hooks (OpenCode) | none today — server-side Submit-Audit is the backstop, same as any non-hook host. Designed follow-up: `myst-guards.mjs`, a JS plugin spawning the SAME `.claude/scripts/*.sh` (`tool.execute.before` throw / `permission.ask` deny / `tool.execute.after`). Build triggers: a user trips a guard, or OpenCode's edit tool proves to flip CRLF on a Perforce consumer (then the `normalize-eol` port is rollout-blocking) | `SETUP.md` OpenCode gaps table; `docs/adr-0005-opencode-pointer-consumer.md` |
| `.claude/rules/*.md` (Codex, OpenCode) | a counterpart section in `AGENTS.md` — OpenCode reads `AGENTS.md` natively, so the Codex parity invariant covers both | `check-rule-parity.sh`, `check-rules-alignment.sh` |

**Not yet closed:** `check-script-standard.sh` (AngelScript naming) is wired only through a
consumer's `.claude/settings.json`, so it is Claude-only. It *could* ship through
`hooks/hooks.json` like the Submit-Audit bridge. Until it does, `AGENTS.md` must say plainly
that the rule is unenforced under Codex — and it does.

**Reclassified in 4.26.0 — the reviewer-agent gap is closable, not permanent.** It was recorded
as "Codex has no subagent mechanism", which is false. Codex has one; the plugin's agents are
Markdown and Codex's are TOML. Porting `agents/*.md` to TOML and declaring them in
`.codex-plugin/plugin.json` is the real remedy, and until someone tries it we do not know
whether Codex's loader accepts plugin-delivered agents at all. The `review-changes` skill stays
the fallback meanwhile — it is a genuine one, which is why this went unnoticed.

**Closed in 4.41.0 — by generation, not by plugin delivery.** `setup-devkit.ps1` writes the
two reviewers as user-scope agents for both Codex (`~/.codex/agents/*.toml`, per the official
subagent docs schema: `name`/`description`/`developer_instructions`, `sandbox_mode =
"read-only"`) and OpenCode (`~/.config/opencode/agents/myst/*.md`, `mode: subagent`,
`permission: edit deny`). Fixed literal headers, body verbatim, regenerated on every script
run, removed by `-Uninstall`. The plugin-delivered-agents question above is thereby moot —
user config is the documented path for both hosts. The shared `.md` files stay untouched and
Claude-native; their `tools:` restriction (the read-only enforcement under Claude) is never
weakened, and the generated variants carry each host's NATIVE read-only mechanism instead.

**Closed 2026-08-06 by an observed run — this was the table's longest-standing hole.** v4.26.0
downgraded the `hooks/` row to `unverified` because the existing "measured" only ever covered
*project*-level hooks failing to load; nobody had watched a **plugin** hook fire under Codex, and
the one plugin hook that exists had spent its whole life gated on a variable no host sets, so its
silence proved nothing.

It has now been watched. Method — an unconditional file-write marker injected into the installed
bridge (stderr is not surfaced by `codex exec`, so a file is the only unambiguous signal), then
`codex exec` run with Claude's env markers stripped. Result, on two consecutive tool calls:

```
hook: PreToolUse ×2 -> both Completed        (the user's own shim + the plugin's)
[CACHE] bridge entered   CLAUDECODE=[]  CODEX_HOME=[]
  -> REACHED EXEC: AUDIT=[<repo>/.claude/scripts/submit-audit-warn.sh] exists=[yes]
```

Measured inside that hook subprocess, and each one retires a hypothesis:

| Fact | Consequence |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}` **resolves** | the documented delivery mechanism is real |
| `CLAUDECODE` is **empty** | the v4.26.0 gate correctly identifies non-Claude |
| **`CODEX_HOME` is empty** | it appears 53× in `codex.exe` but is **not exported to hooks**. Gating on it — which was the obvious candidate — would have shipped a second dead gate, failing exactly as `PLUGIN_ROOT` did |
| `"matcher": "Bash"` **matches** | Codex's shell tool logs as `exec` and runs `pwsh.exe`, yet the Claude-flavoured matcher still matches. Never a blocker |
| No `[hooks.state]` entry exists for it | plugin hooks do **not** require persisted trust |

> **Two copies of an installed Codex plugin exist and only one runs.**
> `~/.codex/plugins/cache/<mkt>/<plugin>/<version>/` is live;
> `~/.codex/.tmp/marketplaces/<mkt>/plugins/<plugin>/` is a full, inert copy. Instrumenting the
> wrong one yields a completely convincing false negative — it cost several rounds here before
> tagging both copies with distinct markers made the experiment identify its own subject.

## Rules for changing this

1. **Adding a capability directory to the plugin** — add a row here, and say what happens
   under the tool that cannot load it. "It just won't work there" is a fallback; write it down.
2. **Do not let a manifest description promise a capability the tool cannot run.** The Codex
   description advertised both reviewer agents until v4.25.0. A user reading it would never
   have learned that `review-changes` is the actual path.
3. **Asymmetric declarations are fine and expected.** The Codex manifest declares `skills`
   and `hooks` because its loader requires it; Claude's does not because its loader does not.
   That is not drift. What would be drift is a *file* present for one tool and absent for the
   other, or a claim in one manifest that is false for its own tool.
4. **Promote `unverified` to `measured` by running it, not by reasoning about it.** The
   `commands/` row has been unverified since the plugin gained a Codex manifest. Anyone with
   a live Codex session can close it in a minute; nobody has.
