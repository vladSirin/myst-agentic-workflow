---
name: agentic-workflow
description: "Team delivery process (discussion -> spec -> tickets -> triage -> implementation -> verification -> review/submit). Use when starting any non-trivial feature work, or when unsure which process stage applies."
---

# Agentic Workflow

## Scope and relationship to the design skill

This workflow is the **end-to-end shape** for non-trivial work: discussion → captured intent (spec) → planned slices (tickets) → triaged → built → verified → submitted.

For work involving **game design** (mechanics, UX, levels, player experience), the Discussion phase is **extended** via the [design](../design/SKILL.md) skill — that produces a finalized design doc in the design-docs directory identified by the project's instructions, and the spec phase here references it. For pure code / system / bugfix work, Discussion can stay in chat and you jump straight to the spec (`/to-spec`).

Three flow shapes the project supports:

| Work shape | Flow |
|---|---|
| **Game design + implementation** | `design` skill → finalized doc → **this workflow** (Spec → Tickets → Triage → Implement → Verify → Review/Submit), with the spec referencing the design doc |
| **Pure code / system / bugfix** | **This workflow** directly; Discussion happens in chat |
| **Pure game design, no code** | `design` skill only — no spec/tickets needed |

Examples that go straight to this workflow (no `design`-skill Discussion):

- Refactor or extend a subsystem (flow control, objectives, event-system integration, etc.)
- Fix a bug or regression
- Build a tool, pipeline, or CI mechanism
- Integrate a new plugin or library

If you're not sure which shape: would the deliverable be read primarily by a game designer / LD → use the `design` skill first. Read primarily by an engineer → jump straight here.

---

## Mandatory workflow for non-trivial work

When a user asks for non-trivial in-scope (see above) work, use this workflow unless the user explicitly asks for a narrower action.

```text
Discussion -> Spec -> Tickets -> Triage -> Implement -> Verify -> Review/Submit
```

**The pre-implementation gate**: implementation is the LAST phase, not the first. Before
proposing any plan that spans multiple changesets, verify the earlier phases actually
happened — a spec exists, vertical-slice tickets exist, and at least one is triaged
`ready-for-agent` — or the user has explicitly skipped the workflow, recorded as
`Workflow: skipped (<reason>)` in each changeset description. A `ready-for-human` ticket is
a handoff to a human, never work you pick up. Teams may enforce this gate with their own
always-on rule files; this paragraph is the workflow's own statement of it.

## Required references

Before dispatching another skill, changing tracker state, resolving domain
vocabulary, or following VCS instructions, read
[the local integration contract](LOCAL-INTEGRATION.md). It owns dependency
selection, target VCS checks, project pointers, and legacy/new glossary mapping.
Wrappers that need shared integration must load that reference before their
upstream workflow.

Before creating or updating specs, tickets, or workflow state, resolve and read
the project's workflow guide, tracker, and triage model through its applicable
AGENTS.md / CLAUDE.md or existing scoped spec. Read the project's domain docs
before naming concepts and relevant ADRs before architecture changes. Missing
or conflicting configuration must be resolved before dependent writes.

## Stage rules

### 1. Discussion

Use normal conversation, `/roundtable`, or `/grill-with-docs` while intent is unclear. Do not create speculative implementation tickets until the problem, scope, and verification expectations are clear.

### 2. Spec

Use `/to-spec` or write the spec at the location defined by the project tracker
(default: `.scratch/<feature-slug>/spec.md`) when the idea is ready to capture. New specs start at `Status: needs-triage`.

### 3. Tickets

Use `/to-tickets` or write ticket files at the project tracker location
(default: `.scratch/<feature-slug>/issues/`). Tickets must be vertical slices, independently understandable, and small enough to verify.

Assign initial ticket status during creation: `ready-for-agent`, `ready-for-human`, or `needs-info`. Do not default generated tickets back to `needs-triage` — tickets you generated from a spec are already specified, so they skip triage, which is for issues that arrive raw from elsewhere.

Avoid specific file paths or code snippets in ticket bodies because they go stale quickly. Exception: include a compact prototype-derived snippet only when it captures a decision more precisely than prose can.

### 4. Triage

Use the project's resolved triage model. The roles below are the default when
the project has adopted Myst's model.

Triage **roles** say who should pick the ticket up:

- `needs-triage`: not yet evaluated.
- `needs-info`: missing information blocks safe classification or implementation.
- `ready-for-agent`: fully specified; an agent can implement it.
- `ready-for-human`: a human implements this one. An agent does not pick it up, and **only the user** changes its `Status:` — to any value, not just `ready-for-agent`.
- `wontfix`: intentionally not pursued.

### 5. Implementation

Use `/tdd` for planned feature work and `/diagnosing-bugs` for bugs or regressions. Set a **`ready-for-agent`** ticket to `Status: claimed` while working — never a `ready-for-human` one.

### 6. Verification

Lifecycle states say how far the work has got:

- Fully agent-verifiable tickets move from `claimed` to `closed` once all checks pass.
- Work that ships but still needs a human check moves to `resolved`, carrying an `Outstanding:` line naming that check, who performs it, and where the result is recorded. Only that human check moves it to `closed` — in a later CL, never pre-recorded in the one that ships the code.

### 7. Review and submit

For publication (Perforce submit, or git merge/PR), follow the `review-and-submit` skill. Never publish without explicit user approval.

## Guardrails

- Search before creating a planning artifact: Glob `plan_*.md` and `design_*.md` under the design-docs directory identified by the project's instructions, plus specs in the resolved tracker, for the feature/system/phase name. If one exists, extend it rather than opening a second — duplicates don't error, they split the source of truth.
- Do not batch multiple changesets without explicit user approval; follow the `changelist-verification` skill.
- Do not modify the game Docs dir's `_Raw/` (where the project defines a protected raw-material area) without the protected-material approval flow.
- Keep ticket state changes explicit in the issue file's `Status:` line.
