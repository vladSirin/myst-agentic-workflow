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
> Implementation is the LAST phase of the workflow, not the first. Spec → Tickets → Triage come first (per the `agentic-workflow` skill).

---

## Required check (run before any multi-CL plan)

1. **Does a spec exist?** Look under `.scratch/<feature-slug>/spec.md` for this work.
2. **Do tickets exist?** Look under `.scratch/<feature-slug>/issues/` for vertical-slice tickets.
3. **Is at least one ticket triaged `Status: ready-for-agent`?**
   (`ready-for-human` means a human implements it — it is not a ticket you may pick up. See "`ready-for-human` is a handoff" below.)

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
- Work explicitly tied to an existing `ready-for-agent` ticket, linked in the plan.

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

This gate fires INSIDE plan mode. If you've already called `ExitPlanMode` and your plan body is "CL1 do X, CL2 do Y, CL3 do Z" with no ticket link, you skipped this gate. The correct plan body shapes are:

- A **workflow plan**: "Create spec → discuss → break into tickets → triage → implement against triaged-ready ticket(s)."
- A **CL plan against an existing ticket**: "Per ticket `.scratch/<slug>/issues/01-foo.md` (status: ready-for-agent), implement CL1, CL2, CL3 ..."

---

## `ready-for-human` is a handoff, not a workflow

`ready-for-human` means **a human implements this ticket**. It is not a ticket you pick up and
finish carefully — it is one you do not pick up at all. Report that it is waiting for a human
and move to other work.

> [!CAUTION]
> **The relabel is user-only.** `ready-for-human` → `ready-for-agent` is a transition only the
> user makes. An agent that believes a ticket is mislabeled **says so and stops** — it does not
> relabel and proceed. Without this rule the label is worthless: an agent that can grant itself
> `ready-for-agent` can then submit under a goal-mode authorization in the same run, which is
> exactly the gate the label exists to hold.
>
> **If you find yourself holding a CL that implements a `ready-for-human` ticket, that is a
> process error, not a workflow.** Do not submit it, in any mode, attended or not. Run the review
> pass, `p4 shelve -c <CL>` — the depot is untouched, but the files STAY OPEN locally: exclude
> that CL from any later reconcile/submit-all, and re-shelve with `p4 shelve -f -c <CL>` if its
> files change again. Append `HITL-SHELVED: awaiting human review` to the CL description
> (alongside its `Ticket:` line), report it, and continue with other work. Never `p4 submit` it
> yourself; the human's unshelve-review-submit IS the approval.

Separately, and not HITL-specific: **every** submit is human-gated outside a `/goal` run — see the
submit-authority rule in `review-and-submit`. Nothing in this section implies that other CLs ride
standing authorizations.

**Work that ships but still needs a human check is not `ready-for-human`** — it is `resolved` plus
an `Outstanding:` line (next section). Keep the two apart: `ready-for-human` is about who
*implements*, `resolved` is about what remains to be *verified*.

## The ticket travels WITH the CL

The `Ticket:` line points the CL at the ticket. **Nothing points the ticket back**, and that
one-directional gap is what rots a board: ticket state drifts from reality, and someone later
pays to reconstruct it. Three rules close it.

1. **Any ticket whose state a CL changes must be IN that CL** — checked out, updated and
   submitted together. Explicitly including a ticket you touch *incidentally* while working on
   another: if work for ticket 06 discharges a criterion of ticket 03, then **03 is in that CL
   too**. Spelled out rather than assumed, because the failure is not laziness — you are working
   inside 06, you discharge 03's criterion in passing, and you write the evidence where you
   happen to be standing. Later, 03 still reads as open.

2. **`resolved` carries an `Outstanding:` line** — what check, who performs it, where the result
   gets recorded. `resolved` *means* a human check remains; a ticket that does not say WHICH one
   cannot be closed without re-deriving it from scratch.

3. **Deferring a criterion names its receiving owner** — a ticket number or a named slice, in the
   same edit that defers it. "Rides ticket 06" and "remains for the debug pass" are how a
   criterion goes ownerless for weeks.

**The exception, which is what keeps this followable.** A check that can only run AFTER the code
ships — a human play-test, PIE against the shipped binary — cannot be recorded in the CL that
ships it. That is exactly what `resolved` plus rule 2 are for: the ticket moves to `resolved` in
the code CL and to `closed` in a later one. Never hold a code CL hostage to a human, and never
pre-record a check that has not happened.

Why this is worth always-loaded text: a board audited after the fact needed a dedicated pass to
work out what was still outstanding across seven `resolved` tickets — evidence written into the
wrong ticket, a criterion whose prose said "met" while its checkbox said otherwise, and a
deferred criterion that had gone ownerless. The tickets that had travelled with their CL closed
with zero reconstruction.

---

## Enforcement

This rule is advisory (like the `changelist-verification` skill). If you find yourself proposing CLs without checking `.scratch/`, you have violated this requirement. Catch yourself before presenting the plan, not after.

Where the consumer repo runs the Submit-Audit client hook, a risky over-threshold CL whose description carries **neither** a `Ticket:` ref **nor** a `Workflow: skipped (<reason>)` line gets an advisory warning. The two canonical lines above are exactly what that check greps. **Agent-session-only**: the check exists only in the agent-side client hook — human teammates' CLs are exempt from this convention by design and must never be audited for it server-side.

---

## Related

- The `agentic-workflow` skill — the seven-phase workflow this gate enforces.
- The `auto-plan-mode` skill — plan-mode requirement (this gate fires inside plan mode).
- The `changelist-verification` skill — CL-by-CL execution discipline (applies AFTER this gate passes).
- `/to-spec` — skill to create a spec from current conversation context.
- `/to-tickets` — skill to break a spec into vertical-slice tickets.
- `/triage` — skill to route tickets through the status workflow.
