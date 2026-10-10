# Combined upstream refresh acceptance - 2026-10-09

Historical preparation snapshot at edbcf9a. The status, manifest versions and
pending controls below describe that captured stage. The owner later approved
continuing with the release proposal. See the
[current release status](upstream-release-candidate-2026-10-09.md#current-status---2026-10-10)
for the merged preview and remaining controls. Completed temporary fixtures
were retired after merge; their paths below describe this historical snapshot.

Status: release documentation and bounded combined checks complete. Both
independent reviews GREEN; owner verification pending. Review base: 99cd0c8. The installed and
published version has not changed. This report does not claim full cross-host
acceptance. Known consumer scope is UE_Blank_Proto; broader scope has not been
confirmed. The owner can extend that scope before exposure.

## Package and source

The package contains 31 public skills: 24 Matt imports, two Hammer imports and
five local skills. Every imported package has a complete pinned source record,
provenance and unchanged plain source. The sole filename mapping is SKILL.md to
UPSTREAM.md. Myst routing remains outside source. All individual changes and
resolving-merge-conflicts retirement have owner verification in the
[inventory](migration-upstream-boundary.md); their separate reviews and runtime
traces remain the evidence for unchanged methods and integration.

Matt pin: 6fd947921b935b7e1e69293a200400f0fdd5c15f.
Hammer pin: v0.30.0, Intel release asset 614238989, with full archive and member
hashes in the two UPSTREAM.json records. Existing Hammer authorization remains
in provenance; the MIT notice does not grant a Hammer license.
Rollback baseline: v5.4.0, b3aeed04e0ea553af7b39f6d793e91f2ff676ff1 (29 skills).

LICENSE now records current and historical Matt pins and the separate Hammer
permission basis. CONTRIBUTING reflects complete current source records. Draft
CHANGELOG notes record added/retired skills, formatter changes, copy dependencies
and exact pins. Both manifests remain 5.4.0; the migration exception remains open.
The legacy context-format example's complete original body stays byte-identical
under a local path-resolution preface. Starter workflow guidance uses selected
domain paths and actual Evidence rather than prescribing a new CONTEXT.md.
No consumer rename or second glossary is required.

## Install and update matrix

| Route | Evidence | Limit |
| --- | --- | --- |
| Project copy: Codex / Claude / OpenCode | Retirement tests: nine normal add calls, 70 assertions, exact 29 -> 31 -> 29 trees, personal/unrelated preservation and unknown-origin controls; eight fresh Codex/OpenCode catalogs | Claude is a physical copy target; native slash UI untested |
| Global copy: Codex / Claude / OpenCode | Three normal --global --copy add calls in an asserted disposable Node home profile; complete snapshot equality on baseline/upgrade/rollback; CLI list checks; four verified personal-edit backups | Native global host menus untested; no real personal directory touched |
| Native Codex, local marketplace | Normal CLI baseline install matches all files; fresh native catalog has 29 namespaced entries. Re-add selects the candidate with 31 entries and exact full-tree equality. Rollback re-add returns 29 entries | Marketplace upgrade alone leaves a local-path plugin cached; documented in SETUP |
| Native Claude, local marketplace, offline | Normal baseline install, marketplace update + plugin update to candidate, then rollback update; installed versions and complete trees match selected snapshots | No Claude model runtime or slash-menu pass claimed |
| Native remote Git marketplace transition | Not exercised for this unpublished candidate. Both CLIs reject file:// as a marketplace source; local-path fallback uses the normal supported route | HTTPS/auth transport and remote version transition remain unverified |

CLI versions: Codex 0.162.0-alpha.2; Claude Code 2.1.292; skills 1.7.1;
OpenCode 1.18.35 in the earlier project-copy receipts. Node is v22.19.0 here.
The native candidate fixture changes only the two manifest versions to 5.5.0
to exercise cache selection. All skill files match the repository candidate.
That number is confined to the fixture, not a released version.

Native tests set process-local CODEX_HOME and CLAUDE_CONFIG_DIR to disposable
directories; no credentials were copied and no model request ran. Rust Codex
still sees ordinary personal skill paths, so comparisons select only entries
inside the fixture's Myst cache. Three real host configuration hashes remained
unchanged. Global copy checks first assert Node's homedir is the disposable
USERPROFILE; their copy roots are within that profile.

The initial native catalog assertion compared namespaced public names with bare
directory names. The saved response already contained all 29 entries. The check
was corrected to remove exactly the Myst namespace while retaining path scope
and uniqueness. The failed harness and receipt remain. Unsupported file://
registration attempts also remain. No source change produced these test passes.

## Known consumer compatibility

The known consumer is UE_Blank_Proto. Read-only checks used p4admin at
192.168.50.196:1666 and verified client p4admin_Sirin-Dragon_main_2783 maps to
C:/_LocalDev/UE_Blank_Proto. No CL, opened file, shelf or consumer edit was made.
Only parsed trigger name/type/depot path were saved; command arguments can carry
secrets and were neither logged nor copied to fixtures.

The active submit-audit change-commit trigger references the depot-stored
//UEPrototype/main/Tools/P4Triggers/p4-submit-audit-server.sh. Its #15 is at
CL3648, SHA-256 2a73fd858b5eeb93fe299fe19177298e19cad22b702e385b6db357aaf5a7990c.
The workspace copy matches exactly. The description preflight is #1 at CL3697,
SHA-256 f159301bbfe2df476767d17cb213399774366a2295da82bb81ed56d79fae40ea.
Its workspace content differs only in CRLF. The current test-hooks #16 and
doc-audit #7 were also identified; no pending action was reported for these files.

Twenty-one preserved description cases replayed against the freshly printed
head audit, head preflight and actual workspace preflight in disposable offline
fixtures. They include eleven actual model-rendered bodies and ten controls:
GREEN, WARNING, BLOCKING, confirmed skip, missing review, old record, inline
review, no evidence, bad title and non-ASCII. All expected exits and review-marker
warnings match. Consumer workspace hashes remained unchanged afterward.

The audit's documented SA_TEST_* inputs skip P4 reads; P4ROOT points at disposable
logs and no webhook argument is supplied. No live submit/audit delivery occurred.
The loose audit marker accepts not-reviewed axis fields too. This proves parser
compatibility and field presence, not GREEN, human acceptance or publication
readiness. The Myst protocol keeps those review and approval gates.
This is the known consumer scope, not an inventory of every user's repository.

## Remaining release controls

The proposed bump is MINOR under the current version rules: new/retired skills
and behavior changes arrive by plugin directory replacement. Existing invocation
names, installation channels and consumer vocabulary paths remain. Copy users
already manage stale names; the tested cleanup is documented in
[the guide](upstream-refresh-install-cleanup.md). An incompatible additional
required consumer would need resolution before exposure and could change this
version decision.

The proposed 5.5.0 patch changes both manifests and promotes the draft CHANGELOG
section together. `git apply --check` passes without changing the worktree.
Its SHA-256 is dbf43295ea73ffce557b7040d8544f14c3bb664e15cad18d5e2cd3d9b44abfe9.
The integration description uses Summary / Evidence / Merge Danger and leaves
its actual final-integration review results pending. Its SHA-256 is
6162b82c243fc1a989adf8da88d364fba052ec742fdb09c599d7a242c0d6169f.
Both are preparation artifacts; neither manifest is bumped in
this changeset. Final integration still needs the publication protocol, review
of the actual release scope and human authority. Claude runtime stays deferred
until the owner reports it works. Remote Git transition and native slash menus
remain unverified. These limits prevent a full-compliance claim.

Evidence root: `%TEMP%/myst-release-acceptance-20261009`. It holds native prepare,
update/rollback scripts, all CLI receipts, candidate snapshot, four native catalog
responses, normal-host hash receipt, global-copy checks/backups, consumer revision
receipt, freshly printed scripts and 21 replay logs. The original personal-edit
and unknown-origin project fixtures remain in the retirement evidence root.
The root also holds proposed-release-5.5.0.patch, integration-pr-draft.md,
release-preparation-checks.json, legacy-format-preservation.json,
combined-scope.py/combined-scope-checks.json and package.py with its ten logs.

## Combined mechanical checks

All six production gate scripts, both offline manifest validators and all 26
source-verifier acceptance tests pass. Fresh independent
`python tools/verify_upstream.py --require-complete` passes: 26 imported bundles,
zero pending imports and five local skills. All 188 plugin files still match
99cd0c8 byte for byte. There are exactly 31 SKILL.md entries, all at public skill
roots. All 91 relative public-entry links and changed-doc file links resolve.
All 27 individual import/retirement inventory rows have owner verification.
The preserved legacy starter body equals its base Git blob exactly.

The initial release-patch generator normalized existing CRLF context and its
apply-check failed. The corrected patch keeps raw line endings; the rejected
patch and explanation stay saved. A first scope-check command used a Windows
backslash path with git show; the final saved script uses slash-separated Git
paths and passes all comparisons. These were preparation/checker errors, not
skill or consumer defects. No repository patch was applied and no skill changed.

The combined evidence accounts for known routes and limits. It does not replace
the separate per-skill reviews or turn deferred controls into passes. Independent
Standards and Spec reports follow; owner verification stays pending.

## Standards review

Independent verdict: GREEN.
BLOCKING: 0; WARNING: 0; INFO: 0. Worst Standards issue: none.

All eleven files, including both complete additions, were reviewed against
CONTRIBUTING, the approved plan, ADR-0008/0009 and Myst's review mapping. No
documented-standard breach or actionable baseline smell was found. Source
ownership, attribution, vocabulary paths, cleanup safeguards and publication
authority remain. Passed checks and deferred/unverified controls are distinct.

Independent checks confirmed all 188 plugin files match base; both manifests
stay 5.4.0 and the complete legacy body is unchanged. The reviewer inspected
native/global scripts, CLI receipts, package logs, parser replay evidence and
printed consumer scripts. Current workspace parser hashes match the receipt.
The proposed patch passes git apply --check.

Branch/HEAD/base, empty commit/staging lists, eleven actions/current/base hashes,
diff SHA and both preparation artifact hashes matched before and after review.
This covers pinned documentation and bounded acceptance, not release approval.
Claude runtime, remote Git transition, slash menus and broader consumer scope
remain unverified. The patch and PR body remain preparation artifacts.

## Spec review

Independent verdict: GREEN.
BLOCKING: 0; WARNING: 0; INFO: 0. Worst Spec issue: none.

No missing requirement, scope creep or incorrect implementation was found within
the pinned preparation scope. Issue 39 requires "Preserve every imported byte"
and "Keep existing consumer filenames." All 188 plugin files independently match
base. The original legacy body stays byte-identical under its local preface.
Docs reconcile 31 entries, pins, permissions, dependencies, format authority and
the open migration exception.

Actual harnesses, logs, snapshots, discovery responses, backups and parser replay
artifacts support the bounded results: 70 project checks, global upgrade/rollback
with four exact backups, native local selection/rollback, six gates, two validators,
26 verifier tests and 21 description cases. The local-refresh limit is accurate.

Issue 39 says "Do not claim full cross-host acceptance." Deferred Claude runtime,
remote HTTPS transition, slash menus and wider scope remain stated release limits.
Known consumer evidence covers UE_Blank_Proto only. The proposed MINOR decision
is conditional. The 5.5.0 patch and integration body are separate artifacts;
manifests stay 5.4.0. Final integration review and publication authority remain
pending. The patch apply-check passes.

All eleven actions/hashes, branch, HEAD/base
99cd0c8a4fa880d9c55bcfdb50ab4cc7ebc63f22, diff SHA
a485f42f2ad72f533fec91c517c77089d1932299c50b87fb35fdae62fdddd065 and both extra
artifact hashes matched before and after. Commit range/staging stayed empty.
No reviewer edit or publication occurred.
