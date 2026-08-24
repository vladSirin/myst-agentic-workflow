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

## 2.9 The other half: the plugin (Claude Code and Codex)

`setup.ps1` / `install.ps1` deliver the **scaffold** — `Docs/`, `.claude/` rules and
scripts, the generated blocks in `CLAUDE.md` / `AGENTS.md`. They do **not** deliver the
skills, reviewer agents, commands, or hooks. Those ship as a **plugin**, through each
tool's own add-on system, into that tool's own cache. Two payloads, two channels, two
pieces of state — a consumer needs both.

| | Claude Code | Codex |
|---|---|---|
| Install | prompt on trusting the repo, or `/plugin install myst-dev-kit@myst` | `codex plugin marketplace add vladSirin/myst-agentic-workflow` then `codex plugin add myst-dev-kit@myst` |
| Update | `claude plugin update myst-dev-kit@myst` (**restart to apply**) | `codex plugin marketplace upgrade` — that alone replaces the installed plugin |
| Verify | `claude plugin list` | `codex plugin list` |
| Installed to | `~/.claude/plugins/cache/<mkt>/<plugin>/<version>/` | `~/.codex/plugins/cache/<mkt>/<plugin>/<version>/` |

The update commands are **not** mirror images, so don't reason from one to the other:
Codex has no `plugin update` subcommand at all, and refreshing the marketplace snapshot
updates the installed plugin in place (verified 4.18.0 → 4.19.0, cache directory
replaced, no follow-up `add`). Claude's marketplace refresh does *not* update an
installed plugin — it needs the explicit `plugin update`, and then a restart.

**Two Codex limits worth knowing before you design around them**, both measured rather
than inferred:

- **No auto-loaded rules directory.** Codex reads `AGENTS.md` and nothing else, so an
  always-on `.claude/rules/*.md` reaches Claude and never reaches Codex. That is what
  `check-rule-parity.sh` guards.
- **No project-level hooks.** Codex loads hooks from `~/.codex/hooks.json` and from
  installed plugins only; a hooks file committed in the repo is ignored (both
  `.codex/hooks.json` and `.agents/hooks.json` were placed in a live session and never
  fired). A repo-local hook a project depends on is therefore Claude-only unless it
  ships through the plugin.

Plugin-shipped hooks are the delivery path for both tools, and `${CLAUDE_PLUGIN_ROOT}`
resolves in each — Codex ships that name as a compatibility alias (it is present in
`codex.exe`).

**When a hook must run under one tool only, gate on the tool you want to EXCLUDE.**
`[ -n "${CLAUDECODE:-}" ] && exit 0` skips under Claude Code and runs everywhere else.
Do not gate on a marker of the tool you want to include: an unknown or renamed host then
takes the *silent* branch, and a hook that never fires is indistinguishable from a hook
that fired and found nothing.

> **Corrected in 4.26.0.** Releases 4.13.0–4.25.2 documented the opposite — that Codex
> exports a native `PLUGIN_ROOT` — and shipped `[ -z "${PLUGIN_ROOT:-}" ] && exit 0` as the
> worked example. It does not: in `codex.exe` 0.146.0 the string `PLUGIN_ROOT` occurs exactly
> once, as a substring of `CLAUDE_PLUGIN_ROOT`, and `CODEX_PLUGIN_ROOT` occurs zero times
> (control: `CODEX_HOME` occurs 53 times, so env names are stored in the clear and a zero is
> meaningful). That variable was unset on **every** host, so the gate was always true and
> `submit-audit-bridge.sh` never ran the audit for anyone, on any tool, for its whole life.
> The once-open question -- whether Codex plugin hooks fire at all -- is settled: the
> bridge WAS watched firing under Codex on 2026-08-06 (see the v4.27.1 release notes).
> Re-verify with `MYST_AUDIT_DEBUG=1` after any hooks.json or host-version change -- the
> bridge announces every exit path, so total silence means it never ran; the observation
> is per-setup, not a permanent guarantee.

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
  tracks. Examples: project bibles, project-invented rule files.

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

