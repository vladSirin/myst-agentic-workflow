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

Keep the spec until the whole feature is accepted and all required checks have
passed. A ticket at `resolved` still has a human check pending. Carry lasting
decisions into the project's maintained docs. Retire only the effort's
`spec.md`. Keep its tickets and Wayfinder maps in place.

### Git

1. Identify the project's remote and its default branch, then fetch that branch.
   Choose a full commit SHA containing the accepted spec at its repo-relative
   path. Run `git merge-base --is-ancestor <sha> <fetched-default-ref>` and
   require exit code 0. Read `git show "<sha>:<path>"` and verify it contains
   the exact accepted version. Keep the file if either check fails.
2. If the accepted version exists only on the feature branch, merge it with
   the file present. For a squash merge, use the resulting default-branch
   commit as the candidate SHA. Fetch and repeat both checks before preparing
   a follow-up deletion. Adding and removing the spec in the same squash would
   leave its contents out of that commit.
3. Confirm the file being retired still matches the accepted version, including
   any staged or working-tree edits. If it has changed, resolve those edits
   before proceeding. Stage the deletion with `git rm -- <path>` and follow
   the normal review process. Record the accepted SHA, path, and acceptance
   evidence in the closeout PR/MR or deletion commit. To recover the spec,
   run `git show "<sha>:<path>"` with that recorded SHA and path.

### Perforce

1. Confirm the accepted text matches the current submitted depot revision and
   check for pending edits to the spec. If another edit is in progress, keep
   the spec active until its owner resolves it. If the final
   text exists only in a workspace or shelf, preserve it in a submitted revision
   through the normal review process before retiring it.
2. Record the accepted spec's full depot path and revision (`//.../spec.md#N`)
   in the CL description for the deletion, along with the acceptance evidence
   or a link to it. Verify the recorded revision with `p4 print`.
3. Open only that effort's `spec.md` for deletion with `p4 delete` and follow
   the normal review and submit process.

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
and recovery reference in the PR/MR, Git commit, or Perforce CL. A missing
spec alone does not establish acceptance. For Wayfinder,
`resolved` means the question was answered. For implementation, it means a
required human check remains (`Docs/agents/triage-labels.md`).
