---
name: code-review
description: "Review a Git changeset or Perforce changelist on separate Standards and Spec axes. Use when the user asks for a code review, branch or PR review, pending CL review, work-in-progress review, or review since a fixed point."
---

Select this engine as `myst-dev-kit:code-review`. In copy hosts without namespaces,
read this installed Myst SKILL.md by its full path; a bare code-review name can
select another vendor's engine. Use the same identity in dependent review briefs.

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
and [review input mapping](REVIEW-INPUTS.md) before the upstream workflow. Resolve
the target VCS and project tracker/spec pointers there. Required Myst dependency
for copy installs: agentic-workflow; check its local entry and shared contract.

Read the [upstream instructions](references/upstream/UPSTREAM.md), then apply their
two-axis method to the selected evidence. Map the upstream Git-specific input
steps and default tracker path through REVIEW-INPUTS.md. Preserve the separate
Standards and Spec briefs, complete smell baseline, and separate final reports.
If review-and-submit supplied a pinned scope and additional brief requirements,
retain them. Reviewers report only; they never edit, submit, shelve, push, or merge.
Publication and description formatting remain owned by review-and-submit.

The original source bytes are unchanged; only the packaged entry filename differs.
