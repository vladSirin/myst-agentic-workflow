# To-questionnaire source and wrapper - 2026-10-09

Status: implementation and alignment checks passed; both independent reviews
GREEN. Owner verification pending.
Review base: 6f36b30. This changeset migrates to-questionnaire alone.

The former Myst entry exactly matches the approved Matt source. There is no
method delta. Both source files stay byte-for-byte intact under references/upstream;
only SKILL.md maps to UPSTREAM.md under ADR-0009. Previously omitted Codex
metadata is included, with original user-only reach. The local entry resolves the
target project, draft destination, copy dependency, and later work authority.
The send interview, knowledge-gap questions, ordering, and document format remain
owned by the complete source. UPSTREAM.json records approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f, subtree skills/productivity/to-questionnaire,
and both source hashes. The census is 23 verified imports, 3 pending, 5 local.

## Stateful send-interview alignment

Six fresh Codex sessions used the normal configured CLI, codex-cli 0.162.0-alpha.2. The main
pair each resumed twice via exec resume, for ten turns across all six cases.
The actual first-round thread ID stays unchanged through each three-turn main
interview. Every main prompt and the fallback prompt match across their pairs.
All project files and dependencies outside to-questionnaire match as well.
Direct uses both original source files; wrapped uses the exact candidate package.
No model override, credential copy, or host configuration change was made.

The synthetic project is a Perforce target with a Git inventory mirror. Its
instructions select Work/questionnaires as the main draft destination and
Project/CONTEXT.md as vocabulary. The established term is Event Bundle. Alex
needs the ingestion-service contract; Rowan is its fictional data-platform owner
and a peer in another team. None of the service facts are supplied. The project
ticket remains in progress and application implementation is not authorized.

| Case/turn | Actual direct and wrapped observations | Result |
| --- | --- | --- |
| First exchange | Load method/context; ask the recipient's role, expertise, and relationship; no subject interrogation, assumed facts, or draft | Aligned |
| Recipient answer | Resume actual interview; accept Rowan's role/context; ask what facts or decisions Alex needs back; no draft yet | Aligned |
| Knowledge-gap answer | Resume again; author one local discovery questionnaire covering all eight gaps in priority order; report the path and stop | Aligned |
| Current-directory fallback | With send details and three gaps already settled and no project destination, author the normal root filename with three separate questions | Aligned |
| Automatic eligibility | Explain user-only rule from public entry; stop without raw method loading or writes | Passed guard |
| Missing dependency | Identify absent agentic-workflow entry and contract; stop before method or draft | Passed guard |

Actual successful receipts show the public entry, complete method, project
instructions, vocabulary, and ticket being read. Wrapped also reads the shared
contract. This is evidence of method loading and actual artifact content,
not only paths named in an answer. Both interview snapshots show every fixture
file unchanged after the first and second exchanges.

Each main pair produces Work/questionnaires/to-questionnaire-event-bundle-ingestion.md.
The drafts contain the source's Purpose, From, To, answer-use, Context, How to
answer, theme sections, and Anything else catch-all. The context explains the
service-contract gap for a peer who has not seen the ticket. Both include the
16 October 2026 deadline, 15-minute estimate, partial-answer and uncertainty
instructions, and blank answer stubs directly below each question.

Both main documents ask these eight ideas in the specified priority order:

1. Whether a caller idempotency key is required to prevent duplicate processing.
2. Which side owns failed-delivery retries.
3. The largest permitted payload in bytes.
4. Peak accepted request rate per second.
5. Minimum retention in days.
6. Incident escalation contact.
7. Support hours.
8. The timezone for those hours.

They group questions into delivery behavior, service limits/retention, and
incident support. Each question asks one idea; hours and timezone are separate.
No unknown service answer is filled in. Drafting does not answer the subject
for Alex, send to Rowan, close the ticket, or establish implementation readiness.

The no-convention pair writes to-questionnaire-event-bundle-support-handoff.md
at the workspace root. Both include the three separate support questions,
five-minute effort, deadline, source template, and blank answer spaces. Already
settled send details satisfy the source's interview completion conditions; neither
asks them again. Only one requested draft is added per authoring case. All local
Markdown links in the actual drafts resolve, including the main ticket link.

There are output differences. Wrapped numbers its main question headings; direct
does not. Both keep exactly the same priority and meaning. Purpose, context,
catch-all wording, header detail, and optional why-this-matters text vary. Direct
identifies Rowan's role in the main To field; wrapped supplies it in Context.
Fallback context also differs. This is process, question-coverage, format, and
path alignment; it does not claim identical text or every future questionnaire.

## Source, copy installation, and discovery

- Independently acquired approved Git blobs match both full source files and
  the former Myst entry. The complete source verifier passed for all 23 imports.
- All six production CI scripts passed: PowerShell 5.1 parse, ASCII/BOM,
  metadata/frontmatter, version, install-line, and dead-reference checks.
- Both offline Claude plugin validators passed. Claude model runtime remains
  deferred until the owner reports that Claude works.
- skills CLI 1.7.1 normal copy installs passed for Codex, Claude Code, and
  OpenCode. Both physical installed trees match every candidate file hash.
  Runtime fixtures separately include agentic-workflow; installing this entry
  alone is not proof of automatic dependency installation.
- Fresh Codex skills/list exposes one enabled public fixture entry with original
  To Questionnaire metadata. The implicit model catalog omits the user-only
  entry. Its separate eligibility test honors that contract.
- Isolated OpenCode 1.18.35 discovery finds the public wrapper once. OpenCode
  model runtime for this skill was not run; discovery is not invocation proof.
