# Changeset 0: Ratify the boundary and migration contract

Type: task
Status: closed
Spec: [approved plan, Changeset 0](../../../docs/plan_upstream_boundary_refresh.md#changeset-0-ratify-the-boundary-and-migration-contract)

## Scope

Record strict source ownership, the provisional layout and its pilot gate,
the narrow verifier scope, glossary compatibility, and the approved migration
branch. Correct contribution rules and current README claims. Inventory each
import and every deliberate exclusion. Enable existing CI on the migration
branch. Preserve current skill contents and release versions.

## Acceptance

- The new ADR states which earlier decisions it supersedes; history is preserved.
- Contribution rules apply local metadata and publication requirements to wrappers.
- Each current import has a migration destination and pending status.
- README separates current state from the approved target.
- Existing CI is enabled for the migration branch; local applicable checks pass.
- User verifies this changeset before source-verifier implementation begins.

## Comments

2026-10-07: Created as ready-for-agent from the approved plan and claimed for
implementation. Branch: codex/upstream-boundary-contract. Target branch:
codex/upstream-boundary-refresh. No remote issue or PR has been published.

## Verification - 2026-10-07

- Executed all six embedded checks from the existing CI workflow locally:
  PowerShell 5.1 parse, ASCII/no-BOM, skill frontmatter, manifest agreement,
  README install commands, and retired-reference scan. All passed.
- Checked local Markdown links and the finalized plan name. Every current
  import has an inventory row; each listed Matt source subtree exists at the
  pinned target. No skill or manifest changes appear in the diff.
- Re-ran the retired-reference scan against the staged files and ran
  `git diff --cached --check`; both passed.
- Independent Standards and Spec reviewers each returned GREEN with no
  actionable findings on tree `8a1d4bf444ea0d3f45269644325d1d09c951b97c`.
- The separate docs-alignment check found one stale README-debt statement in
  the plan. It was corrected to distinguish Changeset 0 from pending migration.
- Claude CLI is unavailable; its plugin validation did not run. Hosted CI has
  not run because this changeset has not been pushed.

The user verified Changeset 0 on 2026-10-07 and authorized Changeset 1. No source verifier, skill update,
installed-copy cleanup, or consumer migration was performed.
