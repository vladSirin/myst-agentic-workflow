---
name: pre-implementation-gate
description: "HARD RULE - use BEFORE drafting any multi-changelist implementation plan. Verify that PRD, issues, and triage exist first."
---

# CRITICAL WORKFLOW REQUIREMENT

## Pre-Implementation Gate

Before proposing any multi-CL implementation plan (`CL1`, `CL2`, `CL3`, ...), you **MUST** verify the project's PRD / issues / triage state.

---

## Hard Rule

> [!CAUTION]
> If the user asks for non-trivial implementation work and you find yourself drafting a 2+ CL plan, **STOP**.
>
> Implementation is the LAST phase of the workflow, not the first. PRD → Issues → Triage come first (per `AgenticWorkflow.md`).

---

## Required check (run before any multi-CL plan)

1. **Does a PRD exist?** Look under `.scratch/<feature-slug>/PRD.md` for this work.
2. **Do issues exist?** Look under `.scratch/<feature-slug>/issues/` for vertical-slice issues.
3. **Is at least one issue at `Status: ready-for-agent`?**

If ALL three are yes → proceed with the multi-CL plan, and **link the plan to the issue(s)** in the plan body.

If ANY is no → STOP. Don't draft CLs. Respond with:

> "Before drafting a CL plan, I need to follow the workflow. I don't see [PRD / issues / triaged issues] for this work yet. Options:
> (a) Use `/to-prd` to create a PRD now (recommended).
> (b) Skip the workflow and proceed directly to CL planning — I'll note this as an explicit deviation in the CL description.
>
> Which do you want?"

---

## Trigger

Fires when you are about to propose any of:

- A plan body containing `CL1`, `CL2`, `CL3`, ... or "changelist 1", "changelist 2", etc.
- A multi-step implementation plan with 2+ commits / submissions.
- File-level implementation steps (Edit/Write across multiple files in a planned sequence).

Does **not** fire on:

- Single-file edits or trivial fixes (one CL).
- Diagnostic, read-only, or research tasks.
- Work explicitly tied to an existing `ready-for-agent` issue (linked in the plan).

---

## Exceptions

The **ONLY** exceptions are:

1. The user explicitly says "skip PRD" / "skip workflow" / "go straight to implementation."
2. The work is a single small CL (one focused change).
3. A PRD or issue already exists for this work in `.scratch/`, and your plan references it.

---

## Why this matters

- PRDs capture intent. Without one, the rationale gets buried in CL descriptions where it can't be queried later.
- Issues let work be paused, resumed, and verified independently — a CL alone cannot.
- Triage classifies who does what (`ready-for-agent` vs `ready-for-human`) so the right hands pick up the right work.
- Skipping the workflow turns the project into ad-hoc CLs with no record of why they were chosen — exactly the failure mode the workflow exists to prevent.

---

## Plan-mode interaction

This gate fires INSIDE plan mode. If you've already called `exit_plan_mode` and your plan body is "CL1 do X, CL2 do Y, CL3 do Z" with no PRD link, you skipped this gate. The correct plan body shapes are:

- A **workflow plan**: "Create PRD → discuss → break into issues → triage → implement against ready-for-agent issue(s)."
- A **CL plan against an existing issue**: "Per issue `.scratch/<slug>/issues/01-foo.md` (status: ready-for-agent), implement CL1, CL2, CL3 ..."

---

## Enforcement

This rule is advisory (like `ChangelistVerification.md`). If you find yourself proposing CLs without checking `.scratch/`, you have violated this requirement. Catch yourself before presenting the plan, not after.

---

## Related

- `AgenticWorkflow.md` — the seven-phase workflow this gate enforces.
- `AutoPlanMode.md` — plan-mode requirement (this gate fires inside plan mode).
- `ChangelistVerification.md` — CL-by-CL execution discipline (applies AFTER this gate passes).
- `/to-prd` — skill to create a PRD from current conversation context.
- `/to-issues` — skill to break a PRD into vertical-slice issues.
- `/triage` — skill to route issues through the status workflow.
