# Pre-Implementation Gate

**HARD RULE (advisory):** BEFORE proposing a plan whose body contains `CL1`, `CL2`, ...
or any 2+ submission sequence, however labeled, verify the workflow state.
Implementation is the LAST phase, not the first: spec → tickets → triage come first.

Check (locations defined by `Docs/agents/issue-tracker.md`):

1. A **spec** exists for this work.
2. **Vertical-slice tickets** exist.
3. At least one ticket is triaged ready: **`Status: ready-for-agent`** or
   **`ready-for-human`** (HITL — agent implements, human gates; see below).

- ALL yes → proceed; link the ticket in the plan body AND put this line in each CL
  description: `Ticket: .scratch/<slug>/issues/<NN>-<slug>.md` (or tracker ref).
- ANY no → STOP. Don't draft CLs. Offer: (a) create a spec now (`/to-spec`, or
  manually per `Docs/MustRead/MustRead_agentic_workflow.md`); or (b) the user
  explicitly skips the workflow — then put `Workflow: skipped (<reason>)` in each
  CL description. These two line formats are what the Submit-Audit agent check greps.

**HITL tickets (`ready-for-human`)**: hard rule 6 already gates EVERY submit outside a
`/goal` run — this section does not imply non-HITL CLs ride standing authorizations.
What is HITL-specific: a `ready-for-human` CL stays gated **even inside** a `/goal` run,
never covered by a standing batch/goal authorization. Attended → ask per CL. Unattended →
review, `p4 shelve -c <CL>`, append `HITL-SHELVED: awaiting human review` to its
description, report, continue other work; never `p4 submit` it yourself. The shelve
mechanics (files stay open, `-f` to re-shelve, exclude from reconcile/submit-all) are in
the `pre-implementation-gate` skill.

Does NOT fire on: a single focused CL, trivial fixes, diagnostic/read-only work,
work linked to an existing triaged-ready (or already in-flight) ticket, or an
explicit user skip.

Full procedure and rationale: the `pre-implementation-gate` skill
(myst-dev-kit plugin — `/plugin install myst-dev-kit@myst` if missing).
