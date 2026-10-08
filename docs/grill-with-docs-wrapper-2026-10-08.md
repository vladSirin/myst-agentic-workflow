# Grill with Docs source and wrapper - 2026-10-08

Status: implemented, alignment tested, and independently reviewed; both axes
GREEN. Work started on 2026-10-08 and continued on
2026-10-09. Owner verification remains a separate gate.
Review base: cd83250. This changeset migrates grill-with-docs alone.

## Source and local integration

The former Myst entry exactly matches Matt's approved source at
6fd947921b935b7e1e69293a200400f0fdd5c15f. There is no interview method delta.
The complete skills/engineering/grill-with-docs subtree contains two files:
SKILL.md and agents/openai.yaml. Both are preserved byte-for-byte under
references/upstream; only SKILL.md maps to UPSTREAM.md under ADR-0009.
UPSTREAM.json records their hashes and the full inventory. PROVENANCE.md retains
the upstream MIT notice. Public Codex metadata preserves explicit-only use.

The source calls grilling and domain-modeling. Myst's entry selects those local
dependencies by namespace or full installed path, supports hosts without a
Skill tool, and loads the shared project/doc mapping. Copy installs require
agentic-workflow, grilling, and domain-modeling. The existing grilling method
is unchanged and remains a declared pending import; this changeset does not
claim its own boundary conversion is complete.

An observed test gap justified one local guard: confirm the relevant glossary
ownership and project ADR location before writes. If no ADR location is stated
and no existing project location can be confirmed, ask before creating it.
Upstream's default path does not resolve that project mapping gap. No upstream
file or dependency method was patched.

## Source, package, and host checks

Independent source verification passed: 16 imports, 10 pending imports, five
local skills. All 26 verifier unit tests passed. Six CI scripts, both offline
Claude manifest validators, and skills CLI 1.7.1 copy installation passed.
Codex, Claude Code, and OpenCode were selected; the resulting .agents and
.claude skill trees matched the package bytes. A narrow -text attribute preserves
both raw files through a real Git checkout with core.autocrlf=true.

Fresh Codex discovery found one enabled public fixture entry. Its metadata
excludes it from the automatic prompt catalog; grilling remains available there
as a control. The existing installed 5.4.0 namespaced grill-with-docs still appears
in that host catalog. The checks distinguish that old installation from the new
fixture; they do not claim the installed plugin has been upgraded. OpenCode
1.18.35 debug skill with an empty isolated config found one public fixture entry,
with no duplicate raw entry. OpenCode still needs its local explicit-command or
skill-permission rule; metadata alone is not an enforcement claim for every host.
These checks do not prove native slash-menu behavior or OpenCode model execution.
Claude model tests remain deferred by the owner.

## Runtime method and alignment

Evidence root: %TEMP%/myst-grill-with-docs-20261008. Codex CLI
0.162.0-alpha.2 used the normal configured host in disposable Git fixtures.
Direct cases load the complete approved grill-with-docs source under its original
entry filename. Both paths use the same actual Myst dependency entries and the
same project contract. This isolates the composition wrapper; it is not a
comparison against a wholly upstream dependency stack with no project mappings.
Existing host instructions and installed skills remain present. Full fixture
paths select the candidate; these tests do not isolate it as the sole cause of
correct behavior.

The initial pairs have identical prompts and all inputs outside grill-with-docs.
They ask an unresolved capacity-pool question while explicitly authorizing the
inline capture of an already resolved Reservation term and a previously approved
durable-store decision. That ADR meets all three upstream criteria. These doc
writes do not authorize implementation of the still-open pool plan.

