# CRITICAL WORKFLOW REQUIREMENT

## Mandatory Plan Discovery

Before creating ANY new plan or design, you **MUST** check for existing plans:

---

## Search Order (MANDATORY)

Check these locations IN ORDER before generating a new plan. The first two reflect the project's two parallel workflows — search both:

### 1a. Game design docs ({{game_docs_root}}/) — for [DesignWorkflow.md](DesignWorkflow.md) scope
```
{{game_docs_root}}/plan_*.md
{{game_docs_root}}/design_*.md
{{game_docs_root}}/guide_*.md
```

### 1b. Code/system PRDs (.scratch/) — for [AgenticWorkflow.md](AgenticWorkflow.md) scope
```
.scratch/*/PRD.md
.scratch/*/issues/*.md
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

### How 1a and 1b relate

These two are not parallel choices — they sequence into each other. `DesignWorkflow` produces 1a; finalizing it then hands off to `AgenticWorkflow`, which produces 1b. A given feature may have BOTH a design doc and a PRD (the PRD references the design doc). Always search both; if you find one, look for the other.

- Game-design work that will lead to implementation: a design doc in 1a may exist; a PRD in 1b may also exist. The design doc is the Discussion-phase artifact, the PRD is the implementation-intent artifact.
- Code-only / bugfix / pipeline work: typically only 1b is populated (Discussion stayed in chat).
- Game-design-only deliverables (no code): typically only 1a is populated.

If you find one but not the other, that's a signal about where the work currently is in the pipeline, not a sign that the other location is wrong to look in.

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
