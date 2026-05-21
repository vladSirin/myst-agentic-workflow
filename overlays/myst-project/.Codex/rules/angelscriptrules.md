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