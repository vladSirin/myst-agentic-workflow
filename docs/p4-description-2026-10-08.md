# Local P4 description formatter - 2026-10-08

Status: implemented, tested, and independently reviewed; both axes GREEN.
Owner verification pending. Review base: c17c3f2. Only p4-description is added.

## Local ownership and behavior

This is local Myst content, not an upstream wrapper or modified source import.
PROVENANCE.md credits Matt Pocock's pr at approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f and Dex Horthy / Humanlayer's show-me
visual-summary idea. The single intact pr bundle remains in its own package.
There is no copied raw bundle, UPSTREAM.json, or runtime pr/show-me dependency
in p4-description. The policy declares it local; agentic-workflow is its sole
copy dependency. Public metadata keeps both explicit and model invocation.

The skill drafts English/ASCII CL descriptions with established [jobFamily][name]
tags, Summary / Evidence / Submit Risk, and a real ticket/source pointer. It
checks related submitted history, not the current tool account or unrelated
machine defaults. It uses the target CL version, local domain terms, and supplied
evidence. Unknown history, sources, or review results remain visible limitations.

Evidence preserves actual Standards/Spec verdicts, skip reasons, stable finding
anchors, dispositions, detail references, docs-alignment limits, and missing
human acceptance. Submit Risk separates code rollback from data recovery.
The formatter does not edit descriptions, review, shelve, submit, or authorize
publication. Current review-and-submit formatting remains until its separate
changeset; this task does not claim the overall Review Record retirement is done.

## Package and discovery

Independent source verification passed with 15 unchanged imports, 11 declared
pending imports, and five local skills. All 26 verifier tests, six CI scripts,
and both offline Claude manifest checks passed. skills CLI 1.7.1 copied the
complete package for Codex, Claude Code, and OpenCode; both resulting trees
match repository bytes. There is no new raw source requiring a checkout mapping.

Codex CLI 0.162.0-alpha.2 discovered one public p4-description entry. The automatic
catalog carries its Perforce-only trigger. OpenCode 1.18.35 debug skill also
found one entry with empty isolated configuration. Fixtures install no pr skill.
No installed Myst copy or host plugin configuration was changed. Claude runtime
remains deferred; OpenCode model execution and native slash UI were not tested.

## Runtime evidence

Fresh Codex runs use the normal configured host and disposable read-only fixtures.
They have captured CL5151 metadata, an unrelated nested Git mirror, supplied
submitted-history samples, domain terms Reservation/Slot, and synthetic review
receipts. The same measured before/after unit-test logs from the earlier pr
fixture are supplied; they are captured evidence, not new P4 execution proof.
No formatter reruns tests, performs reviews, or contacts a live P4 service.

Alignment here means matching the approved P4 requirements and comparing meaning
across direct, automatic, and cross-skill entry routes. This local skill has no
verbatim upstream method to call directly. Running Git-only pr for a P4 target
would violate the approved boundary and was not used as a comparison route.

| Case | Seconds | Result |
| --- | ---: | --- |
| normal-explicit | 146.371 | Correct tags, format, evidence and risk; also flags reused-log provenance. |
| normal-auto | 56.978 | Selects local skill; same change, tags, evidence and risk. |
| normal-cross | 124.494 | Fixture router selects local skill through shared contract; same core result. |
| states | 142.686 | Five drafts retain warning, blocker, skipped, missing, and unverified states. |
| retry1/missing-history | 138.482 | Provisional title/source; mismatched and conflicting receipts remain unresolved. |
| retry1/destructive-risk | 113.610 | Data-loss risk and missing backup/acceptance remain explicit; code revert is not data recovery. |
| git-exclusion | 89.434 | Declines P4 formatting for a Git target; produces a generic Git draft without CL tags. |
| retry1/conflicting-history | 159.226 | Asks which related tag pair owns the work; title remains provisional. |

Initial missing-history, destructive-risk, and conflicting-history runs exited 0
but failed to read their inputs because Windows read tools could not start.
They produced no grounded draft and are excluded. Their traces remain. Fresh
retry fixtures preserve the exact task inputs, candidate, and prompts; only
workspace paths differ. Other cases recovered from initial shell startup failures.

