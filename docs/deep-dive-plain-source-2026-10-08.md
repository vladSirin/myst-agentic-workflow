# Deep-dive plain-source conversion - 2026-10-08

Status: converted, tested, independently reviewed, and owner-verified on 2026-10-08
for conversion commit c64c236 after alignment verification.
Review base: 74bea52. The owner verified implement and authorized continuation.
Only deep-dive changes source layout in this changeset.

## Source and local behavior

The Hammer v0.30.0 pin and asset identity remain unchanged. The complete selected
subtree contains only SKILL.md. It is now references/upstream/UPSTREAM.md, with
every byte preserved, including Chinese frontmatter, method text, and author
credit. Source SHA-256 remains
bbb960312b72e2bf1c3b6a98f2dba96bf62dbb0e7dcc9ad382fd91a9659fb9ff.
UPSTREAM.json version 2 retains the original inventory and records only the
single entry-filename mapping. Scoped Git attributes preserve source bytes.

The public wrapper now links directly to UPSTREAM.md instead of supplying ZIP
reader commands. Its English frontmatter, argument hint, and
disable-model-invocation setting remain unchanged. Public agents/openai.yaml
still sets allow_implicit_invocation to false. There are no skill dependencies
or method additions. Existing owner redistribution authorization is retained;
this conversion asserts no new public license.

## Package verification

- All 26 verifier acceptance tests passed. Independent source acquisition
  verified all five migrated bundles against their approved pins: four plain
  packages and one remaining ZIP, with 20 pending imports and four local skills.
- skills CLI 1.7.1 copy installation for Codex, Claude Code, and OpenCode preserved
  the complete package byte-for-byte in both generated host directories. Each
  copy contains one SKILL.md. This is not Claude runtime evidence.
- Fresh Codex 0.160.1 discovery selected the enabled local public entry. Debug
  prompt inspection excluded the local deep-dive entry from the automatic catalog.
- Fresh OpenCode 1.18.35 discovery selected the public wrapper and plain source
  link. Explicit-only use still needs the host permission configuration described
  in the handoff pilot, using deep-dive as the skill name. This package does not
  install that configuration; no new OpenCode model request ran.
- A disposable Git index and core.autocrlf=true checkout preserved source bytes.
- All six repository CI script checks, offline Claude plugin/marketplace
  manifest validation passed. Claude runtime stays deferred.
- The complete staged whitespace check flags the original two-space Markdown
  line break after the author credit (UPSTREAM.md line 8). Those bytes match
  upstream and are intentionally preserved. The check excluding that exact raw
  source path passes for all local changes; no global whitespace rule changed.

## Direct and wrapped comparison

Fresh read-only Codex sessions used configured gpt-6.1-sol on the same synthetic
decision: a four-person team is considering two days of release automation,
with two hours of weekly manual work, a changing process, and a milestone three
weeks away. The direct fixture exposes only the original upstream SKILL.md.
The wrapped fixture uses the actual converted package. They receive identical
project instructions and first-step prompts. No other skill is invoked.

Both actual first responses strengthened the case for and against automation,
identified key variables, asked one decisive question, and stopped without a
final verdict. The wrapper asked about the milestone cost if automation produced
no usable savings; the direct run asked what milestone risk automation would
reduce enough to justify the effort. Both treated six hours of remaining manual
work as conditional on two hours meaning total team effort, avoiding the earlier
pilot's unsupported multiplication by team size.

Each second-step prompt includes that run's actual first response and the same
synthetic reply: six incident-free releases, only 15 minutes per week of stable
steps, and the only available engineer needed for a milestone-critical fix.
These are fresh sessions with supplied continuation context, not native resume
tests. Both second responses recommended keeping releases manual through the
milestone and keeping the engineer on the critical fix. Both calculated 45
minutes of known stable work across three weeks, answered the strongest opposing
case, named conditions for reconsideration, and gave concrete next steps.

The question wording and boundary details vary. The direct verdict listed spare
engineering capacity as a reason to change the decision; the wrapped verdict
explicitly said extra capacity alone would not establish the build's value.
Both gave the same present recommendation. This pair supports alignment of the
interaction sequence and present decision, not identical judgment under every
possible future condition. No source or method rewrite was made for this variation.

All four runs exited 0, and all fixture file hashes stayed unchanged. Actual
responses and traces were inspected. Both wrapped phases loaded the plain
UPSTREAM.md through successful ordinary file reads. The direct fixtures read the
original SKILL.md. No archive reader was needed for the converted skill.

| Run | Seconds | Observed result |
| --- | --- | --- |
| Wrapped first | 42.333 | Two-sided analysis, one decisive question, no final verdict |
| Direct first | 42.571 | Two-sided analysis, one decisive question, no final verdict |
| Wrapped second | 29.318 | Manual through milestone, reasons, boundaries, next actions |
| Direct second | 25.209 | Same present recommendation and required output elements |

## Evidence and limits

Temporary evidence is under %TEMP%/myst-deep-dive-plain-20261008: runtime prompts,
traces and outputs, baseline hashes, discovery output, copy-install log, and
checkout fixture. The [earlier ZIP report](deep-dive-wrapper-2026-10-07.md)
retains source history and prior behavior evidence.

verification.json records process exits, timings, unchanged workspace hashes,
and the following trace hashes:

| Trace | SHA-256 |
| --- | --- |
| wrapped/first-trace.jsonl | 90dca93fea77666c55e71ebeff647637d8fa29443fa6622250dc2ed31937ef17 |
| direct/first-trace.jsonl | b4819a1da6696bb3f4db4579c1f4c48a83bde3cbeecbdb295a19387666242d28 |
| wrapped/second-trace.jsonl | e9bdacabd620236058d4b0203d2457c44cd2ff53f0e327cddf032287edb57d60 |
| direct/second-trace.jsonl | 2c11dd8e06a520f24ea3c7fe5c86ab6339559fbd70ae2a15625178ca10aee85c |

Final independent reviews: Standards GREEN, zero findings; Spec GREEN, zero
findings. Reviewers checked the report against actual responses, trace hashes,
source reads, and unchanged fixture inputs. Owner verification is recorded below.

One comparison can establish alignment on this scenario, not deterministic
wording or universal decision quality. Discovery, copy installation, and runtime
behavior are separate evidence. Native slash-menu interaction was not repeated.
Publication and consumer migration remain outside this work.


## Owner verification

The owner instructed: "Run the alignment test too and confirm if it is ok, if
so consider verified." The direct-versus-wrapper tests above already covered
both steps. Their four actual outputs were re-read, and their trace hashes,
exit codes, output-to-trace equality, and unchanged fixture inputs were checked
again. The committed package matches the runtime-tested wrapper copy exactly;
the direct entry matches the preserved upstream source exactly. No extra model
run was needed. alignment-recheck.json records these checks in the evidence root.

Alignment is acceptable for the tested scenario: both runs strengthen both
sides, ask one decisive question and wait, then use the supplied answer to give
the same present recommendation, with reasons, conditions, and actions. The
noted difference in future conditions remains a limit, not an identical-output
claim. The owner's condition is met; conversion c64c236 is owner-verified on
2026-10-08. Claude runtime remains deferred.
