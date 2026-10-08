# Adopt Git-only pr with local review evidence

Type: task
Status: implemented; both reviews GREEN; owner verification pending
Review base: eaf9944
Spec: [description-writing changesets](../../../docs/plan_upstream_boundary_refresh.md#required-description-writing-changesets)
and [Git-only skills](../../../docs/plan_upstream_boundary_refresh.md#git-only-skills-pr-and-implement-spec).

Import the full pinned pr source, metadata, MIT notice, and show-me credits.
Keep source intact; local files own Git-only selection, glossary mapping,
ticket/source pointers, factual review evidence, and publication limits.
Test Git direct/wrapped alignment, supplied review states and evidence gaps,
and direct/automatic/cross-skill P4 exclusion with a nested Git mirror.
Do not publish a PR or change a CL. Keep review-and-submit's formatter change
and local p4-description in their separate later changesets. Claude deferred.

Evidence: [migration report](../../../docs/pr-wrapper-2026-10-08.md).
Owner verification is required before starting the next skill.

Seven selected runtime cases passed: two aligned Git pairs (normal and five review
states), plus direct/automatic/cross-skill P4 exclusion with a Git mirror. One
initial reader-startup failure is retained; the identical-input retry passed.
Package checks, independent source verification, and both review axes are GREEN.
Next after owner verification: local p4-description. No publication included.
