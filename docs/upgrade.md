# Upgrade guide — moving an existing consumer to the current package

For a project that installed an **older** version of the scaffold and wants the current skill
set **without losing local customizations**. A **fresh** install needs none of this — just run
`setup.ps1` (auto-detects Perforce via `.p4ignore` and Unreal via `*.uproject`).

## One command: `upgrade.ps1`

```powershell
$Pkg    = "c:/path/to/myst-agentic-workflow"   # the package clone
$Target = "c:/path/to/your-ue-project"          # your consumer repo

git -C $Pkg pull                                # get the current package

# 1. Preview (read-only — prints the plan, changes nothing)
& "$Pkg/upgrade.ps1" -TargetRoot $Target

# 2. Apply. Perforce consumers: everything lands in ONE changelist you review before submit.
& "$Pkg/upgrade.ps1" -TargetRoot $Target -Apply
```

That's it. For a Perforce consumer it ends with a changelist number — review the diff, then
`p4 submit -c <CL>` (or `p4 revert -c <CL> //...` to abort). Filesystem consumers review the
working tree and commit.

## What it does (and why the built-ins can't)

`setup.ps1` skips manifest bootstrap when one exists, and `update.ps1` never regenerates the
manifest — both drive `install.ps1` from the **stale** installed manifest, so new skills are
never added and retired skills get re-created. `install.ps1 -Mode Write` is also gated by
preflight check 2 (on-disk hash must equal manifest hash), which any local edit trips.

`upgrade.ps1` handles all of it:

| Bucket | Action |
|---|---|
| **ADD** | New skills/files in the current package (e.g. `diagnosing-bugs`, `codebase-design`, `domain-modeling`, `grilling`, `writing-for-agents`, `implement`, `resolving-merge-conflicts`, `research`, `review-changes`, plus companions) are installed. |
| **REFRESH** | Files you did **not** modify are updated to the current package version (e.g. the verbatim-frontmatter format change to carried skills). |
| **PRESERVE** | Files you **customized** (on-disk differs from the install baseline) are left untouched, and marked `manual-only`/`human-owned` so they're never auto-overwritten. The plan lists each. |
| **BLOCK-REFRESH** | `AGENTS.md` / `CLAUDE.md` / `.p4ignore` managed blocks are refreshed in place; your content outside the markers is preserved. |
| **REMOVE** | Retired skills (`zoom-out`, `caveman`, `write-a-skill`, `diagnose`→`diagnosing-bugs`) and old command wrappers are deleted (P4: opened-for-delete in the changelist). |

It works by regenerating the manifest from the current template (into a temp dir for the
preview, so a preview never touches your project), re-baselining every existing managed file's
hash to its on-disk content (so preflight passes), and detecting customizations against the old
install baseline. Tools, overlays, Perforce-vs-filesystem, project name, and docs roots are all
read from your installed manifest — you don't re-specify them.

## After upgrading

- Confirm with `& "$Pkg/scripts/compare-with-package.ps1" -TargetRoot $Target`.
- The plan's **PRESERVE** list shows files where the package may have small improvements you
  chose to skip — diff them against the package source if you want to hand-pick any.
- **Lower-level alternative:** `scripts/migrate-retired-skills.ps1` only removes retired skills
  (Perforce-aware), if you want to stage that step separately.
- **One-shot, once the `enabledPlugins` removal (v4.50.1) has reached you:**
  `scripts/migrate-project-scope-installs.ps1` removes duplicate PROJECT-scope records from
  `~/.claude/plugins/installed_plugins.json`, so one plugin id has one install record. Without
  it, which payload loads is decided by install order and nothing reports the winner. You do not
  need to know when you installed: run it dry (the default) and it reports clean if your machine
  has none. `-Apply` acts and writes a backup first.
  **Order matters:** run it only AFTER the `enabledPlugins` removal has synced to your
  workspace. Converging while those entries are still committed lets the next session recreate
  the very records you just removed - measured, not theoretical.

## Notes

- Nothing is permanent for a Perforce consumer until you `p4 submit` the changelist.
- Re-running `upgrade.ps1` is safe/idempotent: a clean consumer reports an empty plan.
