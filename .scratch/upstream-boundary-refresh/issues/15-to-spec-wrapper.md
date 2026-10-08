# Restore to-spec with a local tracker wrapper

Type: task
Status: resolved
Review base: 7d2888e
Spec: [approved plan](../../../docs/plan_upstream_boundary_refresh.md)
and [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md).

After TDD acceptance, the owner instructed "Good carry on." Migrate to-spec
only: preserve complete approved source and metadata, original template and
seam confirmation, provenance/license, and explicit-only invocation. Move the
existing inline tracker-lookup change into the local integration wrapper.
Use project tracker/triage/glossary and authority rules without editing source.
Compare old/new upstream separately from old/new local integration.

Verify source integrity, copy/discovery, source loading, and relevant behavior:
confirmed seam creates a local spec, unconfirmed seam waits, missing tracker
stops dependent writes, and project initial state overrides an upstream default.
Compare actual output with a direct upstream call using the same fixture.
Run Standards and Spec reviews. Claude runtime is deferred; no external
publication or consumer migration is included.

Evidence: [migration report](../../../docs/to-spec-wrapper-2026-10-08.md).
Source, copy/discovery, checkout, and four runtime checks passed.
Final Standards and Spec reviews are GREEN with zero findings.
Outstanding: owner verification before another changeset.
