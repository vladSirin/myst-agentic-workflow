# Load VCS-specific review details only when needed

Type: task
Status: closed
Spec: [VCS-specific loading follow-up](../spec.md#vcs-specific-loading-follow-up)

Make Perforce-only rules explicit and split local Git/Perforce command guides
and review-input details behind target-specific pointers. Keep the shared
protocol, two-axis review method, public triggers, source records, and upstream
bytes unchanged except for the requested local routing clarification.

Check Git, Perforce, and unresolved-target routes. Keep the review round count
continuous. Run all existing tests and mechanical gates, verify source integrity,
and run both plugin validators before updating PR #109. Keep it unmerged; no tag
or release. Record actual results and limits in maintained evidence.

Evidence: [VCS routing checks and limits](../../../docs/vcs-review-routing-2026-10-20.md).
Both review axes are GREEN in continued round 10; docs alignment is aligned.
Full tests, mechanical gates, source verification and validators pass. PR update
is authorized; merge, tag, release, local refresh and daily-use acceptance remain separate.
