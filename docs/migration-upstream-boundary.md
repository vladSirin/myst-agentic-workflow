# Upstream boundary migration inventory

Status: writing-for-agents f40945e owner-verified on 2026-10-09 after alignment artifact recheck; both reviews GREEN. Roundtable implementation and alignment/package checks complete; both reviews GREEN; owner verification pending. Further imports remain pending. Claude runtime deferred until they report Claude works.

The [approved plan](plan_upstream_boundary_refresh.md) owns scope and acceptance.
[ADR-0008](adr-0008-strict-upstream-boundary.md) owns the boundary decision;
[ADR-0009](adr-0009-plain-upstream-references.md) amends the packaging and root
entry filename rule.
This inventory owns migration status. A pending row is not a source-integrity
or runtime-pass claim. Add actual changeset and evidence references as work lands.
The [verifier policy](../upstream-policy.json) lists machine-checked local skills
and pending waivers; update it with each skill's inventory row. The
[verification guide](upstream-source-verification.md) defines the source record
and commands.

## Source targets

- Matt: commit `6fd947921b935b7e1e69293a200400f0fdd5c15f`.
  Paths below are relative to that repository. The older imports are attributed
  through LICENSE; code-review also has its own provenance pin. See the
  [file comparison](research-matt-pocock-updates-2026-10-06.md).
- Hammer: v0.30.0, Intel ZIP asset ID `614238989`. Paths are under
  `Hammer.app/Contents/Resources/advanced-capabilities/`. Preserve the existing
  redistribution permission. See [source evidence](research-hammer-update-2026-10-06.md).
  The adjacent README was inspected during the
  [deep-dive migration](deep-dive-wrapper-2026-10-07.md); it adds no method dependency.

## Imported skills

Destination for every retained or added import:
`plugins/myst-dev-kit/skills/<skill>/`, with local entry/provenance and a complete
source bundle. All twenty-five packaged imports use plain references with the single
mapped entry filename. TDD completed the earlier ZIP conversions. Roundtable
is the latest prepared import; the last declared import remains pending removal. The [plain-source pilot](plain-source-pilot-2026-10-08.md)
records the accepted replacement for the earlier ZIP workaround.

