# Codebase-design source and wrapper migration

Changeset 6, based on local commit 58509c2. This vocabulary skill precedes TDD,
which calls it for interface design. Only codebase-design migrates here.
Verification began on 2026-10-07 and completed on 2026-10-08.

## Original source comparison

The historical source pin is 0ab1b63a410a03d3627979a109c8695de27af954; the selected
new pin is recorded in the skill's UPSTREAM.json. Both original subtrees were
extracted from upstream archives and compared as bytes.

SKILL.md, DEEPENING.md, and agents/openai.yaml are unchanged. DESIGN-IT-TWICE.md
has one change: its existing instruction to include project vocabulary in each
design agent's brief now names GLOSSARY.md instead of CONTEXT.md. It does not
add a new interview, delegation method, or vocabulary requirement.

The archive includes the complete selected subtree with original member names
and byte hashes. PROVENANCE.md carries the full upstream MIT notice.

## Local integration comparison

The previous local SKILL.md and loose companions match the historical upstream
source byte-for-byte. This migration replaces the public method body with a
thin wrapper and moves the originals into upstream.zip. The loose companions
are removed; source-relative links resolve within the archive. The search
`rg -n "codebase-design/(DEEPENING|DESIGN-IT-TWICE)" plugins README.md docs`
returned no matches before this report recorded the command. Callers
such as TDD and improve-codebase-architecture refer to the skill by name.

The public name and description are unchanged. Automatic and explicit invocation
remain available. New local agents/openai.yaml matches the original metadata.
The shared local integration contract maps upstream glossary references to the
project's authoritative domain files, so a legacy CONTEXT.md remains usable.
Copy installs must include agentic-workflow and its shared reference. No
parallel-design orchestration rules are added to the wrapper.

## Discovery and runtime evidence

A fresh Codex CLI 0.160.1 app-server skills/list request discovered the local
codebase-design entry at its wrapper path, enabled with the expected display
metadata. A debug prompt-input inspection included that local entry in the
automatic catalog. The original source is archived, with only one loose
SKILL.md in the package. This checks catalog exposure; it does not prove that
a model will always select the skill automatically.

A fresh ephemeral, read-only gpt-5.5 session at medium reasoning used the actual
wrapper in an isolated dispatch-design fixture. AGENTS.md pointed to legacy
CONTEXT.md; no GLOSSARY.md existed. The fixture defined RouteCard, DropSlot,
SlotLedger, and DispatchSlip, including idempotency and crash-recovery rules.
The prompt asked for alternative interfaces, comparison, and a recommendation.

The wrapped trace shows this sequence:

1. Read the public entry and shared local contract, then the archived SKILL.md.
2. Read both archived companions and the project's CONTEXT.md and dispatch.py.
3. Frame the constraints and dependency categories for the user.
4. Start three independent subagents before waiting for results. Each brief
   includes architecture terms, all four project terms, the domain guarantees,
   and a distinct constraint: small surface, flexibility, or common-caller ease.
5. Collect the designs and recommend a Dispatcher hybrid with a single-card
   method, a batch method, and an internal SlotLedger port with two adapters.

The process completed with exit 0. Packaging, companion loading, legacy-domain
mapping, and independent delegation worked in this sample. However, the public
answer omitted the requested sequential presentation of the three alternatives
and their full comparison. Its initial frame also used a prose sketch rather
than the upstream-requested illustrative code. This is partial method adherence,
not a full workflow pass. The unchanged upstream source requires those steps.
A direct-source control then used the identical prompt, project instructions,
CONTEXT.md, and dispatch.py with the original loose source files. It completed
with exit 0, read the authoritative legacy vocabulary, ran three independent
design agents, and presented the three alternatives before recommending a
web-first hybrid. That directly observed presentation was stronger than the
first wrapped answer. A single pair cannot attribute the difference to the
wrapper or establish output equivalence. No wrapper workaround was added.
An unchanged wrapped repeat used the same prompt and project files. It completed
with exit 0, loaded the same contract/source/companions and legacy vocabulary,
and ran four independent design agents (including the optional ports/adapters
constraint). Its public answer included summaries of all four designs and a
recommendation. Thus the first omission did not recur in that repeat.

The repeat still led with the recommendation, condensed the alternatives, and
used prose rather than code in its initial problem frame. These samples support
loading and useful design execution, not exact presentation order, exhaustive
method compliance, or identical results to direct invocation. The first failure
remains recorded. No source or local method rewrite was made to force a result.

The final wrapper package matches the first runtime-tested copy exactly. The
first wrapped trace contains no file-change events; the direct fixture's full
before/after file-hash manifest is unchanged. The repeated wrapped fixture's
full before/after file-hash manifest is also unchanged.

## Repository checks and review

- Verifier acceptance suite: 19 tests passed.
- All six existing CI script checks passed, including public frontmatter,
  version agreement, install commands, dead references, ASCII/BOM, and
  Windows PowerShell 5.1 parsing.
- The optional skill-creator quick validator could not start because the local
  Python environment lacks PyYAML. The repository frontmatter gate passed.
- Independent source verification passed: four imported bundles, 21 declared
  pending imports, and four local skills.
- The PowerShell ZIP-reader fallback read all four members and matched their
  original decoded text. The Python reader was exercised in the live trace.
- git diff --check passed.

Final independent review against 58509c2:

- Standards: GREEN. Package and completed evidence delta reviewed; no actionable
  standards finding.
- Spec: WARNING. Migration requirements are met, but the wrapped samples show
  partial adherence to upstream presentation steps, as recorded above.
- [DEFERRED] WARNING Spec: presentation adherence remains an owner-verification
  item. The reviewer found no source-boundary defect or incorrect integration
  and advised against a speculative source or wrapper change from these samples.

Owner verification, including these runtime limits, is required before the next
skill migration.
Claude runtime remains deferred until owner notification. No OpenCode runtime
claim is made for this changeset. No push, PR, release, installed-plugin update,
or consumer migration is authorized here.

## Evidence location

Temporary evidence is under %TEMP%/myst-codebase-design-migration-20261007:
old/new source trees, upstream.diff, the MIT notice, discovery.json,
implicit-prompt.json, and the fixture prompt and runtime harness. Temporary
evidence can expire; this report retains the findings and their limits.

| Runtime trace | SHA-256 |
| --- | --- |
| wrapped/first-trace.jsonl | 285da9971deae8de09e1eb18353fac99634d3e2f6264e260ba5c10e28f90a9e9 |
| direct/first-trace.jsonl | ce803672cda324f9f1e69f125d961adaaec04470a1752debcf7ad28f4ce4e51e |
| wrapped-repeat/first-trace.jsonl | bc6b91fed4a053e7e611ccabc7499e2beac0e65adcae447f9fa9c2c91a038dc4 |
