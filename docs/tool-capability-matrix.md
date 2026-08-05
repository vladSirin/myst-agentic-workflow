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

## The matrix

| Capability | Count | Claude | Codex | Evidence |
|---|---|---|---|---|
| `skills/` | 30 | convention (no `skills` key in `.claude-plugin/plugin.json`) | **declared** — `"skills": "./skills/"` | declared (Codex) / convention (Claude) |
| `hooks/` | 1 entry | plugin hooks load; project `.claude/settings.json` hooks **also** load | **declared** — `"hooks": "./hooks/hooks.json"`. Project-level hooks **never** load | measured — `.codex/hooks.json` and `.agents/hooks.json` were each placed in a repo and a live `codex exec` run for both; neither fired |
| `commands/` | 3 | convention | convention | **unverified** — neither manifest declares `commands`, and no one has confirmed Codex discovers them |
| `agents/` | 2 | convention — `architecture-reviewer`, `radical-design-critic` | **not supported.** Codex has no subagent mechanism; the files ship inert | measured by absence — no `agents` key in either manifest, no Codex subagent API |
| `scripts/` | 8 | **neither tool loads these as a plugin capability.** They are copied into the consumer's `.claude/scripts/` by `install.ps1` from `manifest-template.json`, and invoked by hooks or by hand | same — delivery is via the scaffold installer, not the plugin loader | declared — each is a `sourceTemplate` entry in `manifest-template.json` |

## Where a capability does not reach a tool, name the fallback

A capability with no fallback is a silent hole. These are the ones that exist:

| Gap | Fallback | Where it is stated |
|---|---|---|
| Reviewer agents (Codex) | the **`review-changes`** skill — runs the same architecture + design rubrics inline and ends with the literal `Verdict:` line `review-and-submit` parses | `review-and-submit` SKILL.md, and the Codex plugin description |
| Project hooks (Codex) | ship the hook through the plugin's own `hooks/hooks.json` instead — `${CLAUDE_PLUGIN_ROOT}` resolves under Codex (it exports both `PLUGIN_ROOT` and the compat alias) | this file; `submit-audit-bridge.sh` is the worked example |
| `.claude/rules/*.md` (Codex) | a counterpart section in `AGENTS.md` | `check-rule-parity.sh`, `check-rules-alignment.sh` |

**Not yet closed:** `check-script-standard.sh` (AngelScript naming) is wired only through a
consumer's `.claude/settings.json`, so it is Claude-only. It *could* ship through
`hooks/hooks.json` like the Submit-Audit bridge. Until it does, `AGENTS.md` must say plainly
that the rule is unenforced under Codex — and it does.

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
