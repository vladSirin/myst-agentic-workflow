---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker (edges as text in one file per ticket locally, or native blocking links on a real tracker).
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Use its project-pointer rules for tracker,
triage vocabulary, domain glossary, missing configuration, and publication
authority. The upstream setup references are handled by that contract.

Required Myst dependency for copy installs: agentic-workflow. Check its local
entry and the shared contract are available before proceeding; use the Myst
namespace or these sibling paths, not a same-name third-party skill.

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those local mappings. Project tracker rules govern ticket
locations, initial state, and relationship operations. Preserve the upstream
breakdown approval step before creating tickets. The original source bytes
are unchanged; only the packaged entry filename differs.
