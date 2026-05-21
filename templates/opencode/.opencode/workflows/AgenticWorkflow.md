# Agentic Workflow

## Mandatory workflow for non-trivial work

When a user asks for non-trivial product, design, architecture, bugfix, feature, or implementation work, use this workflow unless the user explicitly asks for a narrower action.

```text
Discussion -> PRD -> Issues -> Triage -> Implement -> Verify -> Review/Submit
```

## Required references

Before creating or updating PRDs, issues, or workflow state, read:

- `Docs/MustRead/MustRead_agentic_workflow.md`
- `Docs/agents/issue-tracker.md`
- `Docs/agents/triage-labels.md`
- `Docs/agents/domain.md`

If `CONTEXT.md` exists, read it before naming domain concepts. If relevant ADRs exist under `Docs/adr/`, read them before proposing architecture changes.

## Stage rules

Use `/to-prd` for PRDs, `/to-issues` for vertical-slice issues, `/triage` for issue state, `/tdd` for planned feature work, and `/diagnose` for bugs or regressions.

PRDs start as `needs-triage`. Generated issues should receive an initial status during creation: `ready-for-agent`, `ready-for-human`, or `needs-info`. Do not default generated issues back to `needs-triage` unless the whole breakdown truly needs human classification.

Avoid specific file paths or code snippets in issue bodies because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.

Agent-verifiable work may move from `work-in-progress` directly to `closed` after all checks pass. Human-in-the-loop work moves to `resolved` first and only reaches `closed` after human verification.

## Guardrails

- Do not skip existing plan discovery.
- Do not batch multiple changelists without explicit user approval.
- Do not modify `{{game_docs_root}}/_Raw/` without the protected-material approval flow.
- Keep issue state changes explicit in the issue file's `Status:` line.
