# Implement plain-source conversion - 2026-10-08

Status: implemented, tested, independently reviewed, and owner-verified on 2026-10-08
for conversion commit d442595 after the requested direct-upstream comparison.
Review base: bbd3b89. The owner verified handoff and authorized continuation.
Only implement changes source layout in this changeset.

## Source and local behavior

The approved Matt pin remains 6fd947921b935b7e1e69293a200400f0fdd5c15f.
Both original files match the prior ZIP member bytes and recorded hashes.
SKILL.md is packaged as references/upstream/UPSTREAM.md; agents/openai.yaml
retains its original relative path. Version 2 records only that entry mapping,
while the source inventory keeps its original names. Scoped Git attributes
preserve the exact bytes on checkout. The original MIT notice is retained.

The public wrapper's frontmatter, invocation metadata, dependency list, and
local integration instructions are unchanged. Its final loading instruction
now links to UPSTREAM.md instead of supplying Python and PowerShell ZIP readers.
TDD still resolves to Myst's entry. Review still uses review-and-submit and the
namespaced code-review engine. The target project owns tracker state, and the
upstream commit instruction remains restricted to authorized Git target work.
The P4 route and publication boundaries are unchanged.

This does not migrate TDD or the review protocol. The required review and
description work remains tracked separately in issue 11.

## Package checks

- All 26 verifier acceptance tests passed. Independent pinned-source verification
  passed for five migrated bundles: three plain-reference packages and two ZIPs,
  with 20 pending imports and four local skills.
- skills CLI 1.7.1 copy installation for Codex, Claude Code, and OpenCode preserved
  every package byte in both generated host directories. Each copy has one
  SKILL.md. This is installation evidence, not Claude runtime evidence.
- Fresh Codex 0.160.1 discovery selected the enabled local wrapper. Debug prompt
  inspection excluded implement from the automatic catalog, preserving explicit
  invocation. Native slash-menu interaction was not repeated.
- Fresh OpenCode 1.18.35 discovery selected the public wrapper with its plain
  source link. User-only skills still need the local host permission rule
  described in the handoff pilot, with implement as the skill name. The package
  does not install that host configuration. No new OpenCode model request ran.
- A disposable Git index and core.autocrlf=true checkout preserved both original
  source files byte-for-byte.
- All six repository CI script checks and offline Claude plugin/marketplace
  manifest validation passed. No Claude model ran. git diff --check passed.

## Runtime checks

Fresh Codex sessions use the configured model and disposable synthetic fixtures.
The Git case repeats the approved get_retry_count seam: configured zero stays
zero, missing returns three, and positive values are preserved. The P4 case is
read-only and contains a real nested Git repository; no P4 server is contacted.
The missing-dependency case omits local tdd and code-review and supplies a
competing review entry. No consumer project or installed plugin is changed.

The first fixture reuse omitted TDD's newer codebase-design dependency. The P4
preflight reported that gap correctly. Complete Git and P4 fixtures were then
created with that dependency. Initial
runs remain separate diagnostic evidence, not proof of a complete installation.

The complete-fixture sessions used configured gpt-6.1-sol. All three final
cases exited 0. Actual output files, test output, tracker state, source-loading
commands, and before/after hashes were inspected, not just the model summaries.

| Case | Observed result |
| --- | --- |
| Git implementation, 169.007 seconds | Read the wrapper, shared contract, and plain UPSTREAM.md. Added the approved zero regression, observed failure before the fix, then fixed the public seam. The regression, focused file, and full suite passed. |
| Git completion | Only source, tests, and ticket changed, apart from Python bytecode caches. Git HEAD is unchanged. The ticket is resolved with owner acceptance outstanding. No commit, publication, or closure occurred. The runtime dispatched Standards and Spec reviewers and reported both GREEN. |
| P4 preflight, 56.504 seconds | Retained Perforce ownership despite mirror/.git. Selected the local Markdown tracker, Myst TDD, and Myst review coordinator/engine. Reported all required entries present and rejected a Git commit for the P4 target. Every input-file hash is unchanged. |
| Missing dependencies, 39.007 seconds | Reported absent local tdd and code-review; stopped before code, tests, or tracker changes. Did not substitute the competing review entry. Every input-file hash is unchanged. |

