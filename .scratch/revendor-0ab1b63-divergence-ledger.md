# Divergence ledger — re-vendor `e9fcdf9` → `0ab1b63` (v4.43.0)

Required by [ADR-0006](../docs/adr-0006-verbatim-by-default-and-the-divergence-ledger.md): every
divergence from upstream carries a written necessity rationale, a reviewer pass, and owner
confirmation. This is that record for the release.

- **Upstream**: `mattpocock/skills` @ `0ab1b63a410a03d3627979a109c8695de27af954` (2026-08-20)
- **Previous pin**: `e9fcdf95b402d360f90f1db8d776d5dd450f9234` (2026-07-14) — 141 commits behind
- **Scope**: 40 vendored files, 8 skills adopted, 31 skills total after the release
- **Mechanical proof**: `scripts/vendored-hashes.ps1 -Verify` — every vendored file matches its
  recorded EOL/BOM-invariant hash; the generator refuses undeclared divergences.

---

## 1. Content divergences — 7 lines across 6 skills

Every one is the same kind: upstream text referencing a skill we do not vendor. Everything else in
these files is byte-verbatim.

| File | Line | Upstream | Ours | Necessity |
|---|---|---|---|---|
| `tdd/SKILL.md` | 38 | `` `code-review` `` | `` `review-changes` `` | We do not vendor `code-review`; a dangling name misroutes. |
| `implement/SKILL.md` | 13 | `/code-review` | `/review-changes` | **Sharpest case.** Unremapped, `/code-review` *resolves* on any machine with the official review plugin enabled — a git-diff reviewer pointed at a Perforce changelist, returning a plausible answer from the wrong tool with no error. A silently-resolving wrong reference is worse than a dangling one. |
| `to-spec/SKILL.md` | 9 | `/setup-matt-pocock-skills` | `/setup-agentic-workflow` | Rejected skill; ours covers the role. |
| `to-tickets/SKILL.md` | 11, 60 | `/setup-matt-pocock-skills` | `/setup-agentic-workflow` | as above |
| `triage/SKILL.md` | 43 | `/setup-matt-pocock-skills` | `/setup-agentic-workflow` | as above |
| `wayfinder/SKILL.md` | 25 | `/setup-matt-pocock-skills` | `/setup-agentic-workflow` | as above |

**Enumerated by grep, not by hand.** Three review passes over the migration plan each produced an
incomplete list by reading — the last one missed `to-spec:9`, `triage:43`, `to-tickets:60` and the
`implement:13` case above. The guard now lives in the release checklist:

```sh
git grep -nE "setup-matt-pocock-skills|code-review|ask-matt" plugins/myst-dev-kit/skills/
```

Run against the working tree at the time of writing: **0 unledgered hits**.

## 2. Rejections (re-confirmed against `0ab1b63`)

| Skill | Necessity |
|---|---|
| `ask-matt` | Hand-authored, branded (aihero.dev) router over *upstream's* catalog: it names skills we reject and is blind to our 9 local-origin skills, so verbatim it misroutes our team. Concept useful → local-origin `ask-myst` queued as a follow-up. |
| `setup-matt-pocock-skills` | `setup-agentic-workflow` covers the role. |
| `code-review` | Git-native throughout (`git diff <fixed-point>...HEAD`, `git rev-parse`); our review unit is the P4 changelist, and the name collides with the built-in `/code-review`. Its one structural idea (Standards+Spec dual axis) was mined into our review paths at v4.4.0. Its 9 commits since the previous pin are all phrasing, no architecture. |
| `agents/openai.yaml` (all skills) | Upstream's own packaging channel. Our Codex delivery reads `.codex-plugin/plugin.json`, which registers skills by **directory pointer**. Verified: zero readers of `openai.yaml` / `allow_implicit_invocation` anywhere in this repo — vendoring them would not shorten Codex deploy by one step. |

## 3. Adoptions (8) — two reverse earlier decisions

| Skill | Note |
|---|---|
| `wayfinder` | **Supersedes** the 2026-07-16 defer (which waited on a Jira/OpenProject tracker). User-directed. Required a tracker-doc section we lacked — see §5. |
| `prototype` | **Reverses** the 2026-06-22 skip ("web-bound; no UE/Perforce relevance"). `wayfinder/SKILL.md:78` resolves a prototype-type ticket by calling it, so keeping the skip would ship a broken adopted skill. Its LOGIC branch (self-contained state-machine demo) is the usable half here. |
| `wizard`, `to-questionnaire` | Deferred 2026-07-16 only for being `in-progress/` upstream; both have since graduated to the stable roster, so the defer basis is spent. |
| `grill-me` | Upstream ships `grill-me` (user-invoked) + `grilling` (model-invoked) as a deliberate pair and we already vendor `grilling`. Body is one line; cost ≈ nil, and upstream's future changes arrive free instead of us maintaining the asymmetry. |
| `teach`, `wait-what` | In the user-facing roster, no prior recorded decision, self-contained. Default-adopt under the verbatim principle. |
| `writing-for-agents` | Rename re-sync: upstream renamed `writing-great-skills` and we never followed. Our local delta on the old file is **dropped** rather than carried. |