| Skill | Source subtree | Required migration | Status |
| --- | --- | --- | --- |
| handoff | skills/productivity/handoff | First packaging pilot; refresh temporary-path guidance and metadata | Owner verified plain-reference conversion 7e05f31 on 2026-10-08 after output review. OpenCode still needs its local invocation rule; Claude deferred ([evidence](handoff-plain-source-2026-10-08.md)) |
| implement | skills/engineering/implement | Restore source; move publication/tracker routing into local wrapper | Changeset 4 verified by owner (0a38ca7). Plain-reference conversion d442595 owner-verified on 2026-10-08 after aligned direct-upstream comparison; both review axes GREEN ([evidence](implement-plain-source-2026-10-08.md)) |
| tdd | skills/engineering/tdd | Restore source; retain tracker/glossary compatibility; no speculative question relay | Changeset 7 implemented. Plain-reference conversion c9e531c owner-verified on 2026-10-08 after both direct comparisons and GREEN reviews ([evidence](tdd-plain-source-2026-10-08.md)) |
| to-spec | skills/engineering/to-spec | Move tracker lookup out of source | Source unchanged across approved pins; wrapper and local-tracker tests complete; both reviews GREEN; b1730da owner-verified on 2026-10-08 after alignment recheck ([evidence](to-spec-wrapper-2026-10-08.md)) |
| to-tickets | skills/engineering/to-tickets | Restore source; local tracker lookup; refresh ticket relationships | Plain-source wrapper and six runtime checks complete; direct results align for local tickets and mock native links; both reviews GREEN; 5b7079d owner-verified on 2026-10-08 after alignment recheck ([evidence](to-tickets-wrapper-2026-10-08.md)) |
| triage | skills/engineering/triage | Restore source; local tracker/glossary mapping | Owner-verified on 2026-10-08 after final direct/wrapped alignment retries; both review axes GREEN; initial service failures retained as history ([evidence](triage-wrapper-2026-10-08.md)) |
| wayfinder | skills/engineering/wayfinder | Move tracker lookup out of source | Plain-source wrapper and six runtime tests complete; direct outputs align for task resolution and human-decision pause; both reviews GREEN; 7fbda73 owner-verified on 2026-10-08; shared naming defect documented ([evidence](wayfinder-wrapper-2026-10-08.md)) |
| domain-modeling | skills/engineering/domain-modeling | Complete companions including upstream glossary format; local path mapping | Wrapper/source and package checks complete; eight selected behavior checks passed including direct alignment; one excluded timeout retained; both reviews GREEN; 985627a owner-verified on 2026-10-08 ([evidence](domain-modeling-wrapper-2026-10-08.md)) |
| diagnosing-bugs | skills/engineering/diagnosing-bugs | Refresh source; local glossary mapping | Plain-source wrapper and four runtime checks complete; direct fix and stop-path results align; both review axes GREEN; 9e22e7a owner-verified on 2026-10-08 ([evidence](diagnosing-bugs-wrapper-2026-10-08.md)) |
| improve-codebase-architecture | skills/engineering/improve-codebase-architecture | Refresh source; local glossary mapping | Four selected runtime comparisons align for report and interview; initial ephemeral delegation failures retained; package and visual checks pass; both review axes GREEN; e123a5f owner-verified on 2026-10-08 ([evidence](improve-codebase-architecture-wrapper-2026-10-08.md)) |
| codebase-design | skills/engineering/codebase-design | Refresh DESIGN-IT-TWICE companion; local glossary mapping | Changeset 6 previously verified (de12d6a). Owner verified plain-reference conversion 23c01bf as OK on 2026-10-08 ([evidence](plain-source-pilot-2026-10-08.md)) |
| wait-what | skills/productivity/wait-what | Refresh source; local glossary mapping | Four direct/wrapped explanation tests align; legacy and scoped terms resolve correctly; package checks pass; both review axes GREEN; 62bcd4a owner-verified on 2026-10-08 ([evidence](wait-what-wrapper-2026-10-08.md)) |
| code-review | skills/engineering/code-review | Refresh to approved source pin; compare method delta; preserve source/metadata and namespaced Git/P4 routing | Source unchanged across pins; wrapper and input adapter implemented; eight runtime checks and package checks passed; both reviews GREEN; bd7fbd3 owner-verified on 2026-10-08 ([evidence](code-review-wrapper-2026-10-08.md)) |
| grill-with-docs | skills/engineering/grill-with-docs | Complete source bundle, metadata, provenance, and loading proof | Final source/composition and guards pass; direct comparisons align in method/docs, with an initial open-choice recommendation difference retained; both reviews GREEN; 9da7632 owner-verified on 2026-10-09 after fresh alignment recheck ([evidence](grill-with-docs-wrapper-2026-10-08.md)) |
| prototype | skills/engineering/prototype | Complete source bundle, metadata, provenance, and loading proof | Complete source and local capture routing implemented; branch comparisons and actual artifacts align in tested method/behavior; exact designs/state shapes differ; both reviews GREEN; 0b8105f owner-verified on 2026-10-09 after fresh alignment recheck ([evidence](prototype-wrapper-2026-10-09.md)) |
| research | skills/engineering/research | Complete source bundle, metadata, provenance, and loading proof | Complete source and local note routing implemented; grounded runs pass with actual background-agent and cited-note alignment; both reviews GREEN; 7a8dc27 owner-verified on 2026-10-09 after fresh alignment recheck ([evidence](research-wrapper-2026-10-09.md)) |
| wizard | skills/engineering/wizard | Complete source bundle, metadata, provenance, and loading proof | Complete source and local setup/CI/capture routing implemented; direct/wrapped authoring alignment, P4 repeatable capture, scope pause, and package/loading checks pass; both reviews GREEN; 5b86625 owner-verified on 2026-10-09 after alignment artifact recheck ([evidence](wizard-wrapper-2026-10-09.md)) |
| grill-me | skills/productivity/grill-me | Complete source bundle, metadata, provenance, and loading proof | Complete source alias and local Myst dependency routing implemented; direct/wrapped first rounds align; user-only, missing-dependency, and package/loading checks pass; both reviews GREEN; 1d481a5 owner-verified on 2026-10-09 after alignment artifact recheck ([evidence](grill-me-wrapper-2026-10-09.md)) |
| grilling | skills/productivity/grilling | Complete source bundle, metadata, provenance, and loading proof | Complete source and local routing implemented; direct/wrapped three-round interviews align with actual fact delegation and unchanged state; package/loading checks pass; both reviews GREEN; 51a07f5 owner-verified on 2026-10-09 after alignment artifact recheck ([evidence](grilling-wrapper-2026-10-09.md)) |
| teach | skills/productivity/teach | Complete source bundle, metadata, provenance, and loading proof | Complete source and local routing implemented; eight turns pass with mission, lesson, continued-learning, and guard alignment; package/browser/loading checks pass; both reviews GREEN; 6dc2168 owner-verified on 2026-10-09 after alignment artifact recheck ([evidence](teach-wrapper-2026-10-09.md)) |
| to-questionnaire | skills/productivity/to-questionnaire | Complete source bundle, metadata, provenance, and loading proof | Complete source and local draft routing implemented; ten turns pass for actual send-interview continuation, full question coverage, default destination, and guards; package/loading checks pass; both reviews GREEN; ebb2717 owner-verified on 2026-10-09 after alignment artifact recheck ([evidence](to-questionnaire-wrapper-2026-10-09.md)) |
| writing-for-agents | skills/productivity/writing-for-agents | Complete source bundle, metadata, provenance, and loading proof | Complete source and local document routing implemented; six direct/wrapped, automatic, and guard runs pass; package/loading checks pass; both reviews GREEN; f40945e owner-verified on 2026-10-09 after alignment artifact recheck ([evidence](writing-for-agents-wrapper-2026-10-09.md)) |
| deep-dive | Hammer: deep-dive | Preserve original Chinese frontmatter; English local trigger and user-only invocation | Changeset 5 verified by owner (58509c2). Plain-reference conversion c64c236 owner-verified on 2026-10-08 after both-step direct-upstream alignment check; reviews GREEN ([evidence](deep-dive-plain-source-2026-10-08.md)) |
| roundtable | Hammer: roundtable | Preserve original Chinese frontmatter; local discovery metadata; method behavior checks | Complete source and metadata implemented; ten actual turns align for opening, continuation, stop, no-topic pause and guards; package/loading checks pass; both reviews GREEN; owner verification pending ([evidence](roundtable-wrapper-2026-10-09.md)) |
| pr | skills/engineering/pr | Add unchanged source and credits; Git-only wrapper and concise actual review evidence | Three-file source adopted; seven selected runtime checks pass, one environment failure retained; both reviews GREEN; d8c2c53 owner-verified on 2026-10-08 ([evidence](pr-wrapper-2026-10-08.md)) |
| implement-spec | skills/engineering/implement-spec | Add unchanged source; Git-only entry and bounded pilot; no speculative orchestration | Pending addition |
| resolving-merge-conflicts | Removed upstream | Remove package/catalog references; document obsolete copy cleanup | Pending removal |

