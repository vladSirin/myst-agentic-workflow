---
name: code-review
description: "Review a Git changeset or Perforce changelist on separate Standards and Spec axes. Use when the user asks for a code review, branch or PR review, pending CL review, work-in-progress review, or review since a fixed point."
---

Select this engine as `myst-dev-kit:code-review`. In copy hosts without namespaces,
read this installed Myst SKILL.md by its full path; a bare code-review name can
select another vendor's engine. Use the same identity in dependent review briefs.

Read [Myst's local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
and [review input mapping](REVIEW-INPUTS.md) before the upstream workflow. Resolve
the target VCS and project tracker/spec pointers there, then load only the input
reference selected for that VCS. An unresolved target loads neither detail
branch. Required Myst dependency for copy installs: agentic-workflow; check its
local entry and shared contract.

Read the [upstream instructions](references/upstream/UPSTREAM.md), then apply their
two-axis method to the selected evidence. Map the upstream Git-specific input
steps and tracker lookup through REVIEW-INPUTS.md. Preserve the separate
Standards and Spec briefs, complete smell baseline, and separate final reports.
If review-and-submit supplied a pinned scope and additional brief requirements,
retain them. Reviewers report only; they never edit, submit, shelve, push, or merge.
Publication and description formatting remain owned by review-and-submit.

For each initial reviewer, explicitly select the host's fresh-context option.
Record the reviewer identity, launch context, verdict, and completion for each
axis. Count an initial review as complete only after a confirmed fresh reviewer
returns its report. If a reviewer inherited the parent chat, keep its findings
and verdict, mark that axis incomplete, and repeat only that axis with a fresh
reviewer. If a fresh start cannot be obtained or verified, report the limit
and leave the axis incomplete. Keep a confirmed Spec skip visible.

For a fix, resume the reviewer that raised the finding with the new pin and
delta. Preserve its review history and the coordinator's round count. If that
reviewer is unavailable, report the pending reassessment.

The original source bytes are unchanged; only the packaged entry filename differs.
