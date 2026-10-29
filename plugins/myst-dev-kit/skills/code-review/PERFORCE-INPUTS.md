# Perforce review inputs

Load this reference only for a confirmed Perforce target. The shared input and
spec rules remain in [REVIEW-INPUTS.md](REVIEW-INPUTS.md).

The target CL and selected workspace/shelf/submitted revision are the review
input. A nested Git mirror does not change the target VCS. Map the upstream Git
base, diff, and commit-list steps to the CL evidence below, rather than running
them against the mirror. Confirm which version the user wants if workspace,
shelf, and submitted content are ambiguous.

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

A Perforce review has no Git commit list; state that and supply the CL identity.
