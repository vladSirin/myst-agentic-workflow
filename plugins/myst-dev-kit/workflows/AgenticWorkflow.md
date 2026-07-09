# Agentic Workflow

## Scope and relationship to DesignWorkflow

This workflow is the **end-to-end shape** for non-trivial work: discussion → captured intent (PRD) → planned slices (issues) → triaged → built → verified → submitted.

For work involving **game design** (mechanics, UX, levels, player experience), the Discussion phase is **extended** via [DesignWorkflow.md](DesignWorkflow.md) — that produces a finalized design doc in `{{game_docs_root}}/`, and the PRD phase here references it. For pure code / system / bugfix work, Discussion can stay in chat and you jump straight to PRD (`/to-prd`).

Three flow shapes the project supports:

| Work shape | Flow |
|---|---|
| **Game design + implementation** | `DesignWorkflow` → finalized doc → **this workflow** (PRD → Issues → Triage → Implement → Verify → Review/Submit), with PRD referencing the design doc |
| **Pure code / system / bugfix** | **This workflow** directly; Discussion happens in chat |
| **Pure game design, no code** | `DesignWorkflow` only — no PRD/issues needed |

Examples that go straight to this workflow (no DesignWorkflow Discussion):

- Refactor or extend a subsystem (Flow, Objective, FrogEvent integration, etc.)
- Fix a bug or regression
- Build a tool, pipeline, or CI mechanism
- Integrate a new plugin or library

If you're not sure which shape: would the deliverable be read primarily by a game designer / LD → use `DesignWorkflow` first. Read primarily by an engineer → jump straight here.

---

## Mandatory workflow for non-trivial work

When a user asks for non-trivial in-scope (see above) work, use this workflow unless the user explicitly asks for a narrower action.

```text
Discussion -> PRD -> Issues -> Triage -> Implement -> Verify -> Review/Submit
```

## Required references

Before creating or updating PRDs, issues, or workflow state, read:

- `{{docs_root}}/MustRead/MustRead_agentic_workflow.md`
- `{{docs_root}}/agents/issue-tracker.md`
- `{{docs_root}}/agents/triage-labels.md`
- `{{docs_root}}/agents/domain.md`

If `CONTEXT.md` exists, read it before naming domain concepts. If relevant ADRs exist under `{{docs_root}}/adr/`, read them before proposing architecture changes.

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

Use the status model in `{{docs_root}}/agents/triage-labels.md`.

- `ready-for-agent`: agent can implement and verify every required check without human judgment.
- `ready-for-human`: human-in-the-loop work or verification is required.
- `needs-info`: missing information blocks safe classification or implementation.
- `wontfix`: intentionally not pursued.

### 5. Implementation

Use `/tdd` for planned feature work and `/diagnosing-bugs` for bugs or regressions. Set the issue to `Status: work-in-progress` while working.

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
