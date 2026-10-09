---
name: wizard
description: "Use when generating a Bash wizard for human-only infrastructure setup, credentials or CI secrets, dashboard steps, or a migration/cutover. Steps the agent can perform itself do not need a wizard."
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
first. Required copy dependency: agentic-workflow. Check its local entry and
contract, then resolve the target project, VCS, and actual setup/CI destinations.

Read the [complete upstream instructions](references/upstream/UPSTREAM.md) and
use the [bundled template](references/upstream/template.sh). Resolve the source's
template link from that source directory; copy this template's full path and
preserve its library while authoring the stages. The source files remain unchanged;
only the packaged entry filename differs.

Map the saved wizard and repeatable-script capture to the project's workflow.
For Perforce, preserve repeatable work through that workflow rather than Git
commits, even when the target contains a Git mirror. The template's GitHub helpers
apply to the project's actual CI backend and authorized destinations; they do
not establish a new backend. Generated code and static validation do not grant
permission to execute the procedure, change shared configuration, close work,
or publish. Keep those actions within the project's authority.