### 6.2 `text+w`-style out-of-band local edits

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

See [§4.3](#43-why--force-is-currently-required). Conservative default; will
relax when the package has real `sourceCommit` values.

### 6.4 Conflict outcomes

A `conflict` from `compare-with-package` means both the disk and the upstream
package source have changed since the pinned snapshot. There is no automatic
resolution — a human must decide which change to keep, or merge them, then
re-promote / re-install.

The `conflict` outcome only appears when `-PinnedSnapshotRoot` is supplied;
without it, all diffs are reported as `downstream-edit` (we can't tell the
direction of the change).

### 6.5 Marker Specification

The parsing rules for generated-block / append-fragment markers
(`<!-- AGENTIC-SCAFFOLD:BEGIN id=... -->` ... `<!-- AGENTIC-SCAFFOLD:END id=... -->`).
Implemented by [`scripts/lib/Markers.ps1`](../scripts/lib/Markers.ps1) (a pure,
read-only parser); `scripts/validate-markers.ps1` is the CLI entry point, and
`scripts/run-marker-fixtures.ps1` holds the 14 pathological fixtures that pin
the behavior. The hard rules, as the code implements them:

- **Whole-line markers.** A marker must be a whole line, with at most 3 leading
  spaces. Comment style follows the file type: HTML comments for `.md`;
  `#`-comments for `.p4ignore`, extensionless files, and everything else.
- **LF normalization.** Files are read as UTF-8 and CRLF / lone-CR line endings
  are normalized to LF before parsing. Block content and block hashes are always
  computed over the LF form, so a client's CRLF checkout (e.g. Perforce
  `LineEnd: local` on Windows) never changes a block hash.
- **BOM stripping.** A leading UTF-8 BOM is stripped on read and never
  reintroduced by the parser.
- **Code-fence exclusion.** A marker-looking line inside a fenced code block
  (three-plus backticks or tildes, CommonMark) or an indented code block (4+
  leading spaces or a tab) is inert -- documentation can SHOW markers without
  them being parsed as markers. This is also why the leading-whitespace budget
  is 3 spaces: at 4, the line IS an indented code block.
- **Ambiguity refuses.** Per id there must be exactly one BEGIN and one END,
  with BEGIN before END, no nesting, no overlap. Zero, multiple, unbalanced, or
  inverted markers are a hard error: callers map it to exit code 2 and refuse to
  write rather than guess.
- **Block content** is the lines strictly between the BEGIN and END marker
  lines. The `sha256=` value embedded on a BEGIN line is informational
  redundancy only -- the manifest's `blockHash` is authoritative and the
  embedded value is never trusted.

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
run them, but reviewers might. **One suite per `scripts/run-*-tests.ps1` file --
the glob is the authoritative count** (18 files match as of this edit; CI in
`.github/workflows/tests.yml` discovers suites by the same glob and runs every
one on each PR/push, and asserts the README badge against that count). The
suites cover, among other things: the marker parser's pathological fixtures,
the install journal's crash/recovery model (including EOL policy), manifest
rewrites, the ownership-classification taxonomy, cross-repo compare outcomes,
promote round-trips and the promotion e2e loop, marketplace-manifest lockstep,
intra-package link existence, upgrade reconciliation (preserve/adopt), the
package-shipped bash hooks, and the PowerShell 5.1 `git pull` regression.

(`run-marker-fixtures.ps1` and `run-skeleton-preflight.ps1` are entry points
invoked by suites/installs rather than suites themselves.)

---

## 8. Where to read more

- [`perforce-consumer.md`](perforce-consumer.md) — Perforce-specific install/promote workflow.
- [ADR 0001](adr-0001-extract-reusable-core-decisions.md)
  — Design rationale for boundary / parameterization / sequencing decisions.
- Plan v1.6 (`plan_agentic_scaffolding_packaging_WIP.md`) — the full workstream
  plan with phase definitions. It lives in the origin Myst project's Perforce
  depot (the implementation precedent), not in this repository.

The ADR ships in this repo's `docs/`; the plan remains in the Myst project and
would only move here if that planning history is ever published.
