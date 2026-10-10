---
name: tdd
description: Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests.
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Apply its project glossary mapping for reads and
writes, including legacy CONTEXT.md paths, and the project's workflow rules.

Required Myst dependencies for copy installs: agentic-workflow, codebase-design,
review-and-submit, and code-review. Use the Myst namespace or the explicit
sibling entries below when the source reaches those references:

- `codebase-design` means Myst [codebase-design](../codebase-design/SKILL.md).
  Consult its vocabulary when the interface shape is in question.
- The review-stage `code-review` reference maps to Myst
  [review-and-submit](../review-and-submit/SKILL.md), whose review engine is
  [myst-dev-kit:code-review](../code-review/SKILL.md).

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those local mappings. Read [tests.md](references/upstream/tests.md)
and [mocking.md](references/upstream/mocking.md) when the source calls for them.
Resolve source-relative links from references/upstream. The original source
bytes are unchanged; only the packaged entry filename differs.
