# Shared local integration verification

Scope: Changeset 3, based on local commit 85b8893. This changes the local
agentic-workflow skill, its shared reference, starter domain guidance, and
catalog. It does not migrate another upstream skill or retire Review Record.

## Targeted runtime

Codex CLI 0.160.1 ran a disposable wrapper in a fresh ephemeral, read-only
session. The wrapper linked to a copy of LOCAL-INTEGRATION.md. Its trace records
successful reads of the wrapper (item_4) and shared reference (item_6), then
target files, followed by a completed turn and JSON decisions.

The first attempt failed before execution because the CLI rejected its configured
gpt-6.1-sol model for the account. An explicit gpt-5.5 override, listed in the
local model cache, completed. No permanent model configuration was changed.
Claude execution remains deferred until owner notification.

| Fixture | Observed decision |
| --- | --- |
| Git with legacy vocabulary and Markdown tracker | Keep CONTEXT.md and existing tracker; upstream commit/push text grants no authority |
| Perforce with nested Git mirror | Reject direct pr, cross-skill implement-spec, and Git commit |
| New vocabulary only | Read/write GLOSSARY.md |
| Legacy map | Follow its scoped CONTEXT.md link |
| New map | Follow its scoped GLOSSARY.md link |
| Both naming families without pointer | Resolve ownership before vocabulary writes |
| Explicit custom pointer | Follow the custom scoped words.md path |
| Neither family, staged legacy convention | Retain CONTEXT.md convention |
| Missing project config | Resolve tracker, vocabulary, and VCS before dependent actions |
| Conflicting tracker docs | Resolve authority before ticket writes |
| Missing Myst review dependency | Report missing dependency; reject other-vendor fallback |
| Competing review entries and user-only handoff | Select myst-dev-kit:code-review; reject automatic/cross-skill handoff |
| Broken explicit pointer | Clarify before writes; no silent legacy fallback |
| Legacy map pointing to new scoped name | Follow the explicit link despite both scoped filenames |

The initial tracker fixture did not state its plain-text path base. The result
used the intended repository-relative path, but this is insufficient evidence
for that ambiguity. The contract now honors a project-declared base, resolves
Markdown links relative to their document, and asks before writes when a plain
path's base is unclear. A focused follow-up uses an explicit repository base.
The follow-up completed with exit 0: it selected
targets/git_legacy/.scratch/issues/*.md and CONTEXT.md, limited local commits to
user-authorized scope, and required review-and-submit plus approval for push.

These are observed instruction-routing decisions, not execution of downstream
skills or a host-enforced security boundary. In particular, the competing skills
are synthetic declarations; later wrapper migrations must prove actual dispatch.
No target workflow, Git/P4 publication, or consumer migration was executed.
The synthetic wrapper proves the shared reference is reachable. Production
wrappers will declare and load it as their own migrations require.

## Repository checks

- Six existing CI script checks passed: PowerShell 5.1 parsing, ASCII/BOM,
  entry frontmatter, manifest versions, install commands, and dead references.
  The first parse attempt hit the local execution policy; the process-only
  ExecutionPolicy Bypass retry passed without changing machine policy.
- Source verifier acceptance tests: 19 passed.
- Independent pinned-source verification passed: one verified import, 24
  declared pending imports, four local skills. The first sandboxed attempt
  could not reach GitHub; the network-enabled retry passed.
- Changed local Markdown reference targets resolve; git diff --check passed.

## Review

Standards review found no actionable violation. Spec review identified a blanket
claim that migrated wrappers already load the shared reference. That claim was
replaced with a requirement for wrappers that need shared integration; handoff
does not gain an unnecessary dependency.

Final independent reviews after the focused check: Standards GREEN; Spec GREEN.
No actionable findings remain. Owner verification is still required before
Changeset 4; these reviews do not authorize publication.

## Local evidence

Disposable root: `%TEMP%/myst-shared-integration-20261007`.
The command used `codex exec -m gpt-5.5 --ephemeral --json
--skip-git-repo-check --sandbox read-only -C <fixture>` with a prompt to read the
fixture wrapper, its reference, and cases.json, then report routing decisions.
The source and fixture files remain there for inspection.

| Artifact | SHA-256 |
| --- | --- |
| Initial fixture wrapper | 9bdfc6a7ca63caefe32bc616ebd4d0f505cf2f9e37d85c05072c2e3efc877030 |
| Initial tested shared reference | 2cb5b7d2b754fc0b818cd07a7bf94777c3d820c9c527dbd09f0f51b64e4d08cf |
| cases.json | 82e6c96e94ceab544e1f45aaefa5e490643da39e742ac48e078444be5c3b6a8d |
| runtime-retry.jsonl | 9c9609664905369c7db5261d9b1f860fcfe7ac23c97b6877e5c60f1ce5ec75e7 |
| decisions.json | 2d507e44020fa4e05342dc2663198b41a85528a81491f243fdb54c794ae0102f |
| runtime-focused.jsonl | 23650a6b79ffe24833dfbd2175d1a903d6f465097ee2467cd748299db792a6cf |
| Final tested shared reference | 9aee90f21c2a7bb77adc7f1266b7ce6245132f7db77ee5208f54be30f52e2c97 |

The shared reference changed after the first matrix run only to narrow wrapper
wording and clarify path bases. The focused run uses the final reference.
