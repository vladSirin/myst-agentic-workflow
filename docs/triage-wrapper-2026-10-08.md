# Triage source and wrapper migration - 2026-10-08

Status: final-wrapper alignment passed; both review axes GREEN; owner-verified
on 2026-10-08 under the user's conditional acceptance.
Review base: 993e5d1. The owner authorized continuation after to-tickets.
Only triage migrates in this changeset.

## Source comparison and local boundary

Complete historical and approved Matt subtrees were independently acquired at
0ab1b63a410a03d3627979a109c8695de27af954 and
6fd947921b935b7e1e69293a200400f0fdd5c15f. Both contain four files:
SKILL.md, AGENT-BRIEF.md, OUT-OF-SCOPE.md, and agents/openai.yaml.
The only upstream change is CONTEXT.md -> GLOSSARY.md in the grilling step.
Both companions and metadata are unchanged.

All approved source bytes are preserved in references/upstream. The sole filename
mapping is SKILL.md -> UPSTREAM.md under ADR-0009. The two former root companion
copies were byte-checked before removal; their relative layout beside the raw
entry is preserved. The root MIT notice is retained in PROVENANCE.md.

The previous local entry altered one missing-label-config sentence. It is now
restored in raw source, and Myst handles that mapping through LOCAL-INTEGRATION.
The wrapper applies project tracker, triage, domain read/write and authority
rules. It explicitly maps glossary references in dependencies as well as triage.
Required dependencies are agentic-workflow, grilling, and domain-modeling, resolved
through the Myst namespace or local sibling paths. Their current versions remain
unchanged; they have not all completed migration. The upstream state machine,
recommendation pause, claim verification, grilling, disclaimer, briefs, and
out-of-scope method remain intact. Public frontmatter is unchanged. Added public
host metadata matches upstream and disables implicit invocation.

## Completed package checks

- All 26 source verifier acceptance tests passed. Independent source verification
  passed for eight imported bundles, 17 pending imports, and four local skills.
- All six existing CI script gates passed. Both offline Claude manifest validations
  passed. No Claude model runtime test was run.
- skills CLI 1.7.1 copied the package for Codex, Claude Code and OpenCode. Both
  resulting package trees matched source file hashes exactly. Dependencies were
  supplied separately in runtime fixtures; the CLI does not install them for us.
- A disposable index with core.autocrlf=true checkout preserved all raw bytes.
- Fresh Codex skills/list discovered the public wrapper. Its implicit prompt
  catalog omitted triage. This is discovery evidence, not native slash UI proof.
- OpenCode debug skill found the wrapper and source link. The isolated profile
  keeps the pilot's explicit-only host configuration; the package installs no
  host rules. No new OpenCode model execution ran.

## Initial interrupted attempts (retained history)

Six fresh Codex CLI sessions used the configured model in disposable fixtures.
The direct packages contain the four original upstream files. Wrapper packages
contain the Myst entry and source. Each pair has identical prompts and project
inputs except the triage package. Dependencies stay constant on both sides.
The target is a local JSON tracker, not a remote service. No real issue comments
or publication are authorized by these tests.

The brief pair uses a legacy CONTEXT.md pointer, mapped category/state labels,
a prior approved recommendation and settled scope. Both reproduced the same bug:
quote_slot(3, 2) wrongly returns accepted true and remaining_units -1; the success
case quote_slot(3, 5) returns true and 2. Both searched for existing behavior and
prior rejection records. Both announced the correct next mapped labels and open
state, but their tracker-write commands were not executed. This is partial
verification agreement, not completed brief or state-update alignment.

The glossary pair uses an explicit Records/vocabulary.md pointer. Both loaded
grilling/domain-modeling and selected that custom file. Both acknowledged the
settled WaitlistRequest term and unresolved selection policy. The glossary-write
commands were not executed, so neither completed the next question or domain
update. Intent to use the correct path is not write-path proof.

| Case | Seconds | Exit | Actual outcome |
| --- | ---: | ---: | --- |
| brief-wrapped | 96.468 | 1 | Bug reproduced; tracker update blocked. |
| brief-direct | 87.44 | 1 | Same bug reproduced; tracker update blocked. |
| glossary-wrapped | 69.351 | 1 | Custom path selected; glossary update blocked. |
| glossary-direct | 72.353 | 1 | Custom path selected; glossary update blocked; Python cache added. |
| conflict-wrapped | 59.134 | 0 | Conflicting states reported; waits for direction; no writes. |
| missing-wrapped | 77.725 | 0 | Missing mapping reported; only read-only analysis; no writes. |

The model service reported a usage limit during four sessions. Their stderr
states that automatic approval review could not complete and the requested
writes were not executed. It identifies this as a review failure, not a decision
that the action is unsafe. No retry, permission change, or manual execution of
those blocked fixture writes was used to manufacture pass evidence.

All baseline file hashes and fixture Git HEADs remain unchanged. The direct
glossary case added only __pycache__/slots.cpython-313.pyc while inspecting code;
that artifact is retained and disclosed, not counted as a glossary result.
The other five fixtures have no file changes. Both guard cases completed and
passed. Four interrupted cases are NOT passes. No alignment acceptance is claimed.

## Initial evidence and retry plan (retained history)

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-triage-migration-20261008

