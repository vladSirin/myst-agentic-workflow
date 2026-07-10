# /promote-myst-skills — Push a local improvement back to the upstream package

When the user has improved a workflow / skill / template file locally and
the change should benefit any other project that adopts the package, run
this flow to round-trip it upstream.

## What you do

1. **Identify the files to promote**. Ask the user which files, or:
   - For Perforce: run `p4 opened` to see currently-open files.
   - For git: run `git status` for unstaged + staged changes.
   - For filesystem: ask the user explicitly.

   Filter to only files that exist in the consumer's scaffold-manifest
   (paths under `.claude/`, `.Codex/`, `Docs/MustRead/`,
   etc.). Files outside the manifest can't be promoted.

2. **Find the package root**. Same as `/update`: read `package.source` from
   the manifest, look for a local clone, ask the user if not found.

3. **Run `promote.ps1`** from the package root:

   ```powershell
   $Pkg    = '<package-root>'
   $Target = '<this-project-root>'
   & "$Pkg/promote.ps1" -TargetRoot $Target -Paths '<file1>','<file2>'
   ```

   The script:
   - Auto-infers classification per path from the consumer's manifest
     (`reusable-core` / `perforce-overlay` / `ue-overlay` /
     `myst-project-overlay`).
   - Dry-runs the promotion, showing which package path each file lands at.
   - Prompts before writing.
   - Reverse-substitutes project values back to `{{var}}` placeholders so
     the next consumer's render produces the right paths.
   - Roundtrip-verifies: re-renders the result with the same vars and
     compares to the original. Refuses on mismatch.

4. **After the write**, the package working tree at `$Pkg` has the change.
   Walk the user through the git steps:

   ```powershell
   cd $Pkg
   git diff                           # eyeball
   git checkout -b improve-<topic>
   git add -A
   git commit -m "improve: <message>"
   git push -u origin improve-<topic>
   gh pr create --fill                # or merge directly to main
   ```

   If the change is publishable (not a hotfix for the current user only),
   bump `CHANGELOG.md` and `package-manifest.json` version, then tag:

   ```powershell
   git tag -a v1.X.Y -m "v1.X.Y - <what>"
   git push origin v1.X.Y
   ```

## When to suggest this command

- The user says "promote this upstream" / "make this part of the package" /
  "push this back to the scaffold".
- You notice the user has edited a scaffold file and is treating it as a
  permanent improvement (not a one-off experiment).
- After a `/grill-with-docs` session that produced a refined workflow rule
  — that rule should probably live in the package, not just this project.

## What NOT to do

- **Don't promote files that aren't generic.** If the change references
  this project's specific paths, names, or domain language, it's
  `myst-project-overlay` (or your-project's overlay), not `reusable-core`.
  The classification auto-inference handles this — trust it unless the
  user has strong reason to override.
- **Don't skip the dry-run.** The user needs to see the reverse-substitution
  and roundtrip-verify result before approving. Roundtrip mismatches mean
  the file uses idioms the substitution layer can't handle.
- **Don't promote `local-only` or `project-owned` files.** `promote.ps1`
  will refuse these; don't try to force them.

## If `promote.ps1` errors

Common cases:
- **"Cannot infer classification for path: X"** — the path isn't in the
  consumer manifest. Either the path is wrong (typo, case mismatch), or
  it's a brand-new file. For new files, pass `-Classification` explicitly:
  `& "$Pkg/promote.ps1" -TargetRoot $Target -Paths 'X' -Classification 'reusable-core'`.
- **"REFUSED: local-only"** — the file is `localOnly: true` in the
  manifest (per-user state). Not promotable by design.
- **"Roundtrip mismatch"** — the file's content doesn't survive a
  substitute → render cycle. The user likely included a literal that
  collides with a `{{var}}` placeholder; manual reconciliation needed.

## Related

- `/update-myst-skills` — pull upstream changes into this project.
- `docs/install.md` §4 in the package — full promote workflow documentation.
