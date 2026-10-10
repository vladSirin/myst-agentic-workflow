# Upstream refresh release candidate - 2026-10-09

Status at this dated check: candidate prepared; both independent review axes
GREEN. Draft [PR #107](https://github.com/vladSirin/myst-agentic-workflow/pull/107)
is published. Candidate manifests are 5.5.0; main remains v5.4.0. No merge, tag
or release. The owner later selected the existing PC installation for the local
5.4-to-5.5 update recorded below. No UE project file was changed.

Owner authorization after the [full review and proposal](review_upstream_refresh_final_2026-10-09.md):
"Good, go ahead." This authorizes candidate and PR preparation, not merging or
tagging. The [tracker](../.scratch/upstream-boundary-refresh/issues/40-release-integration.md)
records the scope. The owner's selected first examples are UE_Blank_Proto for
Perforce and myst-agentic-workflow for Git. Other projects are outside this
example scope. Claude model runtime remains owner-deferred.

## Candidate contents

Fast-forward the migration branch to accepted proposal commit
0714721ff30d857c7d9fe8ee776fbbbd0ae25ba9. Apply its reviewed version/notes patch:
two manifest version fields and one dated 5.5.0 CHANGELOG section. Keep every
other package file byte-identical to the accepted proposal. No wrapper,
source record, imported file or companion changes in this release step.

CONTRIBUTING now makes exception closeout effective when the final PR merges to
main. Per-skill reviews remain linked, and later contributions return to the
normal one-skill PR process. Historical preparation reports are explicitly
scoped to their snapshots. The inventory and README point to this current
candidate record. Published main and tags remain separate.

## Checks and decisions

Actual candidate Standards and Spec review: both GREEN, no findings.
Fresh production gates, source integrity and offline manifest validation: passed.
Actual candidate PR/push CI: all six checks passed at f34add6.
Native HTTPS candidate ref replacement and copy upgrade/rollback: passed.
Ordinary main-branch version transition: untested before main merge.
OpenCode slash-menu alias: displayed in a typing-only check; no execution.
Codex console menu: owner confirmed pr and p4-description are visible.
Required first examples: UE_Blank_Proto (Perforce), myst-agentic-workflow (Git).
Existing PC local-marketplace 5.4-to-5.5 update: passed; native catalogs checked.
Claude model runtime: deferred by the owner.
Merge, tag, release and further consumer changes: pending explicit decisions.

The earlier [combined report](upstream-release-acceptance-2026-10-09.md) retains
project/global copy, local-marketplace upgrade/rollback and deployed UE parser
evidence. The full implementation review retains per-skill alignment limits.
These checks do not establish untested transitions or full cross-host acceptance.

## Preparation evidence

All ten candidate checks pass: six production CI scripts, two offline manifest
validators, 26 source-verifier acceptance tests and fresh independent source
acquisition with --require-complete. Result: 26 imports, zero pending imports
and five local skills. No Claude model request ran.

Codex's normal HTTPS marketplace add with --ref v5.4.0 and plugin add succeeded
in a disposable CODEX_HOME. The checkout resolves to the released base
b3aeed04e0ea553af7b39f6d793e91f2ff676ff1. Its complete 55-file cache equals the
actual Git checkout byte for byte and contains 29 public entries. Compared
with canonical Git blobs, all observed differences are CRLF conversion in the
normal Windows checkout. This is baseline evidence, not a candidate update pass.
The first comparison expected canonical bytes and failed; its checker and the
diagnostic remain saved. Candidate imported files will be checked without EOL
normalization against their recorded source hashes.

Test homes and workspaces are disposable. Node's homedir is asserted before
copy-oriented tools run. No credentials are copied. Normal host configuration
hashes remain unchanged after the baseline test. Native catalog assertions
select only the fixture's Myst paths because Codex can still read personal
skill roots outside a process-local CODEX_HOME.

Evidence root: %TEMP%/myst-release-integration-20261009. Fresh package logs,
remote baseline CLI logs, isolated environment record, protected-host hash
receipt and complete-tree diagnostics are retained there.

## Actual candidate review

Both independent reviewers used the complete released-base candidate capture
and the eleven-path delta against accepted proposal 0714721. They reused the
earlier full migration/proposal reviews for unchanged content. The fixed delta
SHA-256 was c22626dd9a8adb94913e4dd0471577373ea3bea77b7a3d1f6310bde38d9c51fc;
the combined released-base capture was
3169056296cce62e08ab995b58edd3007d53e0197474d989875c57ec59662089.

### Standards

Reviewer: final_migration_standards.
BLOCKING 0; WARNING 0; INFO 0. Worst Standards issue: none.

No documented-standard breach or actionable smell was found across the twelve
required heuristics. Both manifests change only their version fields, and the
CHANGELOG equals the approved patch. Every other plugin file remains unchanged.
The contribution exception ends only upon the final main merge and retains
the per-skill review evidence. Current and historical status claims are bounded.
The report distinguishes successful checks from unverified controls. All eleven
hashes, HEAD, branch, staged scope and both diff hashes matched before and after.

Verdict: GREEN

### Spec

Reviewer: final_migration_spec.
BLOCKING 0; WARNING 0; INFO 0. Worst Spec issue: none.

No missing requirement, scope creep or wrong implementation was found. Both
manifests prepare 5.5.0 together; the other 186 plugin files are byte-identical
to 0714721. No method, wrapper, metadata or source record changes. The exception
closeout and status records preserve the approved final-integration process.
Required consumer compatibility and later merge/tag decisions remain. Ten
passing checks and the bounded HTTPS baseline diagnostic support the claims.
All eleven hashes, scope, HEAD, branch and both regenerated diffs matched.

Verdict: GREEN

Independent docs preflight: "Aligned within the eleven-file candidate scope."
These results clear preparation review, not the remaining release controls or
main merge/tagging. Rendering them adds no new behavior or approval.

## Remote candidate checks

The tested remote candidate is f34add67fa7e7088a62f16de8b2ef648becc9431 on
codex/upstream-boundary-refresh. PR #107 is a draft targeting main and is attached
to the chat. GitHub ran lint, ps51-gates and upstream-source on both the branch
push and PR event; all six checks passed. This receipt covers that exact head,
not later documentation commits or a future main merge.

Codex 0.162.0-alpha.2: changing the registered ref from v5.4.0 to the candidate
with marketplace add alone failed because myst was already registered from a
different source. The supported marketplace remove, marketplace add --ref and
marketplace upgrade sequence then selected 5.5.0. No registry or cache was edited
by hand. The 188-file installed cache equals the actual remote checkout byte for
byte. All 69 imported files match their recorded source hashes without EOL
normalization. A fresh app-server returns exactly 31 unique Myst entries.

The same supported ref-replacement sequence restored v5.4.0 at its exact tag
commit. Its complete 55-file cache equals its remote checkout, and a fresh
catalog returns exactly the original 29 entries. These results prove native
HTTPS ref replacement and rollback. They do not prove a 5.4.0-to-5.5.0 version
transition through upgrade alone on an unchanged main ref. Check that after the
approved main merge and before claiming that path as verified.

OpenCode 1.18.35 and skills CLI 1.7.1: actual HTTPS add commands used the tested
fragment refs #v5.4.0 and #codex/upstream-boundary-refresh, --global, --copy and
--agent opencode in a separate disposable USERPROFILE. After complete origin/hash
checks, the normal remove command removed only resolving-merge-conflicts before
upgrade and only pr, implement-spec and p4-description before rollback. Each
complete skill folder matches its independently checked Git snapshot. Fresh
OpenCode debug skill catalogs return 29, then 31, then 29 unique entries at the
fixture's actual copy root. The candidate's 69 raw imported files match exactly.

The OpenCode terminal also opened without a provider connection. Its default
skill command does not appear in autocomplete; versioned host source confirms
this filter. An optional project command alias pointing to the public wrapper,
with permission.skill.handoff kept deny, displayed /handoff and its description
in a fresh terminal. The owner approved typing only; Enter was not pressed.
No template execution or new policy-enforcement pass is claimed. See the
[menu setup and host sources](handoff-pilot-2026-10-07.md#slash-menu-suggestions-11835).
The first typing attempt was rejected by automatic approval review before it
was sent; explicit owner approval allowed the later typing-only checks.

Codex's first terminal attempt needed a complete daemon package. Its supported
--no-daemon retry reached the sign-in screen. It was stopped there; authenticated
menu display remains unverified. Native catalog success does not substitute for
that check. No login, credential copy or model request was made in these tests.

The three protected normal-host files (.codex/config.toml, .claude/settings.json
and .claude/plugins/installed_plugins.json) retain their before-test hashes.
Evidence root remains %TEMP%/myst-release-integration-20261009: pr-candidate-ci.json,
remote-codex-candidate-bytes.json, remote-codex-rollback-bytes.json, fresh catalog
receipts, the three remote-copy checks, CLI logs and opencode-menu-output.json.
The earlier source/description alignment tests remain the execution evidence;
these install and typing checks add no new model-alignment claim.

## Evidence and menu-guide review

Both reviewers checked the same four-document working-tree delta against
f34add6. Its fixed SHA-256 was
2043bd29d49ad41789c790bd67ff43d5e8b9ffcccbd9189a77d8551df6c521d1.
Branch, HEAD, scope, all four file hashes and regenerated diff matched before
and after. Both independently confirmed that all 188 plugin files are unchanged.

### Standards

Reviewer: final_migration_standards.
BLOCKING 0; WARNING 0; INFO 0. Worst Standards issue: none.

No documented-standard breach or actionable smell across the twelve heuristics.
The receipts support the bounded CI, ref-replacement, copy and rollback claims.
The optional alias addresses observed host display behavior, points at the public
wrapper and retains the deny rule. The text separates display from execution and
policy proof. README and issue 40 preserve the remaining owner decisions.

Verdict: GREEN

### Spec

Reviewer: final_migration_spec.
BLOCKING 0; WARNING 0; INFO 0. Worst Spec issue: none.

No missing requirement, scope creep or incorrect claim. Actual receipts support
the stated cache/copy hashes and fresh catalogs. The ordinary main-ref update
remains untested. Versioned host source and terminal output support the optional
menu guidance. The owner approved typing only; no execution or new policy proof
is claimed. CI is bounded to its tested head. Required consumer scope, Codex's
authenticated menu, Claude runtime and publication decisions remain explicit.

Verdict: GREEN

Independent docs preflight: "Aligned within the four-document scope."
This clears the evidence/menu guide update. It does not grant main merge or
tagging authority. Rendering these verified reports adds no behavior or approval.

## Existing PC update and selected examples

The owner selected UE_Blank_Proto as the first Perforce example and this repo as
the Git example. They offered to inspect the console's Skill command after
installation and selected the existing PC installation for the 5.5 update:
"We have the 5.4 installation on this Codex and PC, I think. You can check, and we can use it to update to 5.5."
This changes the earlier disposable-only scope for the local PC plugin update;
it does not authorize main merge, tagging or a Perforce submit.

Preflight found myst-dev-kit@myst enabled at 5.4.0, installed from this local
repo. Its complete 55-file package matches the v5.4.0 Git snapshot exactly and
has 29 skills. A complete byte-verified backup was preserved outside discovery
roots. No authentication file or credential was copied.

The normal console command codex plugin add myst-dev-kit@myst --json selected
5.5.0 from reviewed candidate 8225cbeab6210196eb7cff5cae776690d1e88d74. The complete
188-file installed package equals the source byte for byte, and all 69 imported
files match their recorded upstream hashes. The plugin stays enabled. No
installed clone was edited by hand.

Fresh native skills/list calls on console CLI 0.154.0 and desktop CLI
0.162.0-alpha.2 return exactly 31 unique active Myst entries for each of the two
example project directories. All point at the selected 5.5.0 cache; the retired
Myst resolving-merge-conflicts entry is absent. These are four catalog checks,
not visible-menu or project-runtime acceptance. The Git-only skills may appear
in the Perforce project's catalog; their target restrictions still apply.

The three protected normal-host configuration hashes remain unchanged. No login
request, credential copy, model prompt, Perforce write, main merge or tag occurred.
The Git example already has the actual three-section PR #107, independent review
reports and CI evidence. UE's description-parser checks are in the combined
report; its workflow docs still use the old Review Record term. Align that wording
before rolling out new Perforce descriptions. No UE doc update is claimed here.

The owner confirmed the visible console entries on 2026-10-10:
"Yes skill commands show pr and  p4 -description as personal skills."
This confirms menu visibility for pr and p4-description, with the reported
personal-skill label. It does not assert a visible count of 31, visibility of
implement-spec, or model execution. The four native catalogs remain the evidence
for the full selected-version skill list.
Official [OpenAI command documentation](https://learn.chatgpt.com/docs/developer-commands?surface=cli)
describes the /skills picker. The earlier pending-menu statements and review
reports describe their recorded snapshots; this later owner report supplies
the manual visibility evidence without changing their original review results.

Evidence root: %TEMP%/myst-existing-install-20261009. preflight-checks.json records
the exact old package and verified backup. post-update-checks.json, native plugin
lists and both scoped catalog receipts record the actual new installation.
This tests an existing local-path installation. The normal Git main-ref version
transition remains a separate check after an approved main merge.

## Existing PC evidence review

Both independent reviewers checked the two-document delta against 8225cbe.
Its fixed SHA-256 was
a9a352c7ce0c27b3d8c32e8973fdc1930ae73034698c252dbf583fbd0ed7ef94.
HEAD, branch, scope, both document hashes and the regenerated diff matched
before and after. All 188 plugin files remain unchanged.

### Standards

Reviewer: final_migration_standards.
BLOCKING 0; WARNING 0; INFO 0. Worst Standards issue: none.

No documented-standard breach or actionable smell across the twelve heuristics.
Saved receipts support the verified backup, installed package, raw-source hashes
and four native catalogs. The docs distinguish local-path installation from the
pending main-ref update, menu display and model execution. Issue 40 retains the
owner's manual check, publication decisions and UE wording follow-up.

Verdict: GREEN

### Spec

Reviewer: final_migration_spec.
BLOCKING 0; WARNING 0; INFO 0. Worst Spec issue: none.

No missing requirement, scope creep or incorrect claim. The reviewer independently
checked the complete 55-file backup and 188-file installation. All four scoped
catalogs contain the expected 31 unique entries. The later owner instruction
authorizes the local PC update and selects the two examples. It does not approve
main merge, tagging or Perforce submission. Manual menu acceptance, UE wording,
the main-ref transition and deferred Claude runtime remain explicit.

Verdict: GREEN

Independent docs preflight: "Aligned within the two-document scope."
This clears the installation-evidence update. Rendering these verified reports
adds no behavior, human acceptance or publication authority.

## Owner menu-evidence review - 2026-10-10

Both reviewers checked the two-document delta against 93c6472. Its SHA-256 was
c824a5c21a4bef961f8238bb0a089012e7df254ca1bb869a9c46117bfb9a1a69.
HEAD, branch, scope, both hashes and the regenerated capture matched before and
after. No plugin file changed.

### Standards

Reviewer: final_migration_standards.
BLOCKING 0; WARNING 0; INFO 0. Worst Standards issue: none.
The exact owner quote and bounded acceptance follow the owner-report rule.
No documented-standard breach or actionable smell across the twelve heuristics.
Verdict: GREEN

### Spec

Reviewer: final_migration_spec.
BLOCKING 0; WARNING 0; INFO 0. Worst Spec issue: none.
No missing requirement, scope creep or incorrect claim. The two confirmed entries
and their reported label remain separate from full discovery and runtime proof.
Historical reports and pending publication decisions retain their scope.
Verdict: GREEN

Independent docs preflight: "Aligned within the two-document scope."
Rendering these verified reports adds no behavior or publication authority.

## UE wording follow-up - 2026-10-10

The owner said: "good submit 4089 and do a final review on PR 107".
CL 4089 was submitted separately to `//UEPrototype/main`. Its description
keeps separate Standards and Spec results inside Evidence. `p4 describe -s 4089`
confirms the exact three-file scope:

- `Docs/MustRead/MustRead_agentic_workflow.md#8`: the landed-changelist statement
  now requires review results in Evidence.
- `Docs/agents/issue-tracker.md#11`: "Where everything else goes" now places
  review results in Evidence.
- `.scratch/myst-review-evidence/spec.md#1`: the scoped contract and closed ticket.

`p4 print -q <depot-file>@=4089` readback matched each reviewed workspace file
after normal P4 line-end translation. Both CL review axes were GREEN with no
findings; docs alignment passed. The actual final description checker passed.
The two exact guide replacements preserve all surrounding bytes, CRLF and the
45-line seam guide. Unrelated open files were unchanged after submission.

This closes the UE wording gate. Earlier PC-install and candidate statements
retain their dated scope; this follow-up does not add UE files to the Git PR.
The owner authorized PR #107 review only. Main merge, the ordinary main-ref
update check, tagging and further consumer changes remain separate steps.
Claude model runtime remains owner-deferred.
