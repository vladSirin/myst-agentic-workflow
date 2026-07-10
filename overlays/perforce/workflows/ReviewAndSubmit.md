# Review and Submit Protocol

## Continuous source-control sync (applies at all times)

This rule applies to **every file modification** in a Perforce client, not just review/submit.

**After modifying, creating, or deleting any tracked file, you MUST `p4 edit` / `p4 add` / `p4 delete` it BEFORE presenting results to the user.** Don't wait to be asked; don't batch checkouts to the end of the session.

> [!CAUTION]
> `Modify file -> p4 edit/add -> Present status` — never `Modify -> Present -> (forget) -> try to submit later -> find dirty files outside any CL`.

When unsure which CL a file belongs in: put it in the **default change** and reorganize later via `p4 reopen -c <CL>`. Default-change files won't be submitted accidentally (preflight catches them) but they WILL be tracked.

## Trigger

When the user says **"review and submit {changelist name or ID}"**, execute this workflow.

---

## Mandatory Workflow

### 1. Organize Changelist

**Before any review**, ensure files are in a properly named changelist:

1. **If files are in default changelist**:
   - Create a new numbered changelist: `p4 change -o | p4 change -i`
   - Move the relevant files to the new CL: `p4 reopen -c {new_CL} {files...}`

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

   ## Notes (optional)
   - Anything reviewers or teammates should know: migration steps, known limitations,
     dependencies on other CLs, areas that need testing, etc.
   ```

   - **Keep it scannable**: prefer bullets over paragraphs
   - **Be specific**: name the classes, systems, and files that changed — don't just say "updated code"
   - **Include context**: teammates who didn't write the code should understand the CL without reading every file
   - To update the description: `p4 change {CL_ID}` (opens editor) or pipe via `p4 change -o {CL_ID} | ... | p4 change -i`

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
```

#### For architecture-reviewer

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

## Submission Step

When user approves submission:

1. **Run repo preflight validators first** — run any project preflight checks (e.g. `check-uproject-assoc.sh` under your tool's scripts dir — `.claude/scripts/` or `.Codex/scripts/` — when the `ue` overlay is installed) and **abort the submit on any non-zero exit**, reporting the failure so it can be fixed before retrying.
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