The actual fix is `settings.get("retry_count", 3)`, replacing
`settings.get("retry_count") or 3`. The zero assertion first failed with
`AssertionError: 3 != 0`, then passed. Final tests:

```text
python -m unittest discover -s tests -p test_settings.py -k test_zero_is_preserved -v
python -m unittest discover -s tests -p test_settings.py -v
python -m unittest discover -s tests -v
```

The focused regression ran one test. The focused file and full suite each ran
three. No type checker is configured, and the runtime reported it as unverified.
An initial shell-quoting error produced no test execution; the model corrected
it before obtaining the actual red/green evidence above. That failed command
is not counted as a red regression.

These results align with the earlier ZIP test on the scoped behavior: same
zero/missing/positive outcomes, real red-before-green tests, correct dependency
and P4 routing, and unchanged publication authority. This is behavioral alignment
for these cases, not exact transcript or cross-model output equivalence.

## Evidence and limits

Temporary evidence: %TEMP%/myst-implement-plain-20261008. It includes copy and
discovery outputs, checkout files, runtime prompts/traces, baseline hashes, and
fixture outputs. The earlier ZIP behavior is recorded in
[the original migration report](implement-wrapper-2026-10-07.md).

| Completed trace | SHA-256 |
| --- | --- |
| git-complete/trace.jsonl | 3f9bb5d5136a0155bfca22378564039d449a5c1eea5fa653da04b835ec877b79 |
| p4-complete/trace.jsonl | 6f7aefcb015f45fc7692836ca376481852494a04fb8702d64c874fc3e9392c73 |
| missing/trace.jsonl | cd0d7b8e94c75295ef5bdba3e03442d7bc375cb8d1f28b19da304687665017e7 |

verification.json records exact changed-file lists, exits, timings, hashes,
and the unchanged Git HEAD. The normal CLI session log records the runtime's
review dispatches (session 01a11916-4eb5-71c3-858b-cc49bddd650b); the JSON trace
records its final review report. These fixture reviews are separate from the
independent review of this package conversion.

Final independent package reviews: Standards GREEN, zero findings; Spec GREEN,
zero findings. Both reviewers checked the completed evidence report. The Spec
reviewer also checked actual fixture outputs, test traces, unchanged HEAD, and
all three trace hashes. The owner's later conditional verification is recorded below.

Tests establish bounded behavior and loading. They do not prove identical
wording across models, live P4 operations, or deferred Claude runtime behavior.
Publication and consumer migration remain outside this changeset.


## Direct upstream comparison and owner verification

The owner requested: "Good do a quick test if result align with the direct call
of upstream skill, consider it verified."

A fresh direct-upstream run used the same pre-implementation Git fixture as the
wrapped run. Every baseline file outside the implement package matched exactly.
The implement package contained only the two original upstream files, with
SKILL.md restored to its original name and both hashes checked against
UPSTREAM.json. It had no Myst implement wrapper. The prompt changed only its
entry/loading sentence; task, project instructions, local dependencies, model,
and no-commit/no-publication limits stayed the same.

The direct run completed with exit 0 in 174.271 seconds. Actual files and test
output were compared with the wrapper run:

- Source code and test text are identical after newline normalization.
- Both preserved zero, returned three for missing input, and kept positive input.
- Both obtained a real failing zero regression before the fix, followed by green
  focused and full suites. The direct run used the whole three-test file for
  its red check; the wrapper used the focused one-test selection.
- Both reported Standards and Spec GREEN and type checking unverified.
- Both changed only source, tests, and ticket among baseline files. Git HEAD
  stayed unchanged; the ticket was resolved with owner acceptance outstanding.
- The direct skill used the local code-review engine directly. The wrapper used
  the intended Myst review coordinator. This routing difference is deliberate.

This confirms aligned results for the tested implementation. Dependency skills
and project rules were held constant; it is not a test of an entirely upstream
skillset or of unrestricted upstream publication behavior. Ticket wording and
review routing differ; result equivalence does not require identical transcripts.

Evidence is in upstream-direct/ under the existing temporary evidence root,
with direct-comparison.json recording the checked results. Direct trace SHA-256:
9950459ab5e87ebb7c59699be6c953bab05994fcfa8143b3680b5ff3167af182.
The owner's stated condition is met. Implement conversion d442595 is recorded
as owner-verified on 2026-10-08. Claude runtime remains deferred.
