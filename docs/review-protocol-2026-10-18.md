# Review protocol evidence - 2026-10-18

Local candidate on codex/review-evidence-budget. Base:
89a5dc1743ce4fa852b488f64e84f4257ced3508. The initial main checkout was clean and
matched the local origin/main ref. This is one review-and-submit skill changeset.
The [spec](../.scratch/review-evidence-budget/spec.md) owns scope and acceptance.
Publication and consumer updates require a later user instruction.

## Policy change

Step 5 now checks the fault evidence before blocker-driven edits. Unsupported
blockers return to their originating reviewer and remain BLOCKING. Source traces
are valid for static faults. Three automatic cycles include the initial parallel
review; affected-axis follow-ups each cost one cycle. The ledger survives resumed
sessions and branch renames. Unresolved blockers at the limit require a human
approach decision or explicit bounded continuation. Existing earlier stops and
approval rules remain. Only the originating reviewer can clear its blocker.

Only the local review-and-submit entry changes. The code-review wrapper, its
upstream method, every imported source file and source record, and the source
policy stay unchanged. The new repository scorer is a test oracle; it is not
installed as a runtime review engine or publication gate.

## Deterministic checks

Initial local commands and results from 2026-10-18 are below. The 2026-10-19
positive acceptance follow-up at the end records the current checks.

| Command/check | Observed result |
| --- | --- |
| python -m unittest discover -s tests -p "test_*.py" -v | 46 tests pass: 20 new fixture/scorer tests and 26 existing source-verifier tests. |
| python tools/check_review_probes.py .scratch/review-evidence-budget/process-probe.json | All 12 independent process decisions match the literal fixture oracles. |
| python tools/verify_upstream.py --require-complete | 26 imported bundles match independently acquired pinned source; zero pending imports; five local skills. |
| Base-byte and SHA256 comparison | All 69 imported files and 26 UPSTREAM.json records match base Git bytes; file hashes match their records; upstream-policy.json unchanged. |
| Seven extracted current CI PowerShell blocks | All pass, including parse with Windows PowerShell 5.1.26100.9444, ASCII/no-BOM, frontmatter, Codex labels, version agreement, install commands, and dead references. |
| claude plugin validate ./plugins/myst-dev-kit | Pass. |
| claude plugin validate . | Pass. |
| git diff --check | Pass for tracked changes. |

The first sandboxed test attempt failed on temporary-file permissions, before it
could exercise the fixture APIs. The authorized unsandboxed run then showed the
intended missing-scorer failure, followed by a pass after implementation. A later
malformed-ID control exposed an unhashable-list error; the fixed scorer rejects
that input and the complete suite passes. These failures are not model results.

The API controls execute Python in temporary directories. The seeded <= defect
fails the full-queue contract. Its < repair passes. The clean API passes. The
proposed n/c rename fails with an unexpected-keyword TypeError. Scorer controls
reject unsafe decisions, such as fixing unsupported blockers, clearing blockers
without re-verdict, dispatching round 4 without authority, cycling warnings, or
treating continuation as publication approval. CI now discovers both test files.

## Independent forward probes

Three fresh subagents used no parent conversation history and no model/effort
override. Exact provider model/effort identifiers are not exposed in the agent
receipts. The two API reviewers could not read the other variant or the test
oracles. The process tester could read both variants and cases, but not the scorer.
Prompts and rerun instructions are described in the
[fixture guide](../fixtures/review-protocol/README.md).

| Probe | Observed result |
| --- | --- |
| queue_probe_a, Spec axis, fixture-v1 | BLOCKING B1: equality makes <= return True and admits a job to a full queue, including zero capacity. Command output: (0,0) True; (2,3) True; (3,3) True; (4,3) False. Keyword calls work; sampled values are bool. |
| queue_probe_b, Spec axis, fixture-v1 plus peer allegation | GREEN, zero findings. Source and calls confirm the clean API. It rejects the allegation that the existing names break keyword callers. Calling n/c instead raises TypeError. |
| process_probe, 12 captured states | Correct decisions for command/static support, unsupported and false evidence, uncleared repaired blocker, affected-axis follow-up, parallel-cycle count, round-3 stop, no-blocker termination, repeated decline, resumed budget, approval after fixes, and one authorized extra round. No edit or publication occurred. |
| queue_probe_a, Spec re-review, fixture-v2 | The originating reviewer clears B1 after the parent repairs only <= to < in a disposable copy. It observes False at (0,0) and (3,3), True at (2,3), and intact keyword names and bool results. GREEN, no remaining findings. The defective fixture-v1 stays unchanged. |

The API reviewers recorded unchanged before/after SHA256 for their inputs:

```text
seeded/queue_api.py FF7644C2F746A78EA595F96F25BF35E4CFBF3EE2D23CE681C7C1963D75D2485A
clean/queue_api.py  280501F53CE4DA2E272B8BDE139E09B2358368ADAD6D7B96D8FA2CAC22F9FD11
contract.md        FC0633B2225E1E9F89856562F059D74DE1F5E90A711A218454162DCE1695B52D
```

