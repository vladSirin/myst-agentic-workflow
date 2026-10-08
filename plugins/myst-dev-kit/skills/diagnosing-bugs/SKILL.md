---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Map its GLOSSARY.md reference to the project's
authoritative legacy, new, custom, or scoped domain documents, and use the
project's ADR location. Apply the target VCS and publication-authority rules
when the diagnosis reaches a commit or PR message.

Required Myst dependency for copy installs: agentic-workflow. Check its local
entry and shared contract before proceeding; use the Myst namespace or these
sibling paths rather than a same-name third-party skill.

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those mappings. When reproduction needs human interaction,
use the [HITL loop template](references/upstream/scripts/hitl-loop.template.sh).
The original source bytes are unchanged; only the packaged entry filename differs.
