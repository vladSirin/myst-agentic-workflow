# Copy-install cleanup across the upstream refresh

This guide applies when a copy install moves across the upstream-boundary
refresh. The migration checkout is not a new published release. Use an exact
approved commit or release as the source. Do not identify its contents by the
manifest version alone: intermediate migration commits still say 5.4.0.

The pre-refresh v5.4.0 tag points to
`b3aeed04e0ea553af7b39f6d793e91f2ff676ff1`. Its package has 29 skills.
The candidate package has 31: it removes resolving-merge-conflicts and adds
pr, implement-spec and p4-description. Install your selected subset and its
declared Myst dependency closure. These counts describe full-library installs.

## Find the actual scope

The tested skills CLI is 1.7.1. Its add command defaults to project scope;
`--global` selects personal scope. Confirm paths in the installer output and
inspect the actual folders, including copies from earlier tools or scopes.

| Host | Project scope | Personal scope |
| --- | --- | --- |
| Codex | `<project>/.agents/skills` | `~/.agents/skills` |
| Claude Code | `<project>/.claude/skills` | `<CLAUDE_CONFIG_DIR>/skills`, or `~/.claude/skills` |
| OpenCode | `<project>/.agents/skills` | `~/.agents/skills` |

`~` means the user's home folder. CLI 1.7.1 routes Codex and OpenCode through
its universal `.agents/skills` store, including personal scope. Also inspect
older/manual copies in `<CODEX_HOME>/skills` (default `~/.codex/skills`) and
`<XDG_CONFIG_HOME>/opencode/skills` (default `~/.config/opencode/skills`). The
host configuration table alone does not determine the CLI's final destination.
A CLI canonical folder, copy or link can
serve more than one host. Follow links and inspect the resolved target before
any change. Check all discovery roots used by your host; a stale personal copy
can still appear after a project copy is fixed. Do not infer ownership from a
skill name, frontmatter, version number or path alone.

## Preflight and preserve edits

1. Record the chosen source commit, installation scope and installed Myst
   subset. Use your install receipt or source/lock record to establish origin.
   Compare every file and relative path in each affected folder against the
   known installed snapshot. A complete byte match plus confirmed Myst origin
   supports removal. A mismatch needs inspection to distinguish personal edits
   from another vendor's files. If origin or the base snapshot is uncertain,
   leave the folder untouched and report it.
2. Inspect both names that will be removed and retained names that add will
   replace. Preserve any confirmed Myst personal edits before either action.
   Copy the complete folder to a user-chosen backup directory outside **all**
   skill discovery roots, plugin folders and the source being installed.
   Record its origin/base and verify the backup's relative file list and
   SHA-256 hashes match the original. A backup under `.agents/skills` or
   `.claude/skills` is still discoverable and is not suitable.
3. Keep unrelated copies intact. If an uncertain or unrelated same-name folder
   collides with the selected install, stop the dependent replacement and
   report the collision for an owner decision. Do not overwrite it through add.
   The install is not ready while that collision remains unresolved.

## Upgrade

Remove only the proven Myst-installed resolving-merge-conflicts folder in each
affected scope, after the preflight and any verified backup. Check the resolved
absolute target lies within the intended discovery root before a recursive
removal; on Windows use native PowerShell with literal paths. Do not delete the
whole skills root or use a wildcard. Re-running add alone leaves stale names.

Then install the chosen candidate from a checkout of its exact commit, at the
same scope and with the selected skills plus dependencies. For example, from
the consuming project's directory, a full project-scope copy is:

```text
npx skills@1.7.1 add <absolute-path-to-selected-checkout>/plugins/myst-dev-kit --skill '*' --agent codex claude-code opencode --copy -y
```

Use only your actual hosts; add `--global` if that is the recorded scope. The
example deliberately uses a local pinned checkout. It does not fetch an
unreleased candidate from main. Review the destination paths before running it.

## Rollback

Repeat the preflight against the installed candidate. Preserve personal edits
in retained skills and the three new-only skills. Remove only proven Myst
copies of pr, implement-spec and p4-description from the affected scopes.
Install the selected pre-refresh snapshot at the same scope. It restores
resolving-merge-conflicts. Compare retained folders completely too: old installs
must not contain new raw references left beside old files.

## Verify the selected install

Compare every Myst folder's complete relative file list and hashes with the
selected snapshot. Check the selected names and dependency closure. Check that
no retired Myst entry, extra nested SKILL.md or backup remains discoverable.
Keep unrelated personal entries; report them separately from the Myst catalog.
Start a fresh session and inspect the host's skill list at that scope. Do not
claim the whole machine is clean from one project fixture or one host list.

Native Claude/Codex plugin users use the normal plugin update/replacement path
and a fresh session. Do not manually delete their plugin caches with these copy
steps. A disposable directory-replacement test does not prove the native updater
or menu. `retire-legacy.ps1` handles v4 state and is not this cleanup process.

The [retirement report](retire-merge-conflicts-2026-10-09.md) records the actual
fixture checks and limits. This guide introduces no installer or automatic
cleanup. Development tests do not authorize changes to real installed copies.
