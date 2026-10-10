# Roundtable source and wrapper - 2026-10-09

Status: implementation and all ten alignment/guard turns passed. Package checks
passed. Both independent reviews GREEN; owner verified e44e253 on 2026-10-09.
Review base: b644479. This changeset migrates roundtable alone.

The complete original file at Hammer v0.19.0 and approved v0.30.0 is identical.
The former Myst body matches after frontmatter removal and newline normalization.
The one-file source subtree stays byte-for-byte intact under references/upstream
with only SKILL.md mapped to UPSTREAM.md. English public frontmatter, argument
hint, and model invocation remain unchanged. New English display metadata is
local; Hammer has no metadata file for this skill. The entry only loads the
source, like deep-dive. It adds no method rule or workflow dependency.
The existing redistribution and re-vendoring permission is retained verbatim;
no new public license is asserted. Author credit and revision date remain raw.

UPSTREAM.json is authoritative for the approved v0.30.0 release, asset ID
614238989, source subtree, and complete archive SHA-256. The original SKILL.md
hash is 44531a16d1662a831562de8d5e58f27e2821bea5c541c3a56c94e1507681a358.
Both complete retained release archives were rehashed and matched their recorded
hashes before extraction. The adjacent advanced-capabilities README was read;
it describes Hammer installation and adds no method dependency or license.
The source census is 25 verified imports, 1 pending removal, and 5 local skills.
The planned implement-spec addition is outside that existing-import census.

## Stateful direct and wrapped alignment

Six fresh sessions used the normal configured Codex CLI, 0.162.0-alpha.2. Each
main session resumed twice through exec resume for three actual turns. This is
ten turns across six cases. The actual first thread UUID stays unchanged through
both continuations. No model override, ephemeral session, credential copy,
or host configuration change was made.

Each main prompt and no-topic prompt is identical across its pair. All fixture
inputs outside roundtable match as well. Direct contains the one original source
file; wrapped contains the exact candidate. The missing-source fixture deliberately
removes only the raw method to check loading failure. No extra workflow skill
is installed: this conversation-only method declares no dependency.

The synthetic project is a Perforce target with a Git inventory mirror. It uses
Project/CONTEXT.md and Project/workflow.md. The term Release Run denotes a release
operation. Local instructions authorize only dialogue, protect every file and
VCS state, and keep Work/ticket.md in-progress. The scenario supplies a four-person
team, a milestone in three weeks, a proposed 16-engineer-hour automation effort,
weekly stable work of 15 minutes, weekly changing work of 45 minutes, eight runs
without observed incidents, unknown future risk, and a milestone-critical defect.
Three fictional thinking-school representatives cover reliability, delivery,
and efficiency. No real people, current outside facts, or real quotations are used.

| Case/turn | Actual observations | Result |
| --- | --- | --- |
| Main opening | Accept supplied topic without asking for it again; define concepts, introduce three simulated perspectives and lightweight MBTI, exchange responsive claims/criticism, summarize with ASCII, propose next question, and pause | Aligned |
| Main continue | Resume actual UUID; retain participants and prior disagreement, incorporate 45-minute checklist and unmeasured 70% estimate, revise conditional positions, give another ASCII summary and pause | Aligned |
| Main stop | End after the stop command; synthesize concepts, consensus, disagreement/premises, conditions/counterexamples, open questions and thought directions into final network | Aligned |
| No topic | Load source, ask which topic/question to discuss, and stop without invented topic or dialogue | Aligned pause |
| Automatic selection | Task invites relevant local guidance without explicit skill command; choose fixture wrapper, load complete source, perform one round and pause | Passed bounded reach test |
| Missing source | Read public entry, identify absent UPSTREAM.md, stop before simulated discussion or fallback | Passed guard |

Actual first-turn command outputs contain the complete original source, not only
its path. Every workspace byte remains unchanged after both opening and continued
rounds. The final check confirms every workspace file, package, glossary, workflow,
ticket, HEAD, branch, and staged-file list still matches the initial state. No
model turn was excluded, edited, or rerun; no method or wrapper tweak followed
an output difference.

Both main first rounds compute the three-week time comparison under explicit
single-operator/weekly assumptions: up to three hours of direct execution time
versus a 16-hour proposal. They distinguish those assumptions from given facts,
observed absence of incidents from proof of safety, and automatic execution from
verified reliability. Speakers directly challenge prior claims and refine them,
rather than giving unrelated monologues. Each summary retains different evidence
thresholds and ends with the source's four user controls.

