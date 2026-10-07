# Plain-source packaging and first production conversion

Status: resolved
Outstanding: Owner verifies this production changeset before the next conversion.

Spec: [approved packaging amendment](../../../docs/plan_upstream_boundary_refresh.md)
and [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md).

Scope: add narrow version 2 path mapping to the verifier and schema; retain
version 1 compatibility; convert codebase-design only with byte-preserving Git
attributes, provenance, and source documentation. Keep all existing source pins.

Evidence: [pilot and production record](../../../docs/plain-source-pilot-2026-10-08.md).
Runtime pilot is complete for Codex/OpenCode; Claude remains owner-deferred.
All 26 acceptance tests, independent source verification, repository checks,
byte-preserving Git checkout, and production copy installation passed. Both
independent review axes are GREEN with no findings.
No push, PR, release, or consumer update is in this changeset.
