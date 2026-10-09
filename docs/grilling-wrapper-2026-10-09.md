# Grilling source and wrapper - 2026-10-09

Status: implementation and alignment checks passed; both independent reviews
GREEN. Owner verification pending.
Review base: 430bf23. This changeset migrates grilling alone.

The former Myst entry exactly matches the approved Matt source pin. There is no
method delta. Both source files stay whole under references/upstream; SKILL.md
alone maps to UPSTREAM.md under ADR-0009. Public metadata matches the source;
model and user reach stay enabled. The local entry loads the shared contract,
maps project context and fact-helper scope, and keeps subsequent implementation,
tracker, and publication actions within project and user authority. Actual
source and behavior evidence is below. The source pin is
6fd947921b935b7e1e69293a200400f0fdd5c15f, subtree skills/productivity/grilling.
UPSTREAM.json records both source hashes. Remove only grilling's pending waiver;
the census is now 21 verified imports, 5 pending imports, and 5 local skills.

## Stateful interview alignment

Two fresh Codex sessions used the normal configured CLI, 0.162.0-alpha.2, in
disposable synthetic workspaces. The direct case used both original source
files; the wrapped case used the exact candidate package. Each session then
continued twice through exec resume, for six turns in total. Thread IDs stay
identical within each case across all three turns. The three prompts match
between cases, as do all project files and dependencies outside grilling.
There was no model override, credential copy, or host configuration change.
This compares entries within the same local project and host context, not a
wholly upstream stack without Myst project rules.

The policy tree was bounded to two independent roots and two conditional
branches. Custodian authority and protection of Linked Previews were already
settled. Storage, UI, audit design, and other implementation details were outside
the interview. This scope lets the test distinguish ready questions from later
ones without claiming full design coverage for a real product.

| Turn | Direct and wrapped observations | Result |
| --- | --- | --- |
| First frontier | Each delegated a code fact check, asked retain/purge and manual/automatic expiry, recommended Archive/manual action, and waited | Aligned |
| Root answers | Both resumed the same session, kept Archive/manual answers settled, asked only recovery-window and purge-confirmation branches, recommended indefinite recovery/explicit confirmation, and waited | Aligned |
| Branch answers | Both resumed again, summarized the same four decisions and role/Linked Preview constraints, found an empty frontier, and asked for shared understanding before action | Aligned |

The actual first-round traces show the selected entry and method loading. The
wrapped trace also shows the shared contract and original source being read.
Each parent dispatches one actual fact-finding child. Dispatch receipts, child
session identity, successful local code reads, and returned findings were checked.
Both establish in-memory Archive/Restore behavior and avoid claiming durable
recovery from those functions. No app code or tests were executed to invent proof.

The continued turns use their actual interview history. The root answers unblock
the two branches; neither session re-asks the settled roots or asks timer details
for the unselected automatic-expiry path. Once branch answers settle the bounded
tree, both summarize Archive, manual Custodian action, indefinite recovery until
manual Purge, and target-specific confirmation of permanent removal. Cancel keeps
the record. Linked Previews stay untouched. They request shared understanding
and keep implementation pending.

Wording, layout, evidence detail, and option lists vary. For purge confirmation,
direct offers three choices including a generic confirmation; wrapped contrasts
the request alone with separate explicit confirmation. Both recommend the same
target-specific confirmation of permanent loss. These are observed output
differences within the unchanged method, not exact answer equivalence or proof
of every future interview result.

All fixture files, installed packages, tickets, domain docs, Git HEADs, and
branches remain unchanged. The target remains Perforce despite its Git fixture
mirror. No implementation, new docs, live P4 action, tracker closure, or publication
occurred. Both cases also have the same read-only project restriction; the test
does not establish that the wrapper alone caused their authority behavior.

## Source, copy installation, and discovery

- The full source verifier passed against independently acquired pinned sources.
  Both raw files and the former Myst entry match approved Git blobs.
- All six production CI scripts passed: PowerShell 5.1 parse, ASCII/BOM,
  metadata/frontmatter, version, install-line, and dead-reference checks.
- Both offline Claude plugin validators passed. Claude model runtime stays
  deferred until the owner reports that Claude works.
