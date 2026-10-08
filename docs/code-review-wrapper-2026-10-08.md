# Code-review source and wrapper migration - 2026-10-08

Status: implemented, tested, and independently reviewed; both axes GREEN.
Owner verified bd7fbd3 on 2026-10-08 after alignment recheck. Review base: cbed6f0. Only code-review migrates here.

## Source and local integration

The complete Matt subtree skills/engineering/code-review was independently
fetched at its historical attribution pin
6654f6b60cd9d5be8b54c6fafe44346dabeb3b76 and the approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f. Both contain two identical files:
SKILL.md and agents/openai.yaml. There is no upstream method update to claim.
The prior local files have CRLF line endings; their text matches the historical
source after newline normalization, but their bytes differ. Both approved files
are now preserved byte-for-byte under references/upstream. Only the entry name
maps from SKILL.md to UPSTREAM.md. UPSTREAM.json records both original names and
SHA256 values. PROVENANCE.md retains credit and the complete MIT notice.

Myst's public wrapper selects myst-dev-kit:code-review, or the full Myst entry
path in copy hosts. It loads LOCAL-INTEGRATION and REVIEW-INPUTS.md to map project
tracker/spec pointers and Git/Perforce evidence. agentic-workflow is the required
copy dependency. The upstream method remains intact: separate Standards and Spec
reviews, the full twelve-smell baseline, and separate final reports. Public host
metadata matches upstream; model invocation remains enabled.

The local adapter pins the requested range or CL version, preserves caller scope
and brief requirements, includes added/deleted content, and stops on missing
review evidence. A nested Git mirror does not make a P4 target Git work. Pending
P4 selection uses opened -c followed by diff -du with explicit paths. Local CLI
help confirmed that diff has no -c option and pending describe has no diff body.
No live P4 server was contacted. Review-and-submit retains description formatting,
review disposition, preflight, and publication authority for its later changeset.

## Package and host checks

All 26 verifier tests, independent source verification (14 imports, 11 declared
pending imports, four local skills), six CI scripts, and both offline Claude
manifest validations passed. skills CLI 1.7.1 copied the complete package for
Codex, Claude Code, and OpenCode; both resulting trees match source hashes.
A disposable core.autocrlf=true checkout preserved all raw source bytes.

Codex discovery found the public wrapper and the distinct namespaced competing
review skill. Prompt inspection also included the wrapper in the automatic catalog. The raw reference did not become another entry. OpenCode 1.18.35
debug skill found the wrapper with empty isolated configuration. These checks
cover discovery and package loading, not native slash UI or automatic selection.
Claude runtime remains deferred. No new OpenCode model run was made.

## Direct versus wrapped behavior

Six fresh Codex CLI 0.162.0-alpha.2 executions used synthetic code with one naming violation and two
behavior defects. Direct cases use the complete approved source with its original
entry filename. Wrapped cases use the exact repository candidate. Each pair has
identical project inputs and prompts outside the code-review package. Both have
the same project contract and agentic-workflow dependency. P4 adaptation is also
provided in that shared contract: this does not test unaided upstream P4 support.

| Case | Seconds | Result |
| --- | ---: | --- |
| git-wrapped | 132.657 | Naming violation and both behavior defects found. |
| git-direct | 134.464 | Same defects; labels naming again as an overlapping heuristic. |
| p4-wrapped | 211.052 | Same defects; also identifies broken keyword argument names. |
| p4-direct | 159.306 | Naming violation and both behavior defects found. |
| missing-wrapped | 116.185 | Reports unavailable edit/add/delete evidence; no reviewers dispatched. |
| nospec-wrapped | 137.850 | Standards reviewer only; explicitly skips Spec at the user's request. |

All six exited 0. Every before/after file inventory and fixture HEAD is unchanged.
Package hashes match the candidate or complete approved source. Saved session
logs confirm two successful review dispatches in each normal case, none for
missing evidence, and one for the explicit no-spec case. Actual read commands
show wrapper cases loading the local adapter, shared contract, and raw source.

Both paired reviews find that n/c violate the public parameter naming rule,
that <= admits jobs when the queue is full, and that is_closed(0) incorrectly
returns False. Both accept deletion of the unused obsolete helper. The extra
P4 wrapped finding is valid: renaming current_jobs/capacity breaks keyword calls.
The Git direct run counts the naming smell separately from the hard violation;
the P4 wrapped run labels it as overlap. Findings and counts are therefore not
identical. They align on all seeded defects and preserve separate axes. These
bounded observations do not establish statistical equivalence or identical prose.

