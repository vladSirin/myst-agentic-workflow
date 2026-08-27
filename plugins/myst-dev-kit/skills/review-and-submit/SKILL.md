---
name: review-and-submit
description: "MANDATORY protocol when the user says 'review and submit' (any variant) or before publishing ANY changeset — a Perforce changelist submit, or a git merge/PR against the shared branch. Changeset organization, two-axis review (Standards + Spec) via myst-dev-kit:code-review sub-agents, Review Record, preflight validators, human-gated submit."
---

# Review and Submit Protocol

A **changeset** is one named, described, reviewable unit of work — a Perforce changelist, or
a git branch/PR. Each step states the neutral rule first; **Perforce** and **git** blocks
carry the command forms. Team specifics — audit checks, tag vocabularies, job families —
live in your project's own docs (CLAUDE.md / AGENTS.md and its stack notes), not here.

## Continuous source-control sync (applies at all times)

This duty applies to **every file modification**, not just review/submit.

**Perforce:** after modifying, creating, or deleting any tracked file, you MUST `p4 edit` /
`p4 add` / `p4 delete` it BEFORE presenting results to the user. Don't wait to be asked;
don't batch checkouts to the end of the session.

> [!CAUTION]
> `Modify file -> p4 edit/add -> Present status` — never `Modify -> Present -> (forget) ->
> try to submit later -> find dirty files outside any CL`.

When unsure which CL a file belongs in: put it in the **default change** and reorganize later
via `p4 reopen -c <CL>`. Default-change files stay out of named-CL submits (`p4 submit -c`
submits only that CL) and they WILL be tracked in `p4 opened`.

**git:** the working tree is already tracked; the equivalent duty is branch discipline —
work happens on a named branch created at task start, never directly on the default branch.

During an active review, a file the changeset did not already contain goes in a NEW changeset
unless the fix itself requires it (Step 5, stopping rule).

## Trigger

When the user gives **any explicit submit instruction naming a changeset** — "review and
submit {CL name or ID}", "submit {CL}", "review and merge {branch/PR}" — execute this
workflow. The long phrase is sufficient, never required: Step 6 already treats any
per-changeset submit instruction as the approval, and the review it buys runs either way.
(A bare "submit" naming no changeset: ask which one, then proceed.)

---

## Mandatory Workflow

### 1. Organize the changeset

**Before any review**, ensure the work is one properly named, described changeset.

**Perforce**

1. **Create a named changelist (at task START, not submit time)**:
   - Start every P4 task in a **new named CL**; use the default change only if the user asks.
     The default change usually holds the human's own WIP — never sweep it wholesale.
   - Create the CL from **Bash** with a heredoc. A PowerShell pipe into `p4 change -i`
     prepends a UTF-8 BOM and fails with `Unknown field name`:

     ```bash
     p4 change -i <<'EOF'
     Change: new
     Description:
     	Title - brief summary
     EOF
     ```

     (Description lines in a change spec are TAB-indented.)
   - **Never create a CL via `p4 change -o | p4 change -i`**: the new-CL form pre-fills
     `Files:` with EVERY default-changelist file and sweeps them all into the new CL.
   - **Verify right after creating**: run `p4 opened -c {new_CL}`; evict any stray with
     `p4 reopen -c default {file}`. Pull task files from default **selectively** via
     `p4 reopen -c {new_CL} {files...}`.
2. **Verify the changelist**: `p4 describe {CL_ID}` — all intended files included, no
   unrelated files mixed in.