- skills CLI 1.7.1 copy installs passed for Codex, Claude Code, and OpenCode.
  Both physical installed trees match every candidate file hash. Method fixtures
  separately include agentic-workflow; a partial dependency copy is not proven
  usable by installing the grilling directory alone.
- Fresh Codex skills/list exposes one enabled public fixture entry with the
  original display metadata. The implicit catalog contains its model-facing
  stress-test/plan/decision/grill trigger. Model and user reach are preserved;
  this proves discovery, not an automatic model selection or slash-menu UI test.
- Isolated OpenCode 1.18.35 discovery finds the public wrapper once. No raw
  SKILL.md, symlink, runtime extraction, or host plugin change was introduced.
- A real core.autocrlf=true Git checkout preserves both raw source files.
- Existing alias entries are unchanged and still point to the same Myst grilling
  entry. Their new composition was not run as a separate model case here.

All six turns exited 0. Initial parent shell startup failures were retried under
the fixture's stated read-only retry rule; no turn was excluded. The continued
turns needed no shell commands. Initial failures remain in the traces. Elapsed
times do not support a token or performance comparison.

## Evidence and acceptance

Disposable evidence is under %TEMP%/myst-grilling-migration-20261009. Each case
contains before.json, its unchanged workspace, and round-1 through round-3 prompt,
trace, stderr, and result files. run.py uses the recorded first-round thread ID
for each continuation. verify.py independently checks exact package identity,
matching prompts/other inputs, preserved history, actual frontier progression,
confirmation, protected state, dispatch, and child read receipts. Its final
alignment-checks.json passed. Source, copy, package, checkout, Codex, OpenCode,
and implicit-catalog receipts are adjacent. Temporary evidence may expire; this
report retains the assessed scope, results, and limits.

Unbounded or asynchronous frontier scheduling, user disagreement, post-confirmation
implementation, current alias composition, competing vendors, automatic model
selection, native slash UI, live P4, OpenCode model execution, and Claude model
runtime remain untested. The source method stays intact for those paths.

Standards and Spec reviews assessed the same working-tree scope against
430bf23, including complete added files. Owner verification remains pending for
this grilling changeset. The earlier conditional approval verified grill-me
1d481a5 after its alignment artifact recheck; it does not close this new gate.

## Standards review

Independent verdict: GREEN. BLOCKING: 0. WARNING: 0. Fowler findings: 0.

All 12 pinned actions, complete added files, saved diff, and file hashes matched
before and after review. HEAD matched base 430bf23; no commits were excluded.
The reviewer checked CONTRIBUTING, ADR-0008, ADR-0009, source records, dependency
and authority rules, metadata, catalog placement, and the actual six-turn traces.
Both source files and the former entry match approved Git blobs. The local entry
loads the shared contract before the intact method. Model and user reach remain
enabled. The required thin wrapper takes precedence over the Middle Man heuristic.
No speculative orchestration or premature optimization was added.

Actual parent/child receipts establish code fact-finding. Equal paired inputs,
continued session IDs, frontier progression, waits, confirmation, and unchanged
fixture state support the reported result. The option-list difference and test
limits are recorded. The reviewer made no edits or new model runs.

Standards summary: GREEN; worst severity: none.

## Spec review

Independent verdict: GREEN. BLOCKING: 0. WARNING: 0.

All 12 pinned action hashes and the saved diff matched before and after review.
No missing or partial requirements, scope creep, or incorrect implementation
were found. Complete source, companions, original metadata, attribution, copy
dependency, filename mapping, scoped attributes, waiver removal, and catalog
updates meet the plan. Existing alias entries remain unchanged.

The actual artifacts confirm two sessions, each resumed twice with the same
thread ID. All three prompt pairs and other inputs match. Both sessions ask the
root questions, then only the ready branches, then request shared understanding
when the bounded frontier is empty. Parent dispatch, child identity, successful
code reads, and actual source/contract loading support the fact-finding claim.
Every fixture file, package, ticket, HEAD, and branch remains unchanged.

This meets the plan's source integrity, complete companion, loading, behavior,
and attribution requirements. The test limits above remain open. Owner
verification remains pending.

Spec summary: GREEN; worst severity: none.
