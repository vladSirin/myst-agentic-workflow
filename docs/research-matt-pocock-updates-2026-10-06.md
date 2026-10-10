# Matt Pocock skills: upstream update assessment

Date: 2026-10-06. This is an assessment, not an adoption or release.

Follow-up: [the restoration and refresh plan](plan_upstream_boundary_refresh.md)
uses a newer Matt snapshot and verified Hammer sources. This note retains its
original comparison pins as historical evidence.

## Sources and scope

- Myst baseline: `b3aeed04e0ea553af7b39f6d793e91f2ff676ff1`, v5.4.0.
- Upstream snapshot: `2237a047bd95abfd1427df94f65165c39e24d3c1`. Its commit timestamp is 2026-10-06T13:55:45+01:00. All upstream links below pin this snapshot.
- Upstream's [plugin manifest](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/.claude-plugin/plugin.json) declares v1.3.1 and includes engineering/productivity skills. A manifest version is not evidence that every commit in this snapshot is in a published release.
- Evidence came from `git show`, `git ls-tree`, and file history against the fetched commit, plus the current Myst files. No skill was installed or run to test its behavior.

## Promoted skills absent from Myst

There are five promoted upstream skills missing from `plugins/myst-dev-kit/skills`. Missing locally does not mean newly authored: `implement-spec`, `pr`, and `retro` graduated on September 24; `ask-matt` and setup existed earlier.

| Skill | What it adds | Recommended use in Myst |
| --- | --- | --- |
| [retro](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/retro/SKILL.md) | Reads session evidence and ranks improvements to navigation, checks, review standards, tools, and agent instructions. Separates mechanical failures from judgement calls. | Best new candidate. Pilot after one real failure or long review. Keep the first result as proposed improvements; implement only changes that match the user's scope. |
| [pr](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/pr/SKILL.md) | Small visuals, before/after evidence, reversibility, and impact in PR bodies. | Useful ideas, but do not activate unchanged. Its mandatory body template conflicts with Myst's required description and Review Record. Settle one description contract first. |
| [implement-spec](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/implement-spec/SKILL.md) | Treats tickets as a dependency graph; runs ready tickets in separate worktrees, merges through an integration branch, and reviews the whole result. | Defer for Perforce projects. Consider a separate Git-only trial after choosing how publication and ticket closure remain gated. |
| [ask-matt](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/ask-matt/SKILL.md) | A guide to the whole skill flow, including prototype detours, context choices, and retrospectives. | Use as a reference for improving `agentic-workflow`. Avoid installing a second process router that names absent skills or omits Myst's verification/publication stages. |
| [setup-matt-pocock-skills](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/setup-matt-pocock-skills/SKILL.md) | Configures tracker, triage labels, and domain docs. Supports GitHub, GitLab, local Markdown, and freeform other workflows. | Useful for a new consumer project. An existing Myst consumer already has these contracts; audit those first. Do not run setup as a migration shortcut. |

### Integration issues that need a decision

**Retro:** The useful rule is to turn repeated mechanical errors into checks and reserve prose standards for judgement. It also treats absent hooks/CI as a finding. In a Perforce/UE project, test whether an existing build gate, server check, or editor check covers the failure before adding Git tooling. Its claim that review needs no exploration is too broad for binary assets and cross-file behavior. Its review-only placement of coding standards must not displace Myst's implementation standards. Keep the skill user-invoked and proposal-only at first; do not revive blanket hooks or agent machinery retired by ADR 0007.

**PR descriptions:** Myst's [review-and-submit](../plugins/myst-dev-kit/skills/review-and-submit/SKILL.md) requires What/Why/Notes, project tags, evidence limits, and a Review Record. Upstream `pr` requires Summary/Evidence/Merge Danger. Use the visual and evidence ideas within an agreed local description contract; do not create two competing mandatory templates. Keep [CREDITS.md](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/pr/CREDITS.md) if importing its visual guidance: it credits Dex Horthy/Humanlayer's `show-me`.