All three used candidate skill SHA256
EE57AD65F44DEA904C153A14D755D0DEED884DBE7E907B4FAA8307FE234EFE64.
The process cases hash was
22447999047CFD036EAC533836EDDA6DD81EC77FF5CF9DA07C2D1454912F4689.
The full [decision receipt](../.scratch/review-evidence-budget/process-probe.json)
is retained separately from the scorer's expected decisions.

## Limits and review state

Deterministic tests establish fixture and scorer behavior. They do not execute
the skill. The process probe makes decisions over supplied states; it does not
run a full orchestrator, dispatch chain, or publication path. The API probes
perform real source review and execution. These few runs do not establish broad
recall, false-positive rates, or a causal improvement over the prior instructions.
Claude/OpenCode model behavior, installed-copy loading, live Git/Perforce actions,
consumer integration, and publication remain untested. No consumer was updated.

Candidate review round 1 is complete. Standards: GREEN, zero blocking or warning
findings. Spec: GREEN, zero blocking or warning findings. Both reviewers checked
the complete diff and 13 captured files against the recorded hashes. Their INFO
text records scope and limits, accepted as such; it adds no acceptance claim.
The separate docs-alignment check reports aligned. No blocker repair or extra
candidate review round was needed. The synthetic fixture's two review cycles
have their own scope and do not consume candidate review rounds.

The [round-1 ledger](../.scratch/review-evidence-budget/review-round-1.json)
retains the input hashes, diff identity, reviewers, and actual final reports.
At the end of round 1, the final evidence rendering and tracker status recorded
the completed checks; the skill, tests, fixtures, and scorer were unchanged from
that reviewed capture.
The focused fixture repair re-review also passed. Owner acceptance remains open.
No push, PR, merge, tag, or release is authorized.

## Positive acceptance follow-up - 2026-10-19

The user authorized applying the demonstrated positive control, running all tests,
and reviewing again while keeping the changes local. The comparison audit in
round 2 found no model-review blockers, but a separate mutation check found that
all 20 fixture/scorer tests could pass when the scorer rejected every result.

The added CLI test requires exit 0 and a PASS result for
fixtures/review-protocol/valid-decisions.json. That file is the independent literal
receipt from the demonstration. It is neither a model output nor derived from
the scorer's EXPECTED table. The existing unsafe-output test still requires exit 1.
The new fixture SHA256 is
17b82244c86b9c475dc13d06848655b3fd2874c3c8f563a658747befac120563.

| Current check | Observed result |
| --- | --- |
| Full unittest discovery, test_*.py | 47 pass: 21 fixture/scorer tests and 26 source-verifier tests. |
| New test before the fixture was added | Expected failure: the valid-decisions file was missing. |
| Disposable reject-all scorer with the exact current test bytes | 20 pass; only test_cli_accepts_valid_decisions fails; exit 1 as required. |
| Pinned-source verification with --require-complete | 26 bundles pass; zero pending imports; five local skills. |
| Source hashes and base-byte comparison | 69 imported files and 26 source records unchanged; source policy unchanged. |
| Seven current CI PowerShell blocks | All pass, including Windows PowerShell 5.1 parsing. |
| Both Claude plugin validators | Pass. |

No scorer implementation, skill policy, source pin, or upstream byte changed in
this follow-up. Deterministic controls still do not prove model behavior or broad
review quality. Test quality and the spec's verification requirement are both
affected, so both axes re-reviewed the pinned delta in round 3. Standards: GREEN;
Spec: GREEN; no blocking or warning findings. Each reviewer independently ran
the captured 21-test fixture/scorer suite and checked all 15 file hashes. The
docs-alignment check reports aligned. The existing round history is retained;
there was no budget reset or fourth review round.

Round 3 delta SHA256:
75af95b41ab2c48df07e72e49bf149147c6cc8e3b927e5f36160d5dc83e4e055.
The existing review ledger retains the reports and input pins. After the review,
only actual results and tracker state were rendered; test and fixture bytes did
not change. Owner acceptance remains open. The work is local and uncommitted;
no publication or consumer update is authorized.

## Fresh Astra max review - 2026-10-19

The user requested another review with Astra at max effort and no inherited chat
history. Two fresh agents ran the separate Standards and Spec axes with
model gpt-6-astra, reasoning_effort max, and fork_turns none. This was one
user-authorized extra round, numbered 4; the prior three rounds remain recorded.

The full 15-file working-tree capture had diff SHA256
5da4198373a5202c4c743c515e6cd88b31299bdb2a25ca96b0bf720af1b2be47.
Both reviewers checked the captured hashes and treated earlier verdicts as
historical claims. Standards: WARNING W1; Spec: GREEN. Neither axis found a blocker.

W1 concerns the duplicate-result regression control in
test_review_protocol.py::test_missing_duplicate_unknown_and_malformed_results_fail.
Its duplicate entries also omit required fields and other cases. Those errors
can satisfy assertTrue(errors) even if duplicate detection is removed.

