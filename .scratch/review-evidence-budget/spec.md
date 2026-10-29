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

## VCS-specific loading follow-up

On 2026-10-20, the user authorized explicit Perforce-only rules and conditional
loading of Git/Perforce details in PR #109. This scoped follow-up covers the
shared review protocol, its VCS mechanics, the local code-review input mapping,
and the shared integration pointer. It is an explicit extension of this PR's
normal one-skill scope; public triggers and invocation policies stay unchanged.

Resolve the target VCS before loading its local details. Git work reads only
the Git mechanics/input reference and selects pr; Perforce work reads only the
Perforce mechanics/input reference and selects p4-description. An unclear target
does not load either detail branch or invoke a formatter. Preserve the explicit
project's VCS when a nested mirror or another installed VCS is present.

Keep shared evidence, review-round, finding-clearance, and publication rules in
their existing owners. Mark remaining Perforce-only rules explicitly. Preserve
the complete selected upstream source, source records, pins, hashes, and review
method. Archived upstream text can retain its original Git wording; the local
mapping selects its meaning for the target rather than rewriting that source.

Run the full existing tests, CI gates, plugin validators, and source verification.
Check reference targets and review both VCS paths without tests of exact Markdown
wording or line positions. Review the scoped delta on both axes and keep the
existing round ledger. Update PR #109 only; keep it unmerged and do not tag or
release. Local plugin refresh is outside this follow-up's requested actions.

## Completion

Show the concrete diff, actual test results, source-integrity evidence, and limits.
The later user instructions authorized the local commit, PR #109, and local
installation. The user then released v5.5.0 from main while keeping PR #109 out.
On 2026-10-20, the user authorized bumping PR #109 to a 5.6.0 preview, running all
tests, updating the PR, and refreshing the local install. Keep both manifests at
5.6.0 and its notes Unreleased. Keep the PR unmerged; no 5.6 tag or release is
authorized. This preview is an explicit exception to the normal tag-on-bump rule.
Keep policy/test behavior and all upstream content unchanged in this version step.
Maintained evidence belongs in docs/; this tracker records state and links to
that evidence. The old migration tracker is history.

## Release finalization - 2026-10-29

After reporting "5.6.0 on this PC works pretty well", the owner approved the
proposal to finalize release notes/status wording, review that small change,
merge PR #109, verify main CI, and tag v5.6.0 from the exact merged commit.
This release authorization supersedes the earlier preview-only publication
limits for this release step; preserve those earlier records as history.

Keep both plugin manifests at 5.6.0. Change release documentation and its existing
review/tracker records only. Keep all installed skill content, tests, upstream
files, source records, source pins, and source policy unchanged. Record the owner
report verbatim and limit it to this PC; do not claim live Perforce or wider-host
acceptance from offline fixtures. Use live release links for publication state.
Do not claim a merge, CI pass, tag, or release before its observed result.

Continue the existing review ledger with one scoped review cycle, round 11.
Run Standards and Spec on the same pinned documentation delta and run the
independent docs-alignment preflight. Preserve earlier reports and dispositions.
After the approved merge and passing main CI, use the existing tag-triggered
release workflow. Refresh the local package through the configured native
marketplace route and verify that its skill bytes still match the released tree.
