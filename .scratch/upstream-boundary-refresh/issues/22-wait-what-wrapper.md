# Restore wait-what with project glossary routing

Type: task
Status: resolved
Review base: 3c85c96
Spec: [approved plan](../../../docs/plan_upstream_boundary_refresh.md)
and [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md).

After architecture-skill acceptance, migrate wait-what alone. Preserve complete
approved source, metadata, license, and user-only invocation. Map legacy, new,
custom, and scoped domain documents outside the unchanged source. Keep the
re-explanation method intact.

Compare direct and wrapped replies for a legacy root glossary and a scoped map
with mixed filenames and conflicting terms outside the selected scope. Check
context, domain meaning, simple wording, no invented behavior, and no workspace
writes. Check package/source integrity, copy/discovery, and both review axes.
Owner acceptance is required before another skill. Claude runtime stays deferred.

Evidence: [migration report](../../../docs/wait-what-wrapper-2026-10-08.md).

All package checks and four fresh direct/wrapped tests passed. Legacy and scoped
explanations preserve the same meaning and proposal status. No fixture file or
HEAD changed. Both review axes are GREEN with zero actionable findings. The
report records wording differences and coverage limits. Owner accepted 62bcd4a on 2026-10-08 after alignment recheck.
