# Convert implement to plain upstream references

Type: task
Status: resolved
Review base: bbd3b89
Spec: [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md)
and [approved plan](../../../docs/plan_upstream_boundary_refresh.md).

After verifying handoff, the owner instructed "move on." Convert implement
only. Preserve the source pin, original file bytes, public invocation metadata,
dependencies, tracker mapping, Git/P4 routing, and publication boundaries.
Replace the ZIP reader with a plain reference. Update mapping, attributes,
provenance, catalog, inventory, and evidence in this changeset.

Validate source integrity, copy installation, discovery, checkout byte
preservation, and bounded Git/P4 behavior. Review actual runtime outputs and
file changes. Run independent Standards and Spec reviews before completion.
Claude runtime remains deferred. No publication or consumer update is included.

Evidence: [conversion report](../../../docs/implement-plain-source-2026-10-08.md).
Source, install, discovery, checkout, and bounded runtime checks passed.
Final independent Standards and Spec reviews are GREEN with zero findings.
Owner verification: accepted on 2026-10-08 for conversion d442595. The owner
authorized verification if a quick direct-upstream test aligned. The comparison
passed: identical code/test text, matching red/green results and completion
state, unchanged HEAD. See the report for the controlled comparison and limits.
