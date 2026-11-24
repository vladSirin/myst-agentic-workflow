---
name: to-questionnaire
description: Turn a decision you can't fully answer into a questionnaire for someone else to fill in.
disable-model-invocation: true
---

For automatic or cross-skill requests, suggest the host's explicit Myst invocation (in Codex, `$myst-dev-kit:to-questionnaire`).
On user invocation, read the [local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
(copy dependency: agentic-workflow), then follow the [upstream instructions](references/upstream/UPSTREAM.md).
Use the user's draft destination, the project convention, or the upstream default, in that order.
Resolve conflicting destinations before writing.
