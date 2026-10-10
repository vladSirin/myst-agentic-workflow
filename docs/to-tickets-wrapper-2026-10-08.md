# To-tickets source and wrapper migration - 2026-10-08

Status: implemented, tested, independently reviewed, and owner-verified for
5b7079d after the alignment recheck on 2026-10-08.
Review base: 02d444f. The owner verified to-spec and requested the next skill.
Only to-tickets migrates in this changeset.

## Source and local comparison

Complete historical and approved subtrees were fetched independently from
Matt Pocock's repository. Pins: 0ab1b63a410a03d3627979a109c8695de27af954
and 6fd947921b935b7e1e69293a200400f0fdd5c15f. Each has SKILL.md and
agents/openai.yaml. Metadata is unchanged. The source update distinguishes
native blocking links from parent sub-issue links: each ticket from an existing
issue becomes its sub-issue. Issue bodies omit Blocked by when native edges
are set. All other source instructions remain intact.

UPSTREAM.json lists complete original names and hashes. Both files are preserved
byte-for-byte under references/upstream, with only SKILL.md renamed UPSTREAM.md
per ADR-0009. PROVENANCE.md carries the upstream root MIT notice.

The former Myst entry changed two setup references inline. Those mappings now
belong to the local wrapper and agentic-workflow's shared contract. Project
pointers govern tracker, triage, glossary, locations, state, and authority.
The wrapper lists and checks its required agentic-workflow dependency. The
upstream slicing, approval, wide-refactor method, and templates are unchanged.
Public frontmatter is unchanged. Added public Codex metadata matches upstream
and disables implicit invocation. No changes to other skill methods are included.

## Package checks

- All 26 source-verifier acceptance tests passed. Independent source verification
  passed: seven imported bundles, 18 declared pending imports, four local skills.
- All six existing CI script gates passed, including Windows PowerShell 5.1
  parsing, ASCII/BOM, public frontmatter, manifest versions, install commands,
  and dead references. Both offline Claude manifest validations passed.
- skills CLI 1.7.1 copy installation for Codex, Claude Code, and OpenCode passed.
  Both resulting package trees matched the repository file hashes exactly.
- A disposable Git index with core.autocrlf=true checkout preserved raw bytes.
- Fresh Codex skills/list found the public wrapper. The implicit prompt catalog
  omitted to-tickets. This checks discovery and metadata, not native slash UI.
- OpenCode debug skill discovery passed with an isolated profile. As established
  in the packaging pilot, user-only routing requires host permission configuration;
  the fixture uses that setting. The package does not install host configuration.
  No new OpenCode model test ran. Claude runtime remains explicitly deferred.

## Runtime fixtures and actual results

Six fresh Codex CLI 0.162.0-alpha.2 sessions used the configured model. Test data
were synthetic and disposable. Direct calls installed the complete two original
source files. Wrapped calls installed the Myst package. Each pair had identical
prompts and baseline files except the to-tickets package; shared project docs
and agentic-workflow stayed constant. This isolates the wrapper's effect.

The approved plan covers booking with full-capacity rejection, cancellation
that restores capacity exactly once, and availability queries without mutation.
Each slice includes public API, in-memory state, and public behavior tests.
The owner in the synthetic prompt approved three tickets and exact blockers:
1 has none; 2 and 3 depend only on 1. Project state is queued. Explicit pointers
select a custom tracker doc and a domain doc linking legacy CONTEXT.md.

| Case | Seconds | Observed outcome |
| --- | ---: | --- |
| approved-wrapped | 90.47 | Three local ticket files; correct blockers and queued state. |
| approved-direct | 96.559 | Same three-ticket behavior, blockers and state. |
| unapproved-wrapped | 78.057 | Proposes slices and asks approval; no writes. |
| missing-wrapped | 57.237 | Reports missing tracker doc and asks for configuration; no writes. |
| native-wrapped | 92.134 | Three mock issues, two native blockers, three parent links. |
| native-direct | 121.241 | Same issue graph and state as wrapped. |

All six exited successfully. File hashes and Git HEAD checks show no baseline
changes except the expected mock tracker state; parent plan and parent issue
fields remain unchanged. Approved local cases add only three ticket files.
Native cases add three drafts and update only tracker.json. Guard cases have
no file changes. Traces show the wrapped runs load the shared contract and raw
source. No implementation, test code, commits, or external publication occurred.
The host sandbox helper sometimes failed before process startup; sessions used
the permitted retry path without changing skill source or global permissions.
Two combined read/search commands ended nonzero because .scratch did not yet
exist. Their output contains the complete contract and source; the later reads
and ticket checks completed. These search errors are not source-loading failures.

