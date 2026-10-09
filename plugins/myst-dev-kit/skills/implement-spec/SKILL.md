---
name: implement-spec
description: "Implement an approved spec and its ticket task graph on a Git integration branch. User-invoked; Git-only, never for Perforce."
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
first. Resolve the target work root and declared VCS before loading the upstream
workflow. A Git mirror or installed Git does not make a Perforce target eligible.
For Perforce, explain the Git-only limit and use the existing project implementation
workflow; do not load or execute upstream implement-spec. Resolve an unclear
target before dependent work. This entry is user-only, including on hosts that
ignore invocation metadata; other skills may suggest its explicit command.

Required Myst copy dependencies: agentic-workflow, tdd, review-and-submit,
code-review, and changelist-verification. Check their local entries before
implementation, plus their declared dependencies (including the Git pr formatter).
Use the Myst namespace or full installed paths; never substitute another vendor.
Resolve the project's spec, tracker, completion rules and domain documents through
the shared contract. The excluded setup-matt-pocock-skills is not a fallback.

Apply these local mappings while following the source:

- `tdd` means Myst [tdd](../tdd/SKILL.md), at the user's pre-agreed seams.
- The upstream `code-review` step uses Myst
  [review-and-submit](../review-and-submit/SKILL.md) as coordinator, with
  [myst-dev-kit:code-review](../code-review/SKILL.md) as its review engine.
- When work spans changesets, load
  [changelist-verification](../changelist-verification/SKILL.md) and keep its
  verification gate or existing explicit user exception. Human-only tickets
  remain human-owned. Local branch/commit/merge actions stay within authorized
  scope. PR creation/readiness, push, merge to shared branches, publication and
  ticket closure retain the project rules and review-and-submit authority.

Read the complete [upstream instructions](references/upstream/UPSTREAM.md), then
follow their task graph and worktree method with these local mappings. Source
bytes are unchanged; only SKILL.md is packaged as UPSTREAM.md.
