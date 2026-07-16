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
   - **If the CL implements a PRD or issue, LINK IT here** (path or tracker ref) —
     this is what enables the reviewers' Spec axis (see Step 5) and the future
     issue-ref audit

   ## Notes (optional)
   - Anything reviewers or teammates should know: migration steps, known limitations,
     dependencies on other CLs, areas that need testing, etc.
   ```

   - **English only**: the ENTIRE description (title, body, Review Record) must be
     English/ASCII — non-English text renders as unreadable garbage on some P4
     clients, CI, and audit systems. Submit-Audit warns on non-ASCII characters.
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
┌─────────────────────────────────────────────────────────────────────┐
│                      Content Type Routing                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Design docs / UX changes       →  radical-design-critic           │
│  (*.md in Docs/, UI blueprints,                                     │
│   player-facing features)                                           │
│                                                                     │
│  Code / Architecture changes    →  architecture-reviewer           │
│  (*.cpp, *.h, *.as, plugin code,                                    │
│   subsystems, API changes)                                          │
│                                                                     │
│  Mixed changes                  →  BOTH agents (parallel)          │
│  (feature with code + docs/UX)                                      │
│                                                                     │
│  Config / Asset only            →  Quick self-review (no agent)    │
│  (*.ini, *.uasset tweaks)                                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
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
   - `Glob: {{game_docs_root}}/*{feature_keyword}*.md`
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
     | MISSING | {{game_docs_root}}/plan_{feature}.md | No plan doc exists for this feature |
     | STALE | {{game_docs_root}}/design_{system}.md | CL work not reflected; phase status not updated |

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

Use the Task tool with the appropriate subagent_type:

#### For radical-design-critic

```
Review the following changelist for submission readiness: {changelist name}

Files to review:
{file list}

If a radical-design-critic-afk-lessons.md file exists under your tool's
agents dir, load it first and apply its anti-patterns to this review.

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

SPEC AXIS (conditional): if the CL description links a PRD, issue, or design doc,
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

#### For architecture-reviewer

```
Review the following changelist for submission readiness: {changelist name}

Files to review:
{file list}

If an architecture-reviewer-afk-lessons.md file exists under your tool's
agents dir, load it first and apply its anti-patterns to this review.

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

SPEC AXIS (conditional): if the CL description links a PRD, issue, or design doc,
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
- If user says "fix" or "2" → Address issues, then **re-run this protocol from Step 5** — never submit directly after fixing
- If user specifies issues → Fix only those, then **re-run Steps 5–7** before submitting
- If user says "defer" → Acknowledge and await further instructions

> [!CAUTION]
> **HARD RULE — No direct submit after fixes.**
> After applying any fix in response to a WARNING or BLOCKING verdict, you MUST re-run the reviewer (Step 5) and present a new summary (Step 6) before submitting. Fixes can introduce new issues; the only path to submission is a clean review pass — not "the fixes look obviously correct."

---

### 8. Record the Review in the CL Description

**After the user approves submission and before any preflight/submit**, append a **Review Record block** to the CL description. If a Submit-Audit hook is installed, this is what it looks for — a reviewed CL without this block still warns "NO review block", and teammates reading `p4 describe` can't see the review outcome.

**Format** (appended after the What/Why/Notes body):

```
## Review
Reviewer: architecture-reviewer — Verdict: WARNING (2 passes)
Reviewer: radical-design-critic — Verdict: GREEN
Findings:
- [FIXED] BLOCKING SomeFile.as:88 — one-line description
- [ACCEPTED] WARNING — magic number in threshold
- [DEFERRED] INFO — naming suggestion
```

**Rules:**

- One `Reviewer: {name} — Verdict: {GREEN|WARNING|BLOCKING}` line per reviewer that ran. The verdict shown is the **final pass** verdict; note the pass count if more than one.
- Fast-path self-review: `Reviewer: self — Verdict: GREEN (quick review: config-only, 3 files)` and `Findings: none`.
- `Findings:` one-liners only, each prefixed with its disposition: `[FIXED]` (fixed before submit), `[ACCEPTED]` (submitting with it), `[DEFERRED]` (tracked for later).
- Cap at ~6 finding lines; summarize overflow as `- ...and N more INFO items (see review transcript)`.
- Write this block on **every** CL that goes through this protocol — it's cheap and keeps the audit quiet. (The AFK path writes the same block before its auto-submit.)

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
2. Run `p4 submit -c {CL_ID}` or create new CL with the files
3. Report submission result — confirm with `p4 changes -m 1 -s submitted` and report the final submitted CL number
4. Note any post-submit verification needed

---

## Example Invocations

| User Says | Action |
|-----------|--------|
| "review and submit FrogEvent fixes" | Search for recent FrogEvent changes, launch architecture-reviewer |
| "review and submit CL 12345" | Query `p4 describe 12345`, route to appropriate reviewer(s) |
| "review and submit Phase 8 LD Triggers" | Find Phase 8 related files, likely launch both reviewers |

---

> [!IMPORTANT]
> **Always wait for explicit user approval before submitting.**
> The user has final authority on whether to submit, fix, or defer.
