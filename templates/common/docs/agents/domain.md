# Domain Docs

This repo is treated as single-context for now.

## Before exploring, read these

- `CONTEXT.md` at the repo root, if it exists
- `Docs/adr/` for architectural decision records that touch the area you are working in

If `CONTEXT-MAP.md` appears later, switch to multi-context behavior and follow it for context-scoped docs.

## Current layout

Single-context repos use one root `CONTEXT.md` plus `Docs/adr/`.

## Consumer rule

Use the vocabulary in `CONTEXT.md` when naming issues, refactors, hypotheses, or tests. If a term is not defined there yet, treat that as a signal to check with the existing domain language before inventing a synonym.

`CONTEXT.md` is a glossary only. Do not use it as a spec, scratch pad, implementation plan, or repository for implementation decisions. Durable implementation decisions belong in ADRs.
