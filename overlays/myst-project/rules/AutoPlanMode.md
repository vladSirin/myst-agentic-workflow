# Auto Plan Mode

**HARD RULE (advisory):** At the START of every new user request, decide whether it needs plan
mode — and enter it yourself with `EnterPlanMode`. Do not wait to be asked. This rule is
auto-loaded every session precisely so the decision never depends on remembering to load a skill.

Plan mode is for **alignment before commitment**: cheap when the wrong path is expensive, noise
when the work is small or read-only.

**Enter** for: 2+ files touched in a coordinated way; implementation that will be reviewed or
submitted; multi-step plans; destructive or hard-to-reverse ops (deletes, `p4 revert`, migrations,
dependency changes); anything about to propose CLs (`PreImplementationGate` also fires there,
before the plan body); or when the user asks for a plan. Present with `ExitPlanMode` and **wait
for explicit approval before executing**.

**Skip** for: single-file edits with no architectural impact; read-only work (Read/Grep/Glob,
status queries, `p4 describe`, logs, diagnosis); lookups; steps inside an already-approved plan;
conversational answers; trivial corrections spotted in passing.

Plan mode for every grep is noise. Plan mode for "refactor these three files" is the point.

## Goal-mode carve-out

In a `/goal` run — identified ONLY by the session-scoped Stop-hook notice in context, never
inferred — **do not enter plan mode**: `ExitPlanMode` waits on a human approval that goal mode
forbids you to pause for, while its Stop hook blocks stopping. State the plan in your reply,
proceed, and let the downstream gates do the work — the submit gate (hard rule 6) still stands,
and `ready-for-human` CLs still shelve.

## Notes

- Approval does not carry across user instructions — each new request re-decides. "Fresh" means
  per request, NOT per tool call.
- Read-only diagnosis stays out of plan mode even when the *subject* is a big refactor. What
  matters is what YOU are about to do, not what the code's problem is.

Related: `PreImplementationGate.md` (multi-CL work needs spec/tickets/triage before the plan body),
`design-workflow` / `agentic-workflow` skills (search for an existing plan/spec before drafting a
new one), `auto-plan-mode` skill (worked examples and the full rationale).
