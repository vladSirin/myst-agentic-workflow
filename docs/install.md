# myst-agentic-workflow — Install / update / promote guide

This is the canonical guide for consuming the `myst-agentic-workflow` package in
your project. The per-script banners show brief usage; this document covers the
workflow they fit into.

The example project throughout this guide is `Acme_Game` with docs at
`Acme_Game/Docs/`. Substitute your own values where appropriate.

---

## 1. Prerequisites

- **PowerShell 5.1+** (Windows PowerShell or PowerShell 7).
- **Python 3.x** is used by some helpers; not strictly required for the install
  path itself.
- A **consuming project** with a `Docs/agents/scaffold-manifest.json` (v3
  schema). First-time consumers who don't have one yet should bootstrap from
  the package's manifest schema — see [§2.1](#21-bootstrapping-an-empty-target).
- For Perforce consumers (UE/P4 projects): see
  [`perforce-consumer.md`](perforce-consumer.md) for the `-UsePerforce` flow.
- The package itself does not need to be on a network drive or in your
  project's depot. It can live anywhere reachable via `-PackageRoot`.

---

## 2. First-time install

### 2.1 The one-command path (recommended)

For most adopters, `setup.ps1` is all you need:

```powershell
$PkgRoot    = 'c:/path/to/myst-agentic-workflow'
$TargetRoot = 'c:/path/to/Acme_Game'

& "$PkgRoot/setup.ps1" -TargetRoot $TargetRoot
```

`setup.ps1` orchestrates three steps with sensible defaults:

1. **Detect** version control (`perforce` if `.p4ignore` or a P4 client root,
   `git` if `.git`, else `filesystem`) and overlay shape (`core`,
   plus `perforce` if VC=perforce, plus `ue` if a `*.uproject` is present
   in the target).
2. **Bootstrap** a `Docs/agents/scaffold-manifest.json` from
   `manifest-template.json` — no hand-editing required. Marker stubs for
   `CLAUDE.md` / `AGENTS.md` / `.p4ignore` are pre-created so the first
   write can populate block content.
3. **Install** — runs the preflight gate, dry-runs first, prompts for
   confirmation (`-Yes` to skip), then writes via `InstallJournal`.

For unattended runs:

```powershell
& "$PkgRoot/setup.ps1" -TargetRoot $TargetRoot -Yes
```

For explicit control over project metadata:

```powershell
& "$PkgRoot/setup.ps1" `
    -TargetRoot     $TargetRoot `
    -ProjectName    'Acme_Game' `
    -GameDocsRoot   'Acme_Game/Docs' `
    -VersionControl perforce `
    -Tools          all `
    -Overlays       'core,perforce,ue' `
    -Yes
```

### 2.2 The step-by-step path (advanced)

If you want explicit control over each step, the three underlying scripts are
exposed directly. Use this path when integrating with CI, scripting a
multi-project rollout, or debugging.

**Bootstrap the manifest:**

```powershell
& "$PkgRoot/scripts/init-consumer.ps1" `
    -TargetRoot     $TargetRoot `
    -PackageRoot    $PkgRoot `
    -ProjectName    'Acme_Game' `
    -GameDocsRoot   'Acme_Game/Docs' `
    -VersionControl perforce `
    -Tools          all `
    -Overlays       'core,perforce,ue'
```

`init-consumer.ps1` is idempotent-by-refusal: it errors out if a manifest
already exists (pass `-Force` to overwrite).

**Dry-run install:**

```powershell
& "$PkgRoot/scripts/install.ps1" `
    -TargetRoot   $TargetRoot `
    -PackageRoot  $PkgRoot `
    -Tools        all `
    -Overlays     'core,perforce,ue' `
    -Mode         DryRun
```

Output ends with a **WRITE PHASE** section listing per-file changes (or "NO
CHANGES" if disk already matches templates).

**Write mode:**

```powershell
& "$PkgRoot/scripts/install.ps1" `
    -TargetRoot   $TargetRoot `
    -PackageRoot  $PkgRoot `
    -Tools        all `
    -Overlays     'core,perforce,ue' `
    -Mode         Write
```

