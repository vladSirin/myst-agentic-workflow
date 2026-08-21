# Issue tracker: Repo markdown

Issues and specs (you may know a spec as a PRD) for this repo live as markdown
files under `.scratch/`. This is the temporary setup until the team migrates to
a hosted tracker.

## Version-control policy

**Files under `.scratch/<feature-slug>/` are version-controlled.** They're
submitted to the repo (Perforce or git) alongside the related work and
serve as the project's tracked history of specs, tickets, and triage state.
"Repo markdown" means *the tracker is in the repo*, not *the files are
local-only*.

If you're unsure whether a `.scratch/` file should be submitted: assume
**yes**, unless it matches a `.p4ignore` / `.gitignore` exclusion (rare;
typically only `_tmp/` or `.cache/` style directories).

Genuinely local-only state lives elsewhere — `.claude/settings.local.json`,
`.Codex/settings.local.json`. Those are per-machine, not `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation tickets are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`
- Triage state is recorded as a `Status:` line near the top of each issue file
- Status values are defined in `Docs/agents/triage-labels.md`
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed). Then submit the file with the work it tracks — same CL/commit, or a closely-related one.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.

**Telling the two kinds of effort apart.** Wayfinder efforts and implementation efforts share the
`.scratch/<effort>/issues/` namespace and both use `claimed` / `resolved`, so read the effort, not
the ticket: **a wayfinder effort has `map.md`; an implementation effort has `spec.md`.** In a
wayfinder effort, `resolved` means the question is answered; in an implementation effort it means
the code shipped and a human check remains (`Docs/agents/triage-labels.md`).
