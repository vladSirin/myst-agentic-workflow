# AFK Auto-Submit Workflow

> **Opt-in, dangerous-by-nature, off by default.** This file ships only in the `afk-autonomy`
> overlay — a plain install does not contain it. Even when installed, autonomous submission only
> activates when the user **explicitly arms it** for the session (see Authorization Sources). There
> is deliberately **no enforcement hook** — this is advisory governance the agent must follow, not a
> blocker (a prior hook-enforced version was removed as over-engineering). The default supervised
> `sync-build-submit` / review flows always ask before submitting; this workflow is the only thing
> that authorizes auto-submit, and only for CLs that pass every gate below.

## Purpose

When the user is **A**way **F**rom **K**eyboard, the agent may autonomously `p4 submit` low-risk CLs
that pass a mechanical safety floor. This workflow defines authorization sources, gate criteria, the
dry-run rollout, audit logging, recovery, and reviewer calibration. It is the **explicit opt-out**
from the per-CL verification HARD RULE in the perforce overlay's ChangelistVerification / ReviewAndSubmit
workflows — but only for CLs that pass every gate.

## Setup — configure for your project

The gate **path lists** below are the safety floor; tune them to your repo before arming live:

- **Whitelist** = file globs that are reviewable via text diff and low-risk to auto-submit (e.g. your
  script/source-of-truth text files, docs). Defaults below are examples — replace with yours.
- **Blacklist** = globs that must NEVER auto-submit (binaries, compiled artifacts, engine source,
  protected raw materials). The UE/Perforce defaults below are a sane starting point.

Requires the `perforce` overlay (p4 vocabulary) and a reviewer agent (the `myst-project` overlay's
`architecture-reviewer` / `radical-design-critic`, or your own). Claude Code only in v1 (uses a
SessionStart surfacer).

---

## Hard Rules

> [!CAUTION]
> 1. **Agent never self-promotes a CL to AFK.** Promotion requires an explicit signal from the user
>    (issue triage, per-CL command, per-issue update, or session-wide toggle).
> 2. **Gates always evaluate**, regardless of authorization source. A promoted CL that fails any gate
>    is queued for HITL, never auto-submitted.
> 3. **Reverts are never AFK-eligible.** Even in session-wide AFK, revert CLs require explicit human approval.
> 4. **Blacklisted paths are locked.** No authorization source can bypass the blacklist.

---

## Authorization Sources

AFK status on a CL is **most-recent-explicit-wins**. Sources:

1. **Issue-level** (primary, set during triage): issue markdown under `.scratch/<feature>/issues/`
   carries an `AFK:` line alongside `Status:` (e.g. `Status: ready-for-agent` + `AFK: true`). Default
   if absent: `false`. Propagates to every CL the agent creates for that issue.
2. **Per-issue update**: user says `"Promote issue 042 to AFK"` → agent sets `AFK: true` in the issue file.
3. **Per-CL command** (one-time): `"AFK this CL"` / `"HITL this CL"` → current CL only.
4. **Session-wide** (in-context only, never persisted): `"AFK mode on"` → applies to CLs with no other
   signal. Dies on `/clear`, session restart, `"AFK mode off"`, or an optional expiry
   (`"AFK mode on for 2 hours"` / `"... for 10 CLs"`).

**Conflict resolution:** most-recent-explicit-wins. Per-CL demotion (`"HITL this CL"`) is always
available without ceremony; per-CL promotion requires you to be present and explicit. The agent never
promotes on its own.

| Issue `AFK:` | Session AFK | Per-CL | Result |
|---|---|---|---|
| `false` | off | none | HITL |
| `false` | on | none | AFK (session more recent) |
| `false` | off | `"AFK this CL"` | AFK |
| `true` | off | none | AFK |
| `true` | off | `"HITL this CL"` | HITL |
| absent | off | none | HITL (default safe) |

---

## Gate Criteria

A CL auto-submits only if **all** pass:

### Gate 1: Path lists

