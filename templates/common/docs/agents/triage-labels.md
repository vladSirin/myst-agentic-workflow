# Triage Labels

Issues in `.scratch/` use one `Status:` line near the top of the file. The status should answer the most important workflow question: who can move this issue forward, and whether it is fully verified.

## Status labels

| Status | Meaning |
| --- | --- |
| `needs-triage` | A maintainer needs to classify the issue and decide the next lane |
| `needs-info` | More information is needed before anyone can act |
| `ready-for-agent` | An agent can implement and verify all required test cases without human judgment |
| `ready-for-human` | Human-in-the-loop work is required before the issue can be completed |
| `work-in-progress` | The issue is actively being worked |
| `resolved` | Implementation is done, but at least one required check still needs human verification |
| `closed` | All required work and verification are complete |
| `wontfix` | The issue will not be actioned |

## Normal workflow

Agent-verifiable issues:

```text
needs-triage -> ready-for-agent -> work-in-progress -> closed
```

Use this lane only when the agent can run or otherwise verify every required test case. The agent may close the issue directly after the implementation and verification pass.

Human-required issues:

```text
needs-triage -> ready-for-human -> work-in-progress -> resolved -> closed
```

Use this lane when any required check depends on human judgment, editor validation, gameplay feel, art or design approval, level-designer usability, or Perforce reviewer confirmation. Mark the issue `resolved` when the implementation is done and tests that the agent can run have passed. Mark it `closed` only after the human check passes.

Blocked clarification path:

```text
needs-triage -> needs-info -> needs-triage
```

Use `needs-info` when the issue cannot be safely classified or implemented yet. Once the missing information is supplied, return it to `needs-triage` or move it directly into the correct lane.

Rejected path:

```text
needs-triage -> wontfix
```

Use `wontfix` when the issue is intentionally not being pursued.
