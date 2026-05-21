# To PRD

<command-name>to-prd</command-name>

## Purpose

Turn the current conversation context into a PRD and publish it to this repo's issue tracker.

## Project setup

- Issue tracker rules: `Docs/agents/issue-tracker.md`
- Status labels: `Docs/agents/triage-labels.md`
- Domain docs: `Docs/agents/domain.md`

## Instructions

When invoked, follow this repo's project-local PRD workflow:

1. Read `Docs/agents/issue-tracker.md`, `Docs/agents/triage-labels.md`, and `Docs/agents/domain.md`.
2. Use `.scratch/<feature-slug>/PRD.md` as the publication target.
3. Set new PRDs to `Status: needs-triage`.
4. Use project vocabulary from `CONTEXT.md` if it exists; otherwise use terms from the existing project docs and code.
5. Avoid specific file paths or code snippets because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.
6. Respect Perforce workflow and do not submit anything without explicit user approval.
