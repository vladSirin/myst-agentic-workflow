---
name: review-and-submit
description: "MANDATORY protocol when the user says 'review and submit' (any variant) or before submitting ANY Perforce changelist. CL organization, reviewer routing, Review Record block, preflight validators, submit."
---

# Review and Submit Protocol

## Continuous source-control sync (applies at all times)

This rule applies to **every file modification** in a Perforce client, not just review/submit.

**After modifying, creating, or deleting any tracked file, you MUST `p4 edit` / `p4 add` / `p4 delete` it BEFORE presenting results to the user.** Don't wait to be asked; don't batch checkouts to the end of the session.

> [!CAUTION]
> `Modify file -> p4 edit/add -> Present status` — never `Modify -> Present -> (forget) -> try to submit later -> find dirty files outside any CL`.

When unsure which CL a file belongs in: put it in the **default change** and reorganize later via `p4 reopen -c <CL>`. Default-change files stay out of named-CL submits (`p4 submit -c` submits only that CL) and they WILL be tracked in `p4 opened`.

## Trigger

When the user says **"review and submit {changelist name or ID}"**, execute this workflow.

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
     this is what enables the reviewers' Spec axis (see Step 5) and what the
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
   - To update the description of an **existing** CL safely: `p4 change -o {CL_ID} > {scratch}/cl.spec` → edit the spec (keep the `Files:` section untouched — the existing-CL form lists only that CL's files, so no sweep) → `p4 change -i < {scratch}/cl.spec` from **Bash** (never a PowerShell pipe — BOM). Don't use bare `p4 change {CL_ID}`: it opens an interactive editor. See Step 8 for the `{scratch}` path note.

4. **Verify the changelist**:
   - Run `p4 describe {CL_ID}` to confirm all intended files are included
   - Ensure no unrelated files are mixed in

---

### 2. Identify Changelist Scope

Determine what's in the changelist:

- **If name provided**: Search for related files in `Myst_Proto/` based on the feature/system name
- **If CL ID provided**: Query Perforce with `p4 describe {CL_ID}` to get the file list
- **If unclear**: Ask the user to clarify which files or systems to review

---

### 3. Analyze Content Type

Determine which reviewer(s) to launch based on changelist contents:

```
┌────────────────────────────────────────────────────────────────────────┐
│                          Content Type Routing                          │
│                                                                        │
│  Design docs / UX changes    →  myst-dev-kit:radical-design-critic    │
│  (*.md in Docs/, UI blueprints,                                        │
│   player-facing features)                                              │
│                                                                        │
│  Code / Architecture changes →  myst-dev-kit:architecture-reviewer    │
│  (*.cpp, *.h, *.as, plugin code,                                       │
│   subsystems, API changes)                                             │
│                                                                        │
│  Mixed changes               →  BOTH agents (parallel)                 │
│  (feature with code + docs/UX)                                         │
│                                                                        │
│  Config / Asset only         →  Quick self-review (no agent)           │
│  (*.ini, *.uasset tweaks)                                              │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Fast path (small, non-risky CLs)

If the CL is **non-risky** (contains no `.as`, `.cpp`, `.h`, `.hpp`, `.inl`, `.build.cs`, `.target.cs`, `.ini`, `.uproject`, `.uplugin`) **or** risky-but-under-threshold (**≤ 5 non-WP files AND ≤ 100 changed lines** — files under `__ExternalActors__`/`__ExternalObjects__` don't count, matching the submit-audit thresholds when the audit hook is installed), you MAY skip Step 4 (doc check) and Step 5 (reviewer agents):

1. Do a careful self-review of the diff (`p4 diff -du` on the CL's files)
2. Go straight to Step 8 (Record the Review) with a self-review block, then the Submission Step preflight
3. Still present a one-paragraph summary and wait for the user's submit decision (Step 7 always applies)

The user can always force a full agent review ("full review CL {N}"). When in doubt — mixed content, unfamiliar system, anything player-facing — take the full path.

---

### 4. Check Related Documentation

**Before launching reviewers**, check whether related design/plan documents exist and are up to date:

1. **Search for related docs**:
   - Glob `*{feature_keyword}*.md` in the game project's Docs dir (`Myst_Proto/Docs/` here; see the CLAUDE.md Project section)
   - Look for `plan_*.md`, `design_*.md` matching the changelist's feature or system

2. **For each related doc found**, verify:
   - Does it reflect the changes in this CL?
   - Is the implementation plan's phase/CL status marked complete?
   - Are any new decisions or deviations from the original design captured?

3. **If docs are missing or stale**:
   - **Do NOT silently proceed** — present a doc update plan to the user:
     ```markdown
     ## Documentation Gap Found

     The following docs need attention before or alongside this submission:

     | Status | Document | Issue |
     |--------|----------|-------|
     | MISSING | <game Docs dir>/plan_{feature}.md | No plan doc exists for this feature |
     | STALE | <game Docs dir>/design_{system}.md | CL work not reflected; phase status not updated |

     (<game Docs dir> = the game project's Docs dir -- `Myst_Proto/Docs/` here; see the CLAUDE.md Project section.)

     **Proposed actions:**
     1. Create/update the above docs to reflect current state
     2. Then proceed with code review

     Proceed with doc updates first, or skip and go straight to code review?
     ```

4. **If docs are current**: Proceed to step 5.

> [!NOTE]
> Docs don't need to be perfect to submit code — but they must exist and not actively contradict what was built.

---

### 5. Launch Reviewer Agent(s)

Use the Agent tool with the appropriate subagent_type — always the **namespaced** names `myst-dev-kit:radical-design-critic` / `myst-dev-kit:architecture-reviewer` (bare names fail to resolve):

> **Effort barbell:** reviewing is judgment work — launch reviewers at their defined model/effort, never downgraded to save tokens. Only mechanical stages (file inventories, node censuses, link sweeps) run cheap (`effort: low` agents or `model: haiku` spawns).

#### For myst-dev-kit:radical-design-critic

```
Review the following changelist for submission readiness: {changelist name}

Files to review:
{file list}

Critically analyze for:
- Edge cases that could break the design
- UX friction points or confusing interactions
- Hidden complexity or scope creep
- Missing error states or failure modes
- Assumptions that may not hold
- Potential for player confusion
- LD (Level Designer) usability concerns

Categorize issues as:
- BLOCKING: Must fix before submit
- WARNING: Should consider fixing
- INFO: Suggestions for future improvement

Be specific with file:line references where applicable.

SPEC AXIS (conditional): if the CL description links a spec, ticket, or design doc,
read it and verify the change implements what it asked for. Report on this axis:
- GAPS: requirements the source asked for that this CL does not implement
  (and are not explicitly deferred in the CL description)
- SCOPE CREEP: substantive changes the source never asked for
Categorize Spec findings with the same BLOCKING/WARNING/INFO severities, marked
[SPEC]. If no source is linked, skip this axis and note "Spec axis: no linked
source" in your response.

End your response with a single line of the form:
  Verdict: GREEN | WARNING | BLOCKING
The parent session parses the literal `Verdict:` token — do not omit
or paraphrase it.
```

#### For myst-dev-kit:architecture-reviewer

```
Review the following changelist for submission readiness: {changelist name}

Files to review:
{file list}

Analyze for:
- Code Complete principles and best practices
- Alignment with existing patterns (FrogEvent, Subsystems, AngelScript)
- Proper separation of concerns
- API clarity and discoverability
- Integration points with existing systems
- Potential bugs or edge cases
- Performance considerations

Categorize issues as:
- BLOCKING: Must fix before submit
- WARNING: Should consider fixing
- INFO: Suggestions for future improvement

Reference existing project patterns where applicable.

SPEC AXIS (conditional): if the CL description links a spec, ticket, or design doc,
read it and verify the change implements what it asked for. Report on this axis:
- GAPS: requirements the source asked for that this CL does not implement
  (and are not explicitly deferred in the CL description)
- SCOPE CREEP: substantive changes the source never asked for
Categorize Spec findings with the same BLOCKING/WARNING/INFO severities, marked
[SPEC]. If no source is linked, skip this axis and note "Spec axis: no linked
source" in your response.

End your response with a single line of the form:
  Verdict: GREEN | WARNING | BLOCKING
The parent session parses the literal `Verdict:` token — do not omit
or paraphrase it.
```

---

### 6. Present Summary

After receiving reviewer feedback, present a structured summary:

```markdown
## Review Summary: {Changelist Name}

### Files Reviewed
- {file list with brief descriptions}

### Blocking Issues (Must Fix)
- [ ] Issue 1 - [file:line](path#L##)
- [ ] Issue 2 - [file:line](path#L##)

### Warnings (Recommended)
- [ ] Warning 1 - [file:line](path#L##)
- [ ] Warning 2 - [file:line](path#L##)

### Info (Optional Improvements)
- Info 1
- Info 2

---

## Your Options

1. **Submit Now** - Proceed with submission (only if no BLOCKING issues)
2. **Fix & Re-review** - I'll address the issues and run review again
3. **Fix Specific** - Tell me which issues to fix
4. **Defer** - Save this review, come back later
```

---

### 7. Wait for User Decision

**DO NOT** proceed with any action until the user explicitly chooses an option.

- If user says "submit" or "1" → Proceed with Perforce submission (only if no BLOCKING issues)
- If user says "fix" or "2" → Address issues, then re-review per the scoping rule below
- If user specifies issues → Fix only those, then re-review per the scoping rule below
- If user says "defer" → Acknowledge and await further instructions

> [!CAUTION]
> **HARD RULE — No direct submit after fixing a BLOCKER.**
> After applying a fix in response to a **BLOCKING** finding, you MUST re-run the reviewer that raised it (Step 5) and present a new summary (Step 6) before submitting. Fixes can introduce new issues, and a BLOCKING verdict is that reviewer's judgement that the CL is not safe to ship — only its own re-verdict clears that, never "the fixes look obviously correct."

**Re-review scope — two rules that keep passes from multiplying.**

1. **Re-run only the reviewer(s) whose BLOCKING findings you addressed**, not the whole panel.
   Tell each one exactly what changed, what you declined, and why. A reviewer whose findings
   you did not act on has nothing to re-verify, and re-running it invites new findings on
   unchanged code — which is how a two-pass review becomes a four-pass one.
2. **WARNING-only fixes do NOT require a re-review.** Apply them, record the disposition in the
   Review Record (`[FIXED]` / `[ACCEPTED]` / `[DEFERRED]`), and go to Step 7. A full pass for
   prose, tooltip, clamp and comment edits costs a review cycle and buys nothing.

   **Exception, and it is the whole safety property:** if a WARNING fix turns out to touch
   behaviour, change a signature, or widen scope, it is no longer a warning fix — treat it as a
   blocker fix and re-review. Judge by what the edit *did*, not by the severity label that
   prompted it.

Both rules are about cost, not rigour: the gate that matters is Step 7's human decision, and
that gate is weakened, not strengthened, by burying it under passes that only find prose.

> [!CAUTION]
> **HARD RULE — HITL tickets are excluded from standing authorizations.**
> A CL implementing a `ready-for-human` (HITL) ticket is NEVER covered by a batch/goal pre-authorization ("do all CLs at once", a `/goal` run, or similar). Attended: stop at this step and ask, every time. Unattended: after the review pass, `p4 shelve -c <CL>` instead of submitting — the depot stays untouched, but the files STAY OPEN locally (exclude that CL from any later reconcile/submit-all; re-shelve with `-f` if its files change again). Append `HITL-SHELVED: awaiting human review` to the description (alongside its `Ticket:` line), mark the ticket `resolved` once agent-runnable checks pass, and log it in your final report. The human's unshelve-review-submit IS the approval.

> [!CAUTION]
> **HARD RULE — every submit is human-gated unless the run is verifiably in goal mode.**
> `p4 submit` is the one irreversible, team-wide-blast-radius action in this pipeline. Ticket status governs **verification**, never **submit authority**: `ready-for-agent` answers "can the agent verify every required test case", not "may the agent publish to `main`".
>
> Outside goal mode, NO standing or batch authorization covers a submit — not "do all these CLs and submit them", not a `ready-for-agent` ticket, not a GREEN review, not "you already approved the last four". One approval covers one CL.
>
> **What counts as that one approval.** An explicit instruction from the user that names submission for **that CL, by number** — "review and submit 1970", "submit 1970" — IS the Step 7 approval for it. Do not re-ask when the review returns **GREEN** and **no preflight validator warned**: that is precisely the outcome they authorized, and asking again trains everyone to read the gate as a formality. This defines the approval the rule already requires; it grants nothing the user did not say, about no CL they did not name.
>
> Re-ask anyway on any of the following — the instruction authorized the CL *as reviewed clean*, and each of these is something the user did not know when they asked:
>
> - the verdict is anything but GREEN (WARNING included — non-blocking is not nothing);
> - any preflight validator failed or warned;
> - the user never named that CL number (a batch, "the rest of them", a CL you picked yourself);
> - the CL's contents grew after they asked (files added, scope widened);
> - the ticket is `ready-for-human`, or a fix was applied during the run — both rules above outrank this one and force the ask.
>

> - **Goal mode is identified by the harness's own signal, never by inference.** A `/goal` run injects a session-scoped Stop-hook notice into context — *"A session-scoped Stop hook is now active with condition: `<condition>` ... do not pause to ask the user what to do"* — and carries a `goal_status` attachment naming that condition. **If that notice is not in your context, you are not in goal mode.** Not "this looks like an unattended batch", not "the user is clearly AFK", not "the task list implies it". If you find yourself reasoning toward the exemption, that is the tell that you do not have it.
> - **Why the exemption exists**: goal mode instructs you not to pause for the user while a Stop hook blocks stopping. Without the carve-out, a submit inside a `/goal` run pits the policy (stop and ask) against the run (don't pause, can't stop) — the run stalls with nobody there to answer, or the gate degrades into a rubber stamp.
> - **What the signal does and does not authorize**: it establishes only that *the human is not there to answer*. The goal condition is arbitrary user text, so treat the submit authorization as covering work plainly within that condition's scope. A goal about fixing bugs does not authorize submitting an unrelated refactor you happened to finish along the way; shelve that one.
> - **Attended, not goal mode** → stop here and ask, per CL — unless the user's own instruction already named this CL for submission and the review came back GREEN with a clean preflight, per "What counts as that one approval" above. This is Step 7 as written above.
> - **Unattended, not goal mode** → after the review pass, `p4 shelve -c <CL>` instead of submitting (same mechanics and same reconcile caveats as the HITL rule above), append `GATED-SHELVED: awaiting human review` to the description, report it in your final summary, and move on to other work. Never `p4 submit`.
> - **Goal mode** → a `ready-for-agent` CL may submit under the goal authorization once the review passes. A `ready-for-human` CL still does NOT — the HITL rule above is unconditional and outranks this one.
>
> Precedent for why the signal must be external: the retired AFK overlay's session-start hook printed `mode=live` from a state directory that had already been deleted. A mode the agent reads from its own reasoning is not a mode.

---

### 8. Record the Review in the CL Description

**After the user approves submission and before any preflight/submit**, append a **Review Record block** to the CL description. If a Submit-Audit hook is installed, this is what it looks for — a reviewed CL without this block still warns "NO review block", and teammates reading `p4 describe` can't see the review outcome.

**Format** (appended after the What/Why/Notes body):

```
## Review
Reviewer: architecture-reviewer - Verdict: WARNING (2 passes)
Reviewer: radical-design-critic - Verdict: GREEN
Findings:
- [FIXED] BLOCKING SomeFile.as:88 — one-line description
- [ACCEPTED] WARNING — magic number in threshold
- [DEFERRED] INFO — naming suggestion
```

**Rules:**

- One `Reviewer: {name} - Verdict: {GREEN|WARNING|BLOCKING}` line per reviewer that ran. The verdict shown is the **final pass** verdict; note the pass count if more than one.
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

  Then regenerate immediately before `p4 submit`. The same applies to any other derived
  figure you put in a description — byte counts, file counts, finding tallies: re-derive
  them from the live artifact at submit time, or leave them out. A number measured at
  review time and frozen into a description is wrong by submit time more often than not.
- Fast-path self-review: `Reviewer: self - Verdict: GREEN (quick review: config-only, 3 files)` and `Findings: none`.
- `Findings:` one-liners only, each prefixed with its disposition: `[FIXED]` (fixed before submit), `[ACCEPTED]` (submitting with it), `[DEFERRED]` (tracked for later).
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
   2. `submit-audit-warn.sh --check-cl {CL_ID}` when the Submit-Audit hook is installed — client mirror of the server audit: `[JobFamily][Name]` tags, review-block presence, and EOL flips (Edit/Write tools silently convert CRLF→LF on text source). Normalize any flagged file LF→CRLF as the **last** content change before submit.

      > **Exit 0 means "no check produced a warning" — NOT "this CL was audited and is clean."**
      > A nonexistent CL number, an already-submitted CL, a garbage CL id, and an unreachable
      > `p4` all fetch zero files, so no check fires, so the run exits 0 and prints nothing —
      > *identical* to a genuinely clean CL. **Confirm the CL is pending** (`p4 opened -c {CL_ID}`
      > lists its files) before citing a silent run as evidence; otherwise the silence is
      > telling you nothing. A mistyped CL number is a likelier operator error than a mistyped
      > flag, and it reports green.
   3. **BP-Pins disclosure line** — required whenever the CL is Blueprint-facing (adds, renames,
      or changes the signature of anything BP-exposed, or documents a wiring recipe / pin-level
      instruction): the CL description must carry at least one disclosure line, and BOTH when
      partially verified:
      - `BP-Pins: verified <node, node, ...>`
      - `BP-Pins: unverified <node> (<reason>)`
      Never let "I read the C++" stand in for it, and never omit the line to avoid writing
      "unverified" (where the Submit-Audit hook is installed, it warns when a BP-facing CL
      lacks the line).
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