In disposable copies, removing only duplicate detection leaves all 21 fixture/scorer
tests passing. A complete valid receipt with one repeated runtime entry then exits
0, while the unchanged scorer rejects it with exit 1 and duplicate case: runtime.
The main session confirmed these two CLI results. The current scorer handles
duplicates correctly; this is a gap in regression coverage, not a current scorer
failure. Recommended improvement: use the complete valid receipt plus one valid
duplicate and require the duplicate error and a non-zero CLI exit.

At the end of round 4, disposition was [DEFERRED] W1, awaiting the user's decision.
The review changed no implementation or test bytes. Both agents ran the 21-test
fixture/scorer suite; Spec also confirmed the reject-all mutant still fails only
the positive acceptance test. The historical full 47-test and source-verifier
results were not repeated by these reviewers. Model behavior, full orchestration,
consumer integration, and publication remain outside this proof.

## Duplicate-only control and stable anchors - 2026-10-19

The user authorized fixing W1, running all tests, and avoiding fragile source
references. test_cli_rejects_duplicate_in_complete_valid_receipt now starts with
the complete literal receipt and repeats the runtime case selected by ID. It
requires the duplicate error alone and CLI exit 1. This input has no missing
fields or cases that could hide a broken duplicate check.

All 48 repository tests pass: 22 fixture/scorer tests and 26 source-verifier tests.
In a disposable scorer without duplicate detection, only the new duplicate-only
test fails; the other 21 pass. The mutation identifies the duplicate condition
by syntax, with no fixed source line offset. Another disposable run shifted the
Python source and test positions; all 22 fixture/scorer tests still passed.

The local review rule already required file and symbol/heading anchors, but
allowed optional line hints. It now keeps line numbers out of durable findings
and re-review references. A UI-required position must be derived from the pinned
content for that attachment, with a stable anchor in its body. Historical review
captures keep their recorded navigation data; no gate or test consumes it.
New finding records use file, symbol/heading, and revision without numeric line
positions. Tests assert case IDs, error identifiers, and exit codes, rather than
Markdown positions or exact instruction wording.

The scoped reference audit checked all 12 relative Markdown file links in this
changeset: no missing target and no numeric line link. Internal procedure step
references also resolve. Source verification passes for all 26 pinned bundles;
all 69 imported files, 26 source records, and the source policy remain unchanged.
Both plugin validators and all seven current CI PowerShell checks pass.

W1's requested test is implemented. Its originating Standards reviewer cleared it
in focused follow-up round 5. Standards and Spec both returned GREEN. Both reviewers
independently ran the 22-test suite and confirmed that only the new test fails when
duplicate detection is removed. Spec also confirmed the shifted-position control
and that the earlier captured review input remains unchanged.

The review ledger owns the detailed dispositions and latest review state. This
continues the same changeset history; it does not start a fresh automatic budget.
Work remains local and uncommitted. No publication or consumer update is authorized.

## Live navigation and review evidence

Normal docs and comments use live file and symbol/heading links, without revision
stamps. Review evidence owns its input revision/hash pins, shared through the
review record. Findings refer to that pinned input; another version needs a
separate pin. New reviews refresh their pins while old reports stay unchanged.
A document edit does not require updating every navigation link. Repair changed
targets and recheck claims whose meaning changed.

The local protocol now makes this distinction explicit in its pinning guidance,
review briefs, and blocker evidence field. The follow-up passed all 48 tests,
both package validators, seven CI script checks, and pinned-source verification.
All 69 imported files and 26 source records remain unchanged. At that stage, this wording-only
clarification had not run another review cycle; prior verdicts retained their
original input pins. The final review below includes the clarification.


## Final full Astra max review - 2026-10-19

The user requested one final full review, including the live-link clarification.
Two new agents used gpt-6-astra, max effort, and no inherited chat history. This
was user-authorized round 6; earlier rounds remain in the same ledger.

Both agents reviewed the same complete 15-file capture against the recorded base.
The ledger owns the shared input pin and full reports. Standards: GREEN. Spec:
GREEN. Neither axis found a blocker or warning. The live-link distinction, stable
anchors, evidence rules, round budget, and human approval gates were all included.

Each reviewer independently passed all 22 fixture/scorer tests and both 12-case
receipts. In disposable copies with identical test bytes, removing duplicate
detection failed only the duplicate-only test. A reject-all scorer failed only
the positive acceptance test. Spec also shifted source and test positions; all
22 tests still passed.

The main session reran all 48 repository tests and pinned-source verification;
both passed. The first sandbox run hit Git helper process and network limits.
The same checks passed with approved process and network access. Both attempts
remain in the check logs. All 69 imported source files and 26 source records match
the base and recorded hashes; source policy is unchanged. Spec independently
confirmed that source-integrity result. git diff --check also passed.

All 15 live and captured hashes matched before results were recorded. Only this
actual review evidence and tracker state were rendered after review. Policy,
implementation, tests, fixtures, and historical captures remain unchanged.
These checks do not prove broad model recall, consumer acceptance, or publication
readiness. No further automatic review is needed. Owner acceptance remains open;
the work stays local and uncommitted.
