# Integrate formatters and retire the standalone Review Record

Type: task
Status: implemented; both review axes GREEN; owner verification pending
Review base: 62d3738
Spec: [required description-writing changesets](../../../docs/plan_upstream_boundary_refresh.md#required-description-writing-changesets)
and [Git/Perforce format and compatibility](../../../docs/plan_upstream_boundary_refresh.md#git-and-perforce-description-writing).

Update review-and-submit only. Route Git through Myst pr and Perforce through
local p4-description, preserving upstream source. Replace What/Why/Notes and the
standalone Review Record with formatter sections and truthful final review evidence.
Remove the old body cap, append-block repair rule, and required description pass
counts. Preserve actual review execution, findings handling, re-review, preflight,
ready-for-human handling, and publication decisions. Correct P4 diff selection.

Inventory and safely test known consumer validators before exposure. Use compatible
axis labels within Evidence when possible; unknown deployed versions remain a
rollout limit. Test code, docs-only, incomplete UE asset acceptance, review states,
and approval/guard cases without publishing real changesets. Claude deferred.

Evidence: [integration report](../../../docs/review-submit-format-2026-10-08.md).
Owner verification is required before the next skill changeset.

Five bounded Codex runs pass core format, routing, evidence, and authority checks.
Standards found a missing INFO disposition in the initial Git draft. The local
evidence handoff now checks all remaining WARNING/INFO dispositions; a targeted
positive case and missing-decision control pass. Original traces remain intact.
Known P4 consumer copies pass ten controls and eleven rendered descriptions.
Deployed consumer revisions remain a rollout check; no consumer migration.
Package/source checks pass. Review evidence and limits are in the report.

Standards recheck is GREEN: the INFO repair and missing-decision control resolve
the initial WARNING. Spec is GREEN. No remaining actionable review findings.
Owner verification is the next gate; no publication or next skill is started.
