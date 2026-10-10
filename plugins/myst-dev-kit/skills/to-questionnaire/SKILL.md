---
name: to-questionnaire
description: Turn a decision you can't fully answer into a questionnaire for someone else to fill in.
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
first. Required copy dependency: agentic-workflow. Check its local entry and
contract. This remains user-invoked; preserve that rule on hosts which ignore
invocation metadata.

Resolve the target project and its questionnaire destination. Use an explicit
user destination or the project's established convention; otherwise keep the
upstream current-directory filename. Resolve conflicting destinations before
writing the draft.

Read the [complete upstream instructions](references/upstream/UPSTREAM.md).
The send interview, knowledge gap, questions, and document format stay owned by
the source. Report the local draft path. Sending it, tracker changes, later
implementation, and shared publication retain the project's workflow and the
user's authorized scope through the shared contract.
The original source bytes are unchanged; only the packaged entry filename differs.
