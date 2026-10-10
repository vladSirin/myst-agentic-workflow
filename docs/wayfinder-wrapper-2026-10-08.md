# Wayfinder source and wrapper migration - 2026-10-08

Status: implemented, tested, independently reviewed, and owner-verified for
7fbda73 on 2026-10-08 after alignment recheck.
Review base: 192344e. After conditional triage acceptance, the user explicitly
authorized the next skill. Only wayfinder migrates in this changeset.

## Source and local comparison

Historical pin: 0ab1b63a410a03d3627979a109c8695de27af954.
Approved pin: 6fd947921b935b7e1e69293a200400f0fdd5c15f.
Complete subtrees were independently fetched. Both contain SKILL.md and
agents/openai.yaml; both files are byte-identical between pins. There is no
upstream method change in this migration.

All approved bytes are preserved under references/upstream. Only SKILL.md is
renamed UPSTREAM.md under ADR-0009. UPSTREAM.json preserves original names and
hashes; PROVENANCE.md includes the upstream root MIT notice. Public frontmatter
is unchanged. Added public host metadata matches upstream and disables implicit
invocation. The plain source has no companion documents beyond host metadata.

The previous local entry changed one missing-tracker instruction inline. The
wrapper now restores the entire raw source and loads LOCAL-INTEGRATION first.
Project pointers govern tracker/wayfinding operations, triage, glossary paths,
claims, closure, and publication authority. Missing operations are established
before writes instead of inventing tracker configuration from the source fallback.
Research branches/assets must follow the target project's VCS rules. This is a
local boundary, not a new research or Perforce orchestration method.

Required local dependencies are agentic-workflow, grilling, domain-modeling,
research, and prototype. Copy users supply them separately; the wrapper checks
the relevant files before dependent steps. They retain their current migration
stage. The upstream map, fog, frontier, ticket types, claim order, one-ticket
rule, human exchange and research exception remain unchanged.

## Package checks

- All 26 verifier acceptance tests passed. Independent source verification:
  nine imported bundles, 16 declared pending imports, four local skills.
- All six existing CI script gates and both offline Claude manifest validations
  passed. Claude runtime remains deferred.
- skills CLI 1.7.1 copy installation for Codex, Claude Code and OpenCode passed;
  both resulting package trees matched repository hashes exactly.
- Disposable Git index and core.autocrlf=true checkout preserved raw source bytes.
- Fresh Codex skills/list discovered the public wrapper; the implicit prompt
  omitted wayfinder. Native slash UI was not tested here.
- OpenCode debug skill found the wrapper/source link with the pilot's explicit-only
  host rule in an isolated profile. No new OpenCode model request ran; the package
  does not install host configuration.

## Runtime fixtures and outputs

Six fresh Codex CLI sessions used the configured model in disposable Git fixtures.
Each direct/wrapped pair had identical prompts and project inputs except the
wayfinder package. Direct packages contain both original source files. Shared
project context and dependencies remain constant. Wrapped packages exactly match
the candidate repository package.

The map's destination is an importer decision plan, not implementation. A local
CLI exposes map, frontier, individual ticket, claim, and resolve operations.
Resolve atomically writes a comment, closes a ticket, and adds a named map pointer.
The CLI stores local native blocker relationships and filters the frontier.
This validates using a supplied tracker contract, not implementing a tracker or
proving live provider behavior. Driver identity is fixture-dev; another developer
already owns one ticket and must remain untouched.

| Case | Seconds | Observed result |
| --- | ---: | --- |
| task-wrapped | 98.206 | Claim task, inspect CSV, record facts, resolve only that ticket. |
| task-direct | 114.485 | Same facts and tracker outcome. |
| hitl-wrapped | 78.178 | Claim decision ticket, ask choice, leave it open. |
| hitl-direct | 82.13 | Same claim/state, options and recommendation. |
| missing-wrapped | 71.641 | Missing tracker operations reported; no writes. |
| small-wrapped | 78.756 | No map needed; asks how to proceed; no writes. |