Both local ticket sets were read and compared. They cover successful booking,
full-capacity rejection without mutation, exactly-once cancellation, and read-only
availability, with API/state/test acceptance criteria and all agreed exclusions.
The wrapper adds Parent: plan.md lines; direct output omits that optional local
addition. Wording differs, but scope, blockers, file count and state align.

Both native issue sets were read and compared. They preserve that scope and
project state, use native blocker edges T-2 -> T-1 and T-3 -> T-1, and link all
three tickets under SPEC-7. Bodies retain Parent and omit duplicate Blocked by
sections. The wrapper creates all issues before links; direct interleaves issue
creation and links. Both create blockers before dependents. Draft names and prose
differ. Direct cancellation explicitly mentions preserving other bookings; wrapped
and direct both include reuse of restored capacity. These are compatible test
details, not identical text or a proof of equal coverage on larger plans.

The unapproved run proposes availability as independent and requests confirmation;
this does not alter the approved-pair graph. That case had no approved breakdown.
We did not compare autonomous breakdown choices with a direct call. The pairs
prove execution of an agreed breakdown, not identical planning judgment.
Native relationship checks use a local mock with real returned mock identifiers;
they do not establish live GitHub/Linear API compatibility or publication approval.
Wide refactors, native slash UI, and live remote publication were not tested here.

## Evidence and review

Evidence root (local disposable artifacts):
C:/Users/Shado/AppData/Local/Temp/myst-to-tickets-migration-20261008

Source comparisons, fixture prompts, initial hashes, traces, generated tickets,
mock state, discovery snapshots, copy/install logs, and checkout evidence remain
there. verification.json records output hashes and allowed changes; package-checks.json
records package checks. Trace SHA-256:

- approved-wrapped: `e7339bce018098ce81325cfe7d23ec9e8e28fd521411822c743beca3c536cb01`
- approved-direct: `9f1ca5ea47b7c4de1781725ac980df305713b2b2bd99739f99de2a705b168377`
- unapproved-wrapped: `f7bafa90ac72e21bfc9cdb494878678c1d8b46b0a8a2781a31e20bcc8f9ce465`
- missing-wrapped: `703246a2bd83a0bc9b1b6ef1c89c7c13f0ade58fe3d9dcbed7b79beaec221952`
- native-wrapped: `15f6efd2035e2ce26560c881719d1684015d3d3510b90e1ffe6b7008d1136613`
- native-direct: `1013a40a488bf100ba98bfb3b63098f646536f7180377de7a7d06fa679a478a2`

## Standards

GREEN - zero actionable findings. The reviewer confirmed the source/local
boundary, attribution, user-only metadata, project authority, concise wrapper,
and evidence limits. No baseline smell warrants a change.

## Spec

GREEN - zero actionable findings. The reviewer read both local ticket sets and
native tracker graphs. Scope, queued state, approved blockers, and parent links
align. Source inventory, metadata, license, guard behavior, hashes, and unchanged
Git HEADs match the requirements and report.

Review summary: Standards 0 findings; Spec 0 findings. No worst issue on either
axis. The complete staged git diff --check passed. Owner verification is recorded below.
No push, PR, merge, release, consumer migration, or Claude model test is included.


## Alignment recheck and owner verification

The owner instructed: "Do alignement test, if ok consider it verified."
The actual local ticket sets and native mock issue bodies were read again and
compared against the agreed plan. Scope, acceptance behavior, queued state,
blockers, and parent links align. Wording, optional local parent references,
and native operation order differ as already disclosed above.

The recheck confirms the committed package 5b7079d equals the tested wrappers,
and direct entries match the pinned source inventory. Paired prompts and project
inputs match. All six trace hashes, output hashes, changed-file inventories,
and fixture Git HEADs match the recorded evidence. Guard cases remain unchanged.
The saved alignment-recheck.json records these checks. This was a revalidation
of the existing direct/wrapped executions, with zero new model calls.

Result: PASS within the documented scope. Under the owner's conditional approval,
5b7079d is owner-verified. Live tracker integration and autonomous decomposition
alignment are not proved by these fixtures. Claude runtime remains deferred.
