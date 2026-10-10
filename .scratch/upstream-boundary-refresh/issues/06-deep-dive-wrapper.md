# Changeset 5: Restore deep-dive with local invocation metadata

Type: task
Status: closed
Spec: [approved plan, Hammer](../../../docs/plan_upstream_boundary_refresh.md#hammer)

## Scope

Preserve the complete deep-dive source from the approved Hammer v0.30.0 asset,
including Chinese frontmatter and credits. Keep the existing English discovery
text, argument hint, and user-only invocation in the public Myst entry. Inspect
the adjacent bundled README and retain the existing redistribution authorization.
Do not change roundtable or add new Hammer skills.

## Acceptance

- Verify the full release archive and selected source bytes independently.
- Separate source comparison from local wrapper and metadata changes.
- Show local discovery and an explicit wrapper-to-source runtime load.
- Confirm the first step strengthens both sides, asks one decisive question,
  and stops before a verdict; preserve the second step's response to the answer.
- Run repository checks and independent Standards/Spec reviews.

The owner verified Changeset 4 on 2026-10-07 and authorized this next skill.
The approved task moved from ready-for-agent to claimed on branch
codex/deep-dive-source-wrapper. Claude runtime tests remain deferred until owner
notification. No publication is authorized.

## Verification

[Migration evidence](../../../docs/deep-dive-wrapper-2026-10-07.md) records exact
old/new source equality, complete-archive verification, adjacent README
inspection, local discovery, first-step comparison, and a second-step check.
Repository checks passed. Independent review is recorded in that report.

Owner verification: "Good continue" on 2026-10-07, after local commit 58509c2.
This permits the next changeset; it does not authorize publication.
