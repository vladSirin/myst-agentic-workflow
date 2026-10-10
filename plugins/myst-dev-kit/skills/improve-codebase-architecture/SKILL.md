---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick.
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Map glossary reads and writes to the project's
authoritative domain documents and use its ADR location. Use the target VCS's
history for upstream history-based scoping. Preserve the project's publication
authority and this entry's user-only invocation on every host.

Required Myst dependencies for copy installs: agentic-workflow,
[codebase-design](../codebase-design/SKILL.md),
[grilling](../grilling/SKILL.md), and
[domain-modeling](../domain-modeling/SKILL.md). Check their local entries before
the dependent step. Route upstream skill calls through the Myst namespace or
these sibling paths, following their invocation contracts.

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those mappings. Use the
[HTML report guide](references/upstream/HTML-REPORT.md) when producing the report.
The original source bytes are unchanged; only the packaged entry filename differs.
