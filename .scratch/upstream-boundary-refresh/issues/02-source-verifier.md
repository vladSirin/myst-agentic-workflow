# Changeset 1: Establish the source verifier

Type: task
Status: claimed
Spec: [approved plan, Changeset 1](../../../docs/plan_upstream_boundary_refresh.md#changeset-1-establish-the-source-verifier)

## Scope and acceptance

Add one repository-only command, source-record schema, and CI checks for source
integrity, entry/source links, and declared dependencies. Preserve the existing
checks. The user verified Changeset 0 and authorized this step on 2026-10-07.

The approved test boundary is the verifier command's acceptance or rejection
of a bundle: altered source, missing companions, valid wrapper edits, and a
source edit accompanied by regenerated local hashes. Independently acquire the
pinned source; local hashes alone cannot establish source equality. Test both
Git and archive providers with disposable fixtures and external transport stubs.
List unmigrated imports as debt; a final release check must reject remaining debt.

Skill migration, installed-copy changes, and publication are outside this step.
The implementation branch is codex/upstream-source-verifier, stacked on locally
verified Changeset 0 until its separately gated integration.

## Verification - 2026-10-07

- `python -m unittest discover -s tests -p test_verify_upstream.py -v`:
  14 tests passed. The Standards reviewer independently repeated that run.
- `python tools/verify_upstream.py`: passed, reporting zero migrated bundles,
  25 pending imports, and four local skills. This is debt accounting, not
  source-equality evidence for existing imports.
- `python tools/verify_upstream.py --require-complete`: failed as expected,
  naming the remaining debt. A complete disposable fixture passed this mode.
- A disposable handoff fixture passed independent acquisition from GitHub at
  the approved Matt commit. The source plugin was not modified or installed.
- Both Git and ZIP fixtures reject edited source with regenerated local hashes.
  ZIP tests are synthetic; the actual full Hammer asset remains unverified.
- All six pre-existing workflow checks passed locally. Markdown links, policy
  coverage, unchanged skill/manifests, staged retired-reference scan, and
  `git diff --cached --check` passed.
- Standards and Spec reviews each returned GREEN with no actionable findings
  at staged tree `33ad20bf522d377b5a4ebc23893796525d7bb7ec`.
- Docs alignment identified one cache wording mismatch. The guide now says
  each repository/revision pair is fetched once per invocation.
- Claude CLI is unavailable and hosted CI has not run. No push, PR, merge, tag,
  release, or installed-skill update occurred.

Prepared locally; awaiting user verification before Changeset 2's handoff pilot.
