---
description: Sync the latest myst-agentic-workflow package changes into this project (update.ps1)
---

# /update-myst-skills — Sync upstream package changes into this project

Pull the latest [`myst-agentic-workflow`](https://github.com/vladSirin/myst-agentic-workflow)
package changes and apply them to this project.

## What you do

1. **Find the package root**. Claude Code auto-maintains a full git clone of the
   package as the marketplace directory:
   `~/.claude/plugins/marketplaces/myst` — prefer it (creating a second clone
   elsewhere invites divergence). If it is absent (e.g. Codex-only machine),
   read `Docs/agents/scaffold-manifest.json`; the `package.source` field has the
   GitHub URL — then ask the user where their clone is rather than guessing
   paths.

2. **Pick the right script — this decides whether new files can arrive.**
   `update.ps1` refreshes files already tracked by the INSTALLED manifest; it
   structurally cannot ADD files a newer package introduced or REMOVE retired
   ones. `upgrade.ps1` regenerates the manifest from the new template and can.
   Decide by version jump: compare the consumer manifest's `package.version`
   against the package clone's `package-manifest.json` version.
   - Same MAJOR.MINOR (patch drift only) → `update.ps1` is enough.
   - MINOR or MAJOR jump (the CHANGELOG's contract: those may add/retire files)
     → run `upgrade.ps1` instead, then follow its plan output.

   ```powershell
   $Pkg    = '<package-root>'
   $Target = '<this-project-root>'
   & "$Pkg/update.ps1" -TargetRoot $Target      # patch-level refresh
   # -- or, on a version jump: --
   & "$Pkg/upgrade.ps1" -TargetRoot $Target     # adds new / retires old files
   ```

   ```powershell
   $Pkg    = '<package-root>'
   $Target = '<this-project-root>'
   & "$Pkg/update.ps1" -TargetRoot $Target
   ```

   Both scripts:
   - `git pull` the package clone (update.ps1; upgrade.ps1 expects a fresh clone)
   - preview the plan / dry-run before writing
   - prompt the user before writing
   - auto-wrap in `-UsePerforce -Changelist new` when the consumer manifest
     declares `versionControl='perforce'`

3. **Surface the dry-run output** to the user. Let them see what would change
   before they answer the prompt.

4. **After the write** (if the user accepted):
   - If Perforce: tell them the CL number that was opened, suggest they
     review it (`p4 opened -c <CL>`) and submit when ready.
   - If git/filesystem: suggest they `git diff` and commit.

## When to suggest this command

- The user says "update the scaffold" / "pull the latest workflow updates" /
  "sync from upstream".
- The user mentions they want the latest skills or workflows.
- You see the package is older than HEAD (e.g., they reference a feature
  from a newer version that isn't in their local skills).

## What NOT to do

- Don't run `git pull` in the package clone manually — `update.ps1` does it.
- Don't run `install.ps1 -Mode Write` directly — go through `update.ps1` so
  the preflight gate and Perforce CL wrapping happen automatically.
- Don't skip the dry-run. The user needs to see what changes before they
  approve.

## If `update.ps1` fails

Read the error. Common cases:
- **Preflight check 10** (default-change clean) — the user has unrelated
  files in P4 default changelist. Tell them to move those to a named CL
  or revert before retrying.
- **Conflict outcome from compare** — both sides moved. Show the conflict
  list; this needs manual reconciliation, not an automated update.

## Related

- `/promote-myst-skills` — push local improvements back to the package.
- `docs/install.md` §3 in the package — full update workflow documentation.
