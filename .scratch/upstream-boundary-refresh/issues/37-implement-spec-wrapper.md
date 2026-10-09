# Adopt Implement Spec for Git work

Type: task
Status: source/wrapper implemented; nine runtime cases, alignment and package checks passed; both independent reviews GREEN; owner verification pending
Review base: d3eeede
Spec: [Git-only adoption](../../../docs/plan_upstream_boundary_refresh.md#required-git-only-implementation-changeset)
and [source boundary](../../../docs/adr-0008-strict-upstream-boundary.md).

Preserve the complete approved upstream implement-spec subtree and metadata.
Keep its user-only invocation contract. Add only Myst target-VCS eligibility,
project/dependency and existing authority routing. Use the unmodified task graph,
worker worktrees, merger, integration validation and cleanup method in a disposable
Git pilot with independent and dependent tickets. Verify dependency ordering,
worker ownership, existing-work preservation, review and publication boundaries.
Compare actual direct/wrapped results. Test P4 direct, automatic and cross-skill
exclusion with a Git mirror. Check source/loading/copy/discovery/checkout.
No upstream edits, speculative task-to-changeset mapping, TDD question relay,
P4 implementation counterpart, live P4, publication, consumer update, host edits,
or Claude model runtime. Local synthetic Git branches and merges are authorized.

Evidence: [report](../../../docs/implement-spec-wrapper-2026-10-09.md).
Owner verification remains the gate before the next changeset.
