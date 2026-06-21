# Diagnose — UE5 / Perforce project notes

Project-specific adaptation of the `/diagnose` discipline for this Unreal Engine 5 + Perforce codebase. Read this alongside the base skill — it does **not** replace the six phases, it tailors them to this project's tools and version control.

## Phase 1 — feedback loops in this project

The base skill's web-flavoured examples (curl, Playwright, `git bisect`) rarely apply here. Prefer, in rough order:

1. **Automation specs / functional tests** run headless via `-ExecCmds="Automation RunTests <Filter>"` (or your project's test commandlet). This is the closest thing to a fast deterministic loop in UE.
2. **Headless editor / commandlet run** with `-ExecCmds`/`-run=<Commandlet>` against a fixture map or asset, diffing log output against a known-good snapshot.
3. **Replay a captured trace** — save a real input sequence, gameplay recording, or event log and replay it through the system in isolation.
4. **Bisect with Perforce**, not git: sync to prior changelists (`p4 sync //depot/...@<CL>`) and re-run the check, narrowing the offending CL. Automate "sync → build → check → repeat" where feasible.
5. **HITL loop (common here, last resort).** Unreal Editor feel, gameplay, asset/material state, VFX, and level validation often cannot be checked automatically. When a HITL loop is genuinely needed, write the minimal issue-local checklist or script into `.scratch/<feature-slug>/` and drive the human through it so the loop stays structured and its output feeds back to you.

## Binary assets

`.uasset` / `.umap` are binary — `Read`/`Grep` on them is useless. Inspect via the Unreal Engine MCP tools (see the `unrealmcprules` rule), the editor, or a commandlet. Never build a "loop" that greps binary assets as text.

## Phase 5–6 — fix, regression, submit

- Keep changes surgical and respect the Perforce changelist workflow. If the `perforce` overlay is installed, follow `ReviewAndSubmit` (pre-submit/CL-description protocol) and `ChangelistVerification` (CL-by-CL execution) when landing the fix.
- Record unresolved human checks as `resolved`, not `closed`, so the verification step is explicit.
- A "regression test" here is usually an automation spec at the correct seam. If no automation seam exists for the bug pattern, that absence is itself the finding (per base Phase 5) — flag it for `/improve-codebase-architecture`.

## Project docs

The base skill refers to "the project's domain glossary" — in this project that is `Docs/agents/domain.md`. Read it for the domain model before diagnosing.
