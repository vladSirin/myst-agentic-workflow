# TDD plain-source conversion - 2026-10-08

Status: converted, tested, and independently reviewed; owner verification pending.
Review base: 52ef497. The owner verified deep-dive and authorized continuation.
Only TDD changes source layout here. This also prepares the current TDD package
for the owner verification still outstanding from its earlier wrapper migration.

## Source and local behavior

The approved Matt pin remains 6fd947921b935b7e1e69293a200400f0fdd5c15f.
The complete four-file source inventory is preserved byte-for-byte. SKILL.md
is packaged as references/upstream/UPSTREAM.md; tests.md, mocking.md, and
agents/openai.yaml retain their original names. Version 2 records only the
entry filename mapping, and scoped Git attributes preserve source bytes.
The full MIT notice is retained.

The wrapper's frontmatter, automatic invocation metadata, dependency list,
and local integration rules are unchanged. Its loading instructions now link
to the plain entry and both companions. Upstream-relative companion links
resolve from references/upstream. No source script requires the old entry name.
The wrapper still maps glossary paths and the conditional codebase-design and
review references through Myst. No seam-confirmation change, question relay,
worker orchestration, or review-protocol change is introduced.

All five migrated source bundles now use plain references; 20 imports remain
pending. This does not claim the entire upstream refresh is complete.

## Package checks

- All 26 verifier acceptance tests passed. Independent source acquisition
  verified five migrated bundles, 20 pending imports, and four local skills.
- Normal skills CLI 1.7.1 installation for Codex, Claude Code, and OpenCode
  preserved every package byte in both generated host directories. Each copy
  contains one SKILL.md, and both source companions are present.
- Fresh Codex 0.162.0-alpha.2 discovery selected the enabled local TDD wrapper.
  Debug prompt inspection included it in the automatic catalog. This proves
  exposure, not that every matching request will select it automatically.
- OpenCode 1.18.35 discovery selected the public wrapper and plain source link.
  No new OpenCode model request ran; Claude runtime remains deferred.
- A disposable Git index and core.autocrlf=true checkout preserved all four
  source files byte-for-byte.
- All six repository CI scripts and offline plugin/marketplace manifest checks
  passed. The complete staged git diff --check passed. Native slash-menu
  interaction was not repeated.

## Runtime comparison

The paired fixtures use the same task, current dependency packages, project
instructions, and model configuration. Every baseline file outside the TDD
package matches between each direct/wrapped pair. The direct TDD package has
only the four original upstream files under their original names. The wrapped
package is the actual converted package. Dependencies stay local and unchanged;
this is not a comparison with an entirely upstream skillset.

The confirmed case approves quote_drop_slot(requested_units, available_units)
as the sole public seam. It requires two literal results, one accepting a
request within available capacity and one rejecting a request above capacity.
The requested stopping point is the second green, before review or refactoring.
The fixture uses GLOSSARY.md.

The unconfirmed case asks for a SlipArchive interface but explicitly withholds
seam approval. It uses an authoritative legacy CONTEXT.md and permits workspace
writes, so any absence of tests is observed behavior rather than a read-only
sandbox restriction. The conditional codebase-design reference is relevant.

The earlier app-managed Codex path disappeared before these tests. Initial
launches failed before model execution; hashes confirmed unchanged fixture
inputs. The harness was updated to the current Codex 0.162.0-alpha.2 binary.
The runtime also encountered host sandbox startup errors. The initial
unconfirmed direct case could not read the skill and stopped; it is a blocked
harness result, not a successful seam-confirmation test. A separate retry uses
identical files and prompt. The retry completed the actual skill task. Other
successful cases recovered from startup errors before reading project files.
These environment failures are not source-loading or TDD correctness evidence.

### Confirmed seam alignment

Both runs loaded the source and both companion files before their first test,
read GLOSSARY.md, and recorded the already-approved seam. Their actual edit/test
traces show the same sequence, with command exit codes 1, 0, 1, 0:

1. Add the accepted-request test; it fails on the original NotImplementedError.
2. Implement only that behavior; one test passes.
3. Add the rejected-request test; it fails because the accepted-only code returns
   accepted=True and remaining_units=-1 instead of the literal rejection result.
4. Implement rejection; both tests pass. Stop before review/refactoring.

Final slot_quote.py text is identical after newline normalization. Both tests
call the public function and compare with the two user-supplied literal results,
without mocks or internal reads. Test method names differ. The wrapper records
the seam in TDD.md; the direct run uses TDD_SEAMS.md. These are equivalent records
of the same user confirmation, not required identical filenames.

Only implementation, test, and seam-record files changed. Skills and glossary
stayed unchanged. Git HEAD stayed at the baseline; no commit or publication ran.

### Unconfirmed seam alignment

Both successful runs read the authoritative legacy CONTEXT.md, consulted the
local codebase-design wrapper and plain vocabulary as a reference, proposed a
small SlipArchive with record/get, then asked for interface and seam approval.
Neither wrote tests or implementation; every input-file hash and Git HEAD stayed
unchanged. Neither created GLOSSARY.md or ran design subagents.

The proposed API details differ: the wrapper returns a DispatchSlip from record;
the direct run proposes None. Both hide JSON persistence and duplicate/conflict
handling behind the same two operations and leave the proposed seam unapproved.
This supports alignment of the confirmation behavior, not identical API design.
No source instruction was changed to force identical model choices.

| Completed case | Seconds | Result |
| --- | --- | --- |
| Confirmed wrapped | 100.355 | Two genuine red/green cycles; two tests pass |
| Confirmed direct | 100.495 | Same sequence, final implementation, and behavior |
| Unconfirmed wrapped | 61.546 | Interface proposal and approval question; no writes |
| Unconfirmed direct retry | 63.803 | Same approval boundary; no writes |

All four completed cases exited 0. Actual files, test output, edit order, source
and companion reads, fixture hashes, and Git HEAD were checked independently of
the models' final summaries.

## Evidence and limits

Temporary evidence: %TEMP%/myst-tdd-plain-20261008. It includes runtime prompts,
traces, outputs, baseline hashes and Git commits, copy-install/discovery output,
and checkout fixtures. The [earlier migration report](tdd-wrapper-2026-10-08.md)
retains the original upstream comparison and ZIP behavior evidence.

verification.json records changed files, command exit sequences, timings,
unchanged HEAD, and these trace hashes. Each confirmed case has test-sequence.json
with the actual test outputs and event positions.

| Completed trace | SHA-256 |
| --- | --- |
| confirmed-wrapped/trace.jsonl | 57a93a0c9ee8e13067b2d44352e57cee1c41be676dae4b49cb4c94be9668b2c9 |
| confirmed-direct/trace.jsonl | b2c9f173602c0aaa8490a1ea3cf606992d175c0bad393fe043570715be482080 |
| unconfirmed-wrapped/trace.jsonl | 6fc024601ea67a576980ac62b69984d2a08b50b7fac7f62281ef9ff872087a0d |
| unconfirmed-direct-retry/trace.jsonl | 6e0e3c0bf0fe264f588810e6c2b1aa956a6bb24920bf3b1246880d3c4d1a0837 |

Final independent reviews: Standards GREEN, zero findings; Spec GREEN, zero
findings. Both reviewers checked the completed evidence. The Spec review also
checked actual source/test outputs, responses, test order, trace hashes, and
unchanged Git HEADs. Owner verification remains pending.

These fixtures do not test the review stage, real external mocks, databases,
or persistence implementations. They cannot prove identical wording or every
future TDD behavior. Claude runtime, publication, and consumer updates remain
outside this changeset. Owner verification remains required.
