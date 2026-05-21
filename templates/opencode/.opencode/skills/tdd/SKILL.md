---
name: tdd
description: Use red-green-refactor with one vertical slice at a time. Use when implementing new behavior, feature work, or fixes where tests should drive the change.
compatibility: opencode
---

# TDD

Read `Docs/MustRead/MustRead_agentic_workflow.md` and `Docs/agents/domain.md`.

Prefer behavior tests through public interfaces over implementation-detail tests. Work one test and one implementation slice at a time.

Treat Unreal Editor-only checks, gameplay feel, LD usability, and asset validation as HITL unless an automated check exists. Mark an issue `closed` only when every required verification is agent-runnable and passed. Mark it `resolved` when code/tests pass but human verification remains.
