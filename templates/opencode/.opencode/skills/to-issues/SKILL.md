---
name: to-issues
description: Break a PRD, plan, or design into independently grabbable vertical-slice issues under .scratch. Use when the user wants implementation tickets, feature breakdowns, or issue generation.
compatibility: opencode
---

# To Issues

Read `Docs/MustRead/MustRead_agentic_workflow.md`, `Docs/agents/issue-tracker.md`, `Docs/agents/triage-labels.md`, and `Docs/agents/domain.md`.

Publish issues under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`.

Assign a `Status:` during creation; do not default every issue to `needs-triage`.

Use `ready-for-agent` only when every required test case can be verified without human judgment. Use `ready-for-human` when the slice requires HITL review, editor validation, gameplay feel checks, art/design approval, LD usability review, or Perforce reviewer confirmation. Use `needs-info` if the slice is still too vague to classify safely.

Avoid specific file paths or code snippets because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.

Prefer vertical slices that are independently verifiable and small enough for one changelist.
