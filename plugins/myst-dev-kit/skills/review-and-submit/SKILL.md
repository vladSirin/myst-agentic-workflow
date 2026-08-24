---
name: review-and-submit
description: "MANDATORY protocol when the user says 'review and submit' (any variant) or before submitting ANY Perforce changelist. CL organization, two-axis review (Standards + Spec) in parallel sub-agents, Review Record block, preflight validators, submit."
---

# Review and Submit Protocol

## Continuous source-control sync (applies at all times)

This rule applies to **every file modification** in a Perforce client, not just review/submit.

**After modifying, creating, or deleting any tracked file, you MUST `p4 edit` / `p4 add` / `p4 delete` it BEFORE presenting results to the user.** Don't wait to be asked; don't batch checkouts to the end of the session.

> [!CAUTION]
> `Modify file -> p4 edit/add -> Present status` — never `Modify -> Present -> (forget) -> try to submit later -> find dirty files outside any CL`.

During an active review, a file the CL did not already contain goes in a NEW CL unless the fix itself requires it (Step 5, stopping rule).

When unsure which CL a file belongs in: put it in the **default change** and reorganize later via `p4 reopen -c <CL>`. Default-change files stay out of named-CL submits (`p4 submit -c` submits only that CL) and they WILL be tracked in `p4 opened`.

## Trigger

When the user gives **any explicit submit instruction naming a CL** — "review and submit {changelist name or ID}", "submit {CL}" — execute this workflow. The long phrase is sufficient, never required: Step 6 already treats any per-CL submit instruction as the approval, and the review it buys runs either way. (A bare "submit" naming no CL: ask which one, then proceed.)

---

## Mandatory Workflow

### 1. Organize Changelist

**Before any review**, ensure files are in a properly named changelist:

1. **Create a named changelist (at task START, not submit time)**:
   - Start every P4 task in a **new named CL**; use the default change only if the user asks. The default change usually holds the human's own WIP — never sweep it wholesale.
   - Create the CL from **Bash** with a heredoc. A PowerShell pipe into `p4 change -i` prepends a UTF-8 BOM and fails with `Unknown field name`:

     ```bash
     p4 change -i <<'EOF'
     Change: new
     Description:
     	[JobFamily][Name] Title - brief summary
     EOF
     ```

     (Description lines in a change spec are TAB-indented.)
   - **Never create a CL via `p4 change -o | p4 change -i`**: the new-CL form pre-fills `Files:` with EVERY default-changelist file and sweeps them all into the new CL.
   - **Verify right after creating**: run `p4 opened -c {new_CL}`; evict any stray with `p4 reopen -c default {file}`. Pull task files from default **selectively** via `p4 reopen -c {new_CL} {files...}`.

2. **Name the changelist properly**:
   - **REQUIRED FORMAT**: `[JobFamily][Name] Brief description of changes`
   - The description MUST start with `[JobFamily][Name]` tags
   - **If unsure about JobFamily or Name, ASK the user before proceeding**
   - Examples:
     - `[Design][Shado] FlowSystem - Add MystLevelScriptActor for sequence triggers`
     - `[Code][Shado] FrogEvent - Fix tag matching in event dispatcher`
     - `[Art][Shado] Phase 8 LD Triggers - Initial trigger meshes`

