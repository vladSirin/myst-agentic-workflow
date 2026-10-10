# Add the local Perforce description formatter

Type: task
Status: resolved; 0dc4e03 owner-verified on 2026-10-08
Review base: c17c3f2
Spec: [Git and Perforce description writing](../../../docs/plan_upstream_boundary_refresh.md#git-and-perforce-description-writing)
and [required formatter changesets](../../../docs/plan_upstream_boundary_refresh.md#required-description-writing-changesets).

Author p4-description locally with pr/show-me attribution. No second upstream
bundle and no runtime pr dependency. Preserve established title tags, brief
English/ASCII output, ticket/source pointers, exact CL evidence and stable finding
anchors. Use Summary / Evidence / Submit Risk; preserve real review states,
evidence gaps, human acceptance, and reversibility limits. Draft only.
Test direct, automatic, and cross-skill P4 use with a Git mirror; negative evidence
and history cases; no publication. Review-and-submit integration is the next
separate changeset. Claude runtime remains deferred. Owner verification required.

Evidence: [report](../../../docs/p4-description-2026-10-08.md).

Eight selected runtime cases passed, including all invocation routes, ASCII
output, review-state handling, missing/conflicting history, stale evidence,
data-loss risk, and Git exclusion. Three initial reader failures are retained;
identical-input retries passed. Exact candidate packages, fixture inventories,
and HEADs were verified. Package/source checks and both review axes are GREEN.
Next after owner verification: review-and-submit integration and parser checks.

Owner explicitly verified this skill as OK and authorized protocol integration.
