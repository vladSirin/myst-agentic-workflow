---
name: review-changes
description: "Perform a pre-submit review of a changelist or diff INLINE, when reviewer subagents are unavailable (e.g. under Codex, or any session without an Agent tool). Applies the team's architecture + design rubrics and ends with the literal Verdict: line the review-and-submit protocol parses."
---

# Review Changes (inline reviewer)

Use this when the `review-and-submit` protocol calls for a reviewer but you
cannot spawn one as a subagent — under Codex (which has no agents), or in any
session without an Agent tool. You perform the review yourself, with the same
rubrics the dedicated reviewer agents use.

## How

1. **Gather the change**: `p4 describe -du {CL}` (or `git diff`) plus the full
   content of every changed file that needs context.
2. **Load the rubrics** — read both agent definitions that ship in this plugin
   (same directory tree as this skill, under `agents/`):
   - `agents/architecture-reviewer.md` — Code Complete principles, SOLID,
     UE5/AngelScript patterns, project conventions.
   - `agents/radical-design-critic.md` — edge cases, UX friction, hidden
     complexity, fragility, loopholes in behavioral/process text.
   Apply the architecture lens to code/config; the design-critic lens to
   designs, workflows, rules, and docs. Mixed CLs get both.
3. **Review adversarially**: you are reviewing the change, not defending it —
   even (especially) when you authored it. Name concrete failure scenarios,
   with file:line references.
4. **Categorize** every finding: BLOCKING (must fix before submit) /
   WARNING (should fix soon) / INFO (future improvement).
5. **End with the verdict line**, exactly:

   `Verdict: GREEN | WARNING | BLOCKING`

   The `review-and-submit` protocol parses the literal `Verdict:` token and
   records it in the CL description's Review Record block as
   `Reviewer: self (inline, review-changes skill) — Verdict: ...`.

## Hard rule: submission authority

You are the reviewer here, not the submitter. Reviewing your own CL inline
NEVER authorizes skipping the user's submit decision, and a GREEN verdict from
an inline self-review carries less weight than an independent agent pass —
say so in the Review Record when the distinction matters (e.g. risky CLs over
the Submit-Audit thresholds deserve an independent reviewer or a human).