**Whitelist** (every file in the CL must match at least one) — *configure for your project*. Example:
- your project's reviewable text source (e.g. `**/*.<your-script-ext>`)
- your project docs `<docs_root>/**/*.md` (excluding any protected raw-materials dir)

**Blacklist** (any match auto-fails — overrides whitelist) — UE/Perforce defaults:
- `**/*.cpp`, `**/*.h`, `**/*.hpp` — C++ source
- `*.uproject`, `*.uplugin` — project/plugin manifests
- `Engine/**` — engine source
- `**/Binaries/**`, `**/*.dll`, `**/*.modules` — compiled artifacts
- `**/*.uasset`, `**/*.umap` — binary assets, not reviewable via text diff
- your protected raw-materials dir (e.g. `Docs/_Raw/**`)

**Rule:** every file matches the whitelist AND no file matches the blacklist.

### Gate 2: Size cap

- `files ≤ 10` AND `lines ≤ 300`
- **Doc-only exemption:** if every file is `.md` (and not under a protected raw dir), the line cap is
  waived. File cap still applies.

### Gate 3: Reviewer verdict

The reviewer agent must output **both**:
- `Verdict: GREEN` or `Verdict: WARNING` (not `BLOCKING`)
- `AFK-Verdict: SAFE` (not `REQUIRES-HITL`)

WARNINGs are logged but don't block. `AFK-Verdict` is the reviewer's meta-judgment: "given everything
I found, is this OK to auto-submit?"

---

## Growing-CL Behavior

When the agent is mid-work on an AFK issue and the CL grows past the size cap, **complete the work and
let the gate decide at submit time** — don't predict size mid-work, don't abort. At submission, gates
evaluate; over-cap CLs are queued for HITL with a logged reason and the description footer
`AFK-DEMOTED-TO-HITL: size cap exceeded (N files, M lines)`. AFK is *authorization*, not *scope control*.

---

## Workflow

**Picking up an AFK-eligible issue:** confirm `AFK: true` → create CL `[JobFamily][Name][AFK-AUTO] {title}`
with body `Issue: <path>` + `AFK-Source: <source>` → implement (`p4 edit`/`add` as you go) → evaluate gates.

**Gate evaluation + submission:**
1. Compute path/size metrics from `p4 describe <CL>`.
2. If path or size gate fails → queue for HITL, log, stop.
3. Launch the reviewer with AFK context (below).
4. Parse `Verdict:` and `AFK-Verdict:`.
5. If `Verdict: BLOCKING` or `AFK-Verdict: REQUIRES-HITL` → queue for HITL, log, stop.
6. All gates pass: **dry-run phase** → log `[DRY-RUN would-submit]`, do NOT submit; **live phase** →
   append the **Review Record block** to the CL description (same format/mechanics as ReviewAndSubmit.md
   Step 8 — `Reviewer:`/`Verdict:` lines + one-liner findings; this is what the server Submit-Audit greps
   for), then `p4 submit -c <CL>`, log `[SUBMITTED]`.

**Queueing for HITL:** leave the CL open, append `AFK-DEMOTED-TO-HITL: <reason>` to its description,
log the failure. On return the user runs the supervised review-and-submit flow.

---

## Reviewer Invocation

Invoke the reviewer agent with **AFK context** appended to the standard review prompt:

```
---
## AFK Context

This CL is being reviewed for autonomous submission (AFK mode). The user is not present to approve.
Your verdict gates the auto-submit. In addition to your standard `Verdict:` line, you MUST emit:

  AFK-Verdict: SAFE | REQUIRES-HITL

- SAFE: confident this is safe to auto-submit; no subtle risks, no patterns I'm uncertain about.
- REQUIRES-HITL: concerns I cannot fully resolve as an AI reviewer; a human should look first (use
  this even without a literal BLOCKING issue — judgment matters).

When in doubt, choose REQUIRES-HITL. Promotion to AFK is not your call; demotion is your safety valve.

## Lessons File
Before reviewing, load: .claude/agents/<reviewer-name>-afk-lessons.md — anti-patterns from past
reviews where you said SAFE on a CL that was later reverted. Apply them.
```

