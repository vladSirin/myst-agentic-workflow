---
name: implement-spec
description: "Implement an approved spec and its ticket task graph on a Git integration branch. User-invoked; Git-only, never for Perforce."
disable-model-invocation: true
---

Read the [local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md).
Use this entry only on explicit user invocation. Resolve the target VCS first.
For Perforce, use the project's implementation workflow and stop here.

For Git, verify the copy dependencies and their Git closure before implementation:
agentic-workflow, [tdd](../tdd/SKILL.md), [review-and-submit](../review-and-submit/SKILL.md),
[myst-dev-kit:code-review](../code-review/SKILL.md) and
[changelist-verification](../changelist-verification/SKILL.md).

Follow [upstream implement-spec](references/upstream/UPSTREAM.md) with the project's
tracker and agreed TDD seams. Resolve upstream `SKILL.md` links to `UPSTREAM.md`.
Route final review through review-and-submit. For multiple changesets, apply
changelist-verification. Leave human-only tickets to their owners.
