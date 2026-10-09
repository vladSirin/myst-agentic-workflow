# Writing-for-agents source and wrapper - 2026-10-09

Status: implementation and six alignment/guard runs passed. Package checks passed.
Both independent reviews GREEN. Owner verified on 2026-10-09 after the conditional alignment artifact recheck.
Review base: b13081d. This changeset migrates writing-for-agents alone.

The former entry and SKILL-MECHANICS companion match the approved Matt source.
There is no method delta. All three source files stay byte-for-byte intact under
references/upstream; only SKILL.md maps to UPSTREAM.md under ADR-0009. Previously
omitted Codex metadata is included, with model invocation enabled as before.
The public entry adds target-document/project/dependency/authority routing and
the source-relative filename mapping. All writing concepts and skill mechanics
remain owned by the complete source. The old root companion moved to the source
folder; no external live caller was found. UPSTREAM.json records approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f, subtree
skills/productivity/writing-for-agents, and all three source hashes.
The source census is 24 verified imports, 2 pending, and 5 local skills.

## Actual direct and wrapped alignment

Six fresh sessions used the normal configured Codex CLI, 0.162.0-alpha.2. Each
ran one actual turn. No model override, credential copy, host configuration edit,
or ephemeral session was used. Direct cases contain all three original source
files; wrapped cases contain the exact candidate package. Each pair has identical
prompts and identical project inputs/dependencies outside this skill.

The synthetic project is a Perforce target with a Git inventory mirror. Its
project pointers select Project/CONTEXT.md and Project/workflow.md. The term is
Event Bundle; the local ticket remains in-progress. Inputs include a noisy
agent guide, Delivery/Support references, a skill-authoring brief, and package.json
scripts. Inputs are draft data, not session instructions. Only requested local
Drafts artifacts can be added. Existing files and packages remain protected.

| Case | Actual observations | Result |
| --- | --- | --- |
| Document direct/wrapped | Read the complete writing reference; author Drafts/agent-guide.md, preserve Delivery/Support intent, clarify completion, disclose incident references, and replace command caches | Aligned |
| Skill direct/wrapped | Read complete method and SKILL-MECHANICS; author two draft entries and one plain shared Delivery reference, with requested model/user invocation choices | Aligned |
| Automatic selection | Task asks the agent to select relevant local guidance; it selects the fixture wrapper, reads method/contract, and authors the requested guide | Passed bounded reach test |
| Missing dependency | Reports both missing agentic-workflow files; stops before method, companion, or draft | Passed guard |

The paired guide drafts use Delivery and Support as clear branches. Delivery
loads service notes for reviews/send checks/ingestion inspection. Support loads
support limits for incidents and records time window and symptoms before test
selection. This replaces unconditional support-reference loading. Both guides
point to package.json for current command definitions, rather than copying the
old node command lines. They remove filler and repeated publication rules.

Both guide drafts require a ledger accounting for every required Delivery field:
idempotency ownership, retry ownership, payload limit, and retention period.
A field has a supported value/owner with evidence or an unresolved fact and owner
question. The completion gate is checkable before planning; unknown facts remain
unknown, and dependent actions remain conditional. Both retain local draft scope,
in-progress ticket state, implementation/owner acceptance, and publication approval.
The actual files have valid relative links from their new Drafts location.

Both skill cases create exactly these three files:

- Drafts/skills/event-bundle-review/SKILL.md
- Drafts/skills/event-bundle-review/references/delivery-rules.md
- Drafts/skills/rollout-interview/SKILL.md

The review entry has a model-facing trigger and no user-only switch, so the
requested automatic and explicit reach are preserved. Both interview entries
set disable-model-invocation: true and use a human-facing description. Other
skills may suggest its explicit command; they cannot auto-run its raw body.
Both keep the Delivery method in one plain file, which other skills can read
directly. They use the existing glossary and workflow rather than new copies.
The shared method accounts for all required fields before drafting a plan.
No router, executable helper, UI metadata, install, or registration is added.
All generated Markdown file links resolve, including source-of-truth pointers.

