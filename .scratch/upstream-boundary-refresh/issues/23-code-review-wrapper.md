# Preserve code-review and route Git/Perforce evidence

Type: task
Status: resolved; bd7fbd3 owner-verified after alignment recheck on 2026-10-08
Review base: cbed6f0
Spec: [review-engine milestone](../../../docs/plan_upstream_boundary_refresh.md#required-upstream-review-engine-changeset)
and [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md).

Migrate code-review alone. Compare its historical pin to the approved target;
preserve complete source, metadata, and license. Report unchanged method honestly.
Keep engine identity, project tracker/spec lookup, and Git/Perforce evidence in
local files. Preserve separate parallel Standards/Spec reviews and the complete
smell baseline. Review-and-submit formatting/publication is a later changeset.

Test the intended engine with a competing review plugin present. Compare direct
and wrapped Git reviews of known standards/spec defects. Exercise pending Perforce
CL evidence, including added/deleted files and a misleading nested Git mirror.
Check evidence-gap and explicit no-spec behavior. No live P4 service or publication.
Verify package checks and both independent review axes. Owner acceptance is
required before the next skill. Claude runtime stays deferred.

Evidence: [migration report](../../../docs/code-review-wrapper-2026-10-08.md).

Complete source is unchanged across the recorded pins. Eight fresh Codex cases
passed the bounded checks, including direct alignment and explicit full-path
selection with a competing plugin present. Fixture files and HEADs stayed intact.
The temporary test plugin was removed; host plugin/marketplace settings match the
pre-test baseline. Both independent review axes are GREEN. Package checks passed.
No publication or installed Myst update. Next skill after owner acceptance: pr.

Owner conditional acceptance fulfilled after the saved alignment evidence recheck.
