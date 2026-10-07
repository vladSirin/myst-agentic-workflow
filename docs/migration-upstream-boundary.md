# Upstream boundary migration inventory

Status: implementation started; skill migration pending.

The [approved plan](plan_upstream_boundary_refresh.md) owns scope and acceptance.
[ADR-0008](adr-0008-strict-upstream-boundary.md) owns the boundary decision.
This inventory owns migration status. A pending row is not a source-integrity
or runtime-pass claim. Add actual changeset and evidence references as work lands.

## Source targets

- Matt: commit `6fd947921b935b7e1e69293a200400f0fdd5c15f`.
  Paths below are relative to that repository. The older imports are attributed
  through LICENSE; code-review also has its own provenance pin. See the
  [file comparison](research-matt-pocock-updates-2026-10-06.md).
- Hammer: v0.30.0, Intel ZIP asset ID `614238989`. Paths are under
  `Hammer.app/Contents/Resources/advanced-capabilities/`. Preserve the existing
  redistribution permission. See [source evidence](research-hammer-update-2026-10-06.md).
  The adjacent bundled README still needs inspection before import finalization.

## Imported skills

Destination for every retained or added import:
`plugins/myst-dev-kit/skills/<skill>/`, with local entry/provenance and a complete
raw source subtree. The proposed nested layout remains subject to the pilot.

| Skill | Source subtree | Required migration | Status |
| --- | --- | --- | --- |
| handoff | skills/productivity/handoff | First packaging pilot; refresh temporary-path guidance and metadata | Pending |
| implement | skills/engineering/implement | Restore source; move publication/tracker routing into local wrapper | Pending |
| tdd | skills/engineering/tdd | Restore source; retain tracker/glossary compatibility; no speculative question relay | Pending |
| to-spec | skills/engineering/to-spec | Move tracker lookup out of source | Pending |
| to-tickets | skills/engineering/to-tickets | Restore source; local tracker lookup; refresh ticket relationships | Pending |
| triage | skills/engineering/triage | Restore source; local tracker/glossary mapping | Pending |
| wayfinder | skills/engineering/wayfinder | Move tracker lookup out of source | Pending |
| domain-modeling | skills/engineering/domain-modeling | Complete companions including upstream glossary format; local path mapping | Pending |
| diagnosing-bugs | skills/engineering/diagnosing-bugs | Refresh source; local glossary mapping | Pending |
| improve-codebase-architecture | skills/engineering/improve-codebase-architecture | Refresh source; local glossary mapping | Pending |
| codebase-design | skills/engineering/codebase-design | Refresh DESIGN-IT-TWICE companion; local glossary mapping | Pending |
| wait-what | skills/productivity/wait-what | Refresh source; local glossary mapping | Pending |
| code-review | skills/engineering/code-review | Preserve complete source and metadata; keep namespaced Myst routing | Pending |
| grill-with-docs | skills/engineering/grill-with-docs | Complete source bundle, metadata, provenance, and loading proof | Pending |
| prototype | skills/engineering/prototype | Complete source bundle, metadata, provenance, and loading proof | Pending |
| research | skills/engineering/research | Complete source bundle, metadata, provenance, and loading proof | Pending |
| wizard | skills/engineering/wizard | Complete source bundle, metadata, provenance, and loading proof | Pending |
| grill-me | skills/productivity/grill-me | Complete source bundle, metadata, provenance, and loading proof | Pending |
| grilling | skills/productivity/grilling | Complete source bundle, metadata, provenance, and loading proof | Pending |
| teach | skills/productivity/teach | Complete source bundle, metadata, provenance, and loading proof | Pending |
| to-questionnaire | skills/productivity/to-questionnaire | Complete source bundle, metadata, provenance, and loading proof | Pending |
| writing-for-agents | skills/productivity/writing-for-agents | Complete source bundle, metadata, provenance, and loading proof | Pending |
| deep-dive | Hammer: deep-dive | Preserve original Chinese frontmatter; English local trigger and user-only invocation | Pending |
| roundtable | Hammer: roundtable | Preserve original Chinese frontmatter; local discovery metadata; method behavior checks | Pending |
| pr | skills/engineering/pr | Add unchanged source and credits; Git-only wrapper and concise actual review evidence | Pending addition |
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
| Documentation and CI branch selection | Boundary ADR, contribution exception, honest README, inventory, approved plan and copy-cleanup scope | Changeset 0 prepared; awaiting user verification |
| Repository verifier | Source-record schema and narrow independent integrity checks | Pending Changeset 1 |
| agentic-workflow | Shared wrapper routing, tracker pointers, glossary compatibility | Pending |
| review-and-submit | VCS formatter routing and Review Record retirement; preserve review and authority | Pending |
| p4-description | New local-origin formatter, credited to pr inspiration; no runtime call to pr | Pending addition |
| design, changelist-verification | Retain existing behavior | No skill change planned |
| Consumer format parsers | Check compatibility before formatter rollout; local P4 audit warning dependency is named in the review report | Pending |
| Release docs and install fixtures | Validate upgrade and rollback cleanup; remove only confirmed obsolete Myst copies and preserve personal edits | Pending |

The [plan review](review_upstream_boundary_refresh_2026-10-07.md) records findings
and the owner's decisions. No installed copies or consumer repositories have
been migrated by Changeset 0.