3. **Write a comprehensive CL description**:
   - The first line is the **title** (tag + brief summary, as above)
   - Below the title, write a **body** that helps teammates understand the change at a glance:

   ```
   [JobFamily][Name] Title - Brief summary of the change

   ## What
   - Bullet list of concrete changes (new files, modified systems, config tweaks)

   ## Why
   - Motivation: what problem this solves, what feature it enables, or what phase/plan it advances
   - Link to relevant design doc or plan if one exists (e.g., "See Docs/plan_flow_system.md Phase 8")
   - **If the CL implements a spec or ticket, LINK IT here** as a
     `Ticket: .scratch/<slug>/issues/<NN>-<slug>.md` line (path or tracker ref) —
     this is what the Spec axis reviews against (see Step 3) and what the
     Submit-Audit agent check greps. If the user explicitly skipped the workflow,
     carry `Workflow: skipped (<reason>)` instead (see the pre-implementation-gate
     skill; agent CLs only — humans are exempt from this convention)

   ## Notes (optional)
   - Anything reviewers or teammates should know: migration steps, known limitations,
     dependencies on other CLs, areas that need testing, etc.
   ```

   - **English only**: the ENTIRE description (title, body, Review Record) must be
     English/ASCII — non-English text renders as unreadable garbage on some P4
     clients, CI, and audit systems. Submit-Audit warns on non-ASCII characters.
     This includes punctuation: use ASCII '-' in the Review Record's
     'Reviewer: {name} - Verdict:' line, never an em-dash.
   - **Keep it scannable**: prefer bullets over paragraphs
   - **Be specific**: name the classes, systems, and files that changed — don't just say "updated code"
   - **Include context**: teammates who didn't write the code should understand the CL without reading every file
   - To update the description of an **existing** CL safely: `p4 change -o {CL_ID} > {scratch}/cl.spec` → edit the spec (keep the `Files:` section untouched — the existing-CL form lists only that CL's files, so no sweep) → `p4 change -i < {scratch}/cl.spec` from **Bash** (never a PowerShell pipe — BOM). Don't use bare `p4 change {CL_ID}`: it opens an interactive editor. See Step 7 for the `{scratch}` path note.

4. **Verify the changelist**:
   - Run `p4 describe {CL_ID}` to confirm all intended files are included
   - Ensure no unrelated files are mixed in

---

### 2. Pin the change

Resolve the CL **before** spawning anything. A bad CL number, an already-submitted CL, or an
empty diff must fail here, in front of the user — not inside two parallel sub-agents.

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

---

### 3. Identify the spec source

Look for the originating spec, in this order:

1. The `Ticket:` line in the CL description (`.scratch/<slug>/issues/<NN>-<slug>.md` or a
   tracker ref) — see `Docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. A design or plan doc under the game Docs dir matching the feature or system name.

If nothing is found, ask the user where the spec is. If they say there isn't one — or the
description carries `Workflow: skipped (<reason>)` — the **Spec** axis is skipped and the
report says so. A missing spec is a reported fact, never a silently-dropped axis.

---

### 4. Spawn both axes in parallel

Two axes, two sub-agents, running concurrently so neither pollutes the other's context.

| Axis | Sub-agent | Asks |
|---|---|---|
| **Standards** | `myst-dev-kit:architecture-reviewer` | Does the code follow how this project writes code? |
| **Spec** | general-purpose sub-agent, brief below | Does the change do what the spec asked for? |

A CL of **design documents only** routes Standards to `myst-dev-kit:radical-design-critic`
instead; mixed CLs use the architecture reviewer.

> **Effort barbell:** reviewing is judgment work — launch reviewers at their defined
> model/effort, never downgraded to save tokens.

**The prompt carries only what the reviewer cannot already know.** Its dimensions, canon,
12-smell baseline and 400-word cap live in `agents/architecture-reviewer.md` and load at
spawn. Restating them here duplicates the *generator* half of the mandate while dropping the
restraint clauses that live only in that file. **Do not re-add a dimension list.**

> [!IMPORTANT]
> **Supply the facts the reviewer cannot observe** — binary/serialized assets, a live editor
> or service, project tooling it cannot run. Read those yourself and put them in the prompt:
> property values, compile status, node or schema shapes, the before/after of a binary you
> diffed. Observed values, not your conclusions from them; mark which you inferred.

**Standards prompt:**

```
Review changelist {CL_ID} for submission readiness.

Diff:  p4 diff -c {CL_ID} //...
Files: {file list}

Observed facts you cannot reach yourself (values read, not inferred):
{observed facts, or "none - nothing in this CL required observation"}

Apply your own review methodology and smell baseline. Cite file:line.
Categorize findings BLOCKING / WARNING / INFO. Under 400 words.

End your response with a single line of the form:
  Verdict: GREEN | WARNING | BLOCKING
```

**Spec prompt:**

```
Review changelist {CL_ID} against the spec it claims to implement.

Diff:  p4 diff -c {CL_ID} //...
Spec:  {path, or pasted contents}

Report only:
(a) requirements the spec asked for that are missing or partial;
(b) behaviour in the diff the spec never asked for (scope creep);
(c) requirements that look implemented but where the implementation looks wrong.

Quote the spec line for each finding. Do not review code quality, naming, or
architecture - that is the other axis's job and duplicating it re-ranks findings.
Categorize BLOCKING / WARNING / INFO. Under 400 words.

End your response with a single line of the form:
  Verdict: GREEN | WARNING | BLOCKING
```

On a **re-review**, add only what changed: which findings you fixed, which you declined and
why, and whether you adopted the reviewer's prescription. Re-run **only the axis whose
BLOCKING findings you addressed** — an axis you did not act on has nothing to re-verify, and
re-running it invites new findings on unchanged code. Do not resend the whole CL as if the
first pass had not happened.

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

The CL's overall verdict for Step 6 and Step 7 is the **worst of the two** — that is a gate
threshold, not a ranking, and both axis verdicts are still recorded separately.

Then present the options:

```markdown
1. **Submit Now** - proceed (only if no BLOCKING on either axis)
2. **Fix & Re-review** - address findings, re-run only the affected axis
3. **Fix Specific** - name the findings to fix
4. **Defer** - keep the review, come back later
```

#### Fixes that never cost a re-review

At any severity, BLOCKING included: a missing Review Record block, a missing or wrong
`[JobFamily][Name]` tag, an EOL flip, non-ASCII in the description, or a missing `Ticket:` /
`Workflow: skipped (<reason>)` line **whose ticket or user decision already exists**. Creating
the ticket and making the skip decision are never on this list.

**The list is closed, and closed on a principle**: every item is a description-or-formatting
fix that *cannot change behaviour*, and every item has a validator behind it. Naming and
`_Raw`-policy findings are script-caught but stay OFF — those fixes can break things. Anything
not on this list, including a wrong claim in the description body, is a real finding.

**You skip the reviewer pass, never the gate.** Fix it and return to Step 6: the user's submit
decision and the Step 7 Review Record both still apply.

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
natural end. Scope also freezes when the review starts: a file the fix genuinely needs is part
of this CL, and unrelated work that arrives mid-review gets its own CL.

---

### 6. Wait for User Decision

**DO NOT** proceed with any action until the user explicitly chooses an option.

- If user says "submit" or "1" → Proceed with Perforce submission (only if no BLOCKING issues)
- If user says "fix" or "2" → Address issues — the fix answers the finding and nothing else (Step 5) — then re-review only the affected axis
- If user specifies issues → Fix only those, then re-review only the affected axis
- If user says "defer" → Acknowledge and await further instructions

> [!CAUTION]
> **HARD RULE — No direct submit after fixing a BLOCKER.**
> After applying a fix in response to a **BLOCKING** finding, you MUST re-run the axis that raised it (Step 4) and present a new aggregate (Step 5) before submitting — except for the closed list in Step 5, whose fixes cannot change behaviour. Fixes can introduce new issues, and a BLOCKING verdict is that reviewer's judgement that the CL is not safe to ship — only its own re-verdict clears that, never "the fixes look obviously correct."

> [!CAUTION]
> **HARD RULE — a CL implementing a `ready-for-human` ticket is a process error. Never submit it.**
> `ready-for-human` means a human implements that ticket, so a CL against one should not exist. If you are holding one anyway, do not submit it in any mode — attended, unattended, or goal. After the review pass, `p4 shelve -c <CL>` instead — the depot stays untouched, but the files STAY OPEN locally (exclude that CL from any later reconcile/submit-all; re-shelve with `-f` if its files change again). Append `GATED-SHELVED: process error - agent implemented a ready-for-human ticket` to the description (alongside its `Ticket:` line) and log it in your final report. The human's unshelve-review-submit IS the approval.
>
> **The label is user-owned.** Only the user changes a `ready-for-human` ticket's `Status:`, and that means to ANY value, not just `ready-for-agent` — every gate matches the current string and nothing records the previous one, so setting `claimed` silences them all just as effectively and leaves no trace. An agent that believes a ticket is mislabeled says so and stops; it never rewrites the field and proceeds. An agent that could grant itself a workable state could then submit under a goal-mode authorization in the same run — this gate is the reason that path is closed.
>
> **Shipped-but-unverified is not this case.** Work that lands and still needs a human check is `resolved` plus an `Outstanding:` line, and its CL submits normally.

> [!CAUTION]
> **HARD RULE — every submit is human-gated unless the run is verifiably in goal mode.**
> `p4 submit` is the one irreversible, team-wide-blast-radius action in this pipeline. Ticket status governs **verification**, never **submit authority**: `ready-for-agent` answers "can the agent verify every required test case", not "may the agent publish to `main`".
>
> Outside goal mode, NO standing or batch authorization covers a submit — not "do all these CLs and submit them", not a `ready-for-agent` ticket, not a GREEN review, not "you already approved the last four". One approval covers one CL.
>
> **What counts as that one approval.** An explicit instruction from the user that names submission for **that CL, by number** — "review and submit 1970", "submit 1970" — IS the Step 6 approval for it. Do not re-ask when the review returns **GREEN** and **no preflight validator warned**: that is precisely the outcome they authorized, and asking again trains everyone to read the gate as a formality. This defines the approval the rule already requires; it grants nothing the user did not say, about no CL they did not name.
>
> Re-ask anyway on any of the following — the instruction authorized the CL *as reviewed clean*, and each of these is something the user did not know when they asked:
>
> - the verdict is anything but GREEN (WARNING included — non-blocking is not nothing);
> - any preflight validator failed or warned;
> - the user never named that CL number (a batch, "the rest of them", a CL you picked yourself);
> - the CL's contents grew after they asked (files added, scope widened);
> - the ticket is `ready-for-human` (that CL should not exist — shelve it, per the rule above), or a fix was applied during the run — both rules above outrank this one and force the ask.
>

> - **Goal mode is identified by the harness's own signal, never by inference.** A `/goal` run injects a session-scoped Stop-hook notice into context — *"A session-scoped Stop hook is now active with condition: `<condition>` ... do not pause to ask the user what to do"* — and carries a `goal_status` attachment naming that condition. **If that notice is not in your context, you are not in goal mode.** Not "this looks like an unattended batch", not "the user is clearly AFK", not "the task list implies it". If you find yourself reasoning toward the exemption, that is the tell that you do not have it.
> - **Why the exemption exists**: goal mode instructs you not to pause for the user while a Stop hook blocks stopping. Without the carve-out, a submit inside a `/goal` run pits the policy (stop and ask) against the run (don't pause, can't stop) — the run stalls with nobody there to answer, or the gate degrades into a rubber stamp.
> - **What the signal does and does not authorize**: it establishes only that *the human is not there to answer*. The goal condition is arbitrary user text, so treat the submit authorization as covering work plainly within that condition's scope. A goal about fixing bugs does not authorize submitting an unrelated refactor you happened to finish along the way; shelve that one.
> - **Attended, not goal mode** → stop here and ask, per CL — unless the user's own instruction already named this CL for submission and the review came back GREEN with a clean preflight, per "What counts as that one approval" above. This is Step 6 as written above.
> - **Unattended, not goal mode** → after the review pass, `p4 shelve -c <CL>` instead of submitting (same mechanics and same reconcile caveats as the HITL rule above), append `GATED-SHELVED: awaiting human review` to the description, report it in your final summary, and move on to other work. Never `p4 submit`.
> - **Goal mode** → a `ready-for-agent` CL may submit under the goal authorization once the review passes. A `ready-for-human` CL still does NOT — that rule is unconditional and outranks this one, and the label that would lift the bar is one only the user can apply.
>
> Precedent for why the signal must be external: the retired AFK overlay's session-start hook printed `mode=live` from a state directory that had already been deleted. A mode the agent reads from its own reasoning is not a mode.

---

### 7. Record the Review in the CL Description

**After the user approves submission and before any preflight/submit**, append a **Review Record block** to the CL description. If a Submit-Audit hook is installed, this is what it looks for — a reviewed CL without this block still warns "NO review block", and teammates reading `p4 describe` can't see the review outcome.

**Format** (appended after the What/Why/Notes body):

```
## Review
Standards: architecture-reviewer - Verdict: WARNING (2 passes)
Spec:      sub-agent vs .scratch/foo/issues/03-bar.md - Verdict: GREEN
Findings:
- [FIXED] BLOCKING Standards SomeFile.as:88 — one-line description
- [ACCEPTED] WARNING Standards — magic number in threshold
- [DEFERRED] INFO Spec — criterion 4 deferred to ticket 06
```

**Rules:**

- One line per **axis**, always both: `Standards:` and `Spec:`, each with the sub-agent that
  ran it and its own `Verdict:`. The verdict shown is the **final pass** verdict; note the
  pass count if more than one. The axes are recorded separately for the same reason they
  are reviewed separately — a blended line lets the passing axis hide the failing one.
- A skipped Spec axis is recorded, never omitted: `Spec: skipped (no linked source)`.
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

  Then regenerate immediately before `p4 submit`. The same applies to **any assertion about
  the CL's own content**, not only the numeric ones — byte counts, file counts and finding
  tallies, but equally "verified by diff", "zero non-comment lines changed", or a quoted
  snippet of what one of its files now says. Re-derive from the live artifact at submit time,
  or leave it out. Anything measured at review time and frozen into a description is wrong by
  submit time more often than not, and **the review's own fixes are what make it wrong** —
  which is why the prose ones rot hardest in exactly the CLs that took the most rounds.
- **Inline run** (no Agent tool — Codex, or any session without sub-agents): say so, per axis:
  `Standards: self (inline, review-changes skill) - Verdict: GREEN`. If neither the axes nor
  that skill actually ran, the honest line is `Standards: self - Verdict: ... (quick review)`
  — never assert a rubric-backed review that did not happen.
- `Findings:` one-liners only, each prefixed with its disposition — `[FIXED]` (fixed before submit), `[ACCEPTED]` (submitting with it), `[DEFERRED]` (tracked for later) — then its severity and **which axis raised it**.
- Cap at ~6 finding lines; summarize overflow as `- ...and N more INFO items (see review transcript)`.
- Write this block on **every** CL that goes through this protocol — it's cheap and keeps the audit quiet.

**Mechanics** (safe description update — see Step 1 for the pitfalls):

```bash
p4 change -o {CL_ID} > {scratch}/cl.spec   # existing-CL form: Files: lists only this CL, no sweep
# append the block to the Description field (TAB-indent every line)
p4 change -i < {scratch}/cl.spec           # from Bash — never a PowerShell pipe (BOM)
```

Use a temp path both Bash and any native-OS tool resolve identically for `{scratch}` (e.g. the session scratchpad dir). On Windows, MSYS `/tmp` is invisible to native tools (python, editors) — a spec written there can't be edited by them and you'll silently re-submit the old description.

---

## Submission Step

After the Review Record block is in place:

1. **Run repo preflight validators** — on any warning or non-zero exit: report it, fix, and re-run before submitting:
   1. Project preflight checks (e.g. `check-uproject-assoc.sh` under your tool's scripts dir — `.claude/scripts/` or `.Codex/scripts/` — when the `ue` overlay is installed).
   2. **There is no client-side audit to run.** `submit-audit-warn.sh` was deleted in CL 2454.
      Its checks split two ways, and neither is a step you perform:
      - **EOL flips** — `normalize-eol.sh` is a PostToolUse hook on Edit that repairs the
        mixed-ending fingerprint the moment a partial rewrite creates it. Nothing to normalize
        at submit time; its header notes it is now the only thing preventing that class.
      - **Everything else** — the server trigger, post-commit, warning to the team channel.

      > **A quiet submit is not evidence the audit passed**, only that nothing blocked you —
      > the server audit always exits 0 by design and reports after the fact. Do not cite
      > silence at submit time as a clean audit.
2. Run `p4 submit -c {CL_ID}` or create new CL with the files
3. Report submission result — confirm with `p4 changes -m 1 -s submitted` and report the final submitted CL number
4. Note any post-submit verification needed

---

## Example Invocations

| User Says | Action |
|-----------|--------|
| "review and submit FrogEvent fixes" | Search for recent FrogEvent changes, launch myst-dev-kit:architecture-reviewer |
| "review and submit CL 12345" | Query `p4 describe 12345`, route to appropriate reviewer(s) |
| "review and submit Phase 8 LD Triggers" | Find Phase 8 related files, likely launch both reviewers |

---

> [!IMPORTANT]
> **Always wait for explicit user approval before submitting.**
> The user has final authority on whether to submit, fix, or defer.
