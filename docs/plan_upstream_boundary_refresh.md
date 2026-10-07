# Upstream Boundary and Skill Refresh Plan

**Version**: v2.0 | **Updated**: 2026-10-08
**Reference**: ADR-0002, ADR-0006, ADR-0007; upstream research notes below
**Status**: APPROVED for implementation, changeset by changeset. Publication remains separately gated.

**Accepted packaging amendment, 2026-10-08:** the owner authorized production
implementation after the disposable pilot. [ADR-0009](adr-0009-plain-upstream-references.md)
supersedes the ZIP default and permits only the root entry filename mapping.
Existing ZIP packages remain valid until their individual conversions. The
[pilot report](plain-source-pilot-2026-10-08.md)
records passing Codex runtime/install checks and OpenCode discovery/runtime,
with answer-quality limits recorded separately and Claude deferred.

## Change Log

| Ver | Date | Changes |
| --- | --- | --- |
| v1.0 | 2026-10-06 | Initial restoration and refresh plan, based on current source comparisons. |
| v1.1 | 2026-10-06 | Include upstream pr and a local P4 description skill; replace description writing only and preserve the separate Review Record. |
| v1.2 | 2026-10-06 | Include implement-spec adoption and a local Perforce implementation plan, with explicit treatment of parallel preparation and existing changeset gates. |
| v1.3 | 2026-10-06 | Supersede the P4 orchestration proposal: pr and implement-spec are Git-only; remove the P4 whole-spec skill and parallel-preparation policy changes. |
| v1.4 | 2026-10-07 | User approved retiring the standalone Review Record format; retain concise review evidence in Evidence and preserve review/publication rules. |
| v1.5 | 2026-10-07 | User approved a migration branch with per-skill reviews and one final release. Preserve upstream implement-spec and tdd behavior; defer extra orchestration rules until a pilot shows a concrete need. |
| v1.6 | 2026-10-07 | User accepted copy-install cleanup and approved implementation. Finalize the plan; start Changeset 0 and retain per-changeset verification and publication gates. |
| v1.7 | 2026-10-07 | Record visible-folder duplicate discovery and the .upstream trial. Codex passes, but repeated OpenCode scans can bypass the wrapper; packaging and further migration remain blocked. |
| v1.8 | 2026-10-07 | Resolve discovery collisions by storing the complete original subtree in a ZIP. Verify member bytes independently and read locally through the wrapper. Discovery fix passes; full host-runtime acceptance remains pending. |
| v1.9 | 2026-10-07 | Owner deferred outstanding Claude runtime tests until they explicitly report Claude works. These tests no longer block changeset acceptance or further migration; keep their results unverified. |
| Draft amendment | 2026-10-08 | Research plain reference-file packaging with a narrow filename exception. Proposal and disposable discovery check only; no production skill changes. |
| v2.0 | 2026-10-08 | Owner approved production implementation after Codex/OpenCode tests. Adopt ADR-0009, version 2 source records, and codebase-design as the first conversion. Retain per-skill gates. |

## Overview

Restore a strict file-ownership boundary: upstream-owned files remain unchanged
at a recorded source revision; Myst-owned wrappers hold local integration and
invocation behavior. Then refresh the currently adopted Matt Pocock and Hammer
skills without losing Myst's review, tracker, and publication behavior.

**Goal:** every shipped upstream file is independently comparable with its
source, and every local behavior has an explicit, tested entry point.

This is the approved plan for the devkit source repository. Implementation
proceeds through the changeset gates below. Consumer changes, installed plugin
updates, PRs, tags, and releases remain later actions with their own scope.

The refresh also adopts upstream pr for Git and a local p4-description skill
for Perforce. Retire the standalone Review Record format and place concise
review results under Evidence. The review process, handling of findings, and
publication authority remain in review-and-submit. This format decision is
approved; implementation is pending under this plan.
Both pr and implement-spec are Git-only and must not run in P4 environments.
There is no P4 whole-spec implementation skill or concurrency-policy change
in this plan.

## Evidence and scope

| Source | Verified baseline | Proposed target |
| --- | --- | --- |
| Myst | b3aeed04e0ea553af7b39f6d793e91f2ff676ff1, v5.4.0 | New reviewed revisions; select versions from actual migration impact. |
| Matt Pocock | Older set: 0ab1b63a410a03d3627979a109c8695de27af954; code-review: 6654f6b60cd9d5be8b54c6fafe44346dabeb3b76 | 6fd947921b935b7e1e69293a200400f0fdd5c15f, fetched on 2026-10-06. |
| Hammer | Two skills attributed to v0.19.0 | v0.30.0, verified through the live release API and static ZIP-member extraction. |

As checked on 2026-10-06, Matt's latest tag was v1.3.1; the proposed commit includes later changes on
main. Since the previous assessment's 2237a04 snapshot, the skill-tree change
is confined to experimental chief-of-staff. The adopted skill assessment still
applies. Pin the proposed commit for this work; advancing it again requires a
fresh delta review rather than silently chasing main.

Hammer's cached web page reported v0.24.0, but its live API returned v0.30.0.
Static extraction found the two existing advanced-capability skills. Their
bodies match the current Myst bodies after frontmatter removal and line-ending
normalization. Their original frontmatter differs from Myst's. Do not describe
this as a new capability or a body rewrite.

Current deviations to resolve:

- Seven inline reference changes across implement, tdd, to-spec, to-tickets,
  triage, and wayfinder. The historical ledger documents their purpose.
