# templates/ — per-tool bibles + tool-neutral docs

Shared skill/agent/command/workflow content lives in `plugins/myst-dev-kit/`
(one source, installed to both `.claude/` and `.Codex/`). What remains here is
genuinely per-tool or tool-neutral:

- `claude/CLAUDE.md` — Claude Code bible template (generated-block source).
- `codex/AGENTS.md` — Codex bible template (generated-block source).
- `common/docs/MustRead/` — single source for the human workflow guide. Installer
  transforms package-native lowercase `docs/` to the consumer's `Docs/`. There is
  no separate `MustRead` package root.
- `common/docs/agents/` — issue-tracker, triage-labels, domain, manifest schema.

OpenCode support was retired with the marketplace restructure (Claude Code +
Codex are the supported tools).
