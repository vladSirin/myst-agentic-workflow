## Summary

Restore complete pinned upstream content behind Myst entries. Keep local project,
VCS and publication rules in the wrappers.

```text
public SKILL.md                 Myst routing and invocation
references/upstream/UPSTREAM.md original upstream method
references/upstream/...         complete original companions
```

Ticket: .scratch/upstream-boundary-refresh/spec.md
Spec: docs/plan_upstream_boundary_refresh.md

Add Git-only pr and implement-spec, plus local p4-description. Put actual review
results inside Evidence. Retire resolving-merge-conflicts. Preserve consumer
vocabulary paths and human publication authority.

## Evidence

Before: released v5.4.0, b3aeed04e0ea553af7b39f6d793e91f2ff676ff1, 29 skills.
After: corrected implementation 5b75a5b0a98c88e1042a538aeaff21b14c8205ff,
31 skills, 26 complete unchanged source bundles and zero pending imports.

Standards: GREEN for the full implementation range through edbcf9a; actual final release-candidate review pending.
Spec: GREEN after the four-file documentation correction at 5b75a5b; actual final release-candidate review pending.

Separate full-range reports and fixed findings are in
docs/review_upstream_refresh_final_2026-10-09.md. Per-skill owner verification and
alignment limits are linked from docs/migration-upstream-boundary.md. Combined
install/cleanup and current UE parser evidence is in
docs/upstream-release-acceptance-2026-10-09.md. Fresh source acquisition, 26
acceptance tests, six CI scripts and both offline validators pass. A disposable
5.5.0 candidate passes nine applicable gates. Docs-alignment fixes are checked.

Claude model runtime is owner-deferred. Remote Git update, native slash menus and
wider required consumer scope remain unverified. Actual PR CI, final candidate
acceptance and publication approval have not happened. Refresh these fields
from the actual reports before publication; this draft cannot supply approval.

## Merge Danger

**Door:** two-way

Skill files can be restored from the exact baseline. Copy users must preserve
personal edits and remove only confirmed obsolete Myst copies. A published tag
cannot be silently rewritten; rollback publication needs its own review.

**Blast Radius:** library

This changes all imported entry paths and shared routing. Selected copy installs
need their declared dependency closure. Required parser compatibility must be
resolved before exposure. The single manifest/notes bump and exception closeout
remain final candidate work. This draft grants no merge or tagging authority.
