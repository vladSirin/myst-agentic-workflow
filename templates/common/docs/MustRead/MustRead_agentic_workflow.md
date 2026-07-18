# Agentic Workflow Guide

**MUST_READ**: Read this guide before using `/to-spec`, `/to-tickets`, `/triage`, `/tdd`, `/diagnosing-bugs`, `/improve-codebase-architecture`, or `/grill-with-docs` in this repo.

This guide explains the recommended human workflow for turning discussion into tracked, verifiable work.

## Core workflow

```text
Discussion -> Spec -> Tickets -> Triage -> Implement -> Verify -> Review/Submit
```

Use this flow when the work is more than a trivial one-off edit. The goal is to keep ideas, implementation slices, verification, and Perforce submission separate enough that humans can inspect each step.

## 1. Discussion

Use normal chat for quick clarification. Use `/roundtable` for broad design tradeoffs or `/grill-with-docs` when the plan needs to be stress-tested against project language and durable decisions.

Discussion should answer:

- What problem are we solving?
- What is out of scope?
- Does this require human-in-the-loop verification?
- Which existing docs, systems, or plans does it touch?

## 2. Spec

Use `/to-spec` when the idea is clear enough to capture as product or feature intent (you may know this document as a PRD).

Output:

```text
.scratch/<feature-slug>/spec.md
```

New specs enter the tracker as:

```text
Status: needs-triage
```

## 3. Tickets

Use `/to-tickets` to break a spec, plan, or design into vertical slices.

Output:

```text
.scratch/<feature-slug>/issues/<NN>-<ticket-slug>.md
```

Each ticket should be independently understandable and verifiable. Prefer slices that can fit in one Perforce changelist.

Ticket creation includes initial triage. Do not default all generated tickets to `needs-triage`. Assign:

- `ready-for-agent` when all required checks are agent-verifiable
- `ready-for-human` when any HITL work or verification is required
- `needs-info` when the ticket is still too vague to classify safely

Avoid specific file paths or code snippets in ticket bodies because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.

## 4. Triage

Use `/triage` to choose the correct lane.

Agent-verifiable lane:

```text
needs-triage -> ready-for-agent -> work-in-progress -> closed
```

Use this lane only when the agent can implement the work and verify every required test case without human judgment.

Human-required lane:

```text
needs-triage -> ready-for-human -> work-in-progress -> resolved -> closed
```

Use this lane when any required check depends on human judgment, Unreal Editor validation, gameplay feel, art or design approval, level-designer usability, or Perforce reviewer confirmation.

## 5. Implementation

Use `/tdd` for new behavior or planned feature work.

Use `/diagnosing-bugs` for bugs, regressions, broken behavior, or performance problems.

Implementation should move the ticket to:

```text
Status: work-in-progress
```

## 6. Verification

For agent-verifiable work, the agent may mark the ticket:

```text
Status: closed
```

only after all required checks pass.

For HITL work, mark the ticket:

```text
Status: resolved
```

when implementation is done and all agent-runnable checks pass. A human moves it to `closed` after verification.

## 7. Review and submit

For code or documentation changes that should enter Perforce, say:

```text
review and submit {changelist name or ID}
```

The agent then follows the project review protocol: organize the changelist, check related docs, route reviewers, summarize blocking/warning/info items, and wait for a human decision before submitting.

## Supporting docs

- `Docs/agents/issue-tracker.md` defines where specs and tickets live.
- `Docs/agents/triage-labels.md` defines allowed status values and lane rules.
- `Docs/agents/domain.md` defines how agents should consume context and ADRs.

Create `CONTEXT.md` or ADRs lazily when stable project language or durable architecture decisions emerge.
