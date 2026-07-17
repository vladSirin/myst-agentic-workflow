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