**Whole-spec execution:** `implement-spec` opens a draft PR when appropriate, marks it ready after review, and otherwise resolves tickets through their tracker. It assumes Git branches, worktrees, merging, and resets onto the integration branch. This does not map directly onto shared Perforce workspaces or a live UE editor. A safe local design needs explicit file ownership, binary-asset constraints, per-CL review/publication authority, and the distinction between implemented, human verification pending, and closed. Do not treat passing code review as visual acceptance. The graph scheduler is useful; the whole workflow is not a drop-in.

**Router and context guidance:** `ask-matt` correctly distinguishes generated tickets from raw incoming issues and separates research from decisions. Its [phase-boundary guide](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/ask-matt/PHASE-BOUNDARIES.md) offers a useful order: continue, clear irrelevant context, hand off portable work, delegate a bounded task, or compact. The approximate 150k-token "smart zone" is an upstream heuristic, not a measured limit for this machine or model. Do not use it as a claim that a threshold was reached.

**Setup:** The skill writes `docs/agents/*`, root glossary pointers, and a block in CLAUDE.md or AGENTS.md. Myst consumers may use different locations and established role/lifecycle rules. Its [local tracker template](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/setup-matt-pocock-skills/issue-tracker-local.md) is close to Myst's `.scratch` layout, but mapping a tracker does not configure Perforce publication authority. Reuse an existing project contract rather than generating a second one.

## Beta and miscellaneous skills

