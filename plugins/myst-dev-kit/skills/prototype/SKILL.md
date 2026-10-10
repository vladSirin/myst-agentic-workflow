---
name: prototype
description: "Use when the user wants a throwaway logic/state demo or contrasting UI layouts to answer a design question."
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
first. Required copy dependency: agentic-workflow. Check its local entry and
contract, then resolve the target VCS, domain docs, and implementation issue.

Read the [complete upstream instructions](references/upstream/UPSTREAM.md), then
follow the selected [logic](references/upstream/LOGIC.md) or
[UI](references/upstream/UI.md) branch. Where a companion links SKILL.md for
common capture rules, read the bundled UPSTREAM.md. The original source files
are unchanged; only the packaged entry filename differs.

Apply capture to the target's VCS and existing project workflow. For Git, retain
the upstream throwaway-branch capture within authorized scope. For Perforce,
preserve the prototype and its question/answer through the project's Perforce
workflow and implementation issue; do not create Git branches or commits, even
in a nested mirror. Shelving/submission still follow the publication protocol.
If the project has no agreed capture destination, resolve it before capture.

Keep the prototype available for evaluation. Record the actual validation state
and fold only a validated decision into real code. A draft demo or UI variant is
not user acceptance or permission to close work or publish shared state.
