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

### Description traps

- Typographic punctuation (section sign, dashes, arrows, curly quotes, no-break spaces)
  arrives by copying from docs and breaks ASCII-only. A server without Unicode mode stores
  the bytes as-is, and a client in another code page shows them as mojibake. Write the
  ASCII form: `-`, `->`, straight quotes.
- P4V renders descriptions as Markdown. With text directly under a heading, it draws the
  rest of the description in heading font: keep a blank line under each heading.
- P4V caches submitted descriptions. After editing one (`p4 change -u` as its owner, or
  `-f` with admin access), restart P4V to see the change.

### Pin the change

```bash
p4 opened -c {CL}          # must list files; empty means not pending: stop and ask
p4 describe -s {CL}        # description + file list; NO diff body for a pending CL
p4 diff -c {CL} //...      # the diff the reviewers read
```

`p4 describe` alone hands a reviewer filenames and nothing to review, and the pass comes
back clean because there was nothing in it. An ADDED file has no diff: brief the reviewer
to read the whole file. Name instead of number: `p4 changes -s pending -u <user>`, confirm
with the user.

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
- Review Record: `gh pr edit {PR} --body-file {scratch}/body.md`; with no PR, amend the
  block into the final commit message before pushing.
- Park: leave the work on its branch; no merge, no PR.
- Publish: push and open or merge the PR per the project's flow; report the URL or SHA.
