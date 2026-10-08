# Restore diagnosing-bugs with local domain and VCS routing

Type: task
Status: awaiting owner verification
Review base: 74148bf
Spec: [approved plan](../../../docs/plan_upstream_boundary_refresh.md)
and [ADR-0009](../../../docs/adr-0009-plain-upstream-references.md).

After domain-modeling acceptance, migrate diagnosing-bugs alone. Preserve the
complete approved source, metadata, license, and automatic invocation. Keep the
CONTEXT-to-GLOSSARY source update intact. Put project glossary, ADR, VCS, and
publication routing in the wrapper/shared contract. Link the unchanged HITL
script directly. Do not change the six-phase method or consumer files.

Compare direct and wrapped diagnosis on a reproducible defect: real failing
loop, ranked hypotheses, cause evidence, regression test before the fix,
passing original scenario, and cleanup. Compare the no-reproduction stop path.
Check source integrity, helper execution, copy/discovery, checkout bytes, and
both review axes. Owner acceptance is required before another skill. Claude
runtime remains deferred.

Evidence: [migration report](../../../docs/diagnosing-bugs-wrapper-2026-10-08.md).

All package checks and four fresh runtime cases passed. The direct/wrapped
implementations are byte-identical; test files differ only in one test name.
Both no-reproduction cases stop without hypotheses or edits. Both review axes
are GREEN with zero actionable findings. The report records the phase-order
difference and bounded coverage. Owner verification remains pending.
