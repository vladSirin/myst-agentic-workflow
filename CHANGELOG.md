# Changelog

All notable changes to `myst-agentic-workflow`.

## Versioning rules

SemVer, scoped to **what an install has to do about it** — not to how big the change felt.

| Bump | When | Examples |
|---|---|---|
| **MAJOR** | An existing install **breaks or needs manual migration**. | Manifest schema change; installer/marker contract change; a path or ownership move `update.ps1` / `upgrade.ps1` cannot resolve on its own. |
| **MINOR** | Anything a consumer gets **automatically** — including removals. | New or retired skills, rules, docs; behaviour changes to an existing skill; content moved between skills. `upgrade.ps1` already adds new files and removes retired ones. |
| **PATCH** | No behavioural change. | Typos, links, wording, formatting. |

Retiring a skill or a rule is **MINOR**, not MAJOR. It is consumer-visible — say so in the entry,
and record what was lost — but the upgrade path handles it without anyone editing a file.

**One bump per merge to `main`.** Not per commit, and not once per PR in a stack: three PRs that
land the same change set share one version. If you are about to write a second `## [x.y.z]`
heading dated today, you almost certainly want to extend the first one instead.

**Tag it or don't bump it.** The version means nothing until `git tag -a vX.Y.Z` exists —
v3.0.0 through v6.0.0 were written into four JSON files and never tagged, which is exactly how
two spurious majors went unnoticed. Either tag on merge, or leave the number alone.

**The number lives in five places** — `package-manifest.json`, `.claude-plugin/marketplace.json`,
`plugins/myst-dev-kit/.claude-plugin/plugin.json`, `plugins/myst-dev-kit/.codex-plugin/plugin.json`,
and the README badge. Update all five in the same commit; the badge is the one that drifts.

## [4.50.0] - 2026-08-25 - Converge duplicate install records, and truth up the install path

MINOR: a new maintenance script consumers get automatically, plus the doc corrections that
make it findable. One documented onboarding archetype is retired -- called out below.
`upgrade.ps1` handles all of it without anyone editing a file.

### The problem

`~/.claude/plugins/installed_plugins.json` can hold BOTH a user-scope and a project-scope record
for one plugin id. Selection takes the first applicable record in stored-array order whose
`installPath` exists -- there is no scope precedence -- so which payload loads is decided by the
order you happened to install things in, and nothing reports the winner. A stale project record
installed first wins every session, silently. Dropping the committed `enabledPlugins` entries
stops NEW records being created; it does not remove the ones already on a machine.

### `scripts/migrate-project-scope-installs.ps1`

Dry-run by default, `-Apply` to act, timestamped backup written before any change. Idempotent.
Missing / empty / unparsable registries are stated no-ops, never crashes.

- **It edits the registry directly rather than calling `claude plugin uninstall --scope project`.**
  Measured 2026-08-25 (CLI v2.1.231): from the repo root, under identical preconditions, that
  command removed one plugin's project record and REFUSED for two others, advising `--scope user`
  -- the flag that deletes the copy you are keeping. The governing rule was never determined.
  When it does succeed it also strips the entry from the project's committed
  `.claude/settings.json` and leaves that file modified but not opened for edit: a shared,
  version-controlled file silently going dirty during someone's setup.
- **It never leaves a plugin with zero records.** If every record for an id is project-scope,
  removing them would uninstall the plugin outright, so it reports and skips instead.
- **It detects `projectPath` with or without `scope: project`** -- the writer stamps one field
  and the selector reads the other, so trusting a single field leaves the other kind behind.

### A PowerShell 5.1 hazard worth knowing about

On 5.1 a one-element filter result unrolls to a scalar, so `ConvertTo-Json` writes
`"id": { .. }` where `"id": [ { .. } ]` is required. That is still valid JSON and a completely
different shape -- it would corrupt the registry of any consumer whose plugin ends up with one
remaining record, which is the normal outcome of converging. Guarded twice, and backstopped by a
round-trip check that refuses to write unless every entry re-parses as a list.

Mutation-tested: removing either guard alone changes nothing (each covers the other), and
removing BOTH fails the suite *and* trips the abort with the original left untouched. The first
two mutation attempts passed, which is how the "load bearing" comment on one wrapper was found
to be wrong and corrected.

### Telling teammates the script exists

A standalone script nobody knows about converges nobody's machine. That cost was accepted
deliberately when the automatic delivery path was dropped -- a converge step inside
`setup-devkit.ps1` would have dirtied a version-controlled file on every teammate's machine
(see above) -- on the condition that the docs close the gap. They now do, on the three surfaces
a teammate actually meets, rather than only `docs/upgrade.md`, which only a maintainer reads:
`SETUP.md`, the `templates/claude/CLAUDE.md` generated block, and
`templates/common/docs/MustRead/MustRead_agentic_workflow.md`.

All three carry the **ordering constraint**, because getting it wrong fails silently: converge
only AFTER the project's `enabledPlugins` removal has synced to your workspace. Converging first
lets the next session recreate the very records you just removed -- observed in the controlled
experiment, not inferred.

### The install path the docs promised no longer exists

Dropping the committed `enabledPlugins` entries also dropped the trust-prompt plugin install,
and four documents still promised it. A doc describing an install path that does not exist is
worse than no doc: the reader follows it, nothing happens, and they have no reason to suspect
the instructions rather than their own machine.

- `SETUP.md` -- **the "Claude-only and allergic to scripts?" archetype is retired**, and now says
  so in those words. It was sold here explicitly ("that zero-touch path still works"), so
  dropping it silently would have been worse than removing it. The section states what was lost,
  why, and the nearest remaining script-free path (`/plugin install myst-dev-kit@myst`, then
  restart).
- `templates/claude/CLAUDE.md`, `templates/common/docs/MustRead/MustRead_agentic_workflow.md`, and
  `overlays/myst-project/docs/MustRead/MustRead_ai_tools_for_creatives.md` -- `setup-devkit.ps1` is
  now the documented path and `/plugin install myst-dev-kit@myst` the manual fallback, each saying
  plainly that nothing installs itself when you trust the repo. The workflow manual previously
  named no install path at all, so a teammate reading the project's own process guide learned none.
- `templates/codex/AGENTS.md` -- the Codex install path is untouched, being a separate plugin
  system that never reads `.claude/settings.json`. Only its now-dangling "(both archetypes)"
  pointer to the retired section is dropped.

**Corrected while here:** "no `marketplace add` needed -- the committed settings pre-register it"
credited the committed file for more than it does. `extraKnownMarketplaces` pre-registers `myst`
and nothing else; `context7` and `claude-md-management` come from the built-in
`claude-plugins-official` marketplace and owe it nothing. `SETUP.md` now says which is which, and
gives `context7` its own install line -- the project's CLAUDE.md mandates that plugin, and since
the `enabledPlugins` removal nothing hands it to a new teammate.

### Verification

`scripts/run-converge-tests.ps1` -- 18 tests, run against **PowerShell 5.1** deliberately, since
5.1 is the version whose array unrolling causes the corruption above.

`scripts/run-linkcheck-tests.ps1` covers the doc changes -- no dangling references introduced.

## [4.49.0] - 2026-08-25 - Say what an EOL flip actually costs, and how to spot one

MINOR: new reviewer guidance in `review-and-submit`, and a corrected overstatement. No script
changes; `normalize-eol.sh` stays exactly as it is.

### What was wrong

The skill said `normalize-eol.sh` "is now the only thing preventing that class" of EOL damage.
It is not: its repair test is `cr>0 && cr<lf`, which by construction cannot see a file already
flipped wholesale to LF.

### What is actually true, measured

`p4 diff` decides WHETHER files differ using an EOL-normalized check, then diffs RAW BYTES.
Measured 2026-08-25 (P4 2025.1, `LineEnd: local` -- a CLIENT spec field, so check your own
`p4 client -o`), same file, same client:

| Case | `p4 diff` |
|---|---|
| a pure CRLF->LF flip, nothing else changed | 1 line, no hunks |
| a real one-line edit, CRLF kept | 5 lines - the actual change |
| that same edit **plus** an LF flip | 111 lines - the whole file |
| `p4 diff -dw` on that last case | 5 lines |

A live instance: a 2-line header edit to a 317-line script diffed as **636 lines**; restoring
CRLF brought it to **8**.

So a flip is invisible right until it matters, and then it buries the change. **Submitted
history is unaffected** -- the depot stores normalized content and `p4 diff2` across stored
revisions shows only the real change -- so this is a pre-submit reviewability problem, which
is precisely where it does damage.

### Changed

- `review-and-submit` SKILL.md: the "EOL flips" bullet drops the overstatement and carries
  the diagnostic in five lines - `p4 diff -dw` when a diff looks absurdly large, then
  `p4 sync -f` to restore the depot form and re-diff. Net +2 lines on the skill. The
  measurements above are deliberately NOT in it: a skill is always-loaded context, so the
  rationale lives here and only the actionable rule ships in the skill.

### Corrigendum

An earlier revision of this branch claimed the opposite -- that P4 normalizes EOL so flips are
harmless and EOL tooling should not be built. That was drawn from testing flips in ISOLATION,
the one case where the problem does not appear, and it was wrong. It never merged. Recorded
here because the reasoning error is the reusable part: measuring a variable alone proved
nothing about the case that occurs in practice, and a clean result read as licence to delete a
working guard.

## [4.48.1] - 2026-08-24 - One install command, no clone step

PATCH: documentation only, no behaviour change. `setup-devkit.ps1` is untouched -- what
changed is that the docs now describe what it has always done.

### The clone step was never necessary, for any tool

README and SETUP.md led with `git clone` + run, as though the clone were a prerequisite.
It is not. `Update-Clone` clones the dedicated path itself when it is missing, so the
script bootstraps from anywhere. **Verified**, not inferred: with `~/.myst-agentic-workflow`
absent and the script alone in a temp directory, `-Tool opencode -DryRun` reported
`Package source: ~/.myst-agentic-workflow` followed by `Cloning <repo> -> ~/...`.

Both docs now lead with one command for every tool -- fetch the script, run it -- with the
clone form kept in a `<details>` block for anyone who would rather read the source first.
Codex and OpenCode get their clone created for them at the right path and checked out to
the latest tag; Claude Code needs nothing on disk at all, since that leg drives `claude`'s
own plugin manager and falls back to `marketplace add` when the marketplace is not
registered.

The clone form keeps its two traps documented, because they are real when you use it:
clone to **exactly** `~/.myst-agentic-workflow` (any other checkout is used AS-IS, so a
clone on `main` installs unreleased commits with no tag involved), and the checkout leaves
a **detached HEAD** at the release tag -- update by re-running the script, never `git pull`.

Also corrected: SETUP.md said Claude needs no `marketplace add` because the committed
settings pre-register it. True inside the team project only -- outside it there are no
committed settings, and the claim would have sent someone in a circle.

### Guides caught up with the v4.48.0 review model

Three docs still described machinery 4.48.0 retired, which is worse than being silent --
a reader would have gone looking for a fast path that no longer exists:

- **SETUP.md** called `review-changes` "the review fast path and the fallback". It is now
  purely the no-subagent path, running the same two axes inline and sequentially.
- **docs/tool-capability-matrix.md** said the fast path invokes it in agent-capable
  sessions "so do not retire it". The conclusion still holds, the reason changed: Codex
  has no Agent tool, so deleting it removes that tool's only review path.
- **README** described `architecture-reviewer` by its four-source canon alone. It is now
  the Standards axis and carries the closed 12-smell baseline and the 400-word cap.

Checked and deliberately unchanged: `MustRead_ai_tools_for_creatives.md` (EN + ZH) names
`/design` and `/review-and-submit` without describing either model, so it did not go stale.

## [4.48.0] - 2026-08-24 - Two axes, a closed smell list, and a stopping rule

MINOR: consumers get it automatically. `review-and-submit` is restructured around the shape of
upstream `mattpocock/skills`' `code-review`, one companion file is deleted, and no skill is
added or retired.

Motivated by measurement, not by taste. `measure-review-rounds.ps1` since 2026-08-01 with the
resumption-aware parser: **median 3 rounds, n=107**, with a tail reaching **19 rounds / 30
invocations** -- and its worst subject is a design document, three of the top five being `.md`.
4.46.0 removed one *input* to that tail (dimension lists restated at every spawn). This
release changes the *structure*, adopting the three properties upstream has and we did not:
a closed finding baseline, a hard output cap, and axis separation with no re-ranking.

### Two axes replace three tiers

`review-and-submit` reviewed along two lenses that were merged into one verdict, routed through
a trivial/fast/full tier table. It now runs **Standards** and **Spec** as parallel sub-agents
that never see each other's reasoning, reported under their own headings and **never merged or
re-ranked** -- upstream's rule, and its reason: a blended verdict lets the passing axis hide the
failing one. A change can follow every convention while implementing the wrong thing, or do
exactly what the ticket asked while breaking every convention.

Standards runs `architecture-reviewer` (design-documents-only CLs run `radical-design-critic`);
Spec runs a general-purpose sub-agent against the linked `Ticket:` / spec / design doc, and is
recorded as `Spec: skipped (no linked source)` rather than silently dropped. The Review Record
now carries one line per axis, and each finding names the axis that raised it. The gate reads
the **worst of the two** -- a threshold, not a ranking.

Gone: the tier table, the trivial and fast paths, and the Step 4 documentation check. The
tiers existed to avoid spending a costly reviewer on a small CL; with a closed baseline and a
400-word cap per axis, the review is cheap enough that routing around it bought nothing.

### The smell baseline lives in the agent, not the prompt

`agents/architecture-reviewer.md` gains upstream's twelve Fowler smells (_Refactoring_ ch.3)
with its two binding rules verbatim -- **the repo overrides**, and **always a judgement call**
("possible Feature Envy", never a hard violation) -- plus "skip anything tooling already
enforces" and the 400-word output budget.

**Deliberate divergence from upstream**: upstream pastes the baseline into the prompt because
its sub-agents are anonymous and have no other access to it. Ours is a named agent whose system
prompt loads at spawn, so pasting it inline would rebuild exactly the duplication 4.46.0 just
removed. Same content, different home, for a reason that only applies here.

The closed list is the point. An open-ended generator ("edge case bombardment") can always
produce one more finding against any finite text; twelve named smells terminate.

### `RE-REVIEW.md` deleted

Upstream `code-review` is a single `SKILL.md`. The companion file was the same split removed
from `design/PROCESS.md` in 4.46.0, and it was read unconditionally, so it deferred nothing.
Rules 1, 3, 5 and 6 collapse into axis separation, the output caps, and the no-re-ranking rule.

**Rule 4 survives as text inside `SKILL.md`**, and deliberately so: it is the exemption letting
a missing `[JobFamily][Name]` tag, an EOL flip, non-ASCII, or a missing `Ticket:` line be fixed
*without* costing a reviewer pass. Deleting it would have made every formatting fix buy a full
round -- a churn increase, the opposite of this release. Its closing principle is kept verbatim:
the list is closed, every item cannot change behaviour, and skipping the pass never skips the gate.

### New, and not from upstream: the stopping rule

**A round that produces no BLOCKING finding is the last round.** Remaining WARNING and INFO
items are recorded with their disposition and the CL ships. Upstream has no explicit analogue --
its caps bound rounds implicitly -- so this is marked as an addition, not as adopted. It is the
one item aimed at the measured tail rather than at its inputs: on prose, a pass spent driving a
WARNING-only report to silence reliably produces a fresh WARNING-only report. It lands in
`review-and-submit` only -- `design` no longer runs reviews at all (below).

### `design` narrows to document authoring only

`design` had grown a review workflow: it launched reviewer agents, parsed their verdicts, ran
an iteration loop, and carried a `> [!CAUTION] Never skip the review step` banner. It now writes
documents and nothing else -- find whether one already exists, name and place it correctly, fill
the standard template, carry it `WIP` -> `APPROVED`. Five steps become three.

Reviewing what a document *proposes* is now nobody's automatic job -- see the alignment check
below. `radical-design-critic` stays directly invokable when someone wants a design critiqued;
nothing fires it on a schedule.

Why it moved rather than being trimmed: `design` was the second home for review rules, which is
how they drifted apart in the first place. Its iteration step restated rules 1, 3, 4 and 6 of the
deleted `RE-REVIEW.md` in its own words, and the restatement had already diverged from the
original. A rule with two homes has no home.

**Consequence, stated plainly:** `/design` no longer routes a finished document to a reviewer.
Nothing in the skill tells you to get one reviewed, and no pointer was added -- ask for a review
explicitly, or let the CL that ships the document carry it. If that turns out to be a gap in
practice, the fix is a pointer, not a workflow.

### `radical-design-critic` becomes a preflight check, not a reviewer

Prose is not a review axis. The Standards axis is `architecture-reviewer` unconditionally,
whatever the CL contains, and the design critic runs **once at submit time** as preflight
item 2 -- on any CL containing `.md`/`.txt` -- answering one closed question: does the prose
here contradict what is true? Behaviour the code in this CL does not have, a stale plan
status, two documents disagreeing, an instruction the diff invalidates.

It is explicitly told **not** to critique the design, the writing, or anything the document
proposes, and it carries no severity and no verdict. It records one `Docs-alignment:` line in
the Review Record and **never starts a review round**.

Why this shape: a reviewer asked to critique prose always finds something -- that is how the
worst subject in the round measurement reached 19 rounds and 30 invocations. A reviewer asked
whether two things contradict either finds a contradiction or does not. The question is
closed, so the loop terminates. It is the same reason the 12-smell baseline is a closed list.

**What is lost, stated plainly:** nothing now critiques a design document automatically.
`design` writes it, the alignment check confirms it does not contradict what shipped, and
quality of the design itself is a human judgement or an explicit request. That is a
deliberate trade: the automatic critique was the single largest round generator measured.

### Not changed, and not a divergence

The submit gate, the `ready-for-human` shelve rule, the Review Record block and the EOL/ASCII
preflight all stand. Upstream omits them because it **has no submit step at all** -- that is
silence, not a verdict. The Review Record has no upstream counterpart because GitHub holds
review output; in Perforce the CL description is the only surface a reviewer can read.

`review-changes` is kept, not deleted, and rewritten to run the same two axes inline. It exists
because **Codex has no Agent tool**; deleting it would have removed the review path for a
supported tool entirely.

### Sizes

| File | Before | After |
|---|---:|---:|
| `skills/review-and-submit/SKILL.md` | 458 | 414 |
| `skills/review-and-submit/RE-REVIEW.md` | 50 | 0 |
| `skills/review-changes/SKILL.md` | 70 | 54 |
| `agents/architecture-reviewer.md` | 64 | 101 |
| `skills/design/SKILL.md` | 265 | 176 |

Net -162 lines. Smaller than the shape suggests, because roughly 200 lines of
`review-and-submit` are the Perforce shell -- CL organization, the Review Record, the preflight
and the submit gate -- which upstream has no equivalent of and which none of this touches.
The structural change is the deliverable; the line count is a side effect.

## [4.47.0] - 2026-08-24 - Retire auto-plan-mode and the BP-Pins requirement

MINOR: consumers get it automatically. One skill retired and one preflight item removed;
`upgrade.ps1` handles both without anyone editing a file.

### Removed

- **`auto-plan-mode` skill deleted.** It existed to carry worked examples for the
  project-owned `AutoPlanMode.md` rule, which the consuming project removed. With no rule
  pointing at it, nothing auto-fires it and the skill is dead weight. Dropped from the
  local-origin roster in `scripts/lib/SkillRoster.ps1`, from both README skill tables, and
  from `pre-implementation-gate`'s Related list.

  **What is lost:** the plan-vs-skip heuristic (2+ coordinated files, work that will be
  reviewed or submitted, hard-to-reverse ops -> plan; single-file edits, read-only work,
  lookups -> skip) is no longer stated anywhere in the package. Agents fall back to harness
  defaults for when to plan. Recoverable from git history at v4.46.0 if it is wanted back.

- **`BP-Pins:` disclosure dropped from the `review-and-submit` preflight** (item 3) and from
  the closed rule-4 list in `RE-REVIEW.md`. The requirement came from the project-owned
  `BlueprintPinVerification.md` rule, also removed. Nothing ever checked for the line - the
  client audit went with CL 2454 and the server audit never carried it - so this removes a
  written expectation, not a gate.

### Changed

- `docs/install.md` cited "AutoPlanMode profiles" as its example of a project-owned file.
  Replaced with "project-invented rule files", which does not name a deleted rule.

- **Stale counts corrected while the skill count moved 31 -> 30.** Two were already wrong
  before this change and were caught by the diff, not by a check: `docs/tool-capability-matrix.md`
  said `skills/` held 24 (it held 31), and the "31 skills" blurb was duplicated across both
  `plugin.json` files, the marketplace entry, README (x4) and SETUP.md (x2). `check-plugin-parity.ps1`
  asserts the matrix Count against the tree, so that one is now green; the prose blurbs have no
  validator and will drift again.

## [4.46.0] - 2026-08-24 - Reviewer prompts stop restating the reviewer, and `design/PROCESS.md` folds home

MINOR: consumers get it automatically. Content moved between files within two skills; no skill
name, trigger, or behaviour contract changes.

Both changes come out of the same observation: the invocation prompts had become a second,
weaker copy of the reviewer agent definitions, and the copy was drifting in the direction that
manufactures findings.

- **Reviewer prompts now carry only what the reviewer cannot already know.** `review-and-submit`
  Step 5 and `design` Step 3 each embedded a bullet list of review dimensions -- *edge cases /
  UX friction / hidden complexity / missing error states / assumptions that may not hold* -- which
  is a flattened paraphrase of `agents/radical-design-critic.md` §Review Methodology and
  `agents/architecture-reviewer.md` §Reference canon + §Review scope and method. Those are the
  system prompt; they load at spawn. The inline copies therefore added nothing true, and
  subtracted two things: §2's guard that UX stress-testing "applies only where the plan has a
  user-facing surface -- a manufactured UX finding is noise", and the "cite, don't name-drop"
  padding guard. Every spawn re-anchored the reviewer on producing findings and handed it none of
  the brakes. Verified before cutting that the canon table and the Runtime-fitness axis subsume
  every deleted bullet (separation of concerns, API clarity, integration points, performance,
  testability), so no instruction is lost. What the prompt keeps: target, file list, observed
  facts, linked spec/ticket, the Spec axis (conditional on a source actually being linked), and
  the literal `Verdict:` contract the parent parses. The two `#### For <agent>` prompt blocks
  collapse to one shared block, and both files now carry a "do not re-add a dimension list" note
  with the reason -- the note is the part that has to survive.

  This is a churn input, not just duplication: prose is the one artifact where fixing a finding
  grows the surface being reviewed, and 4.45.0 already measured that the tail lives in 8-13-round
  subjects. Removing a generator-without-brakes from every spawn is aimed at that tail.

- **`skills/design/PROCESS.md` folded back into `skills/design/SKILL.md`.** The split was residue,
  not design: PROCESS.md is the former `design-workflow` skill, demoted to a sidecar when the two
  merged in v4.28.0 (rename recorded at 58% similarity). A skill split earns its keep through
  progressive disclosure -- SKILL.md stays cheap, the rest loads at the step that needs it, which
  is what `review-and-submit/RE-REVIEW.md` does. This one was read unconditionally (SKILL.md line
  17: "Read it before creating the file"), so it cost two file reads and two places to update and
  deferred nothing. 364 lines across two files -> 264 in one, with the duplicated reviewer-routing
  block, document template, and example workflow deduped rather than concatenated. PROCESS.md's
  §3 iteration rules win over SKILL.md's thinner Step 4, as the process authority always did.

  Consumer-visible: the file is gone. `upgrade.ps1` removes it without anyone editing anything.
  Live references updated in `agentic-workflow`, `auto-plan-mode`, the README skill table, the
  overlay `DocumentStandard.md`, and `migrate-retired-skills.ps1`; historical release notes in the
  README and this file keep saying PROCESS.md, because that is what those releases did.

- **`measure-review-rounds.ps1` counts agent resumptions as rounds** (#91). The parser matched
  only `"subagent_type"`, i.e. Agent spawns. A re-review driven by `SendMessage` to a live
  reviewer carries `to`/`message` and no `subagent_type`, so every resumed round was invisible:
  a hand-verified 9-round review of CL 2601 reported as 2. Resumption is the cheaper way to
  iterate -- it preserves the reviewer's context -- so the expensive tail concentrated exactly
  where the instrument could not see it, inverting the script's own stated error model. It
  claimed "counts are an upper bound"; for a resumed review they were a lower bound. Rounds now
  count spawns AND resumptions, resolving a `SendMessage` to its reviewer by agent name or by the
  agentId recovered from the spawn's own tool_result, and inheriting the subject from the spawn
  rather than re-parsing it -- a resumption is by definition the same review, and its message
  text need not name the CL.

  Merged minutes after the two changes above and shares their version, per "one bump per merge"
  and the rule against a second heading dated the same day. It also means every round count
  quoted in 4.45.0 is a floor, not a ceiling: re-measure before trusting the medians there.

## [4.45.0] - 2026-08-22 - The re-derive rule covers prose, and the preflight stops naming a deleted script

MINOR: consumers get it automatically. Three corrections to `review-and-submit`, two of them to
text that had been describing machinery deleted in CL 2454.

Measured first, because the obvious framing was wrong. `scripts/measure-review-rounds.ps1` over the
consuming project since 2026-08-01 (131 reviewed subjects, 49 multi-round, 840 transcripts):
**median 3 rounds, n=49.** The pre-4.38.0 baseline was also median 3, n=39 -- **4.38.0's four
re-review rules did not move the median.** The CL that prompted this release (a prose-only repair CL,
82 diff lines under a 118-line description) cost exactly 3 rounds: the median, not an outlier. The
cost lives in a tail of 8-13-round subjects that nothing here addresses.

- **The re-derive rule now covers any assertion about the CL's own content**, not only numeric ones.
  It already required byte counts, file counts and finding tallies to be re-derived at submit time
  or left out; it now says the same of "verified by diff", "zero non-comment lines changed", and
  quoted snippets of what one of the CL's files now says. Origin: the CL that motivated this release
  violated the *existing* rule (`[FIXED] WARNING x6 rotted 710-line count`) and separately shipped
  four blocking findings of the form "the description described its own pre-fix text". The review's
  own fixes are what rot these, which is why they rot hardest in the CLs that take the most rounds.
  A widened clause on the rule that exists, not a fifth rule beside it.

- **Fixed: the preflight told you to run a script that no longer exists.**
  `submit-audit-warn.sh --check-cl` went in CL 2454 (`p4 files` shows `#14 - delete`). Its absence
  is indistinguishable from a clean run -- precisely the failure the warning directly below it
  described. That item now states what is true: EOL flips are repaired by the `normalize-eol.sh`
  PostToolUse hook the moment a partial rewrite creates them, everything else runs server-side
  post-commit, and a quiet submit is not evidence the audit passed.

- **Fixed: a false claim that something warns when a BP-facing CL omits its `BP-Pins:` line.**
  Nothing does. The client audit that warned went with CL 2454, and the server trigger never carried
  the check -- verified against its six. The consuming project's own always-on rule had already
  recorded this; the skill had not. It now says the line stands on you and on review.

- **Not in this release, and that is a finding.** A fourth prose rule ("cite, don't restate") was
  drafted and cut: it would have collided with the reviewers' existing **"Cite, don't name-drop"**,
  and its remedy -- point at the linked ticket -- is inert on `Workflow: skipped` CLs, which is the
  exact class of fallout-repair CL it was aimed at. A rule that the file already carries, and that
  was violated anyway, is not improved by adding a fifth beside it.

**Consumers:** no action. The removed preflight item was already un-runnable, so nothing that worked
stops working.
## [4.44.0] - 2026-08-22 - Reviewer agents: pin effort at max

MINOR: behaviour change consumers get automatically.

`radical-design-critic` and `architecture-reviewer` now carry `effort: max` in
frontmatter instead of inheriting the session's effort. Rationale: sessions are
moving to cheaper effort defaults for token cost, and reviewer inheritance meant
a cost setting silently downgraded the verification gate — the D0–D5 ground-truth
harness measured a weakened critic falling from 6/6 defects found to 0/2 on one
class. Review runs are ~0.01% of weekly tokens, so the pin costs nothing
measurable while making review quality independent of session economics.

## [4.43.1] - 2026-08-22 - README: say which skills you type and which the agent reaches for

PATCH: documentation only, no behavioural change.

Upstream's README splits its catalog on one axis this one never showed: **who invokes a skill.**
That distinction matters more here since v4.43.0, which adopted three model-invocable skills --
`writing-for-agents` fires on edits to `CLAUDE.md` or `AGENTS.md`, work nobody explicitly asks
for. A reader deciding whether to install had no way to see that.

- **The catalog is now organised by who invokes a skill**, not by category-with-a-column. The 13
  you type come FIRST, grouped by what you reach for them for (plan the work, do the work,
  pressure-test your thinking, hand off and explain, set up the kit); the 18 the agent reaches for
  follow. Section membership is derived from each skill's `disable-model-invocation` frontmatter.
  Also states the rule that a user-invoked skill may call model-invoked ones but never another
  user-invoked one.
- **A TL;DR and a Contents block** at the top: what this is, how to install, and direct links into
  the two skill sections, so a first-time reader is not hunting through six problem statements to
  find out what they can type.
- Documents the per-tool caveat: Claude and Codex honour the frontmatter key, **OpenCode ignores
  it**, so `setup-devkit.ps1` restores the same gate as a `permission.skill` ask-map -- and its
  `$ManualSkills` list is exactly the user-invoked set.
- **Fixed a catalog gap the work surfaced**: the README claimed "31 skills total" and listed
  **26**. The five team-process skills (`agentic-workflow`, `pre-implementation-gate`,
  `changelist-verification`, `review-and-submit`, `auto-plan-mode`) were described in prose and
  never catalogued. They now have their own table.
- **`scripts/run-catalog-tests.ps1`** (new, CI-discovered) asserts all three facts against the
  tree: every skill catalogued both ways, every skill in the section its frontmatter dictates, and
  the user-invoked set equal to `$ManualSkills`. Suite badge 20 -> 21. The catalog was drifting
  silently because nothing checked it -- the same reason the suite-count badge exists.
- Section headings deliberately carry **no counts**: a count in a heading is part of the anchor, so
  every link to it breaks the day a skill is added. The numbers live in the prose beneath.

## [4.43.0] - 2026-08-21 - Re-vendor mattpocock/skills e9fcdf9 -> 0ab1b63, +8 skills, verbatim-by-default

MINOR: consumers get it automatically. The largest re-vendor to date (141 upstream commits) plus
the process change that keeps the next one cheap.

**Why it was 141 commits.** Nothing ran `check-mattpocock-updates.ps1` between syncs. The detector
existed and worked; it just was not on any checklist. It is now, at every release and monthly.

- **Re-vendored all upstream-derived skills at `0ab1b63`.** Notable gains we had been missing:
  `diagnosing-bugs` "Redact secrets" phase, `grilling` round/frontier question-batching with
  sub-agent fact-finding, harness-neutral subagent-dispatch phrasing across several skills.
- **+8 skills** from upstream's user-facing roster: `wayfinder` (map an effort too big for one
  session as decision tickets), `prototype`, `wizard`, `to-questionnaire`, `grill-me`, `teach`,
  `wait-what`, and `writing-for-agents` (which **replaces `writing-great-skills`** - upstream
  renamed that skill and we had never followed).
