# Diagnosing-bugs source and wrapper migration - 2026-10-08

Status: implemented, tested, independently reviewed, and owner-verified for
9e22e7a on 2026-10-08 after alignment recheck.
Review base: 74148bf. Only diagnosing-bugs migrates in this changeset.

## Source and local integration

Complete source was independently fetched at historical Matt pin
0ab1b63a410a03d3627979a109c8695de27af954 and approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f. Both contain three files:
SKILL.md, agents/openai.yaml, and scripts/hitl-loop.template.sh. The sole update
changes CONTEXT.md to GLOSSARY.md in the source entry. The metadata and script
are byte-identical across pins. Both previous local files match historical source.

All three approved files remain intact under references/upstream, with only
SKILL.md mapped to UPSTREAM.md under ADR-0009. The old root script moves beside
the source after byte comparison. UPSTREAM.json records complete original names
and hashes. PROVENANCE.md retains attribution and the upstream MIT notice.

The thin wrapper loads LOCAL-INTEGRATION for authoritative legacy/new/custom/
scoped domain documents, project ADR locations, target VCS, and publication
authority. It links the raw source and HITL companion directly. agentic-workflow
is the required copy dependency. The trigger and automatic invocation remain
unchanged; public host metadata matches upstream. The six-phase diagnosis
method and helper behavior are not rewritten. No consumer documents are renamed.

## Completed package checks

All 26 source verifier acceptance tests passed. Independent pinned-source
verification passed for 11 imported bundles, 14 declared pending imports, and
four local skills. All six existing CI script gates and both offline Claude
manifest validations passed. skills CLI 1.7.1 copied the complete package for
Codex, Claude Code, and OpenCode; both resulting trees match repository hashes.
A disposable core.autocrlf=true checkout preserved all original source bytes.

Fresh Codex discovery selected the wrapper, and the implicit prompt catalog
included diagnosing-bugs. OpenCode debug skill selected it with an empty isolated
host config. These checks do not prove spontaneous model selection or native
slash UI behavior. No OpenCode model execution or Claude runtime test was run.

The unchanged HITL script passes bash -n. A bounded run with synthetic stdin
prints the expected ERRORED=y and ERROR_MSG=synthetic export failure fields.
This checks the helper's prompt/capture/output path only, not a real human or UI.

## Direct versus wrapped runtime checks

Four fresh Codex executions used disposable local Git projects. Both pairs have
identical prompts and project input hashes outside the diagnosing-bugs package.
Direct runs use the complete approved source with its original SKILL.md name;
wrapped runs use the exact repository candidate. Both include the same shared
project instructions and dependency. Calls explicitly select the local entry.
The project identifies Records/domain.md and Records/decisions/ as authoritative.

| Case | Seconds | Observed result |
| --- | ---: | --- |
| fix-wrapped | 120.830 | Reproduces, diagnoses, tests, and fixes explicit zero capacity. |
| fix-direct | 174.292 | Same code and test behavior; cleans its generated Python cache. |
| blocked-wrapped | 51.458 | Stops at Phase 1, asks for real evidence, makes no changes. |
| blocked-direct | 72.480 | Same evidence boundary and no changes. |

All four exit 0. Full before/after inventories show only queue_policy.py and
test_queue_policy.py changed in each fix case, and no writes in either blocked
case. Every fixture HEAD is unchanged. The wrapped packages still match the
repository candidate and direct packages match the complete source inventory.

The fix traces show the exact symptom twice before the fix: can_admit(0, 0)
returns True and the assertion fails. Both runs present three ranked causes
before inspecting/probing the implementation: truth-value fallback, an inclusive
comparison, and an empty-queue shortcut. Both identify capacity or DEFAULT_CAPACITY
as the cause, disprove the alternatives, add the regression before the fix,
and run five tests with two failing zero-capacity subcases. They then change
the fallback to DEFAULT_CAPACITY if capacity is None else capacity. The five
tests pass and the original assertion returns False. Both read the custom domain
file and ADR, check the final diff, leave no debug instrumentation or temporary
harness, and supply a cause-based commit message without making a commit.

