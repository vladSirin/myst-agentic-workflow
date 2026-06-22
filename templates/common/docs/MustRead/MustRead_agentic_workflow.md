# Agentic Workflow Guide

**MUST_READ**: Read this guide before using `/to-prd`, `/to-issues`, `/triage`, `/tdd`, `/diagnosing-bugs`, `/improve-codebase-architecture`, `/zoom-out`, or `/grill-with-docs` in this repo.

This guide explains the recommended human workflow for turning discussion into tracked, verifiable work.

## Core workflow

```text
Discussion -> PRD -> Issues -> Triage -> Implement -> Verify -> Review/Submit
```

Use this flow when the work is more than a trivial one-off edit. The goal is to keep ideas, implementation slices, verification, and Perforce submission separate enough that humans can inspect each step.

## 1. Discussion

Use normal chat for quick clarification. Use `/roundtable` for broad design tradeoffs or `/grill-with-docs` when the plan needs to be stress-tested against project language and durable decisions.

Discussion should answer:

- What problem are we solving?
- What is out of scope?
- Does this require human-in-the-loop verification?
- Which existing docs, systems, or plans does it touch?

## 2. PRD

Use `/to-prd` when the idea is clear enough to capture as product or feature intent.

Output:

```text
.scratch/<feature-slug>/PRD.md
```

New PRDs enter the tracker as:

```text
Status: needs-triage
```

## 3. Issues

Use `/to-issues` to break a PRD, plan, or design into vertical slices.

Output:

```text
.scratch/<feature-slug>/issues/<NN>-<issue-slug>.md
```

Each issue should be independently understandable and verifiable. Prefer slices that can fit in one Perforce changelist.

Issue creation includes initial triage. Do not default all generated issues to `needs-triage`. Assign:

- `ready-for-agent` when all required checks are agent-verifiable
- `ready-for-human` when any HITL work or verification is required
- `needs-info` when the issue is still too vague to classify safely

Avoid specific file paths or code snippets in issue bodies because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.

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

Implementation should move the issue to:

```text
Status: work-in-progress
```

## 6. Verification

For agent-verifiable work, the agent may mark the issue:

```text
Status: closed
```

only after all required checks pass.

For HITL work, mark the issue:

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

- `Docs/agents/issue-tracker.md` defines where PRDs and issues live.
- `Docs/agents/triage-labels.md` defines allowed status values and lane rules.
- `Docs/agents/domain.md` defines how agents should consume context and ADRs.

Create `CONTEXT.md` or ADRs lazily when stable project language or durable architecture decisions emerge.
