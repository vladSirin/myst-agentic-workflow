---
name: design
description: "Create a design document with reviewer-agent feedback and iterate to approval. Use when the user asks to design a feature or system (/design), or when writing or updating any design doc."
---

# Design Document Workflow

<command-name>design</command-name>

## Purpose

This skill automates the creation and review of design documents. When invoked for design or planning work, it:
1. Creates a properly formatted design document in the game project's Docs dir (`Myst_Proto/Docs/` here; see the CLAUDE.md Project section)
2. Launches reviewer agents to critique the design
3. Iterates on the document based on feedback

**Process authority lives in [PROCESS.md](PROCESS.md)** — file naming, location, reviewer routing, iteration/verdict rules, and the finalization lifecycle. Read it before creating the file; this file is only the automation flow.

## Instructions

You are now in **Design Document Mode**. Follow this workflow:

### Step 1: Gather Requirements

Ask the user clarifying questions if needed to understand:
- **Topic**: What system/feature is being designed?
- **Scope**: Is this a new system, extension, or refactor?
- **Type**: Design document (`design_*`) or plan document (`plan_*`)?

### Step 2: Create the Document

Search for an existing related document first (see [PROCESS.md](PROCESS.md) §"Search before you create"), then create the document in the game Docs dir, named per the [PROCESS.md](PROCESS.md) naming table.

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

After creating the initial document, launch reviewer agents using the Agent tool, routed per the [PROCESS.md](PROCESS.md) routing table:

> **Effort barbell:** design critique is judgment work — launch reviewers at their defined model/effort, never downgraded to save tokens. Only mechanical stages (file inventories, censuses, link sweeps) run cheap (`effort: low` agents or `model: haiku` spawns).

- **Design documents** (game mechanics, UX, features) → launch `myst-dev-kit:radical-design-critic`
- **Architecture/implementation plans** (code structure, systems) → launch `myst-dev-kit:architecture-reviewer`
- **Comprehensive designs** (UX + code) → launch both agents in parallel

Use this Agent tool invocation pattern — always the **namespaced** subagent_type (bare names fail to resolve); full reviewer prompts are in [PROCESS.md](PROCESS.md):

```
Agent tool with:
  subagent_type: "myst-dev-kit:radical-design-critic" OR "myst-dev-kit:architecture-reviewer"
  prompt: "Review the design document at <game Docs dir>/{filename}.md. ..."
```

Each reviewer ends its response with a literal `Verdict: GREEN | WARNING | BLOCKING` line — parse that token; never infer approval from prose.

### Step 4: Iterate on Feedback

Apply the iteration and verdict rules in [PROCESS.md](PROCESS.md):

1. Read the reviewer feedback
2. Update the document to address BLOCKING and WARNING findings (or record an explicit accept/defer decision)
3. Add a new entry to the Change Log
4. Present the updated document to the user with a summary of changes
5. Re-run **only the reviewer(s) whose BLOCKING findings you addressed** — the re-review
   rules in [RE-REVIEW.md](../review-and-submit/RE-REVIEW.md) govern document reviews too
   (all but rule 4, which has no validator analogue here)

### Step 5: Mark Document Ready

When iteration is complete, finalize the filename and the **Status** header per the lifecycle in [PROCESS.md](PROCESS.md) §Finalize, then present the final document to the user.

---

## Example Invocation

User: "Design a checkpoint save system for the game"

You would:
1. Create `design_checkpoint_save_system_WIP.md` in the game Docs dir (`Myst_Proto/Docs/` here)
2. Fill in the template with checkpoint system design
3. Launch `myst-dev-kit:architecture-reviewer` (since it's a code system)
4. Launch `myst-dev-kit:radical-design-critic` (since it affects player experience)
5. Iterate based on feedback
6. Finalize per [PROCESS.md](PROCESS.md) and present the final document

---

## Notes

- Always check existing docs in the game Docs dir (`Myst_Proto/Docs/` here) for related designs before starting
- Reference `split_fiction_scripts/` for AngelScript patterns when applicable
- Follow the project's established architecture patterns (FrogEvent, Subsystems, etc.)
- Keep designs LD-friendly as per project philosophy