**Invocation-gate consequence, accepted deliberately.** Three arrive **ungated** because upstream
ships them that way: `writing-for-agents`, `wizard`, `prototype`. `writing-for-agents` will
auto-fire whenever anyone edits `CLAUDE.md` or `AGENTS.md` — routine work in our consumer
projects. Taken verbatim and recorded rather than quietly gated; reversible later as a normal
ledgered divergence. The other five are gated and join `setup-devkit.ps1 $ManualSkills` (9 → 13).

## 4. Vocabulary divergences

**`claimed` — divergence by extension.** Upstream uses `claimed` only as *wayfinder concurrency*
vocabulary (`issue-tracker-local.md`, "Wayfinding operations"), not as a general lifecycle state.
We extend it to the implementation lane, replacing `work-in-progress`. Necessity: it keeps one
vocabulary across both kinds of effort instead of two words for the same idea. Disambiguation is
by **effort**, not ticket — a wayfinder effort has `map.md`, an implementation effort has
`spec.md`.

**`resolved` + `closed` — recorded as NOT a divergence.** Worth stating so it stops being
re-litigated: upstream's `triage-labels.md` is explicitly a per-repo mapping table ("Edit the
right-hand column to match whatever vocabulary you actually use") and its five names are triage
*roles*, not a repo's whole `Status` vocabulary. Upstream's own file-tracker spec **uses**
`resolved` — `/wayfinder` writes it. Dropping it would have been a divergence *from* upstream, and
would have stranded **48** live tickets (count derived from the tree, not typed), most of which
carry no `Outstanding:` line to fall back on.

**The alternative that was not taken** (recorded so the next sync does not re-derive it):
instead of converging *our* meaning to upstream's, we could have remapped **upstream's**
`triage/SKILL.md:36` to our old meaning as a 7th ≤1-line ref-style divergence. That was strictly
cheaper — one line, versus 4 local-origin skills + 2 template docs + a consumer reconciliation.
Rejected on two grounds: upstream's meaning is the better one (it separates *who implements* from
*what remains to verify*, which our old conflated label could not), and remapping **semantics**
rather than **names** is a far worse precedent — a future reader diffing against upstream would
see identical-looking prose that means the opposite thing. Ref remaps are safe because they are
visibly local; semantic remaps are not.

**When an effort has both `map.md` and `spec.md`** the discriminator in §5 is ambiguous. Not
observed today. If it happens, the wayfinder map governs the tickets that carry a `Type:` line
(wayfinder writes one; implementation tickets do not) — but the honest answer is that this is an
unresolved edge, recorded rather than papered over.

## 5. Additions to vendored-adjacent content

**"Wayfinding operations" ported into `templates/common/docs/agents/issue-tracker.md`.**
`wayfinder/SKILL.md:25` instructs the agent to consult that section by name; our tracker doc had
no such section, and the "no tracker provided" fallback does not fire because a tracker *is*
provided. Without the port the adopted skill is stranded between two branches. Ported from
upstream's `issue-tracker-local.md` with one addition: the effort-level discriminator in §4.

## 6. Project-side relocations (land in a different repo — Phase B, `UE_Blank_Proto`)

Included here deliberately: these previously escaped review entirely by living outside the package
PR. **Status: not yet landed** — the kit-side removal is in this branch; the consumer-side arrival
is Phase B, and neither target file exists yet (see §8 item 4).

| Removed from kit | Will land as | Content |
|---|---|---|
| `resolving-merge-conflicts/P4-NOTES.md` | `Docs/agents/perforce-notes.md` (new file) | P4 resolve verbs, binary-asset caveat |
| `diagnosing-bugs/UE-NOTES.md` | `Docs/agents/unreal-notes.md` (new file) | UE feedback loops, `-ExecCmds`, P4 bisect, binary assets |
| `improve-codebase-architecture` P4 hot-spot aside | same, `perforce-notes.md` | `p4 changes -m 200` instead of git-log inference |
| `improve-codebase-architecture` effort-barbell aside | **dropped**; proposed upstream instead | Stack-agnostic advice that belongs upstream, not in our fork of it |

**New files only** — never appended into the five installer-owned files in `Docs/agents/`
(`domain.md`, `issue-tracker.md`, `triage-labels.md`, `grill-with-docs-context-format.md`,
`scaffold-manifest.json`), which a scaffold render would overwrite.

## 7. Local-origin edits (verbatim principle does not bind these)

`pre-implementation-gate`, `review-and-submit`, `changelist-verification`, `agentic-workflow`
converged to the new semantics. Necessity: adopting upstream's `triage` verbatim while these still
spoke the old meaning would put two contradictory definitions of `ready-for-human` in one context
window — and the dangerous direction is inversion (an agent reads the kit, concludes it may
implement, and takes a ticket the project reserved for a human).

## 8. Phase B reconciliation — REQUIRED before the vocabulary flip is live

