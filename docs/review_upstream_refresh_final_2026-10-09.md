# Final upstream refresh review and release proposal - 2026-10-09

Historical review/proposal snapshot at 0714721. The owner subsequently said
"Good, go ahead" and authorized candidate/PR preparation. Manifest versions and
publication status below belong to this snapshot. See the
[candidate report](upstream-release-candidate-2026-10-09.md) for current work.

Status: implementation review GREEN on both axes after documentation fixes.
Release integration is proposed, not approved or published. Both real manifests
remain 5.4.0. This report does not claim full cross-host acceptance.

## Review scope

The independent reviewers examined the whole migration, not just its last
documentation changeset:

- Released base: v5.4.0, b3aeed04e0ea553af7b39f6d793e91f2ff676ff1.
- Initial review head: edbcf9a276631e235ff76e90b1839ea4eaf519ce.
  The fixed range contains 66 commits and 304 file actions with rename detection
  disabled. Complete added and deleted content was supplied to both axes.
- Initial diff SHA-256:
  f585ef5c573824ba57faaf4a23bc3b0c6f5cea260931c6a581a3a4d5b2e018aa.
- Corrected implementation head: 5b75a5b0a98c88e1042a538aeaff21b14c8205ff.
  This adds one local commit with four documentation corrections. Its committed
  diff equals the rechecked capture, SHA-256
  c571cf92fd8b35d346d9d29e8aebb14ae87085f5b61c066cd427094485a02a32.

The approved [plan](plan_upstream_boundary_refresh.md), ADR-0008/0009,
CONTRIBUTING and the source-record contract supplied the requirements. The
reviewers used Myst's code-review entry, shared integration contract and complete
upstream two-axis method. Reviewers made no edits or publication actions.

The migration contains 31 public skills: 24 Matt imports, two Hammer imports
and five local skills. The selected upstream files remain intact. Myst owns
the wrappers and routing. The sole source filename mapping is SKILL.md to
UPSTREAM.md. See the [inventory](migration-upstream-boundary.md) for each skill's
owner verification, separate review and bounded runtime alignment evidence.
Alignment means the tested methods and outcomes agree; it does not mean model
answers are identical or every possible project has been tested.

## Findings and corrections

The initial Standards review was GREEN, with no findings. The initial Spec
review was WARNING: one grouped documentation warning and one supplemental
release-draft information item.

- Fixed the stale grilling-pending claims in grill-me and grill-with-docs
  provenance. Source files, entries and metadata did not change.
- Removed ADR-0009's stale rollout status. Routed the plan's current execution
  status to the inventory instead of repeating pending formatter claims.
- Fixed the supplemental release patch's contradictory "No release ... claimed
  by this release" wording. Kept the cross-host limit. Preserved manifest line
  endings and limited each manifest hunk to its version field.
- Added the existing spec pointer to the [integration description draft](../.scratch/upstream-boundary-refresh/release-proposal/integration-pr.md).

The Spec reviewer cleared the warning after checking the exact four-file delta.
The independent docs check reported "Aligned within the correction scope."
The proposed patch and description are preparation artifacts; their completion
does not review or approve a future altered integration candidate.

## Standards

Reviewer: final_migration_standards. Full range: released base through edbcf9a.

BLOCKING: 0. WARNING: 0. INFO: 0. Worst Standards issue: none.

No documented-standard breach or actionable Fowler smell was found. The reviewer
considered all twelve required smells. Thin entries comply with ADR-0008/0009;
that required separation suppresses a generic Middle Man concern.

All 31 complete public entries, local host metadata, declared dependencies and
review/formatter references were inspected. Git-only guards cover direct and
dependent routes. User-only contracts, glossary ownership, missing dependencies,
explicit Myst review selection and human publication authority remain consistent.
DESCRIPTION-EVIDENCE's "Consumer compatibility before exposure" distinguishes
parser recognition from review acceptance.

The complete verifier, schema, tests and CI were inspected. Independent source
acquisition prevents local rehashing from approving modified source. Raw bytes,
complete companion inventories, the single filename mapping and scoped Git
attributes support the boundary. Attribution and the separate Hammer permission
basis remain explicit. Fresh gates and saved install/parser receipts support
their bounded claims.