The reviewer reads its lessons file ([architecture-reviewer-afk-lessons.md](../agents/architecture-reviewer-afk-lessons.md)
or [radical-design-critic-afk-lessons.md](../agents/radical-design-critic-afk-lessons.md)) and applies the patterns.

---

## Audit Log

**Location:** `.claude/logs/afk-submits-YYYY-MM-DD.md` (one file per day, local only, not in Perforce).

Each day's file has a scannable **Index** (e.g. `14:23 — CL 12345 [SUBMITTED] <title> (<source>)`) plus
**detail blocks** with: title, source, files, diff size, reviewer, `Verdict`, `AFK-Verdict`, gate results,
and any non-blocking warnings. **Statuses:** `[SUBMITTED]`, `[HITL-QUEUED]`, `[DRY-RUN would-submit]`,
`[DRY-RUN would-queue]`, `[REVERTED by CL N]`.

---

## Recovery

**Per-CL revert** — user says `"revert AFK CL <N>"` → agent reads `p4 describe <N>`, creates
`[Revert][Name] Revert AFK-AUTO CL <N> - {title}`, restores each file to its prior revision
(`p4 sync -f <file>#<rev>` + `p4 edit`), writes a body explaining the revert, **presents the diff for
approval (never auto-submits a revert)**, and on approval submits + marks `[REVERTED by CL <N>]` on the
original log entry + **appends a lesson** to the reviewer's lessons file.

**Mass revert:** not supported in v1. If batch reverts become common, the gate is broken — fix the gate.

---

## Calibration (Reviewer Feedback Loop)

**Lessons file** (`.claude/agents/<reviewer-name>-afk-lessons.md`, one per reviewer): on each
`"revert AFK CL <N>"` the stated reason is appended as a lesson (with a best-effort `Pattern:`
generalization). The reviewer loads it on every AFK invocation.

**Periodic re-calibration:** after every 100 submitted AFK CLs (counter in
`.claude/state/afk-cl-counter.txt`), the system auto-drops to **dry-run** for the next 10 CLs, then
prompts the user to re-promote with `"AFK live mode on"`. State: `.claude/state/afk-mode.txt`
(`dry-run` | `live`, default `dry-run`).

---

## Rollout (Dry-Run Phase)

On first install, `afk-mode.txt` is absent → defaults to **dry-run** (gates evaluate, log records
`[DRY-RUN ...]`, **no `p4 submit`**). User promotes with `"AFK live mode on"` (expected to audit the
dry-run log first; not enforced). Re-entry to dry-run: automatic every 100 CLs, or manual
`"AFK dry-run mode on"`.

---

## Session-Start Surfacing

[`afk-status.sh`](../scripts/afk-status.sh) runs at session start (SessionStart hook, alongside any
`doc-audit.sh`). It surfaces current mode, CLs submitted/queued in the latest log, and pending reverts.
It stays silent when AFK has never run.

---

## Relationship to other workflows (prose — these live in other overlays)

- **ChangelistVerification / ReviewAndSubmit** (perforce overlay): AFK is the explicit opt-out from
  their per-CL HARD RULE, only for CLs passing all gates. ReviewAndSubmit is the HITL counterpart.
- **architecture-reviewer / radical-design-critic** (myst-project overlay): the reviewer agents whose
  `Verdict:` + `AFK-Verdict:` gate the submit. They are reviewers, not submitters — they never run
  `p4 submit`; this workflow (the parent) parses the verdict and decides.
- **sync-build-submit** (ue overlay): its Step 8 asks before submitting by default; auto-submit-on-green
  there activates only when this overlay is installed AND armed.
- **AgenticWorkflow / Triage**: AFK is set during triage (the issue's `AFK:` field).
- **RawMaterialsProtection**: your protected raw-materials dir is blacklist-locked regardless of any AFK signal.

---

## Open Items (future)

Mass-revert tooling; cross-day audit aggregation; a config file for gate paths / size caps / counter
thresholds (`.claude/state/afk-config.json`) if values start drifting; multi-tool (Codex) support.
