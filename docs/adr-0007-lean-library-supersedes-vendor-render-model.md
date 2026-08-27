# ADR 0007 — Lean library supersedes the vendor/render model

**Status**: Accepted (v5.0.0, 2026-08-27)

**Context owners**: package maintainer (sxc)

**Direction inputs**: roundtable 2026-08-26 (scaffold → skills library), a grilling
session, and six review passes over the execution plan. The roundtable's
depot-vendoring conclusion was consciously overridden by the owner: the plugin
marketplace stays the one distribution channel.

## Context

By v4.50.x the package had become heavy scaffolding staffed by one maintainer:
44 maintenance scripts, per-tool install pipelines, a generated-block render
system for co-owned files, version lockstep across five sites, parity auditors,
drift detection, and a promotion round-trip. Each mechanism was individually
defensible — most were built in response to a measured failure — but the sum was
a machinery tax that outweighed the content it delivered: a folder of skills.

v5.0.0 restructures the repo to the shape of its upstream inspiration
([mattpocock/skills](https://github.com/mattpocock/skills)): a skills folder, a
thin marketplace, reference docs, ~zero machinery.

## Decision

1. **The repo ships only project-agnostic skills.** Skills AND commands: anything
   project-specific lives in the consuming project's own committed docs and rules
   (for the origin project, its Perforce depot). Stack-specific-but-reusable
   content (Perforce command forms, UE debugging) counts as agnostic.
2. **The marketplace is the ONE distribution channel** — Claude Code and Codex
   install the plugin natively; everyone else uses `npx skills add` at personal
   scope. No depot vendoring, no per-tool render pipelines, no installer.
3. **Protocols generalize instead of duplicating.** The publication protocol
   (`review-and-submit`) and multi-changeset rule are VCS-agnostic with dual
   Perforce/git command forms; the review engine is the vendored upstream
   `code-review` skill (verbatim + provenance note, cited namespaced).
4. **Machinery dies wholesale**: the 44 scripts, the render/marker system, the
   manifest + hash tracking, the parity suites, the generated reviewer agents,
   the plugin's hooks and commands. A 6-line stub and `retire-legacy.ps1` bridge
   the transition and are removed together in a later MINOR.
5. **Versioning shrinks to two sites** (the two `plugin.json` manifests),
   updated by `bump.ps1`; the marketplace entry carries no version (duplicating
   it there is documented as hazardous and pins consumers to stale snapshots).

## What this supersedes (by ADR)

- **ADR-0001** (extract reusable core): the overlay/manifest install model it
  ratified is retired. Historical record only.
- **ADR-0002** (vendor-and-overlay, not fork): the *vendor-not-fork* half
  stands; the *overlay + manifest + drift-detection* half is retired along with
  the machinery it governed.
- **ADR-0003** (verbatim SKILL.md format): **stands unchanged** — vendored
  skills stay byte-faithful to upstream's format.
- **ADR-0004** (local-origin provenance, `core-local` overlay): the placement
  principle (local-origin never lives where a re-vendor writes) survives in
  spirit via LICENSE's pinned-commit attribution for the pre-v5 vendored set
  and per-skill `PROVENANCE.md` notes for skills vendored v5.0.0 onward; the
  overlay mechanism and the manifest flag are retired.
- **ADR-0005** (OpenCode pointer consumer, agents by generation): retired.
  OpenCode now consumes skills like any npx consumer at personal scope, and
  there are no agents to generate — the reviewer agents are deleted in favor of
  the vendored `code-review` engine's generic sub-agent briefs.
- **ADR-0006** (verbatim by default + divergence ledger): the *verbatim by
  default* rule stands; the *divergence ledger and its hash tooling* are
  retired with the tracking machinery.

## What v5 gives up (recorded, owner-accepted)

- **Upstream drift tracking**: `check-mattpocock-updates.ps1` and the
  vendored-hash ledger die; re-vendoring is a manual wholesale replace + diff.
  Nothing will nag when upstream moves.
- **Generated reviewer agents**: the two custom reviewer agent definitions are
  deleted. Their genuinely-additive canon is archived in git history; a same-dir
  reference brief is added later ONLY if review quality visibly drops. Deleted
  with them is their pinned review model/effort — pinned (commit `78f8675`)
  after a ground-truth harness measured an effort-inheriting reviewer falling
  from 6/6 defects found to 0/2. Generic sub-agents inherit the session's
  model/effort again; only the wrapper's prose "effort barbell" instruction
  pushes back, so a low-effort session can weaken a review silently. Accepted
  under the same reactive gate as the canon.
- **The render system and co-owned-file markers**: consuming projects hand-own
  their bible files; the reference templates here are frozen snapshots.
- **Client-side audit surfaces**: the plugin ships zero hooks; post-submit
  server audits (where a team runs them) are the remaining net.
- **Per-user install state and version skew** across npx consumers: inherent to
  the copy-install model; mitigated by release comms and a staleness nudge in
  the origin project's tooling.

## Consequences

- Adding a skill = one directory, zero prose edits, zero manifest edits.
- CI shrinks to three gates: PowerShell 5.1 parse, ASCII/BOM, and a lint job
  (frontmatter validity, two-manifest version agreement, README one-liners
  present, dead-reference grep).
- Retiring a skill is MINOR for plugin consumers (the plugin directory is
  replaced wholesale on update); npx consumers self-manage removal.
- The origin project's depot absorbs the team-specific layer in four
  changelists (CL-0 → CL-PRE → CL-SRC → CL-GATE), executed after the git
  release so migration pointers resolve; `docs/migration-v5.md` is the
  per-file inventory.
