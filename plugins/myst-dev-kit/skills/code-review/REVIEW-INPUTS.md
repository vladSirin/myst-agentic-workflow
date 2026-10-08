# Myst review input mapping

Apply this mapping to the upstream input steps. The review method stays upstream.

## Project and spec

Use the target project's tracker workflow and explicit spec pointers selected by
LOCAL-INTEGRATION. Map upstream docs/agents/issue-tracker.md to that workflow.
The excluded setup-matt-pocock-skills is not a fallback: report the missing pointer
and establish the project contract. Honor a caller's verified spec, including a
Ticket: pointer supplied by review-and-submit. Otherwise use upstream's ordered
lookup. If no spec is found, ask; skip the Spec axis only when the user confirms
there is no spec, and report the skip explicitly.

## Pin one review input

Keep the target, requested scope, file actions, base revisions, evidence source,
and diff fixed for both reviewers. Reuse a caller's pinned evidence after checking
that it matches the requested scope and current revisions/content. If it is stale,
incomplete, empty, or cannot be checked, report the gap before dispatch. An
explicitly supplied snapshot may be reviewed as that snapshot; identify its age
and limits instead of presenting it as a fresh live-state check.

For Git, use the upstream fixed-point, three-dot diff, and commit-list steps for
a committed range. For an explicitly requested staged or working-tree review,
pin that scope and the requested base instead; include complete added-file content.
Do not silently replace uncommitted scope with HEAD or invent a missing base.

For Perforce, the target CL and selected workspace/shelf/submitted revision are
the review input. A nested Git mirror does not change the target VCS. Map the
upstream Git base, diff, and commit-list steps to the CL evidence below, rather
than running them against the mirror. Confirm which version the user wants if
workspace, shelf, and submitted content are ambiguous.

- Identify the server/client and CL status, description, and file actions with
  read-only project tooling (for example p4 info and p4 describe -s <CL>).
- For a pending workspace review, use p4 opened -c <CL> to select exact files.
  Diff edited files with p4 diff -du <explicit files>, using their recorded base
  revisions. p4 diff has no -c filter: never widen this to all open files.
- Read complete added-file content. For deletes, include the removed base content;
  record both paths/actions for moves. Preserve depot-to-local path mappings.
- For shelf or submitted review, obtain the matching version's diffs and full
  content through the project's read-only VCS tools. Pending workspace diffs do
  not stand in for a shelf. Pending p4 describe alone contains no diff body.
- Identify binary or unavailable evidence and the review limit. Do not claim a
  content review from a filename list. If no reviewable evidence remains, stop
  and request it before dispatching reviewers.

Give both axes the same pinned evidence, file list, revision identity, and command
or snapshot source. Include the spec and standards references each axis needs.
A Perforce review has no Git commit list; state that and supply the CL identity.
For immutable captured evidence, include its recorded hashes when available.
Keep any caller-supplied finding categories, read-only constraints, and artifact
anchors. No VCS action in this adapter authorizes publication or description edits.
