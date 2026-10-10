# Teach source and wrapper - 2026-10-09

Status: implementation and alignment checks passed; both independent reviews
GREEN. Owner verified 6dc2168 on 2026-10-09 after alignment artifact recheck.
Review base: 8a5f222. This changeset migrates teach alone.

The former Myst entry and all four format companions exactly match the approved
Matt source pin. There is no method delta. Six source files stay whole under
references/upstream; SKILL.md alone maps to UPSTREAM.md under ADR-0009. All four
old root companions move into that bundle. The local entry explains a companion
back-link to SKILL.md as the mapped UPSTREAM.md. Original Codex metadata and
user-only invocation are preserved. The local entry resolves the selected
teaching workspace, scoped vocabulary, dependency, and later work authority.
The complete source owns the method and learning formats. UPSTREAM.json records
pin 6fd947921b935b7e1e69293a200400f0fdd5c15f, subtree skills/productivity/teach.
The census is 22 verified imports, 4 pending imports, and 5 local skills.

## Direct and wrapped teaching alignment

Six fresh Codex sessions used the normal configured CLI, codex-cli 0.162.0-alpha.2. The main
pair each continued once with exec resume, for eight turns across all cases.
Each continuation keeps its actual first-round thread ID. Both main prompts and
both mission-pause prompts are identical between direct/wrapped pairs. All
project files and dependencies outside teach also match. Direct uses all six
original source files. Wrapped uses the complete exact candidate package.
No model override, credential copy, or host configuration change was used.

The owner-selected course is Course inside a Perforce target with a local Git
inventory mirror. Course/AGENTS.md selects the legacy Course/CONTEXT.md as the
teaching vocabulary; broader Project/CONTEXT.md is a separate application domain.
The mission is to read a small JSON report and prepare JSON text for a teammate.
Existing records establish dictionary access, but no JSON understanding. Prior
lesson/reference files, shared CSS, and an immediate-feedback quiz component
already exist. The learner opts out of communities.

