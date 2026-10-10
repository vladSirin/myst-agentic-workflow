# Restore Grill-me source and explicit Myst dependency routing

Type: task
Status: done; both reviews GREEN; owner verified 1d481a5 on 2026-10-09 after alignment artifact recheck
Review base: fd1f4c0
Spec: [complete Matt imports](../../../docs/plan_upstream_boundary_refresh.md#changesets-4-onward-restore-and-refresh-each-imported-skill)
and [strict source boundary](../../../docs/adr-0008-strict-upstream-boundary.md).

Preserve the complete approved alias and Codex metadata. Add only local explicit
user invocation, project/authority context, and unambiguous Myst grilling routing.
Map the source Skill call to the host's available mechanism. Declare both copy
dependencies. Keep the grilling method intact and its own migration separate.
Remove only this waiver and preserve credits. Test direct/wrapped first-round
alignment, actual dependency loading, missing-dependency stop, automatic-request
guard, protected state, complete source/package integrity, and discovery.
No live P4 action, implementation, consumer update, publication, host configuration
change, or Claude model runtime.

Evidence: [report](../../../docs/grill-me-wrapper-2026-10-09.md).
Owner verification closed this gate after the successful alignment artifact
recheck against the committed package. The next skill can now start.
