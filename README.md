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

- **User-invoked** — intended to start only on your request. Claude uses `disable-model-invocation: true`; migrated Codex entries also carry native invocation metadata. OpenCode needs a permission rule and an explicit `/name` command; see the [tested handoff setup](docs/handoff-pilot-2026-10-07.md#opencode-invocation-configuration). The frontmatter flag alone does not enforce this in every host.
- **Model-invoked** — the agent loads them itself whenever the task matches the description. You can also call any of them explicitly; the marker only removes the automatic path, never the manual one.

### Delivery & publishing

The pipeline: discussion → spec → tickets → triage → implement → verify → review/publish.

Model-invoked:

- **[agentic-workflow](plugins/myst-dev-kit/skills/agentic-workflow/SKILL.md)** — the stage map and shared local integration: project pointers, dependency routing, and legacy/new glossary paths. Fires on non-trivial feature work.
- **[review-and-submit](plugins/myst-dev-kit/skills/review-and-submit/SKILL.md)** — the mandatory pre-publish protocol: changeset organization, two-axis review, Review Record, human-gated submit (Perforce and git forms).
- **[code-review](plugins/myst-dev-kit/skills/code-review/SKILL.md)** — the review engine: Standards and Spec axes in parallel sub-agents, reported side by side. Cite it namespaced as `myst-dev-kit:code-review` — the bare name resolves to the official git-diff review plugin.
- **[changelist-verification](plugins/myst-dev-kit/skills/changelist-verification/SKILL.md)** — hard rule for multi-changeset tasks: execute one at a time with a stop-and-verify gate between each, never batched.
- **[resolving-merge-conflicts](plugins/myst-dev-kit/skills/resolving-merge-conflicts/SKILL.md)** — work through an in-progress git merge/rebase conflict.

User-invoked:

- **[to-spec](plugins/myst-dev-kit/skills/to-spec/SKILL.md)** — synthesize the conversation into a spec through unchanged upstream instructions and local tracker, glossary, and state rules. Copy installs need agentic-workflow ([migration evidence](docs/to-spec-wrapper-2026-10-08.md)).
- **[to-tickets](plugins/myst-dev-kit/skills/to-tickets/SKILL.md)** — Matt Pocock source with Myst tracker routing; split approved work into tracer-bullet tickets with blockers and parent links. Plain-source migration; verification tracked in the migration inventory.
- **[triage](plugins/myst-dev-kit/skills/triage/SKILL.md)** — Matt Pocock source with Myst tracker and glossary routing; categorise, verify, grill, and write agent briefs. Plain-source migration; verification tracked in the migration inventory.
- **[implement](plugins/myst-dev-kit/skills/implement/SKILL.md)** — implement a spec or tickets through unchanged plain upstream references and Myst dependency/review routing; supports Git and Perforce targets. Copy installs need agentic-workflow, tdd, review-and-submit, and code-review.
- **[wayfinder](plugins/myst-dev-kit/skills/wayfinder/SKILL.md)** — Matt Pocock source with Myst tracker and glossary routing; plan large work as a map of decision tickets. Plain-source migration; verification tracked in the migration inventory.

### Engineering

Model-invoked:

- **[tdd](plugins/myst-dev-kit/skills/tdd/SKILL.md)** — test-first development through unchanged plain upstream references and red-green cycles, with local glossary and review routing. Copy installs also need agentic-workflow, codebase-design, review-and-submit, and code-review ([conversion evidence](docs/tdd-plain-source-2026-10-08.md)).
- **[diagnosing-bugs](plugins/myst-dev-kit/skills/diagnosing-bugs/SKILL.md)** — Matt Pocock source with Myst glossary and VCS routing; diagnose hard bugs and performance regressions. Verification tracked in the migration inventory.
- **[design](plugins/myst-dev-kit/skills/design/SKILL.md)** — design and plan documents: correct name, correct location, standard template, WIP-to-final lifecycle.
- **[prototype](plugins/myst-dev-kit/skills/prototype/SKILL.md)** — build a throwaway prototype to answer a design question before committing to it.
- **[codebase-design](plugins/myst-dev-kit/skills/codebase-design/SKILL.md)** — the deep-module vocabulary: interface design, seam placement, testability, AI-navigability. Upstream bytes stay unchanged in plain references; the entry is packaged as UPSTREAM.md. The local wrapper maps project glossary paths. Copy installs also need `agentic-workflow` ([packaging evidence](docs/plain-source-pilot-2026-10-08.md)).
- **[domain-modeling](plugins/myst-dev-kit/skills/domain-modeling/SKILL.md)** — Matt Pocock source with Myst glossary-path routing; sharpen domain terms and record durable ADRs. Supports legacy, new, and scoped glossary paths; verification tracked in the migration inventory.
- **[research](plugins/myst-dev-kit/skills/research/SKILL.md)** — investigate a question against high-trust primary sources; findings land as a Markdown file in the repo.
- **[wizard](plugins/myst-dev-kit/skills/wizard/SKILL.md)** — generate an interactive bash wizard for steps only a human can perform: credentials, dashboards, one-off cutovers.
- **[writing-for-agents](plugins/myst-dev-kit/skills/writing-for-agents/SKILL.md)** — writing documents agents will read: skills, AGENTS.md, CLAUDE.md.

User-invoked:

- **[improve-codebase-architecture](plugins/myst-dev-kit/skills/improve-codebase-architecture/SKILL.md)** — scan a codebase for deepening opportunities, presented as a visual HTML report, then grill through whichever you pick.

### Thinking & productivity

Model-invoked:

- **[grilling](plugins/myst-dev-kit/skills/grilling/SKILL.md)** — relentless questioning to stress-test a plan, decision, or idea.
- **[roundtable](plugins/myst-dev-kit/skills/roundtable/SKILL.md)** — a moderated, truth-seeking discussion of a contested topic across 3–5 representative thinkers, with an ASCII framework chart each round and user-steered pacing. For decisions with no single right answer, when you want differing roles' or disciplines' views, or want the disagreements on the table before picking a direction.

User-invoked:

- **[grill-me](plugins/myst-dev-kit/skills/grill-me/SKILL.md)** — get interviewed about a plan or design until every branch of the decision tree is resolved.
- **[grill-with-docs](plugins/myst-dev-kit/skills/grill-with-docs/SKILL.md)** — the same interview, writing ADRs and glossary entries as it goes.
- **[deep-dive](plugins/myst-dev-kit/skills/deep-dive/SKILL.md)** — bring it a decision you keep circling: it steel-mans *both* sides to their strongest versions, surfaces the real crux, asks you one decisive question, and only after your answer gives a verdict with boundary conditions and next actions. For questions still tangled, answers that feel plausible but shaky, or premises you suspect you're not seeing. Original Hammer source is preserved as plain references; English discovery and user-only metadata stay local ([conversion evidence](docs/deep-dive-plain-source-2026-10-08.md)).
- **[teach](plugins/myst-dev-kit/skills/teach/SKILL.md)** — learn a skill or concept, taught inside this workspace.
- **[to-questionnaire](plugins/myst-dev-kit/skills/to-questionnaire/SKILL.md)** — turn a decision you can't fully answer into a questionnaire for the person who can.
- **[handoff](plugins/myst-dev-kit/skills/handoff/SKILL.md)** — compact the conversation into an OS-temporary handoff file. Unchanged upstream bytes in plain references, read through a user-invoked local entry; [conversion evidence and host limits](docs/handoff-plain-source-2026-10-08.md).
- **[wait-what](plugins/myst-dev-kit/skills/wait-what/SKILL.md)** — stop: that last message did not land — re-pitch it.

Imported content comes from [mattpocock/skills](https://github.com/mattpocock/skills)
and the Hammer app's advanced-capability bundle
([dreamwords/hammer-releases](https://github.com/dreamwords/hammer-releases);
`deep-dive` by 卡兹克, `roundtable` by 李继刚); the remaining skills are local-origin.
Older Matt imports use the attribution pin in [LICENSE](LICENSE); later imports
also carry per-skill provenance notes.

**Upstream-boundary migration is pending.** Current imports include local inline
adaptations, intentionally omitted upstream metadata, and local Hammer
frontmatter. The approved target is complete unchanged source bundles with
separate Myst entry points. That source guarantee does not imply identical
runtime behavior: the local entries own Myst integration. The
[plain-reference packaging decision](docs/adr-0009-plain-upstream-references.md)
permits one entry filename mapping while preserving every upstream byte. The
[migration inventory](docs/migration-upstream-boundary.md) tracks each skill and
its acceptance evidence. The catalog above describes the current package;
planned additions and removals are not yet shipped.

Adding or retiring a skill updates its catalog row through the
[per-skill checklist](CONTRIBUTING.md). During the refresh, reviewed skill PRs
land on a migration branch before one final integration and release.

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
├── tools/verify_upstream.py          # repository-only pinned-source verifier
├── upstream-policy.json             # local skills and explicit migration debt
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
