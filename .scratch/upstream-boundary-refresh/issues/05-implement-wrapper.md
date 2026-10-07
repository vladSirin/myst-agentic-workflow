# Changeset 4: Restore implement behind a local wrapper

Type: task
Status: resolved
Outstanding: Owner verifies Changeset 4 in chat before the next skill migration.
Spec: [approved plan, Changesets 4 onward](../../../docs/plan_upstream_boundary_refresh.md#changesets-4-onward-restore-and-refresh-each-imported-skill)

## Scope

Preserve the complete pinned implement source and metadata. Move Myst dependency,
tracker, review, and VCS routing into its local entry. Retain explicit user
invocation. Do not migrate TDD, change the review format, or add orchestration.

## Acceptance

- Independently verify the complete source subtree and attribution.
- Review upstream-to-upstream changes separately from local integration changes.
- Show a live wrapper/source/shared-reference load and correct Myst dependency
  selection in a bounded implementation, with no unauthorized publication or
  ticket closure.
- Check a Perforce target with a nested Git mirror and a missing-dependency case.
- Run relevant repository checks and independent Standards/Spec reviews.

The owner verified Changeset 3 and authorized continuation on 2026-10-07.
This approved task moved from ready-for-agent to claimed on branch
codex/implement-source-wrapper. Claude runtime tests remain deferred until the
owner reports that Claude works. Publication is not authorized.

## Verification

[Migration evidence](../../../docs/implement-wrapper-2026-10-07.md) separates
upstream changes from local behavior and records the Git implementation,
missing-dependency, and P4 mirror preflight fixtures. Source comparison and
repository checks passed. Independent migration review is recorded there.