| Initial case | Seconds | Observed result |
| --- | ---: | --- |
| new-direct | 152.191 | Writes the resolved glossary term and ADR 0003; asks the parent pool question; pauses. |
| new-wrapped | 172.176 | Same term, ADR meaning/number/location, parent frontier, and pause. |
| legacy-direct | 145.381 | Uses Records/CONTEXT.md and Records/Decisions/0005; advances to mode limits; borrowing waits. |
| legacy-wrapped | 161.516 | Same legacy mapping, docs, frontier, and pause. |
| missing-dependency | 86.546 | Confirms missing domain-modeling; writes no docs; asks the independent pool question. |
| conflict | 130.996 | Blocks both glossary edits and asks for ownership, but creates ADR 0001 at an unconfirmed default location. Not counted as a complete guard pass. |

The new-project recommendations differ: direct favors a global pool for simplicity;
wrapped favors separate pools for protected capacity. Both describe the trade-off
and leave the decision open. This supports alignment of method, doc meaning, and
user authority, not identical recommendations for an underdetermined design.
The legacy pair recommends explicit finite mode limits on both paths. It does not
invent numbers or ask the dependent borrowing question early. Glossary content
matches exactly; ADR text and optional status presentation vary while preserving
the approved future choice, rationale, migration cost, and unimplemented status.

All six runs have grounded file reads and successful process exits. Scoped read
retries recovered helper_unknown_error / setup-refresh failures. No model override,
credential copy, host config change, installed Myst edit, live Perforce action,
commit, or publication was part of the fixtures. Fixture HEADs, code, PLAN.md,
and dependency/candidate files remained unchanged; only the listed docs changed.

## Observed repair and final-candidate checks

The conflict fixture also lacked an ADR location or existing ADR directory.
Creating an ADR at the source default did not establish the relevant local
mapping. The wrapper now makes this existing shared-contract requirement explicit
at the doc-write boundary. The initial result remains in the evidence rather than
being relabeled as a pass. Initial positive cases predate this short guard.

Fresh final-candidate checks passed:

| Final case | Seconds | Observed result |
| --- | ---: | --- |
| final-conflict | 134.762 | No doc writes; asks for glossary owner and ADR location while keeping the independent pool question open. |
| final-missing-dependency | 128.860 | No doc writes; confirms the missing dependency; no vendor fallback. |
| final-legacy-wrapped | 152.217 | Aligns with legacy-direct: resolved term, ADR 0005, next capacity-limit question, borrowing deferred, no implementation. |

The final legacy prompt and all project/dependency inputs match the unchanged
direct baseline. All three final fixtures have exact final-candidate bytes;
inventories confirm the permitted doc changes and unchanged HEADs/code/packages.
alignment-checks.json retains initial and final results, candidate hashes,
input equality, and the manual semantic assessment. The initial new-project
comparison predates the guard; final alignment with an explicit doc mapping is
rechecked on the legacy pair. This is bounded evidence, not proof of identical
results for every future design.

## Independent review and remaining gates

Both independent reviews used base cd83250 and included all tracked/untracked
files in this skill changeset. They inspected the final saved outputs and report.
Neither reviewer changed files or published state.

Standards: no actionable BLOCKING, WARNING, or heuristic findings. The reviewer
found the ADR guard justified by the retained failure under ADR-0008's source
ownership rule. Final outputs support no writes for unresolved mappings or
missing dependencies; legacy docs and interview progression remain aligned.
The report accurately retains failure history, differences, limits, and gates.
Verdict: GREEN.

Spec: no actionable findings. Complete source inventory/hashes, unchanged method,
explicit-only invocation, dependency composition, copy requirements, and project
mapping meet scope. Final negative cases make no writes; final legacy preserves
the direct baseline's docs, frontier, and user authority. Candidate identity,
inventories, and HEAD checks support the report. Verdict: GREEN.

Final six CI scripts, both offline manifest checks, copy installation/hash checks,
and git diff --check passed after the guard repair. Owner verification is pending.
No deployed consumer or installed plugin was upgraded; no push, PR, merge,
release, or version bump occurred. Package/discovery evidence cannot replace
later consumer acceptance or the deferred Claude runtime checks.
