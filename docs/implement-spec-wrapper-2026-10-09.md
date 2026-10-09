# Implement Spec source and wrapper - 2026-10-09

Status: complete source and local entry implemented. All nine configured root
sessions, source and package checks pass. Whole-spec results align. Independent
package reviews GREEN; owner verification remains pending. Review base: d3eeede. This changeset adopts implement-spec alone.

## Source and local boundary

This is a new Matt Pocock import, with no previous Myst method to compare.
The approved pin is 6fd947921b935b7e1e69293a200400f0fdd5c15f, subtree
skills/engineering/implement-spec. Its complete inventory contains two files:

| Original path | SHA-256 |
| --- | --- |
| SKILL.md | 7a22dd2e60b8fcece478ced9d2533582adf3520d695acd3ab715341535c9e56d |
| agents/openai.yaml | fd41efb42c60c96320d6531be7e4bf15cbf5518cd652d57dff27ccffa46988e9 |

Both files remain intact under references/upstream. SKILL.md alone is packaged
as UPSTREAM.md. Public agents/openai.yaml matches the upstream file exactly,
including allow_implicit_invocation: false. Local entry frontmatter preserves
disable-model-invocation: true and adds the Git-only description. The full MIT
notice from the pinned upstream root is retained in PROVENANCE.md. Scoped -text
attributes preserve source bytes through checkout.

The entry loads the shared target/project contract before the upstream workflow.
A Perforce target stays Perforce when it has a Git mirror. Unclear ownership
must be resolved first. This user-only method is not selected automatically or
invoked by another skill; other skills can suggest its explicit command.
Required copy dependencies are agentic-workflow, tdd, review-and-submit,
code-review and changelist-verification. Their Git closure adds codebase-design
and pr. Dependencies use the Myst namespace or explicit installed paths.

Myst maps the project's tracker and domain documents, TDD at agreed seams, and
final review through review-and-submit and its code-review engine. Existing
changeset verification and human-only ticket rules retain their authority.
Branch/commit/merge work stays in the authorized local scope; PR creation or
readiness, push and shared publication require the existing protocol. The entry
adds no task-to-changeset mapping, TDD question relay, P4 counterpart or scheduler.
Upstream task graph, worktree/worker, merger, integration and cleanup stay intact.
The existing shared contract already owns staged Git-only routing; no separate
agentic-workflow changeset is added here.

## Disposable whole-spec pilot

Two fresh sessions use the normal configured Codex CLI, 0.162.0-alpha.2, with
identical prompts and non-skill inputs. Direct installs the complete original
two-file source; wrapped installs the exact candidate. Both have the same full
Myst dependency closure and project rules. There is no model override, ephemeral
session, credential copy, host configuration change or real project work.

The synthetic Git project uses Records/CONTEXT.md as its authoritative legacy
domain document. Root GLOSSARY.md is an unrelated decoy. Records/workflow.md owns
the tracker and Records/spec.md the approved behavior. S1 (Capacity) and S2
(Priority) are independent; S3 (Dispatch) depends on both. Each worker owns only
its module, public-seam test file and ticket. The same fixture rules pre-approve
those TDD seams and literal examples. Only Python's standard library is needed.

The disposable fixture explicitly authorizes all local ticket branches and
merges at once under the existing changeset-verification exception. That scoped
test exception is not a rule change or task-to-changeset policy for real projects.
The tracker is not PR-driven and has no remote. Work can become resolved after
combined tests and reviews, with owner verification outstanding; no ticket/spec
may become closed. Existing dirty local-note.txt and untracked personal.txt must
remain exact and uncommitted. Skill packages, project rules, domain documents,
spec, existing tests and main history are protected. Workers use separate Git
worktrees under their case's disposable output directory.

Both main sessions finished with exit 0. Each loaded the complete method and
actually dispatched S1 and S2 background workers, a prerequisite merger, S3,
a final merger and separate Standards/Spec reviewers. Original session dispatch
receipts identify those calls; they are not a proposed agent list. Wrapped also
used a separate docs-alignment reviewer. Workers confirmed their integration
base and retained red-before-green evidence. Merger receipts record six passing
combined tests before S3. Both prerequisite tips are ancestors of S3's actual
implementation parent, not only its eventual final tip.

Every non-merge code commit stays within one worker's module/test/ticket ownership.
Final lifecycle-only commits change the three ticket files. Each final integration
candidate changes exactly nine allowed paths: three modules, three new tests and
three tickets. All protected Git blobs, original main tips, dirty/untracked file
bytes and empty staging remain exact. No remote or publication exists. Both
runs remove every created worktree; only each original checkout remains registered.
All tickets are resolved with explicit owner verification outstanding; none is
closed and the approved spec is unchanged.

| Case | Final integration branch and tip | Actual suite | Final pilot review |
| --- | --- | --- | --- |
| Direct | integration/reservation-selection at db0fa43092b0b5cb91f2ba8811ddcd84b02a16f4 | 8 passed | Standards GREEN; Spec GREEN |
| Wrapped | implement-spec/reservation-selection at 8e0494561a2fbd87611f74b504a488cc299cf3a9 | 9 passed | Standards GREEN; Spec GREEN |

