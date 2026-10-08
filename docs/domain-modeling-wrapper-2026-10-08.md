# Domain-modeling source and wrapper migration - 2026-10-08

Status: implemented, tested, and independently reviewed; owner verification pending.
Review base: 6aa0be2. Only domain-modeling migrates in this changeset.

## Source and local integration

Complete source was independently fetched at historical Matt pin
0ab1b63a410a03d3627979a109c8695de27af954 and approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f. Four files exist at each pin.
The update renames CONTEXT-FORMAT.md to GLOSSARY-FORMAT.md and replaces
CONTEXT filenames with GLOSSARY names in the entry and format guide. The guide's
Context Map heading becomes Glossary Map. Exact replacement comparisons confirm
there are no other method changes. ADR-FORMAT.md and agents/openai.yaml are
byte-identical across pins. All three previous local files matched the old source.

The complete approved four-file source is preserved in references/upstream;
only SKILL.md is packaged as UPSTREAM.md under ADR-0009. Old root companions are
removed after byte checks; current companions stay beside the raw entry. Both
are linked directly by the wrapper. PROVENANCE.md includes the upstream MIT notice.
The source inventory records original names and hashes. Consumer documents are
not renamed by this change.

Myst's wrapper loads LOCAL-INTEGRATION and selects project domain pointers,
root/scoped/custom glossary paths, and project ADR locations. Source and format
guide naming defaults map to those paths. Missing or conflicting ownership is
resolved before writes. agentic-workflow is the declared copy dependency. The
public trigger now mentions both CONTEXT.md and GLOSSARY.md, retaining automatic
invocation. Public host metadata matches upstream. No domain or ADR method is
rewritten and no consumer readiness is inferred from this package migration.

## Completed package checks

All 26 verifier acceptance tests passed. Independent source verification passed
for ten imported bundles, 15 declared pending imports, and four local skills.
All six existing CI script gates and both offline Claude manifest validations
passed. skills CLI 1.7.1 copied the complete package for Codex, Claude Code, and
OpenCode; both resulting trees matched repository hashes exactly. A disposable
core.autocrlf=true checkout preserved all raw bytes.

Fresh Codex discovery selected the wrapper, and its implicit prompt catalog
included domain-modeling. OpenCode debug skill found the wrapper/source link
with an empty isolated host config, allowing normal model invocation. These
checks do not prove spontaneous model selection or native slash UI behavior.
No new OpenCode model execution or Claude runtime test was run.

## Runtime status

Synthetic fixtures compare direct and wrapped legacy glossary edits, three scoped
glossary files using legacy/new/custom names, and a custom ADR directory with
existing number 0003. Guard fixtures cover conflicting root glossaries and no
established glossary ownership. Direct/wrapped prompts and project inputs match
except for the domain-modeling package. Shared project instructions and the
agentic-workflow package stay constant. Calls explicitly select each entry.

Nine attempts covered eight cases. The original direct legacy case stalled after
reading the correct source/format and announcing the correct target. It timed out
at 360.022 seconds without a write. The trace does not establish why it stalled.
A fresh retry used identical prompt and baseline hashes and completed successfully.
The timeout is retained as incomplete evidence, not counted as a pass.

| Selected case | Seconds | Observed result |
| --- | ---: | --- |
| legacy-wrapped | 87.126 | Only CONTEXT.md updated with the agreed term. |
| legacy-direct | 75.96 | Clean retry; same glossary bytes as wrapped. |
| scoped-wrapped | 79.173 | Only the three mapped glossary files updated. |
| scoped-direct | 73.195 | All three output files byte-identical to wrapped. |
| adr-wrapped | 82.742 | Only ADR 0004 added to the custom project folder. |
| adr-direct | 83.384 | Same accepted decision and numbering; different prose. |
| conflict-wrapped | 99.765 | Conflicting glossary definitions reported; no writes. |
| missing-wrapped | 58.02 | Asks for filename/location before first glossary; no writes. |

