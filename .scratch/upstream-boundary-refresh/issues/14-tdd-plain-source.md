# Convert TDD to plain upstream references

Type: task
Status: resolved
Review base: 52ef497
Spec: [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md)
and [approved plan](../../../docs/plan_upstream_boundary_refresh.md).

After verifying deep-dive, the owner instructed "Good go on." Convert TDD only.
Preserve the complete source, pin, companion paths, invocation metadata,
dependencies, glossary/review mappings, and upstream seam-confirmation rule.
Replace archive reads with plain links. Update attributes, provenance, catalog,
inventory, and evidence. Check source integrity, copy/discovery, checkout bytes,
and paired direct/wrapped behavior for confirmed and unconfirmed seams.

Run independent Standards and Spec reviews. Claude runtime remains deferred.
No publication or consumer update is included. The current package's owner
verification also covers the outstanding TDD wrapper acceptance from issue 08;
it has not been inferred from acceptance of another skill.

Evidence: [conversion report](../../../docs/tdd-plain-source-2026-10-08.md).
Source, copy/discovery, checkout, and paired runtime checks passed.
Final independent Standards and Spec reviews are GREEN with zero findings.
Outstanding: owner verification of the current TDD package before another changeset.
