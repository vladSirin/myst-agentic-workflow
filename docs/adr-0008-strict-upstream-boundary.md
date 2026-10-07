# ADR 0008 - Preserve upstream files and isolate Myst integration

**Status**: Accepted; migration pending
**Date**: 2026-10-07
**Context owner**: package maintainer

## Context

The owner approved the [refresh plan](plan_upstream_boundary_refresh.md).
The current library has documented inline reference adaptations, intentionally
omitted Codex metadata, and local Hammer frontmatter. The README's blanket
verbatim claim does not describe that state. See the
[migration inventory](migration-upstream-boundary.md) for the work still needed.

## Decision

### Source ownership

Preserve each selected upstream skill's complete files: original frontmatter,
body, metadata, companions, filenames, and internal directory structure.
Record the source root mapping and immutable source identity. Local wrappers
own Myst discovery text, routing, project conventions, and VCS/publication rules.
Keep upstream attribution and applicable permission records.

Upstream source stays byte-faithful. Any runtime adaptation belongs in the local
entry point or a reference that the entry point actually loads. Preserve the
upstream method by default. Add behavior only for an agreed local requirement
or an observed integration failure; do not prebuild speculative orchestration.
Local-origin skills remain local and need no artificial upstream subtree.

### Packaging gate

Pilot a self-contained directory with a local SKILL.md, PROVENANCE.md,
UPSTREAM.json, optional local host metadata, and the whole raw skill under
upstream/. This is a candidate layout, not a validated installation contract.

Before migrating further skills, show that supported normal plugin and copy
installs expose one public entry, preserve source files and relative links,
and load the local rules on direct and cross-skill calls. Record recursive
discovery behavior separately. If normal discovery exposes duplicate raw
skills, revise packaging without modifying source or dropping a supported host.

### Narrow source verification

Add one repository-only verifier in Changeset 1. UPSTREAM.json owns the source
pin, original subtree, file inventory, and hashes; PROVENANCE.md links to it and
explains local choices. Verify changed source or source records against an
independently acquired pinned source. Updating local hashes cannot authorize
modified upstream bytes. Wrapper-only checks may use an already verified record.

Matt imports use pinned Git blobs. Hammer records asset identity and computed
member hashes; an advertised archive digest is not a locally verified full
archive digest. Acquisition happens during build/review, never skill execution.
This decision does not restore render pipelines, runtime hooks, or an installer.

### Local compatibility

Existing local policy owners retain review, tracker, and publication rules.
Keep pr and implement-spec Git-only, including direct and indirect calls in a
Perforce target containing a Git mirror. Use local p4-description for Perforce.
Retire the standalone Review Record through the planned formatter and consumer
migration; review execution and approval remain required. No P4 whole-spec
orchestration or concurrency-policy amendment is included.

For glossary paths, use an explicit project pointer first; otherwise preserve
the sole existing legacy or new form. If both exist without a pointer, resolve
ownership before writing. Use upstream names for new documents only when all
readers and writers are ready. No consumer document rename is part of this work.

### Review and release

The temporary migration process is defined in
[CONTRIBUTING](../CONTRIBUTING.md#upstream-boundary-migration-exception).
Per-skill changes retain their review and user verification gates. One final
integration and release exposes the completed migration to normal consumers.
Copy-install release notes must identify obsolete Myst-owned copies for removal,
preserve personal edits, and cover rollback. No automatic deletion system is added.

## Relationship to earlier ADRs

- ADR-0002: retain vendor-and-curate; source files themselves are no longer a
  place for transformations. Local integration uses wrappers.
- ADR-0003: retain original source format, including complete frontmatter.
  Local entry points are explicitly separate from the preserved source.
- ADR-0004: retain local ownership and provenance outside replacement source.
- ADR-0006: replace the inline ref-remap exception with local routing. Document
  selection and adaptation decisions without permitting source edits.
- ADR-0007: retain the lean library, shared tool source, and existing install
  channels. Amend the removal of source tracking only for the narrow verifier
  above. The retired general installer/render machinery stays retired.

Earlier ADRs remain unchanged as history. This decision governs the migration
target; the inventory lists current debt until each skill passes its checks.

## Completion

Acceptance requires source equality, complete bundles, proven loading and
compatibility, and current attribution for every retained import. The README
may claim complete migration only after the inventory and install matrix pass.

## Pilot follow-up, 2026-10-07

The handoff pilot rejected the visible upstream/ candidate: Codex 0.160.1
discovered two public entries in both source-plugin and project-copy scans.
Moving the raw subtree to .upstream/ fixed Codex discovery without changing
source filenames or bytes. Repeated OpenCode scans, however, selected the raw
entry in one run and wrappers in others. A single listed name is insufficient:
the selected entry must reliably be the wrapper. This revised candidate is
also unaccepted. See the [pilot evidence](handoff-pilot-2026-10-07.md).
Resolve the packaging failure and remaining host-runtime checks before further
migration. These observations do not relax the source or acceptance contract.

### Discovery fix, 2026-10-07

Keep the complete original subtree in upstream.zip, with original member
filenames and bytes. Only the public wrapper remains a discoverable SKILL.md.
The source record points at the archive; the verifier checks its complete
member set against independent upstream source. The wrapper reads bundled
instructions with a local ZIP reader. No network fetch, source rewrite, or
runtime hook is added. Python and Windows PowerShell readers were tested.

Codex discovery and ten fresh OpenCode copy scans select the wrapper with this
layout. This resolves the observed discovery blocker. It adds a local ZIP-reader
requirement; the remaining host-runtime acceptance checks still apply. Loose
source folders above are retained in this ADR only as the failed pilot history.

The owner subsequently deferred outstanding Claude runtime tests until they
explicitly report Claude works. The [plan's v1.9 exception](plan_upstream_boundary_refresh.md)
permits migration to continue while that evidence remains unverified; it does
not relax source ownership or grant publication authority.
