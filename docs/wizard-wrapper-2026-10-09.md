# Wizard source and wrapper - 2026-10-09

Status: implementation, alignment checks, and both independent reviews passed;
owner verified 5b86625 on 2026-10-09 after the alignment artifact recheck.
Review base: 26b7743. This changeset migrates wizard alone.

The former Myst entry and template exactly match the approved Matt source pin.
There is no method delta. The complete subtree contains SKILL.md, template.sh,
and agents/openai.yaml. All three stay whole under references/upstream; SKILL.md
alone maps to UPSTREAM.md under ADR-0009. The local entry maps project setup/CI,
template location, repeatable VCS capture, and authority. The source pin is
6fd947921b935b7e1e69293a200400f0fdd5c15f, subtree skills/engineering/wizard.
The import record lists all three source hashes. Public Codex metadata also
matches the source. Remove only wizard's pending waiver; the import census is
now 19 verified bundles, 7 pending imports, and 5 local skills.

## Alignment and local routing

Four fresh sessions used the configured Codex CLI, 0.162.0-alpha.2. They used
disposable synthetic workspaces and the normal host context. There was no model
override, credential copy, or host configuration change. Full entry paths
selected the intended fixture skills. Direct and wrapped cases had identical
prompts, project files, and agentic-workflow dependency bytes outside wizard.
The direct case used the original three source files; the others used the exact
candidate package. This compares entries in the same local environment, not a
wholly upstream stack without Myst project rules.

| Case | Observed result | Result |
| --- | --- | --- |
| Direct upstream | Generated one scratch wizard for the three confirmed human-only stages | Pass |
| Myst wrapper | Generated the same stages, values, destinations, and confirmation gates | Aligned |
| P4 repeatable, with Git mirror | Generated scripts/setup-preview.sh and its README link/run command; left CL association and publication pending | Pass |
| Unconfirmed scope | Presented ordered stages, value sources, destinations, secrecy, and confirmation request; wrote no files | Pass |

The stages were Preview identifier, Preview key, and Retire old preview. All
three authored scripts preserve the 7,206 library bytes before the STAGES marker
exactly. TOTAL_STAGES=3, ENV_FILE=.env.preview, and the explicit GitHub repository
fixture-owner/preview-fixture are configured below that marker. Static inspection
confirmed the supplied UI journeys, URL-before-input order, visible public entry,
hidden secret entry, local value writes, and exact CI variable/secret names.
Confirmation gates precede local/CI writes and the irreversible click instruction.
The retirement stage captures no value and pauses for manual completion.

The two alignment outputs are not byte-identical. They vary in wording, quoting,
root checks, pauses, and closing text. Direct uses the stock finish helper;
wrapped supplies a stage-section summary that keeps acceptance pending. Its
library remains intact. The P4 output also stops before cutover if CI writes were
skipped. These are observed choices within authored stages and local authority;
they do not change the packaged source or establish identical future behavior.
The tested scope/author/verify/handoff method aligns.

Only the requested scratch script changed in each alignment case. Only the
script and README changed in the repeatable case. Project config, blank synthetic
environment fields, domain docs, ticket, installed fixture packages, Git HEAD,
and branches stayed unchanged in all cases. No setup success or ticket completion
was recorded. No generated wizard was executed, sourced, or run stage by stage.
No browser, actual secret, CI write, live P4 action, or publication was used.

## Mechanical and loading checks

- All six production CI scripts passed, including Windows PowerShell 5.1 parse,
  ASCII/BOM, metadata, version, install-line, and dead-reference checks.
- The full source verifier passed against independent pinned sources. Its 26
  unit tests passed. All three wizard source files match the approved subtree.
- Both offline Claude plugin validators passed. Claude model runtime stays
  deferred until the owner reports that Claude works.
- skills CLI 1.7.1 copy installation passed for Codex, Claude Code, and OpenCode.
  The installed wizard trees matched all candidate file hashes.
- Fresh Codex skills/list exposed one enabled fixture wizard entry with the
  expected public description and original display metadata. Its implicit
  catalog exposed the human-only setup, credentials, dashboard, and cutover
  triggers. The host truncated the trailing description; full skills/list
  retained it. This proves discovery, not autonomous routing in a model run.
- Isolated OpenCode 1.18.35 discovery found the public wrapper entry. No extra
  raw SKILL.md entry, symlink, runtime extraction, or host plugin change was used.
- A real core.autocrlf=true Git checkout preserved all three raw source files.
- Git Bash 5.2.37 parsed the original template and all three generated scripts
  with bash -n. Model receipts confirm chmod +x. ShellCheck was unavailable.

All four model runs exited 0. Initial shell startup failures were retried; one
P4 memory search returned no matches (exit 1). No run was excluded. The first
catalog assertion expected an untruncated trailing clause and failed. Inspection
showed normal host truncation; the corrected check covers the visible triggers
and records that limit. These failed attempts remain in the evidence. Elapsed
times do not support a token or performance comparison.

## Evidence and acceptance

Disposable evidence is under %TEMP%/myst-wizard-migration-20261009. Each case has
prompt.txt, before.json, run.json, trace.jsonl, and actual generated artifacts.
verify.py independently hashes the protected inputs, checks candidate/prompt
identity and authored stages, and parses Bash without executing it. Its final
alignment-checks.json and implicit-checks.json passed. Source, checkout, package,
template-static, Codex, and OpenCode receipts are adjacent. Temporary evidence
may expire; this report retains the assessed scope, results, and limits.

Both independent reviews assessed the same 14-action working-tree changeset
against 26b7743, including complete added files and the unchanged template move.
They checked all pinned hashes and the saved diff against live content. The
commit list was empty. Only review receipts and derived status text were added
after their final scope checks; the reviewed skill package stayed unchanged.

## Standards

GREEN. Blocking: 0. Warning: 0. Fowler heuristic findings: 0.

The reviewer found that the wrapper follows CONTRIBUTING's source separation,
genericity, dependency, trigger, size, and authority rules. The complete source,
metadata, attribution, mapping, scoped attributes, and catalog fit ADR-0008,
ADR-0009, and the source-record contract. The reviewer checked actual authored
stages and recomputed fixture change inventories. The report states the output
differences and test limits accurately. The required thin wrapper overrides the
Middle Man heuristic; intact upstream helper duplication does not warrant local
refactoring.

## Spec

GREEN. Blocking: 0. Warning: 0.

The reviewer found no missing requirements, scope creep, or incorrect local
implementation. All three raw files match independent pinned Git blobs. Actual
scripts preserve the library and align on stages, fields, destinations, hidden
entry, and confirmation gates. The P4 case preserves repeatable work through the
stated capture procedure; unconfirmed scope writes nothing. Actual traces prove
method/template/contract loading and static/chmod checks. Protected state stays
unchanged. The plan's source, companion, live-loading, behavior, and attribution
requirements are met within the stated test scope.

Standards findings: 0; worst issue: none. Spec findings: 0; worst issue: none.
Owner verified wizard 5b86625 under the later instruction to test alignment,
verify it if it passes, and move to the next skill. The recheck used verify.py
against the committed package and all four saved case artifacts. It confirmed
the same alignment prompt/project/dependency inputs, exact candidate files,
protected state, stage/value/destination/gate behavior, and Bash syntax. No new
model sessions or full wizard execution were needed. The output differences and
test limits above still apply. This closes this per-skill owner gate.
