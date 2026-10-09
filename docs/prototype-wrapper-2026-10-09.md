# Prototype source and wrapper - 2026-10-09

Status: implemented, alignment tested, and independently reviewed; both axes
GREEN. Owner verification pending. Review base: f783dd4. This changeset migrates
prototype alone.

## Source and local integration

The former Myst SKILL.md, LOGIC.md, and UI.md exactly match Matt's approved pin
6fd947921b935b7e1e69293a200400f0fdd5c15f. There is no method delta. The complete
skills/engineering/prototype subtree contains those three files and
agents/openai.yaml. All four remain byte-for-byte intact under references/upstream;
SKILL.md alone maps to UPSTREAM.md under ADR-0009. The former root companions
move into that bundle, rather than being edited or omitted. UPSTREAM.json records
the complete inventory/hashes. PROVENANCE.md retains the upstream MIT notice.
Public Codex metadata matches the source and permits model/user reach.

Myst's public entry loads LOCAL-INTEGRATION, declares agentic-workflow as its copy
dependency, and resolves project domain/tracker pointers and target VCS. It links
both source branches and resolves their SKILL.md capture reference to the packaged
UPSTREAM.md. Git retains the throwaway-branch capture method within authorized
scope. Perforce uses the project's capture workflow and issue; a nested mirror
does not permit Git branch/commit capture. Missing capture destinations must be
resolved before capture; shelving/submission retains the publication protocol.
Only actual validated decisions can enter real code. A candidate prototype does
not establish user acceptance or close implementation work. No new orchestration
or test suite was added to the skill or upstream source.

## Package and host checks

Independent source verification passed: 17 imports, nine pending imports, five
local skills. All 26 verifier unit tests, six CI scripts, and both offline Claude
manifest validators passed. skills CLI 1.7.1 copied the complete package for
Codex, Claude Code, and OpenCode; resulting .agents/.claude trees match the
package hashes. A scoped -text attribute preserves all four raw files through
a real core.autocrlf=true Git checkout.

Fresh Codex discovery found one enabled public fixture entry with the full local
trigger. The automatic prompt catalog includes that candidate's logic and UI
branches. OpenCode 1.18.35 debug skill with an empty isolated config found one
public wrapper entry; raw references did not become another skill. These checks
do not prove native slash-menu UI or OpenCode model execution. Claude model tests
remain deferred. No installed Myst copy or host configuration was changed.

## Runtime comparisons

Evidence root: %TEMP%/myst-prototype-migration-20261009. Five fresh Codex CLI
0.162.0-alpha.2 runs used the normal configured host and disposable Git fixtures.
Direct cases load the entire raw prototype subtree with its original entry name;
wrapped cases load the exact candidate. Both use the same agentic-workflow
dependency and project contract. Paired prompts and every project/dependency
input outside prototype are identical. Existing host instructions and installed
skills remain present; full fixture paths select the intended entry. These tests
compare equivalent project requirements, not a wholly upstream stack without
local conventions, and do not isolate the wrapper as the sole cause of safety.

| Case | Seconds | Grounded result |
| --- | ---: | --- |
| logic-direct | 165.752 | Single self-contained HTML beside the real module, pure model, visible state, free play and three guided tabs; evaluation open. |
| logic-wrapped | 206.139 | Same method and tested outcomes; adds an artifact/open-question pointer to the tracker without acceptance or closure. |
| ui-direct | 318.189 | Three distinct layouts on the existing /settings route; one HTML file, shared floating switcher, original data/viewer context, production baseline. |
| ui-wrapped | 289.165 | Same UI method and behavior; helper JS/CSS files and shared switcher beside the host page, plus draft tracker/run notes. |
| p4-capture | 65.822 | Copies the approved primary source unchanged to the agreed local archive and records supplied answer/capture-pending; no Git action through the mirror. |

All five runs completed with grounded reads and successful exits. Scoped shell
retries recovered setup-refresh/helper_unknown_error failures. There were no
excluded model runs. Fixture HEADs/branches, skill packages, real logic module,
domain docs, and UI server stayed unchanged. Draft build cases keep the tracker
in progress and the verdict/winner open. Wrapped paths add draft traceability
where the direct paths only report the artifact; that is a disclosed difference,
not evidence of owner acceptance. No prototype tests were added to the fixture.

