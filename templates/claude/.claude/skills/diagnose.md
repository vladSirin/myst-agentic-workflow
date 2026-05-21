# Diagnose

<command-name>diagnose</command-name>

## Purpose

Debug hard bugs and regressions by building a fast feedback loop before changing code.

## Project setup

- Domain docs: `Docs/agents/domain.md`

## Instructions

When invoked, follow this repo's project-local diagnosis workflow:

1. Reproduce before fixing whenever feasible.
2. Prefer automated build/test/log feedback loops.
3. Use HITL only when Unreal Editor, gameplay feel, asset state, or level validation cannot be checked automatically.
4. Keep changes surgical and respect the existing Perforce changelist workflow.
5. Record unresolved human checks as `resolved`, not `closed`.
6. If a HITL loop is needed, write the minimal issue-local checklist or script into `.scratch/<feature-slug>/`.
