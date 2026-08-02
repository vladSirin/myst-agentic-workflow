---
name: pre-implementation-gate
description: "HARD RULE - use BEFORE drafting any multi-changelist implementation plan. Verify that a spec, tickets, and triage exist first."
---

# CRITICAL WORKFLOW REQUIREMENT

## Pre-Implementation Gate

Before proposing any multi-CL implementation plan (`CL1`, `CL2`, `CL3`, ...), you **MUST** verify the project's spec / tickets / triage state.

---

## Hard Rule

> [!CAUTION]
> If the user asks for non-trivial implementation work and you find yourself drafting a 2+ CL plan, **STOP**.
>
> Implementation is the LAST phase of the workflow, not the first. Spec → Tickets → Triage come first (per `AgenticWorkflow.md`).

---

## Required check (run before any multi-CL plan)

1. **Does a spec exist?** Look under `.scratch/<feature-slug>/spec.md` for this work.
2. **Do tickets exist?** Look under `.scratch/<feature-slug>/issues/` for vertical-slice tickets.
3. **Is at least one ticket triaged ready — `Status: ready-for-agent` or `ready-for-human`?**
   (`ready-for-human` = HITL: the agent still implements; a human gates verification and every submit — see "HITL tickets" below.)

If ALL three are yes → proceed with the multi-CL plan, **link the plan to the ticket(s)** in the plan body, and put the canonical line in each CL description:

```
Ticket: .scratch/<feature-slug>/issues/<NN>-<slug>.md
```

(or the tracker's native ref once a hosted tracker is integrated).

If ANY is no → STOP. Don't draft CLs. Respond with:

> "Before drafting a CL plan, I need to follow the workflow. I don't see [spec / tickets / triaged tickets] for this work yet. Options:
> (a) Use `/to-spec` to create a spec now (recommended).
> (b) Skip the workflow and proceed directly to CL planning — I'll put `Workflow: skipped (<reason>)` in each CL description.
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
- Work explicitly tied to an existing triaged-ready ticket (`ready-for-agent` or `ready-for-human`, linked in the plan).

---

## Exceptions

The **ONLY** exceptions are:

1. The user explicitly says "skip spec" / "skip workflow" / "go straight to implementation."
2. The work is a single small CL (one focused change).
3. A spec or ticket already exists for this work in `.scratch/`, and your plan references it.

---

## Why this matters

- Specs capture intent. Without one, the rationale gets buried in CL descriptions where it can't be queried later.
- Tickets let work be paused, resumed, and verified independently — a CL alone cannot.
- Triage classifies who does what (`ready-for-agent` vs `ready-for-human`) so the right hands pick up the right work.
- Skipping the workflow turns the project into ad-hoc CLs with no record of why they were chosen — exactly the failure mode the workflow exists to prevent.

---

## Plan-mode interaction

This gate fires INSIDE plan mode. If you've already called `exit_plan_mode` and your plan body is "CL1 do X, CL2 do Y, CL3 do Z" with no ticket link, you skipped this gate. The correct plan body shapes are:

- A **workflow plan**: "Create spec → discuss → break into tickets → triage → implement against triaged-ready ticket(s)."
- A **CL plan against an existing ticket**: "Per ticket `.scratch/<slug>/issues/01-foo.md` (status: ready-for-agent or ready-for-human), implement CL1, CL2, CL3 ..."

---

## HITL tickets (`ready-for-human`): the batch-authorization carve-out

Work on a `ready-for-human` ticket proceeds normally — the agent implements and runs every agent-runnable check. What changes is the **submit endgame**:

> [!CAUTION]
> Every submit is human-gated outside a `/goal` run (see the submit-authority rule in `review-and-submit`) — do not read this section as implying non-HITL CLs ride standing authorizations. What is HITL-specific: a CL implementing a `ready-for-human` ticket is **NEVER covered by a standing batch/goal authorization** ("do all CLs at once", a `/goal` run, or any similar pre-approval) — it stays gated even *inside* goal mode.
>
> - **Attended session**: stop and ask for explicit per-CL approval, every time.
> - **Unattended session**: run the normal review pass, then `p4 shelve -c <CL>` — the depot is untouched, but the files STAY OPEN locally: exclude that CL from any later reconcile/submit-all, and re-shelve with `p4 shelve -f -c <CL>` if its files change again. Append `HITL-SHELVED: awaiting human review` to the CL description (alongside its `Ticket:` line), mark the ticket `resolved` once agent-runnable checks pass, log it in your final report, and continue with other work. The human's unshelve-review-submit IS the approval. Never `p4 submit` it yourself.
>
> Ticket status flow stays per triage-labels: HITL tickets end at `resolved` (agent-runnable checks passed); only a human moves them to `closed`.

---

## Enforcement

This rule is advisory (like `ChangelistVerification.md`). If you find yourself proposing CLs without checking `.scratch/`, you have violated this requirement. Catch yourself before presenting the plan, not after.

Where the consumer repo runs the Submit-Audit client hook, a risky over-threshold CL whose description carries **neither** a `Ticket:` ref **nor** a `Workflow: skipped (<reason>)` line gets an advisory warning. The two canonical lines above are exactly what that check greps. **Agent-session-only**: the check exists only in the agent-side client hook — human teammates' CLs are exempt from this convention by design and must never be audited for it server-side.

---

## Related

- `AgenticWorkflow.md` — the seven-phase workflow this gate enforces.
- `AutoPlanMode.md` — plan-mode requirement (this gate fires inside plan mode).
- `ChangelistVerification.md` — CL-by-CL execution discipline (applies AFTER this gate passes).
- `/to-spec` — skill to create a spec from current conversation context.
- `/to-tickets` — skill to break a spec into vertical-slice tickets.
- `/triage` — skill to route tickets through the status workflow.