Both continued rounds keep their original named speakers. They add the 45-minute
checklist as a third option and compare its 0.75-hour preparation cost with the
16-hour proposal. The 15.25-hour preparation difference is not claimed as net
benefit. Both reject treating the estimated 70% as measured risk reduction; they
question its denominator and whether the remaining risks are severe. They lean
toward evaluating checklist-assisted manual work while keeping effectiveness,
ongoing costs and the critical engineer's time unknown. Proposals remain proposals.

Both stop responses end the dialogue rather than offering the next round. Their
knowledge networks preserve definition changes, conditional consensus, unresolved
perspective-specific demands, assumptions and values, causal relations, boundary
conditions and hypothetical counterexamples. They retain the new checklist
questions and directions for further thought. They do not invent a final team
decision or turn the conversation into implementation/acceptance evidence.

There are differences. Fictional names, speech counts, chart shapes, and next
questions vary. Wrapped's first and final outputs add optimistic long-term
payback calculations; direct focuses on the milestone and relative checklist
benefit. Both label those calculations/risks conditional. Direct's last response
uses tables and labelled sections; wrapped uses more prose. Wrapped's final lead
emphasizes insufficient evidence to pick the best option, while both retain the
tentative checklist evaluation from round two. No-topic direct asks in Chinese;
wrapped asks in English. The empty-topic prompt did not require a language.
Both main prompts required Chinese and both complied. These are semantic/process
and control-flow matches, not identical wording, participants, or every future
judgment. One pair cannot attribute variation to wrapping.

## Source, copy installation, and discovery

- Source extraction inventories from both complete archives contain only SKILL.md
  in this subtree and match exactly. Public frontmatter and the existing
  permission paragraph match their pre-migration versions.
- The complete verifier independently reacquires pinned source and verifies all
  25 bundles, including Hammer asset/archive identity and original file bytes.
- All 26 source-verifier acceptance tests pass. No verifier code or test was
  changed by this skill changeset.
- All six production CI scripts pass: PowerShell 5.1 parse, ASCII/BOM,
  frontmatter, version, install-line, and dead-reference checks.
- Both offline Claude plugin validators pass. Claude model runtime remains
  deferred until the owner reports that Claude works.
- skills CLI 1.7.1 normal copy installs pass for Codex, Claude Code, and OpenCode.
  Both physical installed trees match every candidate file hash.
- Fresh Codex skills/list exposes one enabled public fixture entry with the
  unchanged English description and new Roundtable display metadata. The local
  entry appears in the implicit model catalog, matching its invocation mode.
- Isolated OpenCode 1.18.35 discovery finds the public wrapper once. Its model
  runtime was not run; discovery is distinct from invocation.
- A real core.autocrlf=true Git checkout preserves the raw Chinese source bytes.
  There is no second discoverable source entry, symlink, extraction command,
  runtime download, renderer, or installed-plugin edit.

The final staged whitespace check reports only the original two-space Markdown
line breaks on source lines 8 and 9 (author and date credits). Those raw bytes
remain intact. Local-file whitespace checks pass. The commit guard checks those
exact upstream diagnostics separately and verifies the staged source hash;
it does not normalize the original file to satisfy a local style check.

All ten turns exited 0. Initial shell helper errors were retried under the same
scoped fixture rule and remain in the original traces. No failing model turn
was excluded or replaced. Elapsed time is not a token/performance comparison.

| Case/turn | Exit | Successful commands | Failed commands | Seconds |
| --- | --- | --- | --- | --- |
| direct round 1 | 0 | 2 | 2 | 135.1 |
| direct round 2 | 0 | 0 | 0 | 88.008 |
| direct round 3 | 0 | 0 | 0 | 66.475 |
| wrapped round 1 | 0 | 3 | 3 | 133.44 |
| wrapped round 2 | 0 | 0 | 0 | 84.509 |
| wrapped round 3 | 0 | 0 | 0 | 64.846 |
| no-topic-direct round 1 | 0 | 1 | 1 | 27.07 |
| no-topic-wrapped round 1 | 0 | 2 | 2 | 40.087 |
| automatic round 1 | 0 | 2 | 2 | 124.71 |
| missing-source round 1 | 0 | 1 | 3 | 46.465 |

The first artifact verifier expected selected heading phrases for open questions.
Actual finals use remaining questions/thinking directions and retained thinking
questions. Both contain substantive open questions from the later checklist
choice. The failed script and reason are retained. The corrected check requires
actual question content and the new 70% estimate, while retaining concept,
consensus, disagreement, premise and boundary checks. Manual comparison assessed
all required network components above; punctuation alone is not semantic proof.
No source, wrapper, model turn, or generated response was changed to fix the
classification error. All ten unchanged turns pass the final artifact verifier.

