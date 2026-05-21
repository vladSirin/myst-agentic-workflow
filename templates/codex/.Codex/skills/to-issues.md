# To Issues

<command-name>to-issues</command-name>

## Purpose

Break a plan, spec, or PRD into independently grabbable implementation issues using vertical slices.

## Project setup

- Issue tracker rules: `Docs/agents/issue-tracker.md`
- Status labels: `Docs/agents/triage-labels.md`
- Domain docs: `Docs/agents/domain.md`

## Instructions

When invoked, follow this repo's project-local issue generation workflow:

1. Read the repo agent docs listed above before writing issues.
2. Publish issues under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`.
3. Assign a `Status:` during creation; do not default every issue to `needs-triage`.
4. Use `ready-for-agent` only when every required test case can be verified without human judgment.
5. Use `ready-for-human` when the slice requires HITL review, editor validation, gameplay feel checks, art/design approval, LD usability review, or Perforce reviewer confirmation.
6. Use `needs-info` if the slice is still too vague to classify safely.
7. Avoid specific file paths or code snippets because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.
8. Prefer vertical slices that are independently verifiable and small enough for one changelist.