The [in-progress bucket](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/in-progress/README.md) is explicitly beta, excluded from the plugin, and may change or disappear. At the pinned tree it contains `chief-of-staff`, `claude-handoff`, `loop-me`, `setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, and `writing-shape`. The bucket README omits `chief-of-staff`; the tree and its [skill file](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/in-progress/chief-of-staff/SKILL.md) establish its presence.

- `chief-of-staff` explores long-running goals with subagents and schedules. Watch it; do not make this beta orchestrator the default workflow.
- `claude-handoff` uses `claude --bg`; it is not a portable Codex handoff.
- `setup-ts-deep-modules` is relevant to TypeScript projects, not an immediate UE/AngelScript need.
- `loop-me` and the three writing skills serve separate interview/writing tasks. Adopt only after a real local need appears.

The [misc bucket](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/misc/README.md) contains `git-guardrails-claude-code`, `migrate-to-shoehorn`, `scaffold-exercises`, and `setup-pre-commit`. Upstream [scope](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/SCOPE.md) declares misc frozen and unmaintained. Do not count these as promoted updates or import them as routine maintenance.

## Adoption and contribution constraints

1. Follow [CONTRIBUTING.md](../CONTRIBUTING.md): dogfood each candidate, preserve upstream files verbatim, add a same-directory PROVENANCE.md, keep local additions in separate reference files, and submit one skill per PR. Run the documented parse/ASCII/lint/plugin checks. Larger protocol or trigger changes need an issue and agreed shape first.
2. Follow [ADR 0007](adr-0007-lean-library-supersedes-vendor-render-model.md): keep the plugin as the distribution channel and avoid restoring the old vendor/render machinery. Manual, pinned comparisons are intentional. Do not edit an installed plugin clone.
3. Upstream's [MIT notice](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/LICENSE) requires preservation of copyright and permission text. Keep attribution and any bundled credits with imports. The local [LICENSE](../LICENSE) has the older pre-v5 pin; new/replaced skills need clear per-skill provenance rather than silently treating that old pin as current.
4. Keep Myst's [agentic-workflow](../plugins/myst-dev-kit/skills/agentic-workflow/SKILL.md) and publication protocol authoritative. A new upstream skill does not grant submit authority or close outstanding human checks.
5. Upstream contributions need an observed failure and a fit with its stated philosophy. Harness-specific policy, local workflows, new skill proposals, and first-class additional tracker backends are outside its stated scope. Myst's Perforce and human publication rules belong locally. Its [subagent recursion policy](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/.out-of-scope/subagent-recursion.md) also puts depth limits in the harness; do not assume upstream will accept local agent-guard changes.

## Suggested order for new capabilities

1. Pilot `retro` on a real session. Check whether its proposed changes reduce a measured failure without adding broad new machinery.
2. Resolve the PR description contract, then trial the useful visual/evidence guidance on one Git PR.
3. Improve local routing with selected ideas from `ask-matt`, while preserving verification, publication, and project-specific design stages.
4. Keep setup for new consumers and defer `implement-spec` until a Git-only pilot has clear ownership and completion rules.

These are recommendations. No adoption, skill edits, version bump, commit, push, or release is recorded by this assessment.

## Existing-skill audit

This comparison reads Myst commit `b3aeed0` and upstream commit
`2237a047bd95abfd1427df94f65165c39e24d3c1`. It compares actual files, with
CRLF/LF and final newline differences normalized. It is not a runtime test.

Upstream's package version and nearest release tag are **1.3.1**. Main also
contains later fixes. Myst's version **5.4.0** is a separate version series.
The pre-v5 attribution pin is `0ab1b63a410a03d3627979a109c8695de27af954`;
code-review has its own pin, `6654f6b60cd9d5be8b54c6fafe44346dabeb3b76`.
Neither single pin is a complete statement of every local file's baseline.
Sources: [upstream package](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/package.json),
[release-to-main comparison](https://github.com/mattpocock/skills/compare/v1.3.1...2237a047bd95abfd1427df94f65165c39e24d3c1),
[local attribution](../LICENSE), [code-review provenance](../plugins/myst-dev-kit/skills/code-review/PROVENANCE.md).

### What is already current

Of the 22 same-named skills shared with upstream's engineering/productivity
buckets, code-review has matching upstream content, including agents/openai.yaml,
apart from Myst's additional provenance file. Research, grilling, grill-me,
grill-with-docs, prototype, wizard, teach, to-questionnaire, and writing-for-agents
also have matching bodies and companion content, but lack upstream's Codex metadata.

Eleven SKILL.md files differ: diagnosing-bugs, domain-modeling, implement,
improve-codebase-architecture, tdd, to-spec, to-tickets, triage, wayfinder,
handoff, and wait-what. Codebase-design also differs in DESIGN-IT-TWICE.md.
Domain-modeling has CONTEXT-FORMAT.md where upstream has GLOSSARY-FORMAT.md.

These differences do not all represent missing fixes. to-spec and wayfinder
differ only in Myst's deliberate project-tracker lookup; other skills combine
local changes with upstream changes. Myst already has the earlier secret-redaction,
wizard stage-count, glossary-map lookup, and most explicit skill-invocation fixes.
Source trees: [Myst](https://github.com/vladSirin/myst-agentic-workflow/tree/b3aeed0/plugins/myst-dev-kit/skills)
and [upstream](https://github.com/mattpocock/skills/tree/2237a047bd95abfd1427df94f65165c39e24d3c1/skills).

### Changes worth adopting

| Change | Evidence and actual gap | Recommendation |
| --- | --- | --- |
| Handoff temporary directory | The new body spells out TMPDIR, /tmp, and Windows TEMP. Myst still says only the OS temporary directory. | First small update. Re-vendor this skill, including metadata and provenance. Check Windows path resolution and that the handoff stays outside the workspace. |
| Codex metadata | 21 of the 22 skills shared with current upstream lack agents/openai.yaml. The historical v4.43.0 ledger explicitly excluded these files; this was not an accidental omission. | Recheck the exclusion against the current Codex runtime before proposing adoption. If needed, pilot with handoff and check fresh-session discovery and explicit invocation. Do not put the false flag on model-invoked skills such as writing-for-agents. |
| Ticket relationships | Upstream now separates parent/sub-issue hierarchy from blocking edges, and omits the body Blocked by section when native edges already own it. | Useful for hosted trackers. Retain Myst's project tracker lookup and local Markdown blockers. Current local reference uses Markdown, so the immediate gain is modest. |
| Explicit implementation skill calls | Upstream implement now explicitly calls tdd and code-review. | Adopt the explicit loading principle through Myst's own workflow guidance. Preserve review-and-submit and its namespaced review engine. The bare upstream code-review route is not an equivalent replacement. |
| GitHub external-PR listing | The setup template now uses REST pulls data to filter author_association. | Carry this into a future GitHub tracker reference only if that tracker is used. It is not a reason to install upstream's entire setup skill. |

Sources:
[handoff](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/productivity/handoff/SKILL.md),
[handoff metadata](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/productivity/handoff/agents/openai.yaml),
[writing-for-agents metadata](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/productivity/writing-for-agents/agents/openai.yaml),
[to-tickets](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/to-tickets/SKILL.md),
[implement](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/implement/SKILL.md),
[GitHub tracker](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/skills/engineering/setup-matt-pocock-skills/issue-tracker-github.md),
[local tracker reference](../reference/docs/agents/issue-tracker.md).

### Glossary migration and removal

Upstream changed CONTEXT.md / CONTEXT-MAP.md to GLOSSARY.md / GLOSSARY-MAP.md.
This changes file discovery, not just display wording. It affects domain-modeling,
diagnosing-bugs, tdd, triage, improve-codebase-architecture, wait-what, and
codebase-design's companion brief. Myst also uses the old names in agentic-workflow,
README, and reference docs. A partial migration can make agents miss the existing
glossary or create a second one.

Defer this until a coordinated migration is agreed. Audit consumer file paths,
choose a compatibility policy, and move readers and writers together. A
fallback for old names is a **local proposal**, not upstream behavior; under
Myst's verbatim policy it needs an explicit local home and a tested loading path.
Without a compatible transition, the required consumer migration meets Myst's
MAJOR criterion. Metadata and small behavior additions alone do not justify
that bump. Do not rename consumer documents during this research task.

Upstream also removed resolving-merge-conflicts because it considers ordinary
agent behavior sufficient. Keep Myst's copy for now unless the owner wants it
retired; its removal provides no prerequisite for adopting the other changes.
Sources: [upstream changelog](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/CHANGELOG.md),
[local workflow](../plugins/myst-dev-kit/skills/agentic-workflow/SKILL.md),
[local domain reference](../reference/docs/agents/domain.md),
[local version rules](../CHANGELOG.md).

### Integration constraints

A wholesale replacement would erase established local changes:

- implement and tdd route to review-and-submit.
- to-spec, to-tickets, triage, and wayfinder consult project-owned tracker docs.
- Myst's workflow and multi-changeset protocol retain human publication and
  per-changeset verification.

Current policy requires upstream files to remain verbatim, with local additions
in separate reference files. Existing adaptations predate this update. Before
re-vendoring an affected skill, make their ownership explicit and ensure the
local guidance will actually load. Merely creating an unreferenced companion
file does not preserve behavior. Simple handoff and metadata work can proceed
without resolving all of this first.
Sources: [contribution rules](../CONTRIBUTING.md),
[ADR-0007](../docs/adr-0007-lean-library-supersedes-vendor-render-model.md),
[local implement](../plugins/myst-dev-kit/skills/implement/SKILL.md),
[local tdd](../plugins/myst-dev-kit/skills/tdd/SKILL.md),
[local multi-changeset rule](../plugins/myst-dev-kit/skills/changelist-verification/SKILL.md).

Upstream also explicitly declines skill-level subagent recursion guards and
native question-tool routing. The proposed leaf-reviewer/research recursion
fixes visible on remote branches are not delivered changes on main. Keep any
needed harness controls and personal question-UI choices local.
Sources: [recursion scope](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/.out-of-scope/subagent-recursion.md),
[question UI scope](https://github.com/mattpocock/skills/blob/2237a047bd95abfd1427df94f65165c39e24d3c1/.out-of-scope/native-question-tool.md).

## Proposed delivery order

1. **Handoff pilot:** copy upstream skill files and add its exact provenance;
   first reassess the historical metadata exclusion. Verify temp-path behavior and fresh-session
   discovery. This is the smallest useful first PR.
2. **Retro trial:** use it on a completed session and assess the quality of its
   proposals before vendoring it. Retain the user-invoked entry point.
3. **Metadata coverage, if the reassessment supports adoption:** work skill by skill, preserving each invocation type.
   Do not replace otherwise-current bodies just to add metadata.
4. **Ticket and invocation changes:** resolve local guidance ownership, then
   adopt each affected skill separately with local and hosted tracker examples.
5. **Glossary migration:** agree the compatibility and versioning plan before
   any coordinated change. Defer implement-spec and broader orchestration.

Each adoption should carry attribution, the relevant README catalog change,
and validation. Follow the current one-skill-per-PR contribution rule; a future
cross-skill glossary migration needs an agreed exception or compatible staging.
Run the repository CI checks and both plugin validation commands when adopting.
For metadata changes, also check Codex invocation behavior; current CI does
not test it. This is a proposed sequence, not completed implementation.

## Verification and scope

- Fetched upstream/main; examined committed source and release-to-main diffs.
- Compared the 22 shared promoted skill trees and local integration references.
- Checked local contribution, versioning, provenance, and CI requirements.
- Saved this research note only. No skill was replaced, no consumer was updated,
  and no commit, PR, or publication was made.
- No installed-plugin behavior or UE/Perforce runtime was tested.

## Follow-up: did we preserve upstream content intact?

Strictly, no. The history supports a more precise statement: upstream content
was kept mostly intact, with small, documented inline exceptions. A comparison
against each recorded pin, rather than current upstream main, found:

- 22 older Matt Pocock skills map to the LICENSE pin, 0ab1b63. Six SKILL.md
  files differ in seven lines: implement and tdd change the review route;
  to-spec, to-tickets (two lines), triage, and wayfinder change setup/tracker
  references. The other 16 skills' shipped content matches the pin after
  EOL/final-newline normalization.
- All 22 omit agents/openai.yaml. The historical ledger explicitly rejected
  these files on packaging grounds. That rationale is historical evidence,
  not proof that present Codex runtimes ignore the metadata. This corrects
  the earlier framing of the metadata as simply a gap to fill.
- code-review's SKILL.md and agents/openai.yaml match its separate 6654f6b
  pin after the same normalization. Its local provenance note is additive.
- Hammer-derived deep-dive and roundtable explicitly declare local frontmatter
  and an unchanged body in their provenance notes. This follow-up did not
  retrieve the original Hammer binary to independently verify those bodies.

The seven inline changes were recorded in the v4.43.0 divergence ledger.
Commit 9cb2231 records reviewer passes and owner confirmation. The v5 migration
then revised those same seven references as the old local entry points were
retired. The current migration inventory names those edits. This establishes
documented intent, rather than unexplained content drift.

However, current CONTRIBUTING.md says vendored content stays verbatim and local
additions go in separate files. README also claims verbatim vendoring and
per-skill provenance more broadly than the tree supports. ADR-0007 retired
the ledger/hash machinery while keeping the verbatim-by-default principle.
Thus the live documentation needs to distinguish actual exceptions from the
strict rule; removing the tooling did not make the inline edits into wrappers.

Sources: [ADR-0006](adr-0006-verbatim-by-default-and-the-divergence-ledger.md),
[historical ledger](https://github.com/vladSirin/myst-agentic-workflow/blob/9cb22310bdd4b89eee6129fba7f6648cad072347/.scratch/revendor-0ab1b63-divergence-ledger.md),
[v5 migration inventory](migration-v5.md),
[current contribution rule](../CONTRIBUTING.md),
[deep-dive provenance](../plugins/myst-dev-kit/skills/deep-dive/PROVENANCE.md),
[roundtable provenance](../plugins/myst-dev-kit/skills/roundtable/PROVENANCE.md).

Recommended direction: keep upstream-owned files unchanged at their pins and
make Myst's routing, publication rules, and project setup live in explicitly
loaded local wrappers. Before moving any of the seven inline changes, prove
that the wrapper preserves skill resolution and publication behavior. Do not
blindly restore upstream references that would select the wrong review skill
or require an uninstalled setup skill.
