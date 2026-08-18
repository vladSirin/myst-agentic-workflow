# Design & Planning Process

Companion to [SKILL.md](SKILL.md) — this file is the **process authority** for design
documents: naming, location, reviewer routing, iteration/verdict rules, and the
finalization lifecycle. SKILL.md automates the flow; when the two ever disagree, this
file wins. (Merged from the former `design-workflow` skill in v4.28.0.)

## Automatic Detection

When the user requests design or planning work, you **MUST** follow this process. Triggers include:

- Explicit: "design", "plan", "architect", "spec", "proposal"
- Implicit: "how should we implement", "what's the best approach for", "let's think through"

---

## 1. Create Document First

> **Naming rules**: See `.claude/rules/DocumentStandard.md` (installed by the myst-project
> overlay) for the full naming convention and lifecycle.

> **Search before you create.** Glob `plan_*.md`, `design_*.md`, `guide_*.md` under the
> game Docs dir (`Myst_Proto/Docs/` here; see the CLAUDE.md Project section) and
> `.scratch/*/spec.md` for the feature, system, or phase name first. If a related document
> exists, extend it — update status, add sections, keep its history — rather than opening a
> second one. Two documents for one feature don't error; they split the source of truth, and
> someone later works from the stale half.

**ALWAYS** create a design document in the game Docs dir before any implementation:

| Request Type | File Naming | Example |
|--------------|-------------|---------|
| Feature design | `design_{feature}_WIP.md` | `design_checkpoint_system_WIP.md` |
| Implementation plan | `plan_{feature}_WIP.md` | `plan_phase9_audio_WIP.md` |
| System architecture | `design_{system}_architecture_WIP.md` | `design_save_system_architecture_WIP.md` |
| Refactor proposal | `design_{area}_refactor_WIP.md` | `design_event_system_refactor_WIP.md` |

## 2. Launch Reviewers

After creating the initial document, **ALWAYS** launch at least one reviewer agent — via
the Agent tool with the **namespaced** subagent_type names shown below (bare names fail
to resolve):

```
┌────────────────────────────────────────────────────────────────────────┐
│                         Document Type Routing                          │
│                                                                        │
│  Game Design / UX / Features  →  myst-dev-kit:radical-design-critic   │
│  (gameplay mechanics, player                                           │
│   experience, UI flows)                                                │
│                                                                        │
│  Code Architecture / Systems  →  myst-dev-kit:architecture-reviewer   │
│  (subsystems, plugins, APIs,                                           │
│   implementation patterns)                                             │
│                                                                        │
│  Comprehensive Design         →  BOTH agents (parallel)                │
│  (new features with code +                                             │
│   player-facing elements)                                              │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

## 3. Iterate at Least Once

After receiving reviewer feedback:

1. Update the document to address BLOCKING and WARNING findings (record an explicit
   accept/defer decision for any WARNING you do not fix)
2. Add entry to Change Log with version bump
3. Present summary of changes to user
4. Re-run per the re-review rules — **the same loop, the same rules**: see
   [RE-REVIEW.md](../review-and-submit/RE-REVIEW.md), which governs a CL review and a
   document review alike. Rules 1, 2, 3, 5 and 6 apply as written. Rule 4 has no
   analogue here — no validator checks a design document — so every finding is a real
   finding. Read rule 6's "gets its own CL" as "gets its own document": a section that
   arrives mid-review does not restart this review.

   The two that change what most people do today: **rule 1** — re-run only the reviewer
   whose BLOCKING findings you addressed, not both — and **rule 3** — the fix answers the
   finding and nothing else, with your reasoning going in the re-review brief rather than
   growing the document. On a design doc the second matters most: new rationale prose is
   new reviewable surface, and prose is where the churn was measured to live.

**Verdict rules**: each reviewer ends its response with a literal
`Verdict: GREEN | WARNING | BLOCKING` line. Parse that token — never infer approval from
prose, and treat a response without it as ambiguous (ask the reviewer again or present
the findings to the user). Do not finalize a document whose latest verdict is BLOCKING.

## 4. Finalize

When design is approved:
1. Remove the `_WIP` suffix from the filename (do NOT add `_Updated` or any other suffix)
2. Update **Status** header in document: `WIP` → `APPROVED` or `COMPLETE`

---

## Document Template

Use the standard template from [SKILL.md](SKILL.md). Key sections:

1. **Header**: Version, date, status, reference
2. **Change Log**: Track iterations
3. **Overview**: What and why
4. **Design Philosophy**: Core principles
5. **Architecture**: System diagram
6. **File Structure**: Where code lives
7. **API/Interface**: Public surface
8. **Implementation Plan**: Phased CLs with verification
9. **Edge Cases**: Failure modes
10. **Troubleshooting**: Predicted issues
11. **Future Expansion**: Growth paths

---

## Reviewer Prompts

### For myst-dev-kit:radical-design-critic

```
Review the design document at <game Docs dir>/{filename}.md.

Critically analyze for:
- Edge cases that could break the design
- UX friction points or confusing interactions
- Hidden complexity or scope creep
- Missing error states or failure modes
- Assumptions that may not hold
- Potential for player confusion
- LD (Level Designer) usability concerns

Provide specific, actionable feedback with document section references.
Categorize issues as BLOCKING / WARNING / INFO.
Suggest concrete improvements, not just problems.

End your response with a single line of the form:
  Verdict: GREEN | WARNING | BLOCKING
```

### For myst-dev-kit:architecture-reviewer

```
Review the design document at <game Docs dir>/{filename}.md.

Analyze for architectural consistency:
- Alignment with the patterns and conventions this project already established
- The reviewer's canon (Code Complete, Readable Code, and the game/engine
  sources where they apply) and best practices
- Proper separation of concerns
- API clarity and discoverability
- Integration points with existing systems
- Testability and verification approach
- Performance considerations

Provide specific, actionable feedback with document section references.
Categorize issues as BLOCKING / WARNING / INFO.
Reference existing project patterns where applicable.

End your response with a single line of the form:
  Verdict: GREEN | WARNING | BLOCKING
```

---

## Example Workflow

**User**: "Let's design a dialogue system for NPCs"

**Claude**:
1. Creates `design_npc_dialogue_system_WIP.md` in the game Docs dir
2. Fills in template with dialogue system design
3. Launches both reviewers (it's UX + code):
   - `myst-dev-kit:radical-design-critic` → checks player experience, edge cases
   - `myst-dev-kit:architecture-reviewer` → checks integration with the systems it already exists alongside
4. Receives feedback, updates document (v1.1)
5. Presents updated design with change summary
6. User approves → renames to `design_npc_dialogue_system.md`

---

> [!CAUTION]
> **Never skip the review step.** Even "obvious" designs benefit from a second perspective.
> The cost of iteration in design is far lower than the cost of iteration in code.
