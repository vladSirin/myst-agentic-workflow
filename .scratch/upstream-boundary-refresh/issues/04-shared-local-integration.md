# Changeset 3: Shared local integration

Type: task
Status: closed
Spec: [approved plan, Changeset 3](../../../docs/plan_upstream_boundary_refresh.md#changeset-3-establish-shared-local-integration)

## Scope

Update the local agentic-workflow contract and reference material for explicit
dependency routing, project tracker pointers, and staged glossary compatibility.
Preserve publication authority in review-and-submit. Do not migrate another
skill or change the review description format in this changeset.

## Acceptance

- Exercise Git and Perforce targets, including a Perforce target with a Git mirror.
- Resolve legacy, new, mapped, and ambiguous glossary layouts for reads and writes.
- Detect missing dependencies and missing or ambiguous project configuration.
- Show an actual wrapper load reaching the shared reference in a fresh session.
- Keep upstream sources unchanged and run the repository checks.

The owner authorized continuation from the verified handoff pilot on 2026-10-07.
This approved task moved from ready-for-agent to claimed on branch
codex/shared-local-integration. Claude execution tests remain deferred until the
owner reports that Claude works. No publication is authorized.

## Verification

The [targeted report](../../../docs/shared-local-integration-2026-10-07.md)
records fresh-session wrapper-to-reference loading, the synthetic routing
matrix, the focused path-base check, repository checks, and review findings.
Implementation and agent checks are complete. User changeset verification is
was required before the next skill migration. The owner verified continuation
on 2026-10-07 after the additional direct-versus-wrapper experiments. Local
commit: 5b3b1f3.
