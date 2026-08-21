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

**Triage is only for issues you did not create.** Bug reports, incoming requests, anything that
arrives raw. Tickets produced by `/to-spec` or `/to-tickets` are already specified and self-label
`ready-for-agent` — do not send them back through triage.

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
> **`ready-for-human` → `ready-for-agent` is a user-only transition.** An agent that believes a
> ticket is mislabeled says so and stops — it never relabels and proceeds. Otherwise the label is
> self-granting: an agent that can award itself `ready-for-agent` can then submit under a
> goal-mode authorization in the same run, which is the exact gate this label exists to hold.

**`ready-for-agent` is a verification label, not a submit authorization.** It answers "can the
agent verify every required test case", nothing more. Publishing the resulting change is still
human-gated outside a `/goal` run — see the submit gate hard rule in `CLAUDE.md` and the
submit-authority rule in the `review-and-submit` skill. An agent may take a `ready-for-agent`
ticket all the way to a reviewed, shelved changelist unattended; publishing it is a separate
decision with a separate gate.

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
