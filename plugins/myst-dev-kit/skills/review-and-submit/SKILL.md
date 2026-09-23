---
name: review-and-submit
description: "MANDATORY protocol when the user says 'review and submit' (any variant) or before publishing ANY changeset — a Perforce changelist submit, or a git merge/PR against the shared branch. Changeset organization, two-axis review (Standards + Spec) via myst-dev-kit:code-review sub-agents, Review Record, preflight validators, human-gated submit."
---

# Review and Submit Protocol

A **changeset** is one named, described, reviewable unit of work: a Perforce changelist or a
git branch/PR. Rules are here; command forms and traps are in
[VCS-MECHANICS.md](VCS-MECHANICS.md). Team specifics (audit checks, tag vocabularies, job
families) live in the project's own docs.

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

**Description** (CL description / PR body, same shape either way):

```
Title - brief, specific summary (follow the project's title-tag convention; unsure: ASK)

## What

- Concrete changes: which files, systems, config

## Why

- The problem solved or the plan step advanced; link the design doc if one exists
- Ticket: .scratch/<slug>/issues/<NN>-<slug>.md   (what the Spec axis reviews against)
  or, if the user skipped the workflow: Workflow: skipped (<reason>)   (agent changesets only)

## Notes (optional)

- Migration steps, known limitations, dependencies, what needs testing
```

- **Point, never restate.** Explain the change so a teammate understands it without reading
  every file, but never copy a fact one of the files owns: counts, tallies, "all N",
  "both", version strings, CL numbers, quoted snippets, "verified by diff", what a file
  "now says". Name the file instead.
- **Owner reports verbatim.** A user's one-word verdict ("works", "5 yes") is quoted, never
  expanded into mechanism, values, or scope. Record its limits alongside.
- **Claims of work done carry their evidence.** "Swept", "verified", "no X exists" appear
  only next to the command and result; otherwise leave the sentence out.
- **Cap: the body before the Review Record fits in about 150 words**, one line per bullet.
  Over the cap means the description is restating what the files own, or the changeset is
  too big; fix whichever it is, never the cap.
- Perforce: English/ASCII only, typographic punctuation and the Review Record included (ASCII
  `-` in Verdict lines). Bullets over paragraphs; name classes and files.

---

## 2. Pin the change

Resolve the changeset before spawning anything: a bad ID, a published changeset, or an
empty diff stops here, in front of the user. Produce the file list and the actual diff the
reviewers read (VCS-MECHANICS: a pending Perforce CL has no diff body in `p4 describe`; an
added file has no diff at all).

---

## 3. Identify the spec source

In order: the `Ticket:` line; issue references in commit messages; a path the user passed;
a design or plan doc matching the feature. Nothing found: ask. No spec, or `Workflow:
skipped`: the Spec axis is skipped and the report says so, never silently.

---

## 4. Spawn both axes in parallel

The engine is **`myst-dev-kit:code-review`** (always namespaced; the bare name is a
different plugin). It defines the two axes, the standards sources, the smell baseline, and
the briefs. Deltas:

- The diff is Step 2's; the spec is Step 3's; paste the smell baseline into the Standards
  brief.
- Each brief: cite file:line, naming the artifact and revision each finding was read from;
  categorize BLOCKING / WARNING / INFO; under 400 words; end with one line
  `Verdict: GREEN | WARNING | BLOCKING`.
- Each brief states: a reviewer reports only; it never submits, shelves, pushes, merges, or
  edits files. Publication happens in the main session through Steps 6-7, nowhere else.
- Each brief states the prose-fix rule (Step 5): for a false or unverifiable claim in the
  description, a ticket, or a doc, prescribe strip first, downgrade second, and a corrected
  value only when derived from a command the fix will show.
- Supply the facts the reviewer cannot observe (binary assets, a live editor, tooling it
  cannot run) as observed values in the brief; mark which you inferred.
- Full model and effort; never downgrade reviewers to save tokens.

Two axes, always. Prose is not a third axis: what a document proposes is not reviewed;
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

At any severity: a missing Review Record block; a missing or wrong project title tag; an
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

## 7. Record the review in the description

After approval and before any preflight or submit, append to every changeset
(VCS-MECHANICS):

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

- One line per axis, always both, each with who ran it, its final-pass verdict, and the pass
  count. Skipped axis: `Spec: skipped (no linked source)`. Inline run (no Agent tool):
  `Standards: self (inline, myst-dev-kit:code-review brief) - Verdict: ...`; if the axes
  did not actually run, say `(quick review)`.
- `Docs-alignment:` when the changeset has prose: `aligned`, or what contradicted and how
  it was fixed. A preflight result: no verdict, no pass count.
- `Findings:` one-liners with disposition, severity, and axis; cap at ~6, overflow as
  `- ...and N more INFO items (see review transcript)`.
- **Generate pass counts and verdicts from a list of the passes, do not type them, and
  regenerate immediately before publishing.** Same for any other assertion about the
  changeset's own content: re-derive at submit time or leave it out.

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
4. **Publish** (VCS-MECHANICS) and report the final submitted number or merge SHA. A quiet
   submit is not evidence any audit passed.
5. Note any post-submit verification needed.

The user has final authority on submit, fix, or defer. Always wait for explicit approval
before publishing.