The **preflight gate** (`run-skeleton-preflight.ps1`) runs first. If it fails
write mode is refused. See [§6 Troubleshooting](#6-troubleshooting) for what
each preflight check means.

When preflight passes, the install uses `InstallJournal`:

1. Acquires an exclusive lock at `.scratch/agentic-scaffold-install.lock`.
2. Stages each write to a sibling `<target>.agentic-stage` temp file.
3. Atomically renames every temp into place (`File.Replace` on NTFS) AND
   updates the manifest hashes — single commit point.
4. On any mid-commit failure, restores all targets from `.agentic-bak` files
   and revokes the journal (no half-installed state).

For Perforce consumers add `-UsePerforce -Changelist new` — see the
[Perforce consumer guide](perforce-consumer.md). (`setup.ps1` does this
automatically when VC=perforce.)

---

## 3. Update from upstream

### 3.1 The one-command path

```powershell
& "$PkgRoot/update.ps1" -TargetRoot $TargetRoot
```

`update.ps1` orchestrates four steps:

1. **`git pull`** in `$PkgRoot` (skip with `-NoPull` if you've already pulled
   or are testing against a local change).
2. **`compare-with-package`** — read-only drift report. Aborts the update if
   any `conflict` outcomes appear (both sides moved; needs manual resolution).
3. **Dry-run install** with the tools and overlays read from the consumer's
   own manifest. You see exactly what would change.
4. **Confirm + write** — prompts for `[y/N]` unless you pass `-Yes`. Writes
   via `InstallJournal`; wraps in `-UsePerforce -Changelist new` automatically
   if the consumer's manifest declares `versionControl='perforce'`.

For unattended runs:

```powershell
& "$PkgRoot/update.ps1" -TargetRoot $TargetRoot -Yes
```

When the resulting Perforce CL looks right, `p4 submit -c <CL#>`. When it's a
git/filesystem target, `git diff` and commit normally.

### 3.2 The step-by-step path (advanced)

If you want explicit control or just to inspect drift:

```powershell
cd $PkgRoot
git pull

& "$PkgRoot/scripts/compare-with-package.ps1" `
    -TargetRoot $TargetRoot `
    -PackageRoot $PkgRoot
```

Outcomes per entry:

| Outcome | Meaning | What to do |
|---|---|---|
| `clean` | disk matches package template | nothing |
| `downstream-edit` | you've edited the disk; package unchanged | decide: keep your edit (run `promote.ps1` later) or run `install -Mode Write` to revert to package |
| `upstream-update` | package has changed since your last install; disk hasn't | run `install -Mode Write` (or `update.ps1`) to adopt the upstream change |
| `conflict` | both disk and upstream moved | manual reconciliation needed; see [§6.4](#64-conflict-outcomes) |

`compare-with-package.ps1` exits **0** when there are zero conflicts and
**1** when there are. Useful in CI: any conflict halts the pipeline.

To detect conflicts properly, supply `-PinnedSnapshotRoot` pointing to a copy
of the package as it was at your last sync. Without that, all diffs are
reported as `downstream-edit` (the package can't tell whether the diff is
yours or the upstream's).

---

## 4. Promote a local improvement

### 4.1 The one-command path

If you've improved a file in your project and the change should benefit any
adopter of the package:

```powershell
& "$PkgRoot/promote.ps1" `
    -TargetRoot $TargetRoot `
    -Paths 'Docs/MustRead/MustRead_agentic_workflow.md'
```

`promote.ps1` does the work:

1. **Auto-infers classification** for each path from the consumer's manifest:
   `owner=package,overlay=core` → `reusable-core`; `overlay=perforce` →
   `perforce-overlay`; `overlay=ue` → `ue-overlay`; `overlay=myst-project` →
   `myst-project-overlay`. (`-Classification` overrides explicitly.)
2. **Dry-run** the promotion, showing which package path each file would land
   at and any roundtrip issues.
3. **Confirm + write** — prompts unless `-Yes`. Writes to the package working
   tree with `-Force` (see §4.3 for why).

After it completes, the package working tree at `$PkgRoot` has your change.
Commit + push as usual:

```powershell
cd $PkgRoot
git diff
git checkout -b improve-mustread
git add -A
git commit -m "improve: clarify MustRead step 3"
git push -u origin improve-mustread
gh pr create --fill
```

For paths that aren't already in the consumer's manifest (a brand-new file),
`promote.ps1` errors out and asks you to pass `-Classification` explicitly.

### 4.2 The step-by-step path (advanced)

```powershell
& "$PkgRoot/scripts/promote-from-project.ps1" `
    -TargetRoot $TargetRoot `
    -PackageRoot $PkgRoot `
    -Paths 'Docs/MustRead/MustRead_agentic_workflow.md' `
    -Classification 'reusable-core' `
    -Mode DryRun
```

Drop the `-Mode DryRun` and add `-Mode Write -Force` to actually write.

### 4.3 Why `-Force` is currently required

A real promotion always changes the package source (that's why you're
promoting). The script's "upstream divergence" check can't distinguish that
expected change from an *unexpected* one (someone else edited the upstream
since your last sync) without a pinned-snapshot baseline. Until the package
has published `sourceCommit` values, the conservative behavior is to require
`-Force` for any write. That tells the script "I have inspected the diff and
accept it."

### 4.4 What promotion does

For each file:

1. Looks up the manifest entry to determine ownership bucket:
   - `local-only` / `project-owned` → **refuses** (never promotes).
   - `package-core` → promotes to `templates/{tool}/...` or `templates/common/...`.
   - `overlay` → promotes to `overlays/{overlay}/...`.
2. Extracts the right content:
   - `copy` strategy → whole file.
   - `generated-block` / `append-fragment` → bytes between markers.
3. **Reverse-substitutes** project values back to `{{var}}` placeholders
   (e.g., `Acme_Game/Docs` → `{{game_docs_root}}`).
4. **Roundtrip-verifies**: re-renders the result with the same vars; must
   equal the original. Refuses on mismatch (ambiguity guard).
5. Atomically writes via `InstallJournal` (same crash-safety as install).

### 4.5 PackageRoot in a Perforce depot — known limitation

`promote-from-project.ps1` does **not** currently support `-UsePerforce` for
the package side. If `PackageRoot` is itself in a Perforce client workspace,
the script will write to read-only files and the atomic rename will fail. To
work around: open the destination files for edit manually before running
promote (e.g., `p4 edit -c <CL> overlays/.../*`), then submit the resulting
package CL yourself afterward. This will be addressed in a future iteration
when the package goes live on GitHub (at which point the upstream side
typically isn't Perforce-managed anyway).

### 4.6 Refusing local-only / project-owned

Some files are intentionally never promoted:

- `local-only` files (`localOnly: true`) — per-user state like
  `.claude/settings.local.json`. Never in Perforce, never in the package.
- `project-owned` files (`mergeStrategy: manual-only` or
  `writablePolicy: human-owned`) — files the installer never writes, only
  tracks. Examples: project bibles, AutoPlanMode profiles.

Passing such a path to `promote-from-project` returns `REFUSED` with an
explanation.

---

## 5. Upstream sync — `mattpocock/skills`

The package's substrate references the upstream
[`mattpocock/skills`](https://github.com/mattpocock/skills) repo. The manifest
records:

- `upstreams.mattpocockSkills.pinnedCommit` — the commit our content is
  derived from.
- `upstreams.mattpocockSkills.lastCheckedRemoteHead` — the upstream HEAD when
  we last checked.

Run the upstream check to see if HEAD has moved:

```powershell
& "$PkgRoot/scripts/check-mattpocock-updates.ps1"
```

It reports either "pinned matches HEAD" (no action) or "HEAD has moved" (a
human should review and decide whether to re-pin). The pinned commit is the
authoritative reference for license compliance — see ADR 0001.

---

## 6. Troubleshooting

### 6.1 Preflight not 10/10

Run the preflight directly to see which check fails:

```powershell
& "$PkgRoot/scripts/run-skeleton-preflight.ps1" -TargetRoot $TargetRoot
```

Each check and its fix:

| # | Check | Common fix |
|---|---|---|
| 1 | schema v3 loads | manifest is corrupt or wrong schema; restore from VCS |
| 2 | all non-self hashes match | drift: `compare-with-package` to see which; either promote (issue 4) or re-install |
| 3 | no generated-block/append-fragment carries whole-file hash | manifest schema bug; should never happen post-v3 |
| 4 | depotRevision == headRev | a tracked file was edited outside the installer; run `p4 fstat -T headRev` on each tracked path and re-bind |
| 5 | no unmanaged scaffold-like files | something landed under managed roots without a manifest entry; add the entry or remove the file |
| 6 | local-only files not in P4 opens | a localOnly file got `p4 add`-ed by accident; revert it |
| 7 | tool-capability deviations recorded | informational; no fix needed |
| 8 | block-scoped null-blockHash reporting | informational unless you have block-scoped files without markers |
| 9 | Marker Specification fixtures pass | the package's marker parser is broken; report as bug |
| 10 | `p4 opened -c default` is clean | move the unrelated files in default to a named CL — common in shared depots; see [perforce-consumer.md](perforce-consumer.md) |

### 6.2 `opencode.json`-style out-of-band local edits

Some files in Perforce have type `text+w` (always writable). They can be
edited without `p4 edit`, which means a local change won't show up in `p4
opened` but **will** show up in `compare-with-package` as `downstream-edit`.

Detect:

```powershell
& "$PkgRoot/scripts/compare-with-package.ps1" -TargetRoot $TargetRoot -PackageRoot $PkgRoot
```

Resolve by either promoting the change upstream (if intentional) or
re-installing to revert (if accidental).

### 6.3 `-Force` required for promotion

See [§4.1](#41-why--force-is-currently-required). Conservative default; will
relax when the package has real `sourceCommit` values.

### 6.4 Conflict outcomes

A `conflict` from `compare-with-package` means both the disk and the upstream
package source have changed since the pinned snapshot. There is no automatic
resolution — a human must decide which change to keep, or merge them, then
re-promote / re-install.

The `conflict` outcome only appears when `-PinnedSnapshotRoot` is supplied;
without it, all diffs are reported as `downstream-edit` (we can't tell the
direction of the change).

---

## 7. Script API reference

Brief signature reference. Run any script with `-?` for parameter details.

| Script | Purpose | Read/Write |
|---|---|---|
| `install.ps1` | Apply package templates to a project | Write (gated) |
| `diff-installed.ps1` | Drift report: disk vs manifest | Read-only |
| `compare-with-package.ps1` | Cross-repo diff: target vs package source | Read-only |
| `promote-from-project.ps1` | Push a local improvement back upstream | Write (gated, `-Force` required) |
| `check-mattpocock-updates.ps1` | Check upstream HEAD vs pinned commit | Read-only |
| `run-skeleton-preflight.ps1` | 10-point sanity check (gates install -Mode Write) | Read-only |
| `validate-markers.ps1` | Marker Specification parser entry point | Read-only |

### 7.1 Test runners (verification surface)

These exist in `scripts/` to prove the package works; consumers don't usually
run them, but reviewers might:

- `run-marker-fixtures.ps1` — 14 pathological cases for the marker parser
- `run-journal-tests.ps1` — 10 tests for the crash/recovery model
- `run-manifest-update-tests.ps1` — 5 tests for in-place manifest rewrites
- `run-classification-tests.ps1` — 16 tests for the 4-bucket ownership taxonomy
- `run-compare-tests.ps1` — 5 tests for the 4 cross-repo outcomes + meta-conflict
- `run-promote-tests.ps1` — 4 tests for promote-from-project Write mode
- `run-promotion-e2e-tests.ps1` — 5 tests for the full edit→classify→promote→parity loop

Total: 59 tests across 7 runners.

---

## 8. Where to read more

- [`perforce-consumer.md`](perforce-consumer.md) — Perforce-specific install/promote workflow.
- [ADR 0001](../../UE_Blank_Proto/Docs/adr/0001-extract-reusable-core-decisions.md)
  — Design rationale for boundary / parameterization / sequencing decisions.
- [Plan v1.6](../../UE_Blank_Proto/Myst_Proto/Docs/plan_agentic_scaffolding_packaging_WIP.md)
  — Full workstream plan with phase definitions.

The plan and ADR are in the Myst project (the implementation precedent); they
will move into the package once the package is published on GitHub as part of
a future phase beyond plan v1.6.