The separate docs check identified stale progress statements that required
correction. Those are documentation defects, not method or source defects.
The supplemental release disclaimer also required correction.

HEAD, clean checkout and full diff hash matched before and after the initial
review. This verdict assesses implementation standards. It does not approve
publication or clear the unverified host and consumer limits below.

Verdict: GREEN

## Spec

Reviewer: final_migration_spec. Full range: released base through edbcf9a;
follow-up: the four-file correction committed as 5b75a5b.

Initial: BLOCKING 0; WARNING 1; INFO 1. The warning concerned stale current-state
claims. The information item concerned the supplemental release drafts.

The correction resolves the warning. Both provenance files no longer call
grilling pending; ADR-0009 retains its accepted decision; the plan points to
the inventory. Historical decisions and requirements remain intact.

The correction hash matched its capture. All 69 imported files still match their
recorded hashes. No missing skill-method requirement, scope creep or wrong
boundary behavior was found. Complete source records, invocation contracts,
Git-only guards, domain mapping, separate review axes, formatters and safe
retirement match the approved design.

The corrected supplemental patch removes its contradictory release disclaimer
and passes apply-check. It remains unapplied. The description now carries its
existing spec pointer. Actual candidate checks and publication authority remain
separate gates.

Final implementation scope: BLOCKING 0; WARNING 0; INFO 0.
Worst Spec issue: none. No full cross-host acceptance is claimed.

Verdict: GREEN

## Verification and limits

Fresh checks on the final-review source passed:

| Check | Observed result |
| --- | --- |
| Independent pinned-source acquisition | 26 imports, zero pending imports, five local skills |
| Source verifier acceptance suite | All 26 tests passed on Python 3.13.7 |
| Production CI scripts | All six local gate scripts passed, including PowerShell 5.1 |
| Offline plugin and marketplace validation | Both passed; no Claude model request |
| Corrections | Exact four-file reviewed delta; all 69 imported file hashes unchanged |
| Proposed 5.5.0 candidate | Nine applicable gates passed in a disposable copy; all other 186 plugin files match the corrected source |
| Proposed patch | Apply-check passed; two manifest version fields and CHANGELOG only; real manifests remain 5.4.0 |
| Remote release target | main and v5.4.0 point to the released base; no v5.5.0 tag or remote migration branch was returned |

The [combined acceptance report](upstream-release-acceptance-2026-10-09.md)
holds the install/consumer matrix: project copy 29 -> 31 -> 29, global copy
upgrade/rollback, actual native offline local-marketplace selection/rollback,
preserved personal edits, uncertain-origin controls and 21 current UE parser
replays. Those earlier checks were not rerun for unchanged skill methods.
Parser recognition proves compatibility, not review approval or submit readiness.

Claude model runtime remains deferred by the owner. Native remote Git update
and native slash-menu checks remain unverified. Known consumer scope is
UE_Blank_Proto; broader required scope is unconfirmed. These limits remain release
decisions. They cannot be reported as passes. No live Perforce submit, webhook
delivery, consumer edit or real plugin update was performed.

Evidence root: %TEMP%/myst-final-review-20261009. It contains the original full
diff/commit list, correction capture, fresh ten-check logs, corrected candidate
nine-check logs, raw-file proof and local commit receipt. Failed preparation
harnesses remain saved: an initial candidate tool-path error, a manifest EOL
rewrite and a mixed-EOL changelog assertion. Only the harness/proposed artifacts
were corrected; none required an upstream method change.
The saved patch has a path-specific Git attribute that preserves its bytes and
allows its blank context-line syntax. Other files keep their whitespace checks.

## Proposed release integration

Recommend one MINOR release, provisionally 5.5.0. Current version rules treat
plugin additions, behavior changes and retirement as MINOR. Copy users already
manage stale names. No install channel or consumer vocabulary rename is required.
A newly identified incompatible required consumer can change this decision.

