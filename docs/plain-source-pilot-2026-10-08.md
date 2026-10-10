# Plain-source packaging pilot - 2026-10-08

**Status:** Pilot complete; first production conversion implemented, reviewed,
and verified as OK by the owner on 2026-10-08 (commit 23c01bf).
The earlier sections record the disposable pilot; production evidence is below.
ADR-0008 is retained as history and narrowly amended by ADR-0009. Consumer
installations remain unchanged. Claude runtime remains deferred.

## Candidate and scope

The candidate uses codebase-design at its existing approved source revision,
`6fd947921b935b7e1e69293a200400f0fdd5c15f`. The public `SKILL.md` is a local
wrapper. The complete upstream subtree is under `references/upstream/`, with
only the original `SKILL.md` packaged as `UPSTREAM.md`. All original bytes,
frontmatter, and companions remain unchanged. The wrapper loads the shared
local integration contract and explains how upstream `SKILL.md` links map to
`UPSTREAM.md`.

The fixture includes a draft source record with `pathMap`. At pilot time, the
production verifier did not support that draft schema. The pilot checked
the layout directly; the production follow-up below adds verifier support.
Fixture provenance was copied from the ZIP package and is not release-ready.

The synthetic dispatch project uses legacy `CONTEXT.md`. Its terms are
RouteCard, DropSlot, SlotLedger, and DispatchSlip. Required behavior includes
idempotent reservations and recovery after a reservation succeeds before local
persistence. No real consumer project is involved.

## Mechanical and installation evidence

| Check | Result |
| --- | --- |
| Source integrity | PASS: all four files match the approved manifest and the independently extracted upstream subtree, including complete inventory. |
| Discovery entry count | PASS: one `SKILL.md` in the candidate package; no alias or nested entry. |
| Companion links | PASS under the explicit filename mapping. Literal `SKILL.md` back-links still do not resolve in ordinary Markdown viewers. |
| Normal copy install | PASS: skills CLI 1.7.1 copied the candidate and agentic-workflow dependency for Codex, Claude Code, and OpenCode. Both `.agents/skills` and `.claude/skills` copies match every candidate file by hash. This is not Claude runtime evidence. |
| Copy upgrade | PASS: installing plain files over the ZIP package produced the exact candidate inventory, with no stale archive. |
| Copy rollback | PASS: reinstalling the ZIP package produced its exact original inventory, with no stale reference directory. |
| Codex plugin install | PASS: normal CLI installation of uniquely named `myst-plain-pilot@myst-plain-pilot-20261008`; the installed cache matches the whole disposable plugin by hash. |
| Codex 0.160.1 discovery | PASS: fresh app-server discovery exposes the copy wrapper and namespaced installed-plugin wrapper. Debug prompt inspection includes the plugin entry in the automatic catalog. |
| OpenCode 1.18.35 discovery | PASS: three fresh `debug skill` processes selected the public wrapper, not the upstream reference. XDG state was isolated. |
| Existing ZIP source audit | No nested `SKILL.md` entries or `SKILL.md` references in the inspected Python, shell, PowerShell, JavaScript, or TypeScript members of the five migrated bundles. This is a bounded audit, not a guarantee for future imports. |

The restricted Codex discovery process initially omitted user-installed plugins.
Repeating discovery with access to the normal user profile exposed the expected
namespaced entry. That first result was not treated as a package failure.

## Runtime evidence

Codex tests use the configured model, `gpt-6.1-sol`, in fresh read-only sessions.
They send synthetic project content, skill files, and normal Codex session
context. This is not an isolated model benchmark or a token-cost comparison.