These outputs differ. The direct guide mostly obtains its field list from the
project context; wrapped also lists the current four fields. Wrapped gives a
separate planning completion bound; direct adds a final document/link bound.
Both apply the same required facts and unresolved-field gate. Wording, numbering,
headings, interview topics, and interview-record completion detail vary. Direct
asks the owner to confirm or correct the interview record; wrapped returns it
with open questions. That extra confirmation is not required by the fixture
brief. Direct's review trigger also covers draft Delivery plans; wrapped focuses
on Delivery review. Both cover the specified review branch. The plain shared
reference paths and invocation modes match. This is bounded semantic/process
alignment, not identical text or a claim that every optional workflow step matches.

The automatic-selection prompt invited use of relevant fixture writing guidance;
it did not explicitly invoke the skill by name or force a result. This is an
eligible local reach test, not a blind global routing benchmark. Its guide also
records synthetic check limitations and distinguishes planned from actual tests.
No downstream draft skill was installed or executed; those invocation choices
are artifact/frontmatter checks, not runtime proof for the generated skills.

## Source, installation, and discovery

- Independently acquired approved Git blobs match all three raw files and both
  former method files. The complete source verifier passes for all 24 imports.
- All 26 repository source-verifier acceptance tests pass. The verifier code and
  tests were not changed by this skill changeset.
- All six production CI scripts pass: PowerShell 5.1 parse, ASCII/BOM,
  frontmatter, version, install-line, and dead-reference checks. Codex's
  skill-creator quick validator reports the public entry valid. Diff check passes.
- Both offline Claude plugin validators pass. This does not run a Claude model;
  Claude runtime remains deferred until the owner reports that Claude works.
- skills CLI 1.7.1 normal copy installs pass for Codex, Claude Code, and OpenCode.
  Both physical installed trees match every candidate file hash. Runtime fixtures
  separately include agentic-workflow; dependencies are not automatically proven
  by installing the writing entry alone.
- Fresh Codex skills/list exposes one enabled public fixture entry, with original
  Writing for Agents metadata. Its implicit model catalog includes the entry.
- Isolated OpenCode 1.18.35 discovery finds one public wrapper. OpenCode model
  runtime for this skill was not run; discovery is distinct from invocation.
- A real core.autocrlf=true Git checkout preserves all three raw files. The raw
  companion stays with the raw method. SKILL.md back-links map to UPSTREAM.md
  as the entry directs; ordinary Markdown viewers do not perform that mapping.
  No extra raw discovery entry, symlink, extraction step, or renderer is introduced.

All six turns exited 0. Shell helper failures were retried under the same scoped
fixture rule; all failures remain in the traces. Some compound read commands
returned exit 1 because a later rg search named Drafts before it existed. Their
actual returned outputs still contain the complete original writing and companion
text. The first artifact verifier wrongly filtered those read receipts out by
command exit status. Its failure/script are retained. The corrected check requires
the full source text in returned output, while keeping command failures recorded.
No model turn or generated artifact was changed, excluded, or rerun. Source and
wrapper were not edited to fix the evidence-classification error.

| Case | Exit | Successful commands | Failed commands | Seconds |
| --- | --- | --- | --- | --- |
| document-direct | 0 | 3 | 5 | 109.752 |
| document-wrapped | 0 | 4 | 4 | 119.938 |
| skill-direct | 0 | 3 | 5 | 135.551 |
| skill-wrapped | 0 | 3 | 5 | 142.63 |
| automatic | 0 | 4 | 6 | 137.489 |
| missing-dependency | 0 | 2 | 2 | 40.497 |

The method is loaded in each authoring case. Both skill cases also load the
complete companion; guide-only cases do not load that skill-specific branch.
All existing fixture files, packages, input references, glossary, workflow,
tracker, HEADs, and branches remain unchanged. No staged changes remain in any
fixture. Document cases add only the requested guide; skill cases add only the
three requested draft files. The dependency guard adds nothing. There was no
live P4 action, VCS mutation, host change, recipient message, shared publication,
consumer update, or actual service call. Shared project authority rules apply
to both halves of each pair; the wrapper alone is not proven to cause compliance.
Elapsed time does not establish token cost or performance equivalence.

## Evidence and acceptance

