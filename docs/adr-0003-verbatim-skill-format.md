# ADR 0003 — Skills adopt upstream's SKILL.md format verbatim (drop the house `# H1` / `<command-name>` convention)

**Status**: Accepted

**Date**: 2026-06-22

**Context owners**: package maintainers

## Context

ADR-0002 established that upstream-inherited skills must be faithful to upstream in **name, body, and architecture**. This ADR extends "faithful" to include **format**: the exact `SKILL.md` shape.

Upstream `mattpocock/skills` writes each skill as **YAML frontmatter + markdown body**:

```yaml
---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs… Use when the user says "diagnose"/"debug this"…
---

# Diagnosing Bugs
<body>
```

Our package had transformed every skill into a **house format** — `# <description>` as the H1, a `<command-name>` line, no frontmatter. That transform:

- **dropped upstream's frontmatter**, so we could not express upstream's invocation model (`disable-model-invocation` / `user-invocable`) — this was the unanswered "why do we reject `disable-model-invocation`" question;
- made our copies **gratuitously diverge** from upstream, defeating clean `compare` diffs and re-vendoring;
- added a `<command-name>` line that **isn't a real field** in any of the three tools (the command name comes from the skill **directory** name).

Upstream also formalized a **user-invoked vs model-invoked** taxonomy (`docs/invocation.md`): user-invoked skills set `disable-model-invocation: true` with a plain description; model-invoked skills omit it and carry rich "Use when…" trigger text. Our house format could represent neither.

## Decision

**Every `SKILL.md` is vendored in upstream's frontmatter+body format, near-verbatim.**

- **Claude** and **Codex**: byte-identical to upstream's `SKILL.md` (frontmatter + body). `{{placeholder}}` substitution still applies where a value is genuinely project-specific.
- **OpenCode**: identical, with the single tool-required addition `compatibility: opencode` in the frontmatter.
- The house `# H1`-as-description and `<command-name>` lines are **removed**. The command name is the skill **directory** name in all three tools.
- Upstream's invocation fields (`disable-model-invocation`, `argument-hint`, `user-invocable`, …) are carried through verbatim — they now work where the tool supports them.

### Per-tool support (verified 2026-06-22)

| Tool | Discovery | Frontmatter / invocation |
|---|---|---|
| **Claude Code** | `.claude/skills/<name>/SKILL.md`; **dir name = command**; frontmatter optional | Native: `name`, `description`, `disable-model-invocation`, `user-invocable`, `argument-hint`, … all honored. |
| **Codex** | documented in `AGENTS.md`; no frontmatter parser | Frontmatter is harmless metadata; body + `AGENTS.md` listing drive use. Safe; future-proof. |
| **OpenCode** | registered via `opencode.json`; already frontmatter-based | Frontmatter-aware; keep `compatibility: opencode`. |

## Consequences

- **Positive**: maximal faithfulness — claude/codex skills are byte-identical to upstream, so `compare-with-package.ps1` shows clean diffs and re-vendoring is mechanical. Upstream's invocation model works natively in Claude Code. The format convergence and the content convergence become **one operation** ("vendor upstream HEAD verbatim").
- **Negative / rework**: every skill file changes shape. Skills already vendored in the old house format (`diagnosing-bugs`, and Phase-A `domain-modeling`/`grilling`/`teach`) are re-wrapped to frontmatter; the local-only `roundtable` is given proper frontmatter. CLAUDE.md/AGENTS.md skill listings stay valid (command = dir name).
- **Open sub-decision — overlay surfacing**: dropping the house footer removes the base→`*-NOTES.md` pointer. With a verbatim base we cannot also append an overlay fragment to the same `copy` file idempotently (ADR-0002 engine gap). How a `ue`-overlay companion (e.g. `diagnosing-bugs/UE-NOTES.md`) is surfaced to the agent — via the consumer bible's overlay block, or an accepted minimal footer as a documented overlay-architecture exception — is resolved in Phase B.

## Validation

Proven by re-wrapping the already-merged skills (`diagnosing-bugs`, `domain-modeling`, `grilling`, `teach`) + `roundtable` to verbatim frontmatter, with all test suites green and install idempotent. The remaining skills converge to this format as part of the Phase-B faithful HEAD vendoring.
