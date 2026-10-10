# Required upstream review and description refresh

Type: tracking task
Status: in progress

This work was already required by the approved plan; this entry makes it visible.
Spec: [description-writing changesets](../../../docs/plan_upstream_boundary_refresh.md#required-description-writing-changesets)
and [upstream review-engine changeset](../../../docs/plan_upstream_boundary_refresh.md#required-upstream-review-engine-changeset).

Execute as separate verified skill changesets, not one bulk change:

1. code-review: compare the old and approved target source, preserve the complete
   upstream package, and verify Myst's namespaced Git/P4 review routing.
2. pr: adopt the complete Git-only upstream description skill and its credits.
3. p4-description: add the local P4 counterpart without invoking Git-only pr.
4. review-and-submit: use those formatters, retire What/Why/Notes and the standalone
   Review Record, and place verified review results under Evidence. Preserve review,
   preflight, and publication authority. Required consumer-parser compatibility
   must be resolved before rollout.

The plan owns detailed acceptance criteria and format fields. This tracking
entry is not an implementation or release-completion claim. Claude runtime is
deferred; no live CL edits/submissions or Git publication are authorized by tests.

Code-review now has its own [changeset](23-code-review-wrapper.md) and
[evidence report](../../../docs/code-review-wrapper-2026-10-08.md). Its upstream
method is unchanged across the recorded pins; Myst adds the local input adapter.
Code-review bd7fbd3 is owner-verified after alignment recheck on 2026-10-08. The later review-and-submit changeset must also
replace the unsupported p4 diff -c command in VCS-MECHANICS.md with exact CL file
selection and supported diff commands. The code-review adapter already uses the
correct form. Keep formatter and Review Record retirement work in that later step.

PR adoption has [its own changeset](24-pr-wrapper.md) and [evidence](../../../docs/pr-wrapper-2026-10-08.md). Local p4-description and protocol integration remain next, after verification.

PR d8c2c53 is owner-verified after alignment recheck on 2026-10-08. Proceed with the separate local p4-description skill.

Local p4-description now has [its own changeset](25-p4-description.md) and [evidence report](../../../docs/p4-description-2026-10-08.md). Protocol integration follows after its verification.

Local p4-description 0dc4e03 is owner-verified on 2026-10-08. Proceed with review-and-submit integration.

Review-and-submit integration now has [its own changeset](26-review-submit-format.md)
and [evidence](../../../docs/review-submit-format-2026-10-08.md). Runtime/package and
known offline consumer checks pass. Independent review and owner verification
remain pending; required deployed consumer compatibility is still checked before
exposure. This tracking task does not claim full release acceptance.

Protocol Spec review is GREEN. Standards INFO-disposition WARNING is repaired
and its targeted runtime checks pass; Standards recheck and owner verification
remain pending. The repair is local; upstream source stays intact.

Standards recheck is now GREEN; Spec is GREEN. Protocol owner verification
remains pending. Required live/deployed consumer checks stay before exposure.

Review-and-submit 39a285f is owner-verified after fresh alignment on 2026-10-08.
All four skill changesets in this workstream are verified. Required deployed
consumer checks remain before exposure; this is not full release acceptance.
