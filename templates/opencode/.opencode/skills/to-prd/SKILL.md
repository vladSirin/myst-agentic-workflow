---
name: to-prd
description: Turn the current conversation context into a PRD and publish it to this repo's in-repo issue tracker (version-controlled markdown under .scratch/). Use when the user asks to create a PRD, product requirements, or capture a feature plan.
compatibility: opencode
---

# To PRD

Read `Docs/MustRead/MustRead_agentic_workflow.md`, `Docs/agents/issue-tracker.md`, `Docs/agents/triage-labels.md`, and `Docs/agents/domain.md`.

Write the PRD to `.scratch/<feature-slug>/PRD.md` with `Status: needs-triage`.

Use project vocabulary from `CONTEXT.md` if it exists; otherwise use terms from existing project docs and code.

Avoid specific file paths or code snippets because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.

Respect Perforce workflow and do not submit anything without explicit user approval.