1. Prepare the final candidate from the reviewed stack. Fast-forward the local
   codex/upstream-boundary-refresh branch to the accepted proposal head; preserve
   the per-skill history and review links. Remote main still equals the base.
   Apply the [proposed version/notes patch](../.scratch/upstream-boundary-refresh/release-proposal/5.5.0.patch)
   only in that candidate. Refresh its date if needed. Prepare migration-exception
   closeout and final status updates to take effect with main integration.
   Re-pin and review that exact additional scope. No intermediate tags or bumps.
2. With explicit publication approval for that candidate, push the migration
   branch and open one final integration PR to main. Use the prepared description,
   current actual axis results and per-skill evidence links. Attach the created
   PR to this chat. Run remote CI and test the actual HTTPS marketplace route in
   disposable host homes. Use supported ref selection and update/rollback;
   distinguish candidate-ref replacement from ordinary same-branch update.
   Check Codex/OpenCode slash discovery in fresh sessions. Keep Claude runtime
   deferred. Add any further required consumer before exposing the new format.
3. Present the exact PR and remaining limits for the owner's merge decision.
   Merge only through review-and-submit. Tag the approved main merge separately;
   pushing v5.5.0 triggers the existing GitHub Release workflow. If an ordinary
   default-branch update can only be tested after merge, disclose that exposure
   before merge and complete the check before tagging. No full-compliance claim
   while deferred controls remain.
4. Update required consumers through their normal route and verify the selected
   snapshot in a fresh session. Native plugins use normal update/replacement;
   Codex local-path sources need plugin add again. Copy installs follow the
   [cleanup guide](upstream-refresh-install-cleanup.md), preserving edits and
   removing only proven obsolete Myst copies. Close the migration exception
   with integration and resume one-skill PRs against main.

Rollback uses the exact v5.4.0 snapshot. Native hosts select it through their
normal route. Copy users preserve edits, remove only proven new-only Myst
pr/implement-spec/p4-description copies, and reinstall the baseline. Do not
rewrite a published tag; use a separately reviewed revert/release if needed.

The [proposal checks](../.scratch/upstream-boundary-refresh/release-proposal/checks.json)
record the saved patch hash and validation. Actual merge, tag, release and
consumer-update acceptance remain pending. This proposal requests no Claude
test rerun and no repeat of all unchanged per-skill model tests.

## Proposal artifact checks

Both independent reviewers checked the five staged proposal paths against
5b75a5b, including all four complete additions and the exact patch-path Git
attribute. The fixed preparation diff SHA-256 was
07cb61fee2eed8d03864617cb5dfabad520d65cb4df6a9673dddd970b0dd9233.
The following results are rendered from those actual reports; this rendering
adds no new requirement or publication authority.

### Standards

Reviewer: final_migration_standards.
BLOCKING: 0; WARNING: 0; INFO: 0. Worst Standards issue: none.

No documented-standard breach or actionable smell was found across the twelve
required heuristics. The report preserves separate axis results and revision
limits. The description carries its spec pointer, three sections, line-start
axis fields and explicit pending release-candidate review. The proposed sequence
keeps candidate review, publication decisions, update, cleanup and rollback.

The patch changes only the two version fields and release notes; apply-check
passes. Manifest line endings match the existing LF files. The Git attribute
applies only to the saved patch. All five file hashes, staged diff hash, branch
and base matched before and after. Both actual manifests remain 5.4.0.

Verdict: GREEN

### Spec

Reviewer: final_migration_spec.
BLOCKING: 0; WARNING: 0; INFO: 0. Worst Spec issue: none.

The five paths meet the preparation scope. No missing requirement, scope creep
or wrong implementation was found. The prior information item is resolved:
Summary carries its existing Ticket and Spec pointers, and the patch retains
the cross-host limit without its contradictory release disclaimer.

The report distinguishes the full migration, documentation correction and
future integration candidate. Required compatibility and publication decisions
remain. Independent byte checks confirm each manifest preserves its existing
line endings and changes only the version. All artifact hashes, exact scope,
base and branch matched before and after. Both diff-check and apply-check pass.

Verdict: GREEN

Independent docs preflight: "Aligned within the five-file proposal scope."
It confirmed receipts support the bounded claims and that pending release
actions remain separate from completed implementation checks.
