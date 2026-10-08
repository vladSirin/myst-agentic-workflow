# Restore triage with project tracker and glossary routing

Type: task
Status: resolved
Review base: 993e5d1
Spec: [approved plan](../../../docs/plan_upstream_boundary_refresh.md)
and [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md).

The owner authorized the next skill after accepting to-tickets. Migrate triage
alone: retain all approved source files, companions, metadata, and attribution.
Move the inline setup reference into the local integration contract. Map glossary
reads and writes, including dependencies, to authoritative project pointers.
Keep source method and state machine intact; preserve publication authority.

Check source integrity, copies, discovery, Windows checkout, and runtime behavior.
Compare direct and wrapped local tracker briefs and custom glossary updates.
Check conflicting states and missing label mappings stop dependent writes.
Run both review axes, then obtain owner verification before the next skill.
Claude runtime remains deferred; no external publication is authorized.

Evidence: [migration report](../../../docs/triage-wrapper-2026-10-08.md).
Package checks and two guard cases passed. Four direct/wrapped runtime attempts
were interrupted by a model service usage limit during automatic approval review;
tracker and glossary writes did not execute. All baseline files/HEADs are intact;
one direct attempt added a Python cache. No completed alignment claim is made.
Resume those four tests from fresh baseline fixtures when model access works,
then finish independent reviews and owner acceptance.

Final acceptance: model access recovered. Both final direct/wrapped pairs align
for brief/state updates and custom glossary writes. The companion-link P3 was
fixed and final wrapper runs match the package. Standards and Spec are GREEN
with zero open findings. Owner verification follows the explicit conditional
approval on 2026-10-08. All original failed attempts remain in the evidence.
