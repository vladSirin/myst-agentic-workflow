---
name: grill-with-docs
description: "Use when the user asks to interview a plan or design and record resolved terms and decisions in project docs."
disable-model-invocation: true
---

For automatic or cross-skill requests, suggest the host's explicit Myst invocation (in Codex, `$myst-dev-kit:grill-with-docs`).
On user invocation, read the [local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
and follow the [upstream instructions](references/upstream/UPSTREAM.md) using Myst's
[grilling](../grilling/SKILL.md) and [domain-modeling](../domain-modeling/SKILL.md).
Copy dependencies: agentic-workflow, grilling, and domain-modeling. Confirm the project's
ADR location before creating an ADR.
