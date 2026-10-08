# Review and submit format integration - 2026-10-08

Status: implemented, tested, and independently reviewed; both axes GREEN.
The initial Standards WARNING is repaired and rechecked. Owner verification pending. Review base: 62d3738. Only review-and-submit changes behavior; README,
migration state, and this evidence accompany it. No release or consumer migration.

## Change and ownership

This is local protocol content. Git uses the accepted Myst pr wrapper and intact
upstream bundle; Perforce uses the accepted local p4-description. The shared
contract resolves target VCS, dependency identity, tracker, and domain pointers.
A nested Git mirror does not select Git formatting for a P4 target.

Summary / Evidence / Merge Danger (Git) and Summary / Evidence / Submit Risk
(P4) replace What / Why / Notes. Separate line-start Standards:/Spec: results
live inside Evidence. The standalone Review Record, mandatory description pass
counts, narrative cap, and old append-block repair are retired. Detailed reviewer
identity, revision anchors, pass history, and finding dispositions remain in the
actual review evidence; existing durable detail is linked when useful. Essential
unresolved findings stay in the body when no usable detail exists. No new report
is required solely for formatting. Missing review evidence cannot become GREEN.

The protocol supplies actual results to the formatter after the decision and
refreshes them after preflight. It validates the final description again if its
text changes. Reviewers still report only. Actual review, finding handling,
re-review, documentation checks, and publication authority stay with the protocol.

Step 5 aggregation / fix ladder, fix discipline, and all Step 6 authority text
match the base exactly. The closed formatting-repair entry now covers rendering
existing verified evidence. It skips a reviewer pass, never the approval gate.
First-pass GREEN with an unchanged named changeset retains the existing approval
shortcut. WARNING, fixes, preflight warnings, missing ID, and scope growth retain
renewed decision requirements. ready-for-human and unattended parking remain.

P4 mechanics now select the exact CL files before p4 diff -du. There is no
unsupported p4 diff -c filter. Added/deleted content, base revisions, binary
limits, and workspace versus shelf evidence stay explicit. Git bodies use UTF-8
files and --body-file; storing evidence does not create a PR or rewrite history.
Both independent review axes are GREEN after the affected Standards recheck.
The reviewer confirmed the INFO repair and its missing-decision control; no
remaining actionable finding. Owner acceptance and publication stay separate.
Copy dependencies are agentic-workflow, code-review, and the target formatter.
README also identifies this transitive dependency for implement and tdd.

## Bounded runtime tests

Codex CLI 0.162.0-alpha.2 ran four initial disposable sessions and one targeted
repair session on the normal configured
host. The fixtures supply explicit local Myst paths, target VCS, tracker/domain
pointers, and a read-only dry-run request. No publication action is permitted.
The first three prompts also request the axis layout; the fourth removes that
layout hint and tests selection from the skill itself. These tests do not isolate
each instruction from normal host guidance or prove every possible workflow.

| Case | Seconds | Observed result |
| --- | ---: | --- |
| git-fresh | 297.288 | Two fresh independent axes return GREEN; uses Git pr wrapper and source; correct three sections and separate Evidence fields. |
| p4-fresh | 331.240 | Two fresh independent axes return GREEN on captured CL5151; exact file selection; uses p4-description, not the nested Git repo. |
| states | 242.884 | Five captured descriptions and eleven hypothetical authority decisions retain evidence and gate limits. |
| natural-format | 234.840 | Same five cases and eleven decisions without layout hints; correct axis lines inside Evidence and no Review Record. |
| info-handoff | 137.621 | Final-candidate repair: recorded ACCEPTED INFO is rendered; missing-disposition control stays incomplete and returns to the protocol. |

Fresh cases change can_reserve from active <= limit to active < limit. Before
and after tests were actually run on each local fixture: before fails equality,
after passes below/at/above capacity. Models also run permitted fresh checks.
Git verifies source hashes against pinned committed revisions. P4 verifies the
captured workspace hash; its source-text hashes do not authenticate log bytes,
and the output states that limit. No live P4 test is claimed.

Saved runtime sessions confirm separate Standards and Spec spawn calls with no
model/effort downgrade. Git and P4 use the same pinned scope for both axes. P4
calls only the recorded mock tool: no native p4 or Git mirror review. The Git
Spec reviewer adds an INFO about synthetic coverage; the initial body retains
that limit but omits an ACCEPTED/DEFERRED label. Standards review identifies this
as a required handoff repair. The local evidence companion now checks every
remaining WARNING/INFO disposition against the protocol decision and returns a
missing decision as a gap; it never invents acceptance. Initial traces remain
unchanged. The targeted final-candidate repair test passes both controls. The
main protocol session records ACCEPTED for the intentionally limited synthetic
scope, with the actual reviewer receipt and a reason retaining production/live
limits. This is a Step 5 finding decision, not human acceptance or publication
authority. The missing-decision control stays incomplete and requests that
actual decision without copying it from the positive case or rerunning reviews.
The warning and blocking cases below already preserve their supplied dispositions
and anchors.

Five description cases cover docs-only work, a UE asset with missing visual
acceptance, a WARNING, a confirmed Spec skip, and missing reviews. Both runs keep
W1 WARNING/DEFERRED and B1 BLOCKING/OPEN with artifact/revision anchors and risks.
Compile success does not become visual acceptance. Missing reports stay not
reviewed; planned tests stay unrun. Captured GREEN results stay identified as
supplied reports, not new live review or acceptance. Absent referenced spec/log/
detail files remain stated limits, not fabricated contents.

