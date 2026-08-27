# myst-agentic-workflow

**A lean agentic skills library for [Claude Code](https://github.com/anthropics/claude-code), [Codex](https://github.com/openai/codex), and [OpenCode](https://opencode.ai) — one shared source, per-tool one-line install.**

Skills for the delivery loop (discussion → spec → tickets → triage → implement → verify → review/publish), engineering discipline (TDD, debugging, design, grilling), and a vendored two-axis code-review engine. Protocols are VCS-agnostic, with Perforce and git command forms. The plugin ships skills only — no agents, commands, hooks, or scripts.

## Install

| Tool | One-liner |
|---|---|
| **Claude Code** | `/plugin marketplace add vladSirin/myst-agentic-workflow` then `/plugin install myst-dev-kit@myst`, restart the session. (Myst team projects pre-register the marketplace — skip the first command there.) |
| **Codex** | Paste both, then start a new session:<br>`codex plugin marketplace add vladSirin/myst-agentic-workflow`<br>`codex plugin add myst-dev-kit@myst` |
| **OpenCode** — or any tool that scans `~/.claude/skills` / `~/.agents/skills` | `npx skills add vladSirin/myst-agentic-workflow` — per-skill selection, installed at personal scope (Node ≥ 22.20; add `--copy` on Windows). |

**Updating** — Claude Code: `claude plugin marketplace update myst` then `claude plugin update myst-dev-kit@myst`, restart (the marketplace refresh alone moves nothing you have installed). Codex: `codex plugin marketplace upgrade` (there is no separate plugin-update subcommand). npx consumers: re-run the add command.

## Migrating from v4

Two steps — details in the [CHANGELOG](CHANGELOG.md)'s v5.0.0 section:

1. Fetch `retire-legacy.ps1` from this repo and run it with `-WhatIf` (report-only), then without. It cleans v4 per-user state — the dedicated clone, generated reviewer agents, stale config keys — refuses to touch state it cannot prove committed, and backs up configs before writing.
2. Run your tool's one-liner from the table above.

Also check personal instruction files (`CLAUDE.local.md`, `~/.claude/CLAUDE.md`) for references to commands v5 removed. The v4 installer scripts are gone; a single deprecation stub remains that prints these steps and exits nonzero. The stub and `retire-legacy.ps1` are transitional and will be removed together in a later MINOR release.

## What you get

[`plugins/myst-dev-kit/skills/`](plugins/myst-dev-kit/skills/) is the library — one directory per skill, one shared source for every tool. Browse it directly: each `SKILL.md`'s frontmatter description is its trigger ("use when…"), which is exactly what your agent reads when deciding to load it.

Two kinds of skill, split by how they start:

- **User-invoked** — inert until you call them: type `/name` in Claude Code, or ask for the skill by name in Codex/OpenCode. The model never fires them on its own (`disable-model-invocation: true` in frontmatter).
- **Model-invoked** — the agent loads them itself whenever the task matches the description. You can also call any of them explicitly; the marker only removes the automatic path, never the manual one.

### Delivery & publishing

The pipeline: discussion → spec → tickets → triage → implement → verify → review/publish.

Model-invoked:

- **[agentic-workflow](plugins/myst-dev-kit/skills/agentic-workflow/SKILL.md)** — the stage map: which process stage you are in and what comes next. Fires on any non-trivial feature work.
- **[review-and-submit](plugins/myst-dev-kit/skills/review-and-submit/SKILL.md)** — the mandatory pre-publish protocol: changeset organization, two-axis review, Review Record, human-gated submit (Perforce and git forms).
- **[code-review](plugins/myst-dev-kit/skills/code-review/SKILL.md)** — the review engine: Standards and Spec axes in parallel sub-agents, reported side by side. Cite it namespaced as `myst-dev-kit:code-review` — the bare name resolves to the official git-diff review plugin.
- **[changelist-verification](plugins/myst-dev-kit/skills/changelist-verification/SKILL.md)** — hard rule for multi-changeset tasks: execute one at a time with a stop-and-verify gate between each, never batched.
- **[resolving-merge-conflicts](plugins/myst-dev-kit/skills/resolving-merge-conflicts/SKILL.md)** — work through an in-progress git merge/rebase conflict.

User-invoked:

- **[to-spec](plugins/myst-dev-kit/skills/to-spec/SKILL.md)** — turn the current conversation into a spec on the project tracker: no interview, just synthesis of what was discussed.
- **[to-tickets](plugins/myst-dev-kit/skills/to-tickets/SKILL.md)** — break a spec or plan into tracer-bullet tickets, each declaring its blocking edges.
- **[triage](plugins/myst-dev-kit/skills/triage/SKILL.md)** — move issues and external PRs through triage roles: categorise, verify, grill if needed, write agent-ready briefs.
- **[implement](plugins/myst-dev-kit/skills/implement/SKILL.md)** — implement a piece of work from a spec or set of tickets.
- **[wayfinder](plugins/myst-dev-kit/skills/wayfinder/SKILL.md)** — plan work too big for one session as a shared map of decision tickets, resolved one at a time until the way is clear.

### Engineering

Model-invoked:

- **[tdd](plugins/myst-dev-kit/skills/tdd/SKILL.md)** — test-driven development: red-green-refactor, features and bug fixes built test-first.
- **[diagnosing-bugs](plugins/myst-dev-kit/skills/diagnosing-bugs/SKILL.md)** — a diagnosis loop for hard bugs and performance regressions.
- **[design](plugins/myst-dev-kit/skills/design/SKILL.md)** — design and plan documents: correct name, correct location, standard template, WIP-to-final lifecycle.
- **[prototype](plugins/myst-dev-kit/skills/prototype/SKILL.md)** — build a throwaway prototype to answer a design question before committing to it.
- **[codebase-design](plugins/myst-dev-kit/skills/codebase-design/SKILL.md)** — the deep-module vocabulary: interface design, seam placement, testability, AI-navigability.
- **[domain-modeling](plugins/myst-dev-kit/skills/domain-modeling/SKILL.md)** — build and sharpen the project's domain model: terminology, CONTEXT.md, ADRs.
- **[research](plugins/myst-dev-kit/skills/research/SKILL.md)** — investigate a question against high-trust primary sources; findings land as a Markdown file in the repo.
- **[wizard](plugins/myst-dev-kit/skills/wizard/SKILL.md)** — generate an interactive bash wizard for steps only a human can perform: credentials, dashboards, one-off cutovers.
- **[writing-for-agents](plugins/myst-dev-kit/skills/writing-for-agents/SKILL.md)** — writing documents agents will read: skills, AGENTS.md, CLAUDE.md.

User-invoked:

- **[improve-codebase-architecture](plugins/myst-dev-kit/skills/improve-codebase-architecture/SKILL.md)** — scan a codebase for deepening opportunities, presented as a visual HTML report, then grill through whichever you pick.

### Thinking & productivity

Model-invoked:

- **[grilling](plugins/myst-dev-kit/skills/grilling/SKILL.md)** — relentless questioning to stress-test a plan, decision, or idea.
- **[roundtable](plugins/myst-dev-kit/skills/roundtable/SKILL.md)** — a moderated, truth-seeking discussion of a contested topic across 3–5 representative thinkers.

User-invoked:

- **[grill-me](plugins/myst-dev-kit/skills/grill-me/SKILL.md)** — get interviewed about a plan or design until every branch of the decision tree is resolved.
- **[grill-with-docs](plugins/myst-dev-kit/skills/grill-with-docs/SKILL.md)** — the same interview, writing ADRs and glossary entries as it goes.
- **[deep-dive](plugins/myst-dev-kit/skills/deep-dive/SKILL.md)** — bring it a decision you keep circling: it steel-mans *both* sides to their strongest versions, surfaces the real crux, asks you one decisive question, and only after your answer gives a verdict with boundary conditions and next actions. For questions still tangled, answers that feel plausible but shaky, or premises you suspect you're not seeing.
- **[teach](plugins/myst-dev-kit/skills/teach/SKILL.md)** — learn a skill or concept, taught inside this workspace.
- **[to-questionnaire](plugins/myst-dev-kit/skills/to-questionnaire/SKILL.md)** — turn a decision you can't fully answer into a questionnaire for the person who can.
- **[handoff](plugins/myst-dev-kit/skills/handoff/SKILL.md)** — compact the current conversation into a handoff document for the next session to pick up.
- **[wait-what](plugins/myst-dev-kit/skills/wait-what/SKILL.md)** — stop: that last message did not land — re-pitch it.

Vendored content comes verbatim from [mattpocock/skills](https://github.com/mattpocock/skills) and from the Hammer app's advanced-capability bundle ([dreamwords/hammer-releases](https://github.com/dreamwords/hammer-releases); `deep-dive` by 卡兹克), each with a per-skill provenance note; the rest is local-origin. Adding a skill is one directory plus its one catalog line above — the [per-skill checklist](CONTRIBUTING.md) keeps the two in step.

[`reference/`](reference/) holds starter docs to copy into a consuming project: workspace-setup sections for the tool bibles, the human workflow guide, issue-tracker and triage-label templates, and a UE `.p4ignore` fragment.

## Support

A working team library shared as-is: no support commitments, no roadmap, and releases track this team's needs. Issues and PRs are welcome ([CONTRIBUTING.md](CONTRIBUTING.md)); responses are best-effort. Pin a tag if you need stability.

## Layout

```
myst-agentic-workflow/
├── README.md / CHANGELOG.md / CONTRIBUTING.md / SETUP.md / LICENSE
├── bump.ps1                          # release helper: 2 manifest versions + CHANGELOG check + tag
├── retire-legacy.ps1                 # transitional v4-state cleanup (dies with the stub in a later MINOR)
├── .github/workflows/tests.yml       # CI: PS 5.1 parse gate, ASCII/BOM gate, lint
├── .github/workflows/release.yml     # tag push v* -> GitHub Release from the CHANGELOG section
├── .claude-plugin/marketplace.json   # plugin marketplace (Claude Code native)
├── .agents/plugins/marketplace.json  # plugin marketplace (Codex native)
├── docs/                             # ADRs + the v5 migration inventory
├── plugins/myst-dev-kit/
│   ├── .claude-plugin/plugin.json    # dual plugin manifests (one per tool)
│   ├── .codex-plugin/plugin.json
│   └── skills/                       # the library — ONE shared source for every tool
└── reference/                        # starter docs for a consuming project
```

## Releases

Every `v*` tag auto-publishes a GitHub Release with that version's CHANGELOG section as the body — the [CHANGELOG](CHANGELOG.md) is the release history. Architecture decisions live in the ADRs under [`docs/`](docs/); [ADR-0007](docs/adr-0007-lean-library-supersedes-vendor-render-model.md) is the v5 "lean library" restructure and records what it superseded and gave up.

## License

MIT. Bundles content vendored from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) — attribution preserved in [LICENSE](LICENSE) and per-skill provenance notes.