Normal routes all choose [runtime][rhea] from the related submitted history,
not the build account or unrelated [tools][alex] history. They use the authoritative
legacy glossary and describe <= changing to <. Their facts, review status, and
risk meaning align, but layout and caveats vary. Direct use marks the draft
provisional because the before log names the earlier fixture workspace. The
other two routes describe supplied snapshots without that extra provenance caveat.
No claim of identical output, independent test provenance, or live readiness is made.

The five-state case keeps W1 open with its durable link and B1 open/blocking with
its file/line anchor even without a detail report. Both remain visible in Submit
Risk. It preserves the user-confirmed Spec skip, absent before/after evidence,
missing reviews, unchecked docs, and required but unperformed human acceptance.
No standalone Review Record or required review pass count is added.

The missing-history case also finds conflicting same-version review records in
the supplied files. It keeps the final results unresolved instead of selecting a
GREEN receipt. Missing title tags and ticket remain explicit placeholders; the
draft is not ready to apply. The destructive case uses [data][rhea] from related
history and states that reverting code cannot recover lost live assignments.
It identifies missing loader revision, backup proof, and human acceptance, and
does not turn the submitted-intent label into a claim of actual submission.

All eight selected cases have exact candidate packages, unchanged inventories /
HEADs, and ASCII description bodies. No fixture contains a pr package, and no
observed command reads a pr workflow. The conflicting-history retry asks whether
[runtime][rhea] or [gameplay][noah] owns the CL rather than choosing one. Its draft
keeps placeholders and notes unresolved title ownership in Submit Risk.
A personal-memory read was rejected by automatic approval review in that retry;
it continued with the allowed fixture sources. No broader access was needed.

## Limits and retained evidence

These are bounded formatter tests with existing host guidance and memory; they
do not isolate each instruction's effect. Real submitted-history queries, live
CL updates, P4 client rendering, every shelf/submitted scenario, ambiguous VCS,
and non-ASCII identifier aliases remain untested. Synthetic verdicts are supplied
input, not actual reviewer acceptance. The installed publication protocol and
consumer parsers remain unchanged and still need their own migration checks.

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-p4-description-20261008

Complete fixtures, prompts, traces, replies, copy/discovery logs, before hashes,
and package-checks.json are retained. verification.json / verify.py check candidate
identity, unchanged files/HEADs, ASCII draft bodies, and absence of pr dependencies.
Failed executions stay separate from selected successful cases.
acceptance-checks.json records the eight selected cases and three excluded starts.

Trace SHA256:

- normal-explicit: `50df4026abed44b4c57f4e3ac75e16200df25339d0fd93293d94c46fd520cd0b`
- normal-auto: `9b95c2e10940111e91722bad42b9a54f41cf5929f5bba52607a2af25657d9032`
- normal-cross: `f8811913d0cc77edc2bddb48e097e64d005ccbfe3fc60dfd67c89c0c41c4c61a`
- states: `9c8db34874e6c67d14e0e9968e15bcc3dd4e49432cd3b745fb700a6373220bd5`
- missing-history: `a5e7ced8c92db7bd133d212bb0307555b320724e3f1172efe0afd4b30daa18dc`
- conflicting-history: `9d09f5234e4321673acd64f131ecd32e4e0982c69fa462c039e6d661c37643ff`
- destructive-risk: `db2dbc7b0eb7b34ae4761fdfec10d629a51af43977d5eb58aff61188ba7c3b00`
- git-exclusion: `4a11d1e1486bf27d71d40b7c4f6c2eee29dee8b64fd41089164fb7a589bccedc`
- retry1/missing-history: `e9fc3a34328d69c9ee73d9b30430a7aa9bf2667203e5005639188b5ea8e2bc7a`
- retry1/destructive-risk: `96b818e095dd46c7ffc9b0d9ab7c5a009bd5c50fb170fec00b769dae601f09a9`
- retry1/conflicting-history: `ae7b5ca08e3e2ff9017d4911436ca9a4775e9afc22d90791db20a7843ace87e0`

Final Standards review: GREEN, zero actionable findings. It confirmed local
ownership, attribution, P4 routing, evidence limits, and accurate test reporting.
Final Spec review: GREEN, zero actionable findings. It independently checked all
eight selected outputs, artifact hashes, complete inventories, candidate packages,
and HEADs against the approved requirements. Both retained the stated limits.
The final six CI gates and staged whitespace check passed. Owner verification
remains pending.
No push, PR, merge, release, live CL change, or consumer update is included.
