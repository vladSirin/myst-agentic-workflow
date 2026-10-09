# Prepare upstream refresh release integration

Type: task
Status: claimed
Spec: [final integration](../../../docs/plan_upstream_boundary_refresh.md#final-changeset-complete-documentation-and-integrate-the-release)
Proposal: [reviewed release sequence](../../../docs/review_upstream_refresh_final_2026-10-09.md#proposed-release-integration)

Owner authorization on 2026-10-09 after the full review/proposal: "Good, go ahead."
Prepare the reviewed stack on codex/upstream-boundary-refresh, the single 5.5.0
manifest/notes bump, and contribution-exception closeout effective on main merge.
Keep source and skill behavior unchanged. Review the actual candidate, run
preflight, push that branch and create the one integration PR to main. Attach
the created PR to this chat. Use the existing three-section Git description
with actual review evidence and explicit pending controls.

Run useful HTTPS/native update and fresh host discovery checks in disposable
profiles. Preserve normal host configuration and do not copy credentials.
Distinguish ref replacement from ordinary same-branch upgrade. Confirm required
consumer scope before exposure. Keep Claude model runtime deferred as directed.
No main merge, tag, release or real consumer/plugin update is authorized by this
preparation step. Those later decisions name the exact PR or release revision.

Evidence: [candidate report](../../../docs/upstream-release-candidate-2026-10-09.md).
