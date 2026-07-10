# /update-myst-skills — Sync upstream package changes into this project

Pull the latest [`myst-agentic-workflow`](https://github.com/vladSirin/myst-agentic-workflow)
package changes and apply them to this project.

## What you do

1. **Find the package root**. Read `Docs/agents/scaffold-manifest.json` in the
   project; the `package.source` field has the GitHub URL. Look for an existing
   local clone of that repo (commonly under `c:/_LocalDev/` or
   `~/code/`). If none found, ask the user where their clone is.

2. **Run `update.ps1`** from the package root, targeted at this project:

   ```powershell
   $Pkg    = '<package-root>'
   $Target = '<this-project-root>'
   & "$Pkg/update.ps1" -TargetRoot $Target
   ```

   The script:
   - `git pull`s the package clone
   - runs `compare-with-package` (aborts on conflicts)
   - dry-runs the install
   - prompts the user before writing
   - auto-wraps in `-UsePerforce -Changelist new` if the consumer manifest
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
