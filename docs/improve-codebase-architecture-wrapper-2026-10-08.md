# Improve-codebase-architecture source and wrapper migration - 2026-10-08

Status: implemented, tested, independently reviewed, and owner-verified for
e123a5f on 2026-10-08 after alignment recheck.
Review base: 9933b03. Only improve-codebase-architecture migrates here.

## Source and local integration

Complete source was independently fetched at historical Matt pin
0ab1b63a410a03d3627979a109c8695de27af954 and approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f. Both contain three files: SKILL.md,
HTML-REPORT.md, and agents/openai.yaml. The only source update replaces all
CONTEXT.md references with GLOSSARY.md. The report companion and metadata are
unchanged. Both previous local files match the historical source exactly.

All three approved files remain byte-for-byte intact under references/upstream.
Only SKILL.md maps to UPSTREAM.md under ADR-0009. The old root report guide moves
beside the raw source after byte comparison. UPSTREAM.json records complete names
and hashes; PROVENANCE.md includes source attribution and the upstream MIT notice.

Myst's wrapper loads LOCAL-INTEGRATION, maps domain reads/writes and ADR locations,
uses target VCS history for history-based scoping, and routes dependency calls
through Myst entries. Required copy dependencies are agentic-workflow,
codebase-design, grilling, and domain-modeling. The report guide has a direct
wrapper link. The trigger, user-only invocation, and source host metadata remain
unchanged. The three-phase exploration/report/interview method is not rewritten.
No consumer documents are renamed.

## Package and host checks

All 26 source verifier acceptance tests passed. Independent source verification
passed for twelve imported bundles, thirteen declared pending imports, and four
local skills. All six current CI script gates and both offline Claude manifest
validations passed. skills CLI 1.7.1 copied the complete package for Codex, Claude
Code, and OpenCode; both resulting trees match repository hashes. A disposable
core.autocrlf=true checkout preserved every source byte.

Fresh Codex discovery selected the wrapper; its automatic prompt catalog excluded
improve-codebase-architecture. Public metadata retains allow_implicit_invocation:
false as well as disable-model-invocation: true in the entry. OpenCode debug skill
found the wrapper in an isolated profile with this explicit local setting:

```json
{"permission":{"skill":{"improve-codebase-architecture":"deny"}}}
```

