# Retire the obsolete merge-conflict skill

Type: task
Status: 2222413 owner-verified on 2026-10-09 by explicit removal approval; 70 disposable install assertions, eight host catalog checks and package/source checks pass; both independent reviews GREEN
Review base: f0334fe
Spec: [approved retirement and copy cleanup](../../../docs/plan_upstream_boundary_refresh.md#copy-install-cleanup-approved)
and [migration inventory](../../../docs/migration-upstream-boundary.md).

Remove resolving-merge-conflicts from the package and active README catalog.
Remove its pending waiver in the same changeset. Keep the other twenty-six
imports and five local skills unchanged. Do not retain a legacy skill copy.

Document the actual copy-install paths and manual upgrade/rollback steps.
Remove only confirmed Myst copies: resolving-merge-conflicts on upgrade;
pr, implement-spec and p4-description on rollback to pre-refresh v5.4.0.
Preserve personal edits outside discovery paths before replacement or removal.
Leave unrelated and uncertain-origin copies alone; report any name collision.
Test disposable normal copy installs, selected-snapshot catalog and byte equality,
personal/unrelated preservation, uncertain-origin refusal and rollback restoration.
Native plugin directory replacement may be simulated, with its limits disclosed.
No new installer, real installed-copy changes, release, publication or Claude
model runtime. Required source verifier must pass with no pending imports.

Evidence: [report](../../../docs/retire-merge-conflicts-2026-10-09.md).
Both review axes and owner verification passed. Combined release acceptance follows.
