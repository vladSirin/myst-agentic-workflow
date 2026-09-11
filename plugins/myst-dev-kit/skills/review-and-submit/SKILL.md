---
name: review-and-submit
description: "MANDATORY protocol when the user says 'review and submit' (any variant) or before publishing ANY changeset — a Perforce changelist submit, or a git merge/PR against the shared branch. Changeset organization, two-axis review (Standards + Spec) via myst-dev-kit:code-review sub-agents, Review Record, preflight validators, human-gated submit."
---

# Review and Submit Protocol

A **changeset** is one named, described, reviewable unit of work: a Perforce changelist or a
git branch/PR. Every step states the neutral rule; command forms and their traps are in
[VCS-MECHANICS.md](VCS-MECHANICS.md). Team specifics (audit checks, tag vocabularies, job
families) live in the project's own docs, not here.

## Source-control sync (applies at all times)

After modifying, creating, or deleting any tracked file, open it in version control
(`p4 edit` / `p4 add` / `p4 delete`) BEFORE presenting results. Never batch checkouts to the
end of a session. git: work on a named branch created at task start, never on the default
branch. During an active review, a file the changeset did not already contain goes in a NEW
changeset unless the fix itself requires it (Step 5).

## Trigger

Any explicit submit instruction naming a changeset ("review and submit {ID}", "submit
{CL}", "review and merge {PR}") runs this workflow. A bare "submit" naming no changeset:
ask which one, then proceed.

---

## 1. Organize the changeset

One properly named, described changeset, created at task START (mechanics: VCS-MECHANICS).
Verify its file list before review: every intended file in, nothing unrelated mixed in. The
default change usually holds the human's own WIP; never sweep it wholesale.

**Description** (CL description / PR body, the same shape either way):

```
Title - brief, specific summary (follow the project's title-tag convention; unsure: ASK)

## What
- Concrete changes: which files, systems, config

## Why
- The problem solved or the plan step advanced; link the design doc if one exists
- Ticket: .scratch/<slug>/issues/<NN>-<slug>.md   (what the Spec axis reviews against)
  or, if the user skipped the workflow: Workflow: skipped (<reason>)

## Notes (optional)
- Migration steps, known limitations, dependencies, what needs testing
```

Rules for the body:

- **Point, never restate.** Explain the change so a teammate understands it without reading
  every file, but do not copy into the description a fact one of the files owns: counts,
  tallies, "all N", "both", version strings, CL numbers, quoted snippets, "verified by
  diff", what a file "now says". A copy cannot update itself and is the single largest
  source of review blocks (measured: three quarters of BLOCKING findings were sentences
  about correct work, not the work).
- **Owner reports verbatim.** A user's one-word verdict ("works", "5 yes") is quoted, never
  expanded into mechanism, values, or scope. Record its limits alongside.
- **Claims of work done carry their evidence.** "Swept", "verified", "no X exists" appear
  only next to the command and result; otherwise the sentence is left out.
- English/ASCII only in Perforce (the whole description, Review Record included; ASCII `-`
  in Verdict lines, never an em-dash). Bullets over paragraphs; name classes and files.

---

## 2. Pin the change

Resolve the changeset before spawning anything. A bad ID, an already-published changeset,
or an empty diff fails here, in front of the user, not inside two parallel sub-agents.
Produce the file list and the actual diff the reviewers will read (VCS-MECHANICS: a pending
Perforce CL has no diff body in `p4 describe`, and an added file has no diff at all).

---

## 3. Identify the spec source

In order: the `Ticket:` line; issue references in commit messages; a path the user passed;
a design or plan doc matching the feature. Nothing found: ask. No spec, or `Workflow:
skipped`: the **Spec** axis is skipped and the report says so. A missing spec is a reported
fact, never a silently dropped axis.

---

## 4. Spawn both axes in parallel

The engine is **`myst-dev-kit:code-review`** (always namespaced; the bare name is a
different plugin). It defines the two axes, the standards sources, the smell baseline, and
the briefs. Follow it with these deltas:

- The diff is Step 2's; the spec is Step 3's; paste the smell baseline into the Standards
  brief (a generic sub-agent has no other access to it).
- Each brief: cite file:line; categorize BLOCKING / WARNING / INFO; under 400 words; end
  with one line `Verdict: GREEN | WARNING | BLOCKING`.
- Each brief states the submission-authority rule: a reviewer reports only. It never
  submits, shelves, pushes, merges, or edits files. Publication happens in the main session
  through Steps 6-7 and the Submission Step, nowhere else.
- Each brief states the prose-fix rule (Step 5): for a false or unverifiable claim in the
  description, a ticket, or a doc, prescribe **strip** first, **downgrade** second, and a
  corrected value only when it is derived from a command the fix will show.
- Supply the facts the reviewer cannot observe: binary assets, a live editor, tooling it
  cannot run. Put observed values in the brief, and mark which you inferred.
- Full model and effort. Reviewing is judgment work; never downgrade it to save tokens.

Two axes, always, whatever the changeset contains. Prose is not a third axis: what a
document proposes is not reviewed here; whether it contradicts what shipped is the
Docs-alignment preflight (Submission Step).

**Re-review:** brief only what changed: findings fixed, findings declined and why, whether
you adopted the reviewer's prescription. Re-run only the axis whose BLOCKING findings you
addressed; an axis you did not act on has nothing to re-verify, and re-running it invites
new findings on unchanged code.

---

## 5. Aggregate, then fix

Present both reports under `## Standards` and `## Spec`, verbatim or lightly cleaned. Never
merge or re-rank findings across axes: a blended verdict lets the passing axis hide the
failing one. End with findings per axis and the worst issue within each; never name a single
winner across axes. The gate verdict
for Steps 6 and 7 is the worst of the two; both are still recorded separately.

Options to present:

```markdown
1. Submit Now      - only if no BLOCKING on either axis
2. Fix & Re-review - address findings, re-run only the affected axis
3. Fix Specific    - name the findings to fix
4. Defer           - keep the review, come back later
```

### Fixing a false claim: strip, downgrade, derive

Most review rounds are spent on sentences, not code. Fix a claim in this order and stop at
the first rung that applies:

1. **Strip.** If a file already owns the fact (a count, a status, a quoted line, a CL
   number), delete the sentence. Point at the owner if the reader needs one.
2. **Downgrade.** If the sentence asserts work done ("verified in PIE", "criteria MET",
   "no callers anywhere") and nothing else records that state, make it true by
   weakening it: "not verified", "checked with `<command>`: `<result>`". Never strengthen.
3. **Derive.** Correct the value only when the correction comes from a command run now,
   shown next to it, and regenerated before submit.

Never answer a wrong count with more counts, or a false "none remain" with a more careful
"none remain". A corrected assertion is a fresh target for the next pass; a stripped one has
no truth value and a downgraded one is true by construction. Only those two end the loop.

### Fixes that never cost a re-review

At any severity: a missing Review Record block; a missing or wrong project title tag; an
EOL flip; non-ASCII in the description; a missing `Ticket:` / `Workflow: skipped` line whose
ticket or decision already exists; **deleting a claim from the description** (rung 1 above,
description only). The list is closed on a principle: each item cannot change behaviour or
add reviewable content. Off the list: creating the ticket or making the skip decision;
deletions inside tickets or docs (they can remove an acceptance criterion or a decision
record); project-validator findings that touch file content. Anything else, a wrong claim
in the description body included, is a real finding. You skip the reviewer pass, never the
gate: Step 6 and Step 7 still apply.

### The fix answers the finding and nothing else

Implement the finding, not the reviewer's prescription (written without running anything);
if you adopt theirs, say so in the re-review brief. Explanation goes in the brief, not the
artifact: no re-arguing the design in comments or doc prose. New prose is new reviewable
surface.

### Stopping rule

A round with no BLOCKING finding is the last round. Record remaining WARNING and INFO items
with `[ACCEPTED]` / `[DEFERRED]` and go to Step 6. A pass spent driving a WARNING-only report
to silence reliably produces a fresh WARNING-only report. Scope freezes when review starts.

---

## 6. Wait for the user's decision

Do not act until the user chooses. "submit" / "1": publish, only with no BLOCKING. "fix" /
"2": fix per Step 5, re-run only the affected axis. Named findings: fix only those. "defer":
await instructions.

**Hard rule: no direct submit after fixing a BLOCKER.** Re-run the axis that raised it and
present a new aggregate first, except for the closed list in Step 5. Only the reviewer's own
re-verdict clears its BLOCKING, never "the fixes look obviously correct".

**Hard rule: a changeset implementing a `ready-for-human` ticket is never published**, in any
mode. Park it (VCS-MECHANICS), append `GATED-SHELVED: process error - agent implemented a
ready-for-human ticket` to the description, and report it. The label is user-owned: only the
user changes that ticket's `Status:`, to any value. An agent that thinks the ticket is
mislabeled says so and stops. (Shipped-but-unverified is different: `resolved` plus an
`Outstanding:` line, published normally.)

**Hard rule: every publish is human-gated unless the run is verifiably in goal mode.**
Ticket status governs verification, never submit authority. One approval covers one
changeset; no batch or standing instruction covers a publish.

- **What counts as the approval:** the user's instruction naming publication for that
  changeset by ID ("submit 1970", "merge PR 42"). Do not re-ask when the review is GREEN and
  no preflight warned; re-asking trains everyone to read the gate as a formality.
- **Re-ask anyway** when: the verdict is not GREEN (WARNING included); a preflight failed or
  warned; the user never named this ID; the contents grew after they asked; a fix was
  applied during the run.
- **Goal mode is identified by the harness's own signal, never by inference:** the
  session-scoped Stop-hook notice in context plus its `goal_status` attachment. If that
  notice is not in your context, you are not in goal mode. Reasoning toward the exemption
  is the tell that you do not have it. Under it, a `ready-for-agent` changeset within the
  goal's scope may publish once the review passes; unrelated work is parked.
- **Attended, not goal:** stop and ask, per changeset, unless the approval above already
  applies. **Unattended, not goal:** park the changeset, append `GATED-SHELVED: awaiting
  human review`, report it, move on. Never publish.

---

## 7. Record the review in the description

After approval and before any preflight or submit, append a Review Record block (mechanics:
VCS-MECHANICS):

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

- One line per axis, always both, each with who ran it and its own final-pass verdict and
  pass count. A skipped axis is recorded: `Spec: skipped (no linked source)`. Inline run
  (no Agent tool): `Standards: self (inline, myst-dev-kit:code-review brief) - Verdict: ...`;
  if the axes did not actually run, say `(quick review)`, never assert a review that did
  not happen.
- `Docs-alignment:` line when the changeset has prose: `aligned`, or what contradicted and
  how it was fixed. A preflight result, not an axis: no verdict, no pass count.
- `Findings:` one-liners with disposition, severity, and axis. Cap at ~6; overflow as
  `- ...and N more INFO items (see review transcript)`.
- **Generate the pass counts and verdicts, do not type them, and write them last.** Keep the
  verdicts in a list and derive count, sequence and headline from it; regenerate immediately
  before publishing:

  ```python
  VERDICTS = ["BLOCKING", "WARNING", "GREEN"]   # append each pass as it lands
  DESC = DESC.replace("__N__", str(len(VERDICTS))).replace("__FINAL__", VERDICTS[-1])
  assert "__" not in DESC, "unfilled template token"
  ```

  The same holds for any other assertion about the changeset's own
  content (Step 1: point, never restate): re-derive at submit time or leave it out. The
  review's own fixes are what make a frozen claim wrong.

---

## Submission step

1. **Project preflight validators**, if the project defines any. On any warning or non-zero
   exit: report, fix, re-run. None defined: say so.
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

   Fix each contradiction by the Step 5 ladder (strip, downgrade, derive) and re-run. No
   severity, no verdict, never a review round. Why a closed question and not an axis: a
   reviewer asked to critique prose always finds something (one subject reached 19
   rounds); asked whether two things contradict, it either finds one or does not.
3. **EOL flips** (Perforce on Windows): an absurdly large diff is usually a wholesale LF
   flip; fix per VCS-MECHANICS, re-diff, review that.
4. **Publish** (VCS-MECHANICS) and report the final submitted number or merge SHA. A quiet
   submit is not evidence any audit passed; post-submit audits report after the fact.
5. Note any post-submit verification needed.

The user has final authority on submit, fix, or defer. Always wait for explicit approval
before publishing.
