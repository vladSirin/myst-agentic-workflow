# Deep-dive Hammer migration

Changeset 5, based on local commit 0a38ca7. This is the Hammer metadata test
from the approved plan. Only deep-dive migrates here; roundtable stays pending.

## Original source comparison

The complete deep-dive subtree in both Hammer v0.19.0 and v0.30.0 contains only
SKILL.md. Extraction from both original release archives found those files
byte-identical, including the Chinese frontmatter and credited method body.
There is no upstream method change to adopt.

| Source evidence | Value |
| --- | --- |
| v0.19.0 Intel ZIP asset ID | 521886586 |
| v0.19.0 complete archive SHA-256, computed | fd4d5bf1ce94d82de548402ace410d6e519c9bb5bf622c9ecf0a556336d565e5 |
| v0.30.0 Intel ZIP asset ID | 614238989 |
| v0.30.0 complete archive SHA-256, computed | 1532f24e8ae95f9606a9ad4bb2916acfcb6fa0dff9f1496cca216c93c26f72be |
| Original SKILL.md SHA-256 at both releases | bbb960312b72e2bf1c3b6a98f2dba96bf62dbb0e7dcc9ad382fd91a9659fb9ff |

Unlike the earlier range-extraction research, this migration downloaded the
complete v0.30.0 archive and verified its hash. The source verifier then fetched
it independently again, checked release/asset identity and archive hash, and
compared the complete selected subtree against the bundled member.

The adjacent advanced-capabilities README was also read. It lists deep-dive and
roundtable and describes Hammer's global Claude installation behavior, including
not overwriting an existing directory. It adds no method instructions, required
companions, or license grant. It is outside the selected skill subtree and is
retained in temporary evidence; no runtime dependency on it is introduced.

## Local integration comparison

Before this change, the public SKILL.md combined Myst frontmatter with the
Chinese upstream body. Now it retains the same public frontmatter, loads the
complete original file from upstream.zip, and supplies local ZIP-reader examples.
The body is no longer maintained inline. No extra workflow rules or skill
dependencies are added.

The original Chinese description remains unchanged inside the archive. English
discovery text, argument hint, and disable-model-invocation: true remain at the
public entry. New local agents/openai.yaml sets the English display metadata and
allow_implicit_invocation: false. There was no upstream metadata file to replace.
The existing author credit and owner redistribution/re-vendoring authorization
remain in PROVENANCE.md. No new public license is asserted.

## Discovery and runtime evidence

Codex CLI 0.160.1 inspected the project-copy package through a fresh app-server
skills/list request. It exposed one local deep-dive entry at the wrapper path,
with the retained English description and new display metadata. There is one
loose SKILL.md in the package; the original is only inside the ZIP.

A debug prompt-input inspection omitted that local deep-dive entry from the
automatic catalog while including a separate automatic control. The existing,
unmigrated installed myst-dev-kit:deep-dive entry appeared separately. It was not
changed or confused with the project-copy entry. This proves local catalog
exposure, not universal prevention of every possible model action.

Fresh ephemeral, read-only gpt-5.5 sessions at medium reasoning ran these cases:

| Case | Result |
| --- | --- |
| Direct original, first step | Read the original file, used the supplied decision, strengthened both sides, asked one decisive follow-up, and stopped without a final verdict. One unsupported time calculation is noted below. |
| Myst wrapper, same first-step input | Read the public entry and archived source, strengthened both sides, identified the tradeoff, asked one decisive question, and stopped without a verdict. |
| Myst wrapper, answer supplied | Read the wrapper/source and gave a clear verdict, rationale responding to the opposing case, boundary conditions, and concrete next actions. |

The synthetic decision was whether a four-person team should spend two days
automating a changing release process three weeks before a milestone. The
wrapped first step asked which risk was greater: manual release mistakes or
losing engineering time to automation and rework. The follow-up supplied the
actual first response plus a synthetic user answer that manual releases had
been incident-free, only 15 minutes of weekly work was stable, and the engineer
was needed for a milestone-critical fix. The second step recommended staying
manual through the milestone and explained when that judgment should change.

The second-step test used a new ephemeral session with the prior response and
answer included explicitly. It is a continuation-context test, not proof of
native session resumption. All three processes completed with exit 0. No fixture
files changed. The final entry, source archive, and invocation metadata match
the runtime-tested copy exactly.

The direct first-step output introduced an unsupported claim of eight person-hours
per week, then used six team-hours across three weeks elsewhere. The wrapped
output did not repeat that error. Both followed the interaction sequence, but
the direct result was not fully faithful to the stated numbers. One pair cannot
establish whether differences are caused by packaging or normal model variation.
No method rewrite or workaround was added on that observation.

Claude runtime remains deferred until owner notification. OpenCode was not
retested for this skill; the handoff pilot's host limitation still applies:
user-only frontmatter alone is insufficient there. An OpenCode installation
must apply its native skill permission rule for deep-dive while preserving
explicit command use. This report makes no new OpenCode enforcement claim.

## Repository checks and review

- Independent verifier: three source bundles verified; 22 declared pending
  imports; four local skills.
- Verifier acceptance suite: 19 tests passed.
- All six existing CI script checks passed; git diff --check passed.
- Public frontmatter matches the pre-migration entry exactly.

Final independent reviews against 0a38ca7: Standards GREEN; Spec GREEN. The
Spec review's duplicate current-pin finding was fixed by leaving UPSTREAM.json
authoritative and retaining only historical context in provenance.
Owner verification remains required before another skill migration. No push,
PR, release, installed-plugin update, or consumer migration is authorized here.

## Evidence location

`%TEMP%/myst-deep-dive-migration-20261007` contains both full release archives,
source-comparison.json, an empty upstream.diff, extracted source including the
adjacent README, discovery.json, implicit-prompt.json, the saved prompts, and
the runtime harness. Each run records trace JSONL, final output, and process
status. It uses `codex exec --ephemeral --json --skip-git-repo-check --sandbox
read-only` with explicit model and reasoning settings. No Hammer app binary was run.
Temporary evidence can expire; the report retains the results and limits.

| Trace | SHA-256 |
| --- | --- |
| direct/first-trace.jsonl | f51a47f7e39fe8c98dee10f92f9fb8a67ad8a6f78ce7fd2740715d7abdaa054d |
| wrapped/first-trace.jsonl | dc350e952a0bf18052d424b79c55187e7330daffe1642dc51a0aea2b28f456f8 |
| wrapped/second-trace.jsonl | a26f104496deb96637cc40570c2de464dbcee179b548c028c0b4dd6d22a0b356 |
