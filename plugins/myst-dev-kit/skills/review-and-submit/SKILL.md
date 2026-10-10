---
name: review-and-submit
description: "MANDATORY protocol when the user says 'review and submit' (any variant) or before publishing ANY changeset — a Perforce changelist submit, or a git merge/PR against the shared branch. Changeset organization, two-axis review (Standards + Spec), VCS-specific descriptions with review evidence, preflight validators, and human-gated publication."
---

# Review and Submit Protocol

A **changeset** is one named, described, reviewable unit of work: a Perforce changelist or a
git branch/PR. Rules are here; command forms and traps are in
[VCS-MECHANICS.md](VCS-MECHANICS.md). Team specifics (audit checks, tag vocabularies, job
families) live in the project's own docs.

Read [LOCAL-INTEGRATION](../agentic-workflow/LOCAL-INTEGRATION.md) before selecting
VCS-specific dependencies. Required copy dependencies: agentic-workflow and
code-review, plus pr for Git targets or p4-description for Perforce targets.
Check the selected local entries before dependent work. A nested Git mirror does
not change a Perforce target. Never invoke or load the Git-only pr workflow for P4.

## Source-control sync (applies at all times)

After modifying, creating, or deleting any tracked file, open it in version control
(`p4 edit` / `p4 add` / `p4 delete`) BEFORE presenting results; never batch checkouts to
the end of a session. git: work on a named branch created at task start, never on the
default branch. During an active review, a file the changeset did not already contain goes
in a NEW changeset unless the fix itself requires it.

## Trigger

