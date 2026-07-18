# Triage Labels

Tickets in `.scratch/` use one `Status:` line near the top of the file. The status should answer the most important workflow question: who can move this ticket forward, and whether it is fully verified.

## Status labels

| Status | Meaning |
| --- | --- |
| `needs-triage` | A maintainer needs to classify the ticket and decide the next lane |
| `needs-info` | More information is needed before anyone can act |
| `ready-for-agent` | An agent can implement and verify all required test cases without human judgment |
| `ready-for-human` | Human-in-the-loop work is required before the ticket can be completed |
| `work-in-progress` | The ticket is actively being worked |
| `resolved` | Implementation is done, but at least one required check still needs human verification |
| `closed` | All required work and verification are complete |
| `wontfix` | The ticket will not be actioned |

## Normal workflow

Agent-verifiable tickets:

```text
needs-triage -> ready-for-agent -> work-in-progress -> closed
```

Use this lane only when the agent can run or otherwise verify every required test case. The agent may close the ticket directly after the implementation and verification pass.

Human-required tickets:

```text
needs-triage -> ready-for-human -> work-in-progress -> resolved -> closed
```

Use this lane when any required check depends on human judgment, editor validation, gameplay feel, art or design approval, level-designer usability, or Perforce reviewer confirmation. Mark the ticket `resolved` when the implementation is done and tests that the agent can run have passed. Mark it `closed` only after the human check passes.

Blocked clarification path:

```text
needs-triage -> needs-info -> needs-triage
```

Use `needs-info` when the ticket cannot be safely classified or implemented yet. Once the missing information is supplied, return it to `needs-triage` or move it directly into the correct lane.

Rejected path:

```text
needs-triage -> wontfix
```

Use `wontfix` when the ticket is intentionally not being pursued.
