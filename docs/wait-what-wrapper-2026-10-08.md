# Wait-what source and wrapper migration - 2026-10-08

Status: implemented, tested, and independently reviewed; owner verification pending.
Review base: 3c85c96. Only wait-what migrates in this changeset.

## Source and local integration

Complete source was independently fetched at historical Matt pin
0ab1b63a410a03d3627979a109c8695de27af954 and approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f. Both contain two files: SKILL.md and
agents/openai.yaml. The only update replaces CONTEXT.md and CONTEXT-MAP.md with
GLOSSARY.md and GLOSSARY-MAP.md. Source metadata is unchanged. The previous
local entry matches the historical source exactly.

Both approved files remain byte-for-byte intact under references/upstream.
SKILL.md alone maps to UPSTREAM.md under ADR-0009. UPSTREAM.json records complete
original names and hashes. PROVENANCE.md includes attribution and the MIT notice.

The wrapper loads LOCAL-INTEGRATION and maps glossary and map references to the
project's authoritative root/custom/scoped domain documents. agentic-workflow is
the required copy dependency. The public trigger and user-only invocation remain
unchanged; public host metadata matches upstream. No re-explanation instruction
is rewritten and no consumer glossary is renamed.

## Package and host checks

All 26 source-verifier acceptance tests passed. Independent source verification
passed for thirteen imported bundles, twelve declared pending imports, and four
local skills. All six current CI script gates and both offline Claude manifest
validations passed. skills CLI 1.7.1 copied the complete package for Codex, Claude
Code, and OpenCode; both resulting trees match repository hashes. A disposable
core.autocrlf=true checkout preserved every source byte.

Fresh Codex discovery selected the wrapper and excluded wait-what from the
automatic prompt catalog. Public metadata retains allow_implicit_invocation:
false and the entry retains disable-model-invocation: true. OpenCode debug skill
found the wrapper with an isolated local setting:

```json
{"permission":{"skill":{"wait-what":"deny"}}}
```

This uses the [tested handoff host pattern](handoff-pilot-2026-10-07.md#opencode-invocation-configuration).
The setting enforces user-only invocation on that host and is not installed by
copying the skill folder. This migration checks configuration and discovery;
it does not repeat an OpenCode model execution or prove native slash UI behavior.
Claude runtime remains deferred.

## Direct versus wrapped behavior

Four fresh Codex runs compare legacy root glossary use and scoped map routing.
Both pairs have identical prompts and project inputs outside the wait-what
package. Direct runs use the complete approved source with its original entry
name. Wrapped runs use the exact repository candidate. Both routes receive the
same project instructions and agentic-workflow dependency. Invocation is explicit.

| Case | Seconds | Observed result |
| --- | ---: | --- |
| legacy-wrapped | 34.667 | Explains Hold, Booking, and Expiry from CONTEXT.md. |
| legacy-direct | 27.866 | Same flow and domain meaning; different wording. |
| scoped-wrapped | 45.176 | Follows custom map to warehouse terms; correct Claim meaning. |
| scoped-direct | 39.227 | Same path, terms, and proposed behavior. |

All four exit 0. Full before/after file inventories are identical and every
fixture HEAD is unchanged. Tested wrappers match the repository candidate;
direct packages match the complete approved source. Actual successful read
commands confirm that wrapped runs load the shared contract and raw source.
No failed or timed-out model attempt is excluded. Each initial shell start hit
the known sandbox-helper setup error and succeeded on the normal bounded retry.

Both legacy replies give brief context and the same three steps: a Hold keeps
the room for the guest, confirmation before Expiry creates a Booking, and lack
of confirmation ends the Hold so the room becomes available again. Both say the
flow is proposed and not implemented. One uses action-led bullets; the other
uses glossary terms as labels. Neither invents payment or cancellation behavior.

Both scoped traces read Docs/domain-index.md, then Records/term-map.md, then
scopes/warehouse/CONTEXT.md. Relative links are resolved from their declaring
files. The map also names a billing GLOSSARY.md with a different Claim meaning;
root CONTEXT.md and GLOSSARY.md contain old insurance/payment examples. Both
runs select the warehouse glossary and avoid those unrelated meanings.

The scoped replies explain Claim as stock held while an Order awaits confirmation,
Allocation as the confirmed assignment, and Release as making stock available if
confirmation fails. Both retain proposal status. They differ only in bolding
Order and adding the adjective required before stock; after those two changes,
the replies are byte-identical. No glossary, map, code, or tracker file is written.

The actual replies use short sentences, simple verbs, and consistent project
terms. This is a qualitative style review, not a measured ASD-STE100 compliance
score. The tests support semantic alignment for these two supplied explanations.
They do not prove identical prose for all inputs, recovery of missing conversation
context, missing/conflicting ownership guards, every scoped map layout, native
slash UI, or automatic host routing. No source-method rewrite was needed.
No publication, fixture commit, consumer migration, or subagent ran in these
runtime fixtures.

## Evidence and review

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-wait-what-migration-20261008

Source comparisons, complete fixtures, before hashes, traces, final replies,
and package/discovery logs are retained there. verification.json and verify.py
check paired inputs, exact package identity, glossary reads, reply hashes,
unchanged inventories, and fixture HEADs. package-checks.json records packaging
and host checks.

Trace SHA256:

- legacy-wrapped: `d5117f6e55d5b07445f03940139e7f907c9d828543b68094e95b27785bd986e8`
- legacy-direct: `95ba4de1eaed1f148fdb01b397524d4cc337657c0b9c29b77ffea1e8d959b2ac`
- scoped-wrapped: `98e56b7565d406ce68ea72109f1f3d348760c94c0d42a36f5e99080c56d51eb1`
- scoped-direct: `e47b03c8653c92fb4495029db8bb5a73fba7e88ed7ff4d64ba3881af56a95e55`

Final Standards review: GREEN, zero actionable findings. It confirmed source
ownership, user-only metadata, glossary routing, and honest style/host claims.
Final Spec review: GREEN, zero actionable findings. It checked actual replies,
trace reads and hashes, unchanged inventories/HEADs, and candidate identity.
The complete staged whitespace check passed. Owner verification remains pending.
No push, PR, merge, release, or installed-copy update is included.
