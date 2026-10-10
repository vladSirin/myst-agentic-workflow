# VCS mechanics for review-and-submit

Command forms and traps referenced from SKILL.md. Rules live there; this file holds only
the how.

## Perforce

### Create a named changelist (task start)

Create from **Bash** with a heredoc. A PowerShell pipe into `p4 change -i` prepends a UTF-8
BOM and fails with `Unknown field name`. Description lines are TAB-indented.

```bash
p4 change -i <<'SPEC'
Change: new
Description:
	Title - brief summary
SPEC
```

- Never `p4 change -o | p4 change -i` for a NEW CL: the new-CL form pre-fills `Files:` with
  every default-changelist file and sweeps them in.
- Verify right after creating: `p4 opened -c {CL}`; evict strays with
  `p4 reopen -c default {file}`; pull task files in selectively with
  `p4 reopen -c {CL} {files...}`.
- Unsure where a file belongs: leave it in the default change and `p4 reopen` later.
  Default-change files stay out of `p4 submit -c` and show in `p4 opened`.

### Update an existing CL's description

```bash
p4 change -o {CL} > {scratch}/cl.spec   # existing-CL form lists only this CL's files: no sweep
# edit the Description field; TAB-indent every line; leave Files: untouched
p4 change -i < {scratch}/cl.spec        # from Bash, never a PowerShell pipe (BOM)
```

Never bare `p4 change {CL}`: it opens an interactive editor. `{scratch}` must be a path
both Bash and native tools resolve identically (the session scratchpad). MSYS `/tmp` is
invisible to python and editors on Windows; a spec written there is silently not edited
and you re-submit the old description.

### Pin the change

For a pending workspace version, pin the target server/client, CL, and exact
file actions before collecting evidence:

```bash
p4 info
p4 opened -c {CL}
p4 describe -s {CL}
p4 diff -du {explicit edited files from that CL}
```

An empty opened-file list is not a pending workspace review; resolve the requested
version before proceeding. p4 diff has no -c filter. Never widen the diff to every
open file or use a nested Git mirror as the P4 target. Record each edited file's
base revision and depot/local mapping. Read added files in full; obtain deleted
base content with p4 print -q <depot-file>#<recorded-base-revision>. Include both
paths/actions for moves. Identify binary or unavailable evidence and its limits.
A pending p4 describe contains metadata and filenames, not a diff body.

For shelf or submitted versions, obtain matching diffs and full content through
the project's read-only VCS tools. Workspace content is not shelf evidence.
Reuse the code-review wrapper's input mapping and keep the same pinned evidence
for both axes. Name instead of number: p4 changes -s pending -u <user>, then
confirm the intended CL with the user.

### EOL flips (Windows)

A file flipped wholesale to LF slips past edit-time hooks and diffs as the whole file.
`p4 diff -dl` collapses it to the real change. Fix by restoring CRLF in the working file
(it stays open, the edit survives). Not `p4 sync -f` (skips open files, says up-to-date)
and not `p4 revert` (discards the edit). Re-diff, then review that.

### Park and publish

- Park: `p4 shelve -c {CL}`. Files stay open locally; exclude that CL from any later
  reconcile or submit-all; re-shelve with `-f` if its files change again.
- Publish: `p4 submit -c {CL}`; confirm with `p4 changes -m 1 -s submitted` and report the
  submitted number (pending CLs are renumbered on submit).

## git

- Commit titles follow the description's title convention; a PR carries the full
  description as its body.
- Pin: `git rev-parse {base}` must resolve; `git diff {base}...HEAD` (three-dot, against
  the merge-base); `git log {base}..HEAD --oneline`. An empty diff stops in front of the user.
- Description: keep the complete approved body in a UTF-8 file with real newlines.
  For an existing PR, use `gh pr edit {PR} --body-file {scratch}/body.md` only when
  that shared update is authorized. With no PR, retain the body for the authorized
  PR-creation step; do not create a PR or rewrite commits merely to store evidence.
  If the project's authorized publication flow uses a commit message instead,
  supply the complete body through Git's message-file option; history rewriting
  still requires its own authority. No review block is appended.
- Park: leave the work on its branch; no merge, no PR.
- Publish: push and open or merge the PR per the project's flow; report the URL or SHA.
