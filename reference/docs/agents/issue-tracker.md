# Issue tracker: Repo markdown

Issues and specs (you may know a spec as a PRD) for this repo live as markdown
files under `.scratch/`. This is the temporary setup until the team migrates to
a hosted tracker.

## Version-control policy

**Files under `.scratch/<feature-slug>/` are version-controlled.** They're
submitted to the repo (Perforce or git) alongside the related work and
serve as the project's tracked history of specs, tickets, and triage state.
"Repo markdown" means *the tracker is in the repo*, not *the files are
local-only*.

If you're unsure whether a `.scratch/` file should be submitted: assume
**yes**, unless it matches a `.p4ignore` / `.gitignore` exclusion (rare;
typically only `_tmp/` or `.cache/` style directories).

Genuinely local-only state lives elsewhere — `.claude/settings.local.json`,
`.Codex/settings.local.json`. Those are per-machine, not `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation tickets are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`
- Triage state is recorded as a `Status:` line near the top of each issue file
- Status values are defined in `Docs/agents/triage-labels.md`
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed). Then submit the file with the work it tracks — same CL/commit, or a closely-related one.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Retire an accepted Markdown spec

This starter includes retirement by default. An existing project adopts it once
in its own tracker. Apply it as each feature reaches closeout. Cleanup of older
specs needs a separate request.

- **Acceptance.** Apply the project's feature acceptance rule. If none exists,
  ask the feature owner once. All required checks for the accepted scope must
  pass, including any human check on a `resolved` ticket. If the owner accepts
  a smaller scope, record what shipped and link the open ticket for deferred work.
- **Planning record.** Preserve the spec as it stood. Record differences between
  the plan and the accepted result in the acceptance evidence. Put lasting rules
  in the maintained design or test docs.
- **Active links.** Before deletion, check active tickets and maintained docs
  for references to this spec. Move instructions still in use to a maintained
  home and update their links. For historical references in active material,
  link to the exact revision verified below. Pause while an active dependency
  remains unresolved. Retire only this effort's `spec.md`. Keep its tickets
  and Wayfinder maps, and leave closed tickets as historical records.

### Git

1. **Preserve.** Fetch the project's remote default branch. Choose a full commit
   SHA and repo-relative path for the planning text. Require exit code 0 from
   `git merge-base --is-ancestor <sha> <fetched-default-ref>`. Verify that
   `git show "<sha>:<path>"` returns the exact text to preserve. If it exists
   only on the feature branch, merge with the file present. After a squash,
   fetch and verify the resulting default-branch commit before preparing a
   follow-up deletion. Keep the file until both checks pass.
2. **Prepare.** Check the staged and working-tree copies for pending edits.
   Once the file matches the preserved revision, stage `git rm -- <path>` for
   normal review. Include the full SHA and path in both the closeout PR/MR (if
   used) and the deletion commit message. Include them in the final squash
   message when merging. Link the acceptance evidence in the closeout record.
3. **Recheck.** Immediately before merging, fetch the default branch again and
   repeat both Preserve checks. If history changed, use a reachable SHA with
   the same planning text and update both recovery pointers before proceeding.
   Keep the file if either check still fails. Compare the spec on the freshly
   fetched merge target with the preserved version and check for pending edits.
   If the file changed, pause deletion and resolve ownership. Changes to other
   paths can proceed.
4. **Verify.** The merger reads the full SHA and path from the landed deletion
   message, fetches the default branch, and repeats both Preserve checks using
   that pointer. Closeout stays incomplete if the pointer fails either check.
   If the assignment ends at opening the PR/MR, put this handoff in its body.
   If the pointer is missing or invalid after merge, verify a reachable copy
   of the planning text. Closeout stays incomplete until a follow-up commit
   lands with its verified SHA, path, and this exact line
   (substitute the full SHA of the landed deletion commit):

   ```text
   Spec closeout repair for <full-deletion-SHA>
   ```

To recover from the old path, use `git log --diff-filter=D -- <path>` on the
default branch to find the deletion message. For a repaired pointer, search
that branch with `git log --fixed-strings --grep="Spec closeout repair for <full-deletion-SHA>"`
without a path filter. Read the spec at the preserved SHA and path.

### Perforce

1. **Preserve.** Verify the exact planning text with `p4 print` at its full
   depot path and submitted revision (`//.../spec.md#N`). If it exists only in
   a workspace or shelf, submit that version through normal review first.
2. **Prepare.** Check the workspace copy against the preserved text and check
   for pending edits. Resolve local or competing edits before opening the
   file for deletion. Record the preserved path and revision
   and the acceptance evidence (or a link) in the deletion CL description.
   Open only this spec for deletion with `p4 delete` in that CL.
3. **Recheck.** Immediately before submit, compare the depot head for this
   path to the preserved revision and check for competing pending edits.
   If the spec changed or has another owner working on it, pause deletion
   and resolve ownership. Changes to other files can proceed.
4. **Verify.** After normal review and submit, the submitter checks that the
   submitted CL description contains the verified path, revision, and
   acceptance evidence. Use `p4 print` on that path and revision to read it.

To read a retired spec, use `p4 filelog -l` on its exact depot path to find the
deletion CL, then `p4 print` the revision recorded in its description.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.

**Identify the effort.** Wayfinder uses `map.md` and its decision tickets.
Active implementation uses `spec.md` and its implementation tickets. After
retirement, confirm the implementation effort from its recorded acceptance
and recovery reference in Git history or the submitted Perforce CL. A missing
spec alone does not establish acceptance. For Wayfinder,
`resolved` means the question was answered. For implementation, it means a
required human check remains (`Docs/agents/triage-labels.md`).
