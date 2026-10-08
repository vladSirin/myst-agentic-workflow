---
name: grill-with-docs
description: "Use when the user asks to interview a plan or design and record resolved terms and decisions in project docs."
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
first. Required copy dependencies: agentic-workflow, grilling, and domain-modeling.
Check their local entries before dependent work. Preserve explicit user invocation;
this entry is not an automatic or cross-skill interview trigger.

Read the [upstream instructions](references/upstream/UPSTREAM.md), then use both
named dependencies. Select Myst's [grilling](../grilling/SKILL.md) and
[domain-modeling](../domain-modeling/SKILL.md) entries through the host's namespace
or these full installed paths in copy hosts. If the host has no Skill tool, read
those selected entries and follow their methods; do not substitute another vendor.

The dependency entries own the interview frontier, user decisions, project domain
pointers, glossary writes, and ADR rules. Follow domain-modeling's local mapping
for legacy/new vocabulary and scoped docs. Keep the complete upstream source
unchanged; only SKILL.md is packaged as UPSTREAM.md.

Confirm the relevant glossary ownership and project ADR location before writes.
If an ADR location is missing and no existing project location can be confirmed,
ask before creating it; the upstream default path does not resolve that gap.
