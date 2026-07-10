---
name: design
description: "Create a design document with reviewer-agent feedback and iterate to approval. Use when the user asks to design a feature or system (/design)."
---

# Design Document Workflow

<command-name>design</command-name>

## Purpose

This skill automates the creation and review of design documents. When invoked for design or planning work, it:
1. Creates a properly formatted design document in `{{game_docs_root}}/`
2. Launches reviewer agents to critique the design
3. Iterates on the document based on feedback

## Instructions

You are now in **Design Document Mode**. Follow this workflow:

### Step 1: Gather Requirements

Ask the user clarifying questions if needed to understand:
- **Topic**: What system/feature is being designed?
- **Scope**: Is this a new system, extension, or refactor?
- **Type**: Design document (`design_*`) or plan document (`plan_*`)?

### Step 2: Create the Document

Create the document at `{{game_docs_root}}/` with this naming convention:
- Design docs: `design_{feature_name}_WIP.md`
- Plan docs: `plan_{feature_name}_WIP.md`

Use this template structure:

```markdown
# {Feature Name} Design

**Version**: v1.0 | **Updated**: {YYYY-MM-DD}
**Reference**: {Similar systems or patterns} | **Status**: WIP

---

## Change Log
| Ver | Date | Changes |
|-----|------|---------|
| v1.0 | {date} | Initial design document |

---

## Overview

{Brief 2-3 sentence description of what this system does and why}

> [!IMPORTANT]
> **Goal**: {Core goal in one line}

---

## Design Philosophy

### 1. {Key Principle 1}
{Description with code example if applicable}

### 2. {Key Principle 2}
{Description}

---

## Architecture

```
{ASCII diagram showing system structure and relationships}
```

---

## File Structure

```
{Directory tree showing where files will live}
```

---

## API / Interface

{Tables and code examples showing the public interface}

---

## Implementation Plan

### CL X.1: {First Milestone}
**Deliverables**: {bullet list}
**Verification**: {how to test}

### CL X.2: {Second Milestone}
**Deliverables**: {bullet list}
**Verification**: {how to test}

---

## Edge Cases & Considerations

{List potential edge cases, failure modes, and how they're handled}

---

## Troubleshooting (Predicted)

| Issue | Cause | Fix |
|-------|-------|-----|
| {Issue} | {Why} | {Solution} |

---

## Future Expansion

| Feature | Implementation Approach |
|---------|------------------------|
| {Feature} | {How it could be added} |
```

### Step 3: Launch Reviewers

After creating the initial document, launch reviewer agents using the Task tool:

**For Design Documents** (game mechanics, UX, features):
- Launch `radical-design-critic` to stress-test the design for edge cases, UX concerns, and fragilities

**For Architecture/Implementation Plans** (code structure, systems):
- Launch `architecture-reviewer` to analyze architectural consistency and potential improvements

**For Both** (comprehensive designs with UX + code):
- Launch both agents in parallel

Use this Task tool invocation pattern:

```
Task tool with:
  subagent_type: "radical-design-critic" OR "architecture-reviewer"
  prompt: "Review the design document at {{game_docs_root}}/{filename}.md.
           Analyze it for: {relevant concerns based on doc type}.
           Provide specific, actionable feedback with line references.
           Focus on: edge cases, failure modes, UX friction, architectural consistency,
           missing considerations, and potential improvements.
           Output a structured review with HIGH/MEDIUM/LOW priority items."
```

### Step 4: Iterate on Feedback

1. Read the reviewer feedback
2. Update the document to address HIGH and MEDIUM priority items
3. Add a new entry to the Change Log
4. Present the updated document to the user with a summary of changes

### Step 5: Mark Document Ready

When iteration is complete:
1. Rename file suffix from `_WIP` to appropriate status (`_Updated`, `_Final`, etc.)
2. Update the **Status** header in the document
3. Present final document to user

---

## Example Invocation

User: "Design a checkpoint save system for the game"

You would:
1. Create `{{game_docs_root}}/design_checkpoint_save_system_WIP.md`
2. Fill in the template with checkpoint system design
3. Launch `architecture-reviewer` (since it's a code system)
4. Launch `radical-design-critic` (since it affects player experience)
5. Iterate based on feedback
6. Present final document

---

## Notes

- Always check existing docs in `{{game_docs_root}}/` for related designs before starting
- Reference `split_fiction_scripts/` for AngelScript patterns when applicable
- Follow the project's established architecture patterns (FrogEvent, Subsystems, etc.)
- Keep designs LD-friendly as per project philosophy