- **The kit is now stack-agnostic where it is upstream-derived.** `UE-NOTES.md`, `P4-NOTES.md`
  and the P4 hot-spot aside are gone from vendored skills; that content is preserved in git history and
  relocates to the consumer project's own `Docs/agents/` in the paired project changelist
  (not in this release -- see the divergence ledger, section 6). 0 stack-specific hits remain in upstream-derived skills.
  Local-origin skills (`review-and-submit`, `pre-implementation-gate`, ...) are still P4-shaped -
  that is a separate workstream, not a claim this release makes.
- **Triage vocabulary converged with upstream, with the two jobs separated.** Upstream's five
  triage ROLES are adopted verbatim - including `ready-for-human` now meaning *a human implements
  this*, not the old "agent implements, human gates the submit". Our lifecycle STATES stay
  (`claimed` - renamed from `work-in-progress` - plus `resolved` and `closed`), because upstream's
  `triage-labels.md` is explicitly a per-repo mapping table and upstream's own file-tracker spec
  uses `resolved`. One `Status:` field, two jobs, now said out loud.
  - **A `ready-for-human` ticket's `Status:` is user-owned — only the user changes it, to ANY
    value.** An agent that thinks a ticket is mislabeled reports and stops. Not just the obvious
    relabel to `ready-for-agent`: every gate matches the *current* string and nothing records the
    previous one, so setting `claimed` silences them all just as effectively and leaves no trace.
    Without this the label is self-granting — an agent that can award itself a workable state can
    submit under a goal-mode authorization in the same run.
  - Consumers: the converged `triage-labels.md` / `issue-tracker.md` / `MustRead_agentic_workflow.md`
    arrive by scaffold render. **Re-triage your open tickets** - the same string now means
    something different.
- **`issue-tracker.md` gains upstream's "Wayfinding operations" section**, which `/wayfinder`
  requires by name. Without it the adopted skill is stranded. Efforts are told apart by structure:
  a wayfinder effort has `map.md`, an implementation effort has `spec.md`.
- **[ADR-0006](docs/adr-0006-verbatim-by-default-and-the-divergence-ledger.md) - verbatim by
  default.** Every divergence from upstream now needs a written necessity rationale, a reviewer
  pass, and owner confirmation. The whole release ships **7 divergent lines across 6 skills**, all
  the same kind: a reference to a skill we do not vendor, remapped to ours.
- **`vendored-hashes.json` + `scripts/vendored-hashes.ps1`** make "verbatim" a test instead of a
  promise. `-Verify` fails on drift; `-Update` **refuses** to record a file that differs from the
  pinned upstream unless it is a declared divergence - so a divergence cannot be silently
  regenerated away. Hashing reuses the EOL/BOM-invariant `Get-NormalizedContentHash`; a naive
  scheme re-introduces the autocrlf false-positive this repo already fixed twice.
- **Dangling-ref grep in the release checklist.** Three review passes over the migration plan each
  mis-enumerated the divergence set by hand; one `git grep` got it right first time. Enumerate by
  grep, never by hand.
- **Fixed: `migrate-retired-skills.ps1` would have deleted two shipped skills.** `teach` and
  `grill-me` were retired in v4.28.0 and are re-adopted here, but remained on the retired list -
  the next migration would have removed them from every install.
- Bookkeeping: attribution pin in both `LICENSE` files was **two re-vendors stale**; provenance
  tests' `$localOrigin` guarded 2 of 9 local-origin skills; skill counts recomputed to 31;
  `run-provenance-tests.ps1` header corrected to say plainly that it does not cover vendored skill
  content.

## [4.42.0] - 2026-08-21 - setup-devkit: Codex install-if-missing actually installs

MINOR: consumers get it automatically. One defect in the day-old script, found by running the
release end-to-end on a machine where the Codex plugin was genuinely not installed.

- **`setup-devkit.ps1` Codex leg**: the install-if-missing check grepped the plugin NAME out
  of `codex plugin list` - but the name appears in the table even when its row says
  `not installed` (and the command can exit non-zero while printing a valid table), so the
  leg concluded "installed" and silently skipped `codex plugin add`. Now it always attempts
  the add (harmless when already installed) and judges the row TEXT afterwards - the leg
  FAILs loudly only if the row still says `not installed`. Verified live: the same machine
  went `not installed` -> `installed, enabled 4.41.0` on the fixed leg.
- Docs consistency pass (README vs SETUP): the per-tool notes block is no longer stranded
  inside Provenance; README now carries the same writable-twin story SETUP documents
  (OpenCode's Claude-plugin compat path surfaces `myst-dev-kit:<name>` writable - the script
  disables them; spawn `myst/<name>`); SETUP's Codex row matches the always-attempt-add
  implementation; the FAQ covers three tools and states OpenCode is deliberately not a
  scaffold render target.
