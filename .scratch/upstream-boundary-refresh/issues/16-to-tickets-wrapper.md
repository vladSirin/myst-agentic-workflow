# Restore to-tickets with local tracker routing

Type: task
Status: resolved
Review base: 02d444f
Spec: [approved plan](../../../docs/plan_upstream_boundary_refresh.md)
and [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md).

The owner verified to-spec and requested the next skill. Migrate to-tickets
only: complete approved source, metadata, attribution, explicit-only entry,
and a thin wrapper using the existing integration contract. Move both inline
setup references into local routing. Adopt the upstream distinction between
native blockers and parent sub-issues without rewriting its method.

Compare source revisions and previous local behavior. Check source integrity,
copy/discovery, Windows checkout bytes, and runtime behavior. Compare direct
and wrapped approved ticket creation for local and mock native trackers.
Check that missing tracker configuration and unapproved breakdowns cause no
writes. Preserve project state, parent content, and publication authority.
Run Standards and Spec reviews. Claude runtime remains deferred.

Evidence: [migration report](../../../docs/to-tickets-wrapper-2026-10-08.md).
Six runtime checks and package checks passed. Standards and Spec reviews are
GREEN with zero findings on each axis. Owner verified 5b7079d on 2026-10-08
under conditional approval after alignment recheck. Actual ticket scope, state,
blockers, and parent links align; package, trace/output hashes, and fixture
inventories match. Evidence retains the mock-tracker and planning limits.
