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

### 1. Discussion

Use normal conversation, `/roundtable`, or `/grill-with-docs` while intent is unclear. Do not create speculative implementation issues until the problem, scope, and verification expectations are clear.

### 2. PRD

Use `/to-prd` or write a PRD directly under `.scratch/<feature-slug>/PRD.md` when the idea is ready to capture. New PRDs start at `Status: needs-triage`.

### 3. Issues

Use `/to-issues` or write issue files under `.scratch/<feature-slug>/issues/`. Issues must be vertical slices, independently understandable, and small enough to verify.

Assign initial issue status during creation: `ready-for-agent`, `ready-for-human`, or `needs-info`. Do not default generated issues back to `needs-triage` unless the whole breakdown truly needs human classification.

Avoid specific file paths or code snippets in issue bodies because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.

### 4. Triage

Use the status model in `Docs/agents/triage-labels.md`.

- `ready-for-agent`: agent can implement and verify every required check without human judgment.
- `ready-for-human`: human-in-the-loop work or verification is required.
- `needs-info`: missing information blocks safe classification or implementation.
- `wontfix`: intentionally not pursued.

### 5. Implementation

Use `/tdd` for planned feature work and `/diagnose` for bugs or regressions. Set the issue to `Status: work-in-progress` while working.

### 6. Verification

- Agent-verifiable issues may move directly from `work-in-progress` to `closed` after all checks pass.
- HITL issues move from `work-in-progress` to `resolved` after implementation and agent-runnable checks pass.
- Only a human verification step moves a HITL issue from `resolved` to `closed`.

### 7. Review and submit

For Perforce submission, follow `ReviewAndSubmit.md`. Never submit without explicit user approval.

## Guardrails

- Do not skip existing plan discovery; follow `PlanPriority.md`.
- Do not batch multiple changelists without explicit user approval; follow `ChangelistVerification.md`.
- Do not modify `{{game_docs_root}}/_Raw/` without the protected-material approval flow.
- Keep issue state changes explicit in the issue file's `Status:` line.