The artifact verifier independently extracts the actual committed Python artifacts
and reruns their suites. Both pass. Additional literal public-interface probes
pass on both: Capacity below/at/above its limit; Priority descending/stable order,
new list and preserved input; Dispatch b,c selection, at/above-capacity empty
results, empty input and preserved requests. Manual reading of actual modules,
tests, final reports, TDD/merge logs and final review reports agrees. This is
alignment of the tested method, behavior, integration and authority boundaries.

There is variation. Capacity and Priority implementation bytes match. Dispatch
slices Requests before ID projection in direct and after projection in wrapped;
both return the specified results for the supplied valid Requests. Tests group
cases differently (8 versus 9 test methods). Direct checks out its integration
branch in the original work area; wrapped uses a separate integration worktree
and keeps the original checkout on main. Branch names, intermediate commits,
report layout and the extra docs reviewer differ. These are permitted choices,
not identical execution. One pair does not attribute variation to wrapping.
No model run was excluded or repeated; no source, wrapper or output was changed
in response to a main-pilot result.

The nine root command counts below exclude subagent tools. Child TDD/merger/review
receipts retain their failures/retries separately. Shell helper errors and owned
file newline corrections did not cause model-turn replacement. Elapsed time is
not a cost or performance comparison.

| Case | Exit | Root successful commands | Root failed commands | Seconds |
| --- | --- | --- | --- | --- |
| git-direct | 0 | 20 | 1 | 1118.072 |
| git-wrapped | 0 | 21 | 1 | 1084.7 |
| p4-direct | 0 | 5 | 3 | 56.562 |
| p4-automatic | 0 | 3 | 5 | 99.428 |
| p4-cross | 0 | 5 | 2 | 56.893 |
| git-automatic | 0 | 2 | 1 | 48.898 |
| missing-dependency | 0 | 4 | 1 | 54.692 |
| human-only | 0 | 2 | 1 | 47.197 |
| ambiguous | 0 | 4 | 3 | 57.152 |

## Applicability and guard outputs

Seven fresh configured sessions finished with exit 0. All protected files,
HEADs, branches and staging remain unchanged. No source workflow was loaded for
P4 direct, automatic or cross-skill requests, even with the Git mirror. No native
P4 command ran. The P4 cases report the existing project Perforce workflow.

| Case | Actual result |
| --- | --- |
| P4 direct | Read local entry/contract; explain Git-only exclusion and stop |
| P4 automatic | Use applicable local guidance to describe the existing P4 route; no implement-spec workflow |
| P4 cross-skill | Fixture router uses shared contract and existing P4 workflow; no indirect user-only invocation |
| Git automatic | Search skill names/metadata, inspect public entry, suggest explicit command, load no complete upstream method and make no changes |
| Missing TDD | Stop before implementation; report missing local tdd entry, use no substitute |
| Human-only | Inspect eligible Git method/tickets; preserve all ready-for-human states and make no branches, worktrees or edits |
| Unclear target | Ask which VCS owns the work; load no upstream method and make no changes |

The first inline artifact check incorrectly required no method read in the
human-only Git case. Its actual requirement is no implementation or relabelling.
The run did inspect the method, then stopped, with every protected state unchanged.
The corrected check preserves the no-method-load condition for the other six
cases. The original tool trace and a reason receipt are retained. No model run,
source, wrapper or output was changed or rerun to correct that classification.

## Source, copy installation and discovery

- The repository verifier independently fetches pinned source and reports 26
  verified imports, 1 pending removal and 5 local skills. The remaining debt is
  resolving-merge-conflicts. No source-verifier code or test was changed.
- All 26 existing source-verifier acceptance tests pass.
- All six production CI scripts pass: PowerShell 5.1 parse, ASCII/BOM,
  frontmatter, versions, install lines and dead references.
- Both offline Claude plugin validators pass. Claude model runtime remains
  deferred until the owner says Claude works.
- skills CLI 1.7.1 normal --copy installs pass for Codex, Claude Code and OpenCode.
  The new package matches every file in both physical destination trees.
  A separate normal copy install of all eight Git dependency-closure entries
  matches every file in both .agents/skills and .claude/skills trees.
- Fresh Codex skills/list exposes one enabled fixture public entry with its
  Git-only description and unchanged display metadata. It is absent from the
  implicit model catalog. Metadata/discovery is distinct from native slash UI.
- Isolated OpenCode 1.18.35 discovery exposes the public wrapper once. OpenCode
  model invocation was not run; its local user-only restriction remains needed.
- A real core.autocrlf=true checkout preserves both original source files exactly.
  There is no duplicate raw SKILL.md, runtime archive extraction, source download,
  renderer, symlink or installed-plugin edit.

## Evidence limits and acceptance

