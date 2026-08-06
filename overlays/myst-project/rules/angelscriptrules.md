---
trigger: model_decision
description: When writing AngelScript code
---

## AngelScript Reference Architecture
**Rule:** When writing AngelScript code, **always consult** the following reference sources for patterns, best practices, and API usage:
| Priority | Path | Purpose |
|----------|------|---------|
| 1 | `/split_fiction_scripts/Script/` | Production-grade patterns from *Split Fiction* (Animation, Audio, Core, Gameplay, GUI) |
| 2 | `/Myst_Proto/Script/Examples/` | 50+ learning examples covering AngelScript fundamentals |
| 3 | `/Myst_Proto/Script/` | Project-specific implementations (`MovingActor.as`, `ObjectiveSystem/`, etc.) |
**Mechanism:** Ensures consistency with established patterns, prevents reinventing the wheel, and maintains style uniformity across the codebase.
> [!TIP]
> For complex systems (e.g., Animation, GAS, Audio), prioritize `split_fiction_scripts` as it contains battle-tested, shipped code.

> [!NOTE]
> **Enforcement scope (accepted gap):** where a consumer project wires a write-time hook to enforce AngelScript naming/placement rules, that hook sees only the agent's Write/Edit tool calls -- file writes made through Bash/PowerShell/python (or any other shell command) bypass it. Those scripted writes are caught only by the advisory submit-time audit, so treat the hook as a guardrail, not a guarantee.