3. To update the description of an **existing** CL safely:
   `p4 change -o {CL_ID} > {scratch}/cl.spec` → edit the spec (keep the `Files:` section
   untouched — the existing-CL form lists only that CL's files, so no sweep) →
   `p4 change -i < {scratch}/cl.spec` from **Bash** (never a PowerShell pipe — BOM). Don't
   use bare `p4 change {CL_ID}`: it opens an interactive editor. See Step 7 for the
   `{scratch}` path note.

**git**

1. A named branch created at task START; the changeset under review is the branch's diff
   against its merge-base with the default branch.
2. Commit titles follow the same title conventions as the description below; a PR carries
   the full description as its body.

**Describe the changeset** (CL description / PR body — the same shape either way):

- The first line is the **title**: a brief, specific summary. If the project's CLAUDE.md /
  AGENTS.md defines a title tag convention (e.g. a `[JobFamily][Name]` prefix), follow it —
  **if unsure what the tags should be, ASK the user before proceeding**.
- Below the title, write a **body** that helps teammates understand the change at a glance:

  ```
  Title - Brief summary of the change

  ## What
  - Bullet list of concrete changes (new files, modified systems, config tweaks)

  ## Why
  - Motivation: what problem this solves, what feature it enables, or what phase/plan it advances
  - Link to relevant design doc or plan if one exists
  - **If the changeset implements a spec or ticket, LINK IT here** as a
    `Ticket: .scratch/<slug>/issues/<NN>-<slug>.md` line (path or tracker ref) —
    this is what the Spec axis reviews against (see Step 3). If the user explicitly
    skipped the workflow, carry `Workflow: skipped (<reason>)` instead (see the
    agentic-workflow skill's pre-implementation gate; agent changesets only — humans
    are exempt from this convention)

  ## Notes (optional)
  - Anything reviewers or teammates should know: migration steps, known limitations,
    dependencies on other changesets, areas that need testing, etc.
  ```

- **English only (Perforce)**: the ENTIRE description (title, body, Review Record) must be
  English/ASCII — non-English text renders as unreadable garbage on some P4 clients and CI
  systems. This includes punctuation: use ASCII '-' in the Review Record's
  'Verdict:' lines, never an em-dash.
- **Keep it scannable**: prefer bullets over paragraphs.
- **Be specific**: name the classes, systems, and files that changed — don't just say
  "updated code".
- **Include context**: teammates who didn't write the code should understand the changeset
  without reading every file.

---

### 2. Pin the change

Resolve the changeset **before** spawning anything. A bad ID, an already-published
changeset, or an empty diff must fail here, in front of the user — not inside two parallel
sub-agents.

**Perforce**

```bash
p4 opened -c {CL_ID}        # must list files; empty means not pending -> stop and ask
p4 describe -s {CL_ID}      # description + file list (no diff body for a pending CL)
p4 diff -c {CL_ID} //...    # the actual diff the reviewers read
```

> [!CAUTION]
> `p4 describe` alone prints **no diff body** for a pending changelist. It would hand a
> reviewer filenames and nothing to review, and the pass would come back clean because there
> was nothing in it.

If a name was given instead of a number, find the CL first (`p4 changes -s pending -u <user>`)
and confirm it with the user before proceeding.

**git**

```bash
git rev-parse {fixed-point}          # the base must resolve; else stop and ask
git diff {fixed-point}...HEAD        # three-dot: compare against the merge-base
git log {fixed-point}..HEAD --oneline
```

An empty diff stops here, in front of the user.

---

### 3. Identify the spec source

Look for the originating spec, in this order:

1. The `Ticket:` line in the changeset description (`.scratch/<slug>/issues/<NN>-<slug>.md`
   or a tracker ref) — see the project's issue-tracker doc.
2. Issue references in the commit messages (git: `#123`, `Closes #45`).
3. A path the user passed as an argument.
4. A design or plan doc under the project's docs tree matching the feature or system name.

If nothing is found, ask the user where the spec is. If they say there isn't one — or the
description carries `Workflow: skipped (<reason>)` — the **Spec** axis is skipped and the
report says so. A missing spec is a reported fact, never a silently-dropped axis.

---

### 4. Spawn both axes in parallel

The review engine is **`myst-dev-kit:code-review`** — always cite it namespaced; the bare
name resolves to a different, official plugin. It defines the two axes (Standards + Spec),
the standards sources, the Fowler smell baseline, and the sub-agent briefs. Follow its
process, with these deltas:

- **The diff is the pinned diff from Step 2** — its own git commands for a git changeset;
  the `p4 diff -c {CL_ID} //...` output plus file list for a Perforce one.
- **The spec source is Step 3's.**
- **Build each brief per the engine's own instructions** — including pasting the smell
  baseline into the Standards brief (a generic sub-agent has no other access to it).
- **Each axis brief additionally requires**: cite file:line; categorize findings
  BLOCKING / WARNING / INFO; under 400 words; end with a single line of the form
  `Verdict: GREEN | WARNING | BLOCKING`.

Two axes, always, whatever the changeset contains. Prose is **not** reviewed as a third
axis: reviewing what a document *proposes* is not this protocol's job; checking that it does
not contradict what shipped is the Docs-alignment preflight (Submission Step).

> **Effort barbell:** reviewing is judgment work — launch reviewers at full model/effort,
> never downgraded to save tokens.

> [!IMPORTANT]
> **Supply the facts the reviewer cannot observe** — binary/serialized assets, a live editor
> or service, project tooling it cannot run. Read those yourself and put them in the brief:
> property values, compile status, node or schema shapes, the before/after of a binary you
> diffed. Observed values, not your conclusions from them; mark which you inferred.

On a **re-review**, add only what changed: which findings you fixed, which you declined and
why, and whether you adopted the reviewer's prescription. Re-run **only the axis whose
BLOCKING findings you addressed** — an axis you did not act on has nothing to re-verify, and
re-running it invites new findings on unchanged code. Do not resend the whole changeset as
if the first pass had not happened.

---

### 5. Aggregate — do not merge

Present both reports under `## Standards` and `## Spec`, verbatim or lightly cleaned.

> [!CAUTION]
> **Never merge or re-rank findings across the two axes.** A change can pass one and fail the
> other: code that follows every convention while implementing the wrong thing passes
> Standards and fails Spec; code that does exactly what the ticket asked while breaking the
> project's conventions does the reverse. A blended verdict lets the passing axis hide the
> failing one — which is the whole reason the axes are separate.

End with a one-line summary: findings per axis, and the worst issue **within each axis**.
Do not name a single winner across axes.

The changeset's overall verdict for Step 6 and Step 7 is the **worst of the two** — that is
a gate threshold, not a ranking, and both axis verdicts are still recorded separately.

Then present the options:

```markdown
1. **Submit Now** - proceed (only if no BLOCKING on either axis)
2. **Fix & Re-review** - address findings, re-run only the affected axis
3. **Fix Specific** - name the findings to fix
4. **Defer** - keep the review, come back later
```

#### Fixes that never cost a re-review

At any severity, BLOCKING included: a missing Review Record block, a missing or wrong title
tag required by the project's convention, an EOL flip, non-ASCII in the description, or a
missing `Ticket:` / `Workflow: skipped (<reason>)` line **whose ticket or user decision
already exists**. Creating the ticket and making the skip decision are never on this list.

**The list is closed, and closed on a principle**: every item is a description-or-formatting
fix that *cannot change behaviour*, and every item has a validator behind it. Findings from
project validators that touch file content stay OFF the list — those fixes can break things.
Anything not on this list, including a wrong claim in the description body, is a real finding.

**You skip the reviewer pass, never the gate.** Fix it and return to Step 6: the user's
submit decision and the Step 7 Review Record both still apply.

#### The fix answers the finding and nothing else

Implement the finding, not the reviewer's prescription — it was written without running
anything. If you adopt theirs, say so in the re-review brief so the next pass knows where to
look. **Explanation goes in the brief, not the artifact**: a fix does not re-argue the design
in rationale, comments, or doc prose. New prose is new reviewable surface, and prose is where
the review churn was measured to live.

#### Stopping rule

**A round that produces no BLOCKING finding is the last round.** Record the remaining WARNING
and INFO items in the Review Record with their disposition (`[ACCEPTED]` / `[DEFERRED]`) and
go to Step 6. Do not spend another pass to drive a WARNING-only report to silence — on prose
especially, that pass reliably produces a fresh WARNING-only report, and the loop has no
natural end. Scope also freezes when the review starts: a file the fix genuinely needs is
part of this changeset, and unrelated work that arrives mid-review gets its own changeset.

---

### 6. Wait for User Decision

**DO NOT** proceed with any action until the user explicitly chooses an option.

- If user says "submit" or "1" → Proceed with publication (only if no BLOCKING issues)
- If user says "fix" or "2" → Address issues — the fix answers the finding and nothing else
  (Step 5) — then re-review only the affected axis
- If user specifies issues → Fix only those, then re-review only the affected axis
- If user says "defer" → Acknowledge and await further instructions

> [!CAUTION]
> **HARD RULE — No direct submit after fixing a BLOCKER.**
> After applying a fix in response to a **BLOCKING** finding, you MUST re-run the axis that raised it (Step 4) and present a new aggregate (Step 5) before submitting — except for the closed list in Step 5, whose fixes cannot change behaviour. Fixes can introduce new issues, and a BLOCKING verdict is that reviewer's judgement that the changeset is not safe to ship — only its own re-verdict clears that, never "the fixes look obviously correct."

> [!CAUTION]
> **HARD RULE — a changeset implementing a `ready-for-human` ticket is a process error. Never publish it.**
> `ready-for-human` means a human implements that ticket, so a changeset against one should not exist. If you are holding one anyway, do not publish it in any mode — attended, unattended, or goal. After the review pass, park it instead — the shared history stays untouched:
>
> - **Perforce**: `p4 shelve -c <CL>` — the files STAY OPEN locally (exclude that CL from any later reconcile/submit-all; re-shelve with `-f` if its files change again).
> - **git**: leave the work on its branch; never merge it or open its PR yourself.
>
> Append `GATED-SHELVED: process error - agent implemented a ready-for-human ticket` to the description (alongside its `Ticket:` line) and log it in your final report. The human's own review-and-publish IS the approval.
>
> **The label is user-owned.** Only the user changes a `ready-for-human` ticket's `Status:`, and that means to ANY value, not just `ready-for-agent` — every gate matches the current string and nothing records the previous one, so setting `claimed` silences them all just as effectively and leaves no trace. An agent that believes a ticket is mislabeled says so and stops; it never rewrites the field and proceeds. An agent that could grant itself a workable state could then submit under a goal-mode authorization in the same run — this gate is the reason that path is closed.
>
> **Shipped-but-unverified is not this case.** Work that lands and still needs a human check is `resolved` plus an `Outstanding:` line, and its changeset publishes normally.

> [!CAUTION]
> **HARD RULE — every publish is human-gated unless the run is verifiably in goal mode.**
> Publishing — `p4 submit`, or merging to the shared branch — is the one irreversible, team-wide-blast-radius action in this pipeline. Ticket status governs **verification**, never **submit authority**: `ready-for-agent` answers "can the agent verify every required test case", not "may the agent publish to `main`".
>
> Outside goal mode, NO standing or batch authorization covers a publish — not "do all these changesets and submit them", not a `ready-for-agent` ticket, not a GREEN review, not "you already approved the last four". One approval covers one changeset.
>
> **What counts as that one approval.** An explicit instruction from the user that names publication for **that changeset, by ID** — "review and submit 1970", "submit 1970", "merge PR 42" — IS the Step 6 approval for it. Do not re-ask when the review returns **GREEN** and **no preflight validator warned**: that is precisely the outcome they authorized, and asking again trains everyone to read the gate as a formality. This defines the approval the rule already requires; it grants nothing the user did not say, about no changeset they did not name.
>
> Re-ask anyway on any of the following — the instruction authorized the changeset *as reviewed clean*, and each of these is something the user did not know when they asked:
>
> - the verdict is anything but GREEN (WARNING included — non-blocking is not nothing);
> - any preflight validator failed or warned;
> - the user never named that changeset ID (a batch, "the rest of them", one you picked yourself);
> - the changeset's contents grew after they asked (files added, scope widened);
> - the ticket is `ready-for-human` (that changeset should not exist — park it, per the rule above), or a fix was applied during the run — both rules above outrank this one and force the ask.
>
> - **Goal mode is identified by the harness's own signal, never by inference.** A `/goal` run injects a session-scoped Stop-hook notice into context — *"A session-scoped Stop hook is now active with condition: `<condition>` ... do not pause to ask the user what to do"* — and carries a `goal_status` attachment naming that condition. **If that notice is not in your context, you are not in goal mode.** Not "this looks like an unattended batch", not "the user is clearly AFK", not "the task list implies it". If you find yourself reasoning toward the exemption, that is the tell that you do not have it.
> - **Why the exemption exists**: goal mode instructs you not to pause for the user while a Stop hook blocks stopping. Without the carve-out, a publish inside a `/goal` run pits the policy (stop and ask) against the run (don't pause, can't stop) — the run stalls with nobody there to answer, or the gate degrades into a rubber stamp.
> - **What the signal does and does not authorize**: it establishes only that *the human is not there to answer*. The goal condition is arbitrary user text, so treat the publish authorization as covering work plainly within that condition's scope. A goal about fixing bugs does not authorize publishing an unrelated refactor you happened to finish along the way; park that one.
> - **Attended, not goal mode** → stop here and ask, per changeset — unless the user's own instruction already named this changeset for publication and the review came back GREEN with a clean preflight, per "What counts as that one approval" above. This is Step 6 as written above.
> - **Unattended, not goal mode** → after the review pass, park the changeset instead of publishing (Perforce: `p4 shelve -c <CL>`, same mechanics and reconcile caveats as the rule above; git: leave on branch, no merge/PR), append `GATED-SHELVED: awaiting human review` to the description, report it in your final summary, and move on to other work. Never publish.
> - **Goal mode** → a `ready-for-agent` changeset may publish under the goal authorization once the review passes. A `ready-for-human` changeset still does NOT — that rule is unconditional and outranks this one, and the label that would lift the bar is one only the user can apply.
>
> Precedent for why the signal must be external: a retired session-start hook here once printed `mode=live` from a state directory that had already been deleted. A mode the agent reads from its own reasoning is not a mode.

---

### 7. Record the Review in the Changeset Description

**After the user approves publication and before any preflight/submit**, append a **Review
Record block** to the changeset description — the CL description in Perforce; the PR body
(or the final commit message body when the flow has no PR) in git. If the project runs a
post-submit audit, this block is what it looks for; either way, teammates reading the
changeset can't see the review outcome without it.

**Format** (appended after the What/Why/Notes body):

```
## Review
Standards: myst-dev-kit:code-review sub-agent - Verdict: WARNING (2 passes)
Spec:      sub-agent vs .scratch/foo/issues/03-bar.md - Verdict: GREEN
Docs-alignment: aligned
Findings:
- [FIXED] BLOCKING Standards SomeFile.cpp:88 - one-line description
- [ACCEPTED] WARNING Standards - magic number in threshold
- [DEFERRED] INFO Spec - criterion 4 deferred to ticket 06
```

**Rules:**

- One line per **axis**, always both: `Standards:` and `Spec:`, each with the sub-agent that
  ran it and its own `Verdict:`. The verdict shown is the **final pass** verdict; note the
  pass count if more than one. The axes are recorded separately for the same reason they
  are reviewed separately — a blended line lets the passing axis hide the failing one.
- A skipped Spec axis is recorded, never omitted: `Spec: skipped (no linked source)`.
- A changeset containing prose also carries one `Docs-alignment:` line — `aligned`, or what
  was contradicting and how it was fixed. It is a preflight result, not an axis: no severity,
  no verdict, and it never counts as a review pass.
- **Generate that line — do not type it, and write it last.** It is the one field in the
  description that cannot be true until the review ends, and a multi-pass review will
  invalidate a hand-written one every time a pass lands. Keep the verdicts in a list and
  derive count, sequence and headline from it, so they cannot disagree with each other:

  ```python
  VERDICTS = ["BLOCKING", "WARNING", "GREEN"]   # append each pass as it lands
  DESC = (DESC.replace("__N__", str(len(VERDICTS)))
              .replace("__SEQ__", ", ".join(VERDICTS))
              .replace("__FINAL__", VERDICTS[-1]))
  assert "__" not in DESC, "unfilled template token"
  ```

  Then regenerate immediately before publishing. The same applies to **any assertion about
  the changeset's own content**, not only the numeric ones — byte counts, file counts and
  finding tallies, but equally "verified by diff", "zero non-comment lines changed", or a
  quoted snippet of what one of its files now says. Re-derive from the live artifact at
  submit time, or leave it out. Anything measured at review time and frozen into a
  description is wrong by submit time more often than not, and **the review's own fixes are
  what make it wrong** — which is why the prose ones rot hardest in exactly the changesets
  that took the most rounds.
- **Inline run** (no Agent tool available): the axes still run — work through
  `myst-dev-kit:code-review`'s briefs yourself, one axis at a time, and **record each axis
  verdict before any submit step**. Say so, per axis:
  `Standards: self (inline, myst-dev-kit:code-review brief) - Verdict: GREEN`. If the axes
  did not actually run, the honest line is `Standards: self - Verdict: ... (quick review)` —
  never assert a rubric-backed review that did not happen.
- `Findings:` one-liners only, each prefixed with its disposition — `[FIXED]` (fixed before
  submit), `[ACCEPTED]` (publishing with it), `[DEFERRED]` (tracked for later) — then its
  severity and **which axis raised it**.
- Cap at ~6 finding lines; summarize overflow as
  `- ...and N more INFO items (see review transcript)`.
- Write this block on **every** changeset that goes through this protocol — it's cheap and
  it keeps the review outcome visible.

**Mechanics**:

- **Perforce** (safe description update — see Step 1 for the pitfalls):

  ```bash
  p4 change -o {CL_ID} > {scratch}/cl.spec   # existing-CL form: Files: lists only this CL, no sweep
  # append the block to the Description field (TAB-indent every line)
  p4 change -i < {scratch}/cl.spec           # from Bash — never a PowerShell pipe (BOM)
  ```

  Use a temp path both Bash and any native-OS tool resolve identically for `{scratch}`
  (e.g. the session scratchpad dir). On Windows, MSYS `/tmp` is invisible to native tools
  (python, editors) — a spec written there can't be edited by them and you'll silently
  re-submit the old description.

- **git**: `gh pr edit {PR} --body-file {scratch}/body.md` for a PR; for a no-PR flow,
  amend the block into the final commit's message body before pushing.

---

## Submission Step

After the Review Record block is in place:

1. **Run the project's preflight validators, if it defines any** — the project's CLAUDE.md /
   AGENTS.md or scripts directory names them. On any warning or non-zero exit: report it,
   fix, and re-run before publishing. A project with none defined has nothing to run here —
   say so and move on.
2. **Docs-alignment check** — when the changeset contains any `.md`/`.txt`. Spawn ONE
   general-purpose sub-agent with this brief:

   ```
   Alignment check on changeset {ID} - NOT a review.

   Prose in this changeset: {md/txt file list}
   Code/assets in this changeset: {everything else, or "none - docs-only changeset"}
   Diff: {the pinned diff command from Step 2}

   Report ONLY contradictions between what the prose claims and what is
   true: a doc describing behaviour the code in this changeset does not have; a
   plan whose phase status is stale against what shipped; two documents in
   this changeset disagreeing; a documented instruction that the diff invalidates.

   Do NOT critique the design, the writing, the structure, or anything the
   document proposes. Do NOT suggest improvements. If nothing contradicts,
   say "aligned" and stop. Under 200 words. No verdict line.
   ```

   Report each contradiction, fix it, and re-run the check — the same loop as any other
   preflight item. It produces **no severity and no verdict**: it is not a review pass, it
   does not appear as an axis in the Review Record, and it never starts a review round.
   A changeset that reaches here with prose and no contradictions records
   `Docs-alignment: aligned` in the Review Record.

   Why a preflight and not an axis: a reviewer asked to critique prose always finds
   something, which is how the worst subject in the round measurement reached 19 rounds.
   A reviewer asked whether two things contradict either finds a contradiction or does not.
   The question is closed, so the loop terminates.
3. **EOL flips (Perforce on Windows)**: even where an edit-time hook repairs mixed line
   endings, a file already flipped wholesale to LF slips past it. When a diff looks
   absurdly large, `p4 diff -dl` collapses it to the real change. To fix it, restore CRLF
   in the working file itself - it stays open and the edit survives. Do not reach for
   `p4 sync -f` (it skips open files and reports `up-to-date`) or `p4 revert` (it discards
   the edit). Then re-diff and review that.

   > **A quiet submit is not evidence any audit passed**, only that nothing blocked you —
   > post-submit audits exit 0 by design and report after the fact. Do not cite silence at
   > submit time as a clean audit.
4. **Publish**:
   - **Perforce**: `p4 submit -c {CL_ID}`. Confirm with `p4 changes -m 1 -s submitted` and
     report the final submitted CL number (pending CLs are renumbered on submit).
   - **git**: push the branch and open/merge the PR per the project's flow; report the PR
     URL or merge SHA.
5. Note any post-submit verification needed.

---

> [!IMPORTANT]
> **Always wait for explicit user approval before publishing.**
> The user has final authority on whether to submit, fix, or defer.