The final implementation files are byte-identical. Test files differ only in
the zero-capacity test method name. Both cover job counts 0, 1, and 8 at zero
capacity, explicit None, omitted capacity, and positive capacity. Independent
final unittest runs pass. A 50-case comparison (job counts 0 through 9 across
None, 0, 1, 3, and 8 capacities) returns identical results. Suggested commit
message wording differs without changing the stated cause.

There is a small process-order difference: the wrapped run lists hypotheses
after the first failed call, then repeats it before probing; the direct run
repeats the failure before listing hypotheses. This does not change the outcome,
but it is not proof of strict adherence to every phase boundary. The one-call
fixture also does not exercise meaningful multi-step minimization. No speculative
source or wrapper change was made to address these limits.

The blocked incident supplies no code, binary, logs, captured request, or local
reproduction and permits no network or human interaction. Both runs inspect the
available files, state that no red-capable loop can be built, avoid linking the
unrelated capacity vocabulary to the incident, and stop without hypotheses or
fixes. They ask for concrete steps, time/version details, redacted captures/logs,
and a runnable local build or replay. The requested evidence aligns despite
normal wording differences.

Local shell starts sometimes failed with the sandbox-helper setup error; each
was retried through the normal mechanism. In the direct run, one successful
green-test command ended with exit 1 because its final debug-prefix grep had no
matches. Its output shows passing tests and original assertion; the later diff
check and independent final tests pass. These are not model service failures.
No failed or timed-out model attempt is excluded from these four cases.

The result supports alignment for this deterministic local defect and the
no-reproduction stop path. It does not establish equal judgment for harder bugs,
performance/bisection, nondeterminism, missing regression seams, live HITL,
secret-redaction behavior, P4 publication, automatic selection, or all downstream
callers. Claude runtime remains deferred. No publication or consumer migration
was performed. No fixture commits or subagents ran.

## Evidence and review

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-diagnosing-bugs-migration-20261008

Source comparison, full fixtures, before hashes, raw traces, final messages,
final output files, final-test logs and matrix outputs are retained there.
verification.json and verify.py record paired inputs, changed files, HEADs,
package identity, output comparisons, and red/green evidence. package-checks.json
and individual logs record install, discovery, helper, and checkout checks.

Trace SHA256:

- fix-wrapped: `c95c7615d86e50aa00dc18a764874317e692745dc2e9662a7126268af8410b33`
- fix-direct: `6d5b71a30ccfcbf8dd23e159f12df80b79bce4ad2af2537819b6c536b9d35881`
- blocked-wrapped: `891a6ffb69e4d5fcbaa236c75206f149a72ceaf49fb224b1444d40919591f435`
- blocked-direct: `a7fef2f97a1d5c45406c288a8af85ca4dd025221f0c79e9fb800d94094116afe`

Final Standards review: GREEN, zero actionable findings. It confirmed source
ownership, automatic invocation, direct helper access, and honest evidence limits.
Final Spec review: GREEN, zero actionable findings. It checked actual traces,
outputs, hashes, unchanged HEADs, regression order, and both stop-path results.
The complete staged whitespace check passed. Owner acceptance is recorded below. No push, PR, merge, release, or consumer update.

## Alignment recheck and owner acceptance

The owner requested alignment testing, conditional verification, and continuation.
Existing direct/wrapped executions were rechecked against 9e22e7a. Paired inputs,
complete package hashes, trace/output hashes, red-before-green evidence, output
code/tests, fifty-case results, changed-file inventories, and fixture HEADs match
the reviewed evidence. Both no-reproduction runs still show no writes.

alignment-recheck.json records PASS for this bounded comparison. No new model
request was needed. Under the owner's conditional approval, 9e22e7a is verified.
The recorded phase-order difference and coverage limits remain. Claude runtime
is still deferred.
