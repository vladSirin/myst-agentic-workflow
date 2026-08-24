---
name: design
description: "Write a design or plan document: correct name, correct location, standard template, WIP-to-final lifecycle. Use when the user asks to design a feature or system (/design), or when writing or updating any design doc."
---

# Design Document

<command-name>design</command-name>

## Purpose

This skill writes design and plan documents: it finds whether one already exists, names and
places the new one correctly, fills the standard template, and carries it through the
WIP-to-final lifecycle. Its scope is **the document** — reviewing what the document proposes is
a separate job and is not done here.

## Automatic Detection

When the user requests design or planning work, you **MUST** follow this process. Triggers include:

- Explicit: "design", "plan", "architect", "spec", "proposal"
- Implicit: "how should we implement", "what's the best approach for", "let's think through"

---

## Instructions

You are now in **Design Document Mode**. Follow this workflow:

### Step 1: Gather Requirements

Ask the user clarifying questions if needed to understand:
- **Topic**: What system/feature is being designed?
- **Scope**: Is this a new system, extension, or refactor?
- **Type**: Design document (`design_*`) or plan document (`plan_*`)?

### Step 2: Create the Document

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

### Step 3: Finalize

When the user approves the design:
1. Remove the `_WIP` suffix from the filename (do NOT add `_Updated` or any other suffix)
2. Update **Status** header in document: `WIP` → `APPROVED` or `COMPLETE`
3. Present the final document to the user

---

## Example Workflow

**User**: "Let's design a dialogue system for NPCs"

**Claude**:
1. Creates `design_npc_dialogue_system_WIP.md` in the game Docs dir
2. Fills in template with dialogue system design
3. Presents it to the user
4. Revises on the user's notes, bumping the Change Log to v1.1
5. User approves → renames to `design_npc_dialogue_system.md`, Status `WIP` → `APPROVED`

---

## Notes

- Always check existing docs in the game Docs dir (`Myst_Proto/Docs/` here) for related designs before starting
- Reference `split_fiction_scripts/` for AngelScript patterns when applicable
- Follow the project's established architecture patterns (FrogEvent, Subsystems, etc.)
- Keep designs LD-friendly as per project philosophy
