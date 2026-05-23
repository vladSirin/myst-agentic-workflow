# CRITICAL WORKFLOW REQUIREMENT

## Mandatory Plan Discovery

Before creating ANY new plan or design, you **MUST** check for existing plans:

---

## Search Order (MANDATORY)

Check these locations IN ORDER before generating a new plan:

### 1. Project Plans (Highest Priority)
```
{{game_docs_root}}/plan_*.md
{{game_docs_root}}/design_*.md
```

### 2. User Claude Plans
```
~/.claude/plans/*.md
%USERPROFILE%\.claude\plans\*.md
```

### 3. Session Memory
```
~/.claude/projects/{project}/memory/*.md
```

---

## Hard Rule

> [!CAUTION]
> **NEVER** generate a new plan from scratch if a related plan exists in ANY of the above locations.
>
> You MUST:
> 1. Search for existing plans using Glob/Grep before planning
> 2. Read and reference existing plans when found
> 3. Build upon or update existing plans rather than replacing them
> 4. Only create new plans when NO related plan exists

---

## Search Triggers

When the user mentions ANY of these topics, FIRST search for existing plans:

- Feature names (e.g., "checkpoint", "dialogue", "mission")
- Phase numbers (e.g., "Phase 8", "Phase 9")
- System names (e.g., "FrogEvent", "Flow", "Objective")
- Keywords: "plan", "design", "implement", "build", "create"

---

## Search Commands

Run these searches BEFORE planning:

```bash
# Project design docs
Glob: {{game_docs_root}}/*{keyword}*.md

# User plans directory
Glob: ~/.claude/plans/*{keyword}*.md
Glob: %USERPROFILE%\.claude\plans\*{keyword}*.md

# Grep for topic mentions
Grep: pattern="{keyword}" path="{{game_docs_root}}/" glob="*.md"
```

---

## When Existing Plan Found

1. **Read the existing plan completely**
2. **Present it to the user**: "I found an existing plan at {path}. Should I use this as the basis?"
3. **Update rather than replace**: Add new sections, update status, increment version
4. **Preserve history**: Keep the change log, don't overwrite previous decisions

---

## When No Plan Found

Only then may you:
1. Create a new plan using the `/design` workflow
2. Save it to the appropriate location (`{{game_docs_root}}/`)
3. Run reviewer agents as per `DesignWorkflow.md`

---

## Enforcement

If you create a new plan without first searching for existing plans, you have violated this requirement.

**Workflow**: `Search → Read Existing → Update/Extend` (NEVER: `Generate New → Ignore Existing`)
