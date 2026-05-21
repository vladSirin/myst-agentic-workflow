# Grill With Docs

<command-name>grill-with-docs</command-name>

## Purpose

Stress-test a plan against project language and documented decisions, then update docs as decisions crystallize.

## Project setup

- Domain docs: `Docs/agents/domain.md`

## Instructions

When invoked, follow this repo's project-local grill-with-docs workflow:

1. Ask one question at a time and provide a recommended answer for each.
2. Explore the codebase instead of asking when the answer can be found locally.
3. Create or update `CONTEXT.md` only when stable project language has actually emerged.
4. Keep `CONTEXT.md` as a glossary only. Do not use it as a spec, scratch pad, implementation plan, or repository for implementation decisions.
5. Create ADRs only for durable architectural decisions worth preserving.
6. Keep docs aligned with `Docs/agents/domain.md` and the repo's Perforce workflow.
7. When creating `CONTEXT.md` or ADRs, use the existing style in this repo.