Source comparisons, prompts, baseline hashes, traces, stderr, partial messages,
package checks and discovery snapshots remain there. verification.json records
all outcomes including the service failures and incidental cache. Trace hashes:

- brief-wrapped: `86bc77dbcc2da204f395c0b8602a039bbf8332232fe72cd4cefee6062ef267a2`
- brief-direct: `5784f98a71714d6b0e034fae06fd6970bd96f0a10c9d83cbd265560a2f435eec`
- glossary-wrapped: `9e5f375b55fd4ee245d44958f6421d006ca7b59b30831494ddc84349efc9ea84`
- glossary-direct: `0412e475ffe76d580083972c1f89244840435e43e99ba66a2bbb6544d6a32c10`
- conflict-wrapped: `8db599c3fa1220e3b6b66f33655f8165fa626b76b651abe5c4f6e3fe26032faf`
- missing-wrapped: `ada2ba13019c975a105122284fbc642f3f993ef8fc56938fe3cc385302d42a80`

After model access works, rerun the four interrupted cases in fresh fixtures
built from the saved baselines. Keep failed attempts for comparison. Inspect actual
briefs, mapped state, disclaimer, preserved fields, custom glossary writes, next
questions, source/dependency loads, and file/HEAD changes. Then run Standards
and Spec reviews and obtain owner verification before the next skill.
External PR checkout, live tracker APIs, rejected-enhancement KB writes, native
slash UI, and Claude runtime are outside this bounded test. This migration does
not authorize publication, consumer updates, or changes to other skills.


## Completed retries and final alignment

The user requested: "Test alignment and verify if it passed," then authorized
moving to the next skill. Model access recovered on retry. All four retry-1
sessions completed successfully. Spec review found one P3 packaging gap: the
wrapper needed direct links to both source companions under ADR-0009. The fix
adds conditional links only; source files and local mappings are unchanged.
The final wrapper was retested in retry-2 for both write paths. These final
wrapped runs are paired with retry-1 direct runs using identical prompts and
project input hashes. Only the triage package differs. Failed attempts remain
separate and are not included as passes.

| Final comparison case | Evidence folder | Seconds | Changes |
| --- | --- | ---: | --- |
| brief-wrapped | retry-2/brief-wrapped | 122.053 | tracker.json |
| brief-direct | retry-1/brief-direct | 107.635 | tracker.json |
| glossary-wrapped | retry-2/glossary-wrapped | 95.658 | Records/vocabulary.md |
| glossary-direct | retry-1/glossary-direct | 74.681 | Records/vocabulary.md |

All four selected runs exit 0 and preserve their Git HEAD. The brief pair changes
only tracker.json; the glossary pair changes only Records/vocabulary.md. The
final wrapper fixtures match the current repository package exactly. Direct
entries retain the original pinned source files. Final local link validation,
raw source hash checks, and fresh three-host copy installation passed.

Both actual briefs were read. They record the same reproduced failure and passing
control, approved inputs/return shape, insufficient-capacity behavior, pure quote
contract, acceptance criteria, and exclusions. Both begin with the required AI
triage disclaimer and retain all companion template fields. Both append exactly
one agent comment, set kind:defect / queue:agent, and preserve priority, old
comments, issue identity/body, and open status. Neither implements the fix.
Direct output adds an explicit equal-capacity test example; wrapped output states
the general within-capacity rule. Both cover that boundary in meaning, but their
wording and detail are not identical. This does not prove equal coverage for all
future briefs.

The glossary texts are identical after newline normalization. Both add only the
settled WaitlistRequest definition to the custom authoritative file, preserve the
existing terms, and leave tracker state/comments unchanged. Output hashes differ
because line endings differ. Neither creates GLOSSARY.md or CONTEXT.md. Both
ask the unresolved selection-order question with FIFO, priority, and random
options; both recommend FIFO without recording it as a decision. The wrapper's
final prose uses canonical role names while direct prose uses mapped labels;
actual tracker labels remain identical and unchanged.

The earlier completed conflict and missing-config cases remain valid guard
evidence. Only direct companion links changed after those tests; the guard and
mapping rules are unchanged. The retry comparison covers local tracker state,
brief generation, dependency use, and custom glossary writes. It does not prove
live tracker API behavior, PR checkout, or every triage outcome. Claude runtime
is still deferred.

Final evidence is in alignment-final.json and check-final.py at the evidence
root. The JSON records output hashes, allowed changes, HEADs, and these traces:

- retry-2/brief-wrapped: `13e43c268cede7d90d2611b70c1285f6af82b04d8fd1dc73f0649064cb739ea9`
- retry-1/brief-direct: `ad1fca92ef7f101b0d0b7984c876a025b2651c08b0a8e8345d7941f56608c852`
- retry-2/glossary-wrapped: `a0d8893f20f5aabba80ea851ce92bdbe9ec5de78ceaddf49c71a9cba3f0588d0`
- retry-1/glossary-direct: `bfa4d6f715877a99d014f6e065f9daec2603af64af9d9e24d1e3657ce6298fdf`

Final Standards review: GREEN, zero findings. Final Spec review: GREEN, zero
open findings after fixing the companion links. Both reviewers inspected actual
outputs and confirmed the report's evidence and limits. Under the user's
conditional approval, the final triage package is owner-verified. The final
staged whitespace check passed. No publication or consumer update occurred.
