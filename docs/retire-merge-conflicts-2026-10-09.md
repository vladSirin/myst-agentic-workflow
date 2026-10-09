# Merge-conflict skill retirement - 2026-10-09

Status: obsolete package/catalog row and pending waiver removed. Disposable
upgrade/rollback checks pass. Both independent reviews GREEN; owner verification pending.
Review base: f0334fe. This changeset retires one skill; it does not release the kit.

## Change and boundary

The approved plan removes resolving-merge-conflicts because the selected Matt
catalog no longer includes it. Its sole SKILL.md is deleted; no legacy skill
copy remains in the package. The active README row and pendingImports waiver
are removed together. Historical plans/reports retain their dated evidence.

All 188 retained plugin files match f0334fe byte for byte. The candidate has
31 skills: twenty-six source imports and five local skills. README has exactly
31 distinct valid catalog links. No resolving-merge-conflicts mention remains
in active skills, README, SETUP, starter references or verifier policy.

The [cleanup guide](upstream-refresh-install-cleanup.md) covers exact snapshots,
scope, origin checks, backup verification, manual cleanup, reinstall and fresh
catalog checks. It checks retained skills before add can overwrite personal
edits. Uncertain ownership or a same-name foreign copy stops the dependent
replacement. Nothing extends retire-legacy.ps1 or adds a new installer.
README/SETUP now use explicit --global for their personal-scope copy command;
omitting it selects project scope. README states the checkout's restored source
boundary while keeping combined release/consumer acceptance pending.

## Disposable installation checks

The rollback snapshot is v5.4.0 commit
b3aeed04e0ea553af7b39f6d793e91f2ff676ff1 (29 skills), extracted by git archive.
The candidate is a complete copy of this working plugin (31 skills), with all
paths/hashes recorded. Both manifests remain 5.4.0 under the migration exception.

Tests used skills CLI 1.7.1, Node v22.19.0, --skill '*', explicit Codex,
Claude Code and OpenCode agents, --copy, -y, and project scope. Nine actual add
calls wrote only disposable fixtures' .agents/skills and .claude/skills trees.
Claude here is a physical copy target; no Claude model session was run.

The fresh retry passed 70 assertions:

- Clean baseline: full 29-skill copies match the archived snapshot.
- Add-only upgrade leaves resolving-merge-conflicts. Origin/hash-checked manual
  cleanup plus reinstall yields exactly 31 candidate skills in both trees.
- Add-only rollback leaves pr, implement-spec and p4-description. Checking their
  candidate origin, removing only those copies and reinstalling yields exactly
  29 baseline skills. The old resolving-merge-conflicts entry is restored.
- Edited upgrade preserves complete copies of retired and retained teach skills
  before cleanup/reinstall. Edited rollback does the same for all three new-only
  skills and teach. All twelve backups match the original relative files/hashes
  and sit outside discovery roots. Installed retained files match the chosen
  snapshot, with no stale companions.
- Unrelated personal-sentinel skills remain byte-identical in both trees.
- Unknown resolving-merge-conflicts origin and foreign pr name collisions are
  reported at four paths. No cleanup/add runs on that conflicted state; its
  whole file inventory remains unchanged. This is a blocked install, not a
  ready selected catalog.
- Fresh Codex app-server skills/list and OpenCode debug skill processes match
  the fixture-scoped selected catalog once per skill after clean and edited
  upgrade and rollback (eight host checks). Backups are absent. Extra personal
  sentinel entries stay present in edited fixtures.
- Complete plugin-directory replacement is simulated baseline -> candidate ->
  baseline with exact full-tree equality. It does not call a native updater.

The first harness attempt failed on a KeyError while reading mixed installation
and backup receipts. Its clean stale-name demonstration also backed up already
replaced retained folders as mismatches to the old base; those backups are not
personal-edit evidence. The corrected harness uses a safe receipt lookup and
removes only the byte-verified stale name in that demonstration. It ran again
in a fresh retry1 directory. The failed script/state and explanation are kept.
No skill source or model result was changed to get a pass.

CLI path evidence includes its getCanonicalSkillsDir, getAgentBaseDir and
isUniversalAgent code, not just the per-host configuration table. Both Codex
and OpenCode use the canonical .agents/skills destination in CLI 1.7.1.
Personal-scope paths were inspected in that source; global installs were not run.

## Package and source checks

All six production CI gate scripts passed under their specified PS 5.1/pwsh
engines. Both offline Claude plugin/marketplace manifest validators passed.
All 26 source-verifier acceptance tests passed. Independent
`python tools/verify_upstream.py --require-complete` passed: 26 imported bundles
against pinned source, zero declared pending imports and five local skills.
Catalog/scope checks and git diff --check passed.

