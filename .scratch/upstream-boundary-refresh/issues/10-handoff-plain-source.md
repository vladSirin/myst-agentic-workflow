# Convert handoff to plain upstream references

Type: task
Status: resolved
Owner verification: accepted on 2026-10-08 for commit 7e05f31.
After the generated result was checked against the request and source, the
owner instructed: "Good verify it now."
Spec: [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md)
and [approved plan](../../../docs/plan_upstream_boundary_refresh.md).

The owner verified codebase-design conversion 23c01bf as OK on 2026-10-08 and
authorized continuation. Convert handoff only; preserve its complete source,
source pin, user-only invocation metadata, and behavior. Remove archive-reading
commands from the local wrapper. Update source mapping, attributes, provenance,
and evidence. Keep the existing OpenCode user-only invocation configuration.

The [evidence report](../../../docs/handoff-plain-source-2026-10-08.md) records
checks and limitations. Final independent Standards and Spec reviews are GREEN;
one stale catalog description was fixed and rechecked. Claude runtime remains deferred.
No publication or consumer update is included.
