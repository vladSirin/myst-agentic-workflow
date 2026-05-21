# Design Document Workflow

## Purpose

Use this skill to create and review design documents. When invoked for design or planning work, it:

1. Creates a properly formatted design document in `{{game_docs_root}}/`
2. Routes the document through the relevant reviewer agents
3. Iterates on the document based on review feedback

## Instructions

You are now in Design Document Mode. Follow this workflow.

## Step 1: Gather Requirements

Ask clarifying questions only when needed to understand:

- Topic: what system or feature is being designed
- Scope: new system, extension, or refactor
- Type: design document (`design_*`) or plan document (`plan_*`)

## Step 2: Create the Document

Create the document at `{{game_docs_root}}/` with this naming convention:

- Design docs: `design_{feature_name}_WIP.md`
- Plan docs: `plan_{feature_name}_WIP.md`

Use this template structure:

````markdown
# {Feature Name} Design

**Version**: v1.0 | **Updated**: {YYYY-MM-DD}
**Reference**: {Similar systems or patterns} | **Status**: WIP

## Change Log

| Ver | Date | Changes |
| --- | --- | --- |
| v1.0 | {date} | Initial design document |

## Overview

{Brief 2-3 sentence description of what this system does and why}

> [!IMPORTANT]
> **Goal**: {Core goal in one line}

## Design Philosophy

### 1. {Key Principle 1}

{Description with code example if applicable}

### 2. {Key Principle 2}

{Description}

## Architecture

```text
{ASCII diagram showing system structure and relationships}
```

## File Structure

```text
{Directory tree showing where files will live}
```

## API / Interface

{Tables and code examples showing the public interface}

## Implementation Plan

### CL X.1: {First Milestone}

**Deliverables**: {bullet list}
**Verification**: {how to test}

### CL X.2: {Second Milestone}

**Deliverables**: {bullet list}
**Verification**: {how to test}

## Edge Cases & Considerations

{List potential edge cases, failure modes, and how they are handled}

## Troubleshooting (Predicted)

| Issue | Cause | Fix |
| --- | --- | --- |
| {Issue} | {Why} | {Solution} |

## Future Expansion

| Feature | Implementation Approach |
| --- | --- |
| {Feature} | {How it could be added} |
````

## Step 3: Route Reviewers

After creating the initial document:

- For design documents involving game mechanics, UX, or player-facing features, use `radical-design-critic`.
- For architecture or implementation plans, use `architecture-reviewer`.
- For documents spanning both UX and code architecture, run both reviewers.

Ask reviewers to provide specific, actionable feedback with file and line references where possible.

## Step 4: Iterate

1. Read reviewer feedback.
2. Update the document to address high and medium priority items.
3. Add a new entry to the change log.
4. Present the updated document with a concise change summary.

## Step 5: Mark Ready

When iteration is complete:

1. Rename the file suffix from `_WIP` to the appropriate status.
2. Update the status header in the document.
3. Present the final document to the user.

## Notes

- Always check existing docs in `{{game_docs_root}}/` for related designs before starting.
- Reference `split_fiction_scripts/` for AngelScript patterns when applicable.
- Follow the project's established architecture patterns: FrogEvent, subsystems, and AngelScript conventions.
- Keep designs usable by level designers and gameplay implementers.