RESOURCES.md supplies a checked, bounded reading note grounded in the
[primary Python json documentation](https://docs.python.org/3/library/json.html).
Both runs read that note and cite the official URL. The topic and resources are
intentionally sufficient for the small string-conversion lesson; this does not
test the source's poor-resource research branch or arbitrary topics.

| Case | Actual direct and wrapped behavior | Result |
| --- | --- | --- |
| Mission absent | Load method/companions and Course state; ask why, observable success, and limits; wait without writing | Aligned |
| One lesson | Use mission and known floor; add lesson 0002 plus a compressed reference; reuse existing CSS/quiz; cite primary source; ask for recall; leave understanding unverified | Aligned |
| Learner demonstration | Resume actual session with identical unaided written answer; add LR-0002 with evidence and limits; promote demonstrated terms in selected Course/CONTEXT.md; preserve mission and stop | Aligned |
| Automatic eligibility | Explain user-only rule from public entry; do not load or run raw method | Passed guard |
| Missing dependency | Identify absent agentic-workflow entry and contract; stop before raw method or teaching writes | Passed guard |

The successful command receipts show actual public-entry loading, complete
source and all four format companions, mission, resources, prior learning state,
and assets being read. The wrapped trace also shows the shared contract. Actual
new HTML files and continued learning records were inspected; claimed paths alone
are not the artifact evidence.

All existing files are unchanged after lesson authoring, including vocabulary
and prior records. The first response does not promote exposure to mastery. Both
lessons ground one small step in the mission, use immediate quiz feedback, ask
for recall rather than copying, link prior/reference materials, recommend the
primary source, invite follow-up questions, and suggest later recall.

The actual continuation introduces the same written Boolean-field example,
conversion directions, and value-equality explanation. Both add a sequenced
learning record with the learner's answer as evidence. Both distinguish this
conceptual recall from independent execution, a complete new summary task,
broader cases, or retention after a delay. They promote justified course terms
and leave application work, mission, tracker, and publication state unchanged.

There are real output differences. Lesson wording, example field names, recall
blanks, reference/record filenames, and promoted vocabulary differ. Direct adds
an explicit Round trip term; wrapped records that idea in LR-0002. Direct also
annotates LR-0001 as superseded because its initial JSON floor changed, while
preserving the exact original title and paragraph. Wrapped leaves LR-0001 intact
and links it as historical prior experience. Both establish the same bounded new
floor and retain history. The source's supersession rule permits the direct
annotation. This is method and learning-evidence alignment, not identical text,
identical glossary membership, or proof of long-term teaching results.

## Browser and artifact checks

A headless browser loaded both actual lessons and tested all four radio choices
across their two quizzes. Correct and incorrect selections produced the expected
immediate feedback. Choice labels have equal word counts and equal character
counts within each quiz. There were no page script errors or broken relative
file targets. Existing course.css and quiz.js are loaded; no inline duplicate
quiz logic or extra assets were introduced. Each quiz's correct answer matches
its prompt. Both authors' Python-example checks passed in their actual traces.

Desktop screenshots were inspected: the typography, code blocks, navigation,
and quizzes are readable with no visible overlap. Both 390px mobile views have
scroll width 390px, and full-page images are retained. This is a bounded rendering
check, not owner visual acceptance, print-output proof, or proof of every viewport.
The first bundled Playwright launch failed because its expected Chromium binary
was absent. The recorded retry used already installed Microsoft Edge headlessly;
no browser download or host change was made.

## Source, copy installation, and discovery

- Independent acquisition confirms six approved source Git blobs and the former
  five files' equality. The full source verifier passed for all 22 imports.
- All six production CI scripts passed: PowerShell 5.1 parse, ASCII/BOM,
  metadata/frontmatter, version, install-line, and dead-reference checks.
- Both offline Claude plugin validators passed. Claude model runtime remains
  deferred until the owner reports that Claude works.
- skills CLI 1.7.1 normal copy installs passed for Codex, Claude Code, and
  OpenCode. Both physical installed trees match all candidate file hashes.
  Runtime fixtures separately include agentic-workflow; the CLI does not prove
  that installing teach alone installs its required dependency.
- Fresh Codex skills/list exposes one enabled public fixture teach entry with
  original Teach metadata. Its implicit model catalog omits user-only teach.
  The separate eligibility run confirms the public rule's stop behavior; this
  is not a native slash-menu UI test or unrestricted autonomous selection test.
- Isolated OpenCode 1.18.35 discovery finds one public wrapper. OpenCode model
  runtime for this skill was not run. The host may require its local invocation
  restriction even when discovery ignores frontmatter.
- A real core.autocrlf=true Git checkout preserves all six raw source files.
  No raw SKILL.md, symlink, runtime extraction, or installed-plugin edit is used.

All eight turns exited 0. Initial shell helper failures were retried under the
same scoped fixture rule and remain in the traces. No model turn was excluded,
rerun, or changed. Shell receipts by turn are below. Elapsed times do not support
a token or performance comparison.

| Case/turn | Exit | Successful commands | Failed commands | Seconds |
| --- | --- | --- | --- | --- |
| direct round1 | 0 | 4 | 1 | 161.213 |
| direct round2 | 0 | 3 | 1 | 106.969 |
| wrapped round1 | 0 | 6 | 6 | 184.14 |
| wrapped round2 | 0 | 4 | 4 | 113.097 |
| mission-direct round1 | 0 | 3 | 5 | 66.736 |
| mission-wrapped round1 | 0 | 3 | 2 | 64.503 |
| automatic round1 | 0 | 1 | 1 | 29.479 |
| missing-dependency round1 | 0 | 2 | 2 | 42.094 |

The initial artifact verifier failed because it required Course/CONTEXT.md to
be the only modified existing file. That check overlooked the source-permitted
LR-0001 supersession. The failed verifier is retained as verify-initial.py with
its reason. The corrected verifier permits only the exact old record's title and
paragraph to be retained with a justified LR-0002 supersession annotation. Other
existing files must match their recorded hashes. It passed all eight actual
turns. This repairs a test assumption; it changes neither source nor wrapper.

All packages, application domain docs, source notes, prior lesson/reference
files, reused assets, mission, project ticket, Git HEADs, and branches remain
unchanged. Four pause/guard cases change no files. Main runs add only local
lesson/reference/learning artifacts and justified course vocabulary/history.
No live P4 action, application implementation, tracker closure, publication,
consumer update, or visible app launch occurred. Both pairs share the same local
project authority rules; this does not prove that the wrapper alone caused those
boundaries.

## Evidence and acceptance

Disposable evidence is under %TEMP%/myst-teach-migration-20261009. Each case has
before.json, its workspace, and prompt/trace/stderr/run receipts. Main cases also
have after-round-1.json and the actual second-turn receipts. run.py resumes the
first thread ID. verify.py checks source/package identity, matching paired inputs,
loading receipts, sequenced artifacts, demonstrated learning, preserved history,
selected vocabulary, guards, and protected VCS/project state. Its final
alignment-checks.json passed. Browser outputs/screenshots, initial failures,
package/copy/checkout receipts, discovery, and source comparison are adjacent.
Temporary files may expire; this report retains the assessed scope and limits.

Delayed retention, arbitrary subjects, sparse/untrusted resource search, mission
change confirmation, wisdom/community recommendations, competing vendors, native
slash UI, live P4, later application work, OpenCode model execution, and Claude
model runtime remain untested. Print styling is present but physical printing was
not checked. Source equality does not prove identical future lesson results.

Independent Standards and Spec reviews assessed this same working-tree scope
against 8a5f222, including complete added files and relocated companions. Owner
verification was pending for teach at review time. The earlier conditional approval verified
grilling 51a07f5 after its artifact recheck; it does not close this new gate.

## Standards review

Independent verdict: GREEN. BLOCKING: 0. WARNING: 0. Fowler findings: 0.

All 20 pinned actions, complete added files, and four deleted base blobs were
reviewed. File hashes, HEAD, the empty commit list, and saved diff matched before
and after review. All six raw files match independently acquired approved source;
the former five source files remain intact.

The wrapper follows CONTRIBUTING and ADR-0008/0009. It maps companion links,
retains user-only reach, and adds only workspace, vocabulary, dependency, and
authority routing. The required source boundary overrides the Middle Man
heuristic. No documented-standard breach or actionable heuristic was found.

The eight original turns, actual artifacts, package copies, discovery receipts,
and screenshots support this report. Output differences, source-permitted
LR-0001 supersession, the corrected verifier assumption, the Edge retry, test
limits, and pending owner gate are disclosed. The reviewer made no file changes
or new model runs.

Standards summary: GREEN; worst severity: none.

## Spec review

Independent verdict: GREEN. BLOCKING: 0. WARNING: 0.

No actionable missing or partial requirement was found. All six pinned source
files match independent blobs. The four former root companions survive unchanged
under references/upstream. Original metadata, user-only reach, credits, dependency
declaration, and back-link mapping are preserved. No scope creep or incorrect
implementation was established; the source method is not rewritten or optimized.

Successful receipts return the complete method and all four companions. Paired
prompts and other inputs match. Actual sessions demonstrate mission pause,
lesson/reference creation, asset reuse, feedback, and learning records after a
learner demonstration. Each continuation retains its original thread ID.

The disclosed output differences fit the method. Direct's prior-record annotation
preserves history under the source supersession rule. Both retain the original
text and bound their learning claim. Actual hashes confirm protected files,
tickets, HEADs, and branches remain unchanged. Guards stop before raw method
loading and make no writes. Browser receipts and saved images support the
reported artifact behavior.

All 20 pinned actions, current hashes, deleted base blobs, and saved diff matched
at the final check. Owner verification was pending at review time, along with the stated
runtime and teaching limits.

Spec summary: GREEN; worst severity: none.

## Owner verification

The owner authorized verification if alignment passed, then the next skill.
On 2026-10-09, verify.py rechecked all eight saved turns against committed
package 6dc2168. Source and package identity, equal paired inputs, actual
continued sessions, mission pause, lesson/reference authoring, demonstrated
learning, retained history, scoped vocabulary, guards, and protected state still
pass. Saved browser receipts also passed. This was an artifact recheck, not a
new model run. Both review axes were GREEN. Teach is verified OK for this scope;
the stated runtime and learning limits remain.
