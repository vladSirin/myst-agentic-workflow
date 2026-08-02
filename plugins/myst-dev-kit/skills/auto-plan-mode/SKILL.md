---
name: auto-plan-mode
description: "Use before the first Edit or Write of any request, to decide whether the work needs a plan first."
---

# Plan Mode — When to use it

Plan mode is for **alignment before commitment**. Use it when the cost of going down the wrong path is high; skip it when the work is small or read-only.

---

## Use plan mode when

- **Multi-file changes** — anything touching 2+ files in a coordinated way
- **Implementation work** — about to write/edit code that will be reviewed or submitted
- **Multi-step plans** — when proposing more than a single immediate action
- **Destructive or hard-to-reverse ops** — deletes, `p4 revert`, force pushes, migrations, dependency changes
- **The user explicitly asks for a plan** — "give me a plan", "what's the approach", "let's think through this"
- **About to propose CLs** — see [PreImplementationGate.md](PreImplementationGate.md) for the additional check that fires here

Enter plan mode yourself with `EnterPlanMode` — don't wait to be asked. Present the plan with `ExitPlanMode` and **wait for explicit user approval before executing.**

**Exception — `/goal` runs**: do NOT enter plan mode. `ExitPlanMode` waits on an approval that goal mode explicitly forbids you to pause for, while its Stop hook blocks stopping — at best auto-granted and the gate is theatre, at worst the run stalls with nobody there to answer. State the plan in your reply and proceed.

---

## Skip plan mode when

- **Single-file edits** with no architectural impact (typo fix, comment update, small bug fix in one function)
- **Read-only operations** — Read, Grep, Glob, status queries, `p4 describe`, viewing logs
- **Lookups** — searching for a symbol, finding a file, checking what's in a directory
- **Individual edits inside an already-planned task** — once the user has approved a plan, don't re-plan each Edit/Write call within it
- **Conversational responses** — answering questions, explaining behavior, summarizing
- **Trivial corrections** — when you spot and fix a typo while reading

Plan mode for every grep would be noise. Plan mode for "I'm about to refactor three files" is the point.

---

## Why this exists

Approval doesn't carry across user instructions — each new task starts fresh on whether plan mode applies. But "fresh" doesn't mean "every tool call needs a plan." It means: when a *new task* arrives, decide whether the work is in the "use plan mode" list or the "skip plan mode" list.

---

## Related

- [PreImplementationGate.md](PreImplementationGate.md) — when in plan mode for multi-CL work, this gate fires before the plan body is drafted.
- [ChangelistVerification.md](ChangelistVerification.md) — once a plan is approved and multiple CLs are executing, this rule kicks in.
- [DesignWorkflow.md](../design-workflow/SKILL.md) and [AgenticWorkflow.md](../agentic-workflow/SKILL.md) — both require searching for an existing plan/spec before creating a new one.