Both reviewer passes landed BLOCKING on the same gap, from different directions, and they were
right: §1–7 declared the *decision* to redefine `ready-for-human` and none of its *consequences*
outside this repository. The ledger counted live-ticket blast radius when the answer was "keep
upstream's word" (§4, 48 tickets) and did not count it when the answer was "flip the meaning".
That asymmetry is precisely the rationalization ADR-0006 exists to catch.

Numbers below are derived from the consumer tree (`UE_Blank_Proto`, 244 ticket files), not typed.

| # | Item | Why it blocks |
|---|---|---|
| 1 | `.claude/rules/PreImplementationGate.md:12` + `:51-58`, `CLAUDE.md:57-58`, `AGENTS.md:63`, `AutoPlanMode.md:28` still teach the OLD meaning | These are **always-on** rules, resident in every session, while skills load on demand. The highest-priority context slot currently asserts the exact inversion §7 was written to prevent: an agent reads the rule, concludes it may implement a `ready-for-human` ticket, and never reaches the skill that would stop it. |
| 2 | 28 `ready-for-human` tickets were labeled under the old meaning; **~3 are pure verification-HITL** (work already buildable/built, a human must only check it) and belong at `resolved` + `Outstanding:` | They keep the string as a *safe* default, so nothing escalates. But the board is inaccurate until reclassified — and by the rule written in this very release, `ready-for-human` → `ready-for-agent` is **user-only**, so this sweep is the owner's by construction. Recorded here so that is a stated constraint, not a surprise. |
| 3 | 5 tickets carry `Status: work-in-progress`, a string the kit no longer defines anywhere | Orphaned vocabulary; rename to `claimed`. |
| 4 | §6's relocations have not landed: `Docs/agents/perforce-notes.md` and `unreal-notes.md` do not exist yet | This branch removed `P4-NOTES.md`/`UE-NOTES.md` **and** the pointer to them. Until Phase B lands, a Perforce shop's merge-conflict skill has no P4 guidance at all. |

**Two mechanics corrections** the Phase B recon turned up, which the plan had wrong:

- `Docs/agents/issue-tracker.md` and `Docs/MustRead/MustRead_agentic_workflow.md` are
  `manual-only` / **human-owned** in this consumer's installed manifest — a scaffold render will
  **not** deliver them. Only `triage-labels.md` (`installer-owned`/`copy`) renders. The Wayfinding
  section and the MustRead convergence must be hand-applied consumer-side.
- A **third** definitional site exists that the plan never named:
  `Myst_Proto/Docs/plan_agentic_scaffolding_packaging_WIP.md` re-enumerates the full 8-status
  model in two places.

**Ordering.** Phase A may merge and tag before Phase B lands — the kit only reaches a machine on
`/plugin update`, which the rollout defers until after B. What must **not** happen is a
`/plugin update` on any machine before Phase B is submitted. If Phase A ships and Phase B stalls,
that gap is the release's live risk, and it is the owner's call to accept or to gate on.

## Reviewer sign-off

- **`radical-design-critic`** → **BLOCKING**, resolved. Verified the ledger mechanically (34
  identical / 6 divergent / 0 undeclared; all four spot-checked claims true) and found no
  divergence that should have been taken verbatim instead. Its blocker was the undeclared
  consumer-side blast radius above → §8 added; the considered-and-rejected alternative recorded
  in §4; `47` regenerated to `48`.
- **`architecture-reviewer`** → **BLOCKING**, resolved. Empirically measured five holes, all now
  fixed and regression-tested:
  1. **The gate never ran** — CI discovers `run-*-tests.ps1`; `vendored-hashes.ps1` does not match
     that glob, and the provenance header named a wrapper that did not exist. The release that
     diagnosed "a detector nobody runs" had added a second one. → `scripts/run-vendor-hash-tests.ps1`,
     suite badge 19 → 20.
  2. **Deleting a vendored file passed green** (measured: dropping all of `teach/` scored `[PASS]`
     with a smaller count). The loop walked the disk, never the ledger. → reverse existence check;
     dropping one file now yields exactly one failure.
  3. **Rename-laundering** — `mv teach teach-v2` + edit + `-Update` wrote and exited 0. → refused.
  4. **Ledger not byte-stable across shells.** → LF/no-BOM writer, and `-Update` pinned to pwsh 7
     because 5.1's `ConvertTo-Json` formats differently (`-Verify` stays 5.1-compatible for CI).
     Verified byte-idempotent across three runs; a 5.1 `-Update` aborts without touching the file.
  5. Bookkeeping: `attributionRequirement` still cited the superseded pin; README/CHANGELOG
     asserted a completed relocation that had not happened; `overlays/README.md` claimed P4-NOTES
     still rides the skill; the guard's documented pass condition was unreachable as worded.
  Also fixed from its INFO set: deterministic key order, one shared `$localOrigin` roster
  (`scripts/lib/SkillRoster.ps1`), quoted `cmd` interpolation, and a zero-guard on the derived
  count test so it cannot pass vacuously at `0 == 0`.
- **Owner confirmation** → **GRANTED**. PR #87 merged to `main` 2026-08-21 (merge `c30201c`),
  release tagged `v4.43.0`. The ADR-0006 gate is discharged for this sync.
