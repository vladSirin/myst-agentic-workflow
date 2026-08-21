# ADR 0006 — Verbatim by default: every divergence from upstream is earned, reviewed, and confirmed

**Status**: Accepted

**Date**: 2026-08-21

**Context owners**: package maintainers

## Context

ADR-0002 chose vendor-and-curate over forking, and ADR-0003 fixed the vendored format as
near-verbatim so re-vendoring stays mechanical. Both are about *how* we copy. Neither says how
much we may change once copied, or who decides — and that gap is what produced the state this
ADR was written in.

The v4.43.0 re-vendor found the pin **141 commits behind** upstream (`e9fcdf9`, 2026-07-14 →
`0ab1b63`, 2026-08-20). The drift itself was cheap to fix. What was expensive was the accumulated
set of small local adaptations nobody had written down as decisions: a P4 parenthetical here, an
effort-barbell aside there, a dropped companion pointer, an old skill name we never followed
upstream in renaming. Individually each was defensible. Collectively they meant every sync had to
re-derive, by reading, which differences were *intentional* and which were *rot* — and three
successive review passes over the migration plan each mis-enumerated the divergence set by hand.

The failure is not that we diverge. Divergence is sometimes right. The failure is **undocumented**
divergence, which converts a five-minute sync into an archaeology exercise, and does so again on
every future sync.

## Decision

**Vendored content is verbatim by default. Nothing changes from upstream unless it is really
necessary.**

Every divergence — a reject, a remap, an adaptation, a relocation, a dropped file, an added line —
must carry all three of:

1. **A written necessity rationale.** Not "we prefer ours" but what breaks if we take upstream's.
   "Preference" is not necessity; if the honest answer is preference, take upstream's.
2. **A reviewer pass.** The divergence ledger for the release goes to `radical-design-critic`
   (is the reasoning sound?) and `architecture-reviewer` (does the diff match the claim?).
3. **Owner confirmation.** The maintainer signs off on the ledger before the release merges.

A divergence missing any of the three is not a divergence — it is a bug, and gets reverted to
verbatim.

### What counts as a divergence

Anything that makes a vendored file differ from the pinned upstream blob, **plus** the decisions
that surround vendoring: skills rejected from upstream's user-facing roster, skills adopted, and
project-side relocations of content removed from a vendored file. Relocations are included
deliberately: they land in a *different repository* (the consumer project), which is exactly the
class that previously escaped review entirely.

### The ref-remap convention

The commonest necessary divergence, and the only one in v4.43.0: upstream text references a skill
we do not vendor. Remap the name to our equivalent as a recorded ≤1-line divergence; leave the
rest of the file verbatim. Where we have no equivalent, leave the reference verbatim and record it
as knowingly dangling.

Necessity is not cosmetic here. `implement/SKILL.md:13` said "use `/code-review`". Left alone, on
any machine with the official review plugin enabled, that name **resolves** — to a git-diff
reviewer, pointed at a Perforce changelist, returning a plausible answer from the wrong tool with
no error. A silently-resolving wrong reference is worse than a dangling one.

### Enumerate by grep, never by hand

Three review passes over the v4.43.0 plan each produced an incomplete list of dangling references,
by reading. A single `git grep` produced the complete list in one shot. Therefore the release
checklist carries the grep, not a list:

```sh
git grep -nE "setup-matt-pocock-skills|code-review|ask-matt" plugins/myst-dev-kit/skills/
```

Every hit must be a ledgered divergence. Extend the pattern when a new skill is rejected.

### Enforcement, not promise

`vendored-hashes.json` records an EOL/BOM-invariant hash of every vendored file, and
`scripts/vendored-hashes.ps1` runs in two modes:

- `-Verify` — every vendored file still matches its recorded hash.
- `-Update` — regenerate, **refusing** to record any file that differs from the pinned upstream
  unless its path is already declared in the ledger.

The refusal is the point: you cannot silently regenerate a divergence away, and a new one has to
be declared before it can be recorded. `run-provenance-tests.ps1` does not cover this — it walks
manifest entries, and plugin skills are not manifest-tracked. Do not read a green provenance run
as evidence about vendored skill content.

## Consequences

**We will sometimes ship upstream behaviour we would not have chosen.** v4.43.0 does exactly that:
`writing-for-agents`, `wizard` and `prototype` arrive without `disable-model-invocation`, so
`writing-for-agents` auto-fires whenever anyone edits `CLAUDE.md` or `AGENTS.md` — routine work in
our consumer projects. We took it verbatim and ledgered the consequence rather than quietly adding
the gate. Reversing it later is a normal ledgered divergence; the point is that it be a decision
with a name on it.

**Syncs get cheaper the more of them we do.** The pin, the hash file and the ledger together mean
the next re-vendor reads three files instead of re-deriving intent from prose.

**Curation memory stops re-litigating.** `.scratch/agentic-scaffold-rejected-upstream.json` now
also records decisions that are *not* divergences but look like they might be — `resolved` being
the worked example: upstream's `triage-labels.md` is explicitly a per-repo mapping table and
upstream's own file-tracker spec uses `resolved`, so keeping it is faithful, not divergent.
Writing that down once stops the next sync from "fixing" it.

## Related

- [ADR-0002](adr-0002-vendor-and-overlay-not-fork.md) — vendor-and-curate, not fork
- [ADR-0003](adr-0003-verbatim-skill-format.md) — the vendored format is near-verbatim
- [ADR-0004](adr-0004-local-origin-provenance-and-core-local.md) — local-origin content a re-vendor cannot touch
