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

- Resolve feature-local ticket IDs within the named feature. Include the feature
  (when used) and ID with the title. If lookup fails or the title conflicts
  with the request, ask before editing.
- Before editing, note existing changes in the files the ticket touches so
  review can distinguish the user's work and flag edits to the same lines.
- `tdd` means Myst [tdd](../tdd/SKILL.md), at the user's pre-agreed seams.
- At the upstream `code-review` step, load Myst
  [review-and-submit](../review-and-submit/SKILL.md) as the local coordinator.
  Its review engine is [myst-dev-kit:code-review](../code-review/SKILL.md).
  Give each reviewer the same pinned ticket changes and only its own axis brief.
  Include a separate observation
  only when the reviewer needs it, with its source and test conditions.
  Leave code interpretation, expected findings, and verdicts to the reviewers.
  Select the inputs below for the target VCS.
- The upstream commit instruction applies only to Git-managed target work and
  within the user's authorization. Perforce work follows the project's named
  changelist workflow. Review completion does not authorize publication or
  ticket closure; keep human acceptance and tracker rules intact.

For Git, retain the [committed diff and commit list](../code-review/GIT-INPUTS.md)
for the agreed base. Check the index, working tree, and untracked files for
ticket work missing from that range. Include the ticket's staged and unstaged
diffs and the full contents of new ticket files. Keep unrelated commits and
hunks outside the ticket verdict. If all ticket work is
uncommitted, pin it directly. An empty committed diff alone does not end review.
Identify unrelated edits outside the ticket scope. Where edits overlap, supply
the actual current file and flag the overlap. Ask the reviewers to assess the
combined behavior. If the overlap prevents a ticket verdict, name the gap
and ask for clarification.
Preserve the user's edits.

For Perforce, use the [named CL input](../code-review/PERFORCE-INPUTS.md).

Read the bundled [upstream instructions](references/upstream/UPSTREAM.md), then
follow them with those local mappings. The original source bytes are unchanged;
only the packaged entry filename differs.
