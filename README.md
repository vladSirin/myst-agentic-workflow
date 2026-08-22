# myst-agentic-workflow

**One dev kit for [Claude Code](https://github.com/anthropics/claude-code), [Codex](https://github.com/openai/codex), and [OpenCode](https://opencode.ai) — installed in 30 seconds, updated with one command.**

The skills, workflows, and conventions you'd hand-copy between projects, packaged as a single source of truth with a crash-safe installer, drift detection, and a promotion path. Every skill and agent lives ONCE; each tool consumes the same files through its native mechanism.

[![tests](https://img.shields.io/badge/tests-21%20suites%20passing-brightgreen)](#) [![version](https://img.shields.io/badge/version-v4.45.0-blue)](https://github.com/vladSirin/myst-agentic-workflow/releases) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## TL;DR

- **What it is** — one dev kit (31 skills, 2 reviewer agents, 3 commands) shared by Claude Code, Codex and OpenCode. Every skill lives once; each tool reads the same files through its own mechanism.
- **Install** — `git clone` + run `setup-devkit.ps1`. Re-run the same command to update. [Jump to Install](#install-30-second-setup).
- **The 13 skills you actually type** — `/to-spec`, `/to-tickets`, `/triage`, `/wayfinder`, `/implement`, `/grill-me`, `/handoff`, and friends. [Jump to the catalog](#skills-you-invoke).
- **The other 18 fire on their own** when the task fits, so it is worth [skimming what they are](#skills-the-agent-reaches-for) before you install.
- **Adopting it in your own project?** The consumer scaffold (bibles, rules, hook scripts) installs separately — see [Adopting the scaffold](#install-30-second-setup) and [SETUP.md](SETUP.md).

## Contents

- [Install](#install-30-second-setup) · [What you get](#what-you-get) · [Per-tool notes](#per-tool-notes-measured-not-inferred)
- [Why this package exists](#why-this-package-exists) — the six problems it solves
- **Reference** — [lifecycle commands](#lifecycle-commands-top-level) · [**skills you invoke**](#skills-you-invoke) · [skills the agent reaches for](#skills-the-agent-reaches-for) · [divergence from upstream](#divergence-from-upstream-and-why) · [agents](#agents) · [overlays](#overlays)
- [FAQ](#faq) · [Gotchas](#gotchas-known-limitations) · [Layout](#layout) · [Status](#status) · [License](#license) · [Contributing](#contributing)


## Install (30-second setup)

One command covers every tool on your machine — it detects which CLIs you have and drives each tool's native plugin manager (it never replaces them):

```powershell
git clone https://github.com/vladSirin/myst-agentic-workflow "$env:USERPROFILE\.myst-agentic-workflow"
& "$env:USERPROFILE\.myst-agentic-workflow\setup-devkit.ps1"
```

**Updating is the same command** — re-run it any time. It prints the version delta and self-verifies delivery. New versions are announced on the [Releases page](https://github.com/vladSirin/myst-agentic-workflow/releases).

> **Myst team member?** [SETUP.md](SETUP.md) is your page — committed core via `p4 sync`, this one command for the kit, per-tool notes and known gaps.

<details>
<summary><strong>What the script does per tool</strong></summary>

| Tool | Install / update actions |
|---|---|
| Claude Code | `claude plugin marketplace update myst`, then install-if-missing / `claude plugin update myst-dev-kit@myst` (restart to load) |
| Codex | `codex plugin marketplace add` + `upgrade` + `plugin add`, then generates the two reviewer agents as `~/.codex/agents/*.toml` (`sandbox_mode = "read-only"`) |
| OpenCode | checks the clone out at the latest release tag, registers skills via `skills.paths` in `~/.config/opencode/opencode.json`, writes the unreal-engine MCP entry + the manual-skill ask-map, generates the two reviewer agents, self-verifies |

`-Tool claude|codex|opencode` scopes it; `-Version vX.Y.Z` pins or rolls back; `-Uninstall` removes what it added. One failing tool never aborts the others.

</details>

<details>
<summary><strong>Native per-tool paths (no script needed)</strong></summary>

```bash
# Claude Code — install, then the two-step update (restart after):
/plugin install myst-dev-kit@myst            # marketplace pre-registered in Myst projects; else: /plugin marketplace add vladSirin/myst-agentic-workflow
claude plugin marketplace update myst
claude plugin update myst-dev-kit@myst

# Codex — install once; refreshing the marketplace IS the update (no second command):
codex plugin marketplace add vladSirin/myst-agentic-workflow
codex plugin add myst-dev-kit@myst
codex plugin marketplace upgrade
```

- **Claude**: a marketplace refresh alone does **not** move an installed plugin; it stays pinned until the explicit `plugin update`, and the new version loads on the next session.
- **Codex**: `marketplace upgrade` replaces the installed plugin in place, cache directory and all. There is no `codex plugin update` subcommand.
- **OpenCode** has no native path — `setup-devkit.ps1` IS its path (schema-validated `skills.paths` pointing at the clone; the tag checkout is the update).
- Verify with `claude plugin list` / `codex plugin list` / `opencode debug skill`. Note Codex's VERSION column reports the *marketplace snapshot*; to confirm what is actually installed, look under `~/.codex/plugins/cache/<marketplace>/<plugin>/<version>/`.
- Inside a Claude Code session without the `/plugin` command (e.g. some IDE extensions), the same commands work from a terminal — `claude plugin …` is a plain CLI subcommand.

</details>

<details>
<summary><strong>Adopting the scaffold in a new project (consumer install)</strong></summary>

The committed core (bible generated-blocks, team docs, rules, hook scripts, `.p4ignore` fragment) installs into a project with one command — auto-detects Perforce/git/filesystem and UE-vs-not:

```powershell
& "$env:USERPROFILE\.myst-agentic-workflow\setup.ps1" -TargetRoot c:/path/to/your-project [-Yes]
```

Four lifecycle commands cover the entire flow — all four dry-run first, prompt before writing, and auto-derive their configuration from your installed manifest:

```powershell
& "$Pkg/setup.ps1"   -TargetRoot $Target  [-Yes]                        # first-time install
& "$Pkg/update.ps1"  -TargetRoot $Target  [-Yes] [-NoPull]              # sync upstream changes in
& "$Pkg/upgrade.ps1" -TargetRoot $Target  [-Apply]                      # major version jump (preserves customizations)
& "$Pkg/promote.ps1" -TargetRoot $Target -Paths '<file>'                # push local improvements out
```

</details>

## What you get

**`myst-dev-kit`** — 31 skills (engineering + productivity + the team process rules as on-demand skills), the two reviewer agents (native Markdown under Claude; **generated** read-only variants for Codex TOML and OpenCode — the shared source is never forked), `sync-build-submit` and package commands, and the Codex-side Submit-Audit warning bridge. Full catalog with when-to-use guidance: [Reference](#reference).

The repo is a **plugin marketplace** for Claude Code and Codex (`.claude-plugin/marketplace.json` / `.agents/plugins/marketplace.json`, consistency enforced by `scripts/run-marketplace-tests.ps1` + `claude plugin validate`) and a **`skills.paths` source** for OpenCode. Public repo — installs need no auth (if it goes private later: collaborator access + `gh auth login`).

## Per-tool notes (measured, not inferred)

**Two Codex limits worth knowing before you design around them:**

- **No auto-loaded rules directory.** Codex reads `AGENTS.md` and nothing else, so an always-on `.claude/rules/*.md` reaches Claude and never reaches Codex. `check-rule-parity.sh` guards that gap.
- **No project-level hooks.** Codex loads hooks from `~/.codex/hooks.json` and from installed plugins only; a hooks file committed in the repo is ignored. A repo-local hook is Claude-only unless it ships through the plugin.

Notes:
- The plugin's `hooks/hooks.json` delivers the client Submit-Audit warning **to Codex only** — under Claude Code the bridge no-ops because the consumer project's committed `.claude/settings.json` already registers the same audit (no double warnings). On consumers without the Myst governance core, the hook exits silently. **Verified firing under Codex 2026-08-06** (`docs/tool-capability-matrix.md`); it had never run on any host before v4.26.0.
- `agents/` is loaded natively by Claude only. Codex and OpenCode get the same two reviewers as **generated** read-only variants written by `setup-devkit.ps1` (Codex: `~/.codex/agents/*.toml` with `sandbox_mode = "read-only"`; OpenCode: `~/.config/opencode/agents/myst/*.md` with `permission: edit deny`) — fixed known-good headers, body verbatim from the shared source, regenerated on every script run. The shared `.md` files are never hand-forked, and OpenCode's agents directory never loads them directly (their Claude frontmatter fails its parser). One measured exception to keep straight: OpenCode's Claude-plugin compat path DOES surface the installed plugin's copies as `myst-dev-kit:<name>` subagents, resolving **writable** (`edit: true`) — so `setup-devkit.ps1` ships those twins disabled in your config; spawn the generated `myst/<name>` variants instead (same note in [SETUP.md](SETUP.md)).
- Former always-on workflows are now **on-demand skills** with trigger-strength descriptions (`review-and-submit`, `changelist-verification`, `pre-implementation-gate`, ...) — advisory by design; the server-side Submit-Audit is the enforcement backstop.

**Upgrading an older scaffold install?** Run [`upgrade.ps1`](upgrade.ps1) (preview, then `-Apply`) — it adds new skills, refreshes untouched files, **preserves your customizations**, removes retired skills, and (for Perforce) wraps it all in one reviewable changelist. `setup.ps1`/`update.ps1` can't do this jump (they drive install from the stale manifest). See [`docs/upgrade.md`](docs/upgrade.md).

## Provenance

Extracted from `Myst_Proto`, a UE5/Perforce game project, and offered as a starting point for anyone else. MIT-licensed, generic core, honest about origin. The `myst-` prefix says where it came from, not who it's for.

The `overlays/myst-project/` directory ships the original project-specific content **as a reference example, not generic content** — see [`overlays/myst-project/README.md`](overlays/myst-project/README.md). `setup.ps1` never auto-installs it.

## Why this package exists

Pain points solved, with the skills / scripts that solve them.

### #1: Agentic CLIs that drift apart

Claude Code, Codex, and OpenCode each have their own config dirs (`.claude/`, `.Codex/`, `.opencode/`). When you tweak a workflow file in one, the others fall behind. Multiply by every project you work on and the drift becomes structural.

**The fix:** every skill, workflow, and agent lives **once**, in `plugins/myst-dev-kit/`. Claude and Codex load it as a plugin; OpenCode reads it in place via `skills.paths`; the per-tool reviewer-agent variants are generated from it, never forked. Edit the shared source; `update.ps1` propagates the change to every consumer's per-tool directories. Edit a per-tool file in a consumer; `promote.ps1` round-trips it back to the shared source (reverse-substituting `{{var}}` placeholders) so every tool stays in lockstep by construction.

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

**31 skills**, split by the thing that matters most when you are picking one: **who starts it.**

A **user-invoked** skill runs only when you type it (`/to-spec`). These orchestrate, and they are
the entry points worth remembering — there are 13 of them. A **model-invoked** skill can be typed
*or* reached for by the agent on its own when the task fits; these hold reusable discipline that
should apply without being asked. A user-invoked skill may call model-invoked ones, never another
user-invoked one.

Worth knowing before you install: a model-invoked skill can fire on work you did not explicitly
ask about — `writing-for-agents` triggers on edits to `CLAUDE.md` or `AGENTS.md`. Claude and Codex
gate this with the `disable-model-invocation` frontmatter key; **OpenCode ignores that key**, so
`setup-devkit.ps1` restores the same gate as a `permission.skill` ask-map (its `$ManualSkills`
list is exactly the user-invoked set below, asserted by `scripts/run-catalog-tests.ps1`).

Provenance: the engineering/productivity set is vendored **verbatim** from
[mattpocock/skills](https://github.com/mattpocock/skills) (MIT, attribution in [LICENSE](LICENSE);
pinned commit in `package-manifest.json`); the rest is local-origin.

#### Skills you invoke

The 13 entry points worth remembering.

**Plan the work**

| Skill | Use it when |
|---|---|
| [`/to-spec`](plugins/myst-dev-kit/skills/to-spec/SKILL.md) | Turn the current conversation into a spec on the issue tracker (specs start `needs-triage`). |
| [`/to-tickets`](plugins/myst-dev-kit/skills/to-tickets/SKILL.md) | Break a spec/plan into independently-grabbable vertical-slice tickets. |
| [`/triage`](plugins/myst-dev-kit/skills/triage/SKILL.md) | Move tickets through the lifecycle state machine. |
| [`/wayfinder`](plugins/myst-dev-kit/skills/wayfinder/SKILL.md) | Plan an effort too big for one agent session as a shared map of decision tickets, resolved one at a time. |

**Do the work**

| Skill | Use it when |
|---|---|
| [`/implement`](plugins/myst-dev-kit/skills/implement/SKILL.md) | Implement a planned slice from a spec/ticket. |
| [`/improve-codebase-architecture`](plugins/myst-dev-kit/skills/improve-codebase-architecture/SKILL.md) | Scan a codebase for deepening opportunities, presented as a visual HTML report, then grill through the one you pick. |

**Pressure-test your thinking**

| Skill | Use it when |
|---|---|
| [`/grill-with-docs`](plugins/myst-dev-kit/skills/grill-with-docs/SKILL.md) | Stress-test a plan against the project's domain language before a non-trivial change; writes ADRs + glossary as it goes. |
| [`/grill-me`](plugins/myst-dev-kit/skills/grill-me/SKILL.md) | The user-invoked half of the grilling pair -- ask to be grilled on your own plan. |
| [`/to-questionnaire`](plugins/myst-dev-kit/skills/to-questionnaire/SKILL.md) | Turn a decision you can't answer into a questionnaire for whoever can. |

**Hand off and explain**

| Skill | Use it when |
|---|---|
| [`/handoff`](plugins/myst-dev-kit/skills/handoff/SKILL.md) | Compact the session into a handoff doc for another agent. |
| [`/wait-what`](plugins/myst-dev-kit/skills/wait-what/SKILL.md) | Re-pitch a message that didn't land. |
| [`/teach`](plugins/myst-dev-kit/skills/teach/SKILL.md) | Learn a new concept or skill in-workspace, with lessons and a learning record. |

**Set up the kit**

| Skill | Use it when |
|---|---|
| [`/setup-agentic-workflow`](plugins/myst-dev-kit/skills/setup-agentic-workflow/SKILL.md) | Interactive wizard to install/upgrade the scaffold in a project -- detects the environment, proposes tools + overlays, asks one question at a time, dry-runs, then writes (front-end over `setup.ps1`/`upgrade.ps1`). |

#### Skills the agent reaches for

The other 18.

Typeable too, but you should not have to. Listed so you know what can fire on its own.

**Engineering**

| Skill | Use it when |
|---|---|
| [`/diagnosing-bugs`](plugins/myst-dev-kit/skills/diagnosing-bugs/SKILL.md) | A hard bug / perf regression: build a feedback loop, reproduce + minimise, hypothesise, instrument, fix + regression-test. |
| [`/tdd`](plugins/myst-dev-kit/skills/tdd/SKILL.md) | Build a feature / fix a bug with red-green-refactor, one vertical slice at a time. |
| [`/codebase-design`](plugins/myst-dev-kit/skills/codebase-design/SKILL.md) | Shared vocabulary for designing deep modules and seams. |
| [`/domain-modeling`](plugins/myst-dev-kit/skills/domain-modeling/SKILL.md) | Actively build/sharpen the domain model -- challenge terms, write the glossary + ADRs inline. |
| [`/research`](plugins/myst-dev-kit/skills/research/SKILL.md) | Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo -- reading legwork you can delegate. |
| [`/resolving-merge-conflicts`](plugins/myst-dev-kit/skills/resolving-merge-conflicts/SKILL.md) | Resolve merge conflicts (Perforce specifics live project-side in `Docs/agents/perforce-notes.md`). |
| [`/prototype`](plugins/myst-dev-kit/skills/prototype/SKILL.md) | Build a throwaway prototype to answer a design or state-model question before committing to it. |
| [`/wizard`](plugins/myst-dev-kit/skills/wizard/SKILL.md) | Generate an interactive wizard for steps only a human can perform (credentials, dashboards, cutovers). |

**Productivity**

| Skill | Use it when |
|---|---|
| [`/grilling`](plugins/myst-dev-kit/skills/grilling/SKILL.md) | Relentless plan/design interview until shared understanding (`grill-with-docs` delegates here). |
| [`/writing-for-agents`](plugins/myst-dev-kit/skills/writing-for-agents/SKILL.md) | Write docs agents actually follow -- skills, `AGENTS.md`, `CLAUDE.md`. |

**Team process (the governance rules, on demand)**

| Skill | Use it when |
|---|---|
| [`/agentic-workflow`](plugins/myst-dev-kit/skills/agentic-workflow/SKILL.md) | Which stage of the delivery process applies -- discussion, spec, tickets, triage, build, verify, submit. |
| [`/pre-implementation-gate`](plugins/myst-dev-kit/skills/pre-implementation-gate/SKILL.md) | About to propose a multi-CL plan: checks a spec, tickets and triage exist first. |
| [`/changelist-verification`](plugins/myst-dev-kit/skills/changelist-verification/SKILL.md) | More than one changelist is in play: execute them one at a time with a verify gate between. |
| [`/review-and-submit`](plugins/myst-dev-kit/skills/review-and-submit/SKILL.md) | The full pre-submit protocol -- organize the CL, route reviewers, record the verdict, gate the submit. |
| [`/auto-plan-mode`](plugins/myst-dev-kit/skills/auto-plan-mode/SKILL.md) | Deciding whether the request in front of you needs a plan before the first edit. |

**Local-origin (no upstream counterpart)**

| Skill | Use it when |
|---|---|
| [`/design`](plugins/myst-dev-kit/skills/design/SKILL.md) | Create a design document with reviewer-agent feedback and iterate to approval; the team's doc-process rules (naming, lifecycle, BLOCKING/WARNING/INFO) live in the companion [PROCESS.md](plugins/myst-dev-kit/skills/design/PROCESS.md). |
| [`/review-changes`](plugins/myst-dev-kit/skills/review-changes/SKILL.md) | Pre-submit review of a CL/diff INLINE: the `review-and-submit` fast path (small CLs), and any session without reviewer subagents (e.g. Codex); same rubrics, same parseable `Verdict:` line. |
| [`/roundtable`](plugins/myst-dev-kit/skills/roundtable/SKILL.md) | Multi-perspective design discussion when one viewpoint isn't enough. |

Plus the plugin **commands** (not skills), all maintainer/build-machine-facing: `/update-project-scaffold` (re-render the committed project scaffold from upstream; formerly `/update-myst-skills`), `/promote-myst-skills` (push a local improvement out), and `/sync-build-submit` (UE build-machine pipeline).

### Divergence from upstream (and why)

We track upstream **faithfully** — name + body + architecture + verbatim frontmatter — and deviate only with a documented reason (see [ADR-0002](docs/adr-0002-vendor-and-overlay-not-fork.md), [ADR-0003](docs/adr-0003-verbatim-skill-format.md), and `.scratch/agentic-scaffold-rejected-upstream.json`):

- **Project specifics live project-side, never in a vendored skill.** As of v4.43.0 the kit carries no stack-specific text in upstream-derived skills: the UE and Perforce notes that used to ride `diagnosing-bugs` and `resolving-merge-conflicts` are removed from the kit. Their content is preserved in git history and is being relocated into the consumer's own `Docs/agents/` (see the v4.43.0 divergence ledger, section 6) -- a re-vendor can never touch it there, and a non-UE consumer never sees it.
- **Renamed (followed upstream):** `diagnose` → `diagnosing-bugs`; `writing-great-skills` → `writing-for-agents`. **Removed (followed upstream):** `zoom-out`, `caveman`, `write-a-skill`.
- **Skipped:** `ask-matt` (personal/branded router over upstream's own catalog — it would misroute here), `setup-matt-pocock-skills` (our `setup-agentic-workflow` covers the role), `code-review` (git-diff-shaped; our review unit is the P4 changelist, and the name collides with the built-in `/code-review`), `agents/openai.yaml` per-skill metadata (upstream's own packaging channel; our Codex delivery reads `.codex-plugin/plugin.json`).
- **The only content divergences** are 7 lines across 6 skills, all of the same kind: an upstream reference to a skill we do not vendor, remapped to our equivalent. They are listed in the v4.43.0 divergence ledger and guarded by a grep in the release checklist.
- Everything else is byte-faithful to upstream `0ab1b63`.

### Process-rule skills — what each one enforces

The five team-process skills are listed in the catalog above; this is the other lens on them: what fires them and what they hold you to. Converted from always-on workflows to on-demand skills in v4.0.0 — each carries a trigger-strength description so the agent loads it at the right moment; all are advisory (the server Submit-Audit is the backstop).

| Skill | Fires when | What it enforces |
|---|---|---|
| [`agentic-workflow`](plugins/myst-dev-kit/skills/agentic-workflow/SKILL.md) | non-trivial feature work starts | Discussion → spec → tickets → triage → impl → verify → review/submit. |
| [`pre-implementation-gate`](plugins/myst-dev-kit/skills/pre-implementation-gate/SKILL.md) | before drafting a multi-CL plan | **HARD RULE**: spec/tickets/triage must exist first. |
| [`changelist-verification`](plugins/myst-dev-kit/skills/changelist-verification/SKILL.md) | any multi-CL task | **HARD RULE**: CL-by-CL execution, never batched. Stop between CLs for verification. |
| [`review-and-submit`](plugins/myst-dev-kit/skills/review-and-submit/SKILL.md) | "review and submit" / any p4 submit | Pre-submit protocol: reviewer routing, Review Record block, preflight validators. |
| [`auto-plan-mode`](plugins/myst-dev-kit/skills/auto-plan-mode/SKILL.md) | start of non-trivial implementation | Decide whether to enter plan mode before coding. |

(The former `design-workflow` skill merged into [`design`](plugins/myst-dev-kit/skills/design/SKILL.md) in v4.28.0 -- the doc naming/location/reviewer-routing rules now live in that skill's [PROCESS.md](plugins/myst-dev-kit/skills/design/PROCESS.md).)

### Agents

Specialized subagents. Native Markdown under Claude Code; under Codex and OpenCode, `setup-devkit.ps1` generates read-only variants from the same source (see the Notes above), so all three tools can spawn them.

| Agent | Triggers on |
|---|---|
| `architecture-reviewer` | Post-implementation review. Judges against a four-source canon — Code Complete, The Art of Readable Code, and (for game/engine projects) Game Programming Patterns + Game Engine Architecture — plus the conventions it discovers in your repo. Stack-agnostic: it reads your `CLAUDE.md`/`AGENTS.md` and the code around the change instead of assuming an engine. |
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

**Do I need every tool (Claude Code / Codex / OpenCode)?**
No. For the per-user kit, `setup-devkit.ps1` only touches the tools it finds on PATH (or scope it with `-Tool`). For the project scaffold, pass `-Tools` to select a subset, e.g. `setup.ps1 -TargetRoot ... -Tools claude` — the other tool directory simply isn't written; add tools later by re-running with a broader `-Tools` flag and `-Force`. OpenCode is deliberately NOT a scaffold render target (no `-Tools opencode` exists) — it reaches the kit through `setup-devkit.ps1`'s config pointer instead.

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
├── SETUP.md                       # Myst team onboarding (all three tools)
├── LICENSE
├── package-manifest.json          # schema v3 + package metadata
├── manifest-template.json         # canonical entry list for new consumers
├── setup-devkit.ps1               # per-user kit install/update for claude+codex+opencode
├── setup.ps1                      # first-time consumer-project install
├── update.ps1                     # sync upstream changes in
├── upgrade.ps1                    # major-version jump (preserves customizations)
├── promote.ps1                    # push local improvements out
├── .github/workflows/tests.yml    # CI: every scripts/run-*-tests.ps1 suite, each PR/push
├── .github/workflows/release.yml  # tag push v* -> GitHub Release from the CHANGELOG section
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
│   ├── adr-0004-local-origin-provenance-and-core-local.md
│   └── adr-0005-opencode-pointer-consumer.md
├── plugins/myst-dev-kit/
│   ├── .claude-plugin/plugin.json # dual plugin manifests (one per tool)
│   ├── .codex-plugin/plugin.json
│   ├── agents/                    # architecture-reviewer + radical-design-critic (shared source; generated variants for codex/opencode)
│   ├── commands/                  # promote-myst-skills, sync-build-submit, update-project-scaffold
│   ├── hooks/hooks.json           # Codex Submit-Audit warn bridge (no-ops under Claude Code)
│   ├── scripts/                   # consumer hook scripts (doc-audit, rule parity, ...)
│   └── skills/                    # the 31 skills (ONE shared source for every tool)
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

**v4.41.0** — OpenCode joins Claude Code + Codex as a supported tool, as a **pointer consumer**: `setup-devkit.ps1` (one command, all tools, install = update) registers the 24 skills via OpenCode's schema-validated `skills.paths` against a dedicated clone — nothing rendered, nothing copied, the tag checkout is the update. The two reviewer agents now reach Codex and OpenCode as script-generated read-only variants (TOML / opencode-native `.md`) from the unchanged shared source. Releases auto-publish from tags. The maintainer command `/update-myst-skills` is now `/update-project-scaffold` (what it always did). This deliberately revives NOTHING of the v3.0.0-retired render-target model — see [ADR-0005](docs/adr-0005-opencode-pointer-consumer.md). Previously — **v4.28.0** — Audit hardening: catalog trimmed to 24 skills (5 personal skills removed; `design-workflow` merged into `design` + `PROCESS.md`); PS 5.1 crash class fixed across the lifecycle scripts (EAP/stderr, measured); provenance stamping; installer EOL policy; doc-audit ~20x faster with a version-staleness nudge; linkcheck now guards `plugins/`; 18 test suites incl. PS 5.1 gates. One breaking edge: `promote.ps1` requires an explicit `-Force` for divergent promotions (the refusal prints the remedy). Previously — **v4.0.0** — Role shift: the plugin owns the kit (29 skills incl. the process rules as on-demand skills, both review agents, commands, Codex audit bridge); the installer only bootstraps the committed core (bibles, docs, rules, scripts). Existing consumers converge via `upgrade.ps1 -Apply`. Previously — **v3.0.0** — Marketplace restructure: OpenCode support retired (tool scope is Claude Code + Codex); the per-tool template mirror collapsed into ONE shared source at `plugins/myst-dev-kit/` (skills/agents/commands/workflows live once; the manifest maps each file to both `.claude/` and `.Codex/` targets); overlays flattened the same way. Skills remain vendored **verbatim** from upstream `mattpocock/skills` HEAD (`6eeb81b`) — project specifics live in overlays, never in the base (see [ADR-0002](docs/adr-0002-vendor-and-overlay-not-fork.md), [ADR-0003](docs/adr-0003-verbatim-skill-format.md)). Full history in [CHANGELOG.md](CHANGELOG.md).

## What `runtime-mutable` means

Some files are package-templated but get rewritten by the tool at runtime. These files can't be hash-tracked the normal way without perpetually reporting drift.

The `hashPolicy: "runtime-mutable"` policy says:
- **Install seeds the file from the template on first run** (when the target is absent).
- **Subsequent installs never overwrite it** — the runtime mutations are preserved.
- **Preflight check 2 skips the hash check** — no false-positive drift.
- **Compare reports the entry with outcome `runtime-mutable`** (its own bucket, not `downstream-edit` or `clean`); does not count toward conflicts.
- **Promote refuses** to push runtime-mutated content upstream (the disk content is user-state, not package content).

Mark any tool-managed-at-runtime file with this policy in `manifest-template.json`. No entry currently uses it (the canonical case was OpenCode's `opencode.json`, retired with the v3.0.0 render-target model; today's OpenCode support is a config pointer written by `setup-devkit.ps1` into the USER's global config — nothing manifest-tracked, so the policy stays unused); the mechanism remains for any future file with the same property.

See [CHANGELOG.md](CHANGELOG.md) for the version history.

## License

MIT. Bundles content adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, pinned at commit `0ab1b63`) — attribution preserved in [LICENSE](LICENSE).

## Contributing

Content enters the marketplace through a **per-skill contribution gate** — one skill per PR, promote.ps1 roundtrip, mechanical validation, review checklist. Full process: [CONTRIBUTING.md](CONTRIBUTING.md).
