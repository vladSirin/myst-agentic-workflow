---
name: setup-myst-agentic-workflow
description: Install or update the agentic-workflow scaffold into a target project. Detects Codex/Claude Code/OpenCode, asks core/overlay choices, runs dry-run first, writes only after explicit confirmation. Use when a user wants to set up or refresh the agentic workflow scaffolding in a repo.
---

# setup-myst-agentic-workflow (skeleton)

> Skeleton phase. This skill currently performs **detection + dry-run reporting only**.
> Write-mode is plan-gated (see `package-manifest.json` `writeModePreconditions`).

## Responsibilities

1. **Detect tools** in the target project:
   - Codex: `AGENTS.md`, `.Codex/`
   - Claude Code: `CLAUDE.md`, `.claude/`
   - OpenCode: `opencode.json`, `.opencode/`, `AGENTS.md`
2. **Ask scope**: one tool or all detected; which overlays (`core`, `perforce`,
   `ue`, `myst-project`).
3. **Dry-run**: call `scripts/install.ps1 -Mode DryRun` and present the planned
   add / update / skip / project-owned / unverifiable report. **Stop here in the
   skeleton phase.**
4. *(Gated)* Write: only after preconditions met, explicit confirmation, and — if
   Perforce — a named changelist.
5. **Report**: clean summary of added, updated, skipped, project-specific,
   `unverifiable-pending-markers`, and conflicts.

## Hard rules

- Never write `localOnly`, `manual-only`, `human-owned`, or project-owned files.
- Never write `generated-block`/`append-fragment` files until conforming markers
  exist and `blockHash` is populated.
- DryRun is the default and the only mode available in the skeleton phase.
