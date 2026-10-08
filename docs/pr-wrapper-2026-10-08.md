# PR source and wrapper adoption - 2026-10-08

Status: implemented, tested, and independently reviewed; both axes GREEN.
Owner verified d8c2c53 on 2026-10-08 after alignment recheck.
Review base: eaf9944. This changeset adopts pr alone.

## Source and local integration

This is a new import; there is no prior Myst pr method to update or compare.
The complete Matt subtree skills/engineering/pr at approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f contains SKILL.md, CREDITS.md, and
agents/openai.yaml. All three files remain byte-for-byte intact under
references/upstream. Only SKILL.md maps to UPSTREAM.md under ADR-0009.
UPSTREAM.json records the full inventory and hashes. Public metadata matches
upstream. PROVENANCE.md includes the MIT notice; CREDITS.md retains Dex Horthy /
Humanlayer's show-me attribution. No show-me runtime dependency is needed.

Myst owns the Git-only guard, target selection, glossary mapping, ticket/source
pointer, and concise review evidence. The wrapper loads LOCAL-INTEGRATION first;
copy installs require agentic-workflow. A nested Git mirror cannot make Perforce
work eligible. The upstream three-section template, visual menu, and risk method
stay intact. REVIEW-EVIDENCE.md preserves actual verdicts, unresolved findings,
skip reasons, missing evidence, docs-alignment limits, and missing acceptance.
No extra Review Record or mandatory pass-count summary is added by this formatter.
Review-and-submit still owns review execution, preflight, finding handling, and
publication. Its existing format remains until its separate migration.

## Package and host checks

Independent source verification passed: 15 imports, 11 declared pending imports,
four local skills. All 26 verifier tests, six CI scripts, and both offline Claude
manifest checks passed. skills CLI 1.7.1 copied the whole package for Codex,
Claude Code, and OpenCode; both resulting trees match repository hashes.
A disposable core.autocrlf=true checkout preserved every raw source byte.

Codex discovery found one public pr entry with its full Git-only description.
The automatic prompt catalog includes its Git PR trigger, but truncates the
later description text. OpenCode 1.18.35 debug skill found one public entry with
empty isolated configuration. Raw references did not become another entry.
These are discovery checks, not native slash-UI or OpenCode model-execution
proof. Claude runtime stays deferred. No installed Myst copy or host plugin
configuration was changed.

## Behavior and alignment

Codex CLI 0.162.0-alpha.2 used disposable fixtures and the normal configured host.
Direct cases load the complete approved source under its original entry name;
wrapped cases load the exact candidate. Each pair has identical prompts and
project inputs outside the pr package. Both receive the same project contract
and request to include the supplied source pointer and review facts. This tests
equivalent task requirements, not an upstream default with no project guidance.
Existing host instructions and memory also reinforce routing; the tests do not
isolate the wrapper as the sole cause of safe selection.

A real fixture test measured the full-capacity Reservation bug before and after
changing <= to <. Paired cases receive the same captured outputs. Review verdicts
are explicitly synthetic supplied receipts, not claims that live reviews ran.
Records/CONTEXT.md owns domain terms; root GLOSSARY.md is an unrelated decoy.

| Selected case | Seconds | Result |
| --- | ---: | --- |
| git-wrapped | 79.669 | Three-section draft, diff sketch, measured evidence, supplied GREEN axes, source pointer, two-way door. |
| git-direct | 77.969 | Same facts, vocabulary, format, and risk; different grouping. |
| retry1/states-wrapped | 139.128 | Five drafts preserve WARNING, BLOCKING, skipped, missing, and unverified states. |
| states-direct | 144.876 | Same five-state handling, with different visual and blast-radius wording. |
| p4-direct-request | 123.233 | Reads local guard, rejects upstream pr, uses existing P4 format. |
| p4-auto-request | 113.269 | Chooses existing P4 workflow; no upstream pr load. |
| p4-cross-request | 91.443 | Fixture router follows shared VCS contract and declines Git-only pr. |

Initial states-wrapped exited 0 after 60.721 seconds but could not read inputs:
shell startup failed and its Node reader also failed. No draft was produced, so
it is excluded. The successful fresh retry has identical fixture bytes and prompt;
only its workspace path differs. The failed trace remains. Other runs recovered
from initial shell errors with successful read-only retries.

Both normal drafts use Reservation and Slot, the same comparison diff, before
failure, after pass, supplied review results, and undo/impact information. Neither
treats those receipts as publication approval. The grouping and wording differ.

