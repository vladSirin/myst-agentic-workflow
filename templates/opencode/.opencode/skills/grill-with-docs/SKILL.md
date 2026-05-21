---
name: grill-with-docs
description: Stress-test a plan against project language and documented decisions, then update context or ADR docs as decisions solidify. Use when the user wants to be grilled on a plan with docs.
compatibility: opencode
---

# Grill With Docs

Read `Docs/MustRead/MustRead_agentic_workflow.md` and `Docs/agents/domain.md`.

Ask one question at a time and provide a recommended answer for each. Explore the codebase instead of asking when the answer can be found locally.

Create or update `CONTEXT.md` only when stable project language has actually emerged.

Keep `CONTEXT.md` as a glossary only. Do not use it as a spec, scratch pad, implementation plan, or repository for implementation decisions.

Create ADRs only for durable architectural decisions worth preserving.