All eight selected runs exit 0 and preserve their Git HEADs. Full before/after
inventories show only the expected document edits. All final wrapped packages
match the repository candidate exactly; direct packages match the complete source
inventory. Paired prompts and all project baseline files match outside the skill
package. The direct legacy evidence is in retry-1/legacy-direct; other selected
runs use their top-level case folders.

The actual glossary files were read and compared. The legacy pair produces
byte-identical CONTEXT.md, retaining Slot and adding the same DeliveryHold
meaning, Booking distinction, and _Avoid_: SoftBooking. Neither writes a new
GLOSSARY.md, adds programming details, or creates an ADR.

The scoped pair follows Docs/team/domain.md to Records/domain-map.md and resolves
links relative to that map. It updates only src/ordering/CONTEXT.md,
src/billing/GLOSSARY.md, and Records/inventory-terms.md. All three files are
byte-identical across the pair. Definitions are short, use the selected names
and avoided synonyms, and preserve existing vocabulary. Non-authoritative root
CONTEXT.md and GLOSSARY.md, the map, pointer, and all unrelated files are unchanged.
This tests explicit map authority over conflicting root naming families.

Both ADR outputs were read. Each uses the next number, 0004, in docs/decisions/
(the physical directory is Docs/decisions on this Windows fixture), carries
accepted status, and records immutable PostedCharge amounts, append-only
corrections, rejected in-place editing, audit value versus projection complexity,
and data/API migration cost. The wrapper uses three summary sentences; direct
adds a Consequences section. Meaning and scope align; text is not identical.
Both preserve the glossary and prior ADR and perform no implementation.

The conflict case reports different Reservation definitions in CONTEXT.md and
GLOSSARY.md, asks which owns the vocabulary, and makes no edit. The missing case
asks for an agreed filename/location instead of choosing upstream's new-project
GLOSSARY.md default. Both keep the candidate term in the response only.

These are bounded tests of settled terms, document paths, and an approved ADR.
They do not prove equal open-ended modeling judgment, automatic skill selection,
code/glossary contradiction detection, every ADR-offer decision, an in-place
consumer migration, or downstream caller regression coverage. The brief waits
on missing ownership are intentional local behavior. No source-method rewrite
was needed. Some local tool starts needed the documented sandbox-helper retry;
the timeout is separate from those successful retries. Claude runtime remains
deferred. No external publication, commits inside fixtures, or subagents ran.

## Evidence and review

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-domain-modeling-migration-20261008

Source comparisons, fixtures, traces, final messages, document outputs, baseline
hashes, discovery/copy/checkout checks and package-checks.json are retained there.
verification.json records the selected outputs, allowed changes, unchanged HEADs,
and the separate original timeout. Trace hashes:

- legacy-wrapped: `d571f4475f5fbded3f2c020f5736614658b6855c906b6212c538d01f7ffd94a3`
- legacy-direct: `5bb863ac98b3bb0335fac20a0846aee02db3a4655d73965cfe0dcde11a26b1ed`
- scoped-wrapped: `fe71e686a5c917759f7ce57f2f8602ace90fdc9445ce8e4fd231716393a9a516`
- scoped-direct: `9a53a48db319d6ed7bde2a0183f578bcae9dd99593b2bf5bda145b2382dd0b35`
- adr-wrapped: `8ab3cc86b1d88a6963233e12bcdf4b13e0e1dbebb6d28bd27776c205619a2382`
- adr-direct: `bdde7658eedbf3b13586a01af485692f663e0fe1c926de7a2d927845f369a144`
- conflict-wrapped: `e5e9221f8141f2984b6508792cd6e642bedba243f5b91cfde598e678242fdd77`
- missing-wrapped: `de20901e86e03a86518418e6b68270ee91b2b66b55d061c57cff4f4c4145e947`
- initial-legacy-direct: `76648c825f122f8124863f0cc72c150f733494746aa7414317dfed2979820143`

Final Standards review: GREEN, zero actionable findings. Final Spec review:
GREEN, zero actionable findings. Both reviewed the actual outputs and evidence
limits. The complete staged whitespace check passed. Owner verification remains
pending.
No publication, implementation, or consumer migration is included.
