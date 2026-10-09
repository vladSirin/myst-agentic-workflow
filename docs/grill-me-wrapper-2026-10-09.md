# Grill-me source and wrapper - 2026-10-09

Status: implementation, alignment checks, and both independent reviews passed;
owner verified 1d481a5 on 2026-10-09 after the alignment artifact recheck.
Review base: fd1f4c0. This changeset migrates grill-me alone.

The former Myst alias exactly matches the approved Matt source pin. There is no
alias method delta. Both source files stay whole under references/upstream;
SKILL.md alone maps to UPSTREAM.md under ADR-0009. Public metadata matches the
source and retains allow_implicit_invocation: false. The local entry loads the
shared contract, preserves explicit user invocation, and maps the source Skill
call to the intended Myst grilling entry through the host's available mechanism.
The current grilling entry also matches the approved method; its own source
migration is still pending. This changeset does not modify that dependency.
The source pin is 6fd947921b935b7e1e69293a200400f0fdd5c15f, subtree
skills/productivity/grill-me. Both source hashes are recorded in UPSTREAM.json.
Only grill-me's waiver was removed. The census is now 20 verified imports,
6 pending imports, and 5 local skills.

## Alignment and routing

Four fresh sessions used the normal configured Codex CLI, 0.162.0-alpha.2, in
disposable synthetic workspaces. There was no model override, credential copy,
or host configuration change. The direct alias used both original source files;
the other cases used the exact candidate package. Direct and wrapped prompts,
project files, and dependencies were identical outside grill-me. Both used the
current Myst grilling entry, which matches its approved upstream method. This
compares the alias entries within the same local context, not a wholly upstream
stack without project rules. Native Skill-tool dispatch was unavailable; the
selected fixture entry was read and followed instead.

| Case | Actual result | Result |
| --- | --- | --- |
| Direct alias | Loaded grilling, delegated a local code fact check, asked the first frontier, then waited | Pass |
| Myst wrapper | Loaded shared contract, raw alias, and selected Myst grilling entry; same fact check, frontier, recommendations, and wait | Aligned |
| Missing grilling | Reported the absent installed dependency and next step; did not start an interview or use a global substitute | Pass |
| Automatic/cross-skill request | Reported the user-only restriction and an explicit command; did not load the raw method or grilling engine | Pass |

Each interview produced one actual fact-finding child. Parent dispatch receipts,
child session identity, successful child code reads, and returned findings were
checked. They establish archive/restore of copied records, protection of linked
records during archive, and the absence of a linked-record check during restore.
Both distinguish those in-memory functions from durable recovery or recovery
after permanent purge. No app code or test execution was used to invent proof.

Both first rounds ask the same two independent decisions: retain versus purge,
and manual versus automatic expiry. Both recommend Archive and manual Custodian
action. They leave recovery windows, purge confirmation, and timer details for
later rounds. They wait for the user's answers and do not treat recommendations
as settled decisions. Wording, evidence detail, and justification differ; this
does not prove identical text or every future interview result.

All four cases leave every fixture file, installed package, ticket, domain doc,
Git HEAD, and branch unchanged. The target remains Perforce despite its Git
fixture mirror. No live P4 action, implementation, new document, tracker closure,
or publication occurred. The automatic request was a stated synthetic role;
it tests the documented guard rather than every native host call chain.

## Source, installation, and invocation

- The full source verifier passed against independently acquired pinned sources.
  Both raw alias files and the former entry match the approved Git blobs.
- All six production CI scripts passed: PowerShell 5.1 parse, ASCII/BOM,
  frontmatter/metadata, version, install-line, and dead-reference checks.
- Both offline Claude plugin validators passed. Claude model runtime remains
  deferred until the owner reports that Claude works.
- skills CLI 1.7.1 copy installs passed for Codex, Claude Code, and OpenCode.
  Both physical installed trees match all candidate hashes. Method fixtures
  separately include the declared dependencies; copy add does not establish
  that a partial dependency install is usable.
