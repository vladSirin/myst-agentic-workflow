---
name: design-workflow
description: "Team process for creating and routing design documents (naming, location, reviewer agents, iteration loop). Use when writing or updating any design doc."
---

# Design & Planning Workflow

## Automatic Detection

When the user requests design or planning work, you **MUST** follow this workflow. Triggers include:

- Explicit: "design", "plan", "architect", "spec", "proposal"
- Implicit: "how should we implement", "what's the best approach for", "let's think through"

---

## Mandatory Workflow

> **Naming rules**: See `Claude/DocumentStandard.md` for the full naming convention and lifecycle.

### 1. Create Document First

**ALWAYS** create a design document in `{{game_docs_root}}/` before any implementation:

| Request Type | File Naming | Example |
|--------------|-------------|---------|
| Feature design | `design_{feature}_WIP.md` | `design_checkpoint_system_WIP.md` |
| Implementation plan | `plan_{feature}_WIP.md` | `plan_phase9_audio_WIP.md` |
| System architecture | `design_{system}_architecture_WIP.md` | `design_save_system_architecture_WIP.md` |
| Refactor proposal | `design_{area}_refactor_WIP.md` | `design_event_system_refactor_WIP.md` |

### 2. Launch Reviewers

After creating the initial document, **ALWAYS** launch at least one reviewer agent:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Document Type Routing                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Game Design / UX / Features     →  radical-design-critic          │
│  (gameplay mechanics, player                                        │
│   experience, UI flows)                                             │
│                                                                     │
│  Code Architecture / Systems     →  architecture-reviewer          │
│  (subsystems, plugins, APIs,                                        │
│   implementation patterns)                                          │
│                                                                     │
│  Comprehensive Design            →  BOTH agents (parallel)         │
│  (new features with code +                                          │
│   player-facing elements)                                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 3. Iterate at Least Once

After receiving reviewer feedback:

1. Update the document to address HIGH and MEDIUM priority issues
2. Add entry to Change Log with version bump
3. Present summary of changes to user
4. (Optional) Re-run reviewers if major changes were made

### 4. Finalize

When design is approved:
1. Remove the `_WIP` suffix from the filename (do NOT add `_Updated` or any other suffix)
2. Update **Status** header in document: `WIP` → `APPROVED` or `COMPLETE`

---

## Document Template

Use the standard template from the `/design` skill. Key sections:

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

### For radical-design-critic

```
Review the design document at {{game_docs_root}}/{filename}.md.

Critically analyze for:
- Edge cases that could break the design
- UX friction points or confusing interactions
- Hidden complexity or scope creep
- Missing error states or failure modes
- Assumptions that may not hold
- Potential for player confusion
- LD (Level Designer) usability concerns

Provide specific, actionable feedback with document section references.
Categorize issues as HIGH / MEDIUM / LOW priority.
Suggest concrete improvements, not just problems.
```

### For architecture-reviewer

```
Review the design document at {{game_docs_root}}/{filename}.md.

Analyze for architectural consistency:
- Alignment with existing patterns (FrogEvent, Subsystems, AngelScript)
- Code Complete principles and best practices
- Proper separation of concerns
- API clarity and discoverability
- Integration points with existing systems
- Testability and verification approach
- Performance considerations

Provide specific, actionable feedback with document section references.
Categorize issues as HIGH / MEDIUM / LOW priority.
Reference existing project patterns where applicable.
```

---

## Example Workflow

**User**: "Let's design a dialogue system for NPCs"

**Claude**:
1. Creates `{{game_docs_root}}/design_npc_dialogue_system_WIP.md`
2. Fills in template with dialogue system design
3. Launches both reviewers (it's UX + code):
   - `radical-design-critic` → checks player experience, edge cases
   - `architecture-reviewer` → checks integration with FrogEvent, subsystems
4. Receives feedback, updates document (v1.1)
5. Presents updated design with change summary
6. User approves → renames to `design_npc_dialogue_system.md`

---

> [!CAUTION]
> **Never skip the review step.** Even "obvious" designs benefit from a second perspective.
> The cost of iteration in design is far lower than the cost of iteration in code.