The eleven decision cases preserve the existing outcomes: named first-pass
GREEN; WARNING; post-fix GREEN; preflight warning; missing publication ID;
re-raised declined blocker; ready-for-human; unattended without goal signal;
missing reviews; closed formatting repair; and scope growth. Formatting repair
avoids re-review while retaining the decision gate. No decision is executed.

All five inventories match before/after. Git/P4 fixture HEADs stay unchanged;
all initial candidate skill copies matched the tested draft. Only the local
evidence companion changes for the review repair; the targeted test uses that
final exact copy and confirms unchanged workspace/HEAD. The four initial runs
are not repeated for this narrow INFO check. P4 fixtures contain no pr
package, and observed commands do not read a pr workflow. No CL, PR, consumer
file, installed Myst package, or host plugin configuration was changed.

Windows shell startup errors and trusted Node kernel failures occurred inside
runs; successful reads recovered before outputs were accepted. Missing fixture
detail files are deliberate negative evidence. The expected failing before test
is not a failed integration case. All attempts remain in their full traces.

## Known consumer compatibility

Read-only inventory covered the known UE_Blank_Proto description preflight,
server audit, its hook regression fixtures, and doc-audit references, plus devkit
tools/CI. This is not an inventory of every consumer repository. No deployed
trigger table or credentials were read. The known scripts were copied unchanged
to temporary fixtures and their original hashes checked again afterward.

- .claude/scripts/check-cl-description.sh: tag and ASCII preflight. Stdin mode
  avoids p4 change -o or CL edits.
- Tools/P4Triggers/p4-submit-audit-server.sh: its documented SA_TEST_* interface
  skips server calls. P4ROOT points to temporary logs; no webhook argument is
  passed. The audit always exits 0, so assertions inspect the warning log.
- .claude/scripts/test-hooks.sh: known regression cases retain old markers and
  the mid-sentence negative control. No runtime hook registration occurs.
- .claude/scripts/doc-audit.sh: inspected for description/review-marker parsing;
  no matching parser reference was found. Devkit tools/CI have no required old
  Review Record/pass-count parser in the searched scope.

The audit recognizes unbulleted line-start Standards:/Spec:. The inline
"- Review: Standards GREEN; Spec GREEN." form does not satisfy this marker check.
DESCRIPTION-EVIDENCE.md owns the compatible line placement. No consumer edit is
needed for the two inspected script versions.

Ten static controls passed: GREEN, WARNING, BLOCKING, confirmed skip, missing
reviews, old-record control, inline-review negative, no-evidence negative,
bad-title negative, and non-ASCII negative. All eleven actual P4 bodies passed
the copied tag/ASCII preflight and avoided the no-review-marker warning. Even
not-reviewed fields satisfy the loose audit marker; this proves field presence
only, not GREEN, acceptance, or publication readiness. The protocol keeps the
actual review gate separate.

The deployed consumer revision remains unverified. Confirm required consumers
before exposure; any incompatible required parser is a separately reviewed
release dependency. Offline format compatibility does not prove live preflight
or a live submit audit, and a quiet submit is never audit evidence.

## Package checks and retained evidence

Pinned upstream verification passes: 15 imports, 11 declared pending imports,
five local skills. All 26 verifier tests, six current CI script checks, and both
offline Claude manifest checks pass. skills CLI 1.7.1 copy-install selects the
complete review-and-submit package for Codex/Claude/OpenCode; generated trees
match source bytes. Fixture dependency packages also match source. Fresh Codex
skills/list and OpenCode 1.18.35 debug skill find the candidate public entry.
Claude runtime remains deferred; no OpenCode model call or native slash UI test.

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-review-submit-format-20261008

Retained: prompts, complete fixtures, before inventories/HEADs, traces/final
outputs, measured test logs, mock P4 calls, review-dispatch summary, verification
and acceptance checks, actual Git reviewer receipts, the main disposition
decision and info-repair-checks.json, authority-text equality checks, consumer inventories/
controls/rendered results, copied scripts/logs, package and discovery logs,
and independent-reviews.json.

Trace SHA256:

- git-fresh: `16d94cdabe8330b3327495f009c4a9a4e78f4cfe4cb1a5a94661289a78cc3188`
- p4-fresh: `a803beb5f1044c6a121b6b4d203962ca1db5e643c37cbd3d63ef1acd1037c12f`
- states: `d27e1e0e93682f6bc84f65ca41051a71b2656f0c7266708530e31fcf5edff759`
- natural-format: `651cc9dcd5c99e42bc6e452419c7c64e2d1735faec882295bb4040687aa39af2`

- info-handoff: `3ee487faa5552b9252855b028d00a11b20c75a689c96516e1b4dd75d99a5a9e0`

Consumer source SHA256:

- preflight: `d6624ee48627c436ebd8315f4e0a33e20fdceba039d33a0031435f08189472ae`
- audit: `2a73fd858b5eeb93fe299fe19177298e19cad22b702e385b6db357aaf5a7990c`

Actual blocker repair/re-review, docs-alignment execution, goal-mode publication,
shelf/submitted snapshots, and live description application remain untested.
The state/authority cases are hypothetical decisions over captured input.
No full migration, release readiness, live acceptance, or identical prose is claimed.
