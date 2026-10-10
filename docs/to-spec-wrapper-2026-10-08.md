# To-spec source and wrapper migration - 2026-10-08

Status: implemented, tested, independently reviewed, and owner-verified on
2026-10-08 for conversion commit b1730da after the alignment recheck.
Review base: 7d2888e. The owner verified TDD and authorized continuation.
Only to-spec migrates in this changeset.

## Upstream comparison

The historical Matt revision is 0ab1b63a410a03d3627979a109c8695de27af954;
the approved revision is 6fd947921b935b7e1e69293a200400f0fdd5c15f. Complete
subtrees were independently fetched and compared. Both contain SKILL.md and
agents/openai.yaml. Both files are byte-identical between revisions. There is
no upstream method or template change to adopt.

The new bundle preserves both original files. Only SKILL.md is packaged as
references/upstream/UPSTREAM.md under ADR-0009. UPSTREAM.json retains original
inventory names/hashes and the exact single mapping. The root MIT notice from
the approved revision is retained in PROVENANCE.md.

## Local integration comparison

The old Myst entry had one inline change: upstream's missing-tracker setup
instruction was replaced with a request for the project's tracker-doc location.
The migration restores the complete upstream text and moves that local behavior
into a wrapper that first loads agentic-workflow's LOCAL-INTEGRATION.md.

The project owns tracker/triage pointers, authoritative glossary paths, initial
spec state, and publication authority. Missing configuration follows the shared
contract instead of invoking the excluded setup skill. agentic-workflow is the
required copy dependency. The wrapper checks the local entry and shared contract
before dependent work. The original seam-confirmation rule, seven-section
spec template, and ready-for-agent instruction remain unchanged in raw source.
Project state rules take precedence through the local mapping.

The public frontmatter is unchanged, including disable-model-invocation: true.
The newly included public Codex metadata matches the original upstream metadata
and disables implicit invocation. No seam relay, interview rewrite, or extra
spec template is introduced. This changeset does not update review-and-submit.

## Package verification

- All 26 verifier acceptance tests passed. Independent pinned-source verification
  passed for six imported bundles, with 19 declared pending imports and four
  local skills. The to-spec pending waiver was removed with its source record.
- skills CLI 1.7.1 copy installation for Codex, Claude Code, and OpenCode kept
  every package byte in both generated host directories. Each has one SKILL.md.
- Fresh Codex 0.162.0-alpha.2 discovery selected the enabled local wrapper.
  Debug prompt inspection excluded to-spec from the automatic catalog, preserving
  explicit-only use. Native slash-menu interaction was not repeated.
- OpenCode 1.18.35 discovery selected the wrapper and plain source link. User-only
  use still requires the local host skill permission rule described in the
  handoff pilot, using to-spec as its key. The package does not install that rule.
  No new OpenCode model request ran.
- A disposable Git index and core.autocrlf=true checkout preserved both source
  files byte-for-byte. Source-relative layout has no companion or script obstacle.
- All six repository CI checks and offline plugin/marketplace manifest checks
  passed. The complete staged git diff --check passed. Claude runtime remains
  deferred.

## Runtime checks and direct comparison

Fresh sessions with the configured Codex model use synthetic Git repositories
and a local Markdown tracker. The supplied conversation concerns DropSlot quoting:
accept 3 units from 5 with 2 remaining; reject 3 from 2 with capacity unchanged.
The confirmed public seam is quote_drop_slot(requested_units, available_units).
The task excludes validation, persistence, cancellation, network calls, and UI.

Team pointers use Docs/team, and the authoritative domain file is legacy
CONTEXT.md. New specs must start with Status: proposed; only the owner can move
them to ready-for-agent. The only authorized tracker write is a new local spec.
No real tracker service or consumer project is touched.