Evidence lives in `%TEMP%/myst-retirement-migration-20261009`:
fixtures-initial.py, initial-failure.txt, fixtures-retry.py, remove-fixture.ps1,
package.py and its ten logs, retirement-scope-checks.json, plus retry1 snapshots,
actual CLI logs, fixture-checks.json, all eight discovery outputs, backup trees
and unresolved-collisions.json. The fixture cleanup script checks resolved
targets stay inside that disposable root and rejects links before native
PowerShell recursive removal. It is not shipped.

Retry snapshot receipt SHA-256:
59a217daf829b19a5c8d316cbf865f962f2a0e5ad986757dcbc05b11977a056f.
Retry check/install/backup receipt SHA-256:
2b140df45ca57b2348da3eab6ecd6100f011025f5618d9a1015ebe124f5e898b.

## Limits and next gate

These are project-scope copy and catalog checks. Existing global/plugin entries
in the normal host were excluded by fixture path; the test does not prove a
clean whole-machine menu. Actual native plugin updates, global copy installs,
symlink cleanup, native slash UI and Claude runtime remain untested here.
No real installed plugin, consumer, P4 workspace or personal skill was changed.
No tag, version bump, push, PR or shared merge occurred.

No runtime comparison of the deleted skill is useful for this retirement. The
alignment criterion is exact selected-snapshot files/catalog and preservation
of personal/unrelated state. Owner verification remains the next gate after
both independent reviews. Combined release documentation, full acceptance and
required consumer compatibility remain separate work.

## Standards review

Independent verdict: GREEN.
BLOCKING: 0; WARNING: 0; INFO: 0. Worst Standards issue: none.

The reviewer read all eight pinned files, including the complete deleted base
file and all three additions. Branch codex/retire-merge-conflicts, HEAD/base
f0334fec65e4cca7dae048553e32d7ca13460e16, actions, content hashes and diff SHA
matched before and after. Commit/staged lists stayed empty. The input is current.

No documented-standard breach was found. Deletion, README row removal and waiver
removal follow CONTRIBUTING's catalog/migration rules. All 188 retained plugin
files match base bytes. The cleanup guide follows CONTRIBUTING and ADR-0008:
origin checks, personal-edit preservation, upgrade/rollback and unrelated-copy
protection. No installer or release change appears. README distinguishes source
restoration from pending consumer acceptance.

The reviewer independently checked the saved evidence without rerunning tests:
all 70 assertions pass; snapshot inventories match actual baseline, candidate and
current package; all 12 backups match their complete recorded inventories/hashes;
nine add logs exist; all eight host receipts contain the expected fixture catalog
once per skill, without backups. Package logs and the retained failure support
the report. All 12 smell heuristics were considered; none warrants a finding.
The documented thin-wrapper boundary stays unchanged.

Global installs, native updater, slash UI, symlink cleanup, Claude runtime and
whole-machine acceptance remain unverified as stated. Owner verification and
publication remain separate gates.

## Spec review

Independent verdict: GREEN.
BLOCKING: 0; WARNING: 0; INFO: 0. Worst Spec issue: none.

No missing/partial requirement, extra scope or incorrect implementation found.
Issue 38 lines 9-11 are met: obsolete skill, active row and pending waiver are
removed together; all 188 retained plugin files independently match f0334fe;
no legacy package copy remains.

Lines 13-17 are met: canonical .agents/skills and older host paths, exact source
snapshots, ownership checks, verified backups before replacement and collisions
that block installation. For lines 18-20, the reviewer inspected the harness,
actual CLI logs, snapshots, all eight discovery outputs, installed file maps and
twelve backups. Captured upgrade/rollback catalogs match selected snapshots.
Final rollback trees match baseline; unknown/foreign folders remain intact.
Native replacement is disclosed as a directory simulation.

All ten package logs pass, including zero-debt complete source verification.
The first harness failure and its limits stay disclosed. The pin matched before
and after: base/HEAD f0334fec65e4cca7dae048553e32d7ca13460e16, branch, eight
actions, all current/base hashes and diff SHA
69ca9deaf5744e4db6db2356f170fac5e8493d19955053582b370157ada9e9c8.
Commit range and staging stayed empty.

The verdict covers retirement and disposable copy migration. Global installs,
native updater, symlink cleanup and Claude runtime stay outside this proof.
Owner verification remains pending under issue line 25.
