# VCS-specific review references

## Scope

The owner requested explicit Perforce-only rules and conditional Git/Perforce
detail loading in PR #109. This follow-up changes Myst-owned reference routing,
not the upstream review method. The scoped contract is the
[VCS-specific loading follow-up](../.scratch/review-evidence-budget/spec.md#vcs-specific-loading-follow-up).

The previous local VCS mechanics and review-input files held both sets of details.
The shared source-control rule also put Perforce commands before its Git rule.
The new entry path resolves the target VCS and reads only its local detail branch:

```text
Target VCS
  Git      -> GIT.md + GIT-INPUTS.md + pr
  Perforce -> PERFORCE.md + PERFORCE-INPUTS.md + p4-description
  unclear  -> resolve the target before either detail branch or formatter
```

The mechanics and input references are selected when their workflow step needs
them; review alone does not require publication commands or a formatter.
[VCS-MECHANICS.md](../plugins/myst-dev-kit/skills/review-and-submit/VCS-MECHANICS.md)
remains a small selector so existing links still resolve.
[REVIEW-INPUTS.md](../plugins/myst-dev-kit/skills/code-review/REVIEW-INPUTS.md)
keeps shared spec and evidence rules. The main protocol marks Perforce-only
checkout, default-changelist, and Windows EOL rules explicitly.

## Preserved behavior and limits

The shared evidence gate, round ledger, separate Standards/Spec axes, original
reviewer clearance, description evidence, and publication approval stay in their
existing owners. A nested Git mirror does not turn a Perforce target into Git.
Live links and review-evidence pins keep their existing roles.

The archived upstream files, source records, pins, and method remain intact.
Their original Git wording is still read with the upstream method and mapped by
the local target-specific input reference. Conditional loading here concerns the
Myst-owned detail files; it does not claim that all Git words vanish from a
Perforce review or that the host enforces document routing at runtime.

## Verification and review

The full existing suite passes: 48 tests. The seven mechanical CI checks pass,
including Windows PowerShell 5.1 parsing, ASCII/BOM, frontmatter, public labels,
manifest versions, install instructions, and retired-reference checks. Both
plugin and marketplace validators pass without warnings on the real paths.
Initial sandbox runs failed on temporary-file/Git helper access or skipped paths;
successful reruns are retained separately from those attempts.

Static checks confirm that all 69 archived source files, 26 source records, and
upstream-policy.json match the starting commit. Relative links resolve and
Markdown fences are balanced. Independent verification passes for all 26 imported
bundles, with no pending imports. Clean-context Astra/max Standards and Spec
reviews both returned GREEN in round 10, with no blockers or warnings. Docs
alignment is aligned. These are static routing checks; live model routing and
consumer daily use remain unverified. The existing
[review ledger](../.scratch/review-evidence-budget/review-round-1.json) owns the
shared input pin, continued round count, reports, and finding dispositions.
Historical reports remain unchanged. No test of exact instruction wording or
Markdown line positions is added.

PR #109 remains an unmerged 5.6.0 preview. The owner authorized its update, not
a merge, tag, release, or local plugin refresh in this follow-up.