Disposable evidence is under %TEMP%/myst-writing-for-agents-migration-20261009.
Each case retains before.json, actual workspace/artifacts, prompt, trace, stderr,
and run receipt. verify.py checks full returned source/companion text, paired
inputs, exact source/package identity, output scope, requested frontmatter,
actual draft content/links, dependency guard, and protected state. Its final
alignment-checks.json passes. Manual comparison of actual drafts assesses the
writing concepts and differences above. Source comparison, copy/package/checkout,
discovery, and implicit-catalog receipts are adjacent. The first verifier and
its reason remain as verify-initial.py and verification-initial-failure.txt.
Additional-checks.json records the executed unit and public-validator results.
Temporary artifacts may expire; this report retains assessed results and limits.

Arbitrary documents, other branch structures, conflicting project pointers,
unprompted global routing, cross-skill host dispatch, competing vendors, native
slash UI, live P4, actual publication, downstream generated-skill execution,
OpenCode model runtime, and Claude model runtime remain untested. Source equality
and these selected cases do not prove identical future choices or output quality.

Independent reviews assessed this same working-tree scope against b13081d,
including all complete additions and the companion move. Owner verification
remains pending for this new changeset. The current conditional instruction
verified to-questionnaire ebb2717; it does not close this new skill's gate.

## Standards review

Independent verdict: GREEN. Documented-standard breaches: 0. Heuristic findings: 0.

Reviewed all 14 pinned actions, including complete additions and the deleted
root companion. HEAD remains b13081dcb64f26b859d7f1253405bb17ede6d4b8. All action
hashes and the saved diff match before and after review.

The package follows CONTRIBUTING, ADR-0008, ADR-0009, and the source-record
contract. All three source files match independent pinned Git blobs. The
companion moved intact. Only the entry filename maps to UPSTREAM.md. Scoped
attributes, metadata, license, provenance, dependency, policy-waiver removal,
and catalog status agree. The required Myst wrapper boundary overrides the
possible Middle Man heuristic.

Report claims hold against the six original traces, prompts, protected-state
snapshots, and actual Drafts artifacts. Paired inputs match. Each case completed
one turn, added only its requested artifacts, and preserved existing bytes,
HEADs, branches, and staging.

The verifier correction is sound. Actual exit-1 receipts contain complete source
text before later commands fail. The final checker requires full returned source
text rather than heading fragments and retains failed-command counts. No model
rerun was needed.

The report discloses output differences and untested routes. It separates source
equality, discovery, generated-skill frontmatter, and runtime evidence. Shared
authority rules apply to both pair halves. Claude runtime remains deferred;
owner verification remains pending.

Standards summary: GREEN; total findings: 0; worst severity: none.

## Spec review

Independent verdict: GREEN. Missing/partial: 0. Scope creep: 0. Incorrect: 0.

Reviewed all 14 pinned actions, complete additions, and the companion
deletion/move against b13081dcb64f26b859d7f1253405bb17ede6d4b8. Base and HEAD
match; the commit list is empty. All hashes and the saved diff matched before
and after review.

The package preserves all three independent upstream blobs at the approved Matt
pin, including original metadata. The former method and companion already match
those blobs. Only the permitted entry filename changes. Attribution and license
are retained. Model invocation remains enabled. The wrapper adds only the
permitted project, dependency, authority, and source-path routing.

Both actual pairs satisfy the required outcomes: branch-specific pointers and
disclosure, checkable exhaustive Delivery completion, removal of command caches,
requested model/user invocation modes, one shared plain reference, and bounded
draft output. The report records optional interview differences accurately.

All six retained traces support their reported results. Compound commands
returned full source text despite later failures. The verifier correction
strengthens loading proof from selected headings to complete raw text; it
preserves failure counts. No turn or output was rerun or changed. Snapshots,
paired inputs, package copies, checkout bytes, discovery, and the implicit
catalog match their receipts.

Automatic reach is a bounded invited-guidance test. Generated skills were neither
installed nor executed. Shared authority rules prevent a wrapper-only causal
claim. OpenCode and Claude model runtime remain unverified, as disclosed.
Owner verification remains pending before another skill changeset.

Spec summary: GREEN; total findings: 0; worst severity: none.

## Owner verification

The owner authorized verification if alignment passed, then the next skill.
On 2026-10-09, verify.py rechecked all six unchanged saved turns against
committed candidate f40945e. Every check passed: exact source/package bytes,
paired inputs, complete returned method/companion, draft scope/content/links,
invocation modes, automatic catalog, dependency guard, and protected state.
This was an artifact recheck, not a fresh model run. Candidate f40945e is verified
OK. Earlier pending statements record the pre-acceptance review state.
