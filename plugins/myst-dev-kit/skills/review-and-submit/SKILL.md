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

During an active review, a file the CL did not already contain goes in a NEW CL unless the fix itself requires it — [RE-REVIEW.md](RE-REVIEW.md) rule 6.

When unsure which CL a file belongs in: put it in the **default change** and reorganize later via `p4 reopen -c <CL>`. Default-change files stay out of named-CL submits (`p4 submit -c` submits only that CL) and they WILL be tracked in `p4 opened`.

## Trigger

When the user gives **any explicit submit instruction naming a CL** — "review and submit {changelist name or ID}", "submit {CL}" — execute this workflow. The long phrase is sufficient, never required: Step 7 already treats any per-CL submit instruction as the approval, and the review it buys runs either way. (A bare "submit" naming no CL: ask which one, then proceed.)

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
│  Config / Asset only         →  Fast path: review-changes inline       │
│  (*.ini, *.uasset tweaks)                                              │
│                                                                        │
│  Docs/ledger only            →  Trivial path (tier 0, below)           │
│  (*.md/*.txt in the doc trees)                                         │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### Trivial path (tier 0 — docs/ledger only)

Check this BEFORE the fast path. The CL qualifies when ALL of:

- **Every** file is `.md` or `.txt` under a doc tree — the team docs dir (`Docs/` here), the
  game project's Docs dir (`Myst_Proto/Docs/` here; see the CLAUDE.md Project section), or
  `.scratch/` — including pure `p4 move`/rename CLs whose source and target both stay inside
  those trees with zero content-line changes;
- **Nothing** under a leads-only subtree (`_Raw/`), and nothing under `.claude/` / `.codex/`
  (rules, hooks, scripts, and manifests steer agent behavior — they review as code, whatever
  their extension);
- **≤ 10 files.**

One file outside the allowlist makes the CL not-trivial — route it normally. When in doubt,
it does not qualify: take the fast path.

For a qualifying CL, skip Step 3 routing, Step 4 (doc check), and Step 5 (reviewers). The
protocol collapses to:

1. Description check: `[JobFamily][Name]` tags, English/ASCII only, `Ticket:` / `Workflow:`
   line when the pre-implementation gate applies.
2. `p4 opened -c {CL}` lists exactly the intended files, nothing else.
3. EOL-normalize any flagged text file (Edit/Write tools silently flip CRLF→LF).
4. Record line in the description (Step 8 format):
   `Reviewer: self - Verdict: GREEN (trivial path: docs-only, {N} files)`
5. Submission Step preflight, then Step 7 as always — **the gate does not change**: a
   submit instruction from the user naming this CL is still required.

Why this tier exists: measured across CLs 2386–2469, every docs-only CL that ran the
fast-path rubric self-reviewed GREEN with zero findings — the review pass was pure ceremony
there, while code CLs in the same window drew real BLOCKING and WARNING verdicts. The tier
removes the ceremony and keeps the record, the audit trail, and the human gate.

### Fast path (small, non-risky CLs)

If the CL is **non-risky** (contains no `.as`, `.cpp`, `.h`, `.hpp`, `.inl`, `.build.cs`, `.target.cs`, `.ini`, `.uproject`, `.uplugin`) **or** risky-but-under-threshold (**≤ 5 non-WP files AND ≤ 100 changed lines** — files under `__ExternalActors__`/`__ExternalObjects__` don't count, matching the submit-audit thresholds when the audit hook is installed), you MAY skip Step 4 (doc check) and Step 5 (reviewer agents):

1. Run the `myst-dev-kit:review-changes` skill on the CL — the same rubrics, applied inline, ending in the `Verdict:` line Step 8 records. Lens selection is the skill's own (Step 3's table): one lens for single-type CLs, both for mixed.
2. Present a one-paragraph summary and wait for the user's submit decision (Step 7 always applies)
3. Then Step 8 (Record the Review) with its verdict, then the Submission Step preflight — in that order, because Step 8 records a review the user has approved

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

> [!IMPORTANT]
> **Supply the facts the reviewer cannot observe.** Reviewers read files, but may not be able
> to open binary or serialized assets, query a live editor or service, or run the project's
> tooling. When the CL touches any of that, read those facts yourself and put them in the
> prompt: the property values, compile/validation status, node or schema shapes, the
> before/after of a binary you diffed. Observed values, not your conclusions from them — and
> mark which are observed and which you inferred, using the evidence ranking the reviewer is
> being asked to apply.

**The prompt carries only what the reviewer cannot already know.** Its review dimensions are
its own — `agents/radical-design-critic.md` §Review Methodology and
`agents/architecture-reviewer.md` §Reference canon / §Review scope and method are the system
prompt, loaded at spawn. Restating them here duplicates the *generator* half of the mandate
while dropping the restraint clauses that live only in those files (§2's "a manufactured UX
finding is noise"; "cite, don't name-drop"), which re-anchors the reviewer on producing
findings and hands it none of the brakes. Do not re-add a dimension list.

Both reviewers take the same prompt — routing (Step 3) decides which one(s) receive it:

```
Review the following changelist for submission readiness: {changelist name}

Files to review:
{file list}

Observed facts you cannot reach yourself (values read, not inferred):
{observed facts, or "none - nothing in this CL required observation"}

Linked source (spec / ticket / design doc), if any:
{path or tracker ref, or "none linked"}

Apply your own review methodology. Cite file:line. Categorize findings
BLOCKING / WARNING / INFO.

SPEC AXIS (only if a source is linked above): read it and verify the change
implements what it asked for, marking findings [SPEC] at the same severities —
GAPS (asked for, not implemented, not explicitly deferred in the CL
description) and SCOPE CREEP (substantive changes never asked for). If nothing
is linked, note "Spec axis: no linked source".

End your response with a single line of the form:
  Verdict: GREEN | WARNING | BLOCKING
The parent session parses the literal `Verdict:` token — do not omit
or paraphrase it.
```

On a **re-review**, add only what changed: which findings you fixed, which you declined and
why, and whether you adopted the reviewer's prescription ([RE-REVIEW.md](RE-REVIEW.md) rules
1 and 3). Do not resend the whole CL as if the first pass had not happened.

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
- If user says "fix" or "2" → Address issues — the fix answers the finding and nothing else ([RE-REVIEW.md](RE-REVIEW.md) rule 3) — then re-review per the scoping rule below
- If user specifies issues → Fix only those, then re-review per the scoping rule below
- If user says "defer" → Acknowledge and await further instructions

> [!CAUTION]
> **HARD RULE — No direct submit after fixing a BLOCKER.**
> After applying a fix in response to a **BLOCKING** finding, you MUST re-run the reviewer that raised it (Step 5) and present a new summary (Step 6) before submitting — except for the closed list in [RE-REVIEW.md](RE-REVIEW.md) rule 4, whose fixes cannot change behaviour. Fixes can introduce new issues, and a BLOCKING verdict is that reviewer's judgement that the CL is not safe to ship — only its own re-verdict clears that, never "the fixes look obviously correct."

**Re-review scope.** You fixed a finding and you are about to spend another reviewer pass. What
re-runs, what must never cost a pass, and how to keep a fix from creating the next round's work:
read [RE-REVIEW.md](RE-REVIEW.md) before launching it.

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
> **What counts as that one approval.** An explicit instruction from the user that names submission for **that CL, by number** — "review and submit 1970", "submit 1970" — IS the Step 7 approval for it. Do not re-ask when the review returns **GREEN** and **no preflight validator warned**: that is precisely the outcome they authorized, and asking again trains everyone to read the gate as a formality. This defines the approval the rule already requires; it grants nothing the user did not say, about no CL they did not name.
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
> - **Attended, not goal mode** → stop here and ask, per CL — unless the user's own instruction already named this CL for submission and the review came back GREEN with a clean preflight, per "What counts as that one approval" above. This is Step 7 as written above.
> - **Unattended, not goal mode** → after the review pass, `p4 shelve -c <CL>` instead of submitting (same mechanics and same reconcile caveats as the HITL rule above), append `GATED-SHELVED: awaiting human review` to the description, report it in your final summary, and move on to other work. Never `p4 submit`.
> - **Goal mode** → a `ready-for-agent` CL may submit under the goal authorization once the review passes. A `ready-for-human` CL still does NOT — that rule is unconditional and outranks this one, and the label that would lift the bar is one only the user can apply.
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

  Then regenerate immediately before `p4 submit`. The same applies to **any assertion about
  the CL's own content**, not only the numeric ones — byte counts, file counts and finding
  tallies, but equally "verified by diff", "zero non-comment lines changed", or a quoted
  snippet of what one of its files now says. Re-derive from the live artifact at submit time,
  or leave it out. Anything measured at review time and frozen into a description is wrong by
  submit time more often than not, and **the review's own fixes are what make it wrong** —
  which is why the prose ones rot hardest in exactly the CLs that took the most rounds.
- Fast path: `Reviewer: self (inline, review-changes skill) - Verdict: GREEN (fast path: config-only, 3 files)`. Trivial path: `Reviewer: self - Verdict: GREEN (trivial path: docs-only, 7 files)` — no rubric ran, and the line says so. If the skill did not run and the CL was not tier 0, the honest line is `Reviewer: self - Verdict: ... (quick review)` — never assert a rubric-backed review that did not happen.
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
