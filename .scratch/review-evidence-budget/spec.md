# Evidence before blocker repairs and bounded review

Status: active; triaged from the agreed handoff, local implementation authorized
Owner: local review-and-submit skill

## Scope and contract

The 2026-10-18 handoff authorizes local implementation and tests for one skill
changeset. Keep every upstream file, source record, pin, hash, and method intact.
Keep Standards and Spec separate. Security expansion, publication, consumer
updates, and changes to human approval are outside scope.

Before a blocker drives an edit, require the artifact/revision, trigger or
violated contract, failure path, and consequence. Accept observed command output
or a checkable source trace. Static evidence need not have a runnable reproduction.
An unsupported blocker goes back to its reviewer for evidence or reassessment.
It remains BLOCKING until that reviewer's new verdict clears it.

Default to three automatic rounds per changeset, including the initial review.
Parallel axes in one cycle count once. Later affected-axis cycles each count once,
including evidence requests. Keep the count across session and branch changes.
Stop earlier under existing escalation rules or when a round has no blockers.
At the limit, present unresolved findings and request a human approach decision
or a bounded continuation. Exhaustion does not clear findings or permit publication.

## Tracker and verification

This spec owns the scoped Markdown tracker in issues/. Use the agentic-workflow
ticket states. One ticket covers policy, fixtures, tests, and evidence together.
There is no separate project glossary for this scope. Existing review terms apply.

The user-approved test seams are observable reviewer findings, blocker-driven
edit decisions, affected-axis dispatch, round counts, and publication decisions.
Use real defective and clean fixture APIs, harmful-fix controls, supported and
unsupported blocker inputs, and boundary cases. Do not assert instruction wording.
Use fresh independent agents for forward probes. Keep model outputs separate
from test oracles. Deterministic checks prove the fixture/scorer, not model behavior;
bounded model probes prove neither broad recall nor false-positive rates.

On 2026-10-19, the user authorized the demonstrated positive acceptance control:
the CLI must accept a separate literal valid receipt, and the same test must fail
against a disposable scorer that rejects every result. Apply this within the same
changeset, run all tests, and review again. Keep it local. This is the already
agreed CLI decision seam; it does not add a model or publication test.

The user then authorized a duplicate-only rejection control and an audit for
fragile references. Use the complete valid receipt plus one duplicate selected by
case ID, and verify its specific error and CLI failure. Durable findings use the
affected file, symbol or heading, and pinned revision; numeric line positions are
only temporary UI navigation data. Keep historical captures intact. Do not add
tests of Markdown line positions or exact instruction wording.

Normal document/comment links refer to the live file and symbol or heading, without
revision stamps. Only review evidence needs revision/hash pins. Store a shared
input pin once in its review record; findings refer to that pinned input. Editing
a document does not require changing every reference. Refresh pins for new review
input and preserve old evidence. Update live links only for changed targets or
claims whose meaning changed.

## Completion

Show the concrete diff, actual test results, source-integrity evidence, and limits.
Keep this changeset local for user review. No push, PR, merge, tag, release, or
consumer update is authorized. Maintained evidence belongs in docs/; this tracker
records state and links to that evidence. The old migration tracker is history.
