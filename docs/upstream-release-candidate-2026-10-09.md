# Upstream refresh release candidate - 2026-10-09

Status at this dated check: candidate prepared; both independent review axes
GREEN. Draft [PR #107](https://github.com/vladSirin/myst-agentic-workflow/pull/107)
is published. Candidate manifests are 5.5.0; main remains v5.4.0. No merge, tag,
release or real consumer update.

Owner authorization after the [full review and proposal](review_upstream_refresh_final_2026-10-09.md):
"Good, go ahead." This authorizes candidate and PR preparation, not merging or
tagging. The [tracker](../.scratch/upstream-boundary-refresh/issues/40-release-integration.md)
records the scope. The known consumer remains UE_Blank_Proto; wider required
scope is unconfirmed. Claude model runtime remains owner-deferred.

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
Codex authenticated slash menu: unverified; disposable profile stops at login.
Further required consumer scope: unconfirmed.
Claude model runtime: deferred by the owner.
Merge, tag, release and real consumer update: pending explicit decisions.

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
