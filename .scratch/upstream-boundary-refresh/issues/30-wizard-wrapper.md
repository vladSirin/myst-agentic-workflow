# Restore Wizard source and local setup/capture routing

Type: task
Status: implementation and alignment checks complete; both reviews GREEN; owner verification pending
Review base: 26b7743
Spec: [complete Matt imports](../../../docs/plan_upstream_boundary_refresh.md#changesets-4-onward-restore-and-refresh-each-imported-skill)
and [strict source boundary](../../../docs/adr-0008-strict-upstream-boundary.md).

Preserve the complete approved wizard entry, fixed Bash template, and Codex
metadata. Move only project setup/CI, VCS capture, and authority into a local
entry. Preserve human-only step selection, scope confirmation, stage authoring,
static verification, and human execution. Keep model/user reach, declare copy
dependencies, remove only this waiver, retain credits. Test direct/wrapped
authoring alignment, exact generated library bytes, values/destinations, hidden
entry and irreversible confirmation, P4 repeatable capture despite a Git mirror,
scope-confirmation pause, source/package integrity, and discovery.
No full wizard execution, actual secrets, shared service writes, live P4,
consumer update, publication, or Claude runtime.

Evidence: [report](../../../docs/wizard-wrapper-2026-10-09.md).
Owner verification remains the gate before another skill changeset.