## Exceptions and exclusions

- Existing inline source adaptations in implement, tdd, to-spec, to-tickets,
  triage, and wayfinder move to their local entry points and policy owners.
- Previously omitted Codex metadata belongs in complete raw source bundles.
  Local host metadata is separately owned and must pass fresh-session checks.
- Hammer's local frontmatter moves to local entry points; original files stay
  whole. Preserve credits and the existing permission record.
- ask-matt stays excluded. Existing agentic-workflow remains the local router.
- setup-matt-pocock-skills stays excluded. Use the project's existing tracker
  and setup contract. Raw references remain intact; local routing resolves them.
- retro is outside this release; a later trial must show a useful local case.
- Upstream in-progress and frozen misc buckets stay excluded. They are not
  dependencies to install as part of this migration.

## Local work

| Owner | Work | Status |
| --- | --- | --- |
| Documentation and CI branch selection | Boundary ADR, contribution exception, honest README, inventory, approved plan and copy-cleanup scope | Changeset 0 verified by user on 2026-10-07; local commit 12d7a75 |
| Repository verifier | Source-record schema and narrow independent integrity checks | Changeset 1 verified by user on 2026-10-07; local commit 1a9cabf |
| Plain-reference packaging | ADR-0009, version 2 filename mapping, codebase-design conversion | Owner verified 23c01bf as OK on 2026-10-08; conversions remain per-skill |
| agentic-workflow | Shared wrapper routing, tracker pointers, glossary compatibility | Changeset 3 verified by owner on 2026-10-07; local commit 5b3b1f3 ([evidence](shared-local-integration-2026-10-07.md)) |
| review-and-submit | PR/P4 formatter routing; replace What/Why/Notes and standalone Review Record with verified review evidence; preserve review/authority | Five bounded integration runs and fresh direct/protocol alignment pass after the INFO repair; both review axes GREEN; 39a285f owner-verified on 2026-10-08 ([evidence](review-submit-format-2026-10-08.md)) |
| p4-description | New local-origin formatter, credited to pr/show-me inspiration; no runtime call to pr | Eight selected cases and package checks pass; three reader failures retained; both reviews GREEN; 0dc4e03 owner-verified on 2026-10-08 ([evidence](p4-description-2026-10-08.md)) |
| design, changelist-verification | Retain existing behavior | No skill change planned |
| Consumer format parsers | Check compatibility before formatter rollout | Known P4 preflight/audit copies pass static controls and eleven rendered bodies with line-start axis fields; deployed revisions and other required consumers must be confirmed before exposure ([evidence](review-submit-format-2026-10-08.md)) |
| Release docs and install fixtures | Validate upgrade and rollback cleanup; remove only confirmed obsolete Myst copies and preserve personal edits | Pending |

The [plan review](review_upstream_boundary_refresh_2026-10-07.md) records findings
and the owner's decisions. No installed copies or consumer repositories have
been migrated by Changeset 0.
