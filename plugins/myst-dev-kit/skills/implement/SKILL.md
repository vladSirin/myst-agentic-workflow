---
name: implement
description: "Implement a piece of work based on a spec or set of tickets, using the project's Git or Perforce workflow."
disable-model-invocation: true
---

Read the [local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md),
then follow [upstream implement](references/upstream/UPSTREAM.md). Resolve upstream
`SKILL.md` links to `UPSTREAM.md`. Before implementation, verify the copy
dependencies: agentic-workflow, [tdd](../tdd/SKILL.md), [review-and-submit](../review-and-submit/SKILL.md)
and [myst-dev-kit:code-review](../code-review/SKILL.md).

Use the feature (when applicable) and ticket ID for lookup and title reporting.
Treat a failed lookup or conflicting title as ambiguous. Before editing, record
existing changes in the ticket files.

Route upstream review through review-and-submit. Give each axis its own brief
and the same pinned ticket changes. Supply source and conditions for observations
the reviewer needs. Leave findings and verdicts to the reviewers.

For [Git](../code-review/GIT-INPUTS.md), include all ticket work: committed,
staged, unstaged and full new files, even if nothing is committed. Preserve user
edits. Flag overlaps, show the actual file and review the combined behavior.
Exclude unrelated edits from the ticket verdict. If attribution prevents a
verdict, state the gap and ask. For Perforce, use the [named CL input](../code-review/PERFORCE-INPUTS.md).
