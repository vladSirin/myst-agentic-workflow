# ADR-0004: Local-origin provenance and the `core-local` overlay

- **Status:** Accepted (2026-06-23)
- **Context builds on:** [ADR-0002](adr-0002-vendor-and-overlay-not-fork.md) (vendor-and-overlay),
  [ADR-0003](adr-0003-verbatim-skill-format.md) (verbatim skill format)

## Problem

The package mixes two kinds of content:

- **Upstream-derived** — vendored faithfully from `mattpocock/skills` (e.g. `tdd`, `triage`,
  `diagnosing-bugs`). A re-vendor from upstream rewrites these.
- **Local-origin** — invented in this package, not from upstream (e.g. `roundtable`, the
  `update`/`promote-myst-skills` commands, the `ue` build pipeline, the AFK governance).

A re-vendor from upstream only ever writes under `templates/{tool}/.{tool}/skills/<upstream-name>/`
(and a "stay faithful" cleanup may *delete* skills there that upstream doesn't have). So **any
local-origin skill living under `templates/.../skills/` can be silently clobbered or removed by a
future sync.** The `upstreamDerived` manifest flag existed but was documentary only — no tool read
it, and 30 entries had inconsistent license metadata.

## Decision

**Provenance is recorded by a flag, enforced by physical placement, and checked by a test.**

1. **Flag (record).** Every manifest entry carries `upstreamDerived` (bool) + `upstreamLicense`.
   Upstream entries are `upstreamDerived: true` + `upstreamLicense: "MIT"`. Local-origin entries are
   `upstreamDerived: false`, license `null`.

2. **Physical placement (enforce — the durable guard).**
   - **Local-origin SKILLS** live in the **`core-local` overlay** (`overlays/core-local/`), never
     under `templates/.../skills/`. `core-local` is **force-added at install** (like `tool-capability`)
     by both `init-consumer.ps1` and `install.ps1`, so it ships to every consumer — but because it
     lives under `overlays/`, a re-vendor (which targets `templates/`) **structurally cannot touch it.**
     `roundtable` is the first member.
   - **Local-origin NON-skill content** (commands, workflows, agents, scripts) may remain under
     `templates/` — the upstream *skill* sync does not target those directories.
   - **Overlay-specific local features** live in their overlay: the UE build pipeline + EngineAssociation
     guard in `overlays/ue/`; the AFK autonomy governance in `overlays/afk-autonomy/` (ADR/forthcoming).

3. **Test (check).** `scripts/run-provenance-tests.ps1` asserts: every `upstreamDerived: true` entry
   has a license; **no `upstreamDerived: false` skill is sourced from `templates/.../skills/`**;
   `core-local` entries are well-formed and the overlay is declared. This fails CI the moment a local
   skill is added to the wrong place.

4. **Curation memory (double-check).** `.scratch/agentic-scaffold-rejected-upstream.json` carries
   name-keyed `type: "local-origin"` entries so a future upstream name-collision (e.g. upstream adds a
   `roundtable`) is flagged for explicit reconciliation rather than blind adoption.

## Consequences

- A re-vendor from upstream cannot drift onto local-origin content: local skills aren't in the sync's
  target tree, the flag is consistent, and the test guards the boundary.
- `core-local` always installs (force-added), so moving a local skill there is invisible to consumers
  (same installed path), but its source is now sync-safe.
- New local-origin work has a clear home: skills → `core-local`; UE/P4 features → `ue`/`perforce`;
  project-specific → `myst-project`; autonomy → `afk-autonomy`.