Both five-state replies preserve W1 as an open warning with an existing detail
link, and B1 as an open blocker in Evidence and Merge Danger. They retain the
Spec skip reason, absent execution/review evidence, unchecked docs, and required
but missing human acceptance. Each body keeps the three upstream headings and
source pointer. Direct uses pseudocode and Reservations as the blast-radius label;
wrapped uses Python and Capacity. Both describe capacity-admission impact. Only
direct says proposed in the missing case's Summary; both state no execution and
no review in Evidence. Neither invents GREEN or manual acceptance.

All seven selected runs left full file inventories and HEADs unchanged; P4 cases
pin the nested mirror HEAD. Packages match the candidate or complete source.
Successful read commands show wrapped Git cases loading the shared contract,
raw source, evidence additions, and authoritative legacy glossary. The normal
wrapped case also reads CREDITS.md. No formatter reran tests or reviews.

All P4 cases recognize CL5151 as Perforce despite mirror/. No command loads the
upstream pr workflow or local Git evidence additions. The direct route reads
the public guard; automatic and cross-skill routes use the shared contract.
Routing searches may traverse skill filenames; this is not workflow invocation.
Direct and automatic cases consult the installed review-and-submit P4 format.
The fixture router states that a dedicated P4 formatter is unavailable. Their
provisional P4 drafts keep unknown title-tag placeholders and disclose that the
supplied Git review does not verify CL5151. These are exclusion checks, not
acceptance of the future p4-description skill or the old publication protocol.

## Evidence and limits

Seven selected cases passed, with one environment failure retained. This supports
bounded semantic alignment and configured-host VCS exclusion, not identical prose
or a statistical guarantee. Live GitHub/P4, every visual/risk choice, stale or
missing source pointers, and ambiguous target ownership remain untested. No PR
or CL was created, changed, or published. No subagent review ran inside the
formatter fixtures. Protocol and consumer-parser migration remain separate.

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-pr-migration-20261008

Source inventory, full fixtures, measured logs, prompts, traces, replies, package
and discovery logs, and before hashes remain there. verification.json and verify.py
record paired inputs, package identity, trace/reply hashes, and unchanged files /
HEADs. acceptance-checks.json names selected/excluded runs; package-checks.json
records package checks.

Trace SHA256:

- git-wrapped: `a0ad6480eda545c627f638d95e2ff0a89723726d62044dd81be2e1e9d0d556e6`
- git-direct: `4a770ee0dc40d279823649b61d0e1a29e589ea4fbe4edc2798a0b4f3c68c2bae`
- states-wrapped: `bee0aa92d26968c5fabece05044beebf373f4ae8804c5f0cfa711aa4cfe5c5b5`
- states-direct: `a811bf835acb0cbb8bc68054dc45b72e738327a860d05afefa4a4ec6289fe0a3`
- p4-direct-request: `bceeb4b8c78aeaab2ec2c9767fcb9a0d853dc1e8e62c1527f3b28f9a2ce6f728`
- p4-auto-request: `2ca81e6b4d19cde51b61ed9cf91484ffa52cb9a5c1080bff46fefa0d165bf577`
- p4-cross-request: `c7fad71488d6228c02a8cfd98ac7be55bbb6dfe01cdb7a55e1ce9bbfa95e79aa`
- retry1/states-wrapped: `f9a8220277c719137585d31752838363d41273bdca1b5db70f0b226fa5abcedc`

Final Standards review: GREEN, zero actionable findings. It confirmed source
ownership, Git-only routing, credit preservation, and accurate evidence limits.
Final Spec review: GREEN, zero actionable findings. It checked actual replies,
source/package identity, unchanged inventories/HEADs, the seven selected cases,
and P4 exclusion. Both retained the stated test and host limits.
Final six CI gates and staged whitespace check passed. Owner verified d8c2c53 on 2026-10-08 after alignment recheck.
No push, PR, merge, release, or consumer update is included.


## Alignment recheck and owner acceptance

The owner requested alignment testing, conditional verification, and continuation.
The seven selected saved cases were rechecked against d8c2c53: exact package
identity, paired inputs, trace/reply hashes, unchanged files/HEADs, and the
three-section output checks still match. Actual review states, evidence limits,
and risk meanings align; presentation differences remain documented above.
alignment-recheck.json records PASS with zero new model calls. The initial
reader-startup failure remains excluded. Under the owner's conditional approval,
d8c2c53 is verified. Claude deferral and all stated coverage limits remain.