The approved direct/wrapped pair has identical baseline files outside the
to-spec package and the exact same user prompt. The direct entry is original
upstream SKILL.md; the wrapper loads the plain original source. Shared project
instructions and dependency availability stay constant. This isolates the
entry wrapper, not an entirely upstream skillset or unrestricted publication.

| Case | Seconds | Observed result |
| --- | --- | --- |
| Approved wrapped | 89.012 | Created only the requested local spec, with Status: proposed and all seven template sections |
| Approved direct | 106.739 | Same artifact scope, state, template, approved seam, outcomes, and scope limits |
| Unconfirmed seam | 54.026 | Asked to confirm the sole public seam and its two literal results; no spec or other file written |
| Missing tracker | 60.974 | Reported both missing tracker/triage documents, retained supplied decisions, and stopped without writes or invented configuration |

All four runs exited 0 and left Git HEAD unchanged. Before/after hashes confirm
that the approved cases added only specs/local/01-slot-quote.md. Every input file
is unchanged in the two blocked-by-workflow cases. Actual specs and traces were
read rather than relying on completion messages.

Both produced specs cover the agreed acceptance/rejection behavior, pure result,
confirmed public seam, literal test results, legacy glossary terms, and all
exclusions. Neither claims implementation or tests have run. Both follow the
project's proposed state despite upstream's ready-for-agent default.

The prose is not identical: the wrapper uses five stories and the direct run
ten. Both cover the fixed feature scope; the direct run splits it into more
stories and is more verbose. Upstream asks for an extensive story list, so this
one small fixture does not establish equal coverage for a large feature. No
wrapper instruction was added to force a story count or rewrite the template.

## Evidence and limits

Temporary root: %TEMP%/myst-to-spec-migration-20261008. source-comparison.json,
upstream.diff (empty), old-local.diff, original files/licenses, runtime fixtures,
prompts, outputs, copy/discovery checks, and checkout evidence are retained there.
verification.json records changed files, section names, story counts, timings,
unchanged HEAD, and the following trace hashes:

| Completed trace | SHA-256 |
| --- | --- |
| approved-wrapped/trace.jsonl | 0c2e1a3cb6bfa78178da84a856527e0b928bc1395f498db22dd816d00c3a9fed |
| approved-direct/trace.jsonl | 4603373f1e6abb6d19f93e16ff1b4ab62e03d98e253c7a7b4d2cfe17c5b073a1 |
| unconfirmed/trace.jsonl | 737e576521cf863a0592396f271097fdc2e3e2b846c3c42da165014600c39195 |
| missing-tracker/trace.jsonl | cef7406bf7f4b40226dec3d279648fe986de5e22564dd7b20c01598fe8343eda |

Final independent reviews: Standards GREEN, zero findings; Spec GREEN, zero
findings. Reviewers checked actual specs, source integrity, trace/spec hashes,
unchanged input files and HEADs, and the no-write cases. The tests prove bounded
local-tracker behavior, not real remote issue creation, cross-host model output,
prototype-snippet handling, or every large-spec coverage requirement. Shared
publication and consumer migration remain outside this changeset.


## Owner verification

The owner requested: "Good do a test for result alignment if that works we can
say it is verified." The completed direct/wrapped specs were re-read and checked
against the supplied requirements. Both preserve all seven sections, literal
acceptance/rejection outcomes, the approved public seam, glossary meaning,
scope limits, and the project's proposed state. The five-versus-ten story count
and prose differences do not remove an agreed requirement in this fixture.

All four trace hashes, both generated-spec hashes, actual changed-file lists,
and unchanged Git HEADs were rechecked. The committed wrapper package matches
its tested copy exactly, and the direct entry/source metadata match the recorded
upstream bytes. alignment-recheck.json records this check. No extra model run
was needed because the paired execution already existed for this exact package.

The owner's condition is met: to-spec conversion b1730da is owner-verified on
2026-10-08 for the tested scope. The larger-spec coverage and remote-tracker
limits above remain; Claude runtime is still deferred.
