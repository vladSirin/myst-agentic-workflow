---
name: triage
description: Move issues and external PRs through a state machine of triage roles, categorise, verify, grill if needed, and write agent-ready briefs.
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Apply its project-pointer rules for tracker,
triage labels, glossary reads and writes, missing configuration, and authority.
The upstream setup reference is handled by that contract. Map glossary references
in triage and its dependencies to the project's authoritative domain files.

Required Myst dependencies for copy installs: agentic-workflow, grilling, and
domain-modeling. Check the relevant local entry and references before each
dependent step. Resolve dependencies through the Myst namespace or these sibling
paths; preserve their invocation rules.

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those mappings. Resolve its companion links inside the bundled
source directory. Project rules govern labels, state changes, and publication;
upstream close or comment instructions do not grant extra authority. The original
source bytes are unchanged; only the packaged entry filename differs.
