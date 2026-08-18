---
name: review-changes
description: "Perform a pre-submit review of a changelist or diff INLINE. Use for the review-and-submit fast path (small, under-threshold CLs), and when reviewer subagents are unavailable (Codex, or any session without an Agent tool). Applies the team's architecture + design rubrics and ends with the literal Verdict: line the review-and-submit protocol parses."
---

# Review Changes (inline reviewer)

Use this when the `review-and-submit` protocol calls for a reviewer and a
subagent pass is not the right spend: its **fast path** (small, under-threshold
CLs), or any session that cannot spawn one — under Codex (which has no agents),
or any session without an Agent tool. You perform the review yourself, with the
same rubrics the dedicated reviewer agents use.

## How

1. **Gather the change**: `p4 diff -c {CL} //...` for the per-file diffs, plus
   `p4 describe -s {CL}` for the description and file list (or `git diff`), plus
   the full content of every changed file that needs context. `p4 describe` alone
   prints NO diff body for a PENDING changelist - it would hand you filenames and
   nothing to review.
2. **Load the rubrics** — read both agent definitions that ship in this plugin,
   at the plugin root's `agents/` dir (a sibling of `skills/` — from this file:
   `../../agents/`):
   - `agents/architecture-reviewer.md` — its four-source canon (Code Complete,
     Readable Code, and the game/engine sources where they apply), SOLID, and
     the conventions the project itself establishes.
   - `agents/radical-design-critic.md` — edge cases, UX friction, hidden
     complexity, fragility, loopholes in behavioral/process text.
   Apply the architecture lens to code/config; the design-critic lens to
   designs, workflows, rules, and docs. Mixed CLs get both — unless the invoking
   protocol scoped you to one lens.

   Read each file whole, with ONE narrow exception: under
   `## Submission Authority (HARD RULE)`, the two paragraphs beginning "You are a
   **reviewer**, not a submitter" and "If the workflow that invoked you" address a
   subagent reporting to a parent. Here there is no parent, and their second-person
   "you MUST NOT run `p4 submit`" would land in the session that must submit. Your
   submit decision is governed by `review-and-submit` Step 7 and by the hard rule
   below.

   **The `**Required output:**` block in that same section is NOT excluded** — it
   is the only place the verdict values are defined (GREEN = no blocking issues;
   WARNING = only non-blocking concerns; BLOCKING = must fix first), and it is
   where "do not paraphrase" lives. It binds you exactly as it binds a subagent.
3. **Review adversarially**: you are reviewing the change, not defending it —
   even (especially) when you authored it. Name concrete failure scenarios,
   with file:line references.
4. **Spec axis (conditional)**: if the CL description links a spec, ticket, or
   design doc, read it and verify the change implements what it asked for —
   report GAPS (asked-for but missing, and not explicitly deferred) and SCOPE
   CREEP (substantive changes never asked for) as findings marked [SPEC], with
   the same severities. No linked source -> note "Spec axis: no linked source".
5. **Categorize** every finding: BLOCKING (must fix before submit) /
   WARNING (should fix soon) / INFO (future improvement).
6. **End with the verdict line**, exactly:

   `Verdict: GREEN | WARNING | BLOCKING`

   The `review-and-submit` protocol parses the literal `Verdict:` token and
   records it in the CL description's Review Record block as
   `Reviewer: self (inline, review-changes skill) - Verdict: ...`.

## Hard rule: submission authority

Here you are reviewer and submitter both. That makes the gate matter more, not
less: reviewing your own CL inline NEVER authorizes skipping the user's submit
decision, and a GREEN verdict from an inline self-review carries less weight
than an independent agent pass —
say so in the Review Record when the distinction matters (e.g. risky CLs over
the Submit-Audit thresholds deserve an independent reviewer or a human).
