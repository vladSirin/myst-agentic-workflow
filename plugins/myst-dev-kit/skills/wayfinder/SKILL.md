---
name: wayfinder
description: Plan a huge chunk of work (more than one agent session can hold) as a shared map of decision tickets on your issue tracker, and resolve them one at a time until the way to the destination is clear.
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Use its project-pointer rules for tracker,
wayfinding operations, triage, glossary reads and writes, and missing configuration.
The upstream setup and local-tracker fallback follow that contract; establish
missing tracker operations before dependent writes.

Required Myst dependencies for copy installs: agentic-workflow, grilling,
domain-modeling, research, and prototype. Check the relevant local entry and
references before each dependent step. Resolve them through the Myst namespace
or these sibling paths and preserve their invocation rules. Map glossary
references in dependencies to the project's authoritative domain files.

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those mappings. Project rules govern claims, state changes,
closure, and publication. Resolve research-branch and artifact instructions
against the target project's VCS rules before dispatch. The original source
bytes are unchanged; only the packaged entry filename differs.
