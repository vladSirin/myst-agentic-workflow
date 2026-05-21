---
name: diagnose
description: Debug hard bugs and regressions by building a reproducible feedback loop before changing code. Use when something is broken, failing, throwing, or regressing.
compatibility: opencode
---

# Diagnose

Read `Docs/MustRead/MustRead_agentic_workflow.md` and `Docs/agents/domain.md`.

Reproduce before fixing whenever feasible. Prefer automated build, test, and log feedback loops. Use HITL only when Unreal Editor, gameplay feel, asset state, or level validation cannot be checked automatically.

Keep changes surgical and respect the existing Perforce changelist workflow. Record unresolved human checks as `resolved`, not `closed`.