- Codex metadata was deliberately omitted from the older imports. Preserve it
  in the new raw source bundles regardless of whether the host uses it there.
- Hammer frontmatter is local, while its body is upstream-derived.

Changeset 0 corrects the README's blanket verbatim and provenance claims.
Source and runtime migration remain pending in the
[inventory](migration-upstream-boundary.md).

Sources: [Matt assessment](research-matt-pocock-updates-2026-10-06.md),
[Hammer assessment](research-hammer-update-2026-10-06.md),
[Matt target](https://github.com/mattpocock/skills/tree/6fd947921b935b7e1e69293a200400f0fdd5c15f),
[Hammer latest API](https://api.github.com/repos/dreamwords/hammer-releases/releases/latest),
[Hammer v0.30.0](https://github.com/dreamwords/hammer-releases/releases/tag/v0.30.0).

## Design Philosophy

### 1. Preserve source files, not only their main prose

Intact means the full upstream file: frontmatter, body, filenames, companion
files, and internal directory structure, with only ADR-0009's packaged root
SKILL.md to UPSTREAM.md exception. No English rewrites, footer injection,
reference remaps, or invocation flags inside the source copy. Preserve source
bytes through checkout with narrowly scoped Git attributes if required. Scope
that rule to imported files; do not renormalize the rest of the repository.

Import complete selected skill directories, not the entire upstream catalog.
Retain licenses and credits. Inspect relative links and cross-skill dependencies
before accepting a selected directory as complete.

### 2. Myst owns the execution contract

The public Myst entry point owns discovery metadata, local dependencies, tracker
selection, glossary compatibility, and VCS/publication rules. It explicitly
reads the preserved source as its method reference. It does not restate the
whole method or silently edit that reference.

Any changed behavior is identified as a local adaptation in the wrapper's
provenance. Byte-faithful source does not imply identical runtime behavior.
README must make that distinction clear.

### 3. Prove loading and routing

A companion file is not a wrapper merely because it exists. Every required
local rule must be reached through the actual entry point. Test direct use,
cross-skill calls, and name collisions. Source text alone does not prove those
paths work. Instruction text also does not create a security boundary; existing
tool permissions and human publication rules remain authoritative.

### 4. Keep verification small and specific

Add one repository-only source-integrity check. Do not restore the retired
installer, renderer, per-tool source trees, runtime hooks, or generated agents.
This is a narrow, explicit amendment to ADR-0007's decision to remove drift
checks, justified by the current ownership mismatch.

## Architecture

```text
User request or permitted model invocation
                 |
                 v
Registered Myst entry point (local SKILL.md + local metadata)
        |                        |
        v                        v
Pinned upstream method     Myst integration rules
(full unchanged files)     (routing, tracker, VCS, document paths)
                 |
                 v
Execution -> evidence -> existing review/publication protocol
```

Use the same public skill names where possible. Keep local-origin skills such
as agentic-workflow, review-and-submit, changelist-verification, and design
local; they do not need artificial upstream source folders.

### Earlier ZIP layout, retained for unconverted packages

The accepted [plain-reference layout](#recommended-layout-and-boundary) below
supersedes this default for reviewed conversions. This section preserves the
earlier discovery findings and explains the remaining ZIP packages.

```text
plugins/myst-dev-kit/skills/<public-name>/
  SKILL.md                     # Myst-owned entry point
  agents/openai.yaml           # Myst-owned host metadata, if required
  PROVENANCE.md                # ownership, adaptations, source-record pointer
  UPSTREAM.json                # authoritative source pin/path/file record
  LOCAL.md                     # only when local integration needs explanation
  upstream.zip                 # complete original subtree; archive members:
    SKILL.md                   # complete original, including frontmatter
    agents/openai.yaml         # original metadata, where supplied
    <all other source files>   # original names and relative layout
```

The source root is archived as a unit; member names, layout, and bytes stay
unchanged. Record that root mapping. Keep the full selected source inside the
public skill directory so a per-skill copy install can include its dependencies
on local files. An external sibling vendor directory would risk broken npx
copies and is not the default proposal.

**Layout gate:** nested SKILL.md discovery is not yet verified across all
supported hosts. The pilot must show that ordinary installation discovers one
public entry point, bundles the raw subtree, and does not register a second
unwrapped skill. Also test recursive discovery modes and report their behavior.
If a supported default install exposes duplicate entries, reject this layout
before migrating more skills. Resolve packaging explicitly; do not fix it by
editing upstream metadata or by silently dropping an install channel.

The [handoff pilot](handoff-pilot-2026-10-07.md) rejected the original visible
upstream/ folder: Codex 0.160.1 registered both the local and raw entries.
The revised .upstream/ mapping preserves every original filename and byte.
Codex discovery passed with that mapping, but repeated OpenCode scans selected
the raw entry and bypassed the wrapper. Both loose-folder candidates were
rejected. The ZIP layout above resolves that collision: Codex discovery and
ten fresh OpenCode copy scans select the wrapper. The wrapper reads SKILL.md
from the archive with a local ZIP reader (Python or Windows PowerShell in this
pilot). This is packaging glue, not a source transformation or runtime download.
Codex and OpenCode runtime checks subsequently passed. The owner deferred the
remaining Claude runtime checks on 2026-10-07 until they report Claude works.
That deferred evidence no longer gates Changeset 3; ordinary changeset review
and user verification still apply.

Current skills.sh source supports ordinary discovery stopping below a found
skill; full-depth scanning can still recurse. This supports the proposal but
does not prove Codex, Claude, or OpenCode runtime behavior. The pilot must pin
the actual installer/host versions it checks.
Source: [skills.sh discovery](https://github.com/vercel-labs/skills/blob/main/src/skills.ts),
[copy installation](https://github.com/vercel-labs/skills/blob/main/src/installer.ts).

### Source record and integrity

UPSTREAM.json owns provider, source URL, immutable revision or release/asset ID,
original subtree, imported file list, and expected hashes. PROVENANCE.md owns
the reason for selection and local adaptations; it links to the source record
instead of duplicating its pin. Record raw source files separately from local
files so extra local files cannot be mistaken for upstream content.

For Matt, verify against Git blobs at the exact commit. For Hammer, record the
release asset identity and any advertised archive digest, plus independently
computed member hashes. A ZIP CRC check is not a full-archive SHA verification;
keep those evidence claims separate.

The check rejects changed, missing, or unexpected source files. A changed source
record must be verified against the independent pinned source too; regenerating
local hashes must not bless an edited copy. Use source acquisition in CI when
source files or provenance change. Routine wrapper-only checks can use the
already verified record. Downloads are build/review inputs, never runtime work.

## API / Interface: local integration contract

| Concern | Local owner and intended behavior | Required proof |
| --- | --- | --- |
| Review routing | Myst wrappers select myst-dev-kit:code-review as the engine and review-and-submit for publication. | With a competing code-review plugin installed, the correct engine receives the intended Git diff or Perforce CL evidence. |
| Tracker setup | Read the project's existing tracker and triage docs. If absent, locate or establish that contract before tracker writes. | No call to an uninstalled setup-matt-pocock-skills; existing Markdown conventions remain usable. |
| Skill calls | Explicitly load a required local wrapper through the host's available mechanism, preserving its user/model invocation contract. | No bare-name collision, no automatic invocation of a user-only entry point, no absent dependency hidden by fallback. |
| Commit/publish | Upstream commit and PR instructions run only within the user's scope and the project's VCS rules. | Perforce use does not create a Git commit; no submit, push, merge, or ticket closure bypasses the existing protocol. |
| Description writing | Git uses upstream pr; Perforce uses local p4-description. review-and-submit supplies concise review results for Evidence. | No standalone Review Record block; final axis results and relevant detail references remain traceable, with existing approval rules intact. |
| Git-only skills | Local discovery text and entry checks restrict pr and implement-spec to Git-managed target work. P4 routing never invokes either skill. | Automatic, cross-skill, and direct requests in P4 stop before the upstream workflow runs; a nested Git mirror does not override the project VCS. |
| Hammer metadata | English discovery text and current invocation choices live at the local root. Original Chinese frontmatter remains unchanged in the source archive. | deep-dive remains user-invoked; roundtable retains its agreed trigger behavior and its original method. |
| Codex metadata | Preserve original metadata in source. Set local metadata to the intended public contract and test the current host. | Fresh-session discovery and explicit invocation, with recorded versions and no duplicate skills. |

Keep common policy in the existing local owner, agentic-workflow or
review-and-submit. A wrapper links to that owner and contains only the mapping
needed for its own source. Do not add a new always-loaded policy skill without
a demonstrated need. For copy installs, document required skill dependencies;
detect a missing dependency instead of silently choosing another tool.

### Git and Perforce description writing

Retire the old standalone Review Record template. Use Summary / Evidence /
Merge Danger for Git, with Submit Risk as the P4 counterpart to Merge Danger.
The description explains the change; review execution remains in
review-and-submit. Its verified results become part of Evidence.

Adopt upstream pr unchanged, including its credits. Myst's local wrapper adds
the required ticket/source pointer and concise review evidence; it does not
edit upstream files to add them.

Under Evidence, give the final Standards and Spec results, or state why an axis
was skipped. Link to the existing durable review evidence when findings need
detail, preserving their disposition and source/revision context there. If no
usable report exists, include the essential unresolved findings and disposition
briefly in the description. Relevant remaining risks also belong in the risk
section. Keep docs-alignment as a preflight check and report its result or
limitation where relevant.

Do not require pass counts, a copied findings list, a separate Review heading,
or a new standalone report just to satisfy a replacement template. Reviewer
identity and detailed pass history can remain in the actual review evidence.
A short description must not hide a blocker, a skipped check, or missing human
acceptance. Missing review evidence is not a GREEN result.

Add a local-origin **p4-description** skill with the same purpose, adapted to
Perforce. It produces a changelist description, not a pull request. Cite the
pinned pr source and retain the relevant show-me attribution. Keep one verbatim
pr source bundle; do not maintain a second modified copy labeled upstream.
The P4 skill owns its runtime instructions and does not invoke pr. Source
attribution does not create a runtime dependency on the Git-only skill.

Proposed P4 description shape:

```text
[jobFamily][name] <specific title using established project tags>

## Summary

<brief change explanation; an ASCII diff sketch or tree when useful>
Ticket: <existing spec/ticket, or the protocol's justified workflow-skip line>

## Evidence

- Before: <observed failure or previous behavior, with evidence>
- After: <observed result, with evidence>
- Not verified: <remaining check, when applicable>
- Review: Standards <final result>; Spec <final result or skip reason>.
  Details: <existing durable evidence reference, when needed>

## Submit Risk

Reversibility: <how to undo it and any limit>
Impact: <affected behavior, data, assets, or consumers>

```

The formatter owns presentation. review-and-submit owns review execution,
finding handling, preflight checks, and the approval process, and supplies the
actual review results for Evidence. Keep the established P4 title-tag
lookup, English/ASCII rule, stable finding anchors, and evidence limits. Link
screenshots or logs through the project's evidence convention; do not assume a
P4 description renders Mermaid, images, or HTML. If before evidence is absent,
state that limit rather than invent a failing run.

Replace the old What / Why / Notes description skeleton in review-and-submit
with VCS-specific formatter routing. Reconcile its brief-body guidance with the
new formats so two competing narrative templates do not remain. Remove its
standalone Review Record template and requirements to append that block or
count review passes in descriptions. Preserve its review axes, finding handling,
preflight rules, and submit authority. Neither description-writing skill grants
permission to publish.

Before rollout, inventory consumer validators and audit/report tooling that
parse the old Review heading, verdict fields, or pass counts. Migrate required
consumers with the format change, preserving their actual review/approval checks.
If a required consumer cannot be updated in the release, record the migration
dependency before rollout; do not claim that removing the template is compatible.
Cover a simple code change, a docs-only change, and a UE asset change with
incomplete visual evidence. Use synthetic descriptions or already available
evidence during validation; do not edit or submit live CLs for these tests.

### Glossary compatibility

The upstream update reads/writes GLOSSARY.md and GLOSSARY-MAP.md. Existing
consumers may use CONTEXT.md and CONTEXT-MAP.md. Handle the mapping in local
wrappers and project configuration, not in upstream files.

1. An explicit project domain-doc pointer wins.
2. If only the legacy form exists, keep using it for both reads and writes.
3. If only the new form exists, use it.
4. If both exist without an authoritative pointer, surface the conflict before
   writing; do not guess which copy owns the vocabulary.
5. If neither exists, use the new upstream names once the complete reader/writer
   migration is ready. During staged rollout, preserve the existing convention.

Cover context maps and scoped glossaries, not just root files. No automatic
rename in UE_Blank_Proto belongs in this devkit change. A later consumer rename
is optional and separately reviewed. If compatibility cannot be demonstrated,
use an explicit migration and MAJOR release instead of claiming a transparent
MINOR update.

## Upstream disposition

### Matt Pocock

Refresh the 22 currently adopted skills still present in the promoted upstream
buckets. One skill per PR; carry original metadata and companions into its raw
subtree. The migration record must name every skill and its outcome.

| Group | Skills | Main attention |
| --- | --- | --- |
| Small pilot | handoff | Source packaging, Windows temporary paths, discovery. |
| Existing inline exceptions | implement, tdd, to-spec, to-tickets, triage, wayfinder | Restore seven source lines; preserve behavior through wrappers. |
| Glossary-sensitive | domain-modeling, diagnosing-bugs, improve-codebase-architecture, codebase-design, wait-what | Legacy/new path mapping; companion rename; tdd and triage above also participate. |
| Remaining current imports | code-review, grill-with-docs, prototype, research, wizard, grill-me, grilling, teach, to-questionnaire, writing-for-agents | Complete source bundles, invocation metadata, dependency loading. |

Additional dispositions:

- **resolving-merge-conflicts:** upstream removed it. Remove it from Myst as part
  of this refresh. Update catalog entries and references so no dead pointers
  remain. Do not retain a legacy copy.
- **retro:** recommended new candidate after the boundary migration. Trial it on
  one completed session, preserving its user-invoked entry point. Review useful
  proposals before adding checks or changing standards. Treat this as optional
  expansion, not a prerequisite for refreshing current imports.
- **pr:** required adoption in this plan. Preserve upstream files and credits,
  use its Git description format, and add a separate local p4-description skill.
  Put concise review results under Evidence for both paths; retire the old
  standalone Review Record format.
- **implement-spec:** required Git-only adoption and controlled Git pilot.
  Preserve upstream source unchanged. Exclude P4 environments through the local
  entry point and routing rules. Do not build a P4 counterpart or change the
  sequential-changeset policy as part of this refresh.
- **ask-matt and setup-matt-pocock-skills:** skip adoption of these two upstream
  skills in this refresh. Keep Myst's existing local router and project setup
  contract instead. Record both exclusions and their reasons. Preserve raw
  upstream references unchanged, but route runtime calls through local wrappers
  to the existing Myst behavior; do not call these uninstalled skills.
- **Experimental and frozen misc skills:** outside this refresh. chief-of-staff
  is not a required dependency of the current catalog.

### Hammer

Update deep-dive and roundtable to the verified v0.30.0 source, separately.
Preserve their entire raw SKILL.md, including original frontmatter. Keep author
credits and the existing documented redistribution permission. The provenance
already states that re-vendoring uses that permission; do not ask for it again.

The extracted skill bodies have no substantive delta from current Myst. The
deliverable is a clean source/wrapper boundary and current source provenance.
No new Hammer skill is proposed from this bundle.

Inspect the adjacent bundled README before finalizing the import. Check the
two method-specific behaviors: deep-dive asks one decisive question and stops;
roundtable pauses between rounds and preserves its rule against invented real
quotations. Full source equality alone does not establish these behaviors.

## Git-only skills: pr and implement-spec

Adopt both upstream skills unchanged for Git-managed work. Their local wrappers
own the VCS restriction; do not insert P4 guards into upstream source files.

- Mark both skills Git-only in local descriptions, README catalog entries, and
  workflow routing. Preserve their user/model invocation contracts.
- Before loading or executing the upstream workflow, establish the target
  project's declared VCS and the actual work root. Git being installed, or a
  nested Git checkout/mirror existing, does not make a P4 project eligible.
- In P4 environments, do not auto-select either skill or invoke it through
  another skill. A direct request receives a short applicability explanation
  without starting Git actions. Use p4-description for CL descriptions and
  the existing P4 implementation workflow for implementation work.
- For ambiguous or mixed workspaces, identify the target project and VCS before
  dispatch. Do not infer Git eligibility merely from a successful Git command
  in an unrelated parent or nested directory.
- In Git environments, implement-spec can use its task graph and worktree
  workflow within the approved task scope. Existing changeset verification,
  human-only ticket rules, and publication authority still apply. The skill
  does not silently override them; where separate changesets require sequential
  verification, honor that rule or its existing explicit exception.

The first implement-spec pilot uses a disposable Git repository with independent
and dependent tickets. Check ordering, bounded worker ownership, integration
validation, preservation of existing work, and correct review/publication
routing. Separately test P4 exclusion for direct, automatic, and cross-skill
requests, including a P4 fixture containing a Git mirror.

Preserve upstream implement-spec and tdd behavior as the first choice. Keep the
agreed Git-only boundary and existing Myst policy integration, but do not add
the review's proposed changeset-mapping procedure or TDD question relay in
advance. These are possible integration concerns, not demonstrated failures.
If the pilot exposes a real conflict, record the case and address the smallest
necessary local integration change. Do not patch upstream files or silently
bypass existing policy to make the pilot pass.

There is no implement-spec-p4 deliverable, P4 worker-client provisioning,
shelved-handoff scheduler, or new parallel-preparation mode in this plan.
The earlier P4 orchestration proposal is superseded, not deferred work.

## Implementation Plan

These are ordered work groups, not permission to execute all changesets at once.
Keep one skill per PR. Shared policy, verification, and catalog work can be
separate infrastructure/documentation PRs. After each changeset, present its
evidence and wait for the verification required by changelist-verification.
Publication follows review-and-submit with explicit changeset-specific authority.

### Approved migration and release strategy

Use the migration branch `codex/upstream-boundary-refresh`. Individual skill PRs target that branch and
retain their own review and user verification gates. Infrastructure and
documentation PRs also target the migration branch. Keep the current release
on main until the complete migration passes acceptance.

Changeset 0 documents a one-time contribution-process exception: migration
PRs target this branch instead of main and do not trigger version bumps or
release tags. The final integration PR brings the reviewed migration into
main as one release. This final PR is also an explicit exception to the
one-skill-per-PR rule; it links each completed skill review and checks combined
compatibility. It does not replace or bypass those reviews.

Prepare one version bump in both manifests and the release notes for that
final merge. Publish its tag only through the existing publication protocol.
Complete required consumer-parser compatibility work before exposing the new
format on main. Do not publish intermediate migration builds through the normal
consumer update path. The user approved this strategy and implementation on
2026-10-07. Publication remains separately gated.

### Changeset 0: Ratify the boundary and migration contract

**Deliverables:** an ADR amendment for strict source ownership, the wrapper
layout gate, the narrow integrity check, and glossary compatibility. Update
CONTRIBUTING.md to distinguish requirements for local wrappers from unchanged
source files. Correct README's present-tense claims; show migration status until
the last exception is removed. Establish an explicit row for every imported skill.

The contribution checklist must not require editing imported frontmatter into
local English trigger prose or adding publication rules inside source files.
Those requirements belong to the local entry point. A skill PR may include its
own wrapper, source bundle, provenance, catalog row, and evidence.

**Verification:** each current exception and intentional exclusion has a named
destination. No document claims the target state has already shipped. Larger
protocol changes get the issue and shape agreement required by CONTRIBUTING.md
before implementation begins.

Document the approved migration-branch and final-integration exceptions in
CONTRIBUTING.md, including PR targets, per-skill verification, and the single
version bump/release on final integration. Ordinary contributions retain the
existing main-target process after this migration.
Enable the existing CI checks for PRs and pushes to the migration branch;
the source-integrity check itself remains Changeset 1 work.

### Changeset 1: Establish the source verifier

**Deliverables:** one repository-only verification command, source-record schema,
and a CI step limited to imported-source integrity, wrapper/source links, and
declared dependencies. Preserve existing lint and plugin checks.

**Verification:** a deliberate edit to an upstream file fails; a missing
companion fails; a legitimate wrapper-only edit passes; changing a local hash
along with the edited file cannot pass independent source verification.
Do not enforce new compliance claims on unmigrated entries without listing them
as migration debt. The final gate permits no remaining undeclared debt.

### Changeset 2: Pilot handoff without changing all skills

**Deliverables:** migrate and refresh handoff using the proposed self-contained
layout. Keep the public name stable. Make a disposable local install fixture.

**Verification:** one entry point, bundled readable source, working relative
links, Windows temporary-directory behavior, and correct invocation metadata
in fresh supported-host sessions. Test normal plugin and copy-install routes;
record full-depth discovery separately. Stop the migration if packaging fails.

**Owner exception, 2026-10-07:** defer outstanding Claude runtime and invocation
restriction tests until the owner explicitly notifies us that Claude works.
Do not retry or schedule those tests in the meantime. They remain unverified,
not failed packaging checks or passed acceptance evidence. Their deferral does
not block closing this changeset or continuing the migration. Other changeset
verification and publication requirements remain in force.

### Changeset 3: Establish shared local integration

**Deliverables:** update the existing agentic-workflow local contract and its
reference material for dependency routing, tracker pointers, and staged glossary
compatibility. Keep publication authority in review-and-submit.

**Verification:** exercise the contract against Git and Perforce fixtures, legacy
and new glossary paths, and missing/ambiguous project config. Confirm the rule
is actually loaded through a wrapper before declaring the contract usable.

### Changesets 4 onward: Restore and refresh each imported skill

**Deliverables:** one skill per changeset. Start with implement as the routing
stress test, then a Hammer skill as the metadata stress test. Continue through
the disposition table in dependency order. Each review has two separate diffs:
old upstream source versus new upstream source, and old local behavior versus
the new local wrapper. Do not hide both inside a bulk folder replacement.

**Verification:** source integrity, complete companions, live loading trace,
relevant behavior cases, and attribution. For a skill whose source is unchanged,
record that result; wrapper migration is still a local behavior change.

### Required description-writing changesets

These are separate skill changesets after the wrapper pilot and before final
release readiness:

1. **pr:** vendor the full pinned upstream skill and credits; test the Git
   description entry point and the local addition of concise review evidence.
2. **p4-description:** add the local-origin Perforce format above. Test ASCII
   output, established title tags, evidence limits, and submit-risk wording.
3. **review-and-submit:** route description writing to the appropriate skill;
   retire the old narrative skeleton and standalone Review Record format.
   Preserve review execution, findings handling, preflight, and publication
   rules. Replace the old append-record step with supplying verified review
   results to Evidence. Update the old word-cap wording, missing-block repair
   rule, pass-count requirement, trigger description, and VCS mechanics pointers
   so none still require the retired format. Consumer validator changes, if
   required, are separately reviewed dependencies completed before rollout.

**Verification:** each resulting description uses the selected three-section
format, with concise actual review results under Evidence and no standalone
Review Record. Check GREEN, WARNING, BLOCKING, skipped-axis, missing-evidence,
and unverified-acceptance cases. Formatting does not invent test results,
review verdicts, or approval. No live changeset is published by a
description-writing test.

### Required Git-only implementation changeset

**implement-spec:** adopt the pinned upstream skill intact, with a local Git-only
entry check and a bounded Git task-graph pilot. Include catalog and routing
updates in the appropriate owning skill's changeset. No changelist-verification
policy amendment or P4 counterpart is required.

**Verification:** dependency ordering and combined validation in Git; correct
review/publication routing; and no upstream workflow execution in P4. Exercise
both explicit invocation and cross-skill routing. Keep pr under the same VCS
restriction in its own description-writing changeset.

### Final changeset: Complete documentation and integrate the release

**Deliverables:** resolve every inventory row; correct README, CONTRIBUTING,
SETUP, reference docs, source attribution, and CHANGELOG against what actually
passed. Update both plugin manifests together at release time. Confirm removal
of resolving-merge-conflicts and its catalog pointers as specified above.
Record the exact release pins, not the word latest.

The final integration PR targets main from the migration branch. Link the
individual skill reviews and their verification evidence, include the single
version bump and release notes, and review the combined compatibility result.
Merge and tagging still require the existing publication authority.

**Verification:** full install/update matrix, no remaining inline source edits,
no dead pointers, no duplicate entry points, and all review/acceptance records.
Retest existing consumers without hand edits. Only then claim full compliance.

Optional retro adoption follows as its own skill changeset after the refresh.

## Acceptance evidence

| Check | Passing evidence |
| --- | --- |
| Source integrity | Every imported file matches independently acquired pinned source bytes; local-only files are excluded by ownership, not by loose wildcard. |
| Complete import | Companion files, license/credit references, internal links, and external skill dependencies are accounted for. |
| Correct discovery | Each supported normal install exposes the intended public entries once; raw references do not become competing defaults. |
| Copy-install cleanup | Upgrade removes confirmed Myst copies of retired skills; rollback removes new-only copies. Personal edits are preserved and the discoverable catalog matches the selected release. |
| Cross-host invocation | Direct and cross-skill use works in Codex and Claude; OpenCode/copy installation preserves the source subtree and callable wrappers. |
| Review routing | Git and Perforce test cases reach the intended Myst review path, including the name-collision case. |
| Publication authority | A bounded implementation case ends with work available for review, without unauthorized publication or ticket closure. |
| Description and review separation | Git and P4 use the selected three-section format. Evidence contains actual final review results, skip reasons, and useful detail references. No standalone Review Record or mandatory pass-count summary remains; review and approval behavior is preserved. |
| Git-only scope | pr and implement-spec run only for Git-managed target work. P4 direct, automatic, and cross-skill cases do not execute their upstream workflows, including when a Git mirror exists. |
| Whole-spec execution | The Git pilot honors dependency and ownership constraints, validates the combined result, and preserves existing changeset review and publication authority. |
| Glossary compatibility | Read/write cases for legacy-only, new-only, mapped contexts, absent docs, and conflicting docs pass. No duplicate glossary is created. |
| Hammer behavior | Current English triggers and intended invocation modes work; raw Chinese frontmatter/body remain intact. |
| Documentation | README claims match the inventory and evidence; every import has current provenance. |

Use meaningful negative cases for the new integrity verifier. Do not build a
large prose-test framework. Keep runtime acceptance traces short and record the
host/version, input, selected entry/source, observed behavior, and limitation.
No test trace is a statistical guarantee of model compliance.

Claude CLI was unavailable during planning. The later pilot passed manifest,
installation, and offline command-registration checks, but execution failed
because the account was on hold. The owner deferred the remaining runtime
checks until they explicitly report Claude works. Keep those checks unverified;
do not infer a Claude runtime pass from another host or static inspection.

## Edge Cases & Considerations

- **Direct raw discovery:** a host may recursively load nested source skills.
  Reject a layout that causes this on the supported default route.
- **Copy-install dependencies:** a selected wrapper may lack another required
  skill. Provide an explicit prerequisite and a clear missing-dependency result.
- **Instruction conflicts:** source prose may name Git operations or a different
  review flow. Local routing must be demonstrated, not assumed from read order.
- **Relative links:** resolve upstream links from the original source root, not
  the wrapper's root. Verify dependency paths that leave that source subtree.
- **Mutable release assets:** record asset ID and source-member hashes; do not
  rely on a release tag alone. An asset change needs renewed source review.
- **Versioning:** target MINOR only if public invocation and installed consumers
  remain compatible. A mandatory document rename, changed install route, or
  required manual repair requires MAJOR under existing rules. Do not preassign
  a release number while these acceptance questions remain open.
- **Historical ADRs:** preserve them as history. Add a new decision that names
  what it supersedes; do not rewrite earlier approvals into a different claim.

## Troubleshooting and rollback

| Failure | Response |
| --- | --- |
| Duplicate raw skill appears | Stop after the pilot; revise packaging before further migrations. |
| Wrapper misses local policy | Fix the explicit entry/dependency route; repeat that behavior test. Do not patch upstream prose. |
| Upstream bytes or companions differ | Restore from the recorded immutable source and rerun the verifier. |
| Legacy consumer loses glossary | Restore the previous release for that consumer and fix compatibility before release. |
| Release has a runtime regression | Retain prior tag and source records; use a reviewed revert/fix release. Copy-install users follow the cleanup procedure below before reinstalling the chosen ref. |

Revert an affected skill's complete local package and its provenance/catalog
change together. Never roll back only the wrapper while leaving its referenced
source or metadata from another revision. Preserve unrelated user changes.

### Copy-install cleanup (approved)

Document the actual copy-install locations and inspect ownership before cleanup.
For this upgrade, remove obsolete Myst-installed resolving-merge-conflicts
copies. For rollback to the pre-refresh release, remove newly introduced Myst
copies of pr, implement-spec, and p4-description. Preserve personal edits outside
skill discovery paths before removal; leave unrelated or uncertain-origin
skills alone and report any unresolved name collision.

Install the selected release, then check the discoverable catalog in a fresh
session. Test upgrade and rollback with disposable copy-install fixtures.
Plugin updates use their normal directory replacement path. This work adds
release instructions and validation, not a new installer or automatic deletion
system. It does not authorize deleting users' installed copies during devkit
implementation.

## Future Expansion

| Candidate | Condition for reconsideration |
| --- | --- |
| retro | One useful trial, bounded local behavior, then a separate adoption PR. |
| Broader Hammer catalog | Actual new bundled capabilities and a local use case, not an app version bump alone. |

## Completion and handoff

The plan is complete when the source boundary is restored for the retained
catalog, both source targets are accounted for, and supported install paths and
local integration behavior pass. Git pr adoption, local p4-description, and
description routing with concise review evidence and retirement of the old
Review Record format are required outcomes. Required consumer parsers must be
compatible before rollout; review and approval rules remain in effect.
Git-only implement-spec adoption and verified P4 exclusion for both Git-only
skills are also required outcomes. No P4 orchestration or concurrency-policy
change is included. New optional skills are not exit criteria.

At the end of the pilot, capture a short handoff with the chosen layout, source
pins, actual runtime evidence, open failures, and remaining inventory rows.
That is the useful checkpoint before distributing the per-skill migration work.

## Accepted packaging amendment — 2026-10-08

**Status: Approved for production implementation, one skill at a time.**
ADR-0009 records the narrow filename exception. The first conversion is
codebase-design; the remaining ZIP packages stay in place until separately
verified. Source pins, upstream behavior, and local routing policy do not change.

### Problem and evidence

The ZIP solved a demonstrated discovery collision: some hosts treated the
wrapper and its nested original `SKILL.md` as separate skills. But it adds a
custom archive-reading step to normal skill use and makes source review harder.
That is an avoidable maintenance cost, not proof that ZIP execution is broken.

The [Agent Skills specification](https://agentskills.io/specification) and sampled
Anthropic, OpenAI, Superpowers, Vercel, and Matt Pocock repositories use readable
skill instructions with linked support files. Archives used to distribute a
package are distinct from an archive that the model must read during execution.
The sample supports plain files as the common pattern; it is not a statistical
survey of every repository. See the [research report](research-skill-packaging-2026-10-08.md)
for primary sources, host versions, and discovery limits.

### Recommended layout and boundary

Keep one public `SKILL.md` wrapper and store the original upstream entry as
ordinary reference Markdown. Rename the packaged entry only; preserve its bytes.

```text
skills/codebase-design/
  SKILL.md                         # Myst entry, routing, and direct source links
  agents/openai.yaml               # Myst invocation metadata
  UPSTREAM.json                    # Source revision, original paths, hashes, mapping
  PROVENANCE.md
  references/upstream/
    UPSTREAM.md                    # Original SKILL.md bytes, including frontmatter
    DEEPENING.md                    # Original bytes and filename
    DESIGN-IT-TWICE.md              # Original bytes and filename
    agents/openai.yaml             # Original upstream metadata
```

This uses the standard reference-file mechanism. The vendoring filename and
path map are Myst conventions, not an official cross-host packaging standard.
Register the public skill directory, never the upstream reference directory.

The proposed source contract is:

1. Preserve every upstream file's bytes, including frontmatter, companion files,
   and any source license files. Preserve required attribution and license notices.
2. Record the immutable source revision and complete original file inventory.
   Map original `SKILL.md` to packaged `UPSTREAM.md` explicitly in `UPSTREAM.json`.
   Retain other names and relative layout under the reference root.
3. Extend the existing verifier with a small, versioned path-map field. Compare
   packaged bytes to original source hashes through this map. Reject missing or
   extra files, unsafe paths, mapping collisions, and unexpected byte changes.
   The agent does not need to parse this manifest during normal execution.
4. Keep Myst policy in the wrapper and shared integration contract. Link the
   source entry and important companions directly from the wrapper. Do not add
   local instructions to upstream files or merge the two instruction bodies.

This is a filename-preservation exception. It must not be described as preserving
the complete original filesystem layout. ADR-0009 explicitly supersedes only the
relevant packaging and filename clauses of ADR-0008.

### Relative links and limits

The codebase-design companions link back to `SKILL.md`. The wrapper must state:
resolve upstream-relative links from `references/upstream/`, and map a reference
to the original entry `SKILL.md` to `UPSTREAM.md`. Other companion links retain
their existing relative paths. A normal Markdown viewer will not apply this
mapping, so the original back-links remain broken in that viewer. Do not add a
`SKILL.md` alias or symlink; that can reintroduce discovery collisions.

Audit each skill for scripts or tools that require a physical file named
`SKILL.md`, nested skill entries, or links that leave its source subtree. Agent
instructions cannot fix a script's filesystem dependency. Stop that conversion
if one exists; keep its current package until a concrete solution is reviewed.
Do not prebuild a general-purpose virtual filesystem or rendering pipeline.

### Costs and alternatives

| Choice | Benefit | Cost or limitation | Recommendation |
| --- | --- | --- | --- |
| Plain references with an explicit entry rename | Ordinary file reads; visible source diffs; self-contained copy installs | Filename exception and back-link mapping | Pilot this first |
| Current runtime ZIP | Original names and layout inside the archive; tested discovery isolation | Archive reader instructions and commands; less direct source review | Keep until the replacement passes |
| Exact source outside the installed skills tree | Preserves names and avoids the ordinary discovery root | Per-skill copy installs omit sibling source directories; needs another distribution rule | Do not add a custom installer for this |
| Hidden directory or host-specific disable rules | Can retain the original entry name | Hidden-directory trial already failed OpenCode; no portable exclusion rule found | Reject as the shared default |
| Generated combined entry | Can reduce runtime reads | Adds source/render maintenance and changes the distributed representation | Avoid the machinery retired by ADR-0007 |

Plain references remove the archive-reading step. The wrapper, shared contract,
and original instructions still need to be read. Do not promise zero extra tool
calls, a measured token reduction, or identical model outputs. The public name
and invocation metadata stay on the wrapper, so explicit and automatic selection
remain intended behavior; verify both through the supported hosts.

### Evidence so far

On 2026-10-08, a disposable codebase-design package preserved all four original
members by hash, with only the entry filename mapped. Fresh Codex 0.160.1
`skills/list` returned one candidate entry at the public wrapper. Debug prompt
inspection included that wrapper in the available-skills catalog. This was a
discovery-only check; it made no model request and proves no runtime behavior.

The fixture is local evidence, not a shipped package:
`%TEMP%/myst-plain-source-proposal-20261008/`. The loader source findings in the
research report support the design but do not replace installed-host tests.

The later owner-authorized [runtime and installation pilot](plain-source-pilot-2026-10-08.md)
passed source integrity, copy/plugin installation, Codex explicit and automatic
use, companion/back-link loading, missing-dependency handling, conflicting-domain
handling, and copy upgrade/rollback. A full three-agent design exercise passed
in a normal fresh Codex session after ephemeral mode failed to start an agent.
OpenCode discovery passed three fresh scans; its owner-approved DeepSeek runtime
passed source/companion loading and local vocabulary mapping, with minor answer
defects recorded in the report. Claude runtime remains deferred. These tests
support the conversion; production implementation evidence follows in that report.

### Implementation and acceptance

1. Record the accepted filename exception, then extend the existing verifier.
   Check unchanged bytes and complete source inventory, plus meaningful failure
   cases for a bad map, duplicate destination, missing member, and changed bytes.
2. Convert codebase-design alone as the pilot. It exercises companion files and
   back-links. Keep source pins and local behavior unchanged. Review the complete
   package, wrapper links, provenance, and catalog changes as one changeset.
3. Test normal per-skill copy installation and plugin installation in disposable
   fixtures. Confirm exactly one entry per candidate skill in Codex and OpenCode,
   with the intended public name and explicit/automatic invocation metadata.
   Test runtime source and companion reads, back-link mapping, dependency routing,
   and the required local glossary decision before any dependent work proceeds.
4. Test upgrade and rollback, including stale archive/reference cleanup. Confirm
   the installed package remains self-contained after copying. Use the approved
   ownership checks; do not remove unrelated or personal installed files.
5. Retain the owner's Claude runtime deferral until they report Claude works.
   Record static/install evidence separately; do not label Claude runtime passed.
6. After pilot verification, convert the other migrated skills one changeset at
   a time, then use the accepted layout for remaining imports. A behavior failure
   blocks that skill's conversion; it does not justify edits to upstream content.

Rollback restores the complete earlier package, wrapper, manifest, and provenance
together. Keep the ZIP layout available through Git history until the pilot is
accepted. This proposal does not authorize consumer edits, publication, or a new
source-version update. The pending TDD owner verification remains separate.
