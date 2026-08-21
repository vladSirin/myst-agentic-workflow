# ADR-0005: OpenCode as a pointer consumer, agents by generation — not a render target

**Status**: accepted (v4.41.0, 2026-08-21)

## Context

v3.0.0 deliberately retired OpenCode support: it was a render-target model — 49 template
files under `templates/opencode/`, 60 `tool: opencode` manifest entries, and two parity
test suites — and the maintenance bill, not the build cost, is what killed it. Meanwhile
OpenCode grew native consumption paths: it reads `AGENTS.md`/`CLAUDE.md` in place, and its
schema-validated `skills.paths` config key scans `**/SKILL.md` under any absolute path,
tolerating unknown frontmatter keys and log-and-skipping malformed skills.

## Decision

1. **Pointer, never copy.** OpenCode consumes `plugins/myst-dev-kit/skills/` IN PLACE via
   `skills.paths` pointed at a dedicated clone (`~/.myst-agentic-workflow`). Nothing is
   rendered, nothing is manifest-tracked, so nothing can drift and no parity suite is
   needed. Update = tag checkout of the clone. `setup-devkit.ps1` owns the whole flow
   (one command for all three tools; install = update; self-verifies delivery).
2. **Agents by generation, never junction, never fork.** The shared Claude agent `.md`
   files are NEVER loaded directly by other tools: their frontmatter breaks OpenCode's
   parser (`color: green` violates its color schema — a declared-key type error in the
   global agents dir is a machine-wide OpenCode startup failure, traced in source), and
   Codex agents are TOML. The script generates per-tool variants — fixed, known-good
   literal headers (OpenCode: `mode: subagent`, `permission: edit deny`; Codex:
   `sandbox_mode = "read-only"`) + the body verbatim — regenerated on every run.
   Read-only enforcement therefore comes from each host's native mechanism, and the
   shared source's own `tools:` restriction stays intact for Claude.
3. **The dedicated clone is never the Claude marketplace clone.** That clone tracks
   `main` and is pulled by Claude's own updater; a tag checkout there detaches HEAD and
   breaks `claude plugin marketplace update`. One extra clone buys total isolation.
4. **No committed per-tool config in consumer projects.** Rules assurance for OpenCode is
   native `AGENTS.md` reading — the same enforced-parity tier as Codex
   (`check-rule-parity.sh`). Full `.claude/rules/*.md` auto-load was measured at ~9.5k
   tokens/session, 65% of it path-scoped rules, and rejected as a default.

## Explicitly not revived

`templates/opencode/`, the `tool: opencode` manifest axis, parity/runtime-mutable suites,
directory junctions (convention-tier discovery that OpenCode has already renamed once),
and a runtime adapter plugin (its entire payload reduced to one hardcoded localhost MCP
URL plus rule text `AGENTS.md` already carries). Do not re-add these casually — the cost
that retired them was maintenance against a weekly-shipping tool, and the pointer model
exists precisely because it has no per-release maintenance surface.

## Consequences

- OpenCode users: two-line install, same command to update, loud failures
  (schema-validated key + script self-verification), `-Uninstall` to leave cleanly.
- Blocking hooks remain undelivered on OpenCode (same posture as Codex; server-side
  Submit-Audit is the backstop). Designed follow-up: `myst-guards.mjs` spawning the same
  `.claude/scripts/*.sh` — build it when a user trips a guard, or immediately if
  OpenCode's edit tool proves to flip CRLF on a Perforce consumer.
- `docs/tool-capability-matrix.md` carries the OpenCode column and the probe evidence.
