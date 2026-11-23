# Triage Labels

Tickets in `.scratch/` use one `Status:` line near the top of the file.

That single field does **two different jobs**, and keeping them apart is what stops the board from
drifting:

- a **triage role** — who should pick this up (the vocabulary the skills speak);
- a **lifecycle state** — how far the work has actually got.

A ticket carries whichever one describes it right now. It starts life with a role and ends with a
lifecycle state.

## Triage roles

| Status | Meaning |
| --- | --- |
| `needs-triage` | A maintainer needs to evaluate it and decide the lane |
| `needs-info` | Waiting on the reporter for more information |
| `ready-for-agent` | Fully specified; an agent can implement it |
| `ready-for-human` | Needs **human implementation** — an agent does not pick it up |
| `wontfix` | Will not be actioned |

Use intake triage for incoming bug reports and requests. Tickets created from an agreed spec
skip intake triage. At creation, default to `ready-for-agent` for work an agent can implement.
Use `ready-for-human` for human implementation or `needs-info` for missing details.
The maintainer can choose another role.

## Lifecycle states

| Status | Meaning |
| --- | --- |
| `claimed` | Someone is actively working it (set this before starting) |
| `resolved` | The work shipped, but at least one required check still needs a human |
| `closed` | All work and verification complete |

`resolved` **must carry an `Outstanding:` line** — which check, who performs it, where the result
gets recorded. `resolved` *means* a human check remains; a ticket that does not say which one
cannot be closed later without re-deriving it from scratch. The check that can only run after the
code ships is exactly what this state is for: the ticket goes `resolved` in the CL that ships the
code and `closed` in a later one. Never hold a code change hostage to a human, and never
pre-record a check that has not happened.

## Two rules that are easy to get wrong

**`ready-for-human` is a handoff, not a careful mode.** It means a human writes the
implementation. An agent does not take the ticket and work slowly; it reports that the ticket is
waiting for a human and moves on.

> [!CAUTION]
> **A `ready-for-human` ticket's `Status:` is user-owned — only the user changes it, to ANY
> value.** An agent that believes a ticket is mislabeled says so and stops; it never rewrites the
> field and proceeds. Not just `ready-for-agent`: every gate matches the *current* string and
> nothing records the previous one, so setting `claimed` silences them all and leaves no trace.
> Otherwise the label is self-granting — an agent that can award itself a workable state can then
> submit under a goal-mode authorization in the same run.

Use `ready-for-agent` when the expected behavior is agreed and an agent can implement the
ticket without another human decision. Record any later human acceptance check in the ticket.
Publication requires separate authorization under the project's rules and `review-and-submit`.

## Normal flows

Agent-implementable, fully agent-verifiable:

```text
needs-triage -> ready-for-agent -> claimed -> closed
```

Agent-implementable, but a human check remains after it ships:

```text
needs-triage -> ready-for-agent -> claimed -> resolved -> closed
```

Use the `resolved` step whenever a required check depends on human judgment — anything the agent
cannot run itself. Mark `resolved` when the implementation is done and every agent-runnable check
has passed; `closed` only after the human check passes.

Human-implemented:

```text
needs-triage -> ready-for-human -> (a human takes it from here)
```

Blocked on clarification:

```text
needs-triage -> needs-info -> needs-triage
```

Rejected:

```text
needs-triage -> wontfix
```

## Local adaptation

These role names are the vocabulary the skills speak. If a repo's tracker uses different strings,
map them here — the skills read this file for the mapping. Lifecycle states are this file-based
tracker's own; a hosted tracker usually expresses them with its native open/closed state instead.
