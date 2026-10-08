# Handoff plain-source conversion - 2026-10-08

Status: implemented, reviewed, and owner-verified on 2026-10-08 (7e05f31).
Review base: 23c01bf. The owner verified codebase-design's conversion as OK and
authorized continued per-skill rollout. Only handoff changes source layout here.

## Source and local behavior

The approved upstream pin remains 6fd947921b935b7e1e69293a200400f0fdd5c15f.
Both original files match the prior ZIP member bytes and source-record hashes:
SKILL.md is packaged as references/upstream/UPSTREAM.md; agents/openai.yaml keeps
its relative name and bytes. The original inventory keys remain in UPSTREAM.json.
Version 2 records only the root entry mapping. No upstream method update occurs.

The local wrapper retains its full frontmatter, including argument-hint and
disable-model-invocation. Public agents/openai.yaml still disables implicit
invocation. Its body now directly links to UPSTREAM.md, replacing archive-reader
commands. Dependencies remain empty. Provenance keeps the original MIT notice.
Scoped Git attributes preserve upstream bytes on checkout.

## Verification

- All 26 verifier acceptance tests passed. Independent pinned-source verification
  passed for all five migrated bundles: two plain-reference packages and three
  remaining ZIPs, with 20 pending imports and four local skills.
- Normal skills CLI 1.7.1 copy installation for Codex, Claude Code, and OpenCode
  preserved the complete package in both generated host directories. Each copy
  has one SKILL.md. This is not Claude runtime evidence.
- Fresh Codex 0.160.1 discovery returned the enabled local handoff wrapper.
  Debug prompt inspection excluded the local handoff from the automatic catalog,
  preserving explicit-only use. Native slash-menu interaction was not repeated.
- Fresh OpenCode 1.18.35 discovery selected the wrapper with its plain-file link.
  OpenCode still requires the handoff skill permission rule documented in the
  [earlier pilot](handoff-pilot-2026-10-07.md#opencode-invocation-configuration).
  This package does not install that host configuration. No new OpenCode model
  request was needed for this conversion; the focused runtime check used Codex.
- A disposable Git index and checkout with core.autocrlf=true preserved both
  source files byte-for-byte.
- All six repository CI script checks passed. Offline plugin and marketplace
  manifest validation passed; no Claude model ran. git diff --check passed.

A fresh ephemeral Codex session with the configured gpt-6.1-sol model explicitly
loaded the local handoff wrapper and then UPSTREAM.md with ordinary file reads.
The synthetic scenario referred to a one-line PLAN.md for JSON settings import.
The model wrote handoff-json-settings-plain-20261008.md to the configured Windows
TEMP outside the project workspace. It linked the plan, stated implementation
had not started, included suggested skills, and redacted the synthetic credential.
The session completed with exit 0 in 41.705 seconds. Every fixture project file
retained its before/after hash. The fixture's Git-status probe reported that it
was not a Git repository; this was not a source-loading failure.

This exercises handoff's output location, artifact pointers, suggested skills,
and redaction with the plain loader. It does not prove identical wording across
models or replace the owner's deferred Claude runtime checks. The common
plugin/copy packaging and rollback matrix was already exercised by the
[plain-source pilot](plain-source-pilot-2026-10-08.md).

## Evidence and review

Temporary evidence is under %TEMP%/myst-handoff-plain-20261008: copy-install log,
Codex/OpenCode discovery outputs, automatic prompt snapshot, checkout fixture,
runtime prompt/trace, before hashes, result metadata, and output artifact.

| Artifact | SHA-256 |
| --- | --- |
| trace.jsonl | b01790be7aacd45bd73e1b34e177e95a8c3e2b9263339265a46443661045ce99 |
| output/handoff-json-settings-plain-20261008.md | f8a59fa80a5cdd47849c8239824c24b12affbdd3721b2fa0589681e169fcb1cb |

Standards: GREEN, zero remaining findings. A stale README description of the ZIP
layout was found and corrected to plain references and the current evidence.
The reviewer verified that correction. Spec: GREEN, zero findings; the reviewer
independently compared both source files to the base archive and confirmed exact
bytes, inventory, metadata, and scope. After the generated handoff was checked
against the test request and upstream instructions, the owner instructed
"Good verify it now." Verification is recorded for commit 7e05f31 on 2026-10-08.
This accepts the tested conversion; Claude runtime remains deferred and no
publication authority is added.

The current changeset also makes the already-required review/description workstream explicit in the plan
and tracker. It does not implement code-review, pr, p4-description, or the
review-and-submit format change. No source pin, consumer, or publication changed.
