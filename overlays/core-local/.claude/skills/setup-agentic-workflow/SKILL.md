---
name: setup-agentic-workflow
description: Interactively install or upgrade the myst-agentic-workflow scaffold in a project — detect the environment, propose tools + overlays, confirm with the user, dry-run, then write. Run once when first adding the toolset to a repo (or to add tools/overlays later).
disable-model-invocation: true
---

# Set up the agentic workflow toolset

A guided wizard that installs the scaffold (skills, workflows, agents, rules) into a project. It is a
**thin front-end over the package's scripts** (`setup.ps1` / `upgrade.ps1`) — it gathers choices
interactively, then lets those scripts do the dry-run-gated, journaled write. It does **not**
reimplement installation.

> **Run once per repo** when first adding the toolset, or again to add tools/overlays. This is a
> user-invoked skill — the agent never runs it on its own.

## Principles (how to interview)

- **Assume the user doesn't know the terms.** Briefly explain each choice before asking.
- **Ask one decision at a time**, in order. Present a smart default inferred from the repo; let the
  user accept or override. Don't dump every question at once.
- **Never write without a dry-run + explicit confirmation.** The scripts dry-run first anyway; surface
  that plan to the user.
- **Don't install things they don't need.** Default conservative: core + only the overlays the repo
  evidence supports. `myst-project` is a reference example — never propose it unless the user IS that project.

## Step 1 — Explore (read-only)

Determine, without changing anything:

- **Package location** (`$Pkg`): the `myst-agentic-workflow` clone (this skill ships from it). Ask if unknown.
- **Target project** (`$Target`): the repo to install into (default: the current workspace root).
- **Already installed?** Check for `Docs/agents/scaffold-manifest.json` in the target. If present →
  this is an **upgrade**, not a fresh install (see Step 5b).
- **Version control:** `.p4ignore` or a reachable `p4` client → **Perforce**; else `.git` → filesystem/git.
- **Unreal project:** any `*.uproject` (often under a subdir) → **UE**.
- **Tools already present:** existing `.claude/` / `.Codex/` / `.opencode/` directories.
- **Shape:** monorepo (multiple projects / docs roots) vs single project.

Report what you found in 3-5 lines before asking anything.

## Step 2 — Decide the tools

Explain: the scaffold installs per AI tool. Options: `claude` (Claude Code), `codex`, `opencode`.

Ask: **"Which tools do you use?"** Default = the tool dirs already present, else `claude`. Multiple allowed.

## Step 3 — Decide the overlays (one at a time)

Overlays add optional layers on top of the always-on core. Walk through each; propose the default from
Step 1 evidence:

1. **`core`** — always installed (the portable skills/workflows/agents). Not a choice.
2. **`core-local`** — always installed automatically (package-invented skills like `roundtable`). Not a choice.
3. **`perforce`** — *"Adds Perforce changelist/review/submit workflows."* Default **yes** if `.p4ignore`/p4
   client was found, else no.
4. **`ue`** — *"Adds the Unreal sync-build-submit command + a UE `.p4ignore` fragment."* Default **yes** if a
   `*.uproject` was found, else no.
5. **`myst-project`** — *"A project-specific reference example (Myst_Proto). Almost never what you want."*
   Default **no**. Only include if the user explicitly confirms they are that project.
6. **`afk-autonomy`** — *"Lets the agent autonomously `p4 submit` low-risk changelists while you're away.
   Powerful and risky: it is off by default and, even installed, only acts when you explicitly arm it
   each session. There is no hard enforcement — it's governance you opt into."* Default **no**. Only
   include if the user asks for autonomous runs (and understands the gating). Requires `perforce` (+ a
   reviewer agent; the `myst-project` overlay supplies one, or bring your own).

Confirm the final overlay set back to the user.

## Step 4 — Dry-run and explain

Build the flags from the answers and run the **dry-run** (no writes):

```powershell
& "$Pkg/setup.ps1" -TargetRoot "$Target" -Tools "<tools>" -Overlays "core,<chosen overlays>"
```

`setup.ps1` previews the plan and prompts before writing. Summarize the planned changes for the user
(files to add, overlays applied). If anything looks wrong, go back to Step 2/3.

## Step 5 — Write

On confirmation, run the same command with `-Yes` to apply (still dry-run-gated + journaled internally):

```powershell
& "$Pkg/setup.ps1" -TargetRoot "$Target" -Tools "<tools>" -Overlays "core,<chosen overlays>" -Yes
```

(`core-local` and `tool-capability` are force-added by the installer — you don't list them.)

### Step 5b — If already installed (upgrade)

Do **not** re-run `setup.ps1` over an existing install (it won't add new skills or remove retired ones).
Use the upgrade path, which preserves local customizations:

```powershell
& "$Pkg/upgrade.ps1" -TargetRoot "$Target"          # preview
& "$Pkg/upgrade.ps1" -TargetRoot "$Target" -Apply   # apply (Perforce: one reviewable changelist)
```

## Step 6 — Done: tell the user what's next

- **Configure the issue tracker / triage labels / domain docs:** run **`/setup-matt-pocock-skills`** —
  the engineering skills read the config it writes. This skill (`setup-agentic-workflow`) installs the
  toolset; `setup-matt-pocock-skills` wires up the project conventions.
- **If `ue` was installed:** open the `sync-build-submit` command and fill its `<DEPOT_ROOT>` /
  `<PROJECT_ROOT>` / `<GAME_DIR>` / `<UPROJECT>` / `<EDITOR_TARGET>` placeholders.
- **If `afk-autonomy` was installed:** it starts in dry-run + disarmed. Read `AFKAutoSubmit.md`, tune
  the gate path lists for your repo, and arm it only when you actually want autonomous runs.
- Skills live under each tool dir; read `CLAUDE.md` / `AGENTS.md` for the skill list and workspace rules.

## Notes

- This skill orchestrates and emits the install command; the scripts own the safety (dry-run, preflight,
  journal, Perforce changelist wrapping). Don't hand-edit files the installer manages.
- Cross-platform: `setup.ps1` is PowerShell (Windows-first). On Mac/Linux ensure `pwsh` is available.
