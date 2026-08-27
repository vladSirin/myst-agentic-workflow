# Agentic Workflow Guide

**MUST_READ**: Read this guide before using `/to-spec`, `/to-tickets`, `/triage`, `/tdd`, `/diagnosing-bugs`, `/improve-codebase-architecture`, or `/grill-with-docs` in this repo.

This guide explains the recommended human workflow for turning discussion into tracked, verifiable work.

## Before any of this works: get the kit

Every slash command named above ships in the `myst-dev-kit` plugin, which is installed **once per user**. It does not arrive with your version-control sync, and **nothing installs it when you trust the repo** — there is no plugin prompt to accept. Install it by typing `/plugin install myst-dev-kit@myst` into the Claude chat box. No `marketplace add` step is needed inside this project: the committed `.claude/settings.json` pre-registers the `myst` marketplace. Restart the session afterwards — Claude loads a new plugin version only at session start. Codex and OpenCode users: see the per-tool install table in the `myst-agentic-workflow` repo's README.

Full onboarding for all three tools is **SETUP.md** in the `myst-agentic-workflow` repo. Migrating from v4 of the kit: the CHANGELOG's v5.0.0 section lists the two commands.

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

Ticket creation includes initial triage. Do not default all generated tickets to `needs-triage` — triage is for issues that arrive raw from elsewhere, and tickets you generated from a spec are already specified. Assign:

- `ready-for-agent` when an agent can implement it
- `ready-for-human` when a **human** must write the implementation
- `needs-info` when the ticket is still too vague to classify safely

Avoid specific file paths or code snippets in ticket bodies because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.

## 4. Triage

Use `/triage` to choose the correct lane — for issues that arrived raw. Tickets `/to-tickets` produced are already agent-ready and skip this step.

The `Status:` field carries either a **triage role** (who picks it up) or a **lifecycle state** (how far it got). Full definitions: `Docs/agents/triage-labels.md`.

Agent-implementable, fully agent-verifiable:

```text
needs-triage -> ready-for-agent -> claimed -> closed
```

Agent-implementable, but a human check remains after it ships:

```text
needs-triage -> ready-for-agent -> claimed -> resolved -> closed
```

Use the `resolved` step when any required check depends on human judgment — Unreal Editor validation, gameplay feel, art or design approval, level-designer usability, or Perforce reviewer confirmation. It carries an `Outstanding:` line naming that check.

Human-implemented:

```text
needs-triage -> ready-for-human -> (a human takes it from here)
```

`ready-for-human` means a human writes the implementation — an agent does not pick the ticket up, and **only the user** changes its `Status:`, to any value (see `Docs/agents/triage-labels.md`).

## 5. Implementation

Use `/tdd` for new behavior or planned feature work.

Use `/diagnosing-bugs` for bugs, regressions, broken behavior, or performance problems.

Implementation moves a **`ready-for-agent`** ticket to:

```text
Status: claimed
```

Never a `ready-for-human` one — that ticket is not yours to start, and its `Status:` is user-owned.

## 6. Verification

When the agent can run every required check itself, it may mark the ticket:

```text
Status: closed
```

only after all of them pass.

When a required check needs a human, mark the ticket:

```text
Status: resolved
Outstanding: <which check, who performs it, where the result is recorded>
```

once the implementation is done and every agent-runnable check has passed. A human moves it to `closed` after verification — in a later changelist, never pre-recorded in the one that ships the code.

## 7. Review and submit

For code or documentation changes that should enter Perforce, name the changelist and ask for submission — any explicit form works:

```text
review and submit {changelist name or ID}
submit {CL}
```

The agent then follows the project review protocol, scaled to the changelist: docs-only changelists (documentation trees only — rules/hooks/workflow files review as code) take a lightweight self-check (tags, file list, EOLs, a one-line review record), while code and asset changelists get the full routing — organize the changelist, check related docs, route reviewers, summarize blocking/warning/info items. Either way the agent waits for a human decision before submitting: the review scales, the human gate does not.

## Supporting docs

- `Docs/agents/issue-tracker.md` defines where specs and tickets live.
- `Docs/agents/triage-labels.md` defines allowed status values and lane rules.
- `Docs/agents/domain.md` defines how agents should consume context and ADRs.

Create `CONTEXT.md` or ADRs lazily when stable project language or durable architecture decisions emerge.