- A real core.autocrlf=true Git checkout preserves both raw source files. No raw
  SKILL.md, symlink, runtime extraction, or installed-plugin edit was introduced.

All ten turns exited 0. Initial shell helper failures were retried under the
same scoped fixture rule and remain in the traces. No model turn was excluded,
changed, or rerun. Elapsed time does not support a token/performance comparison.

| Case/turn | Exit | Successful commands | Failed commands | Seconds |
| --- | --- | --- | --- | --- |
| direct round 1 | 0 | 1 | 3 | 41.367 |
| direct round 2 | 0 | 0 | 0 | 13.197 |
| direct round 3 | 0 | 2 | 1 | 57.179 |
| wrapped round 1 | 0 | 2 | 2 | 59.672 |
| wrapped round 2 | 0 | 0 | 0 | 14.75 |
| wrapped round 3 | 0 | 2 | 2 | 75.564 |
| fallback-direct round 1 | 0 | 3 | 3 | 71.22 |
| fallback-wrapped round 1 | 0 | 4 | 4 | 75.494 |
| automatic round 1 | 0 | 1 | 1 | 29.902 |
| missing-dependency round 1 | 0 | 2 | 2 | 39.972 |

The first independent artifact check failed because its text matcher counted
"timezone for those support hours" as both timezone and a second hours question.
Actual documents have two separate atomic questions. The failed verifier and
reason remain in evidence. The corrected classification assigns a timezone
heading to that gap, while retaining complete coverage, one question per gap,
priority order, and blank-stub checks. All ten unchanged turns pass the final
verifier. Source and wrapper were not edited to resolve a test-matcher error.

All existing fixture files, packages, domain docs, ticket, HEADs, and branches
remain unchanged. There are no staged changes. Authoring adds only one local
questionnaire per case; both interview pauses and both guards make no writes.
No recipient message, P4 action, implementation, tracker closure, publication,
consumer update, or host configuration change occurred. Paired cases share the
same local project/authority instructions; the tests do not prove the wrapper
alone caused those boundaries. Sending or real responses were not exercised.

## Evidence and acceptance

Disposable evidence is under %TEMP%/myst-to-questionnaire-migration-20261009.
Each case holds before.json, its actual workspace, and prompt/trace/stderr/run
files. Main pairs also retain after-round-1.json and after-round-2.json snapshots.
run.py resumes each first thread ID. verify.py checks exact source/package
identity, paired inputs, actual source loading, interview history, template/gap
coverage, atomicity/order, blank stubs, draft paths, guards, and protected state.
Its final alignment-checks.json passed. Source comparison, package/copy/checkout,
discovery, implicit-catalog, and draft-link receipts are adjacent. The initial
failed matcher is preserved as verify-initial.py with its reason. Temporary
artifacts may expire; this report retains assessed results, differences, and limits.

Arbitrary subject areas, incomplete or conflicting send details, explicit
user-destination overrides, conflicting project destinations, competing vendors,
actual recipient delivery or response, native slash UI, live P4, application
implementation, OpenCode model execution, and Claude runtime remain untested.
Source equality does not establish identical future results or response quality.

Independent Standards and Spec reviews assessed this same working-tree scope
against 6f36b30, including all complete added files. Owner verification remains
pending for this changeset. The earlier conditional approval verified teach
6dc2168 after its artifact recheck; it does not close this new gate.

## Standards review

Independent verdict: GREEN. BLOCKING: 0. WARNING: 0. Fowler findings: 0.

All 12 actions, complete added files, base/HEAD, empty commit list, file hashes,
and saved diff matched before and after review. No documented breach was found
against CONTRIBUTING, ADR-0008/0009, the plan, source verification, or writing
rules. The small wrapper owns project, destination, dependency, and later
authority rules. The method remains upstream. User-only metadata stays intact.
The required wrapper boundary overrides the possible Middle Man heuristic.

Both full raw files match independently acquired approved-pin Git blobs. The
former entry and copied MIT notice also match. Scoped attributes, source record,
waiver removal, catalog, and provenance fit the migration contract.

All ten original trace turns and four actual drafts support source loading,
both send exchanges, ordered atomic gaps, blank stubs, source format, project
and fallback destinations. Guards preserve state; paired inputs match. Existing
files, HEADs, branches, and staging stay unchanged. The retained timezone matcher
failure is correctly classified. No output change or model rerun resolved it.
The report states semantic alignment and limits accurately. Owner verification
remains pending; Claude runtime stays deferred.

Standards summary: GREEN; worst severity: none.

## Spec review

Independent verdict: GREEN. BLOCKING: 0. WARNING: 0.

All 12 review hashes, complete additions, base/HEAD, empty commit list, and
saved diff matched before and after review. No missing or partial requirement,
scope creep, or incorrect implementation was found. Both source files and the
former entry match approved Git blobs. Only the permitted root filename changes.
The wrapper adds agreed project, destination, dependency, and authority routing.

Each actual main interview resumes its original UUID twice. Both early snapshots
preserve every file. Successful outputs return the complete method. Four actual
drafts follow the source template, cover every requested gap, keep questions
atomic and ordered, and leave answers blank. Main/fallback paths fit project
rules. Guards stop before method loading. Copy hashes and discovery identify
the public wrapper.

The verifier correction resolves the overlapping timezone classification while
retaining complete coverage, unique question mapping, priority, and blank-stub
checks. Reported wording and context differences are accurate. The stated
untested paths and pending owner gate remain. The reviewer made no file edit
or fresh model run.

Spec summary: GREEN; worst severity: none.
