# Git review inputs

Load this reference only for a confirmed Git target. The shared input and spec
rules remain in [REVIEW-INPUTS.md](REVIEW-INPUTS.md).

Use the upstream fixed-point, three-dot diff, and commit-list steps for a committed
range. For an explicitly requested staged or working-tree review, pin that scope
and the requested base instead; include complete added-file content. Do not
silently replace uncommitted scope with HEAD or invent a missing base.