| Case | Observed result |
| --- | --- |
| Installed plugin, explicit request | PASS: read the installed wrapper, shared contract, plain upstream entry, and deepening companion. Used legacy CONTEXT.md and recommended the correct remote-owned SlotLedger seam with HTTP and in-memory adapters. |
| Copy, automatic selection | PASS: neither the request nor AGENTS.md named codebase-design. The model selected the local wrapper, read the contract and deepening companion, explicitly resolved its SKILL.md back-link to UPSTREAM.md, and used CONTEXT.md. |
| Missing local dependency | PASS for stopping before applying the method: reported absent agentic-workflow/LOCAL-INTEGRATION.md and did not install or substitute another skill. It did read the upstream reference while investigating; this is not evidence of stopping before every source read. |
| Conflicting vocabulary | PASS: with conflicting CONTEXT.md and GLOSSARY.md and no authoritative pointer, gave provisional read-only advice and requested an authoritative mapping before any vocabulary write. |
| Full alternative-design workflow | PASS for the exercised behavior in a normal fresh session: loaded both companions, created three independent design agents, compared their alternatives, and recommended a single-card operation with a batch companion. This is not a claim of exhaustive adherence to every presentation instruction. |
| OpenCode runtime | PASS for packaging and the exercised local mapping: after explicit owner approval, OpenCode 1.18.35 with deepseek/deepseek-flash used its native skill tool to load the wrapper, read the plain upstream entry, deepening companion, shared local contract, CONTEXT.md, and dispatch.py. Exit 0 in 15.9 seconds; no tool errors or workspace changes. Answer-quality limits are recorded below. |
| Claude runtime | Deferred by owner; not run. |

The first automatic-selection fixture named the skill in AGENTS.md, so it was
not used as proof of autonomous selection. A fresh repeat removed that name and
passed. All five Codex fixture workspace inventories matched their before/after
hashes after the runs completed.

The full design trial initially ran with `--ephemeral`. Codex reported
`failed to load model context ... no rollout found for thread id` when spawning
a design agent. That run did not establish a full workflow pass and was stopped.
A normal fresh session, without ephemeral mode, successfully created three
design agents and completed in 184.932 seconds with exit 0. This is a test-harness
compatibility finding; neither the wrapper
nor the upstream method was changed to avoid the required delegation.

The initial restricted runtime attempt could not reach the model service. The
authorized retry used network access. Incidental no-match search and non-repo
Git-probe exits are retained in the traces; source/reference reads succeeded.

### OpenCode approved follow-up

The owner explicitly approved the DeepSeek test after automatic approval review
had blocked it for missing destination-specific authorization. The run used the
existing account, isolated XDG state, and a synthetic project. Credentials were
passed only through the subprocess environment. File edits, shell commands,
delegation, and web fetching were denied for this focused read-only test.

Two startup attempts failed before model execution because the harness selected
`deepseek/deepseek-v4-flash`, which this installed host did not expose. Diagnostic
logging identified `ProviderModelNotFoundError`. The supported identifier
`deepseek/deepseek-flash` completed successfully. The first startup also inserted
OpenCode's schema field into the disposable config; the final harness supplies
that field before taking its baseline. All final workspace hashes match.

The native skill response contained the public wrapper and its source mapping.
The trace then shows successful reads of DEEPENING.md and UPSTREAM.md, so the
companion's original SKILL.md back-link reached the mapped entry without a ZIP
reader or a missing-file error. The model used the authoritative legacy terms,
classified SQLite as local-substitutable and SlotLedger as remote but owned,
and recommended HTTP and in-memory adapters with same-key retry behavior.

This is a packaging and routing pass, not a perfect design-answer score. The
answer called the deletion test a failure while saying deletion would spread
complexity back to callers; that reverses the source's criterion. It also added
an unexplained "Swiftie-style SQLite" phrase. Those answer defects are retained
as evidence. This single run cannot attribute them to packaging or establish
equivalence to direct upstream invocation. No source or wrapper workaround was
added for them.

## Evidence and rollout limits

Evidence is in `%TEMP%/myst-plain-source-proposal-20261008/pilot/`: the disposable
marketplace, fixture prompts, before/after manifests, installer logs,
`codex-discovery.json`, `codex-prompt.json`, three OpenCode discovery snapshots,
`source-audit.json`, runtime traces, and reproducible local harness scripts.
Temporary evidence can expire. This report preserves the findings and limits.

The layout keeps ordinary file reads and visible source text. The candidate
wrapper is 921 bytes versus 1,658 bytes for the current ZIP wrapper. This is a
file-size comparison, not measured token savings. Wrapper and shared-contract
reads remain necessary. These samples do not prove exact output equivalence or
all-host/future-version compatibility. Native slash-menu UI interaction was not
tested separately from catalog registration and explicit runtime requests.

The authorized production follow-up records the filename exception in a new ADR,
implements and tests manifest mapping, updates provenance and documentation,
and reviews the first converted skill as one changeset. Preserve the existing
per-skill verification gates; the remaining catalog is not converted by this
changeset. The TDD owner-verification item remains separate.

## Completion note

