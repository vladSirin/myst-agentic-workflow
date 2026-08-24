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

### Step 3: Launch Reviewers

After creating the initial document, **ALWAYS** launch at least one reviewer agent — via the
Agent tool with the **namespaced** subagent_type (bare names fail to resolve):

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

> **Effort barbell:** design critique is judgment work — launch reviewers at their defined model/effort, never downgraded to save tokens. Only mechanical stages (file inventories, censuses, link sweeps) run cheap (`effort: low` agents or `model: haiku` spawns).

**The prompt carries only what the reviewer cannot already know.** Its review dimensions are
its own — `agents/radical-design-critic.md` §Review Methodology and
`agents/architecture-reviewer.md` §Reference canon / §Review scope and method are the system
prompt, loaded at spawn. Restating them here duplicates the *generator* half of the mandate
while dropping the restraint clauses that live only in those files (§2's "a manufactured UX
finding is noise"; "cite, don't name-drop"), which re-anchors the reviewer on producing
findings and hands it none of the brakes. Do not re-add a dimension list.

```
Agent tool with:
  subagent_type: "myst-dev-kit:radical-design-critic" OR "myst-dev-kit:architecture-reviewer"
  prompt: |
    Review the design document at <game Docs dir>/{filename}.md.

    Observed facts you cannot reach yourself (values read, not inferred):
    {observed facts, or "none - nothing in this document required observation"}

    Apply your own review methodology. Cite document sections. Categorize
    findings BLOCKING / WARNING / INFO.

    End your response with a single line of the form:
      Verdict: GREEN | WARNING | BLOCKING
```

On a **re-review**, add only what changed: which findings you fixed, which you declined and
why, and whether you adopted the reviewer's prescription. The fix answers the finding and
nothing else — your reasoning goes in the re-review brief, never into the document. New
rationale prose is new reviewable surface, and prose is where the churn was measured to live.

Each reviewer ends its response with a literal `Verdict: GREEN | WARNING | BLOCKING` line —
parse that token; never infer approval from prose, and treat a response without it as
ambiguous (ask the reviewer again or present the findings to the user).

### Step 4: Iterate at Least Once

After receiving reviewer feedback:

1. Update the document to address BLOCKING and WARNING findings (record an explicit
   accept/defer decision for any WARNING you do not fix)
2. Add entry to Change Log with version bump
3. Present summary of changes to user
4. Re-run **only the reviewer whose BLOCKING findings you addressed**, not both. One whose
   findings you did not act on has nothing to re-verify, and re-running it invites new
   findings on unchanged text.

   **Stopping rule — this matters more on a document than on a CL.** A round that produces no
   BLOCKING finding is the last round: record the remaining WARNING and INFO items with an
   explicit accept/defer decision and finalize. Do not spend another pass driving a
   WARNING-only report to silence; on prose that pass reliably produces a fresh WARNING-only
   report, and the loop has no natural end. Nothing here has a validator behind it — no tool
   checks a design document — so every finding is a real finding and the stopping rule is the
   only thing that ends the loop. A section that arrives mid-review gets its own document; it
   does not restart this review.

Do not finalize a document whose latest verdict is BLOCKING.

### Step 5: Finalize

When design is approved:
1. Remove the `_WIP` suffix from the filename (do NOT add `_Updated` or any other suffix)
2. Update **Status** header in document: `WIP` → `APPROVED` or `COMPLETE`
3. Present the final document to the user

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

## Notes

- Always check existing docs in the game Docs dir (`Myst_Proto/Docs/` here) for related designs before starting
- Reference `split_fiction_scripts/` for AngelScript patterns when applicable
- Follow the project's established architecture patterns (FrogEvent, Subsystems, etc.)
- Keep designs LD-friendly as per project philosophy

> [!CAUTION]
> **Never skip the review step.** Even "obvious" designs benefit from a second perspective.
> The cost of iteration in design is far lower than the cost of iteration in code.