P4 cases reviewed captured pending workspace CL4242 through a read-only stub.
They selected exact CL files, read the edit diff, complete added file, and deleted
base. The misleading nested Git mirror did not become the target or a finding.
No live-service freshness, real shelf/submitted diffs, binary files, moves, stale
caller evidence, or every Git staging mode was tested. Fixture evidence is
explicitly a snapshot, not a claim about a real current changelist.

## Competing-plugin routing

The owner approved temporary registration of the synthetic
competing-review@myst-review-test plugin in the normal Codex host. Authentication
stayed in place; no credential file was copied. The marketplace path and enable
setting were supplied as process overrides. A fresh catalog showed both the
fixture's full-path Myst entry and competing-review:code-review. Separate fresh
Git and P4 runs exercise explicit full-path selection with this competitor
present. Both passed: Git in 128.431 seconds and P4 in 183.931 seconds.
Both read the wrapper, local adapter, shared contract, and raw upstream source;
neither read the competitor body or returned its sentinel. Each dispatched two
reviewers, found the three seeded defects on separate axes, and left all files
and HEADs unchanged. The P4 report explicitly states the capture age is unknown.

The exact test plugin was then removed through the host CLI. host-cleanup.json
confirms its registration and cache are gone, and the plugin and marketplace
configuration tables match the pre-test baseline. No credential copy exists in
the isolated test home. The earlier credential-copy and unapproved registration
approaches were blocked before execution; the successful route used normal
host authentication and the owner's explicit temporary-registration approval.

This tests the copy-host path route. It does not replace the installed Myst
release with the candidate, prove namespace-only invocation of this candidate,
or prove automatic engine selection. Those limits do not change the wrapper's
explicit namespace/full-path selection contract.

## Evidence and review

Evidence root:
C:/Users/Shado/AppData/Local/Temp/myst-code-review-migration-20261008

Source and local comparisons, complete fixtures, commands, traces, final replies,
file inventories, source hashes, discovery and packaging logs are retained there.
verification.json and verify.py record fixture integrity, package identity,
paired inputs, dispatch calls, trace/reply hashes, and unchanged HEADs.
collision/ holds the separate competitor cases and discovery capture.

Trace SHA256:

- git-wrapped: `3b734ad958b1b276a410c20dec9169a7e03da3fcf0b49b76b6aec6b4dfa88247`
- git-direct: `c819907f769b9f15576bfd910aedf1e0ae06919022050d8a300aa319b75fed1e`
- p4-wrapped: `9477ffa4ab12f9b5cf34f037e0c1ded67b966fda8c36f4b16a601864c6656a11`
- p4-direct: `c817e539ec50db28fb40d3fdbff29a0a605ee6d8568373cb599c9b77b57a4b30`
- missing-wrapped: `adf1489069fabe1861686a35e2c552c791f3999aad5614a8793e084ec4cd77e1`
- nospec-wrapped: `1c9c206c60e9bddcfdd727725f6103a750bcc430be429cb2bf87d1b01326fd14`
- collision/git-wrapped: `6648db6dd076ae4bdbb79f865ca572c365a8e96fa4f8ff50d04bfdaecd312761`
- collision/p4-wrapped: `4a260359e58469e3b3064cea4f8cebf3acc63661666d4ab1594776be9f255faf`

Final Standards review: GREEN, zero actionable findings. It confirmed source
ownership, local input mapping, reported runtime differences, and plugin cleanup.
Final Spec review: GREEN, zero actionable findings. It checked the eight saved
replies and trace hashes, candidate identity, unchanged inventories/HEADs, input
guards, and full-path competitor routing. Both preserve the stated test limits.
The six CI scripts and staged whitespace check also passed on the final content.
Owner acceptance is recorded below. No push, PR, merge, release, or consumer update
is included.


## Alignment recheck and owner acceptance

The owner requested alignment testing, conditional verification, and continuation.
All eight saved runs were rechecked against bd7fbd3: package identity, unchanged
inventories/HEADs, trace/reply hashes, and the recorded plugin cleanup still match.
The actual direct/wrapped replies align on every seeded defect; the extra valid
P4 keyword finding and overlapping naming count remain disclosed above.
alignment-recheck.json records PASS with zero new model calls. Under the owner's
conditional approval, bd7fbd3 is verified. Test limits and Claude deferral remain.
