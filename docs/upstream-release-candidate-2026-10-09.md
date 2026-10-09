# Upstream refresh release candidate - 2026-10-09

Status: candidate prepared; both independent review axes GREEN. PR publication
and remote candidate checks are next. Candidate manifests are 5.5.0;
published main remains v5.4.0. No merge, tag, release or real consumer update.

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
Actual PR remote CI: pending.
Native HTTPS marketplace/ref/update checks: pending.
Native slash-menu checks: pending; catalog checks are separate evidence.
Further required consumer scope: unconfirmed.
Claude model runtime: deferred by the owner.
Merge, tag, release and real consumer update: pending explicit decisions.

The earlier [combined report](upstream-release-acceptance-2026-10-09.md) retains
project/global copy, local-marketplace upgrade/rollback and deployed UE parser
evidence. The full implementation review retains per-skill alignment limits.
These checks do not establish untested remote transitions or full cross-host
acceptance. Current receipts will be recorded here as checks finish.

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
