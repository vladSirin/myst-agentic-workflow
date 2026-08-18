# Re-review scope

Reached from `review-and-submit` Step 7 when you have fixed a finding and are about to spend
another reviewer pass. Rules 3 and 6 fire earlier than that and are triggered from where they
apply.

1. **Re-run only the reviewer(s) whose BLOCKING findings you addressed**, not the whole panel.
   Tell each one exactly what changed, what you declined, and why. A reviewer whose findings
   you did not act on has nothing to re-verify, and re-running it invites new findings on
   unchanged code.
2. **WARNING-only fixes do NOT require a re-review.** Apply them, record the disposition in the
   Review Record (`[FIXED]` / `[ACCEPTED]` / `[DEFERRED]`), and go to Step 7. A full pass for
   prose, tooltip, clamp and comment edits costs a review cycle and buys nothing.

   **Exception, and it is the whole safety property:** if a WARNING fix turns out to touch
   behaviour, change a signature, or widen scope, it is no longer a warning fix — treat it as a
   blocker fix and re-review. Judge by what the edit *did*, not by the severity label that
   prompted it.
3. **The fix answers the finding and nothing else.**
   - **Implement the finding, not the prescription.** A reviewer's suggested fix was written
     without running anything. Decide the fix yourself. If you adopt theirs, say so in the
     re-review brief - `Adopted <reviewer>'s prescription for <finding>, not independently
     verified` - so the pass that must re-verify it knows where to look.
   - **Explanation goes in the brief, not the artifact.** A fix does not re-argue the design in
     rationale, comments, or doc prose. New prose is new reviewable surface.
4. **These findings never cost a re-review** - at any severity, BLOCKING included:
   missing Review Record block, missing or wrong `[JobFamily][Name]` tag, EOL flip, non-ASCII in
   the description, a missing `Ticket:` or `Workflow: skipped (<reason>)` line **whose ticket or
   user decision already exists**, a missing `BP-Pins:` line **whose verification was already
   performed**. Creating the ticket, making the skip decision, and performing the pin
   verification are never rule-4 fixes.

   **The list is closed, and closed on a principle**: every item is a description-or-formatting
   fix that *cannot change behaviour*, and every item has a validator behind it. Naming, `_Raw`
   policy and BuildId findings are script-caught but stay OFF - those fixes can break things.
   Anything not on the list, including a wrong claim in the description body, is a real finding.

   **You skip the reviewer pass, never the gate.** Fix it and return to Step 7: the user's submit
   decision and the Step 8 Review Record both still apply, exactly as they would after any other
   pass.
5. **One re-review per pass, not per finding.** Fix everything the pass raised, or record why you
   declined it, then re-review once - one round, launching every reviewer that needs re-running in
   parallel. Known trade: this raises per-round fix volume, which is itself a churn input, and
   rule 3 is what holds that down.
6. **Scope freezes when the review starts - except what the fix itself requires.** A file the fix
   genuinely needs is part of this CL and is reviewed with it. Unrelated work that arrives
   mid-review gets its own CL.