All six exit 0; file inventories and Git HEADs were checked. The task pair adds
one answer file and changes only tracker.json. The human-decision pair changes
only tracker.json; both output files have identical hashes. Guard cases change
nothing. Source CSV, glossary, application files, other tickets and other claims
remain unchanged. No implementation, commits, remote publication or subagents ran.

Actual task traces show claim T-1 completes before the first source.csv inspection.
Both return three data rows (excluding header) and two distinct external IDs.
Both record a resolution comment and named context pointer, preserve map destination,
fog and scope, leave duplicate handling unanswered, and stop after one resolution.
The wrapper counts through Python csv; direct uses PowerShell Import-Csv. Answer
filenames, prose and map gist differ. Those are compatible execution choices,
not byte-identical outputs. Final responses and map pointers use issue names.
Initial narration in both direct and wrapped runs uses bare M-1, which misses
the upstream requirement to name issues in all human-facing narration. This is
a shared presentation defect, not evidence of complete instruction compliance.
The tested task outcomes align; the naming requirement is not fully satisfied.
No source rewrite is introduced for this observation.

The human-decision pair claims Choose duplicate handling, loads local grilling
and domain-modeling, asks reject-import versus keep-first, recommends rejection,
and waits. No answer is invented and no resolution/comment/map update occurs.
Direct also presents an input-question UI item; wrapped asks in its final text.
Both preserve the human decision boundary. The user did not choose an option.

The missing-config case reports the missing tracker document and asks for its
path or operations. It does not use upstream's local-markdown fallback to create
an alternate tracker. The small-work case accepts the settled scope, explains
that no map is needed, and asks how the user wants to proceed without doing the
rename. This is not a test of new-map creation with unresolved fog.

Coverage limits: existing-map task and human-decision paths, missing configuration,
and the no-map boundary are tested. Full chart/create-then-wire flow, research
subagent fan-out, research Git branches or P4 artifact routing, prototype execution,
fog graduation, concurrency races, live tracker API permissions, and every future
planning judgment are not proved here. Source preservation is not a claim of
complete runtime equivalence. Claude runtime remains deferred.

## Evidence and reviews

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-wayfinder-migration-20261008

Source comparisons, prompts, baseline hashes, traces, final messages, tracker
state, answer files, copy/discovery logs and checkout results are retained there.
verification.json records changed-file/output hashes, events and unchanged HEADs;
package-checks.json records package checks. Trace hashes:

- task-wrapped: `5fb2b5860480fb23aa1a3291b20b395585dda9435e505211f0084d3236631a42`
- task-direct: `f43700b30c6e8174dac79c8381e59666af4c2dc552c80aeac19186c33c5fb5db`
- hitl-wrapped: `8bfd1825ee268abb8a706980da8150525c5823576c41232418b45d07044af18f`
- hitl-direct: `ac9303a5d5570810e07ca68cd36f24d0fcbbfddbcddcccdfc86c498a2dca05d3`
- missing-wrapped: `4011991fe8724f47b16423beb15094700f0d20ac0d0968964f4dd184df7e31da`
- small-wrapped: `21a78af26807d2c28bc1a385ae252793f8ce335cea774087a6fc46ec5ba35f6e`

Standards review: GREEN, zero findings. Spec review found one P3 overstatement
about named references; the report now records the shared bare-ID narration
and limits the pass claim. No implementation defect was found. Final Spec recheck is GREEN with zero open
findings. Standards has zero findings. The staged whitespace check passed.
Owner verification is recorded below.
No push, PR, merge, release, or consumer update is included.


## Alignment recheck and owner acceptance

The owner requested alignment testing, conditional verification, and continuation
to the next skill. The existing actual direct/wrapped executions were rechecked:
task facts, claims, one-ticket resolution, map pointers, and the human-decision
pause align. Package/source equality, all six trace hashes, output hashes,
changed-file inventories, unchanged HEADs, and paired input equality match the
recorded evidence. alignment-recheck.json records this fresh check of existing
executions; no new model call was needed.

Result: PASS within the stated scope. Under that conditional approval, 7fbda73
is owner-verified. The shared bare-ID presentation defect and all other test
limits remain documented; this acceptance does not assert full instruction
compliance. Claude runtime remains deferred.