Evidence is under %TEMP%/myst-implement-spec-migration-20261009. Each case retains
its actual workspace, initial hashes/VCS snapshot, prompt, original trace, stderr,
run receipt and final response capture. Both main cases retain actual worker
red/green and merger logs, pinned review evidence and the resulting Git history.
verify.py checks all nine actual outputs, exact source/package identity, paired
inputs, real dispatches, branch ancestry, ticket states, cleanup, protected state,
actual committed tests and independent literal behavior. alignment-checks.json
passes. ownership-order-checks.json verifies bounded code commits and the S3
implementation parent. Actual dispatcher metadata is retained separately, without
copying full host/session context. Source comparison, independent acquisition,
production checks, complete normal
copies, checkout, discovery and model-catalog checks remain adjacent. Temporary
artifacts may expire; this report records the assessed results and limits.

Shared fixture rules and Myst dependencies apply to both sides. They prevent
attributing the protected state or local authority behavior solely to the wrapper.
The explicit requests identify the local entry, so this is not a blind global
routing benchmark. A toy task graph does not establish arbitrary graph behavior,
conflict resolution, failed workers/retries, optional exploration, review-fix
paths, real PR readiness/closure, hosted publication, live P4, native slash UI,
OpenCode model invocation or Claude model runtime. Human-only and ownership
checks are bounded read-only cases, not permission to change real tracker state.
Source equality and one pair do not establish identical future answers or speed.
Elapsed time is not a token/performance comparison.

Both independent package review axes are GREEN; owner verification remains pending.
The current conditional instruction verified roundtable e44e253; it does not
close this new skill's gate.

## Standards review

Independent verdict: GREEN.
BLOCKING: 0; WARNING: 0; INFO: 1. Worst Standards issue: none actionable.

No documented-standard breach was found. The package meets CONTRIBUTING's
source/provenance, loading, authority and catalog rules, ADR-0008's boundary and
ADR-0009's sole filename exception. Independent comparison against source.git
confirms both complete source files, exact public metadata and pinned MIT notice.
The entry preserves user-only invocation, checks Git eligibility before source,
and routes dependencies/project/review/publication through existing Myst contracts.
No speculative orchestration or TDD relay was added.

The reviewer applied all twelve smell heuristics. No actionable smell remains.
The documented wrapper boundary overrides Middle Man; required source copies,
metadata, attribution and catalog records do not establish a duplication finding.

Actual Git artifacts confirm bounded worker commits, prerequisite ancestry at
S3's implementation parent, exact protected files/main/blobs/staging, and cleanup.
Committed code/tests, TDD logs, merger records, separate reviews and original
agent-dispatch receipts support the disclosed alignment and variation. All seven
guard traces match their reported boundaries; the human-only method read is valid.

INFO [ACCEPTED AS EVIDENCE LIMIT]: Guards are bounded read-only cases. Git-automatic
search exposes matching raw source metadata lines without loading the complete
method. Shared fixture rules apply to both halves. Arbitrary graphs, retries,
publication, live P4, native slash UI, OpenCode execution and Claude runtime
remain unproved. Owner verification remains pending.

All eleven action hashes, branch, HEAD, empty commit/staging lists, and saved/live
diff SHA matched before and after review. No reviewer edit or publication occurred.

## Spec review

Independent verdict: GREEN.
BLOCKING: 0; WARNING: 0; INFO: 2. Worst Spec issue: none actionable.

No missing/partial requirement, extra scope or incorrect implementation was found.
The complete two-file source, MIT notice and public metadata match pinned Git
blobs. The sole filename mapping follows ADR-0009. The entry retains user-only
invocation, Git eligibility, Myst dependency/tracker rules, human ownership and
review/publication authority.

The reviewer inspected actual modules/tests/tickets, histories, worker/merger
receipts and final review reports. Both S3 implementation parents contain both
prerequisite tips. Code commits stay within worker ownership; lifecycle commits
change only tickets. Candidates change exactly nine allowed paths. Protected
files/main/dirty/untracked bytes/staging remain intact; created worktrees are
removed and no remote or publication exists. Independent committed suite replays
pass (direct 8, wrapped 9); independent literal probes pass both.

INFO [ACCEPTED AS EVIDENCE LIMIT]: Issue 37 requires keeping the user-only contract.
Guard commands/snapshots support this requirement. Automatic Git search exposes
raw name/metadata matches but reads no complete method or performs its workflow.
Eligible human-only invocation reads the method, then preserves all ticket state.

INFO [ACCEPTED AS EVIDENCE LIMIT]: Issue 37 keeps owner verification as the next
changeset's gate. The report preserves it. The toy pair supports tested semantic
and method alignment; shared rules do not establish wrapper-only causation.
Complex graphs, worker failure, publication, native slash UI, OpenCode execution
and deferred Claude runtime remain unproved and disclosed.

All eleven actions/hashes, pre-review report hash babad120c1218bb6ff51a187f805b313b721f1f0c96f636e794e4e7773706840,
diff hash 6e6e4654d34f9e488baa357b807bcfa54310f0eac397fcd89bbaedd41580d953,
base/HEAD d3eeede, branch, empty commit range and staging match before and after
review. No reviewer edits or new model sessions occurred.
