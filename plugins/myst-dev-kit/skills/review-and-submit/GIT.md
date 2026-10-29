# Git mechanics for review-and-submit

Load this reference only for a confirmed Git target. Shared review and publication
rules stay in SKILL.md.

- Task start: work on a named branch, never on the default branch.
- Commit titles follow the description's title convention; a PR carries the full
  description as its body.
- Pin a committed range: `git rev-parse {base}` must resolve; use
  `git diff {base}...HEAD` against the merge-base and
  `git log {base}..HEAD --oneline`. An empty diff stops in front of the user.
  For an explicitly requested staged or working-tree review, follow the selected
  [Git review inputs](../code-review/GIT-INPUTS.md) instead of replacing it with HEAD.
- Description: keep the complete approved body in a UTF-8 file with real newlines.
  For an existing PR, use `gh pr edit {PR} --body-file {scratch}/body.md` only when
  that shared update is authorized. With no PR, retain the body for the authorized
  PR-creation step; do not create a PR or rewrite commits merely to store evidence.
  If the project's authorized publication flow uses a commit message instead,
  supply the complete body through Git's message-file option; history rewriting
  still requires its own authority. No review block is appended.
- Park: leave the work on its branch; no merge, no PR.
- Publish: push and open or merge the PR per the project's flow and the user's
  specific authorization; report the URL or SHA.
