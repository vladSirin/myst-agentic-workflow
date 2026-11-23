---
name: code-review
description: "Review a Git changeset or Perforce changelist on separate Standards and Spec axes. Use when the user asks for a code review, branch or PR review, pending CL review, work-in-progress review, or review since a fixed point."
---

Read the [local integration contract](../agentic-workflow/LOCAL-INTEGRATION.md)
(copy dependency: agentic-workflow) and [review input mapping](REVIEW-INPUTS.md),
then follow [upstream code-review](references/upstream/UPSTREAM.md). Resolve upstream
`SKILL.md` links to `UPSTREAM.md`. Reviewers report only. Review-and-submit owns publication and description formatting.

Select fresh context explicitly. Record identity, context, verdict and completion
per axis. Only a confirmed fresh report completes an initial review. Retain
inherited reports and repeat only that axis. If freshness cannot be verified,
leave the required axis and publication gate pending. Record confirmed Spec skips.

Send fixes to the original reviewer with the new pin and delta. Preserve its
history and round count. If unavailable, report the reassessment as pending.
