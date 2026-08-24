---
name: review-changes
description: "Run the review-and-submit two-axis review INLINE, without sub-agents. Use when sub-agents are unavailable (Codex, or any session without an Agent tool). Ends with the literal Verdict: line per axis that the review-and-submit protocol records."
---

# Review Changes (inline reviewer)

Use this when `review-and-submit` reaches Step 4 and the session **cannot spawn sub-agents** —
Codex, which has no agents, or any session without an Agent tool. You run both axes yourself,
one after the other, with the same sources they use.

This is the only reason this skill exists. If sub-agents are available, spawn them: running
both axes in one context is exactly the cross-contamination the axis split prevents.

## How

1. **Pin the change** — `p4 opened -c {CL}` (must be pending), `p4 describe -s {CL}` for the
   description and file list, `p4 diff -c {CL} //...` for the diff body. `p4 describe` alone
   prints NO diff for a pending CL; it would hand you filenames and nothing to review.

2. **Standards axis.** Read `../../agents/architecture-reviewer.md` whole — its four-source
   canon, the closed 12-smell baseline, and the 400-word cap are all there, and the cap binds
   you as it binds a sub-agent. Apply it to code and config. Prose is not reviewed here — see
   the alignment check in step 5.

   One narrow exclusion: under `## Submission Authority (HARD RULE)`, the two paragraphs
   beginning "You are a **reviewer**, not a submitter" and "If the workflow that invoked you"
   address a sub-agent reporting to a parent. Here there is no parent, and their second-person
   "you MUST NOT run `p4 submit`" would land in the session that must submit. Your submit
   decision is governed by `review-and-submit` Step 6 and the hard rule below.

   **The `**Required output:**` block in that same section is NOT excluded** — it is the only
   place the verdict values are defined (GREEN = no blocking issues; WARNING = only
   non-blocking concerns; BLOCKING = must fix first), and where "do not paraphrase" lives.

3. **Spec axis.** Separately, and without reusing the Standards reasoning: read the linked
   spec/ticket/design doc and report only (a) requirements missing or partial, (b) behaviour
   the spec never asked for, (c) requirements implemented wrongly. Quote the spec line for
   each. No linked source → `Spec: skipped (no linked source)`.

4. **Report both axes separately**, under `## Standards` and `## Spec`, each with its own
   verdict line, exactly:

   `Verdict: GREEN | WARNING | BLOCKING`

   **Never merge or re-rank across the axes** — a blended verdict lets the passing axis hide
   the failing one. `review-and-submit` records them as
   `Standards: self (inline, review-changes skill) - Verdict: ...` and the same for `Spec:`.

5. **Docs-alignment check** (preflight, not a review). If the CL contains any `.md`/`.txt`, read
   `../../agents/radical-design-critic.md` for its lens, then answer one closed question: does
   the prose in this CL contradict what is true — behaviour the code here does not have, a stale
   plan status, two documents disagreeing, an instruction the diff invalidates? Report
   contradictions and fix them; otherwise record `Docs-alignment: aligned`.

   **Do not critique the design, the writing, or anything the document proposes.** It carries no
   severity and no verdict, and it never starts a review round. A reviewer asked to critique
   prose always finds something; a reviewer asked whether two things contradict either finds a
   contradiction or does not.

## Hard rule: submission authority

Here you are reviewer and submitter both. That makes the gate matter more, not less: reviewing
your own CL inline NEVER authorizes skipping the user's submit decision, and a GREEN from an
inline self-review carries less weight than an independent agent pass — say so in the Review
Record when the distinction matters (a risky CL deserves an independent reviewer or a human).
