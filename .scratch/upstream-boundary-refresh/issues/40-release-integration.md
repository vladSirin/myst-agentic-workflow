# Prepare upstream refresh release integration

Type: task
Status: resolved
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
No main merge, tag, release or Perforce submit is authorized by this preparation
step. Those later decisions name the exact PR, release revision or changelist.
The owner's later instruction selects UE_Blank_Proto (Perforce) and this repo
(Git) as the first examples and the existing PC 5.4 plugin for a local 5.5 update.
The owner confirmed pr and p4-description are visible as personal skills.
The candidate report quotes their result and its limits; native catalog success
alone does not prove visible-menu acceptance.

Evidence: [candidate report](../../../docs/upstream-release-candidate-2026-10-09.md).

Progress on 2026-10-09: reviewed candidate f34add6 is pushed and draft
[PR #107](https://github.com/vladSirin/myst-agentic-workflow/pull/107) is created
and attached. All six candidate CI checks pass. Disposable Codex HTTPS ref
replacement and OpenCode HTTPS copy upgrade/rollback pass with exact source
hashes and fresh catalogs. OpenCode's optional command alias appears in a
typing-only menu check. The existing PC plugin has now moved from verified 5.4.0
to the reviewed local 5.5 candidate through the normal installer. Full package
hashes and four fresh console/desktop catalogs pass for the two example projects.

UE wording follow-up: completed in a separate submitted CL. See the
[submitted receipt](../../../docs/upstream-release-candidate-2026-10-09.md#ue-wording-follow-up---2026-10-10).

Progress on 2026-10-10: the owner approved the exact PR merge, cleanup and local
PC upgrade. PR #107 is merged at d00f891; all six final PR/push checks and all
three main CI jobs pass. The contribution exception is closed and its branch
is removed. Codex and Claude packages are refreshed from merged main; four
fresh Codex catalogs pass for the two examples. The verified 5.4 rollback is
retained outside discovery, and completed test fixtures are retired. See the
[current status](../../../docs/upstream-release-candidate-2026-10-09.md#current-status---2026-10-10).

Outstanding: the owner runs 5.5 in daily use on the two selected example
projects, reports the result here or in the linked release-status record, and
then decides whether to request tagging and release. Before a requested release,
check Codex's ordinary HTTPS main-ref upgrade and record its result there.
Claude model runtime stays owner-deferred. The merged integration is resolved,
not closed; do not pre-record daily-use acceptance or a release. Further
consumer changes remain separate decisions.