## Evidence and acceptance

Disposable evidence is under %TEMP%/myst-roundtable-migration-20261009.
Each case retains before.json, its actual workspace, prompt, trace, stderr, run
receipts, and final response captures derived from those unchanged traces. Main
pairs also retain after-round-1.json and after-round-2.json snapshots. run.py
resumes the original thread ID. verify.py checks exact source/package identity,
complete returned source, paired inputs, actual continuation, pause/stop controls,
ASCII frames, network content, public frontmatter, permission, guard and unchanged
state. Its final alignment-checks.json passes. Original failed verifier/reason,
source comparison and adjacent README, CI/copy/checkout/discovery/catalog receipts,
and source-verifier logs are adjacent. Manual semantic comparison supplements
the mechanical checks. Temporary artifacts may expire; this report retains the
assessed results, differences, and limits.

Shared project/authority instructions apply to each pair; there is no claim that
the wrapper alone prevented writes. The automatic prompt invited structured local
discussion, so it is not a blind global routing benchmark. Fictional schools were
specified by the test; autonomous choice of real representatives and accuracy of
public-thought simulation remain untested. Deepen-section, add-person commands,
free-form steering, arbitrary subjects, competing vendors, native slash UI,
actual project implementation/publication, live P4, OpenCode model execution,
and Claude model runtime remain untested. Source equality does not establish
identical future answers or conclusions.

Independent reviews assessed the same working-tree scope against b644479,
including all complete additions and the retained permission. Owner verification
remains pending for this new changeset. The current conditional instruction
verified writing-for-agents f40945e; it does not close this new skill's gate.

## Standards review

Independent verdict: GREEN.
Findings: 0 documented violations; 0 smell findings. Worst Standards issue: none.

The reviewer assessed all eleven pinned file actions and complete additions
against CONTRIBUTING, ADR-0008, ADR-0009, and the complete twelve-smell baseline.
Before and after review, base/HEAD, the empty commit list, all pinned file hashes,
and the saved diff matched. The diff SHA-256 was
2e4cb0179e0059b8d182879ec20a6595aebf397963820315d8c456cd22416978.

Both complete archives were independently rehashed and their complete Roundtable
subtrees read. Each contains the same single original SKILL.md. Packaged source,
Chinese frontmatter, author credit, English public frontmatter, argument hint,
and the existing permission match. Local metadata is distinct from source
ownership. The possible Middle Man heuristic does not override the documented
wrapper boundary; no speculative orchestration was added.

The reviewer read all ten actual outputs, prompts, receipts and trace commands.
Captures match trace finals. Both continuation pairs keep their actual thread
IDs. Both final networks contain substantive required categories and later
checklist questions. The corrected classifier supplements that semantic review.
Protected inventories, intermediate snapshots, HEAD, branches and staging match.
The report states invited automatic selection, shared authority instructions,
answer variation and untested/deferred paths accurately. No reviewer edit,
model run or publication occurred. Owner verification remains pending.

## Spec review

Independent verdict: GREEN.
Findings: 0 missing/partial; 0 scope creep; 0 incorrect implementations.
Worst Spec issue: none.

The reviewer assessed the complete approved source, issue 36, plan, eleven
pinned actions, actual outputs and original receipts. Both archives contain the
same complete one-file subtree. Candidate bytes, Chinese frontmatter, author
credit, asset 614238989, archive identity and sole filename mapping are correct.
English public frontmatter, argument hint, model invocation and permission remain
intact. The wrapper adds no method rules or workflow dependency.

Both main UUIDs resume twice, retain participants and prior state, and keep the
70% estimate unmeasured. Both final networks contain all seven required categories
and end the discussion. Open questions include directions for further thought.
The corrected classifier matches those artifacts; punctuation alone would not
establish that result. No-topic sessions ask and pause. Automatic use loads the
wrapper and complete method. Missing source stops before dialogue or fallback.
Protected files and VCS state remain unchanged. Variation and untested paths are
reported accurately. Shared fixture rules do not establish wrapper-only causation.

All eleven pinned hashes, saved diff bytes, base/HEAD, empty commit list and
staging match before and after review. Owner verification remains pending.

## Owner verification - 2026-10-09

The owner authorized verification if alignment passed, then the next skill.
The saved ten turns were rechecked against committed e44e253. All source,
package, actual continuation, final-network and protected-state checks pass.
Both independent reviews remain GREEN. Roundtable is verified OK. Earlier
pending statements above describe the pre-acceptance state. No new model run
was needed for this unchanged package. Next: Git-only implement-spec.
