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

Progress on 2026-10-09: reviewed candidate f34add6 is pushed and draft
[PR #107](https://github.com/vladSirin/myst-agentic-workflow/pull/107) is created
and attached. All six candidate CI checks pass. Disposable Codex HTTPS ref
replacement and OpenCode HTTPS copy upgrade/rollback pass with exact source
hashes and fresh catalogs. OpenCode's optional command alias appears in a
typing-only menu check; Codex's authenticated menu remains unverified.

Outstanding: the owner identifies any further required consumers and decides
the exact PR merge with its stated menu/runtime limits. After an approved main
merge, check the ordinary main-ref version transition. Tagging and real consumer
updates remain separate decisions. Keep this preparation task claimed while
these integration gates remain; do not pre-record human acceptance or release.