At the end of the disposable pilot, the full normal-session design trial and four focused Codex cases completed
successfully. Final before/after workspace hashes are unchanged for every case.
The temporary plugin and marketplace were removed through the normal CLI.
The test registration and installed cache are absent; the regular
`myst-dev-kit@myst` plugin remained enabled. That pilot changed no production
skill files; the subsequently authorized conversion is recorded below.

| Completed trace | SHA-256 |
| --- | --- |
| copy/trace.jsonl | f7f97d7a67da5ff9fc7fbfb2f392821839a66e89b875b73dd53a4a1a0e0fb214 |
| plugin/trace.jsonl | 13e835d0e2f33f58d2d946d8975d21c449a925ad9f99589bd286b21f66e1ca45 |
| implicit/trace.jsonl | 02007a86366b005e0b5c5f143c179bb254bdaa7142084dbdcf752ad5d8bece3e |
| missing-dependency/trace.jsonl | edb1a93766dff444704b8c6096100ab36b4aec0134b29d2e90fd7a377a0b40f9 |
| ambiguous-domain/trace.jsonl | 356a96e2a3d3da5562d4b32131d9543fd8738a4a11709f3c3255b1249b93877b |
| opencode/trace.jsonl | 5f97c6d7c7aab0804fc90d4747153dce4fdc6a2ddd0c0ec2e922dbaaba4d81b9 |

**Conclusion:** the pilot supports adopting the plain-reference layout for this
skill, with the production manifest/verifier and documentation work below.
The approved OpenCode runtime check also passed for packaging and local mapping,
with the answer-quality limits above. Claude runtime remains deferred.

## Production conversion, 2026-10-08

Fixed review base: `13fd17f8123b4960deddd2b1ca3e7aa8c948dad1`.
Only codebase-design changes source layout. Its source pin, original four-file
inventory, all upstream bytes, public metadata, and dependencies remain the same.
The final wrapper and four source files match the runtime-tested candidate
byte-for-byte. Provenance now describes plain files and the filename exception.

ADR-0009 records the accepted rule. Version 2 records require exactly
`{"SKILL.md": "UPSTREAM.md"}` and a directory; all other names remain unchanged.
The verifier maps packaged paths to original inventory keys, then retains its
independent source comparison. Version 1 directory and ZIP support remains.
The schema and guide document the same narrow contract.

### Verification

- All 26 acceptance tests passed, including seven new mapped-package tests.
  Negative cases cover invalid/unsafe mappings, missing mapping fields,
  destination collisions including case-only collisions, another discovery
  entry, missing/extra files, changed bytes, and edits hidden by changed hashes.
- Independent network verification passed: five imported bundles, 20 declared
  pending imports, and four local skills. This included the unchanged ZIP
  packages and their pinned Git/Hammer sources.
- All six repository CI script checks passed: Windows PowerShell 5.1 parsing,
  ASCII/BOM, frontmatter, manifest versions, install commands, and dead references.
  The PS 5.1 runner needed a process-only execution-policy override for the local
  test scripts; no persistent policy changed.
- Offline plugin and marketplace manifest validation passed through the installed
  Windows x64 Claude executable. Its npm shim pointed to an incompatible binary;
  the platform executable resolved that tooling issue. No Claude model ran.
- A disposable Git index and checkout with core.autocrlf=true preserved all four
  source files exactly. Their scoped `text` attribute is unset.
- Fresh production copy installs for Codex, Claude Code, and OpenCode match the
  complete package and its local dependency. Each codebase-design copy contains
  one SKILL.md. This is install evidence, not another Claude runtime claim.
- git diff --check passed. No additional model runs were needed: the final method
  wrapper and original source match the already tested pilot.

Production check artifacts are under
`%TEMP%/myst-plain-source-proposal-20261008/production-checks/`.

### Standards review

GREEN: no actionable findings. The independent reviewer confirmed the source
contract, version 1 compatibility, narrow mapping, glossary/companion routing,
unchanged invocation metadata, attribution, and byte-preserving Git attributes.
No baseline maintainability smell required a change within this scope.

### Spec review

GREEN: no actionable findings. The independent reviewer compared every plain
source file against the approved base archive and confirmed exact bytes, source
pin, complete inventory, local routing, and metadata. Only codebase-design is
converted; the verifier rejects invalid mappings and retains independent checks.

Review totals: Standards 0 findings; Spec 0 findings. The owner verified this
conversion as OK on 2026-10-08 and authorized continuation. No push, PR, release, or consumer
update occurred. The separate TDD verification item remains outstanding.
