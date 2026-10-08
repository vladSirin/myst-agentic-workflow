---
name: implement
description: "Implement a piece of work based on a spec or set of tickets, using the project's Git or Perforce workflow."
disable-model-invocation: true
---

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
before the upstream workflow. Resolve the target VCS and the project's spec,
tracker, and completion rules. A nested Git mirror does not change a Perforce
target into Git work.

Required Myst dependencies for copy installs: agentic-workflow, tdd,
review-and-submit, and code-review. Check that their local entries are available
before starting implementation. Load them through the host's Myst namespace or
the explicit sibling paths below; do not substitute a same-name third-party skill.

Apply these mappings while following the source:

- `tdd` means Myst [tdd](../tdd/SKILL.md), at the user's pre-agreed seams.
- At the upstream `code-review` step, load Myst
  [review-and-submit](../review-and-submit/SKILL.md) as the local coordinator.
  Its review engine is [myst-dev-kit:code-review](../code-review/SKILL.md).
  Supply the actual target changeset evidence through that protocol.
- The upstream commit instruction applies only to Git-managed target work and
  within the user's authorization. Perforce work follows the project's named
  changelist workflow. Review completion does not authorize publication or
  ticket closure; keep human acceptance and tracker rules intact.

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those local mappings. The original source bytes are unchanged;
only the packaged entry filename differs.