Any explicit submit instruction naming a changeset ("review and submit {ID}", "submit
{CL}", "review and merge {PR}"). A bare "submit" naming no changeset: ask which one.

---

## 1. Organize the changeset

One named changeset, created at task START (VCS-MECHANICS); use the default change only if
the user asks, and never sweep it wholesale. Verify the file list before review: every
intended file in, nothing unrelated mixed in.

**Description:** use the target's Myst formatter, with the scope and existing
source pointer. For Git, select [pr](../pr/SKILL.md); for Perforce, select
[p4-description](../p4-description/SKILL.md). Use the host's Myst namespace or the
full installed Myst entry path. Keep its three sections: Summary / Evidence /
Merge Danger for Git, or Summary / Evidence / Submit Risk for P4.

Supply [DESCRIPTION-EVIDENCE.md](DESCRIPTION-EVIDENCE.md) with the formatter brief.
It owns this protocol's evidence handoff and compatibility checks. Initial drafts
state which reviews and checks have not run. After review, Step 7 supplies the
actual final results; a formatter never supplies review or publication authority.

- Explain the change, its reason, evidence, and risk briefly. Use the smallest
  useful visual or ASCII sketch the formatter permits; link details rather than
  duplicating long histories. Keep essential findings and verification limits
  even when a longer description is needed. There is no separate narrative cap.
- **Owner reports verbatim.** Quote the user's verdict without expanding its
  mechanism, values, or scope. Record its limits alongside.
- **Claims of work done carry evidence.** State an observed result with its source;
  otherwise label it unverified. Do not turn planned checks into completed work.
- Perforce: retain the related submitted-history title tags and English/ASCII
  text throughout. Do not infer tags from the current tool account.

---

## 2. Pin the change

Resolve the changeset before spawning anything: a bad ID, a published changeset, or an
empty diff stops here, in front of the user. Produce the file list and the actual diff the
reviewers read (VCS-MECHANICS: a pending Perforce CL has no diff body in `p4 describe`; an
added file has no base diff). Pin the requested workspace, shelf, or submitted
version; include complete added and removed content. Reuse supplied immutable
captures only as those captures. Stale, incomplete, or uncheckable evidence stops
dispatch; a filename list is not a reviewed diff.

---

## 3. Identify the spec source

In order: the `Ticket:` line; issue references in commit messages; a path the user passed;
a design or plan doc matching the feature. Nothing found: ask. No spec, or `Workflow:
skipped`: the Spec axis is skipped and the report says so, never silently.

---

## 4. Spawn both axes in parallel

Read the local **`myst-dev-kit:code-review`** entry (or its full installed path in
copy hosts), then follow its source and local input mapping. Do not use an
ambiguous bare engine name or bypass the wrapper. It defines the two axes,
standards sources, smell baseline, and briefs. Deltas:

- The diff is Step 2's; the spec is Step 3's; paste the smell baseline into the Standards
  brief.
- Each brief: cite by anchor (file plus a symbol, heading or short quoted phrase; a line
  number only as a trailing `~:NNN` hint), naming the artifact and revision each finding
  was read from; categorize BLOCKING / WARNING / INFO; under 400 words; end with one line
  `Verdict: GREEN | WARNING | BLOCKING`.
- Each brief states: a reviewer reports only; it never submits, shelves, pushes, merges, or
  edits files. Publication happens in the main session through Steps 6-7, nowhere else.
- Each brief states the prose-fix rule (Step 5): for a false or unverifiable claim in the
  description, a ticket, or a doc, prescribe strip first, downgrade second, and a corrected
  value only when derived from a command the fix will show.
- Supply the facts the reviewer cannot observe (binary assets, a live editor, tooling it
  cannot run) as observed values in the brief; mark which you inferred.
- Full model and effort; never downgrade reviewers to save tokens.

Keep both axis results visible, including a confirmed Spec skip. Prose is not a third axis: what a document proposes is not reviewed;
whether it contradicts what shipped is the Docs-alignment preflight (Submission step).

**Re-review:** brief only what changed (findings fixed, findings declined and why, whether
you adopted the reviewer's prescription) and re-run only the axis whose BLOCKING findings
you addressed.

---

## 5. Aggregate, then fix

Present both reports under `## Standards` and `## Spec`. Never merge or re-rank findings
across axes and never name a single winner; end with findings per axis and the worst issue
within each. The gate verdict for Steps 6-7 is the worst of the two; both stay recorded.

**BLOCKING on either axis:** fix it now, by the rules below, and re-run the affected axis
without waiting for the user; a finding you decline goes in the re-review brief with the
reason, and that axis re-runs on it; a BLOCKING re-raised on a finding you declined goes to
the user as a Step 6 decision, with your reason and the reviewer's, never another re-run.
Report what was fixed, declined, and why when the round ends. **GREEN on the first pass, no fix applied, and the user named this changeset by ID:**
that is the Step 6 approval; go to Step 7 (a preflight warning in the Submission step still
re-asks). **Otherwise, WARNING or GREEN alike, any fix applied included:** stop and offer
the options: submit now; fix and re-review the affected axis; fix named findings only and
re-review the affected axis; defer. Recommend one and say why.

### Fixing a false claim: strip, downgrade, derive

Stop at the first rung that applies:

1. **Strip.** A file already owns the fact (count, status, quoted line, CL number): delete
   the sentence; point at the owner if needed.
2. **Downgrade.** The sentence asserts work done ("verified in PIE", "criteria MET", "no
   callers anywhere") and nothing else records that state: make it true by weakening it
   ("not verified", "checked with `<command>`: `<result>`"). Never strengthen.
3. **Derive.** Correct the value only from a command run now, shown next to it, and
   regenerated before submit.

Never answer a wrong count with more counts: a corrected assertion is the next pass's
target. A stripped or downgraded one ends the loop only once you re-read what asserts
things about the text you changed (labels, headings, summaries, the description) and fix
those by the same ladder.

### Fixes that never cost a re-review

At any severity: rendering already verified review results into Evidence without
changing their meaning; a missing or wrong project title tag; an
EOL flip; non-ASCII in the description; a missing `Ticket:` / `Workflow: skipped` line whose
ticket or decision already exists; deleting a sentence from the description. The list is
closed: nothing on it can change behaviour or add reviewable content. Off it: creating the
ticket or making the skip decision; deletions inside tickets or docs; validator findings
that touch file content. Anything else, a wrong claim in the description body included, is
a real finding. You skip the reviewer pass, never the gate.

### Fix discipline

Implement the finding, not the reviewer's prescription; if you adopt theirs, say so in the
re-review brief. Explanation goes in the brief, never into comments or doc prose. A round
with no BLOCKING finding is the last round: record remaining WARNING and INFO items as
`[ACCEPTED]` / `[DEFERRED]` and go to Step 6. Scope freezes when review starts.

---

## 6. Wait for the user's decision

Reached with a GREEN or WARNING aggregate (Step 5 fixes BLOCKING first), or with a BLOCKING
re-raised on a finding you declined (submit is then not an option). Unless the
Step 5 first-pass approval applies, do not act until the user chooses: submit, fix (Step 5,
re-run the affected axis), named findings only, or defer.

**No direct submit after fixing a BLOCKER.** Re-run the axis that raised it and present the
new aggregate here first, except for the closed list in Step 5. Only the reviewer's own
re-verdict clears its BLOCKING, and the user still decides on the result.

**A changeset implementing a `ready-for-human` ticket is never published**, in any mode.
Park it (VCS-MECHANICS), append `GATED-SHELVED: process error - agent implemented a
ready-for-human ticket` to the description, and report it. Only the user changes that
ticket's `Status:`, to any value; an agent that thinks it is mislabeled says so and stops.
Shipped-but-unverified is a different case: `resolved` plus an `Outstanding:` line, published
normally.

**Every publish is human-gated unless the run is verifiably in goal mode.** Ticket status
governs verification, never submit authority. One approval covers one changeset; no batch or
standing instruction covers a publish.

- **The approval** is the user's instruction naming publication for that changeset by ID
  ("submit 1970", "merge PR 42"). Do not re-ask when the review is GREEN on the first pass,
  no fix was applied, and no preflight warned.
- **Re-ask** when: the verdict is not GREEN (WARNING included); a preflight failed or
  warned; the user never named this ID; the contents grew after they asked; a fix was
  applied during the run.
- **Goal mode** is identified only by the harness's own signal: the session-scoped
  Stop-hook notice in context plus its `goal_status` attachment. Not in your context: you
  are not in goal mode. Under it, a `ready-for-agent` changeset within the goal's scope may
  publish once the review passes; unrelated work is parked.
- **Attended, not goal:** stop and ask, per changeset, unless the approval above applies.
  **Unattended, not goal:** park the changeset, append `GATED-SHELVED: awaiting human
  review`, report it, move on. Never publish.

---

## 7. Put verified results in Evidence

After the Step 6 decision, give the selected formatter the pinned scope, final
axis reports (or confirmed skip), finding dispositions, existing detail references,
owner acceptance and its limits, and actual preflight results available so far.
Follow [DESCRIPTION-EVIDENCE.md](DESCRIPTION-EVIDENCE.md). Keep results inside
Evidence and remaining risks inside Merge Danger / Submit Risk. Do not append a
separate Review heading or pass-count record.

Keep detailed reviewer identity, pass history, artifact/revision anchors, and
finding dispositions in the actual review evidence. Link existing durable detail
when useful; if it is unavailable, preserve essential unresolved findings briefly
in the body. Never manufacture a new report or review verdict just for formatting.
A missing review is not a formatting repair and cannot become GREEN.

Re-derive final results from the actual reports immediately before publication.
Checks not yet run remain explicitly unverified. Preflight can change readiness;
update Evidence from its real results and follow the existing re-approval rules
if a warning, failure, fix, or scope change occurs. Apply the final description
through VCS-MECHANICS only within the user's authorized scope.

---

## Submission step

1. **Project preflight validators**, if any are defined (the project's CLAUDE.md /
   AGENTS.md or scripts directory names them): on a warning or non-zero exit, report, fix,
   re-run. None defined: say so.
2. **Docs-alignment check**, when the changeset contains any `.md`/`.txt`. Spawn ONE
   general-purpose sub-agent:

   ```
   Alignment check on changeset {ID} - NOT a review.

   Prose in this changeset: {md/txt file list}
   Code/assets in this changeset: {everything else, or "none - docs-only changeset"}
   Diff: {the pinned diff from Step 2}

   Report ONLY contradictions between what the prose claims and what is true: a doc
   describing behaviour the code in this changeset does not have; a plan whose phase
   status is stale against what shipped; two documents in this changeset disagreeing;
   a documented instruction that the diff invalidates.

   Do NOT critique the design, the writing, the structure, or anything the document
   proposes. Do NOT suggest improvements. If nothing contradicts, say "aligned" and
   stop. Under 200 words. No verdict line.

   You report only: never edit files and never run any version-control write command.
   ```

   Fix each contradiction by the Step 5 ladder and re-run. No severity, no verdict, never a
   review round.
3. **EOL flips** (Perforce on Windows): an absurdly large diff is usually a wholesale LF
   flip; fix per VCS-MECHANICS, re-diff, review that.
4. **Refresh and validate the final description.** Update Evidence with actual final
   review and preflight results. Run the project description validator against that
   final text; repeat it if the description changes. Confirm compatibility with
   required consumers as described in DESCRIPTION-EVIDENCE. A validator warning
   or failure follows the existing report/fix/re-run and Step 6 approval rules.
   If preflight changed reviewed content, re-pin it and follow Step 5 for the
   affected review axis before publication.
5. **Publish** (VCS-MECHANICS) only with the required decision and passing preflight;
   report the final submitted number or merge SHA. A quiet submit is not evidence
   any audit passed.
6. Note any post-submit verification needed.

The user has final authority on submit, fix, or defer. Always wait for explicit approval
before publishing.