## Actual artifact behavior and limits

The browser-control helper failed twice at startup. Bundled Playwright could not
find its default headless Chromium binary. The checks instead used preinstalled
Edge 154.0.4258.62 in new isolated headless profiles, with no user profile or
credentials. Browser requests were limited to local files or loopback fixture
servers. Every helper browser/server closed after the check. The external checks
and screenshots remain in temp evidence, outside the prototype and skill package.

Logic checks executed both extracted modules in an empty Node VM without DOM
APIs. The eight tested transition states match after normalizing player/claim IDs:
claim, confirmation, full-capacity refusal, provisional cancellation, refusal to
confirm the canceled claim, slot reuse, and refusal to cancel the confirmed claim.
Each action preserves its input state. Actual browser clicks ran all three
walkthroughs per output and confirmed reset behavior, step progression, and no
page errors. Screenshots show the question, full relevant state, free-play
controls, guided tabs, and pending evaluation.

The direct model allocates claim IDs; the wrapped model uses three fixed claims
per run. State shape, free-play controls, and scenario grouping differ. The
comparison proves the requested cancellation/capacity outcomes, not equivalence
across every unrequested claim-lifecycle behavior or exact output bytes.

Both UI outputs retain the same header/sidebar, viewer, settings data/fetch,
preview input, and existing route. Browser checks passed forward/back wrap,
keyboard cycling, input-arrow protection, URL/query/hash preservation, reload
stability, and memory-only draft retention. Requests were GET-only; no page errors
occurred. APP_ENV=production retains the exact original settings subtree, with
no switcher or variant activation. All six layout screenshots were inspected.

Direct layouts are a stacked settings list, summary/editor split, and capacity
hero with a details table. Wrapped layouts are an overview, compact register,
and label editor with a context panel. Each set changes structure and information
hierarchy; they are not merely recolored copies. Exact designs, state presentation,
and file organization differ. This supports alignment of the UI method and
behavior, not pixel equality, a chosen winner, or visual owner acceptance. Only
the preferred existing-page shape was exercised; the new-page fallback was not.

The Perforce fixture explicitly declares ownership despite its Git mirror and
supplies an already approved synthetic decision plus a local capture procedure.
The archive bytes match the primary source. The ticket states capture-pending,
retains in-progress implementation, and distinguishes the supplied receipt from
a new runtime verdict. No CL number, shelf, or submit was invented. No live p4
commands or Git writes ran. This proves local routing/capture, not live Perforce
integration or publication. Git throwaway-branch capture after acceptance was not
executed; its source stays intact and its authority remains project-controlled.

alignment-checks.json records exact candidate/input equality, changed paths,
HEAD/branch invariance, and the semantic assessment. logic-browser-checks.json,
ui-browser-checks.json, source-comparison.json, checkout-checks.json, discovery
outputs, and package-checks.json retain the separate evidence.

## Independent reviews and remaining gates

Both independent reviews used base f783dd4 and included the full uncommitted
scope, added package/report/issue files, and removed companions. Reviewers only
read and report; neither changed files or published state.

Standards: no actionable BLOCKING, WARNING, or heuristic findings. The removed
companions are byte-identical to the preserved source, and local links/back-link
mapping fit ADR-0009. Capture routing retains methods, Git/P4 scope, and authority.
Saved outputs/browser records support the bounded claims; differences and
untested publication/runtime gates are stated. Verdict: GREEN.

Spec: no actionable findings. All four source files, both methods, invocation,
project routing, and capture authority meet scope. Artifacts support the logic,
UI, and local P4 claims; exact candidate copies and inventories match. The P4
archive is unchanged, and implementation/publication remain pending. Design
equality is not claimed; untested branches and owner verification remain visible.
Verdict: GREEN.

Owner verification is pending. No consumer update, installed skill edit, live
consumer project mutation, push, PR, merge, release, or version bump occurred.
Claude runtime stays deferred. This bounded test set does not replace later
consumer acceptance or an owner's actual prototype evaluation.
