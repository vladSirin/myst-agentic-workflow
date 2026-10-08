# Restore Grill with Docs source and local composition

Type: task
Status: done; owner verification pending
Review base: cd83250
Spec: [complete Matt imports](../../../docs/plan_upstream_boundary_refresh.md#changesets-4-onward-restore-and-refresh-each-imported-skill)
and [strict source boundary](../../../docs/adr-0008-strict-upstream-boundary.md).

Preserve the complete approved grill-with-docs source and host metadata. Keep its
explicit user invocation and two-method composition. Myst selects its own grilling
and domain-modeling dependencies and project glossary/ADR pointers. Remove only
this import's pending waiver; retain credits. Do not modify dependency sources or
add a new interview method. Test direct/wrapped alignment, legacy/new docs,
missing/conflicting pointers, and explicit-only discovery. No consumer update,
publication, or Claude runtime. Owner verification remains a separate gate.

Evidence: [report](../../../docs/grill-with-docs-wrapper-2026-10-08.md).

Complete two-file source verified; no method delta. Nine grounded runtime runs
retain the initial ADR-location failure and demonstrate the local repair. Final
legacy alignment and both negative guards pass. All source/unit/package/CI checks
pass; independent Standards and Spec reviews GREEN. No consumer update or
publication. Owner acceptance is the gate before another skill changeset.