- Fresh Codex skills/list exposes one enabled fixture alias with its original
  display metadata. The alias is absent from the implicit prompt catalog.
  disable-model-invocation: true and allow_implicit_invocation: false are kept.
  This is discovery and metadata evidence, not a native slash-menu UI test.
- Isolated OpenCode 1.18.35 discovery finds the public wrapper once. The source
  entry uses UPSTREAM.md, with no symlink or extra discovery entry. OpenCode model
  execution and native user-only enforcement were not tested here; the entry
  includes the local guard for hosts that ignore this metadata.
- A real core.autocrlf=true Git checkout preserves both raw source files.
  No archive extraction or runtime download is needed.

All four runs exited 0. Initial shell startup failures were retried under the
fixture's stated read-only retry rule. No run was excluded. The first verifier
assertion treated a Test-Path check naming UPSTREAM.md as a source read. Inspecting
the command showed that it only checked existence. The corrected receipt check
passed and distinguishes existence from loading or invoking a method. No skill
change was made for that assertion. Existing root-file LF bytes were preserved
before review; the package and tested fixture bytes stayed unchanged.

## Evidence and acceptance

Disposable evidence is under %TEMP%/myst-grill-me-migration-20261009. Each case
contains prompt.txt, before.json, run.json, trace.jsonl, and its unchanged
workspace. verify.py checks prompt/input/candidate identity, protected state,
actual frontier answers, dispatch, and child read receipts. alignment-checks.json
and implicit-checks.json passed. Source, copy-install, package, checkout, Codex,
and OpenCode receipts are adjacent. Temporary evidence may expire; this report
retains the assessed scope, results, and limits.

Later interview answers, completion confirmation, a competing-vendor collision,
native Skill-tool dispatch/slash UI, live P4, OpenCode model execution, and Claude
model runtime remain untested. The current grilling method is unchanged, but its
own complete-source migration and acceptance remain separate work.

Both independent reviews assessed the same 12-action working-tree scope against
fd1f4c0, including complete added files. They checked all pinned hashes and the
saved diff against live content before and after review. HEAD equaled the base;
the commit list was empty. Only review receipts and derived status text changed
after those final checks; the reviewed skill package stayed unchanged.

## Standards

GREEN. Blocking: 0. Warning: 0. Fowler heuristic findings: 0.

The reviewer found that the wrapper follows CONTRIBUTING's source separation,
genericity, dependency, invocation, and authority rules. The complete source,
metadata, provenance, filename mapping, scoped attributes, waiver removal, and
catalog fit ADR-0008, ADR-0009, and the source-record contract. Grilling is
unchanged and matches the approved method. Actual parent/child receipts and
outputs support the fact-finding and interview claims. Independent hash checks
show unchanged fixture files. The required alias wrapper overrides the Middle
Man heuristic. No speculative orchestration or premature optimization was added.

## Spec

GREEN. Blocking: 0. Warning: 0.

The reviewer found no missing requirements, scope creep, or incorrect local
implementation. Both raw files match independent pinned Git blobs, and user-only
reach and copy dependencies are retained. The wrapper maps the source call to
the selected Myst engine while keeping its migration separate. Actual receipts
prove loading and one fact-finding child per interview. Prompts and other inputs
match; both first rounds give the same two decisions, recommendations, and wait.
Missing dependencies and automatic requests stop before the interview. Protected
state remains unchanged. The report states its runtime limits and owner gate.

Standards findings: 0; worst issue: none. Spec findings: 0; worst issue: none.
Owner verified grill-me 1d481a5 under the later instruction to test alignment,
verify it if it passes, and move to the next skill. verify.py rechecked the exact
committed candidate and all four saved case artifacts. It confirmed matching
prompts/project/dependency inputs, actual alias/engine loading, fact-finding child
receipts, the same frontier questions and recommendations, both routing guards,
and unchanged files/HEAD/branches. No new model sessions were needed. The stated
limits still apply. This closes this per-skill owner gate.
