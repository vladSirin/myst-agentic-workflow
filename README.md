# myst-agentic-workflow

**Reusable agentic-workflow scaffolding for [Claude Code](https://github.com/anthropics/claude-code) and [Codex](https://github.com/openai/codex) — installed in seconds, kept in sync over time.**

The skills, workflows, and conventions you'd hand-copy between projects, packaged as a single source of truth with a crash-safe installer, drift detection, and a promotion path. So your team's hard-won agentic improvements don't get stranded in one repo.

[![tests](https://img.shields.io/badge/tests-18%20suites%20passing-brightgreen)](#) [![version](https://img.shields.io/badge/version-v4.35.0-blue)](https://github.com/vladSirin/myst-agentic-workflow/releases) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## Provenance

Extracted from `Myst_Proto`, a UE5/Perforce game project, and offered as a starting point for anyone else. MIT-licensed, generic core, honest about origin. The `myst-` prefix says where it came from, not who it's for.

The `overlays/myst-project/` directory ships the original project-specific content **as a reference example, not generic content** — see [`overlays/myst-project/README.md`](overlays/myst-project/README.md). `setup.ps1` never auto-installs it.

## Quickstart (60-second setup)

> **Myst team member?** Follow [SETUP.md](SETUP.md) — it covers both archetypes (standard sync-and-go and poweruser) for Claude Code and Codex.

```powershell
git clone https://github.com/vladSirin/myst-agentic-workflow
$Pkg = "$PWD/myst-agentic-workflow"

# One command. Auto-detects Perforce/git/filesystem and UE-vs-not.
& "$Pkg/setup.ps1" -TargetRoot c:/path/to/your-project [-Yes]
```

That's it for the **committed core** (bible generated-blocks, team docs, rules, hook scripts, `.p4ignore` fragment). The skills/agents/commands kit installs separately as a **plugin** (see next section) — `setup.ps1` no longer file-copies it.

Four lifecycle commands cover the entire flow:

```powershell
& "$Pkg/setup.ps1"   -TargetRoot $Target  [-Yes]                        # first-time install
& "$Pkg/update.ps1"  -TargetRoot $Target  [-Yes] [-NoPull]              # sync upstream changes in
& "$Pkg/upgrade.ps1" -TargetRoot $Target  [-Apply]                      # major version jump (preserves customizations)
& "$Pkg/promote.ps1" -TargetRoot $Target -Paths '<file>'                # push local improvements out
```

All four dry-run first, prompt before writing, and auto-derive their configuration from your installed manifest.

## Install as a plugin (marketplace)

The repo is a **plugin marketplace** for both tools — since v4.0.0 the plugin IS the delivery path for the kit (the installer only bootstraps the committed core). One plugin is published: **`myst-dev-kit`** — 24 skills (engineering + productivity + the team process rules as on-demand skills), both review agents (Claude only — they are Markdown, and Codex agents are TOML), `sync-build-submit` and package commands, and the Codex-side Submit-Audit warning bridge.

```bash
# Claude Code
/plugin marketplace add vladSirin/myst-agentic-workflow
/plugin install myst-dev-kit@myst

# Codex
codex plugin marketplace add vladSirin/myst-agentic-workflow
# then /plugins -> Myst Team Plugins -> install myst-dev-kit
```

Both tools read their native manifest from the same repo (`.claude-plugin/marketplace.json` for Claude Code, `.agents/plugins/marketplace.json` for Codex; consistency is enforced by `scripts/run-marketplace-tests.ps1` + `claude plugin validate`). The repo is public today, so installs need no auth (if it goes private later: collaborator access + `gh auth login`).

### Keeping the plugin up to date

**The two tools do not work the same way. Do not infer one from the other** — both sequences below were verified by running them across a real version bump.

```bash
# Claude Code — refresh the marketplace, THEN update the plugin, then restart.
claude plugin marketplace update myst
claude plugin update myst-dev-kit@myst      # "Restart to apply changes"

# Codex — refreshing the marketplace IS the update. No second command.
codex plugin marketplace upgrade
```

- **Claude**: a marketplace refresh alone does **not** move an installed plugin; it stays pinned until the explicit `plugin update`, and the new version loads on the next session.
- **Codex**: `marketplace upgrade` replaces the installed plugin in place, cache directory and all. There is no `codex plugin update` subcommand.
- Verify with `claude plugin list` / `codex plugin list`. Note Codex's VERSION column reports the *marketplace snapshot*; to confirm what is actually installed, look under `~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/`.
- Inside a Claude Code session without the `/plugin` command (e.g. some IDE extensions), the same commands work from a terminal — `claude plugin …` is a plain CLI subcommand.

**Two Codex limits worth knowing before you design around them** (measured, not inferred):

- **No auto-loaded rules directory.** Codex reads `AGENTS.md` and nothing else, so an always-on `.claude/rules/*.md` reaches Claude and never reaches Codex. `check-rule-parity.sh` guards that gap.
- **No project-level hooks.** Codex loads hooks from `~/.codex/hooks.json` and from installed plugins only; a hooks file committed in the repo is ignored. A repo-local hook is Claude-only unless it ships through the plugin.

Notes:
- The plugin's `hooks/hooks.json` delivers the client Submit-Audit warning **to Codex only** — under Claude Code the bridge no-ops because the consumer project's committed `.claude/settings.json` already registers the same audit (no double warnings). On consumers without the Myst governance core, the hook exits silently. **Verified firing under Codex 2026-08-06** (`docs/tool-capability-matrix.md`); it had never run on any host before v4.26.0.
- `agents/` (radical-design-critic) is Claude-only — Codex ignores the directory.
- Former always-on workflows are now **on-demand skills** with trigger-strength descriptions (`review-and-submit`, `changelist-verification`, `pre-implementation-gate`, ...) — advisory by design; the server-side Submit-Audit is the enforcement backstop.

**Upgrading an older install?** Run [`upgrade.ps1`](upgrade.ps1) (preview, then `-Apply`) — it adds new skills, refreshes untouched files, **preserves your customizations**, removes retired skills, and (for Perforce) wraps it all in one reviewable changelist. `setup.ps1`/`update.ps1` can't do this jump (they drive install from the stale manifest). See [`docs/upgrade.md`](docs/upgrade.md).

## Why this package exists

Pain points solved, with the skills / scripts that solve them.

### #1: Agentic CLIs that drift apart

Claude Code and Codex each have their own config dirs (`.claude/`, `.Codex/`). When you tweak a workflow file in one, the other falls behind. Multiply by every project you work on and the drift becomes structural.

**The fix:** every skill, workflow, and agent lives **once**, in `plugins/myst-dev-kit/`, and the manifest maps that single source into both tool directories. Edit the shared source; `update.ps1` propagates the change to every consumer's per-tool directories. Edit a per-tool file in a consumer; `promote.ps1` round-trips it back to the shared source (reverse-substituting `{{var}}` placeholders) so both tools stay in lockstep by construction.

### #2: The Bible-file corruption risk

Files like `CLAUDE.md`, `AGENTS.md`, and `.p4ignore` are *co-owned*: humans author the bulk of them, agents need to inject a block. A naive installer that overwrites the whole file destroys your project bible on first run.

**The fix:** the [**Marker Specification**](docs/install.md#65-marker-specification) defines hard parsing rules — whole-line markers, LF normalization, BOM stripping, CommonMark code-fence exclusion, refuse-to-write on ambiguity. The installer only ever touches bytes strictly between `<!-- AGENTIC-SCAFFOLD:BEGIN -->` and `<!-- AGENTIC-SCAFFOLD:END -->`. 14/14 pathological fixtures verify it.

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

The four commands you'll actually run.

| Command | Purpose |
|---|---|
| [`setup.ps1`](setup.ps1) | First-time install: auto-detect VC, bootstrap manifest, dry-run, write. |
| [`update.ps1`](update.ps1) | Sync upstream: `git pull` + compare + dry-run + write. Auto-wraps Perforce CL. |
| [`upgrade.ps1`](upgrade.ps1) | Major-version upgrade of an existing consumer: regenerate manifest, add new, refresh untouched, **preserve customizations**, remove retired. Preview by default; `-Apply` (Perforce CL). |
| [`promote.ps1`](promote.ps1) | Push local improvements to package: auto-classify + dry-run + write. |

### Skills (shipped in the `myst-dev-kit` plugin)

The engineering/productivity set is adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, attribution preserved in [LICENSE](LICENSE); the pinned commit is recorded in `package-manifest.json`), vendored **verbatim**. The bundle also carries the local-origin skills (design, review-changes, roundtable, setup wizard) and the **team process rules converted to on-demand skills**. **24 skills total**; every skill name below links to its real `SKILL.md` under `plugins/myst-dev-kit/skills/`.

**Engineering**

| Skill | Use it when |
|---|---|
| [`/diagnosing-bugs`](plugins/myst-dev-kit/skills/diagnosing-bugs/SKILL.md) | A hard bug / perf regression: build a feedback loop, reproduce + minimise, hypothesise, instrument, fix + regression-test. |
| [`/tdd`](plugins/myst-dev-kit/skills/tdd/SKILL.md) | Build a feature / fix a bug with red-green-refactor, one vertical slice at a time. |
| [`/improve-codebase-architecture`](plugins/myst-dev-kit/skills/improve-codebase-architecture/SKILL.md) | Scan a codebase for deepening opportunities, presented as a visual HTML report, then grill through the one you pick. |
| [`/codebase-design`](plugins/myst-dev-kit/skills/codebase-design/SKILL.md) | Shared vocabulary for designing deep modules and seams. |
| [`/domain-modeling`](plugins/myst-dev-kit/skills/domain-modeling/SKILL.md) | Actively build/sharpen the domain model -- challenge terms, write the glossary + ADRs inline. |
| [`/grill-with-docs`](plugins/myst-dev-kit/skills/grill-with-docs/SKILL.md) | Stress-test a plan against the project's domain language before a non-trivial change; writes ADRs + glossary as it goes. |
| [`/research`](plugins/myst-dev-kit/skills/research/SKILL.md) | Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo -- reading legwork you can delegate. |
| [`/to-spec`](plugins/myst-dev-kit/skills/to-spec/SKILL.md) | Turn the current conversation into a spec on the issue tracker (specs start `needs-triage`). |
| [`/to-tickets`](plugins/myst-dev-kit/skills/to-tickets/SKILL.md) | Break a spec/plan into independently-grabbable vertical-slice tickets. |
| [`/triage`](plugins/myst-dev-kit/skills/triage/SKILL.md) | Move tickets through the lifecycle state machine. |
| [`/implement`](plugins/myst-dev-kit/skills/implement/SKILL.md) | Implement a planned slice from a spec/ticket. |
| [`/resolving-merge-conflicts`](plugins/myst-dev-kit/skills/resolving-merge-conflicts/SKILL.md) | Resolve merge conflicts (Perforce text-merge notes ship in the skill's `P4-NOTES.md`). |

**Productivity**

| Skill | Use it when |
|---|---|
| [`/grilling`](plugins/myst-dev-kit/skills/grilling/SKILL.md) | Relentless plan/design interview until shared understanding (`grill-with-docs` delegates here). |
| [`/handoff`](plugins/myst-dev-kit/skills/handoff/SKILL.md) | Compact the session into a handoff doc for another agent. |
| [`/writing-great-skills`](plugins/myst-dev-kit/skills/writing-great-skills/SKILL.md) | Author high-quality skills (reference + glossary). |

**Local (not from upstream)**

| Skill | Use it when |
|---|---|
| [`/design`](plugins/myst-dev-kit/skills/design/SKILL.md) | Create a design document with reviewer-agent feedback and iterate to approval; the team's doc-process rules (naming, lifecycle, BLOCKING/WARNING/INFO) live in the companion [PROCESS.md](plugins/myst-dev-kit/skills/design/PROCESS.md). |
| [`/review-changes`](plugins/myst-dev-kit/skills/review-changes/SKILL.md) | Pre-submit review of a CL/diff INLINE when reviewer subagents are unavailable (e.g. under Codex); same rubrics, same parseable `Verdict:` line. |
| [`/roundtable`](plugins/myst-dev-kit/skills/roundtable/SKILL.md) | Multi-perspective design discussion when one viewpoint isn't enough. |
| [`/setup-agentic-workflow`](plugins/myst-dev-kit/skills/setup-agentic-workflow/SKILL.md) | Interactive wizard to install/upgrade the scaffold in a project -- detects the environment, proposes tools + overlays, asks one question at a time, dry-runs, then writes (front-end over `setup.ps1`/`upgrade.ps1`). |

Plus the plugin **commands** (not skills): `/update-myst-skills` (sync upstream in), `/promote-myst-skills` (push a local improvement out), and `/sync-build-submit` (UE build-machine pipeline).

### Divergence from upstream (and why)

We track upstream **faithfully** — name + body + architecture + verbatim frontmatter — and deviate only with a documented reason (see [ADR-0002](docs/adr-0002-vendor-and-overlay-not-fork.md), [ADR-0003](docs/adr-0003-verbatim-skill-format.md), and `.scratch/agentic-scaffold-rejected-upstream.json`):

- **Project specifics live only in overlays**, never in the base. `diagnosing-bugs` → `ue` overlay `UE-NOTES.md` (automation / `-ExecCmds` loops, `p4` bisection, editor HITL). `resolving-merge-conflicts` → `perforce` overlay `P4-NOTES.md` (P4 text merges). `to-tickets` follows upstream's removal of HITL/AFK slice-typing — AFK-readiness rides the triage label instead.
- **Renamed (followed upstream):** `diagnose` → `diagnosing-bugs`. **Removed (followed upstream):** `zoom-out`, `caveman`, `write-a-skill` (replaced by `writing-great-skills`).
- **Skipped (out of scope):** `ask-matt` (personal/branded), `prototype` (web-bound). **Deferred:** `decision-mapping` (upstream marks it in-progress).
- Everything else is byte-faithful to upstream HEAD `e9fcdf9`.

### Process-rule skills (formerly always-on workflows)

Converted to on-demand skills in v4.0.0 — each carries a trigger-strength description so the agent loads it at the right moment; all are advisory (the server Submit-Audit is the backstop).

| Skill | Fires when | What it enforces |
|---|---|---|
| [`agentic-workflow`](plugins/myst-dev-kit/skills/agentic-workflow/SKILL.md) | non-trivial feature work starts | Discussion → spec → tickets → triage → impl → verify → review/submit. |
| [`pre-implementation-gate`](plugins/myst-dev-kit/skills/pre-implementation-gate/SKILL.md) | before drafting a multi-CL plan | **HARD RULE**: spec/tickets/triage must exist first. |
| [`changelist-verification`](plugins/myst-dev-kit/skills/changelist-verification/SKILL.md) | any multi-CL task | **HARD RULE**: CL-by-CL execution, never batched. Stop between CLs for verification. |
| [`review-and-submit`](plugins/myst-dev-kit/skills/review-and-submit/SKILL.md) | "review and submit" / any p4 submit | Pre-submit protocol: reviewer routing, Review Record block, preflight validators. |
| [`auto-plan-mode`](plugins/myst-dev-kit/skills/auto-plan-mode/SKILL.md) | start of non-trivial implementation | Decide whether to enter plan mode before coding. |

(The former `design-workflow` skill merged into [`design`](plugins/myst-dev-kit/skills/design/SKILL.md) in v4.28.0 -- the doc naming/location/reviewer-routing rules now live in that skill's [PROCESS.md](plugins/myst-dev-kit/skills/design/PROCESS.md).)

### Agents

Specialized subagents available via the agent tool.

| Agent | Triggers on |
|---|---|
| `architecture-reviewer` | Post-implementation review. Code Complete + SOLID + project-specific patterns. (Ships in `myst-dev-kit` since v4.0.0 — UE-flavoured; adapt for your project.) |
| `radical-design-critic` | Design docs / proposals. Stress-tests for edge cases, UX friction, hidden complexity. |

### Overlays

An overlay is a **logical name in the manifest** (`-Overlays ...`), not necessarily a directory: since v4.0.0 most former overlay content ships inside the `myst-dev-kit` plugin, so the on-disk `overlays/` directory holds only what must still be file-copied into a consumer -- `ue/` and `myst-project/` (see [overlays/README.md](overlays/README.md)).

| Overlay name | On disk today | When | What selecting it installs today |
|---|---|---|---|
| `core` | `templates/` + `plugins/myst-dev-kit/scripts/` (no `overlays/` dir) | always | The committed-core bootstrap: bible generated-blocks, consumer docs (MustRead, `Docs/agents/`), session hook scripts. |
| `core-local` | -- (name retired; content in the plugin) | accepted, installs nothing new | Package-invented skills (`roundtable`, `setup-agentic-workflow`) ship via the plugin now. See [ADR-0004](docs/adr-0004-local-origin-provenance-and-core-local.md). |
| `perforce` | -- (name retired; content in the plugin) | accepted, installs nothing new | The CL workflows are on-demand plugin skills now (`changelist-verification`, `review-and-submit`); P4 merge notes ride the `resolving-merge-conflicts` skill. |
| `ue` | `overlays/ue/` | `setup.ps1` auto-adds if `*.uproject` present | UE-pattern `.p4ignore` fragment, plus the `check-uproject-assoc.sh` guard (sourced from the plugin's scripts). |
| `myst-project` | `overlays/myst-project/` | **never auto-added**; reference example | Original Myst_Proto-specific committed-core content. See [overlay README](overlays/myst-project/README.md). |

Retired names old manifests may still carry (`afk-autonomy`, legacy alias `ue-perforce`) remain accepted and install nothing.

## FAQ

**Do I need both tools (Claude Code / Codex)?**
No. Pass `-Tools` to select a subset, e.g. `setup.ps1 -TargetRoot ... -Tools claude`. The other tool directory simply isn't written. You can add tools later by re-running `setup.ps1` with a broader `-Tools` flag and `-Force`.

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
The four top-level scripts (`setup.ps1`, `update.ps1`, `upgrade.ps1`, `promote.ps1`) are one-command wrappers with sensible defaults. The scripts under `scripts/` are the underlying primitives — useful for CI integration, scripting multi-project rollouts, or debugging. Both paths are documented in [`docs/install.md`](docs/install.md).

**Why a manifest at all? Why not just `cp -r`?**
Three reasons. **Drift detection** — without a manifest of expected hashes, `compare-with-package.ps1` can't distinguish "user edited this" from "package upgraded this". **Block-scoped editing** — co-owned files (`CLAUDE.md`, `.p4ignore`) need per-block hashes, not whole-file. **Provenance** — every entry records `sourceCommit`, so you can prove what version your install corresponds to.

**Why do I have to `git pull` the package before `update.ps1`?**
You don't — `update.ps1` runs `git pull` for you by default. Pass `-NoPull` if you've already pulled or are testing against an unmerged local change.

## Gotchas (known limitations)

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
├── CONTRIBUTING.md
├── SETUP.md                       # Myst team onboarding (both archetypes)
├── LICENSE
├── package-manifest.json          # schema v3 + package metadata
├── manifest-template.json         # canonical entry list for new consumers
├── setup.ps1                      # first-time install
├── update.ps1                     # sync upstream changes in
├── upgrade.ps1                    # major-version jump (preserves customizations)
├── promote.ps1                    # push local improvements out
├── .github/workflows/tests.yml    # CI: every scripts/run-*-tests.ps1 suite, each PR/push
├── .claude-plugin/marketplace.json  # plugin marketplace (Claude Code native)
├── .agents/plugins/marketplace.json # plugin marketplace (Codex native; same content, enforced by test)
├── docs/
│   ├── install.md                 # full install/update/promote/upstream-sync guide
│   ├── upgrade.md                 # existing-consumer major-version upgrade guide
│   ├── perforce-consumer.md       # UE+P4 addendum
│   ├── tool-capability-matrix.md  # what each tool loads (and deliberately does not)
│   ├── adr-0001-extract-reusable-core-decisions.md
│   ├── adr-0002-vendor-and-overlay-not-fork.md
│   ├── adr-0003-verbatim-skill-format.md
│   └── adr-0004-local-origin-provenance-and-core-local.md
├── plugins/myst-dev-kit/
│   ├── .claude-plugin/plugin.json # dual plugin manifests (one per tool)
│   ├── .codex-plugin/plugin.json
│   ├── agents/                    # architecture-reviewer + radical-design-critic (Claude only)
│   ├── commands/                  # promote-myst-skills, sync-build-submit, update-myst-skills
│   ├── hooks/hooks.json           # Codex Submit-Audit warn bridge (no-ops under Claude Code)
│   ├── scripts/                   # consumer hook scripts (doc-audit, rule parity, ...)
│   └── skills/                    # the 24 skills (ONE shared source for both tools)
├── templates/
│   ├── claude/CLAUDE.md           # per-tool bible templates (generated-block sources)
│   ├── codex/AGENTS.md
│   └── common/docs/               # tool-neutral consumer docs (MustRead, agents/)
├── overlays/
│   ├── ue/                        # UE-pattern p4ignore fragment
│   └── myst-project/              # reference example only — DO NOT INSTALL
└── scripts/
    ├── init-consumer.ps1          # bootstrap a fresh manifest (used by setup.ps1)
    ├── install.ps1                # DryRun default; Write preflight-gated
    ├── compare-with-package.ps1   # cross-repo drift + conflict report
    ├── diff-installed.ps1         # local drift report
    ├── promote-from-project.ps1   # underlying promote primitive
    ├── migrate-retired-skills.ps1 # upgrade helper: remove retired skills from old installs
    ├── check-mattpocock-updates.ps1
    ├── check-plugin-parity.ps1    # tool-capability matrix vs the plugin tree
    ├── run-skeleton-preflight.ps1 # 10-point write-mode gate
    ├── validate-markers.ps1       # Marker Specification CLI entry point
    ├── fake-p4.ps1                # test-only p4 shim (used by the test suites)
    ├── lib/                       # Markers, Render, InstallJournal, Classification, ...
    └── run-*-tests.ps1            # test suites — CI discovers and runs every one
```

## Status

**v4.28.0** — Audit hardening: catalog trimmed to 24 skills (5 personal skills removed; `design-workflow` merged into `design` + `PROCESS.md`); PS 5.1 crash class fixed across the lifecycle scripts (EAP/stderr, measured); provenance stamping; installer EOL policy; doc-audit ~20x faster with a version-staleness nudge; linkcheck now guards `plugins/`; 18 test suites incl. PS 5.1 gates. One breaking edge: `promote.ps1` requires an explicit `-Force` for divergent promotions (the refusal prints the remedy). Previously — **v4.0.0** — Role shift: the plugin owns the kit (29 skills incl. the process rules as on-demand skills, both review agents, commands, Codex audit bridge); the installer only bootstraps the committed core (bibles, docs, rules, scripts). Existing consumers converge via `upgrade.ps1 -Apply`. Previously — **v3.0.0** — Marketplace restructure: OpenCode support retired (tool scope is Claude Code + Codex); the per-tool template mirror collapsed into ONE shared source at `plugins/myst-dev-kit/` (skills/agents/commands/workflows live once; the manifest maps each file to both `.claude/` and `.Codex/` targets); overlays flattened the same way. Skills remain vendored **verbatim** from upstream `mattpocock/skills` HEAD (`6eeb81b`) — project specifics live in overlays, never in the base (see [ADR-0002](docs/adr-0002-vendor-and-overlay-not-fork.md), [ADR-0003](docs/adr-0003-verbatim-skill-format.md)). Full history in [CHANGELOG.md](CHANGELOG.md).

## What `runtime-mutable` means

Some files are package-templated but get rewritten by the tool at runtime. These files can't be hash-tracked the normal way without perpetually reporting drift.

The `hashPolicy: "runtime-mutable"` policy says:
- **Install seeds the file from the template on first run** (when the target is absent).
- **Subsequent installs never overwrite it** — the runtime mutations are preserved.
- **Preflight check 2 skips the hash check** — no false-positive drift.
- **Compare reports the entry with outcome `runtime-mutable`** (its own bucket, not `downstream-edit` or `clean`); does not count toward conflicts.
- **Promote refuses** to push runtime-mutated content upstream (the disk content is user-state, not package content).

Mark any tool-managed-at-runtime file with this policy in `manifest-template.json`. No entry currently uses it (the canonical case was OpenCode's `opencode.json`, retired with OpenCode support); the mechanism remains for any future file with the same property.

See [CHANGELOG.md](CHANGELOG.md) for the version history.

## License

MIT. Bundles content adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, pinned at commit `e9fcdf9`) — attribution preserved in [LICENSE](LICENSE).

## Contributing

Content enters the marketplace through a **per-skill contribution gate** — one skill per PR, promote.ps1 roundtrip, mechanical validation, review checklist. Full process: [CONTRIBUTING.md](CONTRIBUTING.md).
