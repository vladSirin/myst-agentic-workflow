# Tool capability matrix — what the plugin delivers to Claude vs Codex

`myst-dev-kit` ships one tree and two manifests. The loaders differ, so **the two tools do
not receive the same capabilities**, and the differences are deliberate. This file is the
record of which, and on what evidence.

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

| Capability | Count | Claude | Codex | Evidence |
|---|---|---|---|---|
| `skills/` | 30 | convention (no `skills` key in `.claude-plugin/plugin.json`) | **declared** — `"skills": "./skills/"` | declared (Codex) / convention (Claude) |
| `hooks/` | 1 entry | plugin hooks load; project `.claude/settings.json` hooks **also** load | **declared** — `"hooks": "./hooks/hooks.json"`. Project-level hooks **never** load | measured — `.codex/hooks.json` and `.agents/hooks.json` were each placed in a repo and a live `codex exec` run for both; neither fired |
| `commands/` | 3 | convention | convention | **unverified** — neither manifest declares `commands`, and no one has confirmed Codex discovers them |
| `agents/` | 2 | convention — `architecture-reviewer`, `radical-design-critic` | **ship inert — but not for the reason stated until 4.26.0.** Codex *does* have a subagent mechanism; these two files are Markdown and Codex agents are TOML, so nothing consumes them | measured — `~/.codex/agents/` holds 22 `.toml` agents incl. `code-reviewer`; `codex.exe` names `subagents` 19 times as a plugin resource kind. Whether Codex's loader accepts *plugin-delivered* agents is **unverified** |
| `scripts/` | 5 | 4 are copied into the consumer's `.claude/scripts/` by `install.ps1`; `submit-audit-bridge.sh` is **not** — it stays in the plugin and is loaded by the plugin hook loader | same split | declared — the 4 are `sourceTemplate` entries in `manifest-template.json`; the bridge is referenced by `hooks/hooks.json` as `${CLAUDE_PLUGIN_ROOT}/scripts/…` and appears in no manifest |

## Where a capability does not reach a tool, name the fallback

A capability with no fallback is a silent hole. These are the ones that exist:

| Gap | Fallback | Where it is stated |
|---|---|---|
| Reviewer agents (Codex) | the **`review-changes`** skill — runs the same architecture + design rubrics inline and ends with the literal `Verdict:` line `review-and-submit` parses | `review-and-submit` SKILL.md, and the Codex plugin description |
| Project hooks (Codex) | ship the hook through the plugin's own `hooks/hooks.json` instead — `${CLAUDE_PLUGIN_ROOT}` resolves under Codex (it ships that name as a compat alias). Gate a one-tool hook on the tool to **exclude**: `[ -n "${CLAUDECODE:-}" ] && exit 0` | this file; `submit-audit-bridge.sh` is the worked example |
| `.claude/rules/*.md` (Codex) | a counterpart section in `AGENTS.md` | `check-rule-parity.sh`, `check-rules-alignment.sh` |

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

**Also not closed — and it outranks both:** `hooks/hooks.json` is the delivery path this table
calls **measured**, but that measurement only ever covered *project*-level hooks failing to
load. **Nobody has observed a plugin hook firing under Codex.** For its entire life the one
plugin hook that exists gated on a variable no host sets, so its silence proved nothing either
way. Until someone runs Codex with `MYST_AUDIT_DEBUG=1` and sees the bridge announce itself,
"plugin hooks work under Codex" is `unverified`, not `measured`.

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
