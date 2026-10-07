# Upstream refresh plan review

Date: 2026-10-07. The original review did not edit the plan or skill files.

Target: plan v1.4. The [current approved plan](plan_upstream_boundary_refresh.md)
includes the later decisions recorded below.
SHA-256: `C99E425D5264D4ADFDA1335BCAEAA331DD249E423705D65DFA9ED54A23082A55`.
The hash was unchanged before and after the three subagent reviews.

## Assessment

The agreed scope is consistent. One rollout issue needs resolution before
implementation is ready to proceed as written. Three further clarifications
would make execution and validation reliable. These are proposal findings,
not evidence of defects in a shipped implementation.

Review coverage:

- Scope and user decisions: no actionable findings.
- Technical feasibility: two P2 findings.
- Rollout and dependencies: one P1 and one P2 finding, plus a concrete consumer
  dependency already covered by the plan's migration gate.

## Findings

### P1: Decide how partial migration stays off the consumer update path

Plan anchor: **Final changeset: Complete documentation and release readiness**,
line 510, together with the one-skill-per-PR sequence at lines 401-405.

The plan leaves the full compatibility check and manifest update until the
final changeset. CONTRIBUTING requires a bump/tag per merge to main, and the
marketplace points at the repository's plugin tree. Fresh consumers can
therefore encounter a partially migrated catalog. A specific intermediate
conflict is the new pr format while the old review-and-submit still requires
the standalone Review Record. Delaying the release tag alone does not isolate
that state.

Choose one strategy in Changeset 0: independently compatible releases per
merge, or an explicitly agreed migration branch with per-skill PRs and a final
integration/release step. The latter needs a documented exception to the
current main-target contribution process. Schedule required consumer-parser
changes before the first exposed formatter switch.

Evidence: [CONTRIBUTING](../CONTRIBUTING.md),
[Claude marketplace](../.claude-plugin/marketplace.json),
[Codex marketplace](../.agents/plugins/marketplace.json).

### P2: Define the review/publication unit before worker dispatch

Plan anchor: **Git-only skills: pr and implement-spec**, lines 383-387.

The plan preserves the existing sequential-changeset rule but does not say
whether ticket branches are independent changesets or internal work within one
integration PR. That distinction controls whether workers may run together.
A successful dependency-graph test cannot settle this policy question.

Have the coordinator establish the intended review/publication units before
dispatch. Independent tasks within one already agreed changeset may run in
parallel; distinct changesets retain the existing verification gate or its
explicit user override. Do not regroup agreed changesets merely to allow
concurrency. Include both cases in the Git pilot.

Evidence: [changelist-verification](../plugins/myst-dev-kit/skills/changelist-verification/SKILL.md),
[pinned implement-spec](https://github.com/mattpocock/skills/blob/6fd947921b935b7e1e69293a200400f0fdd5c15f/skills/engineering/implement-spec/SKILL.md).

### P2: Define how background workers obtain TDD decisions

Plan anchor: **The first implement-spec pilot**, lines 389-392.

Pinned implement-spec directs workers to use tdd. Pinned tdd requires the user
to confirm test seams before tests are written. The pilot currently covers
dependency and ownership handling, but not this required interaction. Workers
can stall independently or bypass the confirmation without a coordinator path.

Pass existing seam approval as a context pointer. When approval is absent or a
seam changes, the worker returns the question to the coordinator and waits.
The coordinator obtains the answer before resuming that worker. Test both an
already approved seam and a ticket that requires clarification.

Evidence: [pinned tdd, Seams](https://github.com/mattpocock/skills/blob/6fd947921b935b7e1e69293a200400f0fdd5c15f/skills/engineering/tdd/SKILL.md).

### P2: Specify copy-install cleanup during upgrade and rollback

Plan anchor: **Troubleshooting and rollback**, line 573, and removal of
resolving-merge-conflicts under **Upstream disposition**.

Re-running the add command does not establish that obsolete copy-installed
skills are removed. Upgrading must account for resolving-merge-conflicts;
rolling back must account for newly introduced pr, implement-spec, and
p4-description. Otherwise stale entries can remain discoverable after the
reported version changes.

Document removal of confirmed Myst-owned obsolete copies while preserving
personal edits and unrelated skills. Add upgrade and rollback fixtures that
check the discoverable catalog. This fits the existing install matrix and does
not require a new installer.

Evidence: [CONTRIBUTING versioning](../CONTRIBUTING.md),
[CHANGELOG versioning](../CHANGELOG.md).

## Concrete consumer dependency

The rollout reviewer inspected the workspace copy of
`C:/_LocalDev/UE_Blank_Proto/Tools/P4Triggers/p4-submit-audit-server.sh:196`.
Its review-evidence regex does not recognize the proposed line
`- Review: Standards GREEN; Spec GREEN.`. It recognizes forms such as
Reviewed/Reviewer, Verdict, LGTM/Approved, Review Record, or line-start
Standards:/Spec:. This can produce a false missing-review-evidence warning
for a large risky CL. It is not evidence that submission is rejected.

The plan already requires a consumer inventory and migration gate, so this is
a named dependency, not an additional missing-gate finding. Use compatible
concise wording or update the parser before exposure. The deployed server
revision was not verified.

## Not findings

Nested SKILL.md discovery, cross-host wrapper loading, and unavailable Claude
runtime verification already have explicit pilot gates. They remain unverified;
the reviewers did not treat them as proven failures or omitted requirements.

No scope drift was found in the Git-only restrictions, P4 description skill,
retirement of the old Review Record format, upstream source preservation,
skill exclusions, or removal of P4 whole-spec orchestration.

## User decisions after review

The findings above describe v1.4 and remain as review history. Later plan versions record
the following later decisions:

- Finding 1: accepted the migration-branch strategy, with per-skill reviews and
  one final integration/release. Document the temporary contribution exceptions.
- Findings 2 and 3: do not add the proposed changeset-mapping procedure or TDD
  question relay preemptively. Preserve upstream behavior and the already
  agreed Myst boundaries. Add local handling only if the pilot shows a concrete
  problem. Upstream source files remain intact.
- Finding 4: subsequently accepted. Document removal of obsolete Myst-owned
  copy installs, preserve personal edits, and validate upgrade/rollback catalogs.
  No automatic deletion system is planned.

The user approved implementation after settling all findings. Plan v1.6 is
approved, with the existing changeset verification and publication gates.

These are planning decisions, not evidence of implementation or runtime checks.