- Second heading dated today, deliberately: 4.41.0 below is a separate change set already
  merged to `main` (PR #85) and tagged.

## [4.41.0] - 2026-08-21 - OpenCode joins as a pointer consumer; one setup command for every tool

MINOR: consumers get it automatically; nothing existing breaks. OpenCode support returns in
the opposite shape to the v3.0.0-retired render-target model - a pointer, not copies
(ADR-0005 records why, and what is deliberately NOT revived: no `templates/opencode/`, no
`tool: opencode` manifest axis, no parity suites, no junctions, no runtime adapter).

- **`setup-devkit.ps1`** (new, repo root): ONE command that installs AND updates the kit for
  every AI CLI on the machine - drives Claude/Codex native plugin managers, and for OpenCode
  maintains a dedicated clone at `~/.myst-agentic-workflow` (latest release tag,
  version-aware sort), registers the 24 skills via `skills.paths` in the user's global
  `opencode.json`, writes the unreal-engine MCP entry and a `permission.skill` ask-map
  restoring `disable-model-invocation` semantics OpenCode ignores, then SELF-VERIFIES
  delivery. Per-leg isolation (one broken CLI never aborts the others), `-Version` pin/
  rollback, `-Uninstall`, JSONC configs never rewritten (strict-parse guard - pwsh 7's
  ConvertFrom-Json silently accepts comments), deep foreign config preserved (explicit
  -Depth; PS 5.1's default silently flattens). Suite: `run-devkit-setup-tests.ps1` (22
  cases; 19 suites total).
- **Reviewer agents reach Codex and OpenCode - generated, never forked.** The script writes
  read-only variants from the unchanged shared source: Codex `~/.codex/agents/*.toml`
  (official subagent schema, `sandbox_mode = "read-only"`), OpenCode
  `~/.config/opencode/agents/myst/*.md` (`mode: subagent`, `permission: edit deny`). The
  shared Claude files are never loaded directly by other tools - their frontmatter
  (`color: green|purple`, `tools:` string) breaks OpenCode's parser machine-wide.
  Measured during verification: OpenCode 1.18.19 ALSO consumes installed Claude plugins,
  surfacing the plugin's reviewer copies as `myst-dev-kit:<name>` subagents that resolve
  with `edit: true` - a writable reviewer on every dual-tool machine, predating this
  release. The script now ships those twins DISABLED in the user's config; spawn the
  generated `myst/<name>` variants. `review-changes` remains the inline fast path
  everywhere.
- **Renamed: `/update-myst-skills` -> `/update-project-scaffold`** (maintainer command; the
  old name read as a per-user "update my skills" action, colliding with the real per-user
  update story above; the command re-renders the COMMITTED project scaffold into a P4 CL).
  MINOR per the install-break test: maintainer-only, zero committed consumer references
  (swept). Update any personal notes that name it. `promote-myst-skills` keeps its name.
- **Releases**: `.github/workflows/release.yml` turns every `v*` tag push into a GitHub
  Release with that version's CHANGELOG section as the body; README/SETUP point at the
  Releases page as the "what is latest" surface.
- Docs: README head restructured (30-second setup, per-tool details, staying current);
  SETUP.md restructured around the one-command story + OpenCode known-gaps table;
  tool-capability-matrix gains the OpenCode column and the 2026-08-21 Codex subagent-socket
  probe evidence; CONTRIBUTING documents tag->release and the rename semver ruling.

## [4.40.0] - 2026-08-20 - Submit review scales to the changelist; the phrase was never the gate

> Second heading dated today, deliberately: 4.39.0 below is a separate change set already
> merged to `main` (PR #83), so sharing its number would break one-bump-per-merge. Note
> v4.39.0 is still untagged — it needs its tag independently of this entry.

MINOR: consumers get it automatically. Two changes to `review-and-submit`, one template touch.

- **Trigger**: any explicit submit instruction naming a CL ("submit 2470") runs the protocol.
  The long "review and submit" phrase stays sufficient but is documented as never required —
  Step 7 already treated both as the same approval; the trigger section now says so instead of
  implying the incantation is load-bearing.
- **Trivial path (tier 0)**: docs/ledger-only CLs — every file `.md`/`.txt` under the doc
  trees, nothing under `_Raw/` or `.claude/`/`.codex/`, ≤ 10 files — skip reviewer routing,
  the doc check, and the inline rubric. What remains: description/tag check, `p4 opened`
  verify, EOL normalize, a one-line self review record, preflight, and the unchanged human
  gate. Evidence basis (one consumer, CLs 2386-2469): every docs-only rubric pass returned
  GREEN with zero findings, while code CLs in the same window drew real BLOCKING/WARNING
  verdicts — the rubric was ceremony exactly and only in this class. Drift had already begun
  (two docs-only CLs shipped with no record at all); tier 0 legalizes the skip and keeps the
  record line, so a principled skip stays distinguishable from a forgotten review.
- **`templates/common/docs/MustRead/MustRead_agentic_workflow.md` §7**: documents both trigger
  forms and the scaled review, ending on the invariant: the review scales, the human gate
  does not.

## [4.39.0] - 2026-08-20 - The ticket travels with the CL

MINOR: consumers get it automatically. One new section in `pre-implementation-gate`, closing a
one-directional gap in the existing rule.

The gate already requires a `Ticket:` line in every CL description. That points the CL **at** the
ticket. Nothing pointed the ticket back at the CL — so ticket state was free to drift from what
had actually shipped, and nothing noticed until someone tried to close a board.

Driven by an audit of one consumer's board where seven `resolved` tickets needed a dedicated
reconstruction pass. Three distinct failures, none of them carelessness:

- **Evidence written into the wrong ticket.** Work on ticket 06 discharged a criterion of ticket
  03; the evidence was recorded in 06, where the author was standing. 03 still read as open, and
  its own file was never touched. Rule 1's "including a ticket you touch *incidentally*" exists
  for exactly this — a rule that only says "your ticket goes in your CL" does not catch it.
- **A criterion deferred into the void.** "Rides ticket 06" and "remains for the debug pass"
  moved a criterion out of its ticket without naming a receiver. It went ownerless for weeks and
  was eventually discharged by accident, by an unrelated CL that happened to produce the evidence.
- **`resolved` with no stated remainder.** The label means "a human check remains" but nothing
  required saying WHICH. Reconstructing that for seven tickets is the audit that motivated this.

**The exception is load-bearing, not a hedge.** A check that can only run after the code ships
cannot be recorded in the CL that ships it. Making "same CL" absolute would force either a
premature `resolved` or holding code CLs hostage to a human — so the rule states the exception
and hands that half to `resolved` + the `Outstanding:` line instead. A rule with an unstatable
exception gets broken once and then ignored.

Not a new enforcement mechanism: this rides the review protocol, like the `Ticket:` line it
extends.

## [4.38.0] - 2026-08-18 - Review rounds converge by removing causes, not by capping rounds

MINOR: consumers get it automatically. Four new re-review rules, the fast path wired to a skill
that already shipped, and a sibling `RE-REVIEW.md`. Plugin skills reach consumers through the
marketplace clone (`/plugin update myst-dev-kit@myst`), NOT through `upgrade.ps1` — that installer
ships only manifest-declared consumer files and nothing under `plugins/`.

Two transcript sweeps over this repo's own review history drove every line of this.

**Sweep 1 — briefing.** ~48 re-review invocations across 4 sessions and 5 CLs: **100% delta-brief,
0 full-template.** Re-reviews were already narrow. A rule mandating that was drafted and dropped —
always-loaded text buying a behaviour already at 100% is sediment.

**Sweep 2 — what late rounds found.** Fix-churn dominates: from pass 2 on, most findings are
defects in the previous round's own fix, frequently in the prose written to explain the fix. Only
1 of 3 long loops ended on GREEN; the others ended on a human override and on the agent giving up.

**Four rules, each removing a measured cause of rounds** (in the new `RE-REVIEW.md`):

- **Rule 3 — the fix answers the finding and nothing else.** Implement the finding, not the
  reviewer's prescription (declare it in the brief if you adopt theirs); explanation goes in the
  brief, not the artifact. Origin: a CL whose round 3 opened with three BLOCKING defects, all
  introduced by round-2 fixes implementing prescriptions the reviewers later called wrong.
- **Rule 4 — a closed list of findings that never cost a re-review**, at any severity: Review
  Record, `[JobFamily][Name]` tag, EOL flip, non-ASCII description, an existing `Ticket:`, an
  already-performed `BP-Pins:`. Closed on a principle — every item cannot change behaviour, and
  every item has a validator behind it. `BP-Pins:` and `Ticket:` carry qualifiers precisely because
  *doing* the verification or *creating* the ticket is the work, not the line.
- **Rule 5 — one re-review per pass, not per finding.**
- **Rule 6 — scope freezes when the review starts**, except what the fix itself requires.

**No round cap, and that is a finding, not an omission.** Four cap designs were tried and measured:
counting rounds fired on 5 of 5 CLs; counting BLOCKING volume fired on ~2 of 3, including the round
that *caught* nine regressions; attributing findings to the last fix fired on ~3 of 3, because
every brief is a delta brief — so "is this defect inside the last fix" is yes by construction and
the detector measured the briefing convention, not fix quality. You cannot reliably detect a
churning loop from inside it. Nothing in this release stops, asks, or shelves.

**The fast path now invokes `myst-dev-kit:review-changes`.** It told the agent to "do a careful
self-review of the diff" — no rubric, no verdict line — while `review-changes` has defined exactly
that review since 4.1.0. It is documented in the README, CONTRIBUTING and the capability matrix,
and **no skill invoked it**: `myst-dev-kit:review-changes` was 0 hits kit-wide.

**`review-changes` gains its second branch and loses a contradiction.** Its opener read "when you
cannot spawn a subagent", i.e. "not you", which would have defeated the fast path. And it loaded
both reviewer rubrics whole — including a second-person "you MUST NOT run `p4 submit`" written for
a subagent reporting to a parent, landing in the session that must submit. It now reads each rubric
*except* its Submission Authority section and persona: an exclusion, so a renamed heading costs an
extra section rather than silently half a rubric.

**Structural.** The re-review rules moved out of `review-and-submit` Step 7 — already the file's
densest region — into a sibling `RE-REVIEW.md` behind a markdown link. Rules 1-2 moved
byte-identical except the header's hardcoded rule count. Rules 3 and 6 fire earlier than the
launch-a-reviewer moment, so each is triggered from where it applies.

## [4.37.0] - 2026-08-18 - The reviewer agents get pruned of what 4.36.0 made redundant

MINOR: consumers get it automatically; four instructions change what the agents do, the rest
is weight coming off.

4.36.0 added the canon and the reasoning toolkit to the two reviewer agents. It did not remove
what those additions duplicated. Read through `writing-great-skills`, both files were carrying
the standard post-feature residue — the same meaning stated twice, a pile of no-ops, and two
descriptions restating a single branch five and ten times.

**Four fixes that change behaviour:**

- `architecture-reviewer` was told to "ask for clarification when the code's intent is
  ambiguous." A subagent has no user turn — it could only guess anyway or drop the finding.
  Now the ambiguity **is** the finding: name both readings and what each implies.
- `radical-design-critic` had no jurisdiction gate — it MUST-ed through six dimensions
  including a six-bullet UX stress test, on plans with no user in them. Build scripts, CI
  pipelines and infrastructure changes were getting manufactured UX findings. The dimensions
  are now jurisdictions, with §2 gated on a user-facing surface.
- The Verdict contract had drifted: 4.36.0 recorded it as "left byte-alike (parents parse
  them)", but only the Submission Authority paragraphs were. The critic's hardened
  "must be the LAST line … do not bury it mid-response" is now in both, verbatim, so `diff`
  catches the next drift.
- `architecture-reviewer` pointed at the `codebase-design` skill by bare name; plugin skills
  resolve as `plugin:skill`. Now `myst-dev-kit:codebase-design`.

**Weight removed:**

- Both descriptions are always-resident and each described one branch. The reviewer restated
  it five ways and then re-listed the canon the body already carries (81 -> 30 words); the
  critic used ten nouns across two parallel lists (80 -> 42 words).
- `architecture-reviewer`: the canon table and three of the four review axes rendered the
  same content twice — the McConnell row and the Construction-quality axis were near-verbatim,
  and so on for Boswell, Nystrom, Gregory. The table gates jurisdiction, so it stays; the
  three duplicate axes go; `Runtime fitness (project-derived)` has no canon row and stays.
  The trailing "Working principles" paragraph restated six things already said elsewhere.
- `radical-design-critic`: Core Philosophy and Review Methodology §§2-5 were the same material
  as beliefs and as actions, in a file that then spends a paragraph forbidding the framework
  names in findings (11 bullets -> 3). The output section ran two parallel severity
  vocabularies and a paragraph mapping one onto the other; the severity word now leads each
  heading and the mapping is gone. Behavioural rules 1 and 9 instructed opposite things about
  praising a good plan — merged, and stated positively.

Net: bodies 1393 -> 1218 and 1738 -> 1619 words; descriptions 161 -> 72 words off the
always-resident budget.

**Not a quality claim.** The 4.36.0 benchmark ($99, 30 runs, blind-graded) was a null result —
recall at ceiling in both arms, Verdict lines identical across every case. No benchmark was
run for this pass and none is warranted: pruning makes no claim a benchmark could measure.
Verified by `claude plugin validate`, the linkcheck suite, and a byte-diff of the shared
contract block.

Also clears two pieces of release-hygiene debt found on the way:

- 4.34.0, 4.35.0 and 4.36.0 were bumped and never tagged, against this file's own "tag it or
  don't bump it" rule. Tagged retroactively.
- **4.35.0's entry had been deleted from this file.** It was written in `7904a36` and removed
  by `311189d` ("bump to 4.36.0"), which was authored on a branch that predated 7904a36's
  merge and overwrote the section when it landed. Restored verbatim from `7904a36`. The
  release itself shipped intact — only its record was lost — but a changelog that silently
  drops a version is worse than one that never had it, because nothing looks wrong.

## [4.36.0] - 2026-08-17 - The architecture reviewer stops assuming it works on Myst

MINOR: consumers get it automatically; it changes what the reviewer agent believes about
the project it is dropped into.

`architecture-reviewer` carried Myst's own context in its prompt — FrogEvent, AngelScript,
UE5 subsystem patterns, asset prefixes — in a kit whose stated design goal is engine- and
project-agnosticism. Any consumer outside Myst got a reviewer primed to hunt patterns their
repo does not contain.

The rewrite replaces baked-in context with discovery and a named canon:

- **"Know the project before you judge it"** — a cheapest-path discovery order (root agent
  docs, then the change's neighbours, then build manifests), with deeper docs read only when
  a specific finding depends on them, and a tiebreaker: project convention wins on style,
  loses on correctness.
- **Four-source canon with jurisdictions** — Code Complete (construction), The Art of
  Readable Code (readability), Game Programming Patterns and Game Engine Architecture
  (applied only when the project is game/engine-shaped). A cite-don't-name-drop guard keeps
  the books as justification for standards, never as findings.
- **"Runtime fitness (project-derived)"** replaces the UE5-specific axis: the same five
  concern classes (ownership/lifetime, hot paths, framework-boundary exposure, concurrency,
  resource loading), with specifics derived from the stack under review — on a UE project
  the old UPROPERTY/Tick/Blueprint items fall out of it unchanged.

Launch briefings in `review-and-submit` and `design`, the `review-changes` rubric summary,
the README agent row, and the overlay README follow suit (the overlay README also stops
listing two files the overlay never contained).

Benchmarked before landing — 30 blind runs (5 cases x 2 arms x 3 reps, opus pinned,
identical prompts/tools), graded against pre-written ground truth with a blind pairwise
judge: recall 29/30 both arms, zero false BLOCKING on the clean control both arms,
cost/time within noise (+2.8% tokens), blind preference 54% (null). The ship rationale is
**genericity at zero measured quality cost**, not a quality improvement — the data does not
support the stronger claim. Notable from the judging: the old arm's per-finding "Code
Complete principle violated" lines were repeatedly flagged as deletable padding; the guard
removes the habit.

MINOR: consumers get it automatically, and it changes what goes into a reviewer prompt.

Reviewers have less tool reach than the session launching them. They read files, but they
cannot necessarily open a binary or serialized asset, query a live editor or service, or run
the project's tooling. Nothing in Step 5 told the caller to close that gap, so reviewers
derived what they could not observe.

Measured on the consumer CL that produced 4.34.0: one reviewer decoded property tags at byte
offsets inside a serialized asset to recover values the launching session could read in a
single call. A later pass tried the same and failed outright - the package format defeated a
byte parse. And the one materially wrong conclusion in four review passes came from a
reviewer reasoning about geometry it had no way to observe; it was refuted only when the
launching session read the actual values and handed them over. Once facts were supplied in
the prompt, both reviewers independently re-verified them instead of guessing.

#### Changed

- **Step 5 now requires the launching session to supply observed facts** when the CL touches
  anything the reviewer cannot open: the property values read, compile/validation status,
  node or schema shapes, the before/after of a binary diffed. Values, not conclusions drawn
  from them - and labelled observed vs inferred, using the same evidence ranking the reviewer
  is asked to apply.
- **Both reviewer prompt templates gained an `Observed facts` slot**, so the requirement is a
  field to fill rather than advice to remember. "none - nothing in this CL required
  observation" is a valid answer and an explicit one.
#### Removed

- Two lines of justification prose from 4.34.0's re-review section. The rationale belongs in
  this changelog and the PR, where it already is; the skill needs the instruction.

#### Rejected, recorded here rather than in the skill

- **Widening reviewer tool access** was the first instinct and it is wrong: several agents
  concurrently querying a live service is flaky, measurement belongs in one place, and
  judgment agents should not hold tools that can mutate state. An earlier draft also named a
  specific MCP server inside the reviewer agent bodies, which would have failed the
  CONTRIBUTING genericity bar - the core ships to consumers with different engines and no MCP
  at all. Project-specific guidance belongs in the consumer's own rules.
- This paragraph lived in the skill for one commit before being cut. A maintainer weighing
  reviewer tool access reads the changelog, not the middle of Step 5.

## [4.35.0] - 2026-08-08 - Reviewers stop guessing at what they cannot open

MINOR: consumers get it automatically, and it changes what goes into a reviewer prompt.

Reviewers have less tool reach than the session launching them. They read files, but they
cannot necessarily open a binary or serialized asset, query a live editor or service, or run
the project's tooling. Nothing in Step 5 told the caller to close that gap, so reviewers
derived what they could not observe.

Measured on the consumer CL that produced 4.34.0: one reviewer decoded property tags at byte
offsets inside a serialized asset to recover values the launching session could read in a
single call. A later pass tried the same and failed outright - the package format defeated a
byte parse. And the one materially wrong conclusion in four review passes came from a
reviewer reasoning about geometry it had no way to observe; it was refuted only when the
launching session read the actual values and handed them over. Once facts were supplied in
the prompt, both reviewers independently re-verified them instead of guessing.

#### Changed

- **Step 5 now requires the launching session to supply observed facts** when the CL touches
  anything the reviewer cannot open: the property values read, compile/validation status,
  node or schema shapes, the before/after of a binary diffed. Values, not conclusions drawn
  from them - and labelled observed vs inferred, using the same evidence ranking the reviewer
  is asked to apply.
- **Both reviewer prompt templates gained an `Observed facts` slot**, so the requirement is a
  field to fill rather than advice to remember. "none - nothing in this CL required
  observation" is a valid answer and an explicit one.
#### Removed

- Two lines of justification prose from 4.34.0's re-review section. The rationale belongs in
  this changelog and the PR, where it already is; the skill needs the instruction.

#### Rejected, recorded here rather than in the skill

- **Widening reviewer tool access** was the first instinct and it is wrong: several agents
  concurrently querying a live service is flaky, measurement belongs in one place, and
  judgment agents should not hold tools that can mutate state. An earlier draft also named a
  specific MCP server inside the reviewer agent bodies, which would have failed the
  CONTRIBUTING genericity bar - the core ships to consumers with different engines and no MCP
  at all. Project-specific guidance belongs in the consumer's own rules.
- This paragraph lived in the skill for one commit before being cut. A maintainer weighing
  reviewer tool access reads the changelog, not the middle of Step 5.


## [4.34.0] - 2026-08-08 - The review gate stops multiplying its own passes

MINOR: consumers get it automatically, and it changes when `review-and-submit` re-reviews.

`review-and-submit` required a full reviewer pass after **any** fix, warning or blocker, and
said nothing about *which* reviewers to re-run. A consumer CL took **four** passes under that
rule. Passes 3 and 4 were both reached by fixing warnings, and both found only more prose -
each one costing a full two-reviewer cycle to correct tooltip wording. The gate that actually
protects anything is the human decision at Step 7, and burying it under passes that only find
text weakens it rather than strengthening it.

#### Changed

- **Only a BLOCKING fix forces a re-review.** The hard rule is now "No direct submit after
  fixing a BLOCKER" - a BLOCKING verdict is the reviewer's judgement that the CL is unsafe to
  ship, and only its own re-verdict clears that. WARNING-only fixes are applied, recorded in
  the Review Record as `[FIXED]` / `[ACCEPTED]` / `[DEFERRED]`, and go straight to Step 7.
- **Re-review is scoped to the reviewers whose blockers you fixed**, not the whole panel, and
  each is told what changed and what was declined. Re-running a reviewer whose findings you
  did not act on invites fresh findings on unchanged code, which is the mechanism that turns
  a two-pass review into a four-pass one.
- This aligns `review-and-submit` with `skills/design/SKILL.md`, which already said "re-run
  the reviewer(s) after fixing BLOCKING findings". The two skills disagreed; now they do not.

#### Notes

The safety property is preserved by one exception, and it is deliberately judged on the edit
rather than the label: if a WARNING fix turns out to touch behaviour, change a signature, or
widen scope, it counts as a blocker fix and re-reviews. The failure this guards against is a
"tidy the wording" fix that quietly alters what ships.

## [4.33.0] - 2026-08-07 - Every loud path now names a way out

MINOR: consumers get it automatically, and it changes what the check will do for you.

Third review pass of the same consumer CL. The remaining findings were all in text and
control flow added by 4.31.0/4.32.0 - the fixes had closed the holes but left the operator
without a route through them.

#### Fixed

- **The CORRUPT branch was a recovery dead end.** Its own message said "re-record it from
  reviewed files instead" - and the guard sat above the `--write-baseline` handler, so it
  refused to do exactly that. Following the instruction literally hit the same error, and
  the only remaining exit was deleting the file: the one untracked, irreversible action
  this design works to make expensive, reached at the end of a dead end, during an
  incident. `--write-baseline` now passes through the CORRUPT guard.
  It is still refused on the DISAPPEARED paths, and the distinction is the point: there a
  real record exists and re-recording would overwrite evidence; a corrupt baseline has no
  evidence left to protect.

#### Changed

- **Every loud path now prints a command.** `DISAPPEARED` was the only one that printed
  none - it said "restore them" with no `p4 revert`, no way to see what should have been
  there, and no pointer to the doc that explains the escape hatch. Meanwhile deleting the
  baseline was one command the operator already knew, so the effort gradient pointed at
  the silencer. It now leads with the recovery commands and names
  `Docs/agents/agent-context-parity.md`.
- **Creatives update block leads with the ask-the-agent path.** It claimed "you do not
  need to install anything extra" and then called `claude` from a terminal - an unverified
  assertion that the VS Code extension puts the CLI on PATH. SETUP.md's own recommended
  phrasing has no such dependency and works in an IDE session, so it goes first; the two
  CLI commands remain as the fallback.

#### Added

- `run-hook-tests.ps1`: a case proving `--write-baseline` RECOVERS a corrupt baseline
  rather than merely reporting it. Suite total 18.

## [4.32.0] - 2026-08-07 - The last two silent paths

MINOR: consumers get it automatically, and it changes what the check reports.

4.31.0 closed two of the three ways the check could go quiet at the worst moment. The
second review pass of the same consumer CL found the third, and a fourth reached through
a different door. Both reviewers converged on the first one independently, again.

#### Fixed

- **A deleted bible file was still silent.** 4.31.0 hoisted the baseline read above the
  two "nothing to compare" branches, but the file-EXISTENCE loop sat above that. So
  deleting `AGENTS.md` outright - the widest form of the incident class, where Codex
  reads nothing at all rather than reading Claude's rules - still printed
  `no AGENTS.md - nothing to check`, exit 0, with a baseline on disk recording that it
  had rules. The baseline read now precedes every early return, and the legitimate
  silence this branch exists for (a project that never set the second tool up) is
  exactly the no-baseline case, so the two are distinguishable.
- **A corrupt baseline silently reverted to no-baseline mode.** An empty or
  comments-only baseline - what a three-way merge of a unified diff produces - yielded
  an empty signature, which every branch treated as "never recorded". Combined with a
  collapse, that put the incident-class silence straight back. Absence and corruption
  are different states; a present-but-signature-less baseline is now reported as
  `CORRUPT or hand-merged` and exits 1.

#### Changed

- **The loud path no longer offers the silencer without the warning.** The `CHANGED`
  message ended with `--write-baseline` and nothing else; the anti-reflex text lived in
  the baseline header, i.e. inside the file that command overwrites, where the person
  running it never had to read it. The warning now sits at the decision point.
- **The `DISAPPEARED` message leads with "restore", not "delete".** It previously
  offered deleting the baseline first - a single `rm` that converts the loudest alarm
  into permanent good news, since nothing tracks the baseline's absence. Deleting is
  still the right move when the divergences were dropped on purpose; it now comes
  second and asks for the decision to be argued in the CL description.
- **Creatives on-ramp: step 0 is now getting a seat.** The section began at "install the
  extension", but Claude Code demands a sign-in the moment it starts and will not run
  without an account - so a designer on a fresh machine hit a login wall with no named
  person to ask. It also told the reader they did not need "the terminal version" and
  then asked them to run two commands in a terminal; it now points at VS Code's built-in
  terminal instead of contradicting itself.

#### Added

- `run-hook-tests.ps1`: cases for the deleted file and the signature-less baseline, both
  written red against 4.31.0 first (15 passed, 2 failed), green after. Suite total 17.

## [4.31.0] - 2026-08-07 - The baseline now guards the case it was built for

MINOR: consumers get it automatically, and it changes what the check reports.

Two independent reviewers converged on the same hole in 4.29.0 during the reference
consumer's review pass. Both were right, and both defects were reproduced before fixing.

#### Fixed

- **The check was SILENT on the exact incident class it exists for.** If someone "made the
  two files match" - deleting every Codex-only qualifier from AGENTS.md, which is the
  silent-reversal shape this detector descends from - the sections became identical and
  the script printed `hard-rules sections are identical`, exit 0. Its single most
  reassuring message, emitted at the precise moment Codex lost its rules. Same for a
  renamed or deleted `## Hard rules` heading: `nothing to check`, exit 0.
  Both paths returned before the baseline was ever read. A recorded baseline is positive
  evidence that a difference BELONGED there, so absence of a difference is only good news
  if nobody wrote that one was expected. The baseline is now read first and both paths
  report `N sanctioned divergence(s) have DISAPPEARED` and exit 1.
  `--write-baseline` hits the same guard deliberately: it used to print "nothing to
  record" and leave the stale baseline on disk, so the collapse persisted silently even
  after someone tried to re-record it.
- **The signature carried diff CONTEXT, so it re-flagged edits that changed nothing.**
  The header claimed "an unrelated edit elsewhere in the section does NOT re-flag the
  set". That was false: with 3 lines of context, an identical LOCKSTEP edit made to both
  files within 3 lines of a divergence fired the alarm. Measured on the reference
  consumer's bibles - 14 of 31 signature lines were context, making ~39% of the
  hard-rules section a false-alarm surface. Now `diff -U0`: the diverging lines and
  nothing else, which is what "the divergence set" actually means. The header's claim is
  now true rather than qualified.
  This matters beyond tidiness: false alarms are how `--write-baseline` becomes muscle
  memory, and a rubber-stamped baseline is a dead check that still looks green.
- **`no '## Hard rules' section in both files`** fired when EITHER file lacked one - and
  mis-described the more dangerous case. It now names the file that is actually missing it.

#### Changed

- The generated baseline header now carries the anti-reflex instruction (read what
  changed before re-recording; a rubber stamp is a dead check) rather than one passing
  clause. Previously that guidance existed only in a consumer's `.scratch/` ticket, which
  no package consumer ever sees.
- **Correction to the 4.29.0 entry below:** it says the no-baseline path is "byte-identical
  to 4.28.0". Exit code and finding are identical; stdout gains two lines pointing at
  `--write-baseline`. The behaviour is compatible, the bytes are not. Recorded here rather
  than edited above, because a shipped entry describing what a release did should not be
  quietly rewritten.

#### Added

- `run-hook-tests.ps1`: four cases - divergences disappeared, section gone, lockstep edit
  stays quiet, and `--write-baseline` refusing over a stale baseline. All four written red
  against 4.30.0 first (11 passed, 4 failed), green after. Suite total 15.
- The creatives MustRead "Getting set up" section gains what a non-engineer actually
  needs: **step 0, install Claude Code** (it previously began at "open the project",
  assuming the tool was already there); an explicit note of WHERE each command is typed
  (chat box vs terminal - the likeliest silent failure); a one-line gloss of "skills";
  and an absolute URL for the package repository. Naming SETUP.md without a way to reach
  it left ticket 05's own stated problem - "invisible to a teammate browsing
  Docs/MustRead/" - standing.

## [4.30.0] - 2026-08-07 - A null revision is not a claim

MINOR: consumers get it automatically, and it changes when a write gate opens.

#### Fixed

- **Preflight check 4 no longer locks the routine update path shut after a structural
  CL submits.** An entry created while its file was a pending ADD carries
  `depotRevision: null` - correct at that moment, and check 4 already skipped it while
  the add was open. But once the CL submitted, head became 1 and null matched nothing,
  so every subsequent `install.ps1 -Mode Write` (and therefore every `update.ps1`)
  refused. The only escape was `upgrade.ps1` - the heavyweight path a routine update
  exists to avoid, and the one that needs an empty default changelist.
  Contrast the pending-EDIT tolerance immediately below it, which records `head + 1`
  and therefore self-clears on submit by construction. The ADD path had no such value.
  A null depotRevision is the ABSENCE of a recorded revision, not a claim that can
  contradict the depot, so it is now counted and reported rather than gating; the write
  that follows the preflight is what baselines it.
  Real drift still fails (scenario E), and pending-ADD-of-local-state still fails
  check 6 (scenario I) - this weakens neither.
  - Found live on the reference consumer while propagating v4.29.0:
    `.claude/scripts/check-rules-alignment.sh`, added by upgrade in change 2142 and
    submitted as change 2145, blocked the next `update.ps1` outright.
  - `run-pending-opens-tests.ps1` scenario J pins the add-then-submit sequence, written
    red against 4.29.0 first.

## [4.29.0] - 2026-08-07 - Drift detection, not difference detection

MINOR per this file's own rules: both changes reach consumers automatically (plugin update
+ update.ps1), and one is a behaviour change to a shipped script. The follow-up ticket that
requested this work proposed PATCH; the table above says otherwise, and the table wins.

#### Changed

- **`check-rules-alignment.sh` gains baseline mode.** It reported every difference between
  the two bibles' hard-rules sections, forever. But on a project supporting both harnesses,
  permanent sanctioned divergence is the DESIGN, not the defect - so the advisory printed at
  every SessionStart asking for a confirmation no consumer had any way to record. That is how
  the detector built for the silent-reversal incident class turns into background noise, which
  is worse than not shipping it: it still looks like coverage.
  With `.claude/rules-alignment.baseline` present the check reports only what CHANGED since
  that file was written - the signal its own header claimed to be for since it was written.
  Without a baseline, behaviour is byte-identical to 4.28.0; baseline mode is opt-in by the
  file's presence and nothing else.
  - `--write-baseline` records the current set; `--baseline <file>` overrides the path.
  - The signature is a unified diff with `@@` line numbers stripped, stored as readable text
    (not a hash) so a reviewer can see exactly what was sanctioned. An unrelated edit
    elsewhere in the section does not re-flag the set; a change to WHICH rules diverge does.
    Measured on the real Myst bibles: rewording one Claude-only qualifier fires the check
    while the hunk COUNT stays at 2 - a count-based comparison would have missed it.
  - `--advisory` still exits 0 on every path. A SessionStart hook must never fail a session.

#### Added

- **Creatives MustRead gains a "Getting set up" section** (EN + CN): three install steps, the
  two-command update, and a pointer to SETUP.md as the authority. SETUP.md lives in this
  repository - invisible to a designer browsing the project's `Docs/MustRead/`, which is where
  they actually look; the doc previously ended at "ask the project lead". Commands and a
  pointer only, never copied process prose: duplicated prose is the thing that drifts apart.
- `run-hook-tests.ps1`: four cases covering baseline recorded / changed / changed-under-
  advisory, plus a backward-compat pin that the no-baseline path still behaves exactly as
  before. The three baseline cases were written red and confirmed failing against the 4.28.0
  script before the fix existed.

## [4.28.0] - 2026-08-06 - Audit hardening: the kit fixes what its own audit found

MINOR per this file's own rules: every change below reaches consumers automatically
(plugin update + upgrade.ps1) - including the removals, which the rules explicitly
class as MINOR. The one **breaking edge** is called out under Changed. A four-agent
user-perspective audit of the whole kit (2026-08-06) drove all of it; the fix plan
survived four adversarial review rounds before execution.

#### Removed (consumer-visible; migrate-retired-skills.ps1 carries the list)

- **Five personal/off-topic skills**: `obsidian-vault` (hardcoded personal vault path,
  model-invocable on every machine), `teach`, `edit-article`, `grill-me` (pure alias
  of `grilling`), `setup-matt-pocock-skills` (could rewrite installer-owned
  `Docs/agents/*` in scaffold-managed repos). Catalog is now 24 skills, all
  team-relevant. Bootstrap references repoint to SETUP.md.
- **`design-workflow` merged into `design`**: one skill, one process truth. The
  automation flow stays in `design/SKILL.md`; ALL process authority (naming, suffix
  lifecycle, reviewer routing, BLOCKING/WARNING/INFO vocabulary) lives in the new
  `design/PROCESS.md` - with design-workflow's rules winning every historical
  contradiction ("remove `_WIP`, never `_Updated`" - the /design flow previously
  instructed exactly the suffixes doc-audit bans).

#### Changed

- **BREAKING EDGE - `promote.ps1` requires an explicit `-Force` for divergent
  promotions.** It was hard-coded on every write, silently bypassing
  promote-from-project's upstream-divergence refusal; a stale clone could overwrite
  newer upstream work. Now: freshness gate (fetch + refuse when behind origin/main,
  `-AllowStale` to override) and `-Force` only when you pass it. The refusal prints
  the remedy. Wrapper tests pin both sides of the new contract.
- `setup.ps1` auto-wraps `-UsePerforce -Changelist new` (parity with update/upgrade):
  fresh P4-consumer installs no longer land scaffold files unopened in any CL.
- `/update-myst-skills` routes MINOR/MAJOR version jumps to `upgrade.ps1` (update.ps1
  structurally cannot add or retire files) and points at the auto-maintained
  marketplace clone instead of duplicate-clone hunting.
- `doc-audit.sh`: single-pass rewrite, measured 13.6s -> 0.7s on the reference tree
  (it ran at every SessionStart including /clear and /compact); status matching is
  field-anchored (line start or pipe-segment - both measured forms) so prose cannot
  shadow the real field; two-tier docs-root sanity (unrendered {{token}} -> loud
  ERROR, absent dir -> quiet note; still always exit 0); NEW local-files-only
  version-staleness nudge (installed cache vs marketplace clone).
- Skill content truth pass: P4-NOTES/UE-NOTES finally linked (they were orphaned
  while git-centric instructions shipped on a Perforce team); `implement`/`tdd`
  route to review-and-submit; reviewer agents referenced by their NAMESPACED names
  (`myst-dev-kit:architecture-reviewer` - bare names do not resolve, live-confirmed);
  `to-spec` starts specs at `needs-triage` per the documented flow; stale
  CamelCase rule-file references fixed across seven files; unrendered
  `{{game_docs_root}}` tokens replaced with resolution rules (doc-audit.sh keeps
  its real installer token); radical-design-critic verdict placement pinned +
  de-emoji'd; auto-plan-mode gains the worked examples its rule doc promised.

#### Fixed

- **Windows PowerShell 5.1 crash class across the lifecycle scripts** (measured:
  EAP='Stop' + ANY native stderr redirection throws, 2>$null included):
  `update.ps1` died exactly when a pull had content; setup/upgrade p4 probes died
  on p4-present-but-stderr. All native calls EAP-scoped; `$LASTEXITCODE` judged.
  CI could never see this class (pwsh-only) - the new `ps51-gates` job runs the
  parse gate AND the git-pull regression under real powershell.exe.
- **Provenance rot**: consumer manifests recorded `package.version: 1.0.0` forever.
  Triple fix (ManifestUpdate stamp + install threading + init-consumer resolution
  with template sentinels); staleness diagnostics stop lying.
- **upgrade.ps1 reconcile guards**: evidence annotations (blockHashReason) carried
  forward across regeneration; ADOPT constructor reuses the installed manifest's
  entry (defensive - protects the first entry that grows a note); depotRevision
  cast guarded (pending-adds emit empty headRev; `[int]''` silently coerced to 0
  against the code's own stated null intent); p4-where parse stops relying on
  regex-greediness accident.
- **InstallJournal EOL policy** (write path only): `.sh` always LF; everything else
  preserves the target's existing EOL; new files LF. The old unconditional
  CRLF->LF flip rewrote whole CRLF consumer files on every content change. The
  comparison path stays LF-normalized (the install/compare identical-bytes
  guarantee). Journal tests cover all four cases.
- Docs truth pass: README layout tree/overlays table/skills tables match the
  repository that actually exists (with resolving links, now CI-guarded);
  SETUP.md documents the required two-step plugin update; CONTRIBUTING
  acknowledges CI and five version sites; install.md drops the stale
  never-observed Codex-hook claim, gains the Marker Specification section, and
  fixes its dangling links; the creatives MustRead stops advertising three tools
  (both languages); DocumentStandard overlay's dead DesignWorkflow.md pointer
  fixed; submit-audit-bridge header claim corrected.
- Package `.sh` normalized to LF with a narrow `.gitattributes` (`*.sh` only);
  the one stray UTF-8 BOM stripped.

#### Tests (16 -> 18 suites; CI-asserted count follows the glob)

- NEW `run-hook-tests.ps1`: package-shipped bash hooks, pinned exit codes with
  fixtures (the missing-fixture branch is a pinned NEGATIVE, never a vacuous pass);
  the unrendered-token loud branch is itself asserted.
- NEW `run-ps51-pull-tests.ps1`: the git-pull regression end-to-end under real
  powershell.exe against a local bare-repo fixture.
- `run-linkcheck-tests.ps1` scans `plugins/` (the removals/merge are now a standing
  machine gate, not a one-shot grep); dead legacy allow-list pruned to empty.
- `run-upgrade-tests.ps1`: ADOPT preservation + pending-add depotRevision:null
  cases via the fake-p4 shim. `run-journal-tests.ps1`: four EOL write-path cases.
- `run-wrapper-tests.ps1`: pins the promote refusal-then-`-Force` contract.
- `check-plugin-parity.ps1`: Count-column assertion (tolerant of the non-numeric
  `1 entry` cell).

Historical ADRs intentionally untouched; they describe the tree as it was.

## [4.27.1] - 2026-08-06 - The Codex hook was watched firing, so the docs stop hedging

#### Fixed (documentation - no behavioural change)

- **The `hooks/` row goes back to `measured`, with the right evidence this time.** v4.26.0
  honestly downgraded it to `unverified`: the old "measured" only ever covered *project*-level
  hooks failing to load, and nobody had watched a **plugin** hook fire under Codex. That has now
  been observed end-to-end - `${CLAUDE_PLUGIN_ROOT}` resolves, the gate passes, and the bridge
  reaches `exec` on the consumer's real `submit-audit-warn.sh`, on two consecutive tool calls.

  Three hypotheses died with it: hook trust is **not** required for plugin hooks, `"matcher":
  "Bash"` **does** match Codex's shell tool (which logs as `exec` and runs `pwsh.exe`), and
  **`CODEX_HOME` is empty inside the hook subprocess** despite appearing 53 times in `codex.exe`.
  That last one matters most: `CODEX_HOME` was the obvious variable to gate on, and doing so
  would have shipped a second dead gate failing exactly as `PLUGIN_ROOT` did. Gating on the host
  you want to **exclude** is what made it work.

  Also recorded, because it produced a completely convincing false negative for several rounds:
  **two copies of an installed Codex plugin exist and only one runs** - the `plugins/cache/` copy
  is live, the `.tmp/marketplaces/` copy is inert.

- **`SETUP.md` and `README.md` claimed the plugin gives Codex "both reviewer agents".** It does
  not, and this survived the v4.25.0 pass that was supposed to fix exactly this claim. They ship
  but cannot run: they are Markdown and Codex agents are TOML. Corrected in both, alongside the
  Submit-Audit bridge claim - which was false for two years and is now true, so it is stated with
  its verification date rather than left true by luck.

## [4.27.0] - 2026-08-06 — CI exists, and its first run found that the installer never worked without Perforce

#### Added

- **`.github/workflows/tests.yml`** — there was no CI. `run-*-tests.ps1` ran only when a human
  remembered to type it, so *"the suite is green"* was never a property of `main`, only of the
  last time someone looked. It was **red on `main` from PR #65 through PR #66** and was found by
  accident while editing a nearby file.

  Runs all 16 suites on every PR, on `windows-latest` (these scripts are written for Windows —
  `run-marketplace-tests.ps1` does `-replace '/','\'` before `Join-Path`; CI runs the same code
  the maintainer runs, not a port of it). Every suite runs even after one fails. **SKIP counts
  are surfaced per suite**, because `run-p4spec-tests.ps1` skips its P4 cases and still exits 0
  with no `p4` client — a green build with skips is weaker than one without, and the summary now
  says so instead of hiding it. Empty discovery is a hard error: zero suites matched would
  otherwise pass as green.

  Second check: both README badges are asserted against the tree — suite count against the number
  of `run-*-tests.ps1`, version against `package-manifest.json`. Both are hand-maintained numbers
  that drift silently; the version badge sat at v4.24.2 through two releases.

#### Fixed

- **`setup.ps1` failed outright on any machine without the Perforce CLI.** The version-control
  auto-detection probed with `& p4 -F "%clientRoot%" -ztag info 2>$null`. `2>$null` redirects a
  *native* command's stderr; it does not suppress `CommandNotFoundException`, which PowerShell
  raises before any process starts — and `setup.ps1` runs under `$ErrorActionPreference = 'Stop'`.

  So the documented one-command install **terminated**, and the road to `filesystem` mode — which
  `README.md` advertises as the default when there is no `.p4ignore` — ran straight through that
  unguarded call. Measured, old vs new, with `p4` hidden from PATH:

  | | exit | p4 crash | files installed |
  |---|---|---|---|
  | before | 1 | yes | **0** |
  | after | 0 | no | 12 |

  This could not be seen on a Perforce workstation, which is every machine the package has ever
  been developed or tested on. Found by CI on its first run.

- **All 38 `.ps1` files were UTF-8 with no BOM and carried 40 non-ASCII characters** (38 em-dashes,
  one en-dash, one section sign). Windows PowerShell 5.1 — which this package spawns as
  `powershell.exe` children — reads a BOM-less script in the system ANSI codepage. Under cp1252 the
  em-dash's third byte `0x94` decodes to `U+201D RIGHT DOUBLE QUOTATION MARK`, and PowerShell
  accepts smart quotes as string delimiters, so the string terminates early. That was the
  `ParserError` at `migrate-retired-skills.ps1:44`.

  Never seen because the maintainer's ANSI codepage is **65001 (UTF-8)**; GitHub runners are 1252.
  These suites had never run on a standard Windows codepage.

  Fixed as ASCII rather than by adding BOMs, deliberately: the Edit/Write tooling used on this repo
  strips BOMs, so a BOM fix would be silently undone by the next edit and the bug would return with
  no diff to show for it. Covers `scripts/`, `scripts/lib/` (dot-sourced, same exposure) and the
  root wrappers.

#### Consumer impact

**None for an existing install.** Nothing in this release is copied into a consumer project — these
are run-from-the-clone installer scripts plus maintainer CI. Skills, hooks, rules and agents are
untouched; no plugin update or restart is needed. What changes is **onboarding for anyone not on a
Perforce machine**, who previously could not install the package at all.

## [4.26.0] - 2026-08-06 — The Submit-Audit bridge had never run, on any host, ever

#### Fixed

- **`submit-audit-bridge.sh` gated on a variable that does not exist.** Its guard was
  `[ -z "${PLUGIN_ROOT:-}" ] && exit 0`, on the belief — documented in its own header, and
  repeated in `docs/install.md` and this changelog — that Codex exports a native `PLUGIN_ROOT`
  alongside the `CLAUDE_PLUGIN_ROOT` compat alias.

  It does not. In `codex.exe` 0.146.0 (323 MB) the string `PLUGIN_ROOT` occurs **exactly once**,
  as a substring of `CLAUDE_PLUGIN_ROOT`; `CODEX_PLUGIN_ROOT` occurs zero times. Control proving
  the zero is meaningful, since env names are stored in the clear: `CODEX_HOME` occurs 53 times
  by the identical grep. `PLUGIN_ROOT` was therefore unset on **every** host, the gate was
  always true, and the bridge exited 0 before doing anything — for its entire life, under both
  tools. Every Codex teammate has been submitting with no client-side Submit-Audit warning, in
  a state **indistinguishable from clean**: no missing-`Ticket:` warning, no non-ASCII warning,
  no BP-Pins warning.

  The gate now tests `CLAUDECODE`, which Claude Code really does export (read from a live
  shell) and which Codex aliases zero times — along with `CLAUDE_PROJECT_DIR`, `CLAUDE_PID` and
  `AI_AGENT`, so Codex aliases no Claude host marker at all, unlike `CLAUDE_PLUGIN_ROOT`.

- **The direction of the gate was the actual defect**, not the variable name. Testing for a
  marker of the host you want to *include* sends every unknown, renamed or future host down the
  silent branch. Testing for the host you want to *exclude* sends them down the running branch,
  where the worst case is one duplicate advisory warning. A hook that never fires is
  indistinguishable from a hook that fired and found nothing — which is why this survived from
  4.13.0 to 4.25.2 with nobody noticing.

- **`run-marketplace-tests.ps1` was pinning the bug in place.** Check 9 asserted the literal
  string `[ -z "${PLUGIN_ROOT:-}" ] && exit 0` and reported `Bad 'bridge gate'` if it was
  missing — so the suite reported **green on the broken gate and would have reported a
  regression on any correct fix**. It now asserts the two properties that matter (a gate on a
  real host marker, ordered before the `exec` that hands stdin to the audit) and fails loudly
  and specifically if it ever sees `PLUGIN_ROOT` again. A test that asserts an implementation
  string cannot notice that the string is wrong.

- **`MYST_AUDIT_DEBUG=1`** makes every bridge exit path announce itself on stderr. This exists
  because the fix is **not** verifiable by reading it: a rename is not the fix, an observed run
  is. Total silence under that flag means the script never ran at all.

#### Changed

- **`docs/tool-capability-matrix.md` — three rows corrected against measurement.**
  - `agents/` said Codex "has no subagent mechanism", evidence `measured by absence`. False:
    `~/.codex/agents/` holds **22 `.toml` agents** including `code-reviewer`, and `codex.exe`
    names `subagents` 19 times as a plugin resource kind. **4.25.0 stripped the two reviewer
    agents from the Codex plugin description on this false premise.** They do ship inert, but
    because they are Markdown and Codex agents are TOML — a closable gap, not a missing feature.
  - `scripts/` claimed 8 files "neither tool loads as a plugin capability". There are **5**, and
    `submit-audit-bridge.sh` is loaded by the plugin hook loader and appears in no manifest.
  - `hooks/` was marked `measured` for Codex. That measurement only covered *project*-level
    hooks failing to load. **Nobody has observed a plugin hook firing under Codex** — and the
    one plugin hook that exists could not have, per the fix above. Now `unverified`.
- **`"measured by absence" is named as an invalid evidence class**, with the rule that a
  negative claim needs a control: name something you *would* have found by the same method and
  show that you found it. It produced two wrong rows in one table.

#### Still open

Whether Codex plugin hooks fire **at all**. The strings evidence proves the variable was wrong;
it cannot distinguish "wrong variable" from "plugin hooks never fire under Codex". Both are
consistent with everything observed. Verify with `MYST_AUDIT_DEBUG=1` in a live Codex session —
and upgrade the Codex plugin first, since a stale cache measures the wrong build.

## [4.25.2] - 2026-08-05 — Preflight step 2 says what a silent run does and does not license

#### Fixed
- **`review-and-submit` preflight step 2** told the agent to run
  `submit-audit-warn.sh --check-cl {CL_ID}` and handled only the failure direction ("on any
  warning or non-zero exit: report it"). It never said what **exit 0** licenses — and an agent
  citing a silent run reads the skill, not the script header.

  Measured: a nonexistent CL number, an already-submitted CL, a garbage CL id, and an
  unreachable `p4` all fetch zero files, so no check fires, so the run exits 0 and prints
  nothing — **identical to a genuinely clean CL**. A mistyped CL number reports green.

  Step 2 now carries the contract and the one-line confirmation that makes a silent run
  citable: check the CL is pending first.

This is the origin point of the citation, not a duplicate of the script-side warning. The
consumer-side script header can only be read by someone already looking at the script; this
is read by the agent that is about to cite the result.

## [4.25.1] - 2026-08-05 — The plugin's cross-tool capability contract, written down and checked

#### Added
- **`docs/tool-capability-matrix.md`** — the plugin ships one tree and two manifests, so
  Claude and Codex do not receive the same capabilities. That was true, deliberate, and
  recorded nowhere.

  The matrix records what reaches which tool with an **evidence class per row** — measured /
  declared / convention / unverified — so a believed-but-never-run claim cannot pass as a
  measured one. The `commands/` row is honestly marked *unverified*: nobody has confirmed
  Codex discovers them. Every gap names its fallback, because a capability with no fallback
  is a silent hole.
- **`scripts/check-plugin-parity.ps1`** — asserts the matrix against the tree: every
  capability directory has a row, the manifests declare what the matrix says, and no
  description promises a capability its own tool cannot run. Advisory mode for CI.

  It checks declarations and files, **not runtime behaviour** — the same distinction
  `check-rule-parity.sh` draws between proving a counterpart exists and proving it is good.
  A maintainer script (package `scripts/`), not consumer-delivered.

#### Fixed
- **The Codex plugin description advertised both reviewer agents.** Codex has no subagent
  mechanism, so `agents/` ships inert there; the description promised a capability the tool
  cannot run and never mentioned that `review-changes` is the actual Codex review path. Both
  corrected. `check-plugin-parity.ps1` reproduces the finding if the fix is reverted.
- **`toolCapabilities.deviations` cited `.Codex/workflows/AutoPlanMode.md`**, which does not
  exist in the package. The one field designed to record tool deviations had been wrong for
  some time. Replaced with the three that are real, two of them measured.
- **`scripts/` had no matrix row at all** — found by the new check on its first run.

Same root cause as 4.25.0: an invariant that is true when written, has no check, and is
relied on later. That one got a script and a generator; this one got a matrix and a check.

## [4.25.0] - 2026-08-05 — Two invariants that were prose, made checkable

#### Added
- **`check-rules-alignment.sh`** — a sibling to `check-rule-parity.sh`, wired into
  `doc-audit.sh` at SessionStart as `--advisory`, gating when run directly.

  The parity check proves a rule is *mentioned* in `AGENTS.md` and says so in its own
  header — it would exit 0 with the shared hard-rules section completely rewritten.
  Projects that keep one hard-rules baseline across both tools therefore had an invariant
  nothing checked. This diffs the `## Hard rules` section of `CLAUDE.md` against
  `AGENTS.md`'s and reports the hunk count.

  It reports divergence, it does not judge it: a per-tool difference is legitimate and
  common, so the output means "confirm each of these is deliberate", never "these are
  defects". No-ops cleanly on projects without a shared `## Hard rules` section, and on
  projects with no `AGENTS.md`.

#### Changed
- **`review-and-submit`** — the Review Record's `Verdict: … (N passes; …)` line must now be
  **generated from a verdict list and written last**, not typed.

  It is the one field in a CL description that cannot be true until the review ends, so a
  multi-pass review invalidates a hand-written one every time a pass lands. Observed in
  practice on a nine-pass review: the line was stale in four consecutive passes, and the
  reviewer's own suggested correction to it was itself stale on arrival — it proposed a
  final verdict of GREEN in the same message that returned BLOCKING.

  The rule generalises past that field, and the skill now says so: any derived figure in a
  description — byte counts, file counts, finding tallies — gets re-derived from the live
  artifact at submit time or left out. A number measured at review time and frozen into a
  description is wrong by submit time more often than not.

Both changes come from the same root cause: an invariant that is true when written, has no
check, and is relied on later. One got a script; the other got a generator.


## [4.24.2] - 2026-08-04 — `SETUP.md`: one line to hand the whole thing to an agent

#### Added
- A *Just ask the agent* section at the top of `SETUP.md` with a single copy-paste prompt:
  *"Install or update my myst-dev-kit plugin, verify the version, and tell me what I still have to
  do myself."*
- Works for either tool, and in IDE sessions with no `/plugin` command, because `claude plugin …`
  and `codex plugin …` are ordinary CLI subcommands rather than in-session features.
- States the two things the agent **cannot** do, so nobody is left waiting on them: it cannot
  restart your Claude session (Codex applies in place; Claude needs the restart), and it may need
  you to approve the commands the first time.

The manual steps stay exactly where they were, below, for anyone who would rather drive.

## [4.24.1] - 2026-08-04 — README documents how to UPDATE the plugin, not just install it

#### Fixed
- The README explained how to install the plugin for both tools and **never once mentioned
  updating it** (`grep -c "plugin update" README.md` → 0). v4.20.0 documented the verified
  sequences in `SETUP.md` and `docs/install.md` but left the front door — the file most people
  read first — with no way to get a newer version.
- Adds a *Keeping the plugin up to date* section with both sequences, the per-tool difference
  called out explicitly (Claude needs `marketplace update` **then** `plugin update` **then** a
  restart; Codex's `marketplace upgrade` **is** the whole update, and no `codex plugin update`
  subcommand exists), how to verify each, and the note that `claude plugin …` works from a plain
  terminal when a session has no `/plugin` command.
- Carries the two measured Codex limits — no auto-loaded rules directory, no project-level hooks —
  so nobody designs around capabilities Codex does not have.

Docs only; no behaviour change, hence a patch bump.

## [4.24.0] - 2026-08-04 — The write gate stops policing files the installer does not own

### Checks 2 and 4 exempt `human-owned` entries

#### Fixed
- **Editing your own file still closed the write gate.** v4.21.0 exempted block-scoped entries from
  check 4 after a human edit to `AGENTS.md` red-lighted the gate three times in one day. That fix
  was scoped to the three examples in front of it rather than to the category they belonged to —
  so the identical failure returned the moment someone edited a `human-owned` doc
  (`.claude/rules/DocumentStandard.md`, submitted as a normal docs change), tripping **both**
  check 2 (hash) and check 4 (revision).
- Both checks now skip entries whose `writablePolicy` is `human-owned`, and both report the count
  in their own result line rather than skipping silently.

The governing rule, stated once so it stops being rediscovered: **if the installer does not own a
file, the installer's gate does not police it.** `human-owned` means exactly that — the installer
never writes it, so its recorded hash and revision are bookkeeping, not safety. `diff-installed.ps1`
still reads them to annotate a drift report, which is informational and never gating; and since
v4.22.0 `upgrade.ps1` keys customization detection on recorded **ownership** rather than hashes,
nothing load-bearing depends on those baselines any more.

#### Not weakened
Entries the installer *does* own are untouched: an `installer-owned`/`copy` file with a stale hash
or revision still fails both checks, because for those a mismatch genuinely means drift. Verified by
the existing scenario E (real drift still fails check 4) alongside the new case.

#### Added
- `run-pending-opens-tests.ps1` scenario G: a `human-owned` entry whose manifest hash **and**
  revision both disagree with reality must not gate. Confirmed to fail without the fix (`code=1`)
  and pass with it. 17 suites, all green.

Verified on the live consumer: preflight returns to **10/10** with no manifest hand-patching — which
was the alternative on the table and would have had to be repeated after every future edit.

## [4.23.0] - 2026-08-04 — `doc-audit.sh` stops reporting health it never checked

### The SessionStart doc audit was a false green

#### Fixed
- **It only ever looked at the top level.** `for file in "$DOCS_DIR"/*.md` meant every
  subdirectory was invisible. On the reference consumer that hid **24 of 60** docs, and the hook
  printed `Doc audit: all clean.` over a tree containing 7 lifecycle violations. A check that
  cannot see most of what it claims to cover is worse than no check, because people trust it.
  Now recurses.
- **The self-reference in its header pointed at a path that does not exist**
  (`Claude/DocumentStandard.md` → `.claude/rules/DocumentStandard.md`).

#### Added
- **Lifecycle checks** — the drift mode filename rules structurally cannot catch: a doc whose
  declared `Status:` contradicts its own filename. Flags `_WIP` files marked `COMPLETE`/`DEPRECATED`,
  `ToBeDeleted_` files marked `COMPLETE`/`WIP` or carrying no status at all, and `WIP` docs missing
  the `_WIP` suffix. Status parsing is deliberately tolerant (`**Status**: X`, `**Status** X`,
  `**Status:** X`, trailing emoji or parentheticals; case-insensitive, first match wins).
- `game_direction_` joins the valid prefixes — a real, in-use convention that was simply undocumented.

#### Deliberately exempt
`adr/` (numbered `0001-…` ADR convention) and `_Raw/` (leads-only source material whose names come
from the source) are exempt from the **prefix** check only; banned suffixes and lifecycle still
apply. Without those two exemptions, recursing produces 18 false positives — enough noise to make
the whole audit ignorable.

#### Measured, not assumed
The status window is **20 lines**, not the ~8 first drafted. One real doc carries a deprecation
banner above its title and declares its status on line 11; an 8-line window silently missed it — a
false negative on precisely the drift the check exists to find. Widening from 12 to 30 lines changed
nothing across a 60-file tree, so 20 buys the catch without inviting prose false-positives.

Still advisory: exits 0 on violations, and the failure-isolated rule-parity chain (`--advisory ||
true`) is unchanged, because this runs at every teammate's SessionStart under a timeout.

## [4.22.0] - 2026-08-03 — `upgrade.ps1` no longer lets the template overrule the consumer

### Data-loss fix: human-owned files could be silently overwritten

#### Fixed
- **`upgrade.ps1 -Apply` would overwrite locally-customized, explicitly protected files while
  reporting `PRESERVE (your customizations): 0`.** Found by exercising the tool against a real
  consumer: three files marked `human-owned` / `manual-only` in the installed manifest — carrying
  38, 92 and 5 lines of local content — were classified `REFRESH (untouched -> package)`.

Both of the script's safety nets failed, for the same root cause:
1. **The ownership guard read the wrong manifest.** `upgrade` regenerates the manifest from the
   package template *first*, then checks `mergeStrategy -eq 'manual-only'` on the regenerated entry.
   The template naturally claims everything it ships as `installer-owned` / `copy`, so a consumer's
   deliberate `human-owned` marking was discarded before the guard ever ran.
2. **The customization guard cannot see a pre-existing fork.** It calls a file customized when
   on-disk differs from the recorded baseline — but when a file was customized *before* its baseline
   was taken, the baseline was computed from the forked bytes, so on-disk == baseline and the fork is
   invisible. Every legitimate re-baseline (`install.ps1` refreshes `contentHash` on each write)
   makes this *more* likely, not less.

Ownership recorded in the installed manifest is now carried forward: an entry marked `human-owned`
or `manual-only` there stays that way through regeneration, regardless of what the template claims.
Ownership is a decision the consumer made; the template does not get a vote.

#### Added
- Regression test in `run-upgrade-tests.ps1` for the case no existing test covered: a `human-owned`
  file whose **baseline equals its on-disk content**, so the hash guard is blind and only the
  ownership carry-forward can save it. Confirmed to fail without the fix and pass with it — the
  suite was 6/6 green while this defect was live, because its fixtures build consumer manifests
  straight from the template and ownership therefore never diverges.

Verified on a live consumer: the three at-risk files moved from `REFRESH` to
`PRESERVE (human-owned in the installed manifest)`. All sixteen suites pass.

## [4.21.0] - 2026-08-03 — Editing a file you are supposed to edit no longer closes the write gate

### Check 4 stops revision-tracking the files humans co-own

#### Fixed
- **v4.19.0 unjammed installer writes; hand edits still jammed the gate.** Block-scoped entries —
  `CLAUDE.md`, `AGENTS.md`, `.p4ignore` — are *shared*: the installer owns the generated block and
  humans own everything around it. Editing your own region is the intended workflow, but it bumps
  the depot revision, the manifest doesn't follow, and check 4 red-lighted write mode. In one day of
  ordinary work this fired three times and was hand-corrected three times before the pattern was
  noticed at all.
- Check 4 now **skips block-scoped entries**, counts them, and says so in its own result line
  (`3 block-scoped entries not revision-tracked; blockHash guards them (check 2)`) — visible, not
  silent. Their real protection is check 2's `blockHash`, which covers exactly the installer-owned
  bytes between the markers and is unaffected by edits outside them. Revision movement on these
  files is expected behaviour, not drift.

#### Also: `run-pending-opens-tests.ps1` had been red since 4.16.0 — and nobody noticed
That suite covers checks 4 and 5 through a fake-`p4` shim, i.e. exactly the code 4.16.0 changed.
It was left broken because that release was verified against three suites instead of all sixteen.
Three separate causes, now fixed:
- **The shim did not know `p4 where`.** 4.16.0 stopped hardcoding the depot root and began calling
  `p4 -ztag -F "%depotFile%" where`; the shim's `switch` saw `-ztag` as the verb and fell through to
  `default { exit 0 }`, silently returning nothing. It now strips p4's global flags before
  dispatching, and implements `where` (`FAKE_P4_DEPOT_ROOT`, defaulting to the fixtures' depot).
- **The fixtures built a nested array.** `@( (New-Entry ...), (New-LocalOnlyEntries) )` embedded a
  2-element array as a single "entry", so `$e.<field>` member-enumerated into `Object[]`. It had
  been harmless only by luck — every earlier check skipped that pseudo-entry via a truthy
  `$e.localOnly`; the first check to read `$e.owner` instead crashed on it. `Write-Fixture-Manifest`
  now flattens, and materialises a fake package root so `sourceTemplate` entries resolve.
- **Scenario F asserted semantics that were deliberately removed.** It required an unmanaged depot
  file to *fail* check 5; since 4.16.0 that is reported by check 5b and does not gate. F now asserts
  the behaviour we actually want: reported by name, exit 0.

All sixteen suites pass.

#### Deliberately not weakened
Copy-strategy entries — where the installer owns the *whole* file, so any revision change genuinely
is drift — are untouched. Verified by injecting a false revision on one and confirming check 4 still
fails by name (`manifest=99 head=2`) before restoring it. The `depotRevision` field is left in place
on block-scoped entries: `diff-installed.ps1` still uses it to annotate a hash mismatch, which is
informational and never gating.

## [4.20.0] - 2026-08-03 — Codex is documented as a first-class tool, from a sequence that was actually run

### `SETUP.md` + `docs/install.md`: the plugin half, and how Codex differs

#### Added
- **`docs/install.md` had zero occurrences of "codex"** despite being the document the update
  command points at. It now has a section covering the plugin channel for both tools: what the
  scaffold installer does *not* deliver (skills, agents, commands, hooks), where each tool caches
  it, and how to install, update, and verify.
- **`SETUP.md`** gains the Codex update command and a short statement of what Codex does and does
  not receive.

#### The update commands are not mirror images — do not reason from one to the other
- **Codex**: `codex plugin marketplace upgrade` is the *whole* update. There is no
  `codex plugin update` subcommand, and refreshing the marketplace snapshot replaces the installed
  plugin in place — measured 4.18.0 → 4.19.0 with the cache directory swapped and **no** follow-up
  `codex plugin add`.
- **Claude**: a marketplace refresh does *not* update an installed plugin; it needs an explicit
  `claude plugin update`, followed by a restart.

This was written after running it. The prior expectation — recorded in the plan — was that Codex
would need a re-add, by analogy with Claude's version-pinned cache path. That expectation was
wrong, which is precisely why the sequence was executed before being documented.

#### Two Codex limits, measured rather than inferred
- **No auto-loaded rules directory** — Codex reads `AGENTS.md` only, so an always-on
  `.claude/rules/*.md` never reaches it. That is what `check-rule-parity.sh` (4.18.0) guards.
- **No project-level hooks** — hooks load from `~/.codex/hooks.json` and from installed plugins,
  never from a hooks file committed in the repo. Both `.codex/hooks.json` and `.agents/hooks.json`
  were placed in a live Codex session; neither fired and neither produced a hook-trust entry. A
  repo-local hook is therefore Claude-only unless it ships through the plugin.

Plugin-shipped hooks do work under both tools: Codex exports `PLUGIN_ROOT` alongside a
`CLAUDE_PLUGIN_ROOT` compatibility alias, so `${CLAUDE_PLUGIN_ROOT}` resolves in each; guard with
`[ -z "${PLUGIN_ROOT:-}" ] && exit 0` for Codex-only behaviour.

> **This paragraph is wrong; corrected in 4.26.0 and left in place as the record.** Codex exports
> no native `PLUGIN_ROOT` — it occurs once in `codex.exe`, inside `CLAUDE_PLUGIN_ROOT`. The guard
> above was true on every host, so `submit-audit-bridge.sh` never ran. Gate on `CLAUDECODE`
> instead. Whether plugin hooks fire under Codex at all remains unverified.

## [4.19.0] - 2026-08-03 — The update button stops jamming after one press

### The scaffold updater no longer disables itself

#### Fixed
- **A scaffold write left the gate permanently closed.** `Update-ManifestForChanges` refreshed
  `contentHash` but never `depotRevision` (its header scoped it to three fields; `grep -c
  depotRevision` → 0). So after any write + submit, the manifest still named the *pre-submit*
  revision, preflight check 4 went red, and `install.ps1` — which gates write mode on all ten
  checks — refused every subsequent run. Unjamming it meant hand-editing revision numbers, which is
  a maintainer-only operation. The likely history of this area: someone ran an update once, the gate
  closed behind them, and the crash fixed in 4.16.0 sat undiscovered behind a door nobody could open.
- Now `install.ps1` stamps the revision each file **will have** once its changelist submits
  (`head + 1` for an edit, `1` for an add) and `Update-ManifestForChanges` records it **only when
  the caller supplies one** — the library stays Perforce-free, so filesystem-only consumers are
  untouched. Preflight check 4 tolerates `head + 1` **while the file is open for edit in a pending
  changelist**, and the value becomes exact the moment the CL submits.

#### Why live state rather than the field that already exists
`pendingChangelist` sits on every manifest entry and looked purpose-built for this — but it is only
ever written as `null` at init and read by nothing. It was rejected anyway: a stored flag outlives
its truth (precedent: a retired overlay that printed `mode=live` from a state directory already
deleted). `p4 opened` cannot go stale, check 4 already consults it, and an abandoned changelist
therefore fails loudly instead of being tolerated forever.

- **The installer rewrote the manifest without checking it out.** `scaffold-manifest.json` is `+w`
  (writable without a Perforce checkout), so `Update-ManifestForChanges` silently left it
  modified-but-unopened after every write: excluded from the changelist it belongs to, and a stray
  in the next person's `p4 reconcile`. Found while verifying the revision fix — the previous two
  changelists had it opened by hand without anyone noticing the installer should have. It is now
  opened alongside the files it describes.

#### Changed
- `check-rule-parity.sh` summarises path-scoped rules instead of enumerating them when nothing is
  wrong. It runs at every SessionStart; printing the same two names forever is how a channel stops
  being read, which then hides the finding that matters. A real failure still lists everything.

Verified on a live consumer rather than in a harness — a real package change pushed through
`update.ps1` write mode:

- The installer created a correctly-tagged changelist, verified it empty, opened **both** the
  changed file and the manifest, and left **no stray** (`p4 reconcile -n` → *"No file(s) to
  reconcile"*).
- Preflight reported **10/10 with the write still pending** — manifest at `head + 1`, file open for
  edit, tolerance applied. That state was previously an automatic red.
- **Failure branch exercised, not assumed**: the changelist was reverted and deleted instead of
  submitted, leaving the manifest naming a revision that will never exist. Check 4 went red by name
  (`manifest=2 head=1`), confirming the tolerance is scoped to genuinely open files.
- `run-manifest-update-tests.ps1` 10/10 with 4 new cases, including the filesystem-only path that
  must leave the field untouched.

## [4.18.0] - 2026-08-03 — Always-on Claude rules must have a Codex counterpart

### `check-rule-parity.sh`: the drift that nothing was watching

#### Added
- **`plugins/myst-dev-kit/scripts/check-rule-parity.sh`**, installed to
  `.claude/scripts/` and called from `doc-audit.sh` at SessionStart.
  Claude Code auto-loads every `.claude/rules/*.md` without `paths:` frontmatter, every session.
  Codex has no such mechanism — it reads `AGENTS.md` and nothing else. So a rule added to
  `.claude/rules/` reaches Claude teammates immediately and Codex teammates **never**, silently.
  On the reference consumer that had already happened twice: `BlueprintPinVerification.md` (a HARD
  rule that exists because two changelists shipped five wrong Blueprint-pin claims) and
  `PreImplementationGate.md` both had **zero** mentions in `AGENTS.md`.
  The check greps `AGENTS.md` for each always-on rule's filename; path-scoped rules are advisory.
- Registered in `manifest-template.json` so new consumers get it at init and existing ones on upgrade.

#### Notes on its limits, which are deliberate
- **It proves *mention*, not *coverage*.** `TODO: BlueprintPinVerification` would satisfy it. A
  content or length floor was considered and rejected as brittle — rules legitimately compress to a
  paragraph for Codex — without being much harder to game. The script header says so; green means
  "someone wrote a counterpart", not "the counterpart is good".
- **The anchor is the filename, not new frontmatter.** The three always-on rules currently carry no
  frontmatter at all, and adding an unknown key risks the loader skipping the rule — manufacturing
  the exact failure the check exists to prevent, on the rule with the incident history. Citing the
  rule by path is also useful to a human Codex reader.
- **Failure-isolated at the call site** (`--advisory || true`): `doc-audit.sh` runs at every
  teammate's SessionStart under a timeout, so a bug here must not degrade session start. Run the
  script directly, without `--advisory`, for a gating exit code.
- **Safe for consumers this doesn't apply to**: no `.claude/rules/` or no `AGENTS.md` (a
  Claude-only consumer) exits 0 with a plain message rather than failing.

Verified on the reference consumer across four branches, each run rather than reasoned: parity holds
(exit 0, two path-scoped rules noted as advisory); a scratch `AGENTS.md` with the Blueprint mention
stripped fails by name (exit 1); the same case under `--advisory` exits 0; and a directory with no
rules dir exits 0 cleanly.

## [4.17.0] - 2026-08-03 — The installer stops building its changelist the two forbidden ways

### `install.ps1`: a spec that cannot sweep, written in bytes p4 accepts

#### Fixed
- **The new changelist could inherit the user's default one.** CL creation started from
  `& p4 change -o`, whose new-changelist form pre-fills `Files:` with **every** file currently open
  in the default change — so an install would silently drag unrelated work into its own CL and
  submit it under a scaffold description. The spec is now built in-script with **no `Files:`
  section at all**, which removes the possibility rather than working around it. Both the team's
  own `review-and-submit` skill and the `feedback_p4_change_default_contamination` note have warned
  against `p4 change -o | p4 change -i` for exactly this reason.
- **The spec was rejected by p4 anyway.** Piping it in from PowerShell prepends a UTF-8 BOM and p4
  fails the whole spec with `Unknown field name`. Now written via
  `[System.IO.File]::WriteAllText(..., UTF8Encoding($false))` and redirected with
  `cmd /c "p4 change -i < <file>"`. Note for future editors: `<` is a **reserved, unimplemented**
  operator in PowerShell 5.1 and 7 alike — `p4 change -i < $f` is a parse error, and piping instead
  reintroduces the BOM.
- **The default CL tag violated the convention the audit greps for.** `[scaffold]` is a single tag;
  submit audits expect `[jobFamily][name]`. Now `[scaffold][install]`, still overridable via
  `installedProject.clTagPrefix`.

#### Added
- **Post-creation assertion**: the installer now verifies `p4 opened -c <newCL>` is empty before its
  first `p4 edit`/`add` and aborts otherwise — a last line of defence that also closes the window
  between the preflight's default-CL check and the moment the CL is created.
- **`scripts/lib/P4Spec.ps1`** (`New-P4ChangeSpecText`, `Write-P4SpecFile`) and
  **`scripts/run-p4spec-tests.ps1`**. The logic was extracted precisely so it can be tested: the
  CL-creation branch sits inside `if ($Changes.Count -ne 0)`, so a no-op install never reaches it
  and only a genuinely destructive write would exercise it live. The suite asserts no `Files:`
  section, no BOM, tab-indented description lines, a double-bracket tag, that `p4 change -i` accepts
  the spec, and — with a file deliberately opened in `default` — that the file **stays there** and
  the new CL comes up empty. P4-dependent cases SKIP when no client is reachable, so
  filesystem-only consumers can still run the suite.

#### Changed
- The write gate no longer pipes its preflight through `Out-Null`. Report-only findings (v4.16.0's
  check 5b `WARN` lines) were being discarded in the one context where they matter most.

Verified against a live consumer at preflight 10/10: 8/8 spec assertions pass, and with `default`
deliberately dirtied the anti-sweep case reports "1 file(s) stayed put" — a behavioural proof, not a
shape assertion. Test changelists are deleted in teardown.

## [4.16.0] - 2026-08-03 — The write gate stops crashing, and stops judging consumers by their own files

### `run-skeleton-preflight.ps1`: correct, portable, and no longer fatal on a missing root

#### Fixed
- **The preflight crashed before finishing.** Check 5's `& p4 have` was the one unguarded native
  call in the script (`:33` and `:51` were already wrapped): p4 writes its ordinary "file(s) not on
  client" notice to stderr, which `$ErrorActionPreference = 'Stop'` turns into a terminating error,
  so checks 5–10 never ran and the failure looked like a failed check rather than a crash. Now
  routed through `cmd /c "... 2>nul"` — the mechanism check 6 already used — with per-root
  accounting so an unresolvable root is reported, never rendered as "nothing found".
- **The depot root was hardcoded to `//UEPrototype/main/` in four places** (`p4 opened` parsing,
  the head-revision lookup, the `p4 have` query and its result regex) inside a package whose
  premise is reuse. Now derived per consumer via `p4 -ztag -F "%depotFile%" where "<TargetRoot>/..."`.
  Note for anyone tempted by the shorter route: `p4 info`'s `clientRoot` is a **local** path, so
  using it would make every depot query match nothing and turn the gate into a silent pass.

#### Changed
- **Check 5 now asks a question a project-agnostic package can answer.** It used to fail when any
  depot-tracked file under `.claude/`, `Docs/agents/` or `Docs/MustRead/` was absent from the
  manifest — unanswerable by construction, because every consumer legitimately keeps its own rules
  and scripts under those roots. On this repo that was six consumer-owned files, none of them
  shipped by the package, permanently blocking write mode. Recording them in an *install* manifest
  would have grown the gate with content the package does not own.
  The check now runs the other way: **every entry with `owner ∈ (package, overlay)` must still
  resolve to a live `sourceTemplate` on disk.** Two independent sources (consumer manifest vs
  package filesystem), so it can genuinely fail; it catches the *stale managed entry* — still
  claimed, source retired. Entries with `hashPolicy: self-excluded` are exempt (the manifest's own
  entry is generated, never rendered). It needs no Perforce, so filesystem-only consumers get it too.
- **New check 5b keeps the old scan as report-only**, via a new `WARN` level surfaced in the closing
  banner. It preserves the orphan signal without the power to block a consumer for owning files.
- New optional `-PackageRoot` parameter (body default, not a param-block default — `$PSScriptRoot`
  is empty while param defaults are evaluated under `-File`).

Verified on a live consumer: the preflight now reports all ten checks instead of dying after four;
check 5 passes across 13 package/overlay entries with no consumer file added to any manifest; and
both failure branches were exercised, not assumed — a deliberately broken `sourceTemplate` in a copy
of the manifest makes check 5 fail by name, and a target outside the client view skips the
depot-aware checks cleanly.

## [4.15.0] - 2026-08-02 — An explicit per-CL submit instruction IS the approval

### `review-and-submit`: define the one approval instead of re-asking for it

#### Changed
- **`skills/review-and-submit/SKILL.md`** (Step 7, submit-authority rule): an explicit user
  instruction naming submission for **that CL by number** — "review and submit 1970" — now counts
  as the Step 7 approval, and the protocol does **not** re-ask when the review returns GREEN with
  no preflight warning. Previously "one approval covers one CL" was silent on whether the naming
  instruction itself was that approval, so the protocol asked the user to approve the CL they had
  just named — a gate firing on the clean path, which trains people to rubber-stamp it.
- The rule still re-asks on: any non-GREEN verdict (WARNING included), any preflight failure or
  warning, a CL the user never named, scope that grew after they asked, `ready-for-human` tickets,
  and any fix applied mid-run. The HITL rule and the no-direct-submit-after-fixes rule both
  outrank this one and are unchanged.
- Nothing else moves: no standing or batch authorization, `ready-for-agent` still grants
  verification and not publish authority, goal mode is still identified only by the harness's own
  Stop-hook signal, and unattended-not-goal-mode still shelves with `GATED-SHELVED:`.

Consumers of the team baseline get the matching hard-rule-6 wording in `CLAUDE.md` / `AGENTS.md`
from their own repo (Myst: CL 1973); those two files are project-local, not templated here.

## [4.14.0] - 2026-08-02 — Submit authority reaches the triage-labels template

> A second heading dated today is deliberate, not a policy slip: `v4.13.0` is already tagged and
> released, so extending it would rewrite shipped history. The rule against same-day headings
> targets *untagged* increments.

### Carry the submit-authority rule into `triage-labels.md`

#### Added
- **`templates/common/docs/agents/triage-labels.md`**: the `ready-for-agent` lane now states
  outright that the label is a **verification** label, not a **submit authorization**. It answers
  "can the agent verify every required test case", nothing more; submitting the resulting
  changelist stays human-gated outside a `/goal` run. An agent may take a `ready-for-agent`
  ticket all the way to a reviewed, shelved changelist unattended — publishing it is a separate
  decision with a separate gate.

#### Rationale
v4.13.0 landed this rule in the `review-and-submit` skill but never carried it into the triage
docs, so the one file a triager actually reads while choosing a label still implied that
`ready-for-agent` authorized a submit. Found by a downstream `update.ps1` run: the consumer had
written the paragraph locally, and `-Mode Write` would have silently deleted it — the drift was
the package being behind, not the consumer being wrong.

#### Changed
- The paragraph's cross-reference is **"the submit gate hard rule in `CLAUDE.md`"**, not
  "hard rule 6". Rule numbering is per-consumer; a `reusable-core` template must not hard-code
  one project's ordinal. Consumers already carrying the "hard rule 6" wording will see this as
  a one-line drift on their next update.

## [4.13.0] - 2026-08-02 — Submit authority, plan mode, and always-on context

> Consolidates three same-day increments briefly numbered 5.0.0, 5.1.0 and 6.0.0. None was
> tagged or released and nothing downstream ever consumed them, so they are folded into one
> 4.x minor rather than left as two spurious majors. Removals handled automatically by
> `upgrade.ps1` are minor under the policy at the top of this file.

### Remove the UE MCP rule from the `ue` overlay

#### Removed
- **`overlays/ue/rules/unrealmcprules.md`** and its `manifest-template.json` entry
  (`.claude/rules/unrealmcprules.md`, `owner=overlay`, `ownerOverlay=ue`). The `ue` overlay
  now ships only the `.p4ignore` fragment.
- **Consumer-visible**: projects that installed the `ue` overlay lose an always-on rule
  on their next `update.ps1`. Nothing replaces it in the package — consuming projects that
  still want the guidance must carry it as project-owned content.

#### Rationale
- The rule cost ~2,151 tokens of always-on context per session (~28% of the consumer's
  always-on budget) and a large share of it duplicated context carried elsewhere: the
  deferred-tool/`ToolSearch` mechanism is stated verbatim by the harness every session, the
  tool-selection table restated the MCP tool schemas, and its blast-radius tiers documented a
  PreToolUse hook that enforced them without prose.
- Measured in the originating project before removal: MCP was 18% of tool calls but only ~8%
  of tool-result characters, so the rule was not defending a hot path.

#### Known losses (recorded deliberately, not overlooked)
- The `inspect_cdo` `SCS_Inherited` caveat (it reports the PARENT template's values, hiding
  child overrides) is no longer written down in the package.
- The leave-no-trace P4 sweep for MCP-leaked EXCLUSIVE `.uasset`/`.umap` checkouts.
- The parameter crib for observed repeat failures (`delete_assets` + `paths:[...]`, missing
  `action:`, unquoted path values, `add_variable` USTRUCT gap).
- Measured fat-read costs (`list_node_types` ~26k chars/call, `get_blueprint` ~12k).

#### Changed
- `overlays/README.md`: `ue/` description no longer advertises the rule.
- `plugins/myst-dev-kit/skills/diagnosing-bugs/UE-NOTES.md`: the binary-assets note pointed at
  the now-deleted rule; it now states the deferred-tool mechanism inline (linkcheck fix).

### Submit authority + self-directed plan mode

#### Added
- **review-and-submit**: new HARD RULE — *every submit is human-gated unless the run is
  verifiably in goal mode*. Ticket status governs **verification**, never **submit
  authority**: `ready-for-agent` answers "can the agent verify every required test case",
  not "may the agent publish to `main`". Outside goal mode no standing/batch authorization
  covers a submit; attended sessions ask per CL, unattended sessions shelve with
  `GATED-SHELVED:`. Goal mode is identified **only** by the harness's own signal — the
  session-scoped Stop-hook notice a `/goal` run injects into context, plus its
  `goal_status` attachment — never inferred from circumstance. `ready-for-human` CLs stay
  gated even inside goal mode (the existing HITL rule outranks the exemption).

#### Changed
- **auto-plan-mode**: instructs the agent to enter plan mode *itself* via `EnterPlanMode`
  rather than waiting to be asked, and corrects the stale `exit_plan_mode` tool name to
  `ExitPlanMode`. Adds a `/goal` exception: plan mode's approval gate either stalls an
  unattended run or degrades to a rubber stamp, so state the plan in the reply and proceed.
- **auto-plan-mode description de-circularised**: was *"use at the START of any non-trivial
  implementation request"* — which the model can only match after making the very judgment
  the skill exists to make, so it fired only for agents that had already decided to check.
  Now *"use before the first Edit or Write of any request"*: an observable fact rather than
  an assessment. This narrows the gap at zero always-on cost; it does not close it. A
  consumer wanting a guaranteed trigger still needs a project-owned always-loaded rule
  (see Notes).
- **pre-implementation-gate**: the HITL carve-out no longer reads as if non-HITL CLs ride
  standing authorizations. Defers to the submit-authority rule up front, then states what
  is genuinely HITL-specific — `ready-for-human` stays gated even *inside* goal mode.

#### Notes
- Consumers who want plan mode decided per request (not per skill invocation) should carry
  the policy in an always-loaded rules file rather than relying on the `auto-plan-mode`
  skill: a model-invoked skill whose trigger is "use at the start of any non-trivial
  implementation request" can only fire once the model has already made the judgment the
  skill exists to make. Rules files without a `paths:` frontmatter load unconditionally
  every session; ones with it are path-scoped.

### Retire `plan-priority`

#### Removed
- **`skills/plan-priority/`** (~120 lines). **Consumer-visible**: the skill disappears on
  the next `upgrade.ps1`. Skill count 31 → 30.

#### Rationale
- Its description — *"use BEFORE creating any new plan, roadmap, or implementation document"* —
  could only match after the model had already decided to create one, which is the decision the
  skill existed to intercept. Same circular-trigger defect fixed in `auto-plan-mode` in v5.1.0,
  but here it was the whole skill: a guardrail that cannot fire is not a guardrail.
- It had rotted: two sibling links (`DesignWorkflow.md`, `AgenticWorkflow.md`) pointed at files
  retired into the `design-workflow` / `agentic-workflow` skills and resolved to nothing.
- Its protection is now carried where the trigger is real — see below.

#### Changed
- **design-workflow** (step 1) and **agentic-workflow** (guardrails) now state the rule inline:
  search `plan_*.md` / `design_*.md` / `guide_*.md` and `.scratch/*/spec.md` for the feature,
  system, or phase name before creating a planning artifact; extend what exists rather than
  opening a second. Both skills fire exactly when someone is about to create one of these
  documents, so the guidance arrives at the moment it applies.
- **auto-plan-mode** `Related`: the dead `PlanPriority.md` link now points at those two skills.
- README skill table and the three plugin descriptions updated.

#### Known loss (recorded deliberately)
- The four-location search *order* (game docs → `.scratch/` → `~/.claude/plans/` → session
  memory) is no longer written down anywhere. The two folded-in versions name the first two
  locations only — the ones that hold shared, version-controlled artifacts. Per-user plan
  directories and session memory are now searched at the agent's discretion.

## [4.12.0] - 2026-08-01 — Reviewer prompt trim (parity-gated)

### Changed
- **architecture-reviewer** trimmed 12.4KB → ~5.5KB (description condensed to its trigger
  contract; body rewritten at ~half size with the Submission Authority section, the literal
  `Verdict:` contract, BLOCKING/WARNING/INFO categories, project context, and all three
  review axes preserved). **Adopted on finding-parity:** trimmed vs original A/B against the
  CL 1859 diff (the documented ground-truth pin-defect corpus, defects D0–D5 from CLs
  1865/1869) — trimmed found a strict superset of the original's ground-truth findings
  ({D0,D1,D2,D3,D5} vs {D0,D1,D2,D5}).
- **radical-design-critic**: description condensed the same way (routing metadata only —
  never part of the reviewing agent's prompt). **Body deliberately NOT trimmed:** the trimmed
  candidate failed the parity gate — over two runs per variant, the original found all six
  ground-truth defects (the Break-node palette-name defect in 2/2 runs) while the trimmed
  candidate missed that defect in 0/2. Per the token-cost plan's rule (never weaken a
  verification mechanism), the original body ships unchanged.
- Parity method: 6 review cells (2 agents × 2 variants + 2 re-runs), opus, identical task
  and constraints, scored against the documented defect list; full protocol and per-cell
  scores in the PR.

## [4.11.0] - 2026-08-01 — Effort barbell: reviewer tool pinning + spawn-cost guidance

### Changed
- **radical-design-critic** agent gains an explicit `tools:` frontmatter line
  (`Glob, Grep, Read, WebFetch, WebSearch, TodoWrite, Skill, Bash`). Previously it
  inherited *every* tool — including Edit/Write/Task, which its own Submission
  Authority rule forbids it to use — and every spawn paid the full toolset's schema
  tokens. Behavior contract unchanged: the agent was already required to be
  read-only; the frontmatter now enforces and prices it accordingly.
- Both reviewer agents document the **effort decision** in frontmatter: reasoning
  effort deliberately *inherits the session* (a YAML comment marks it) — they are
  judgment agents, and lowering reviewer effort to save tokens would weaken the
  team's verification mechanisms (token-cost plan r2-S3).
- **Effort-barbell guidance line** added at each subagent-spawn site in workflow
  skills (`review-and-submit` §5, `design` Step 3, `improve-codebase-architecture`
  Explore step, `codebase-design/DESIGN-IT-TWICE` Step 2): mechanical stages
  (inventories, censuses, link sweeps) run cheap (`effort: low` agents /
  `model: haiku` spawns); judgment stages (review, critique, design) stay on their
  defined model and session effort.

## [4.10.1] - 2026-07-22 — sync-build-submit: split-BuildId detection

### Fixed
- **sync-build-submit** Step 2c gains a **Split-BuildId check** — a one-line scan that
  groups every `.modules` BuildId and surfaces a drifted minority. Rationale: a build run
  *outside* this command (or a hand-swap that reaches only the engine/game manifests)
  leaves plugin manifests on a stale BuildId, and the editor then refuses to launch with
  `Plugin 'X' failed to load because module 'X' could not be found` — naming an innocent
  `EarliestPossible` plugin whose DLL is present and fine. Nothing detected that state
  after the fact; the check is documented as runnable standalone whenever the editor
  won't launch. Also records that a *partial* revert is worse than none, and that the
  repair (`p4 sync -f`) is local-state only — no `p4 edit`, nothing to submit.
- **sync-build-submit** Step 2c candidate globs widened: added
  `Engine/Binaries/Win64/*.target` (the game `.target` was listed, the engine one was
  not, so engine-target churn could leak into the reconcile), and game plugins now scan
  recursively (`Plugins/.../Binaries/...` instead of one level of `Plugins/*/`) to match
  the engine side and catch nested plugin layouts.

## [4.10.0] - 2026-07-19 — Canonical gate-compliance lines (agent CLs only)

### Changed
- **pre-implementation-gate** + **review-and-submit**: the gate's two compliance trails
  now have canonical, greppable formats — `Ticket: .scratch/<slug>/issues/<NN>-<slug>.md`
  for ticket-linked work, `Workflow: skipped (<reason>)` for user-approved skips. Both
  skills teach the exact lines. Rationale: skip notes were improvised per session (not
  auditable), and silent non-compliance was invisible.
- Consumer side (game repo): Submit-Audit client hook gains advisory check 5 — a risky
  over-threshold CL with neither line warns. **Agent-session-only by design**: the check
  lives exclusively in the agent-side client hook and must never be promoted to the
  server trigger — human teammates are fully exempt from this convention (lead decision
  2026-07-19). Precursor of the tracker issue-ref check (swap the ticket-ref pattern
  when the hosted tracker lands).
- **HITL lane fixes** (lead design review): the gate no longer blocks all-HITL features —
  its ticket check accepts `ready-for-agent` OR `ready-for-human` (HITL: agent implements,
  human gates). NEW HARD RULE closing a real gap: a CL implementing a `ready-for-human`
  ticket is NEVER covered by a standing batch/goal authorization — attended sessions ask
  per-CL; unattended sessions `p4 shelve` the CL (`HITL-SHELVED` description marker, files
  stay open locally, ticket → `resolved`) and the human's unshelve-review-submit IS the
  approval. Wired into `pre-implementation-gate` (HITL section), `review-and-submit`
  (Step 7 hard rule), and `changelist-verification` (batch-exception carve-out); `triage`
  wording aligned (`ready-for-human` = HITL work OR verification, not "needs human
  implementation").

## [4.9.0] - 2026-07-18 — Remove the redundant Docs/agents/ica/ install docs

### Removed
- **`Docs/agents/ica/` no longer installed** (4 template files + their manifest-template
  entries). Investigation showed the two *live* companion docs there were stale duplicates:
  `HTML-REPORT.md` (linked by `improve-codebase-architecture/SKILL.md`) and `DEEPENING.md`
  (linked by `codebase-design/SKILL.md`) already exist in their skill dirs upstream-style,
  where the relative `SKILL.md` links resolve — and the skill-dir copies are the maintained
  ones (they no longer reference the removed `LANGUAGE.md`). The other two, `LANGUAGE.md` and
  `INTERFACE-DESIGN.md`, were referenced by nothing. This completes the ADR-0002 "Phase 1"
  same-dir-layout reconciliation for these two skills and removes the `ica/` footprint from
  consumer installs. Consumer side: the game repo already dropped `Docs/agents/ica/` (CL 1605).

## [4.8.0] - 2026-07-18 — EOL/BOM-invariant contentHash (drift-audit portability)

### Fixed
- **Manifest `contentHash` is now EOL/BOM-invariant.** It was a raw-byte SHA-256, so a file
  hashed as LF on one machine false-reported drift after a fresh Perforce sync delivered it as
  CRLF (`LineEnd: local` on Windows) — or vice versa. `contentHash` now normalizes CRLF/CR→LF
  and strips a UTF-8 BOM before hashing, exactly as `blockHash` already did (new shared
  `Get-NormalizedContentHash` in `lib/Markers.ps1`). **All five** `contentHash` sites were
  rewired to it — the three reporters/writers `install.ps1`, `diff-installed.ps1`,
  `lib/ManifestUpdate.ps1`, plus the consumer re-baseline writer `upgrade.ps1` and the
  write-mode gate `run-skeleton-preflight.ps1` (whose validation must use the same
  normalization the writers now use). The drift audit is now indifferent to a client's
  `LineEnd` setting and OS.

### Migration (consumers)
- LF-only checkouts are unaffected (raw == normalized). A CRLF checkout (Windows/P4
  `LineEnd: local`) becomes correct after running **`upgrade.ps1 -Apply`**, which re-baselines
  every tracked `sha256` entry's `contentHash` to the normalized form; the drift audit then
  reports clean. The migration is **seamless**: during the one-time raw→normalized transition
  `upgrade.ps1` matches each file against its stored hash under **both** the normalized and the
  legacy raw scheme (`Get-RawHash`), so unchanged CRLF files are not spuriously flagged as
  customized and retired files are still removed on the migrating pass. No template re-baseline
  is needed — the package template stores no computed `contentHash` values.

## [4.7.0] - 2026-07-18 — Converge skill names to upstream (to-spec / to-tickets)

### Changed
- **BREAKING (rename)**: `to-prd` → **`to-spec`** and `to-issues` → **`to-tickets`**,
  converging with upstream mattpocock/skills. `/to-prd` and `/to-issues` no longer
  resolve — use `/to-spec` and `/to-tickets`. This reverses the 2026-07-16 reject
  decision; the motivation is **sync-path health**: `check-mattpocock-updates` compares
  upstream by file path, so a renamed skill was invisible to upstream updates.
- **Vocabulary migrated** across skills + templates to match upstream exactly:
  the document is now a **spec** ("you may know a spec as a PRD"); a work-item is a
  **ticket**. PRESERVED verbatim, as upstream keeps them: the `.scratch/<slug>/issues/`
  **directory**, "issue tracker", "issue file", `gh issue`, and every triage label
  (`ready-for-agent`, `needs-triage`, …). Only the local spec file renames
  (`PRD.md` → `spec.md`).
- Skill **bodies kept** (reworded), not re-vendored from upstream — our `to-tickets`
  still drops upstream's HITL/AFK slice-typing.
- Curation memory: the two reject entries + the setup-matt-pocock defer flipped to `adopt`.

## [4.6.2] - 2026-07-17 — Fix Markers.ps1 under PowerShell 7

### Fixed
- **scripts/lib/Markers.ps1**: `-split "`n", -1` silently returns the WHOLE string as
  one element under PowerShell 7 (negative limits split from the end since PS7;
  |-1| = 1 substring = no split), so every marker lookup threw "No BEGIN/END markers
  found" under pwsh while working under Windows PowerShell 5.1. Both sites now use
  `, 0` ("all substrings" in both editions). Found while cross-verifying game CL 1607's
  generated-block rehash. Marker fixtures: 14/14 both editions.

## [4.6.1] - 2026-07-17 — Dedup the generated-block "Key protocol" section

### Changed
- **templates (CLAUDE.md/AGENTS.md generated block)**: removed the "### Key protocol"
  subsection — it restated the "review and submit {CL}" hard rule that consumer
  baselines already carry in their Hard Rules list (both Myst files, and the skeleton
  encourages the same). One less always-loaded duplicate; the protocol itself is
  unchanged (review-and-submit skill). Consumer side: game repo CL 1607 removed the
  section from its installed blocks and refreshed marker + manifest blockHashes.

## [4.6.0] - 2026-07-17 — Retire the afk-autonomy overlay

### Removed
- **`afk-autonomy` overlay** (AFKAutoSubmit workflow, afk-status hook script, both
  reviewer lessons templates) — retired. Rationale: 2 auto-submits in its lifetime,
  no activity since 2026-06-19, and harness auto/goal modes + the review-and-submit
  protocol now cover autonomous operation with human-gated submits. Content is
  recoverable from git history; old manifests naming the overlay still install
  (it just adds nothing), matching the other retired overlays.
- AFK plumbing in plugin content: review-and-submit no longer instructs reviewers
  to load `*-afk-lessons.md`; sync-build-submit's auto-submit-on-green gate note
  replaced with "always asks"; setup-agentic-workflow no longer offers the overlay.
  Generic "AFK agent" triage vocabulary (`ready-for-agent` label semantics) is
  unchanged. Consumer side: game repo CL 1604 deleted the installed files and
  dropped the overlay from its scaffold manifest.

## [4.5.1] - 2026-07-16 — ASCII Review Record (dogfood finding)

### Fixed
- The Review Record template's em-dash (`— Verdict:`) is non-ASCII and tripped the new
  English-only Submit-Audit check on its very first live CL. Template and examples now
  use ASCII `- Verdict:`; the description standard notes the punctuation rule.
  (The audit's loose `Verdict` substring match is unaffected either way.)

## [4.5.0] - 2026-07-16 — English-only CL descriptions

### Changed
- **review-and-submit**: CL descriptions (title, body, Review Record) must be
  English/ASCII only — non-English text turns to mojibake on some P4 clients/CI/audit
  systems. Enforced advisorily by the consumer's Submit-Audit (client + server warn
  on non-ASCII; shipped separately in the game repo).

## [4.4.0] - 2026-07-16 — Spec axis for reviews (idea mined from upstream code-review)

### Changed
- **review-and-submit**: CL descriptions must link the originating PRD/issue in `## Why`
  when one exists; both reviewer prompts gain a conditional **Spec axis** — verify the
  change implements what the linked source asked for, reporting [SPEC] GAPS and SCOPE
  CREEP findings alongside quality findings. No linked source = axis skipped (behavior
  unchanged for unlinked CLs).
- **review-changes** (Codex inline reviewer): same Spec-axis step.

### Notes
- Idea adopted from mattpocock/skills' new `code-review` skill; the skill itself remains
  rejected (git-native mechanics, would duplicate the review-and-submit entry point).

## [4.3.0] - 2026-07-16 — adopt upstream `research` skill (31st)

### Added
- **`research`** (vendored verbatim from mattpocock/skills @ e9fcdf9): delegate a question
  to a background agent that reads PRIMARY sources only and captures cited findings as a
  repo markdown file. Vetted per the CONTRIBUTING gate (plan "Upstream Skill Adoptions").

### Notes
- Curation memory updated: `wayfinder` re-classified defer-with-direction (adopt as the
  discovery FRONT-END of the PRD/issues/triage pipeline when the real tracker lands —
  assessed complementary, not competing); `code-review` mined for its Spec axis
  (lands in review-and-submit via the next release).

## [4.2.0] - 2026-07-16 — upstream re-vendor: mattpocock/skills 6eeb81b -> e9fcdf9

### Changed (adopted verbatim)
- `tdd` (SKILL + tests; upstream deleted `refactoring.md` — followed), `implement`,
  `improve-codebase-architecture` (yagni scoping), `grilling`, `handoff`,
  `writing-great-skills` (SKILL + substantially reworked GLOSSARY).

### Rejected / deferred (recorded in .scratch/agentic-scaffold-rejected-upstream.json)
- **to-prd -> to-spec rename + to-issues -> to-tickets replacement: REJECTED.** The team
  governance vocabulary (PRD/issues) is baked into the consumer's committed
  PreImplementationGate rule, MustRead manual, and triage docs. Ours keep their names and
  pre-rename content; migrating the vocabulary is its own future decision.
- `setup-matt-pocock-skills` updates deferred (teaches the new vocabulary).
- New upstream skills (research, wayfinder, claude-handoff, loop-me, wizard,
  to-questionnaire, setup-ts-deep-modules, review) deferred — CONTRIBUTING gate vets
  new skills one per PR on request.
- Per-skill `agents/openai.yaml` metadata skipped (upstream's own packaging; our Codex
  delivery is the dual-manifest plugin).

### Notes
- First re-vendor since the marketplace went live; pin + license audit date moved in
  package-manifest.json. Upstream now also ships as a Claude plugin itself — noted,
  but the curated team bundle remains the delivery path.

## [4.1.0] - 2026-07-15 — contribution gate + team onboarding + Codex inline review

### Added
- **CONTRIBUTING.md** — the per-skill contribution gate: one skill per PR, author-in-consumer
  -> promote.ps1 roundtrip -> mechanical validation (plugin validate + marketplace/linkcheck
  suites) -> review checklist (trigger-strength frontmatter, genericity, provenance/attribution,
  submission-authority, advisory posture, size) -> 4-site version bump on merge.
- **SETUP.md** — team onboarding for both archetypes (standard sync-and-go, poweruser) and
  both tools; documents the manual `/plugin install myst-dev-kit@myst` path (the trust-prompt
  is version-flaky), the Codex `marketplace add` step, the settings.local opt-out, the
  empty-hook-array pitfall, and the 2-minute verify.
- **`review-changes` skill** (30th) — inline review for sessions without reviewer subagents
  (Codex): loads the same two rubric files from the plugin's `agents/` dir, categorizes
  BLOCKING/WARNING/INFO, ends with the parseable `Verdict:` line, and carries the
  submission-authority hard rule. Closes the D5 "Codex gets review as a skill" item.

### Changed
- README: Contributing section now points at CONTRIBUTING.md; Quickstart points Myst team
  members at SETUP.md.

## [4.0.0] - 2026-07-10 — role shift: plugin owns the kit, installer bootstraps the core

### BREAKING
- **The installer no longer file-copies the optional kit.** manifest-template dropped from
  152 to 25 entries: all `.claude/{skills,agents,commands,workflows}` and ALL `.Codex/*`
  consumer copies are retired (the `myst-dev-kit` plugin owns them; Codex = bible + plugin).
  The installer's remaining job is the committed-core bootstrap: bibles (generated blocks),
  `Docs/agents` + `Docs/MustRead`, `.claude/rules`, `.claude/scripts`, `.p4ignore` fragment,
  and the opt-in `afk-autonomy` overlay. Existing consumers converge via `upgrade.ps1 -Apply`
  (it deletes the retired file-copies in one reviewable changelist).
- **Workflows are now on-demand skills** (user decision: advisory-everything; the server
  Submit-Audit remains the enforcement backstop). Converted with trigger-strength
  descriptions: `review-and-submit`, `changelist-verification`, `plan-priority`,
  `pre-implementation-gate`, `agentic-workflow`, `auto-plan-mode`, `design-workflow`.
  The plugin `workflows/` dir is gone; nothing depends on a consumer `.claude/workflows/`.
- **Overlays `perforce` and `core-local` retired** (content absorbed by the plugin);
  names still parse in old manifests but install nothing.

### Changed
- **myst-dev-kit is now the full team bundle — 29 skills** (was 19): + design, roundtable,
  setup-agentic-workflow, the 7 workflow-skills; + `architecture-reviewer` agent (both
  reviewers now ship); + `sync-build-submit` command; + P4-NOTES/UE-NOTES folded into their
  skills; + `check-uproject-assoc.sh` in plugin scripts.
- Frontmatter hygiene: quoted YAML descriptions (unquoted `: ` broke parsing — validator
  errors on 8 files), added missing frontmatter to the design skill.
- `install.ps1`/`init-consumer.ps1`: core-local force-add retired.

### Notes
- `claude plugin validate` passes clean at both marketplace and plugin level.
- The stale myst-project overlay workflow copies of DocumentStandard/RawMaterialsProtection/
  ScriptStandard remain as committed-core authoring references (consumer rules are the live
  versions) — reconcile in a follow-up.

## [3.1.1] - 2026-07-10 — review/submit protocol: Review Record block + CL-creation lessons

### Changed
- **ReviewAndSubmit (perforce overlay)**: new **Step 8 "Record the Review"** — every reviewed
  CL gets a `Reviewer: <name> — Verdict: <GREEN|WARNING|BLOCKING>` line per reviewer plus
  disposition-tagged (`[FIXED]`/`[ACCEPTED]`/`[DEFERRED]`) one-liner findings appended to its
  description before submit. An installed Submit-Audit hook greps for this block, so reviewed
  CLs no longer false-warn "NO review block", and `p4 describe` shows the review outcome.
- **ReviewAndSubmit**: Step 1 CL-creation mechanics rewritten to codify field lessons — create
  named CLs via a Bash heredoc (a PowerShell pipe into `p4 change -i` prepends a UTF-8 BOM and
  fails); never `p4 change -o | p4 change -i` for a NEW CL (it sweeps every default-changelist
  file in); verify `p4 opened -c` and evict strays after creating. Safe existing-CL
  description-update path + a note that MSYS `/tmp` is invisible to native-OS tools.
- **ReviewAndSubmit**: numbered preflight (project validators + `submit-audit-warn.sh --check-cl`
  incl. EOL-flip detection); a **fast path** letting small non-risky CLs skip agent review after
  a self-review; reviewer prompts now require the literal `Verdict:` line and load the AFK
  lessons files.
- **radical-design-critic (myst-dev-kit)**: added a Submission Authority HARD RULE + required
  `Verdict:` output line, mirroring architecture-reviewer — closes a gate-parsing hole where
  AFKAutoSubmit parsed a `Verdict:` the agent never emitted.
- **AFKAutoSubmit (afk-autonomy overlay)**: live-phase auto-submit now writes the same Review
  Record block before `p4 submit`.

## [3.1.0] - 2026-07-10 — plugin marketplace: dual manifests + myst-dev-kit plugin

### Added
- **Plugin marketplace, both tools native**: `.claude-plugin/marketplace.json` (Claude Code)
  + `.agents/plugins/marketplace.json` (Codex) list ONE bundle plugin `myst-dev-kit`
  sourced from `./plugins/myst-dev-kit` in this repo. Marketplace name: `myst`
  (install as `myst-dev-kit@myst`).
- **Dual plugin manifests**: `plugins/myst-dev-kit/.claude-plugin/plugin.json` +
  `.codex-plugin/plugin.json` over the same shared content (skills/agents/commands
  auto-discovered by Claude; `skills`/`hooks` declared explicitly for Codex).
- **Codex Submit-Audit warn bridge** (`hooks/hooks.json` + `scripts/submit-audit-bridge.sh`):
  PreToolUse(Bash) hook that execs the consumer project's committed
  `.claude/scripts/submit-audit-warn.sh` — single copy of the audit logic per project.
  Under Claude Code the bridge no-ops (gates on Codex's native `PLUGIN_ROOT` env var)
  because the project's committed settings.json already registers that hook; on
  consumers without the governance core it exits silently.
  > **Corrected in 4.26.0, kept as the record:** there is no native `PLUGIN_ROOT`. The gate
  > was true on every host, so this bridge no-opped under Codex too and never ran the audit
  > for anyone from this release until 4.26.0.
- **`plugins/myst-dev-kit/LICENSE`** — MIT + mattpocock/skills attribution travels with
  plugin installs (installs copy only the plugin dir).
- **`scripts/run-marketplace-tests.ps1`** (17 checks): four-manifest consistency
  (name/version/description lockstep incl. package-manifest), source resolution, Codex
  policy fields, SKILL.md coverage, hook-bridge existence + double-fire gate, attribution.
- YAML frontmatter added to the two command files (`claude plugin validate` warning fix).

### Notes
- `claude plugin validate .` and `claude plugin validate ./plugins/myst-dev-kit` both pass clean.
- `agents/` is Claude-only (Codex ignores it); `workflows/` is inert in the plugin for both
  tools — file-copy install remains the workflows delivery path until the package role shift.
- No MCP config in the plugin: the team's `.mcp.json` is committed to Perforce as core.

## [3.0.0] - 2026-07-09 — marketplace restructure: OpenCode retired, shared-source layout

### BREAKING / Removed
- **OpenCode support retired** (tool scope is now Claude Code + Codex): deleted
  `templates/opencode/` (49 files), all `overlays/*/.opencode/` trees, the 60 `tool: opencode`
  manifest entries, the `openCode` tools flag + toolCapabilities block, and every opencode
  branch in the lifecycle scripts and test runners.
- **`run-parity-tests.ps1` retired** — the Claude/Codex/OpenCode mirror it policed no longer
  exists (see below); parity now holds by construction.
- **`run-runtime-mutable-tests.ps1` retired** — `opencode.json` was the only `runtime-mutable`
  entry. The mechanism itself (hashPolicy `runtime-mutable`) remains, documented and dormant.

### Changed
- **Mirror collapsed into ONE shared source: `plugins/myst-dev-kit/`** — `templates/claude/.claude/`
  and `templates/codex/.Codex/` were byte-identical (48/48 files); the shared
  skills/agents/commands/scripts/workflows now live once under `plugins/myst-dev-kit/`, and
  the manifest maps the same `sourceTemplate` to both `.claude/` and `.Codex/` targets
  (132 sourceTemplate values remapped, zero content changes).
- **Overlays flattened** the same way: `overlays/<name>/{skills,workflows,agents,commands,rules,scripts}/`
  with no per-tool split. Only diverging file was `perforce/ReviewAndSubmit.md` (one tool-path
  string) — wording neutralized to cover both tools.
- `templates/` now holds only the per-tool bibles (`claude/CLAUDE.md`, `codex/AGENTS.md`) and
  tool-neutral `common/docs/`.
- README / docs / overlay READMEs updated for the two-tool, shared-source reality.

### Notes
- Layout groundwork for the plugin-marketplace build-out (`.claude-plugin/marketplace.json` +
  dual plugin manifests land next). Named `plugins/myst-dev-kit/` to match the target
  Claude-plugin / Codex-plugin directory shape.
- No consumer-facing install-path changes: installed targets are still `.claude/` + `.Codex/`.

## [2.18.0] - 2026-06-23 — `/setup-agentic-workflow` interactive setup wizard

### Added
- **`setup-agentic-workflow` skill** (`core-local` overlay, all 3 tools, **user-invoked** via
  `disable-model-invocation: true`) — an interactive wizard to install or upgrade the scaffold in a
  project, modeled on upstream's `setup-matt-pocock-skills` UX (explain each term, smart defaults from
  the repo, ask one decision at a time). Flow: **explore** (detect VC / `*.uproject` / existing
  install / monorepo) → **propose tools + overlays** with rationale (auto-suggest `perforce` on
  `.p4ignore`, `ue` on `*.uproject`; never propose `myst-project`; `afk-autonomy` only on request,
  with its risk explained) → **dry-run** → **confirm + write**. It's a thin front-end over
  `setup.ps1` (fresh) / `upgrade.ps1` (existing) — the scripts own the dry-run/preflight/journal/
  Perforce-changelist safety. Closes with next steps (run `/setup-matt-pocock-skills`, fill the `ue`
  `sync-build-submit` placeholders, arm `afk-autonomy` only when wanted).
- Local-origin (`upstreamDerived: false`), homed in `core-local` (re-vendor-safe per ADR-0004),
  with a parity-matrix entry.

### Notes
- 16/16 suites pass; installs via the force-added `core-local` overlay (present in every install).
- Distinct from `setup-matt-pocock-skills` (which configures the issue tracker / triage labels /
  domain docs): this wizard installs the *toolset*; that one wires up *project conventions*.
## [2.17.0] - 2026-06-23 — `afk-autonomy` overlay (Tier 3: gated autonomous submit)

### Added
- **`afk-autonomy` overlay** (`overlays/afk-autonomy/`, Claude Code only, **opt-in — NOT
  force-added**) — autonomous auto-submit governance, generalized from a consumer and homed as a
  separately-selectable overlay so a plain install does not contain it:
  - `AFKAutoSubmit.md` — the protocol: explicit-arming authorization sources (issue / per-issue /
    per-CL / session, most-recent-explicit-wins; agent never self-promotes), a mechanical gate
    floor (path whitelist/blacklist, size cap, reviewer `Verdict` + `AFK-Verdict: SAFE|REQUIRES-HITL`),
    growing-CL handling, dry-run-first rollout, daily audit log, per-CL revert recovery, and a
    reviewer-lessons calibration loop. Cross-overlay references are prose (no file links);
    gate paths are documented as project-configurable.
  - `afk-status.sh` — SessionStart surfacer (mode + recent log + pending reverts).
  - `architecture-reviewer-afk-lessons.md` / `radical-design-critic-afk-lessons.md` — empty lesson
    templates, **`runtime-mutable`** so they accrue lessons and are never overwritten on reinstall.

### Design
- **Two independent gates, neither default-on:** the overlay must be selected at install AND armed by
  an explicit per-session phrase. **No enforcement hook** — advisory governance only (honors the
  v1.9.0 decision to drop hook-enforced auto-submit gating).
- Ties into v2.15.0: `sync-build-submit`'s auto-submit-on-green activates *only* when this overlay is
  installed and armed; the supervised default still always asks.
- Local-origin (`upstreamDerived: false`); added to both overlay enums.

### Notes
- 16/16 suites pass. Verified opt-in: a core-only install excludes the AFK files; selecting
  `afk-autonomy` installs all four.
## [2.16.0] - 2026-06-23 — Local-origin provenance + `core-local` overlay (anti-drift)

Make the upstream-vs-local boundary explicit and re-vendor-proof (see
[ADR-0004](docs/adr-0004-local-origin-provenance-and-core-local.md)).

### Added
- **`core-local` overlay** (`overlays/core-local/`) — force-added at install (like `tool-capability`)
  so it ships to every consumer, but lives under `overlays/` where a re-vendor from upstream can
  never touch it. Holds **`roundtable`** (moved out of `templates/.../skills/`, where a "stay
  faithful" sync could have clobbered it). Consumer install path is unchanged.
- **`scripts/run-provenance-tests.ps1`** — 16th suite: asserts every `upstreamDerived: true` entry
  has a license, **no local-origin skill is sourced from `templates/.../skills/`**, and `core-local`
  is well-formed + declared.
- Rejection-memory `type: "local-origin"` guard entries (`roundtable`, `update`/`promote-myst-skills`,
  `sync-build-submit`, `check-uproject-assoc.sh`) so a future upstream name-collision is flagged.

### Fixed
- **Provenance flags** (resolved the 30-entry anomaly): `update-myst-skills` + `promote-myst-skills`
  (×3 tools) were mismarked `upstreamDerived: true` → corrected to `false` (they're local commands);
  24 genuine upstream entries (`grill-with-docs`, `improve-codebase-architecture`, `tdd`, `to-issues`,
  `to-prd`, `triage`, `grill-me`, `handoff` ×3) were missing `upstreamLicense` → set to `MIT`.

### Changed
- `init-consumer.ps1` and `install.ps1` force-add `core-local`; `core-local` added to the overlays
  enum (both manifests). `install.ps1` now coerces `$TargetOverlays` to an array (fixes a scalar
  `+=` string-concat bug when a single `-Overlays` value is passed).

### Notes
- 16/16 suites pass; fresh core-only install verified to still land `roundtable`.
## [2.15.0] - 2026-06-23 — sync-build-submit: fix auto-submit footgun + Tier 2 build pipeline

### Fixed (safety / behavior change)
- **`overlays/ue/.../sync-build-submit.md` no longer auto-submits on a GREEN review without
  asking.** The previous default ran `p4 submit` automatically when the tech review came back
  green (and on INFO-only) — autonomous submission firing even in normal supervised sessions.
  **New default: always present the verdict and ask before submitting, including on GREEN.**
  Autonomous auto-submit-on-green is now a deliberately-gated capability (forthcoming
  `afk-autonomy` overlay + explicit per-session arming).

### Added (Tier 2 — promoted + generalized from a consumer)
- **Step 1b Build Gate** — skip the Editor build when a sync brought only content assets
  (known-content allowlist + fail-safes: unknown ext → build; `.ini` is not content; new
  `.uplugin`/Plugins dir → build).
- **Step 2c BuildId-only manifest-churn revert** — detect and `p4 sync -f` the `.modules/.target/
  .version` files that differ from depot *only* by a regenerated BuildId GUID (submitting them
  rewrites the team's BuildId + bloats the CL ~100×); keep manifests with real Modules-map changes.
- Heredoc changelist creation (avoids the PowerShell-BOM corruption of `p4 change -i`) and a
  machine-parseable reviewer `Verdict:` contract.

### Changed
- `sync-build-submit` is now **user-invoked** (`disable-model-invocation: true` + a prose note) so
  the agent never starts an Editor build + Perforce ops on its own.
- Generalized from hardcoded Myst paths to clear `<PLACEHOLDER>` tokens (`<DEPOT_ROOT>`,
  `<PROJECT_ROOT>`, `<GAME_DIR>`, `<UPROJECT>`, `<EDITOR_TARGET>`) + a Setup table — reusable by
  any UE source-tree + Perforce project. Project-specific worked examples were stripped.

### Notes
- 15/15 suites pass. Local-origin (not from upstream); categorized under the provenance work
  in a following change.

## [2.14.0] - 2026-06-23 — Promote consumer P4-workflow safety improvements

Generic improvements harvested from a real consumer (3-way diffed vs the install base to
separate generic value from project-specific tailoring), promoted back to the package:

### Added
- **`overlays/ue/.{claude,Codex,opencode}/scripts/check-uproject-assoc.sh`** — a UE
  source-tree + Perforce submission guard: blocks a non-empty `EngineAssociation` in the
  `.uproject` (a committed engine GUID / launcher version makes teammates hit *"Couldn't set
  association for project. Check the file is writeable."* on a read-only Perforce file).
  Generalized from the consumer's version to **discover** the `.uproject` (no hardcoded path).
  Exit 0/1/2 = OK / blocking / not-found. 3 manifest entries added.

### Changed
- **`overlays/perforce/.{claude,Codex}/workflows/ReviewAndSubmit.md`**:
  - New **"Continuous source-control sync"** rule (always `p4 edit/add/delete` a touched file
    before presenting; when unsure use the default change + `p4 reopen` later).
  - **Step 7 HARD RULE — no direct submit after fixes**: re-run the reviewer (Step 5) + a fresh
    summary before submitting; fixes can introduce new issues. (Neutral rationale; project
    incident reference dropped.)
  - **Submission Step** now runs **repo preflight validators first** (e.g. `check-uproject-assoc.sh`
    when the `ue` overlay is installed) and aborts on non-zero; reports the final CL via
    `p4 changes -m 1 -s submitted`.
- **`overlays/myst-project/.{claude,Codex,opencode}/agents/architecture-reviewer.md`** — new
  **"Submission Authority (HARD RULE)"**: the reviewer is a reviewer, not a submitter (no
  `p4 submit`/`shelve`/`git push`); the parent session owns submission. Closes a real gap —
  the package's reviewer agent ships with `Bash` + an "auto-submit on green" contract but had
  nothing forbidding it from submitting itself. Adds a parseable `Verdict:` line for gating.

### Notes
- Project-specific tailoring (Myst build pipeline, AngelScript standards, hardcoded paths) was
  deliberately NOT promoted and stays in the consumer. 15/15 suites pass; install verified.
## [2.13.2] - 2026-06-23 — `upgrade.ps1` apply-time Perforce fixes (validated on a live consumer)

Found and fixed while running the first real Perforce upgrade end-to-end:

### Fixed (upgrade.ps1)
- **EAP vs p4 stderr**: relax `$ErrorActionPreference` in the apply section. p4 writes
  informational text to stderr in normal operation (e.g. "File(s) not opened" when the
  default CL is empty); under `Stop` that aborted the apply on the *success* path.
- **CL creation BOM**: feed the change spec to `p4 change -i` via a no-BOM temp file +
  `cmd` redirection. Piping the spec directly can prepend a UTF-8 BOM that p4 rejects
  with a line-1 syntax error (the test suite never exercises real p4, so it was latent).
- **Head-rev scan covers root files**: `fstat` now scans root-level managed files
  (`.p4ignore`, `AGENTS.md`, `CLAUDE.md`, `opencode.json`) in addition to the dir-roots,
  so their `depotRevision` is re-baselined (preflight check 4). Adoption stays scoped to
  the managed scaffold roots only (never adopts unrelated root files).

### Validated
- Clean end-to-end upgrade of a real v1.0.0 Perforce + Unreal consumer: changelist with
  101 add + 42 edit + 24 delete, 11 customizations preserved (untouched, not in the CL),
  all new skills present, retired removed, **preflight 10/10**. 15/15 suites pass.
## [2.13.1] - 2026-06-23 — `upgrade.ps1`: complete Perforce preflight handling

### Fixed/Added (upgrade.ps1, Perforce mode)
- **Re-baseline `depotRevision` to current head** for every managed entry (and null for
  files not yet in the depot) so preflight **check 4** (`depotRevision == headRev`) passes —
  the P4 analog of the content-hash re-baseline.
- **ADOPT pre-existing unmanaged depot files** under scaffold roots (old-feature artifacts,
  tracked configs like `.Codex/config.toml`) as `owner=project`/`manual-only` so they're
  preserved and recognized as managed (satisfies preflight **check 5**) — never deleted.
  Depot prefix is derived via `p4 where`; head revs via `p4 fstat`.
- **Default-changelist precondition**: `-Apply` aborts cleanly (before any change) if the P4
  default changelist isn't empty (preflight **check 10**), with guidance to move WIP to a
  numbered CL — so a messy workspace never gets a half-open changelist.

### Notes
- Diagnosed against a real consumer whose P4 preflight failed checks 2/4/5/10. Filesystem
  upgrade path unchanged (15/15 suites pass).
## [2.13.0] - 2026-06-23 — `upgrade.ps1`: real upgrades for existing consumers

### Added
- **`upgrade.ps1`** — one-command upgrade of an existing consumer to the current
  package, **preserving local customizations**. Preview by default; `-Apply`
  executes (Perforce-aware: all changes land in one reviewable changelist).
  - Regenerates the manifest from the current template (into a temp dir for the
    preview, so previews never touch the consumer), so **new skills are added** and
    **retired skills are removed** — which neither `setup.ps1` (skips bootstrap when
    a manifest exists) nor `update.ps1` (never regenerates) could do.
  - Re-baselines every existing managed file's hash to its on-disk content so
    `install.ps1` preflight check 2 passes, then refreshes untouched files and marks
    **customized** files `manual-only`/`human-owned` so they're never overwritten.
    Managed blocks (`AGENTS.md`/`CLAUDE.md`/`.p4ignore`) are refreshed in place.
  - Reports the plan in five buckets: ADD / REFRESH / PRESERVE / BLOCK-REFRESH / REMOVE.
- **`scripts/run-upgrade-tests.ps1`** — 15th suite (6 tests): preview is read-only,
  customizations preserved byte-for-byte, deleted skills re-added, retired removed +
  dirs pruned, preflight clean after.

### Fixed
- `upgrade.ps1` resolves `$PackageRoot` in the body (not as a `$PSScriptRoot` param
  default, which is empty under `powershell.exe -File` on Windows PowerShell 5.1).

### Validated
- End-to-end against a copy of a real v1.0.0 Perforce + Unreal consumer: +101 added,
  76 refreshed, 11 preserved (incl. a 128-line `sync-build-submit.md` customization,
  kept byte-for-byte), 24 retired removed; preflight 0 failed afterward. 15/15 suites pass.

### Docs
- `docs/upgrade.md` rewritten around `upgrade.ps1`; README lifecycle commands + table updated.
## [2.12.1] - 2026-06-23 — Fix: restore the manifest's self-tracking entry

### Fixed
- **`manifest-template.json`** — restored the `Docs/agents/scaffold-manifest.json`
  entry that v2.11.2 removed as a "dangling source." That file **is** the installed
  manifest (generated by `init-consumer`, not copied from a template), and it must
  remain **self-listed** so Perforce **preflight check 5** ("no unmanaged scaffold
  files under `Docs/agents`") doesn't flag the manifest itself and **block an
  upgrade**. Re-added with `sourceTemplate: null` + `mergeStrategy: manual-only`
  (so it's tracked but never installer-written) and a "DO NOT remove" note — no
  dangling source, and the prior false-positive can't recur.
- `docs/upgrade.md` — corrected the installed-manifest path reference and version.

### Notes
- Caught while scoping a real consumer upgrade (the consumer's installed manifest
  lives at `Docs/agents/scaffold-manifest.json`). 14/14 suites pass.
## [2.12.0] - 2026-06-23 — Deployment/upgrade tooling for existing consumers

### Added
- **`scripts/migrate-retired-skills.ps1`** — one-time upgrade helper that removes
  the skills retired by the convergence (`zoom-out`, `caveman`, `write-a-skill`,
  and the old `diagnose` renamed to `diagnosing-bugs`) from an existing install.
  Dry-run by default; `-Apply` removes (filesystem); `-UsePerforce` emits the
  `p4 delete -c <CL> …` commands to run in a changelist. The installer doesn't
  auto-delete manifest-removed files, so this fills the upgrade gap (and avoids
  preflight check 5 blocking the write on "unmanaged scaffold files").
- **`scripts/run-migrate-tests.ps1`** — 14th test suite (7 tests) covering the
  helper: dry-run detection, Perforce command emission, apply-removal, and that
  current skills (e.g. `diagnosing-bugs`) survive.
- **`docs/upgrade.md`** — step-by-step upgrade sequence for a Perforce + Unreal
  consumer moving from an older version; README links it from the lifecycle commands.

### Verified
- Fresh install into a Perforce + Unreal consumer (`-Overlays core,perforce,ue`)
  lands all overlays (sync-build-submit, unrealmcprules, UE-NOTES; Changelist-
  Verification, ReviewAndSubmit, P4-NOTES) and all 20 skills, with retired skills
  absent — **ready to deploy fresh**.
- 14/14 suites pass.

### Removed
- **`manifest-template.json`** — dropped the dangling `Docs/agents/scaffold-manifest.json`
  entry (half-built feature, source never existed). **Zero dangling `sourceTemplate`s now.**
- **`skills/setup-myst-agentic-workflow/`** — removed the unreferenced "skeleton"
  self-install skill (superseded by `setup.ps1`); the top-level `skills/` dir is gone.

### Added / Changed
- **Bibles** (CLAUDE.md + AGENTS.md) now list all 20 core skills in both the
  directory map and the Skills table (was missing the 10 new ones; overlay
  entries were already correct, not phantom).
- **README** — complete grouped skill list (all 20) + a new **"Divergence from
  upstream (and why)"** section documenting renames/removals/skips/overlays.

### Notes
- 13/13 suites pass. Cleanup complete; CLAUDE.md/AGENTS.md skill lines stay in sync.

### Fixed
- **README** refreshed to 2.11.0 reality: version badge `v2.1.0` → `v2.11.0`;
  tests badge de-bricked; 7 dead flat skill links (`skills/<name>.md`) repointed
  to `skills/<name>/SKILL.md`; removed the `/zoom-out` row; rewrote the stale
  `v2.0.0` Status block (now describes the HEAD convergence); fixed skill/suite
  counts and the `docs/` ADR tree (adds adr-0002/0003).
- **`MustRead_agentic_workflow.md`** — dropped the removed `/zoom-out` reference.
- **Manifest dangling `sourceTemplate`s** (pre-existing) repointed to real files:
  `AutoPlanMode` (was `profiles/…`, which never existed) → `templates/…/workflows/`;
  `design` overlay (was flat `design.md`) → `design/SKILL.md`.

### Known follow-ups (flagged, not changed)
- `manifest-template.json` entry for `Docs/agents/scaffold-manifest.json` still
  points at a non-existent source — a half-built "install a manifest copy"
  feature; decide create-or-remove.
- Top-level `skills/setup-myst-agentic-workflow/` is an unreferenced "skeleton"
  self-install skill, superseded by `setup.ps1`; decide keep/update/remove.
- Bibles (CLAUDE.md/AGENTS.md) skill listings don't yet enumerate the 10 new
  core skills (overlay entries there are correct, not phantom).

### Notes
- 13/13 suites pass. Audit confirmed: no orphan remote branches; no residual
  manifest entries for removed skills.

### Changed
- **Pin bumped `b8be62f` → `6eeb81b`** in both `package-manifest.json` and
  `manifest-template.json` (`previousPinnedCommit` = `b8be62f`). This declares the
  curated convergence to upstream HEAD **complete** — every carried skill is
  verbatim-faithful to `6eeb81b`, new siblings vendored, deletions followed,
  format converged (ADR-0003), with deviations recorded in the rejection memory.
- LICENSE + README attribution updated to the new pinned commit.

### Provenance
- Adopted faithfully: diagnosing-bugs, domain-modeling, grilling, teach,
  codebase-design, writing-great-skills, setup-matt-pocock-skills, implement,
  edit-article, obsidian-vault, resolving-merge-conflicts (+perforce P4-NOTES),
  plus the converged carried skills.
- Deliberate deviations (rejection memory): skip ask-matt/prototype; defer
  decision-mapping; to-issues drops HITL/AFK slice-typing (AFK-readiness via
  triage label); resolving-merge-conflicts git base + perforce P4-NOTES overlay.
- From here, `compare-with-package.ps1` diffs against a current baseline and
  `check-mattpocock-updates.ps1` reports clean until upstream moves again.

### Notes
- 13/13 suites pass. Convergence-to-HEAD program (Phase 0 → C) complete.

### Removed (BREAKING — follow upstream's deletions)
- **`zoom-out`**, **`caveman`** — deleted (upstream removed them). `/zoom-out`
  and `/caveman` no longer ship.
- **`write-a-skill`** — removed; replaced by `writing-great-skills` (vendored
  B-1), matching upstream. `/write-a-skill` → use `/writing-great-skills`.
- 9 manifest entries + 3 parity rows dropped.

### Fixed
- **VersionControlRule residue cleared** — the 5 dangling refs left by the
  v2.4.1 deletion (ScriptStandard ×2, sync-build-submit ×2, README) re-pointed
  to the perforce overlay's ReviewAndSubmit / ChangelistVerification (plain-text,
  conditional). Link-check allow-list now **3** (only the cross-overlay
  DesignWorkflow / ChangelistVerification see-alsos remain).
- CLAUDE.md / AGENTS.md skill tables + trees pruned of the removed skills; the
  stale "command wrappers" line dropped.

### Added
- **Overlay-surfacing note** (ADR-0003 open item, option a): the bible's Skills
  section now notes that skills may ship `*-NOTES.md` addenda (e.g. UE/Perforce
  notes for `diagnosing-bugs` under the `ue` overlay) to read alongside them.

### Notes
- 13/13 suites pass (parity 184, link-check 117 resolve); install + idempotent.
- Rejection memory records zoom-out/caveman/write-a-skill as follow-deletion.

### Changed
Eight carried skills converged to upstream HEAD (`6eeb81b`), verbatim frontmatter
+ body (Claude/Codex byte-identical; OpenCode +`compatibility`):
- **triage** — + restored `AGENT-BRIEF.md` + `OUT-OF-SCOPE.md` companions;
  `/grilling`+`/domain-modeling`+`/setup-matt-pocock-skills` refs now resolve.
- **tdd** — + restored `mocking.md` / `refactoring.md` / `tests.md` companions.
- **improve-codebase-architecture** — + restored `HTML-REPORT.md`; delegates to
  `/codebase-design` (vendored B-1).
- **grill-with-docs**, **grill-me** — now upstream's stubs delegating to
  `/grilling` + `/domain-modeling` (vendored Phase A).
- **to-prd**, **handoff** — verbatim.
- **to-issues** — verbatim, which **drops the HITL/AFK slice-typing**
  (faithful-pure): AFK-readiness is carried by the triage label, as upstream does.

### Fixed
- 18 companion manifest entries + 6 parity rows. **Link-check allow-list shrank
  20 → 6** — the restored companions mean triage/tdd/ICA/grill-with-docs links
  now genuinely resolve (no longer documented drifts).

### Notes
- 13/13 suites pass (parity 187, link-check 122 resolve); install + idempotent.
- Remaining link-check allow-list (6): cross-overlay DesignWorkflow/
  ChangelistVerification, and the `write-a-skill`/`VersionControlRule` residue —
  all cleared in Phase B-3.

### Added
Seven skills vendored faithfully from upstream HEAD (`6eeb81b`), verbatim
frontmatter+body (Claude/Codex byte-identical; OpenCode +`compatibility`),
companions in-dir:
- **codebase-design** (+ DEEPENING, DESIGN-IT-TWICE) — unblocks faithful tdd/ICA.
- **setup-matt-pocock-skills** (+ domain, issue-tracker-github/gitlab/local,
  triage-labels) — unblocks faithful triage/to-issues.
- **writing-great-skills** (+ GLOSSARY) — successor to write-a-skill.
- **implement**, **edit-article**, **obsidian-vault** — adopted.
- **resolving-merge-conflicts** — git base verbatim **+ a `perforce`-overlay
  `P4-NOTES.md` companion** (Claude/Codex) adapting it to Perforce text merges.
- 47 manifest entries (45 core SPDX MIT + 2 perforce), 16 parity rows.

### Notes
- Phase B-1 of the curated convergence: dependency skills first (codebase-design
  → tdd/ICA; setup-matt-pocock-skills → triage), per principle #5.
- Rejection memory updated: only `ask-matt`/`prototype` (skip) + `decision-mapping`
  (defer) remain; zoom-out/caveman/write-a-skill flagged follow-deletion (B-3).
- 13/13 suites pass (parity 169, link-check 152); install + idempotency verified.

### Changed
- **Skill format converged to upstream verbatim** (ADR-0003). `SKILL.md` is now
  upstream's YAML frontmatter (`name`/`description`/`disable-model-invocation`/
  `argument-hint`) + body — Claude/Codex byte-identical to upstream, OpenCode
  adds only `compatibility: opencode`. The house `# H1`-as-description +
  `<command-name>` convention is **dropped** (the command name is the skill
  directory name in all three tools; `<command-name>` was never a real field).
- Re-wrapped the already-merged skills to this format: `diagnosing-bugs`,
  `domain-modeling`, `grilling`, `teach`. Converted the local-only `roundtable`
  to frontmatter (content preserved; OpenCode keeps its condensed body).
- This makes "faithful" include **format** — Claude Code now gets upstream's
  user/model-invoked split natively (answers the `disable-model-invocation`
  question), and `compare-with-package.ps1` shows clean diffs vs upstream.

### Notes
- Per-tool support verified: Claude Code honors frontmatter + invocation flags
  natively (dir = command); Codex discovery is via AGENTS.md (frontmatter is
  harmless metadata); OpenCode is frontmatter-aware via opencode.json.
- Open sub-decision (Phase B): how a `ue`-overlay companion (`diagnosing-bugs/
  UE-NOTES.md`) is surfaced now that the verbatim base carries no footer pointer.
- 13/13 suites pass; install idempotent.

### Added
- **`domain-modeling`** (engineering) — active domain-model discipline, vendored
  faithfully from upstream HEAD (`6eeb81b`) with its `CONTEXT-FORMAT.md` +
  `ADR-FORMAT.md` companions in-dir (faithful architecture). Three-way.
- **`grilling`** (productivity) — relentless plan/design interview; the upstream
  successor that `grill-me`/`grill-with-docs` delegate to at HEAD. Three-way.
- **`teach`** (productivity) — stateful multi-session teaching workspace, with
  its `MISSION-FORMAT` / `RESOURCES-FORMAT` / `LEARNING-RECORD-FORMAT` /
  `GLOSSARY-FORMAT` companions in-dir. OpenCode frontmatter keeps upstream's
  `disable-model-invocation` + `argument-hint`; Claude/Codex encode
  explicit-only via `<command-name>`. Three-way.
- 27 manifest entries (`owner=package`, `core`, SPDX MIT) + 9 parity rows.
  Companion `.md` files are byte-faithful to upstream (verbatim, no transform).

### Notes
- **Phase A** of the curated convergence-to-HEAD program: vendor the adopted
  siblings first, because Phase-B dependents (`grill-with-docs`, `grill-me`,
  `triage`) hard-bind to `domain-modeling`/`grilling` (principle #5).
- Provenance: these track upstream HEAD (`6eeb81b`), ahead of the package pin —
  deliberate per-skill sync, recorded here.
- 13/13 suites pass (parity 122, link-check 107 resolve); install lands all
  skills + companions and is idempotent.

### Added
- **Link-existence lint** `scripts/run-linkcheck-tests.ps1` (13th test suite):
  resolves every relative companion/cross-link in skills, workflows, and
  commands against the package tree; skips consumer artifacts (`CONTEXT.md`,
  `docs/adr/*`, `Docs/*`, `{{var}}`, `/src/*`, `.scratch/*`). Makes the
  dangling-reference bug class un-reshippable (principle #4). Known not-yet-
  reconciled drifts live in an `$allow` backlog (20 entries) that shrinks as
  Phase-1 re-vendors land.
- **Rejection memory** `.scratch/agentic-scaffold-rejected-upstream.json`
  (principle #6): records skill-level keep/skip/defer decisions vs upstream
  HEAD (`6eeb81b`) so future syncs don't re-litigate them — keep
  zoom-out/caveman/write-a-skill (documented reasons); skip
  ask-matt/edit-article/obsidian-vault/resolving-merge-conflicts/implement/
  prototype/decision-mapping/codebase-design; defer writing-great-skills.
  `check-mattpocock-updates.ps1` already reads this path.

### Notes
- Guardrails for the curated convergence-to-HEAD program. All 13 suites pass.

### Added
- **ADR-0002** (`docs/adr-0002-vendor-and-overlay-not-fork.md`): records the
  decision to stay current with upstream via **vendor-and-overlay**, not a git
  fork or submodule. Staying current is a *curation* problem, not a *storage*
  problem; fork/submodule can't represent our 3-tool transform and would block
  per-file curation. Base is vendored faithfully + complete; project tailoring
  lives in overlays. Documents the engine gap that `append-fragment` can't
  idempotently append to a `copy`-owned skill file (hence same-dir companions
  for skill tailoring).
- **`ue` overlay companion** `skills/diagnosing-bugs/UE-NOTES.md` (three-way:
  Claude/Codex/OpenCode) carrying the UE5/Perforce adaptation of the diagnosis
  loop (automation specs / `-ExecCmds` headless runs / `p4` bisection / editor
  HITL into `.scratch/`). Registered in `manifest-template.json` + parity matrix.

### Changed
- **`diagnose` → `diagnosing-bugs`** (skill dir, `<command-name>` / frontmatter
  `name`, manifest paths, parity IDs, CLAUDE.md/AGENTS.md tables, AgenticWorkflow
  + MustRead refs, README). **Breaking:** the command is now `/diagnosing-bugs`.
  Rationale: upstream-inherited skills track upstream naming faithfully to avoid
  drift; upstream renamed this skill to `diagnosing-bugs` at HEAD (`6eeb81b`).

### Fixed
- **`diagnosing-bugs` restored to the faithful upstream discipline** (was a
  22-line stub that amputated the whole six-phase loop). Adopted the upstream
  **HEAD (`6eeb81b`)** version faithfully — including its improvements over our
  pin (`b8be62f`): the "tighten the loop" guidance, the **red-capable completion
  criterion** for Phase 1, and **Phase 2 "Reproduce + minimise"**. Vendored its
  `scripts/hitl-loop.template.sh` companion too (closes the dangling-companion
  defect ADR-0002 targets). First worked example of the model: faithful base in
  core (Claude/Codex `<command-name>`, OpenCode frontmatter), project specifics
  in the `ue` overlay.

### Notes
- **Provenance:** `diagnosing-bugs` is the first skill synced to upstream HEAD
  (`6eeb81b`), ahead of the package pin (`b8be62f`) which stays put until a
  deliberate full sync. This is intentional per-skill faithful tracking, not
  drift.
- Prototype validating the faithful-base + overlay split before the broader
  re-vendor. All 12 test suites pass; install lands base + companion + script and
  is idempotent.

## [2.4.2] - 2026-06-20 — Restore cross-tool parity; complete v2.4.x file bookkeeping

### Fixed
- **Parity test (`run-parity-tests.ps1`) now green (89/0).** v2.3.0 and v2.4.0
  shipped new files without registering them in the parity matrix, and v2.4.1
  retired `VersionControlRule.md` without removing its matrix row. Reconciled
  the matrix with disk:
  - Added `workflow:PreImplementationGate` (three-way: Claude/Codex/OpenCode).
  - Added `workflow:AutoPlanMode` (two-way: Claude/Codex; OpenCode `$null`
    with a deviation — it targets the Claude/Codex plan-mode capability and
    OpenCode has no equivalent).
  - Added `overlay:ue/UnrealMCPRule` (three-way, per-tool layout: Claude/Codex
    `rules/unrealmcprules.md`, OpenCode `workflows/UnrealMCPRule.md`).
  - Removed the retired `overlay:perforce/VersionControlRule` row + deviation.
- **`manifest-template.json` reconciled with disk.** v2.4.1 deleted the
  `VersionControlRule.md` sources but left two dangling `files[]` entries whose
  `sourceTemplate` pointed at the deleted files (broke `compare`/`promote`
  against the real repo). Removed both. Registered the previously-unregistered
  active files so they actually install: `PreImplementationGate.md` (3 tools)
  and `unrealmcprules.md` / `UnrealMCPRule.md` (3 tools).

### Notes
- All 12 test suites pass (182 tests).
- Known follow-up (not addressed here): the two `AutoPlanMode` entries still
  carry a placeholder `sourceTemplate` under `profiles/` (a non-existent dir),
  flagged by their `tool-capability` / `capabilityProfile` design as
  "needs rewrite before packaging." Left intact pending that rewrite.

## [2.4.1] - 2026-06-01 — Refresh workspace-setup generated block

### Fixed
- `templates/claude/CLAUDE.md` and `templates/codex/AGENTS.md` workspace-setup
  block was stale: removed the dead `VersionControlRule.md` reference (that
  workflow was deleted), added `unrealmcprules.md` (rule) and
  `PreImplementationGate.md` (workflow), and updated the skills/commands
  listings to the folder-based `<name>/SKILL.md` layout (14 skills, 7 commands).

### Removed
- `overlays/perforce/.claude/workflows/VersionControlRule.md` and
  `overlays/perforce/.Codex/workflows/VersionControlRule.md` — the workflow was
  retired; deleting the overlay source stops installs from restoring it.

## [2.4.0] - 2026-05-24 — Unreal Engine MCP rule (ue overlay)

### Added
- **`unrealmcprules.md`** (Claude rules dir) / **`UnrealMCPRule.md`**
  (OpenCode workflows dir) — a new file in the `ue` overlay that fires
  when agents are about to operate on Unreal Engine assets, Blueprints,
  levels, actors, materials, or the editor. Trigger conditions: file
  extensions (`.uasset`, `.umap`), asset paths (`/Game/...`), asset
  prefixes (`BP_`/`WBP_`/`SM_`/`MI_`/`M_`/`T_`/`A_`/`NS_`/`DA_`),
  keywords ("blueprint", "actor", "level", etc.).
- The rule's core mechanism: it tells agents the
  `mcp__unreal-engine__*` tools are **deferred** in the host harness
  (Claude Code surfaces them by name; schemas aren't preloaded), and
  to call `ToolSearch` first to load the schemas before invoking. Maps
  trigger → tool → action in a table so agents reach for MCP instead
  of falling back to `Read`/`Grep` on binary `.uasset` files.

### Why
- Surfaced during a UE_Blank_Proto session where agents repeatedly fell
  back to `Read`/`Grep` on `.uasset` files (binary; output is useless)
  instead of using the MCP tools because the MCP tools were never being
  loaded into the agent's available toolset. The rule is the bridge
  between awareness ("there's an MCP for this") and capability ("load
  the schemas, then call them").

### For consumers
- Consumers using the `ue` overlay (set during `init-consumer.ps1` or
  via `update.ps1`) get this rule automatically on next install. Other
  overlays unaffected.

## [2.3.0] - 2026-05-24 — PreImplementationGate workflow + AutoPlanMode rewrite

### Added
- **`PreImplementationGate.md`** workflow (Claude + Codex + OpenCode):
  fires when an agent is about to draft a 2+ CL implementation plan
  and verifies that the project has a PRD + ready-for-agent issue(s)
  for the work. If not, the agent STOPS and offers two options:
  (a) `/to-prd` to create one, or (b) explicit deviation noted in the
  CL description. Narrowly-scoped gate; doesn't fire on small fixes.

### Changed (BEHAVIOR CHANGE — read before upgrading)
- **`AutoPlanMode.md` rewritten** and **reclassified**. Previously the
  file was treated as a per-project reference (mergeStrategy: manual-only,
  writablePolicy: report-only, ownerOverlay: tool-capability) — the
  installer never overwrote consumer customizations. With v2.3.0 the
  file is package-canonical (mergeStrategy: copy, writablePolicy:
  installer-owned, ownerOverlay: core), so `install.ps1 -Mode Write`
  WILL overwrite any consumer-local AutoPlanMode customizations.
- The content was also rewritten to replace the previous "ANY tool,
  ZERO EXCEPTIONS" rule (which was universally ignored in practice)
  with realistic "use plan mode when X / skip when Y" triggers based
  on actual practice.

### Migration note for existing consumers
If you have a local `AutoPlanMode.md` you've customized, save a copy
before running `/update-myst-skills` to v2.3.0. The installer will
overwrite it. You can re-apply your customizations after, or fork the
file as a project-local workflow with a different name.

### Why
- Surfaced during a consumer-side workflow audit (UE_Blank_Proto CLs
  1049/1050/1051) where the AutoPlanMode rule turned out to be ignored
  by every agent (including by me, the project agent). When a rule is
  universally violated it stops being a rule. The rewrite captures what
  agents actually do: plan-mode for multi-file work, skip for reads /
  single edits / lookups inside an already-planned task.
- `PreImplementationGate` is a narrow gate addressing the pattern where
  agents collapse Discussion → Implementation, skipping PRD/Issues/
  Triage. It's advisory but specific.

## [2.2.0] - 2026-05-24 — Link DesignWorkflow + AgenticWorkflow; PlanPriority dual-search

### Changed
- **`AgenticWorkflow.md`**: added a "Scope and relationship to
  DesignWorkflow" block describing three flow shapes (game-design +
  implementation / pure code / pure game design no code). When game
  design is involved, the Discussion phase is **extended** via
  `DesignWorkflow.md`; the PRD phase here references the finalized
  design doc.
- **`PlanPriority.md`**: search now covers BOTH `{{game_docs_root}}/`
  (1a, for DesignWorkflow-shape work) and `.scratch/` (1b, for
  AgenticWorkflow-shape work). Documents how 1a and 1b sequence into
  each other instead of being parallel choices — finding one but not
  the other is a signal about pipeline position, not a sign the other
  location is wrong to look in.

### Why
- The previous shape of these two workflows looked like competing
  alternatives — DesignWorkflow routed to `{{game_docs_root}}/`,
  AgenticWorkflow routed to `.scratch/`, and a user couldn't tell which
  applied. Surfaced during a consumer-side workflow audit (UE_Blank_Proto
  CLs 1049/1050/1051). Right model: they're sequential, with
  DesignWorkflow as the extended Discussion phase when game-design
  thinking is involved.
- PlanPriority used to search only `{{game_docs_root}}/`, leaving
  `.scratch/` invisible to plan discovery. Agents picked whichever they
  saw first → drift accumulated. Dual-search closes that gap.

### Note
- This release ships only the universally-applicable subset of the
  consumer-side audit. Several related improvements (a
  `PreImplementationGate.md` workflow rule, a rewritten
  `AutoPlanMode.md`, an Unreal Engine MCP rule) remain consumer-local
  pending follow-up manifest surgery to unblock their promotion.

## [2.1.1] - 2026-05-24 — Preflight tolerates pending-CL state

### Fixed
- **Preflight check 4 (depotRevision == headRev) no longer flags
  open-for-add files as drift.** When a file is staged in a pending CL
  via `p4 add` / `p4 branch` / `p4 move/add`, its headRev is `null`
  (depot doesn't know about it yet) while the manifest may already list
  it with `depotRevision=1`. Previous behavior reported this as drift
  and refused `install.ps1 -Mode Write`.
- **Preflight check 5 (no unmanaged scaffold files) no longer flags
  open-for-delete files as unmanaged.** A file removed from the manifest
  but still open-for-delete in a pending CL is intentionally being
  removed; it remains in `p4 have` until submit. Previous behavior
  reported this as unmanaged and refused write mode.

### Why
- The v2.0.0 / v2.1.0 structural CLs (45 file deletes + 28 file adds)
  could not run through `install.ps1 -Mode Write` because preflight
  rejected them — the very state preflight exists to safeguard. Both
  CLs landed via a surgical manual `p4 add`/`p4 delete` workaround that
  bypassed the installer's atomic-rename + journal-rollback. This is
  the exact case that needs the most protection, so the gate was
  defeating its own purpose.
- Distinguishing "new-in-this-CL" / "pending-delete" from real drift
  requires consulting `p4 opened`. The fix runs that query once at
  preflight start and exempts entries with the matching pending action.

### Added
- `scripts/run-pending-opens-tests.ps1` — six scenarios:
  - A. Baseline (no opens, head matches manifest) → PASS 10/10
  - B. Pending add → PASS 10/10 (was: FAIL check 4)
  - C. Pending delete → PASS 10/10 (was: FAIL check 5)
  - D. Mixed structural CL → PASS 10/10
  - E. Real drift (no opens) → FAIL check 4 (no false negative)
  - F. Real unmanaged (no opens) → FAIL check 5 (no false negative)
- `scripts/fake-p4.ps1` — test-only p4 shim that seeds info / opened /
  have / fstat output via environment variables. Prepended to PATH for
  the duration of each test; never touches the live depot.

### Note
- The exemptions are scoped: only `add`/`branch`/`move/add` skip check
  4, and only `delete`/`move/delete` skip check 5. `edit` opens are
  unaffected (an edited file still has a real headRev that must match
  the manifest's depotRevision).

## [2.1.0] - 2026-05-23 — Match upstream skill structure: `<name>/SKILL.md`

### Changed (structural)
- **All skills restructured from flat `<name>.md` to subdirectory
  `<name>/SKILL.md`** to match upstream mattpocock/skills canonical
  format (referenced in their `.claude-plugin/plugin.json`).
- 26 Claude + Codex template files moved:
  - `templates/claude/.claude/skills/<name>.md` →
    `templates/claude/.claude/skills/<name>/SKILL.md`
  - `templates/codex/.Codex/skills/<name>.md` →
    `templates/codex/.Codex/skills/<name>/SKILL.md`
- 2 myst-project overlay files moved too:
  - `overlays/myst-project/.claude/skills/design.md` →
    `overlays/myst-project/.claude/skills/design/SKILL.md`
  - `overlays/myst-project/.Codex/skills/design.md` →
    `overlays/myst-project/.Codex/skills/design/SKILL.md`
- OpenCode was already in subdir form (`templates/opencode/.opencode/
  skills/<name>/SKILL.md`); no change for that tool.
- 28 manifest entries updated: `path` + `sourceTemplate` rewrite.
- Parity matrix updated to expect the new paths.
- 4 test paths updated in `run-init-consumer-tests.ps1` and
  `run-wrapper-tests.ps1` (referenced the old `diagnose.md` location).

### Why
- User reported `/handoff` wasn't visible in Claude Code. Upstream
  installs skills to `~/.claude/skills/<name>/SKILL.md` (subdir per
  skill, with a SKILL.md inside). Our package was writing
  `.claude/skills/<name>.md` flat — Claude Code's skill discovery
  expects the subdir form for the YAML-frontmatter style used by
  upstream's recent skills.
- Now the three tools align with each other (all use subdir form) and
  with upstream's installer pattern, so future upstream syncs are
  simpler (no format translation step).

### Note on slash commands
- Skills (in `.claude/skills/<name>/SKILL.md`) are invoked via the
  Skill tool / natural language ("use the handoff skill"). They do
  NOT appear in Claude Code's `/` dropdown.
- The `/` dropdown only shows files in `.claude/commands/`. Our 2
  slash commands (`/update-myst-skills`, `/promote-myst-skills`) and
  the `sync-build-submit` UE overlay command live there.
- If you want a productivity skill (handoff, caveman, etc.) to appear
  in `/`, that would require creating a `.claude/commands/<name>.md`
  wrapper — not done in v2.1.0; can be added if real demand surfaces.

Tests: 184/184 across 12 suites (no test count change; just paths
updated in 4 test files).

## [2.0.1] - 2026-05-23 — install.ps1 fixes (surfaced during v2.0.0 live install)

### Fixed
- **`scripts/run-skeleton-preflight.ps1` P4HeadRev**: was crashing on
  `p4 fstat` when target file didn't exist in depot (e.g., files staged
  for `p4 add` but not yet submitted). `$ErrorActionPreference='Stop'` +
  native command non-zero exit promoted to a terminating error.
  Wrapped the fstat call in try/catch with local
  `$ErrorActionPreference='Continue'`; null is now returned correctly
  for missing/unknowable head revs.
- **`scripts/install.ps1` Update-ManifestForChanges scope**: the
  scriptblock callback passed to `Complete-JournalCommit` ran in a
  scope where `Update-ManifestForChanges` (dot-sourced into install.ps1's
  script scope) wasn't visible. The new fix dot-sources
  `lib/ManifestUpdate.ps1` at the call site inside the scriptblock,
  guaranteeing the function is bound regardless of caller scope.

### Why
- Both bugs surfaced during the v2.0.0 live install against
  UE_Blank_Proto -- the first end-to-end run of `update.ps1` against
  a real Perforce consumer with new files being added (not just
  edited). The fixture tests + previous installs only exercised edits
  on existing files; new-file paths weren't covered.

### Not changed
- Same content, same skills, same parity tests. Only install.ps1 +
  preflight script behavior. 184/184 tests still pass.

## [2.0.0] - 2026-05-23 — Full upstream sync (skill philosophy shift)

### MAJOR: Philosophy shift

v1.x shipped **minimal pointer skills** — 20-30 line entry files that
mostly said "read CONTEXT.md, follow project patterns." That was a
deliberate adaptation when we extracted the package at upstream commit
`e74f0061`. The assumption was that agents would faithfully read
CONTEXT.md + domain.md + ADRs for context.

v2.0.0 adopts upstream's **rich instruction set** approach. Each skill
is now a complete, self-contained instruction set (80-150 lines) that
doesn't depend on the agent reading sibling docs to produce good output.
More resilient to weaker models, more explicit about process and
vocabulary, more aligned with upstream maintenance going forward.

### Added (4 new productivity skills)
- **`/caveman`** — Ultra-compressed communication mode. Cuts token usage
  ~75% by dropping filler while keeping technical accuracy.
- **`/grill-me`** — Interview the user relentlessly about a plan or design
  until each branch of the decision tree resolves. Lighter than
  `/grill-with-docs` (no documentation updates).
- **`/handoff`** — Compact the current conversation into a handoff doc
  so another agent can continue the work. Useful for context-limit
  scenarios and agent-to-agent transitions.
- **`/write-a-skill`** — Create new skills with proper structure,
  progressive disclosure, bundled resources.

Each shipped in 3 tool formats (Claude flat `.md`, Codex flat `.md`,
OpenCode subdir `SKILL.md`). 12 new manifest entries, 4 new parity matrix
rows (3-way parity).

### Changed (8 engineering skills upgraded)
All replaced with their upstream rich versions:
- `/diagnose` (22 → 117 lines): full reproduce → minimise → hypothesise
  → fix process
- `/grill-with-docs` (23 → 88): full grilling protocol with
  CONTEXT.md/ADR update mechanics; references new
  `Docs/agents/grill-with-docs-context-format.md`
- `/improve-codebase-architecture` (21 → 81 + 4 sibling reference files):
  full Glossary (Module/Interface/Depth/Seam/Adapter/Leverage/Locality),
  4-step Process, HTML report mechanism with Tailwind+Mermaid CDN
- `/tdd` (22 → 109): full red-green-refactor loop with good-vs-bad
  test discussion
- `/to-issues` (26 → 83): vertical-slice issue breakdown protocol
- `/to-prd` (24 → 76): PRD template + synthesis-vs-interview rules
- `/triage` (31 → 103): state-machine triage with role conventions,
  needs-info templates, agent-brief format
- `/zoom-out` (20 → 7): upstream is much smaller; we replaced our
  expanded version with theirs. **This is the one case where we lost
  content**; recoverable from git history if needed.

### Added (5 reference files)
Shared by all tools via `templates/common/docs/agents/`:
- `ica/LANGUAGE.md` — full ICA vocabulary definitions
- `ica/DEEPENING.md` — refactoring patterns (shallow → deep)
- `ica/INTERFACE-DESIGN.md` — interface design guidance
- `ica/HTML-REPORT.md` — HTML output format spec (Tailwind+Mermaid)
- `grill-with-docs-context-format.md` — CONTEXT.md template
  reference (upstream trimmed at commit `e7df78b`)

### Changed (upstream tracking)
- `package-manifest.json`: `upstream.mattpocockSkills.pinnedCommit`
  bumped from `e74f0061` to `b8be62f`. Records the new baseline for
  future `check-mattpocock-updates.ps1` runs.
- `manifest-template.json`: same bump for installed consumer alignment.

### What stayed
- Our 2 workflows (`AgenticWorkflow.md`, `PlanPriority.md`) — package-
  specific, not from upstream.
- All overlay content (`perforce`, `ue`, `myst-project`) — package-
  specific.
- All lifecycle scripts (`setup.ps1`, `update.ps1`, `promote.ps1`) and
  the manifest schema — package-specific.
- The 2 slash commands (`/update-myst-skills`, `/promote-myst-skills`)
  — package-specific.

### Migration notes for v1.x consumers
- `update.ps1` will land all the new content. Expect a large CL.
- Skill outputs will be noticeably more structured going forward
  (HTML reports for ICA, explicit process steps, vocabulary discipline).
- Custom adaptations made to v1.x skill content will be overwritten.
  If you'd customized any of the 8 upgraded skills, the changes are
  gone — capture them as PRDs / ADRs in your project before updating.

### Why a major bump
This is a deliberate philosophy switch. v1.x ships minimal pointers;
v2.0 ships rich instruction sets. Same skill names, same slash commands,
but the agent-facing content is 5x larger and more directive. Anyone
who pinned v1.x for content stability should NOT auto-update to v2.0.

Tests: 184/184 across 12 suites (was 172/172 in v1.9.2). 12 new parity
rows.

## [1.9.2] - 2026-05-23 — Cross-tool parity audit + automated drift detection

### Added
- **`scripts/run-parity-tests.ps1`** — verifies cross-tool parity via an
  explicit matrix listing each logical item and where it should live in
  each tool's template dir (Claude / Codex / OpenCode). Documented
  deviations are allow-listed with a one-line justification each.
  Unknown files in tool dirs (not in matrix, not deviation) fail.
- **`templates/opencode/.opencode/workflows/PlanPriority.md`** — was
  missing from OpenCode while Claude + Codex had it. Generic rule
  (don't write new plans before searching existing) that applies to
  OpenCode too. Added; manifest entry added to `manifest-template.json`.

### Documented (parity matrix + deviations)
- **3-way parity**: 9 skills, 2 workflows (AgenticWorkflow, PlanPriority),
  1 agent (radical-design-critic), 2 slash commands (update-myst-skills,
  promote-myst-skills), UE overlay's sync-build-submit command,
  myst-project's design skill + architecture-reviewer agent.
- **2-way parity (Claude + Codex, OpenCode opts out)**: perforce
  overlay workflows (ChangelistVerification, ReviewAndSubmit,
  VersionControlRule), myst-project workflows (Design/Document/Script/
  RawMaterialsProtection), angelscriptrules.
- **Tool-specific**: CLAUDE.md (Claude bible), AGENTS.md (Codex+OpenCode
  share at consumer root), OpenCode-only convenience commands
  (design, roundtable wrappers around the same-name skills).

### Why
- User asked: "are we synced between Claude, Codex and Opencode?
  If not make sure they are synced and will keep synced in the future."
- Audit found: recent v1.9.1 changes synced correctly across tools that
  had each file. But `PlanPriority.md` was missing in OpenCode -- a
  silent unintended drift never previously detected.
- The fix: explicit matrix-based parity test that makes the cross-tool
  layout legible. Future drift either fits the matrix (and passes), or
  needs an explicit deviation entry (forcing the maintainer to justify
  the asymmetry).

Tests: 172/172 across 12 suites (was 101/101 in v1.9.1; +71 parity tests).

## [1.9.1] - 2026-05-23 — Clarify .scratch/ is version-controlled (docs-only)

### Changed
- `templates/common/docs/agents/issue-tracker.md`: title renamed
  "Issue tracker: Local markdown" -> "Issue tracker: Repo markdown".
  Added an explicit "Version-control policy" section that states
  files under `.scratch/<feature-slug>/` **are version-controlled** and
  should be submitted with their related work. Distinguishes from
  genuinely local-only state (e.g., `.claude/settings.local.json`).
- `templates/{claude,codex,opencode}/.{claude,Codex,opencode}/skills/triage*`:
  description "Move local markdown issues" -> "Move issues" with an
  explicit pointer to the VC policy.
- `templates/claude/CLAUDE.md` + `templates/codex/AGENTS.md`: slash-
  command reference table line for `/triage` no longer calls the issues
  "local markdown"; clarifies they're version-controlled under
  `.scratch/`.
- `templates/opencode/.opencode/skills/to-prd/SKILL.md`: description
  "local markdown issue tracker" -> "in-repo issue tracker
  (version-controlled markdown under .scratch/)".

### Why
- User report: agents reading "local markdown" in the issue-tracker doc
  and triage skill descriptions get confused about whether `.scratch/`
  files should be submitted to Perforce. Actual practice across 15+
  CLs in the live consumer is to submit them; the word "local" in the
  framework docs read as the opposite.
- The framing "Local markdown" was originally meant in the sense
  "issues live as files in the repo rather than a remote tracker like
  Jira" -- but "local" colloquially means "not version-controlled" to
  most readers, including LLMs. Renaming + adding an explicit VC policy
  removes the ambiguity.

### Not changed
- No code, scripts, manifest schema, or templates beyond the doc-text
  edits.
- The `.scratch/` directory convention itself stays the same.
- Tests: still 101/101 across 11 suites.

## [1.9.0] - 2026-05-23 — Remove strict mode + powermode (course correction)

### Removed
- `enable-strict-mode.ps1` (was the v1.8.0 entry point)
- `enable-powermode.ps1` + `disable-powermode.ps1` (v1.8.1 batch-approval
  bypass)
- `templates/claude/.claude/scripts/hooks/block-unapproved-submit.ps1`
- `templates/claude/.claude/scripts/hooks/cleanup-approved-cl.ps1`
- `scripts/run-strict-mode-tests.ps1` (20 tests covering the removed
  feature)
- 2 hook entries in `manifest-template.json` (consumers re-installing will
  no longer pull the hook scripts)
- README sections on strict mode + powermode
- "Strict-mode hook" + "Powermode" sections in
  `ChangelistVerification.md` (perforce overlay, both Claude + Codex);
  replaced with a brief "Implementation note" linking this CHANGELOG entry

### Why
- v1.8.0 (strict mode) and v1.8.1 (powermode) were built in response to a
  user report that agents drift "from time to time" from the CL-by-CL
  HARD RULE. The mechanism was a Claude Code PreToolUse hook that blocked
  `p4 submit -c <N>` unless an approval marker file was present.
- On honest review: cost-vs-benefit was bad. Strict mode adds 3+ round-
  trips per CL (ask → approve → marker → submit) for every submit, to
  prevent ~1 wrong submit per N sessions. Powermode is a second system
  that bypasses the first system — classic over-engineering smell
  (workaround-for-the-workaround).
- Lighter alternatives that achieve ~80% of the value at ~10% of the
  complexity:
  1. Tighter workflow markdown with clearer "STOP AND ASK" language
  2. UserPromptSubmit hook that injects a 1-line reminder of active
     workflow rules every turn (no blocking; keeps rules visible)
  3. Relying on the user to interrupt the agent ("no, show me first")
- The CL-by-CL rule stays in `ChangelistVerification.md` as advisory
  guidance. It was always advisory by default; v1.9.0 just removes the
  hook layer that tried to enforce it.

### Migration for v1.8.x consumers
1. Run `enable-strict-mode.ps1 -Disable -Yes` to remove the hook wiring
   from `.claude/settings.local.json` (this script still works for
   removal even after v1.9.0 ships, until you `git pull` the package —
   keep a copy if needed).
2. After updating to v1.9.0, the hook script files in
   `.claude/scripts/hooks/` become orphan-but-tracked. Delete them
   manually (or `p4 delete` for Perforce consumers). They're no longer
   in the v1.9.0 manifest.
3. The `.claude/settings.local.json` PreToolUse + PostToolUse blocks
   referencing the now-deleted scripts will cause Claude Code to log
   "hook command not found" warnings. Remove those blocks manually or
   reset the file.

### What stays
- All other v1.x features intact: runtime-mutable hashPolicy (v1.7.0),
  init-consumer + setup/update/promote lifecycle (v1.1.0-v1.4.x),
  overlay split (v1.2.0), slash commands (v1.6.0), etc.

Tests: 101/101 across 11 suites (was 121/121 in v1.8.1; the 20 strict-mode
+ powermode test cases removed with the feature, returning to the v1.7.0
test surface plus the wrapper + init-consumer additions made since).

## [1.8.1] - 2026-05-23 — Powermode (batch-approval bypass for autonomous work)

### Added
- **Powermode** — time + count-bounded bypass for the per-CL approval gate.
  Designed for autonomous `/goal`-driven multi-CL work where the per-CL
  beat is friction without value (bugfix sprints, doc cleanups, bulk
  refactors).
- **`enable-powermode.ps1`** (top-level): writes
  `.scratch/.powermode.marker` with `submitsRemaining`, `expiresAt`,
  `reason`. Defaults: 5 submits / 60 minutes. Validates bounds (caps at
  100 submits / 8 hours, warns if exceeded). Supports `-Status` mode.
- **`disable-powermode.ps1`** (top-level): removes the marker. Idempotent.
- **Hook update**: `block-unapproved-submit.ps1` now checks powermode
  first. If active and within both limits, allows + decrements counter
  + writes back. Either limit tripping (count -> 0, or now >= expiresAt)
  deletes the marker. Per-CL approval gate remains as the fallback.
- **Visibility**: hook prints
  `POWERMODE: allowing submit of CL N (remaining: M; expires: T)` to
  stderr on each use, so it's not silent in the agent's context.

### Changed
- `ChangelistVerification.md` (perforce overlay, both Claude + Codex):
  added "Powermode (v1.8.1)" section documenting expected agent behavior
  when powermode is active (still surface CL contents; honor the user's
  trust; pause + ask if user said "do all" but powermode isn't on).
- `block-unapproved-submit.ps1`, `cleanup-approved-cl.ps1`: rename
  `$event` -> `$evt` (PowerShell automatic-variable lint warning).

### Why
- v1.8.0's per-CL gate is the right friction for normal sessions but
  wrong for `/goal`-driven autonomous work. User reported:
  "we also need a powermode that can directly commit multiple CLs
  without a user's approval, like bugfixing etc."
- Picked count + time both (vs. count only / time only / no-code-toggle)
  because both limits as belt-and-suspenders rule out the failure mode
  of forgetting to disable. Either trip = back to strict.

Tests: 121/121 across 12 suites (was 113/113 in v1.8.0). Strict-mode
suite grew from 12 to 20 tests covering: enable writes marker, allows +
decrements, exhaustion deletes marker, blocks after exhaustion, expired
marker ignored + cleaned up, disable removes marker, status reports
correctly.

## [1.8.0] - 2026-05-23 — Strict mode (CL-by-CL hook enforcement)

### Added
- **`enable-strict-mode.ps1`** top-level script: opt-in installer for
  Claude Code hooks that enforce workflow rules at the tool level (not
  just advisory). Writes/merges the hook wiring into
  `.claude/settings.local.json` (per-machine, not VC-tracked).
  Idempotent re-runs. `-Disable` removes the hooks.
- **`templates/claude/.claude/scripts/hooks/block-unapproved-submit.ps1`**:
  PreToolUse hook that blocks `p4 submit -c <N>` unless
  `.scratch/.approved-cl-<N>.marker` is present at the project root.
  Exit 2 with explanatory message to the agent on block.
- **`templates/claude/.claude/scripts/hooks/cleanup-approved-cl.ps1`**:
  PostToolUse companion. Deletes the marker file after submit so each
  approval is one-shot (can't be reused).
- `scripts/run-strict-mode-tests.ps1`: 12-test suite covering hook
  ignores non-Bash, ignores non-submit Bash, blocks unapproved submit
  with correct exit 2 + message, allows when marker present, cleanup
  removes marker, enable-strict-mode writes valid settings.local.json,
  idempotent re-runs, -Disable removes hooks.

### Changed
- `overlays/perforce/.claude/workflows/ChangelistVerification.md` (and
  Codex mirror): added "Strict-mode hook (when enabled)" section
  documenting the marker dance — what the agent should do when blocked
  (surface CL, ask user, create marker, retry submit).
- `manifest-template.json`: 2 new entries for the hook scripts (claude-only
  for now; OpenCode/Codex don't have an equivalent PreToolUse mechanism).

### Why
- Workflows were advisory: the agent reads `.claude/workflows/*.md` at
  session start, but nothing prevents bypass. Real-world agents drift —
  they submit without asking, batch CLs together, skip the review step.
  User reports this happens "from time to time."
- Claude Code hooks are the actual enforcement layer. The package now
  uses them for the single most-violated rule (CL-by-CL). Future
  versions may add hooks for the other rules.
- Opt-in via a separate script (not auto-enabled in setup.ps1) because
  hooks live in `.claude/settings.local.json` which is per-machine, not
  shared across the team. Some users may not want strict enforcement.

### What it doesn't enforce yet
- `RawMaterialsProtection` (Docs/_Raw read-only) — could add a PreToolUse
  hook on Edit/Write blocking paths under that dir. Not in v1.8.0.
- `ReviewAndSubmit` (must invoke reviewer agent before submit) — harder
  to enforce mechanically; defer.
- `AutoPlanMode` for non-trivial tasks — Claude Code has built-in plan
  mode; can't easily force via hook. Future work.

Tests: 113/113 across 12 suites (was 101/101 in v1.7.0).

## [1.7.0] - 2026-05-22 — `runtime-mutable` hashPolicy fixes opencode.json drift

### Added
- **`runtime-mutable` hashPolicy** for files tools mutate at runtime
  (canonical case: OpenCode's `opencode.json` permission block, which the
  tool rewrites in-session when a user grants a permission). Schema
  documented in `package-manifest.json`'s `hashScopeRule.runtime-mutable`.
- Semantics:
  - **Install seeds** the file from the template on first install
    (target absent).
  - **Subsequent installs never overwrite** — preserves runtime state.
  - **Preflight check 2 skips** entries with this policy — no false-positive
    hash mismatch.
  - **Compare reports `runtime-mutable`** outcome (its own bucket, not
    `downstream-edit`); does not count toward conflicts.
- `scripts/run-runtime-mutable-tests.ps1`: 6-test suite covering bootstrap
  manifest carries the policy, first install seeds, runtime mutation
  preserved across second install, compare outcome is `runtime-mutable`
  (not `downstream-edit`), preflight check 2 passes.

### Changed
- `manifest-template.json`: `opencode.json` entry now has
  `hashPolicy: "runtime-mutable"` (was `sha256`).
- `scripts/install.ps1`:
  - Dry-run analysis: reports `runtime-mutable` (file present) or
    `seed-runtime-mutable` (file absent) instead of `clean` / `DRIFT`.
  - Write phase: skip overwrite if `hashPolicy='runtime-mutable'` and file
    exists; first-install seeding still happens.
- `scripts/run-skeleton-preflight.ps1`: check 2 skips `runtime-mutable`
  entries (added to the existing skip list alongside `localOnly` and
  `self-excluded`).
- `scripts/compare-with-package.ps1`: short-circuits to
  `Outcome=runtime-mutable` for entries with the policy, bypassing the
  hash comparison.
- README: gotcha #1 (`opencode.json +w` pitfall) updated to "Resolved in
  v1.7.0" with a new "What runtime-mutable means" section.
- docs/perforce-consumer.md §5: rewritten to document the policy as the
  resolution path, plus the remaining manual-edit case.

### Why
- The `opencode.json` `+w` always-writable pitfall was the longest-running
  documented limitation (since v1.0). Preflight check 2 failed every time;
  compare reported perpetual `downstream-edit`. The friction blocked
  `update.ps1` in real-world use cases.
- Option C from the design discussion (vs. mark localOnly, mark manual-only,
  or JSON-aware partial hashing) was picked: cheapest, most extensible to
  future runtime-mutated files, keeps the entry visible in reports.

Tests: 101/101 across 11 suites (was 95/95 in v1.6.0).

## [1.6.0] - 2026-05-22 — Rename slash commands to avoid collisions

### Changed (BREAKING for v1.5.0 consumers)
- `/update`  → `/update-myst-skills`
- `/promote` → `/promote-myst-skills`

Renamed for collision-avoidance: `/update` and `/promote` are dangerously
generic — every tool ecosystem has those words attached to built-ins or
adjacent packages, and users couldn't tell at a glance which scaffold
the command would touch.

The new names follow the [mattpocock/skills](https://github.com/mattpocock/skills)
convention of suffixing with the package identifier (compare their
`/setup-matt-pocock-skills`). Verbose but unambiguous.

Internal references updated:
- 6 command files renamed (2 commands × 3 tools).
- `manifest-template.json`: 6 entries' `path` and `sourceTemplate` updated.
- Command bodies updated (their cross-references to each other).
- README slash-command reference table updated.

### Migration for v1.5.0 consumers
If you installed v1.5.0 between today and a few minutes ago and want to
upgrade cleanly:

1. Run `update.ps1` against your consumer. It picks up the renamed entries
   and writes the new files alongside the old.
2. The old `update.md` / `promote.md` files become orphan-but-tracked in
   your `.claude/commands/` etc. — delete them manually (or `p4 delete`
   if Perforce-tracked). They aren't in the v1.6.0 manifest.

Realistically nobody had v1.5.0 in production yet (it shipped <1 hour ago),
so this rename is effectively a free do-over.

Tests: still 95/95 across 10 suites.

## [1.5.0] - 2026-05-22 — `/update` and `/promote` slash commands

### Added
- Slash commands `/update` and `/promote` installed into every consumer
  across all three tools (`.claude/commands/`, `.Codex/commands/`,
  `.opencode/commands/`). Agent instructions for how to drive
  `update.ps1` / `promote.ps1` from inside Claude Code, Codex, or OpenCode.
- 6 new entries in `manifest-template.json` (2 commands × 3 tools), so
  fresh consumers get them automatically via `setup.ps1`. Existing
  consumers receive them on next `update.ps1` run.

### Why
- v1.4.0 added the PowerShell wrappers (`setup.ps1` / `update.ps1` /
  `promote.ps1`) but they only worked when a human typed them at a
  terminal. Inside an agent context, the user had to either drop to a
  shell or instruct the agent step-by-step.
- The slash commands give the agent a direct invocation path: when the
  user says "sync the scaffold" or "promote this upstream", the agent
  reads the command file and runs the right script with the right flags.

### Slash-command behavior
- `/update`: agent finds the package clone (via `package.source` in the
  consumer manifest), runs `update.ps1 -TargetRoot <this>`, surfaces the
  dry-run output, waits for user confirmation, applies the result. Maps
  preflight failure modes to actionable next steps.
- `/promote`: agent identifies modified files (via `p4 opened` /
  `git status` / asking the user), runs `promote.ps1 -TargetRoot <this>
  -Paths <files>`, surfaces the dry-run + roundtrip-verify result, waits
  for confirmation, then walks the user through the git commit/push/PR
  steps in the package.

Tests: still 95/95 across 10 suites (no test surface affected; the
slash commands are markdown instructions, not script logic).

## [1.4.1] - 2026-05-22 — Comprehensive intro README

### Changed
- `README.md` fully rewritten as a proper landing page, modelled on
  [mattpocock/skills](https://github.com/mattpocock/skills): hero with
  status badges, 60-second quickstart, six pain points (with the skills/
  scripts that solve each), categorized reference (lifecycle commands,
  skills, workflows, agents, overlays), FAQ, and known gotchas.
- Pain-points section names the actual problems this package solves:
  three-CLI drift, Bible-file corruption risk, half-installed scaffolds,
  drift detection, stuck improvements, Perforce + multi-developer chaos.

### Why
- v1.0–1.4 had a thin README that listed features. New adopters had no
  fast way to decide whether the package solved their problem.
- The mattpocock/skills README is a strong reference for this category
  of repo. Adopting that structure makes the package more discoverable
  for anyone arriving via the upstream-skills ecosystem.

Docs-only release. No code, scripts, manifest, or templates changed.

## [1.4.0] - 2026-05-22 — One-command update + promote (lifecycle complete)

### Added
- `update.ps1` at repo root: one-command upstream sync. Runs `git pull` (skip
  with `-NoPull`), runs `compare-with-package` (aborts on conflicts), dry-runs
  install, prompts (or `-Yes`), writes via `InstallJournal`. Auto-wraps in
  `-UsePerforce -Changelist new` when the consumer's manifest declares
  `versionControl='perforce'`. Tools and overlays are read from the consumer's
  manifest — no flag duplication.
- `promote.ps1` at repo root: one-command promotion of local improvements
  back to the package. Auto-infers classification per path from the
  consumer's manifest (`owner=package,overlay=core` → `reusable-core`;
  `overlay=perforce` → `perforce-overlay`; etc.). Dry-run + confirm + write.
  Explicit `-Classification` for files not yet in the manifest.
- `scripts/run-wrapper-tests.ps1`: 9-test suite covering both wrappers —
  no-op update, manifest-derived flags, classification inference, error
  on un-inferable paths, explicit-classification path.

### Changed
- `docs/install.md` sections 2-4 rewritten to lead with the one-command
  paths (`setup.ps1`, `update.ps1`, `promote.ps1`). The step-by-step
  scripts are still documented as "advanced" paths for CI integration and
  debugging — they were the only docs in v1.0/v1.1, so the rewrite resolves
  a long-standing inconsistency with the README.
- README now lists all three lifecycle commands together: setup / update /
  promote. The package's user-facing surface is exactly these three scripts
  for the common case.

Tests: 95/95 across 10 suites (was 86/86 in v1.3.0).

## [1.3.0] - 2026-05-22 — Provenance honesty

### Changed
- `README.md` adds a **Provenance** section acknowledging the package was
  extracted from a single project (`Myst_Proto`). The MIT license, generic
  core, and reusable scripts stand; the `myst-` prefix is honest about
  origin, not aspirational marketing.
- `overlays/myst-project/README.md` (new) clearly labels the overlay as a
  reference example: **adopters should not install it** unless they are
  the Myst_Proto project. Documents exactly which files are Myst-only and
  shows how to write your own project-specific overlay.

### Why
- Public MIT repo + name containing `myst-` + an `overlays/myst-project/`
  directory was an intellectually inconsistent presentation. The package
  claimed to be generic; the contents said otherwise.
- Two paths to resolve: rewrite the content to be truly generic
  (premature without a second consumer's requirements to design against),
  or be honest about provenance. v1.3.0 picks honesty.
- A future v2.0 may extract `overlays/myst-project/` to a separate repo
  once a second project adopts the package and provides real evidence
  about what's portable vs Myst-specific.

### Not changed
- No code, scripts, manifest, or templates touched.
- `setup.ps1` auto-detection already never picks `myst-project` — adopters
  have to opt in explicitly.
- 86/86 tests still green.

## [1.2.0] - 2026-05-22 — Overlay split: `perforce` vs `ue`

### Changed
- **Overlay rename**: `ue-perforce` split into two overlays:
  - `perforce/` — generic Perforce CL-by-CL workflow, review-and-submit
    protocol, version-control conventions. Applies to *any* Perforce
    consumer (film/VFX, non-UE game engines, generic enterprise Perforce
    projects).
  - `ue/` — Unreal-Engine specific: sync-build-submit commands, UE-pattern
    p4ignore fragment (`Binaries/`, `Intermediate/`, `Saved/`).
- Manifest schema overlay enum: `["core","ue-perforce","myst-project",
  "tool-capability"]` → `["core","perforce","ue","myst-project",
  "tool-capability"]`.
- `setup.ps1` auto-detection: now picks `core,perforce,ue` only when both
  `.p4ignore` AND a `*.uproject` are present (recursively up to 1 level).
  Plain Perforce projects (no .uproject) get `core,perforce` — no UE bias.

### Backward compatibility
- `init-consumer.ps1 -Overlays 'ue-perforce'` (legacy v1.0.0 – v1.1.0)
  still works; expands to `perforce,ue` at install time.
- Existing v1.x consumers (e.g., the Myst_Proto live install) keep their
  recorded `ownerOverlay='ue-perforce'` — no manifest migration required.
- `promote-from-project.ps1` accepts new classifications `perforce-overlay`
  and `ue-overlay`; the legacy `ue-perforce-overlay` is still in the
  ValidateSet but marked DEPRECATED in the help text.

### Added
- 5 new tests in `run-init-consumer-tests.ps1` covering perforce-only path
  (no UE) and the legacy `ue-perforce` alias expansion.

### Why
- v1.0.0 / v1.1.0 conflated "Perforce workflow" with "Unreal Engine on
  Perforce". A film/VFX team, a Unity team on Perforce, or any non-UE
  Perforce project hitting `setup.ps1` got UE-specific build commands and
  `.p4ignore` patterns they didn't need. The split lets each consumer pick
  exactly what applies.

Tests: 86/86 across 9 suites (was 81/81 in v1.1.0).

## [1.1.0] - 2026-05-22 — One-command install

### Added
- `setup.ps1` at repo root: one-command install for new adopters. Auto-detects
  version control (Perforce / git / filesystem), picks sensible overlay
  defaults, bootstraps the manifest, runs a dry-run, prompts before writing.
  `-Yes` skips the prompt for unattended runs.
- `scripts/init-consumer.ps1`: generates a fresh consumer's bootstrap
  scaffold-manifest from `manifest-template.json`. Filters by selected
  `-Tools` and `-Overlays`, injects the consumer's `installedProject` block,
  resolves `sourceCommit` to the package's git HEAD. Refuses to overwrite
  existing manifest unless `-Force`.
- `manifest-template.json` at repo root: canonical entry-list template
  derived from the live installed scaffold (85 entries, project-specific
  state stripped). The starting point that init-consumer copies + filters.
- `scripts/run-init-consumer-tests.ps1`: 16-test suite covering
  init-consumer round-trip and full setup.ps1 flow.
- init-consumer pre-creates marker stubs for `generated-block` /
  `append-fragment` entries (`CLAUDE.md`, `AGENTS.md`, `.p4ignore`) so
  install.ps1 can populate blocks on first write without manual file creation.

### Fixed
- `install.ps1:185` — `Where-Object` returned `$null` (not empty array) when
  no entries matched the `pending-package` filter, causing
  `PropertyNotFoundStrict` on `.Count` in strict mode. Wrapped in `@(...)`.
  Surfaced after v1.0.0 since every entry now has a real sourceCommit.

### Changed
- README install section: replaced 12-line two-step example with the
  one-command `setup.ps1` flow. Old form still documented in install.md.

## [1.0.0] - 2026-05-21 — First stable release

Plan v1.6 complete. Package is coherent and ready for adoption.

### Added
- **Marker Specification** (`scripts/lib/Markers.ps1`) with hard parsing rules:
  whole-line markers, LF normalization, UTF-8 BOM stripping, CommonMark code-fence
  exclusion, indented-code-block exclusion, refuse-to-write on ambiguity. 14/14
  pathological fixtures pass.
- **Install crash/recovery model** (`scripts/lib/InstallJournal.ps1`): exclusive
  lock, staged temps, atomic rename via `File.Replace`, transactional
  restore-from-baks across the whole set. 10/10 journal tests pass.
- **Block-scoped hashing**: `blockHash` validates only bytes between markers, not
  the whole file. Schema-level rejection of any `generated-block` /
  `append-fragment` entry carrying a whole-file `contentHash`.
- **Cross-repo drift detection** (`scripts/compare-with-package.ps1`): 4 outcomes
  (clean / downstream-edit / upstream-update / conflict) + meta-conflict detection
  for schema and overlay enumeration. 5/5 tests pass.
- **Promotion workflow** (`scripts/promote-from-project.ps1`): bidirectional
  template-rendering, roundtrip-verify, classification by 4 ownership buckets
  (`local-only` / `project-owned` / `package-core` / `overlay`). 4 promotion +
  5/5 e2e tests pass.
- **Skeleton preflight** (`scripts/run-skeleton-preflight.ps1`): 10-point
  write-mode gate. Per-target P4 detection (skips P4-dependent checks for
  filesystem-only targets).
- **Perforce integration**: `install.ps1 -UsePerforce -Changelist new` opens
  files for edit in a named CL with What/Why/Notes description.
- **Consumer documentation**: `docs/install.md` (~500 lines, full install/update/
  promote/upstream-sync guide) and `docs/perforce-consumer.md` (~300 lines,
  UE+P4 addendum with worked example).
- **Architectural Decision Record**: documents Q1-Q5 design decisions (ownership
  taxonomy, marker placement, hashing scope, variable substitution model).
- **65 tests across 8 suites**: marker fixtures (14), journal (10), manifest
  update (5), classification (16), compare (5), promote (4), promotion e2e (5),
  new-user e2e (6).

### Changed
- Manifest schema bumped to **v3** with `blockHashPolicy`, `blockHash`,
  `depotRevision`, `upstreams`, `toolCapabilities`, `baselineState`,
  self-excluded entry.
- Write mode **enabled** (was hard-disabled in 0.1.0); now preflight-gated.
- Upstream `mattpocock/skills` license: **audited as MIT** at pinned commit
  `e74f0061`. Redistribution allowed with attribution.
- README and package manifest now reflect graduation state, not skeleton phase.

### Removed
- `writeModePreconditions` list from `package-manifest.json` (all preconditions
  met).
- `phase: "skeleton"` field (no longer phase-gated).

## [0.1.0] - 2026-05-19 — Skeleton phase

### Added
- Package directory structure (`templates/`, `overlays/`, `scripts/`, `skills/`).
- `package-manifest.json` declaring manifest **schema v3**.
- Dry-run / reporting-only scripts: `install.ps1`, `diff-installed.ps1`,
  `promote-from-project.ps1`, `check-mattpocock-updates.ps1`.

### Constrained
- Write-mode install hard-disabled.
- Marker injection into co-owned files deferred.
- Template/overlay content extraction deferred.
- Upstream license audit pending.