The setting follows the [tested handoff host pattern](handoff-pilot-2026-10-07.md#opencode-invocation-configuration):
block implicit skill-tool use while retaining explicit commands. Copying the skill
does not install that host setting. This step checked discovery/configuration,
not another OpenCode model execution or native slash UI. No Claude runtime ran.

## Runtime comparison and harness correction

Four cases compare direct and wrapped explicit-scope scans and continuation into
a selected-candidate interview. Paired project inputs and prompts are identical
outside the architecture skill package. Direct runs use the complete approved
source with its original entry name. Both routes use the same installed Myst
dependencies and fixture instructions, including authoritative Records/CONTEXT.md
and Records/decisions/ pointers. Calls explicitly invoke this user-only skill.

Initial ephemeral sessions could not spawn the required exploration agents:
Codex reported that no rollout existed for the parent thread ID. All four returned
exit 0 with partial fallback results, but they are excluded from passing evidence
because required delegation failed. Their traces and artifacts remain intact.
This was a harness limit, not evidence for changing the skill's method.

Four clean retries use identical prompt and baseline file hashes. Only ephemeral
execution was disabled, allowing normal session persistence. Actual session logs
record successful exploration-agent dispatch for both scans and pricing-fact
agents for both interviews. No collab spawn error appears in these retries.
The source and final wrapper are the same as in the first attempts.

| Selected retry | Seconds | Observed result |
| --- | ---: | --- |
| scan-wrapped | 223.743 | One Strong Order pricing candidate; temp report; waits for choice. |
| scan-direct | 221.257 | Same candidate, constraints, and selection pause. |
| interview-wrapped | 141.565 | Adds agreed Quote term; asks two decisions and waits. |
| interview-direct | 139.608 | Same glossary bytes, recommendations, and wait. |

All four selected retries exit 0 and preserve their Git HEADs. Full inventories
show no workspace edits during either scan. Each interview changes only
Records/CONTEXT.md. All application code, tests, ADRs, and dependencies remain
unchanged. Candidate package hashes match the repository; direct package hashes
match the complete source. Clean retries match their original baseline and prompt.

Both actual reports identify the same friction: two checkout callers duplicate
quantity/Discount validation and pricing order while coordinating three shallow
arithmetic modules. Both select one Strong, in-process candidate: concentrate
that knowledge in a deep Order pricing module. They explain the deletion test,
locality, leverage, tests at the interface, and why no adapter is warranted.
They preserve the Receipt-storage ADR and original receipt audit facts. Neither
proposes a concrete interface or starts implementation before user selection.
Both provide source references, a before/after visual, and a top recommendation.
The HTML layout, prose, evidence detail, and filename differ; meaning aligns.

The headless fixture explicitly replaced native browser opening with an absolute
report path. Parent inspection then rendered both files in headless Edge through
a temporary loopback server. Mermaid rendered in both, page errors were empty,
and neither page had horizontal overflow at 1440px. Full-page screenshots were
visually checked: both diagrams and the recommendation were readable. The in-app
preview tool failed twice at kernel startup; the headless renderer provided the
visual evidence. This does not prove the skill's native OS open command or other
viewport sizes. Report CDN assets require network access when viewed, as upstream
specifies; the runtime fixture itself stayed offline.

Both selected interview outputs add the exact agreed Quote definition while
preserving the existing vocabulary. Their glossary files are byte-identical.
They route through local grilling/domain-modeling entries and ask the same open
frontier: rounding policy and migration compatibility. Both recommend exact
decimal arithmetic, final-total rounding to two decimal places with ties to even,
and preservation of current caller behavior before a separate pricing change.
They use different numeric examples and wording. Both wait for user answers;
neither creates an ADR, repeats the scan, or changes code.

Open-ended advice is not deterministic. The excluded initial interview pair
recommended different tie rules (half-even versus half-up), while still leaving
the choice open to the user. That variation is retained as a limitation; the
successful retry pair is not proof of equal recommendations on every future run.
No speculative wrapper/source rewrite was made to force a preferred answer.

These tests support aligned report and interview behavior for this small,
explicitly scoped example. They do not cover history-based scoping (Git or P4),
multiple-candidate ranking, reopening an ADR, alternative-interface subagents,
all glossary ownership guards, later interview rounds, native report opening,
automatic selection or every downstream caller. Shell-helper startup failures
were retried normally. Claude runtime remains deferred. No publication, fixture
commit, or consumer migration was performed.

## Evidence and review

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-improve-codebase-architecture-migration-20261008

Selected traces, report HTML, extracted report text, final messages, glossary
outputs, and baseline hashes are in retry-1/<case>. Top-level case folders retain
the excluded ephemeral attempts. verification.json and verify.py check package
identity, paired inputs, allowed changes, fixture HEADs, outputs, and successful
subagent dispatch. The record names the exact saved Codex sessions without copying
their full context into this repository. package-checks.json, visual-checks.json,
and screenshots retain the package and rendering evidence.

Selected trace SHA256:

- scan-wrapped: `a1145e4a03785f5ac1600cbea692656c71355f3bc167cb2fece082a851e597d1`
- scan-direct: `22791f58ce1fa1bb3a80696f521648d26b08650ab4170eba0821aa5696710ff9`
- interview-wrapped: `d0b60e1f8a986f22d70ea16468201402e188b1b6e5a8aec39ae247f84b561361`
- interview-direct: `9c79785e4182eb4398d565a1c4cb5f528790d49945130cfa65555e28f8539c3b`

Final Standards review: GREEN, zero actionable findings. It confirmed complete
source ownership, user-only invocation, dependency and companion routing, and
honest evidence limits. Final Spec review: GREEN, zero actionable findings. It
checked actual reports, interviews, output/trace/session hashes, allowed changes,
and unchanged HEADs. The complete staged whitespace check passed.
Owner acceptance is recorded below. No push, PR, merge, release, or installed-copy
update is included.

## Alignment recheck and owner acceptance

The owner requested alignment testing, conditional verification, and continuation.
Existing direct/wrapped executions were rechecked against e123a5f. Paired inputs,
source/wrapper hashes, trace/session/output hashes, permitted file changes,
fixture HEADs, and successful delegation records match the reviewed evidence.
Both reports still recommend the same candidate and preserve the Receipt ADR.
Glossary output bytes and the selected interview decisions still align. Saved
visual results and screenshot hashes were checked; no fresh render was needed.

alignment-recheck.json records PASS within the stated scope. No new model call
was needed. Under the owner's conditional approval, e123a5f is verified. The
excluded ephemeral attempts, advice variation, and coverage limits remain.
Claude runtime is still deferred.
