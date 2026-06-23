# myst-agentic-workflow

**Reusable agentic-workflow scaffolding for [Codex](https://github.com/openai/codex), [Claude Code](https://github.com/anthropics/claude-code), and [OpenCode](https://github.com/sst/opencode) — installed in seconds, kept in sync over time.**

The skills, workflows, and conventions you'd hand-copy between projects, packaged as a single source of truth with a crash-safe installer, drift detection, and a promotion path. So your team's hard-won agentic improvements don't get stranded in one repo.

[![tests](https://img.shields.io/badge/tests-16%20suites%20passing-brightgreen)](#) [![version](https://img.shields.io/badge/version-v2.11.0-blue)](https://github.com/vladSirin/myst-agentic-workflow/releases) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## Provenance

Extracted from `Myst_Proto`, a UE5/Perforce game project, and offered as a starting point for anyone else. MIT-licensed, generic core, honest about origin. The `myst-` prefix says where it came from, not who it's for.

The `overlays/myst-project/` directory ships the original project-specific content **as a reference example, not generic content** — see [`overlays/myst-project/README.md`](overlays/myst-project/README.md). `setup.ps1` never auto-installs it.

## Quickstart (60-second setup)

```powershell
git clone https://github.com/vladSirin/myst-agentic-workflow
$Pkg = "$PWD/myst-agentic-workflow"

# One command. Auto-detects Perforce/git/filesystem and UE-vs-not.
& "$Pkg/setup.ps1" -TargetRoot c:/path/to/your-project [-Yes]
```

That's it. Your project now has the same skills, workflows, and slash commands in `.claude/`, `.Codex/`, and `.opencode/` — whichever tools you have installed will pick them up.

Three lifecycle commands cover the entire flow:

```powershell
& "$Pkg/setup.ps1"   -TargetRoot $Target  [-Yes]                        # first-time install
& "$Pkg/update.ps1"  -TargetRoot $Target  [-Yes] [-NoPull]              # sync upstream changes in
& "$Pkg/upgrade.ps1" -TargetRoot $Target  [-Apply]                      # major version jump (preserves customizations)
& "$Pkg/promote.ps1" -TargetRoot $Target -Paths '<file>'                # push local improvements out
```

All three dry-run first, prompt before writing, and auto-derive their configuration from your installed manifest.

**Upgrading an older install?** Run [`upgrade.ps1`](upgrade.ps1) (preview, then `-Apply`) — it adds new skills, refreshes untouched files, **preserves your customizations**, removes retired skills, and (for Perforce) wraps it all in one reviewable changelist. `setup.ps1`/`update.ps1` can't do this jump (they drive install from the stale manifest). See [`docs/upgrade.md`](docs/upgrade.md).

## Why this package exists

Pain points solved, with the skills / scripts that solve them.

### #1: Three agentic CLIs that drift apart

Codex, Claude Code, and OpenCode each have their own config dirs (`.Codex/`, `.claude/`, `.opencode/`). When you tweak a workflow file in one, the others fall behind. Multiply by every project you work on and the drift becomes structural.

**The fix:** every skill, workflow, and agent ships in **all three tool directories at once**. Edit the upstream template; `update.ps1` propagates the change to every consumer's per-tool directory. Edit a per-tool file in a consumer; `promote.ps1` round-trips it back to the template (reverse-substituting `{{var}}` placeholders) so the next update keeps the three tools in lockstep.

### #2: The Bible-file corruption risk

Files like `CLAUDE.md`, `AGENTS.md`, and `.p4ignore` are *co-owned*: humans author the bulk of them, agents need to inject a block. A naive installer that overwrites the whole file destroys your project bible on first run.

**The fix:** the [**Marker Specification**](docs/install.md#6-troubleshooting) defines hard parsing rules — whole-line markers, LF normalization, BOM stripping, CommonMark code-fence exclusion, refuse-to-write on ambiguity. The installer only ever touches bytes strictly between `<!-- AGENTIC-SCAFFOLD:BEGIN -->` and `<!-- AGENTIC-SCAFFOLD:END -->`. 14/14 pathological fixtures verify it.

### #3: Half-installed scaffolds

A killed installer mid-write leaves your project in a broken state. Some files updated, some still old, hashes mismatched, no clean way to recover.

**The fix:** every write goes through **`InstallJournal`** — exclusive lock, staged temp files, atomic NTFS rename across the whole set, transactional restore-from-backup on any mid-commit failure. 10/10 journal tests, including process-kill scenarios. A killed `install.ps1` either fully succeeds or fully reverts; never anything in between.

### #4: "Did I edit this, or did upstream?"

After months of usage, no one remembers which files are pristine package templates vs which got tweaked locally. Updates become risky, promotions become guesswork.

**The fix:** **`compare-with-package.ps1`** classifies every file into four outcomes — `clean`, `downstream-edit`, `upstream-update`, `conflict` — plus meta-conflict detection for schema and overlay enumeration. Drift state is no longer in your head; it's in a deterministic report with an exit code suitable for CI.

### #5: Improvements stuck in one project

You tighten a workflow on Monday. The team's other three projects don't get the benefit until someone manually diffs and copies — if they ever do.

**The fix:** **`promote.ps1`** classifies your local change (reusable-core / perforce-overlay / ue-overlay / myst-project-overlay), reverse-substitutes project values back to `{{game_docs_root}}`-style placeholders, roundtrip-verifies the result, and writes it into the package working tree. Then a normal git PR ships it to every other consumer's next `update.ps1`.

### #6: Perforce + multi-developer chaos

Perforce projects have specific failure modes a generic installer ignores — read-only files, the `+w` always-writable file-type pitfall, named changelists, default-change pollution from other workstreams.

**The fix:** `install.ps1 -UsePerforce -Changelist new` opens every changed file for edit in a named CL with a structured What/Why/Notes description. The 10-point **preflight gate** catches drift (manifest hash mismatch, depot revision skew, files in default change) before any write — fails fast with actionable error messages. See [`docs/perforce-consumer.md`](docs/perforce-consumer.md).

## Reference

### Lifecycle commands (top-level)

The three commands you'll actually run.

| Command | Purpose |
|---|---|
| [`setup.ps1`](setup.ps1) | First-time install: auto-detect VC, bootstrap manifest, dry-run, write. |
| [`update.ps1`](update.ps1) | Sync upstream: `git pull` + compare + dry-run + write. Auto-wraps Perforce CL. |
| [`upgrade.ps1`](upgrade.ps1) | Major-version upgrade of an existing consumer: regenerate manifest, add new, refresh untouched, **preserve customizations**, remove retired. Preview by default; `-Apply` (Perforce CL). |
| [`promote.ps1`](promote.ps1) | Push local improvements to package: auto-classify + dry-run + write. |

### Skills (per-tool, installed under `.claude/`, `.Codex/`, `.opencode/`)

Adapted from [mattpocock/skills](https://github.com/mattpocock/skills) at pinned commit `6eeb81b`, MIT-licensed, attribution preserved. **20 skills**, vendored **verbatim** (upstream YAML frontmatter; Claude/Codex byte-identical, OpenCode adds only `compatibility`). Every link below resolves to `templates/<tool>/.<tool>/skills/<name>/SKILL.md`.

**Engineering**

| Skill | Use it when |
|---|---|
| `/diagnosing-bugs` | A hard bug / perf regression: build a feedback loop → reproduce + minimise → hypothesise → instrument → fix + regression-test. |
| `/tdd` | Build a feature / fix a bug with red-green-refactor, one vertical slice at a time. |
| `/improve-codebase-architecture` | Find deepening opportunities; informed by CONTEXT.md and docs/adr/. |
| `/codebase-design` | Shared vocabulary for designing deep modules and seams. |
| `/domain-modeling` | Actively build/sharpen the domain model — challenge terms, write the glossary + ADRs inline. |
| `/grill-with-docs` | Stress-test a plan against the project's domain language before a non-trivial change. |
| `/to-prd` | Turn the current conversation into a PRD. |
| `/to-issues` | Break a PRD/plan into independently-grabbable vertical-slice issues. |
| `/triage` | Move issues through the lifecycle state machine. |
| `/implement` | Implement a planned slice from a PRD/issue. |
| `/resolving-merge-conflicts` | Resolve merge conflicts (Perforce text-merge notes via the `perforce` overlay). |
| `/setup-matt-pocock-skills` | One-time: configure the issue tracker + triage labels. |

**Productivity**

| Skill | Use it when |
|---|---|
| `/grilling` | Relentless plan/design interview until shared understanding (`grill-me` / `grill-with-docs` delegate here). |
| `/grill-me` | Shorthand entry to a `/grilling` session. |
| `/handoff` | Compact the session into a handoff doc for another agent. |
| `/teach` | Stateful, multi-session teaching workspace (user-invoked). |
| `/writing-great-skills` | Author high-quality skills (reference + glossary). |
| `/edit-article` | Edit / rewrite an article. |
| `/obsidian-vault` | Search / create / manage Obsidian notes. |

**Local (not from upstream)**

| Skill | Use it when |
|---|---|
| `/roundtable` | Multi-perspective design discussion when one viewpoint isn't enough. |

Plus package-management commands `/update-myst-skills` (sync upstream in) and `/promote-myst-skills` (push a local improvement out); overlay-only additions `/sync-build-submit` (`ue`), `/design` + `architecture-reviewer` (`myst-project`).

### Divergence from upstream (and why)

We track upstream **faithfully** — name + body + architecture + verbatim frontmatter — and deviate only with a documented reason (see [ADR-0002](docs/adr-0002-vendor-and-overlay-not-fork.md), [ADR-0003](docs/adr-0003-verbatim-skill-format.md), and `.scratch/agentic-scaffold-rejected-upstream.json`):

- **Project specifics live only in overlays**, never in the base. `diagnosing-bugs` → `ue` overlay `UE-NOTES.md` (automation / `-ExecCmds` loops, `p4` bisection, editor HITL). `resolving-merge-conflicts` → `perforce` overlay `P4-NOTES.md` (P4 text merges). `to-issues` follows upstream's removal of HITL/AFK slice-typing — AFK-readiness rides the triage label instead.
- **Renamed (followed upstream):** `diagnose` → `diagnosing-bugs`. **Removed (followed upstream):** `zoom-out`, `caveman`, `write-a-skill` (replaced by `writing-great-skills`).
- **Skipped (out of scope):** `ask-matt` (personal/branded), `prototype` (web-bound). **Deferred:** `decision-mapping` (upstream marks it in-progress).
- Everything else is byte-faithful to upstream HEAD `6eeb81b`.

### Workflows (always-on rules)

Rules the agent follows autonomously. Loaded every session.

| Workflow | Scope | What it enforces |
|---|---|---|
| `AgenticWorkflow.md` | core | Discussion → PRD → issues → triage → impl → verify → review/submit. |
| `PlanPriority.md` | core | **HARD RULE**: Always use existing plans before creating new ones. |
| `ChangelistVerification.md` | perforce overlay | **HARD RULE**: CL-by-CL execution, never batched. Stop between CLs for verification. |
| `ReviewAndSubmit.md` | perforce overlay | Pre-submit protocol with What/Why/Notes CL description standard and reviewer routing. |

### Agents

Specialized subagents available via the agent tool.

| Agent | Triggers on |
|---|---|
| `architecture-reviewer` | Post-implementation review. Code Complete + SOLID + project-specific patterns. (Lives in `overlays/myst-project/` — UE-flavoured; adapt for your project.) |
| `radical-design-critic` | Design docs / proposals. Stress-tests for edge cases, UX friction, hidden complexity. |

### Overlays

Tools and rules layered on top of the core for specific environments.

| Overlay | When | What it adds |
|---|---|---|
| `core` | always | The core skills + workflows + agent above. The portable layer (vendored from upstream). |
| `core-local` | always (force-added) | **Package-invented (non-upstream)** skills, kept physically separate from vendored content so an upstream re-sync can't clobber them. Holds `roundtable`. See [ADR-0004](docs/adr-0004-local-origin-provenance-and-core-local.md). |
| `perforce` | `setup.ps1` auto-adds if `.p4ignore` or in P4 client | 3 Perforce workflows (CL-by-CL, review/submit, VC conventions). |
| `ue` | `setup.ps1` auto-adds if `*.uproject` present | UE sync-build-submit slash command + UE-pattern `.p4ignore` fragment. |
| `myst-project` | **never auto-added**; reference example | Original Myst_Proto-specific content. See [overlay README](overlays/myst-project/README.md). |

## FAQ

**Do I need all three tools (Codex / Claude Code / OpenCode)?**
No. Pass `-Tools` to select a subset, e.g. `setup.ps1 -TargetRoot ... -Tools claude`. The other tool directories simply aren't written. You can add tools later by re-running `setup.ps1` with a broader `-Tools` flag and `-Force`.

**Do I need Perforce?**
No. `setup.ps1` defaults to `filesystem` mode when it sees no `.p4ignore`. The core skills + workflows are version-control-agnostic. The Perforce-specific workflows only install if you opt in (auto-detected or explicit `-Overlays perforce`).

**Do I need Unreal Engine?**
No. UE-specific content (sync-build-submit, UE p4ignore patterns) only installs if a `*.uproject` is detected. A film/VFX team on Perforce, or a Unity team on Perforce, gets `perforce` workflows without UE bias.

**Can I customize the templates after install?**
Yes. The installed copies in your project are yours to edit. `compare-with-package.ps1` will report them as `downstream-edit`; `promote.ps1` will offer to push them back upstream if they're generally useful.

**How do I add my own skills / workflows?**
For project-specific content: write your own overlay. Copy `overlays/myst-project/`'s structure as a starting point, add `your-project` to `package-manifest.json`'s overlay enum, populate `manifest-template.json` with entries pointing at your overlay paths. `init-consumer.ps1 -Overlays 'core,your-project'` picks it up.

For generally-useful content: write it in your project first, then `promote.ps1` it back to `templates/` with `-Classification reusable-core`.

**Does this work on Linux / Mac?**
The scripts are PowerShell — Windows-first. PowerShell 7+ runs on Linux/Mac but the install paths assume Windows-style separators in some places. Not currently tested cross-platform. If you're on Mac/Linux and want to adopt: open an issue, the path layer is straightforward to generalize.

**What's the difference between `setup.ps1` and the scripts under `scripts/`?**
The three top-level scripts (`setup.ps1`, `update.ps1`, `promote.ps1`) are one-command wrappers with sensible defaults. The scripts under `scripts/` are the underlying primitives — useful for CI integration, scripting multi-project rollouts, or debugging. Both paths are documented in [`docs/install.md`](docs/install.md).

**Why a manifest at all? Why not just `cp -r`?**
Three reasons. **Drift detection** — without a manifest of expected hashes, `compare-with-package.ps1` can't distinguish "user edited this" from "package upgraded this". **Block-scoped editing** — co-owned files (`CLAUDE.md`, `.p4ignore`) need per-block hashes, not whole-file. **Provenance** — every entry records `sourceCommit`, so you can prove what version your install corresponds to.

**Why do I have to `git pull` the package before `update.ps1`?**
You don't — `update.ps1` runs `git pull` for you by default. Pass `-NoPull` if you've already pulled or are testing against an unmerged local change.

## Gotchas (known limitations)

- **`opencode.json` is `+w` (always-writable).** OpenCode mutates it at runtime when you grant permissions in-session. **Resolved in v1.7.0** via the `runtime-mutable` hashPolicy — the file is now seeded by install on first run, never overwritten after, and reported as `runtime-mutable` (not `downstream-edit`) by compare. Preflight check 2 skips it. See [§ runtime-mutable below](#what-runtime-mutable-means).

- **Preflight check 10 (default-change clean).** Write-mode refuses if your P4 default changelist contains *any* files — including unrelated work from other workstreams. Move them to a named CL or revert before `install.ps1 -Mode Write`. `setup.ps1` and `update.ps1` surface this as a clear error pointing at the offending files.

- **Generated-block strict parsing.** Any ambiguity in the markers (zero matches, multiple matches, unbalanced, nested, inside a code fence) is a hard error — the installer refuses to write rather than guessing. Fix by manually correcting the markers, then re-run.

- **`promote.ps1` + Perforce on the package side.** If your `PackageRoot` is itself in a Perforce client workspace, `promote.ps1` can't open files for edit; the atomic rename will hit read-only files. Workaround: `p4 edit -c <CL> overlays/.../*` manually before promoting. Documented in [`docs/install.md` §4.5](docs/install.md). Doesn't apply if `PackageRoot` is a normal git clone (the common case).

- **Bash required for hooks.** The session-start `doc-audit.sh` hook needs Bash (Git Bash, WSL, or similar) on Windows. Skip the hook if you don't have it — the install itself works without it.

- **The `myst-project` overlay is not generic.** Don't install it unless you ARE Myst_Proto. `setup.ps1` never auto-adds it; you have to explicitly pass `-Overlays 'core,myst-project'` to get it. See [overlay README](overlays/myst-project/README.md).

- **PowerShell-only, Windows-tested.** Cross-platform PowerShell 7+ should work in principle but isn't tested. See FAQ.

## Layout

```
myst-agentic-workflow/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── package-manifest.json          # schema v3 + package metadata
├── manifest-template.json         # canonical entry list for new consumers
├── setup.ps1                      # first-time install
├── update.ps1                     # sync upstream changes in
├── promote.ps1                    # push local improvements out
├── docs/
│   ├── install.md                 # full install/update/promote/upstream-sync guide
│   ├── perforce-consumer.md       # UE+P4 addendum
│   ├── adr-0001-extract-reusable-core-decisions.md
│   ├── adr-0002-vendor-and-overlay-not-fork.md
│   └── adr-0003-verbatim-skill-format.md
├── templates/{common,codex,claude,opencode}/
│   └── ...                        # the core skills + workflows + agent, per-tool
├── overlays/
│   ├── perforce/                  # CL workflow, review-and-submit, VC rules
│   ├── ue/                        # sync-build-submit, UE p4ignore fragment
│   └── myst-project/              # reference example only — DO NOT INSTALL
├── scripts/
│   ├── init-consumer.ps1          # bootstrap a fresh manifest (used by setup.ps1)
│   ├── install.ps1                # DryRun default; Write preflight-gated
│   ├── compare-with-package.ps1   # cross-repo drift + conflict report
│   ├── diff-installed.ps1         # local drift report
│   ├── promote-from-project.ps1   # underlying promote primitive
│   ├── check-mattpocock-updates.ps1
│   ├── run-skeleton-preflight.ps1 # 10-point write-mode gate
│   ├── migrate-retired-skills.ps1 # upgrade helper: remove retired skills from old installs
│   └── run-*-tests.ps1            # 16 test suites (incl. parity, link-existence, provenance)
└── fixtures/                      # E2E install fixtures
```

## Status

**v2.11.0** — Converged to upstream `mattpocock/skills` HEAD (`6eeb81b`). Skills are now vendored **verbatim** (upstream YAML frontmatter; Claude/Codex byte-identical, OpenCode adds only `compatibility`); project specifics live in overlays, never in the base (see [ADR-0002](docs/adr-0002-vendor-and-overlay-not-fork.md), [ADR-0003](docs/adr-0003-verbatim-skill-format.md)). Removed `zoom-out`/`caveman`/`write-a-skill`; renamed `diagnose` → `diagnosing-bugs`; vendored new skills (`codebase-design`, `domain-modeling`, `grilling`, `teach`, `writing-great-skills`, `implement`, `setup-matt-pocock-skills`, `resolving-merge-conflicts`, …). 20 skills, 13 test suites green. Full history in [CHANGELOG.md](CHANGELOG.md).

## What `runtime-mutable` means

Some files are package-templated but get rewritten by the tool at runtime — `opencode.json`'s `permission` block is the canonical case (OpenCode mutates it when you grant a permission in-session). These files can't be hash-tracked the normal way without perpetually reporting drift.

The `hashPolicy: "runtime-mutable"` policy says:
- **Install seeds the file from the template on first run** (when the target is absent).
- **Subsequent installs never overwrite it** — the runtime mutations are preserved.
- **Preflight check 2 skips the hash check** — no false-positive drift.
- **Compare reports the entry with outcome `runtime-mutable`** (its own bucket, not `downstream-edit` or `clean`); does not count toward conflicts.
- **Promote refuses** to push runtime-mutated content upstream (the disk content is user-state, not package content).

Mark any tool-managed-at-runtime file with this policy in `manifest-template.json`. Currently used only for `opencode.json`; reusable for any future file with the same property.

See [CHANGELOG.md](CHANGELOG.md) for the version history.

## License

MIT. Bundles content adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, pinned at commit `6eeb81b`) — attribution preserved in [LICENSE](LICENSE).

## Contributing

The package was extracted from one project. Improvements that benefit other adopters are welcome:

1. Edit the file in your consumer project first (where you'll actually use it).
2. Run `promote.ps1 -TargetRoot <consumer> -Paths <file>` to push the change to the package working tree.
3. Open a PR against `main`.

For larger structural changes (new overlay, new tool support, manifest schema bump), open an issue first.
