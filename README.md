# myst-agentic-workflow

**A lean agentic skills library for [Claude Code](https://github.com/anthropics/claude-code), [Codex](https://github.com/openai/codex), and [OpenCode](https://opencode.ai) — one shared source, per-tool one-line install.**

Skills for the delivery loop (discussion → spec → tickets → triage → implement → verify → review/publish), engineering discipline (TDD, debugging, design, grilling), and a vendored two-axis code-review engine. Protocols are VCS-agnostic, with Perforce and git command forms. The plugin supplies skills and their reference files; it registers no agents, commands, or hooks.

## Version status

`main` contains the **5.5.0 preview**, merged through
[PR #107](https://github.com/vladSirin/myst-agentic-workflow/pull/107).
**The latest published release is v5.4.0.** The owner will test 5.5 in daily use
before a separate tag and release decision. Install commands that follow the
repository can select the preview before it is released. Use a published tag
when you need a released version.

See the [current status and remaining checks](docs/upstream-release-candidate-2026-10-09.md#current-status---2026-10-10).

## Install

| Tool | One-liner |
|---|---|
| **Claude Code** | `/plugin marketplace add vladSirin/myst-agentic-workflow` then `/plugin install myst-dev-kit@myst`, restart the session. (Myst team projects pre-register the marketplace — skip the first command there.) |
| **Codex** | Paste both, then start a new session:<br>`codex plugin marketplace add vladSirin/myst-agentic-workflow`<br>`codex plugin add myst-dev-kit@myst` |
| **OpenCode** — or any tool that scans `~/.claude/skills` / `~/.agents/skills` | `npx skills add vladSirin/myst-agentic-workflow --global` — per-skill selection at personal scope (Node ≥ 22.20; add `--copy` on Windows). Omit `--global` for project scope. |

**Updating** — Claude Code: `claude plugin marketplace update myst` then `claude plugin update myst-dev-kit@myst`, restart (the marketplace refresh alone moves nothing you have installed). Codex: `codex plugin marketplace upgrade` (there is no separate plugin-update subcommand). npx consumers: re-run the add command.

Copy installs also need the [refresh cleanup steps](docs/upstream-refresh-install-cleanup.md)
when crossing this migration boundary. Re-running add can leave retired skill
folders. Check ownership and preserve personal edits before replacement or removal.
For a Codex marketplace registered from a local path, re-run
`codex plugin add myst-dev-kit@myst`, then start a new session. Marketplace
upgrade refreshes Git sources; see [SETUP](SETUP.md#update) for the local-path case.

## Migrating from v4

Two steps — details in the [CHANGELOG](CHANGELOG.md)'s v5.0.0 section:

1. Fetch `retire-legacy.ps1` from this repo and run it with `-WhatIf` (report-only), then without. It cleans v4 per-user state — the dedicated clone, generated reviewer agents, stale config keys — refuses to touch state it cannot prove committed, and backs up configs before writing.
2. Run your tool's one-liner from the table above.

Also check personal instruction files (`CLAUDE.local.md`, `~/.claude/CLAUDE.md`) for references to commands v5 removed. The v4 installer scripts are gone; a single deprecation stub remains that prints these steps and exits nonzero. The stub and `retire-legacy.ps1` are transitional and will be removed together in a later MINOR release.

## What you get

[`plugins/myst-dev-kit/skills/`](plugins/myst-dev-kit/skills/) is the library — one directory per skill, one shared source for every tool. Browse it directly: each `SKILL.md`'s frontmatter description is its trigger ("use when…"), which is exactly what your agent reads when deciding to load it.

Codex generates menu labels from namespaced skill names, such as
`myst-dev-kit:handoff` becoming **Myst Dev Kit: Handoff**. Public metadata leaves
`display_name` unset so this host default applies. Invocation policies and short
descriptions stay in local metadata. **Personal** is the installation scope.
OpenCode uses the names in SKILL.md; it does not inherit the Codex display prefix.

Two kinds of skill, split by how they start:

- **User-invoked** — intended to start only on your request. Claude uses `disable-model-invocation: true`; migrated Codex entries also carry native invocation metadata. OpenCode needs a permission rule and an explicit `/name` command; see the [tested handoff setup](docs/handoff-pilot-2026-10-07.md#opencode-invocation-configuration). The frontmatter flag alone does not enforce this in every host.
- **Model-invoked** — the agent loads them itself whenever the task matches the description. You can also call any of them explicitly; the marker only removes the automatic path, never the manual one.

OpenCode 1.18.35 hides skill commands from slash-menu suggestions. A custom
command alias can show a skill in that menu; it must load the public Myst wrapper.
See the [tested menu setup](docs/handoff-pilot-2026-10-07.md#slash-menu-suggestions-11835).
Skill discovery, menu display and model execution are separate checks.

### Delivery & publishing

The pipeline: discussion → spec → tickets → triage → implement → verify → review/publish.

Model-invoked:

- **[agentic-workflow](plugins/myst-dev-kit/skills/agentic-workflow/SKILL.md)** — the stage map and shared local integration: project pointers, dependency routing, and legacy/new glossary paths. Fires on non-trivial feature work.
- **[review-and-submit](plugins/myst-dev-kit/skills/review-and-submit/SKILL.md)** — the mandatory pre-publish protocol: two-axis review, verified results inside Evidence, VCS-specific formatter routing, preflight, and human-gated publication. Copy installs need agentic-workflow, code-review, and the target formatter (pr for Git; p4-description for Perforce).
- **[code-review](plugins/myst-dev-kit/skills/code-review/SKILL.md)** — unchanged Matt Pocock two-axis review method with Myst engine selection, project spec lookup, and Git/Perforce evidence mapping. Invoke `myst-dev-kit:code-review`, or its full Myst path in copy hosts ([evidence](docs/code-review-wrapper-2026-10-08.md)).
- **[pr](plugins/myst-dev-kit/skills/pr/SKILL.md)** — Git-only PR bodies using intact Matt Pocock source and show-me credits; Myst adds project vocabulary, ticket pointers, and verified review evidence. Never used for P4 targets. Copy installs need agentic-workflow ([evidence](docs/pr-wrapper-2026-10-08.md)).
- **[p4-description](plugins/myst-dev-kit/skills/p4-description/SKILL.md)** — local Perforce-only descriptions with established title tags, ASCII text, factual review evidence, and Submit Risk. Inspired by pr/show-me; never invokes Git-only pr. Copy installs need agentic-workflow ([evidence](docs/p4-description-2026-10-08.md)).
- **[changelist-verification](plugins/myst-dev-kit/skills/changelist-verification/SKILL.md)** — hard rule for multi-changeset tasks: execute one at a time with a stop-and-verify gate between each, never batched.

User-invoked:

- **[to-spec](plugins/myst-dev-kit/skills/to-spec/SKILL.md)** — synthesize the conversation into a spec through unchanged upstream instructions and local tracker, glossary, and state rules. Copy installs need agentic-workflow ([migration evidence](docs/to-spec-wrapper-2026-10-08.md)).
- **[to-tickets](plugins/myst-dev-kit/skills/to-tickets/SKILL.md)** — Matt Pocock source with Myst tracker routing; split approved work into tracer-bullet tickets with blockers and parent links. Plain-source migration; verification tracked in the migration inventory.
- **[triage](plugins/myst-dev-kit/skills/triage/SKILL.md)** — Matt Pocock source with Myst tracker and glossary routing; categorise, verify, grill, and write agent briefs. Plain-source migration; verification tracked in the migration inventory.
- **[implement](plugins/myst-dev-kit/skills/implement/SKILL.md)** — implement a spec or tickets through unchanged plain upstream references and Myst dependency/review routing; supports Git and Perforce targets. Copy installs need agentic-workflow, tdd, review-and-submit, code-review, and the target formatter required by review-and-submit.
- **[implement-spec](plugins/myst-dev-kit/skills/implement-spec/SKILL.md)** -- intact Matt Pocock task-graph/worktree orchestration for an approved Git spec. User-only; never for Perforce. Myst retains project, dependency, review and publication rules. Copy installs need the declared dependencies and their closure ([evidence](docs/implement-spec-wrapper-2026-10-09.md)).
- **[wayfinder](plugins/myst-dev-kit/skills/wayfinder/SKILL.md)** — Matt Pocock source with Myst tracker and glossary routing; plan large work as a map of decision tickets. Plain-source migration; verification tracked in the migration inventory.

### Engineering

Model-invoked:

- **[tdd](plugins/myst-dev-kit/skills/tdd/SKILL.md)** — test-first development through unchanged plain upstream references and red-green cycles, with local glossary and review routing. Copy installs also need agentic-workflow, codebase-design, review-and-submit, code-review, and its target formatter ([conversion evidence](docs/tdd-plain-source-2026-10-08.md)).
- **[diagnosing-bugs](plugins/myst-dev-kit/skills/diagnosing-bugs/SKILL.md)** — Matt Pocock source with Myst glossary and VCS routing; diagnose hard bugs and performance regressions. Verification tracked in the migration inventory.
- **[design](plugins/myst-dev-kit/skills/design/SKILL.md)** — design and plan documents: correct name, correct location, standard template, WIP-to-final lifecycle.
- **[prototype](plugins/myst-dev-kit/skills/prototype/SKILL.md)** — intact Matt Pocock logic demos and contrasting UI variants, with Myst project/VCS capture and validation routing. Copy installs need agentic-workflow ([evidence](docs/prototype-wrapper-2026-10-09.md)).
- **[codebase-design](plugins/myst-dev-kit/skills/codebase-design/SKILL.md)** — the deep-module vocabulary: interface design, seam placement, testability, AI-navigability. Upstream bytes stay unchanged in plain references; the entry is packaged as UPSTREAM.md. The local wrapper maps project glossary paths. Copy installs also need `agentic-workflow` ([packaging evidence](docs/plain-source-pilot-2026-10-08.md)).
- **[domain-modeling](plugins/myst-dev-kit/skills/domain-modeling/SKILL.md)** — Matt Pocock source with Myst glossary-path routing; sharpen domain terms and record durable ADRs. Supports legacy, new, and scoped glossary paths; verification tracked in the migration inventory.
- **[research](plugins/myst-dev-kit/skills/research/SKILL.md)** — intact Matt Pocock background research from primary sources, with Myst project/note routing and authority. Copy installs need agentic-workflow ([evidence](docs/research-wrapper-2026-10-09.md)).
- **[wizard](plugins/myst-dev-kit/skills/wizard/SKILL.md)** — intact Matt Pocock human-only Bash wizard method and fixed template, with Myst setup/CI and VCS capture routing. Copy installs need agentic-workflow ([evidence](docs/wizard-wrapper-2026-10-09.md)).
- **[writing-for-agents](plugins/myst-dev-kit/skills/writing-for-agents/SKILL.md)** — intact upstream writing reference and skill mechanics; Myst resolves project/document scope and authority. Copy installs also need agentic-workflow. [Migration evidence](docs/writing-for-agents-wrapper-2026-10-09.md).

User-invoked:

- **[improve-codebase-architecture](plugins/myst-dev-kit/skills/improve-codebase-architecture/SKILL.md)** — Matt Pocock source with Myst domain, VCS, and dependency routing; visual deepening report, then a user-selected design interview. User-only; OpenCode needs its local invocation rule ([evidence](docs/improve-codebase-architecture-wrapper-2026-10-08.md)).

### Thinking & productivity

Model-invoked:

- **[grilling](plugins/myst-dev-kit/skills/grilling/SKILL.md)** — intact Matt Pocock design-tree interview and fact-finding method, with Myst project/scope/authority routing. Model and user invoked; copy installs need agentic-workflow ([evidence](docs/grilling-wrapper-2026-10-09.md)).
- **[roundtable](plugins/myst-dev-kit/skills/roundtable/SKILL.md)** — intact Hammer dialogue method, round controls, and ASCII frames; Myst retains English discovery and local display metadata. [Migration evidence](docs/roundtable-wrapper-2026-10-09.md).

User-invoked:

- **[grill-me](plugins/myst-dev-kit/skills/grill-me/SKILL.md)** — intact Matt Pocock user-only alias, routed to Myst's grilling engine. Copy installs need agentic-workflow and grilling ([evidence](docs/grill-me-wrapper-2026-10-09.md)).
- **[grill-with-docs](plugins/myst-dev-kit/skills/grill-with-docs/SKILL.md)** — intact Matt Pocock composition of grilling and domain-modeling, with Myst dependency identity and project-doc mapping. User-only; copy installs need agentic-workflow, grilling, and domain-modeling ([evidence](docs/grill-with-docs-wrapper-2026-10-08.md)).
- **[deep-dive](plugins/myst-dev-kit/skills/deep-dive/SKILL.md)** — bring it a decision you keep circling: it steel-mans *both* sides to their strongest versions, surfaces the real crux, asks you one decisive question, and only after your answer gives a verdict with boundary conditions and next actions. For questions still tangled, answers that feel plausible but shaky, or premises you suspect you're not seeing. Original Hammer source is preserved as plain references; English discovery and user-only metadata stay local ([conversion evidence](docs/deep-dive-plain-source-2026-10-08.md)).
- **[teach](plugins/myst-dev-kit/skills/teach/SKILL.md)** — intact Matt Pocock stateful teaching method and formats, with Myst workspace/vocabulary/authority routing. User-only; copy installs need agentic-workflow ([evidence](docs/teach-wrapper-2026-10-09.md)).
- **[to-questionnaire](plugins/myst-dev-kit/skills/to-questionnaire/SKILL.md)** — intact Matt Pocock send interview and discovery-questionnaire method, with Myst project/destination/authority routing. User-only; copy installs need agentic-workflow ([evidence](docs/to-questionnaire-wrapper-2026-10-09.md)).
- **[handoff](plugins/myst-dev-kit/skills/handoff/SKILL.md)** — compact the conversation into an OS-temporary handoff file. Unchanged upstream bytes in plain references, read through a user-invoked local entry; [conversion evidence and host limits](docs/handoff-plain-source-2026-10-08.md).
- **[wait-what](plugins/myst-dev-kit/skills/wait-what/SKILL.md)** — Matt Pocock source with Myst glossary routing; re-explain with context and simple project terms. User-only; OpenCode needs its local invocation rule ([evidence](docs/wait-what-wrapper-2026-10-08.md)).

Imported content comes from [mattpocock/skills](https://github.com/mattpocock/skills)
and the Hammer app's advanced-capability bundle
([dreamwords/hammer-releases](https://github.com/dreamwords/hammer-releases);
`deep-dive` by 卡兹克, `roundtable` by 李继刚); the remaining skills are local-origin.
All twenty-four Matt imports use the recorded refresh pin. Both Hammer imports
record their selected release and existing permission. [LICENSE](LICENSE) and
per-skill provenance notes preserve their respective attribution.

**Source restoration is complete on main.** All twenty-six
retained or added imports have complete unchanged source bundles and separate
Myst entry points. The source guarantee does not imply identical runtime
behavior: the local entries own Myst integration. The
[plain-reference packaging decision](docs/adr-0009-plain-upstream-references.md)
permits one entry filename mapping while preserving every upstream byte. The
[migration inventory](docs/migration-upstream-boundary.md) tracks each skill and
its acceptance evidence. The catalog above describes this checkout. Release and
consumer acceptance are tracked separately from source restoration. Claude
runtime tests remain deferred.
The [combined acceptance report](docs/upstream-release-acceptance-2026-10-09.md)
records the bounded install and consumer checks. The
[release status](docs/upstream-release-candidate-2026-10-09.md#current-status---2026-10-10)
records the merge, local 5.5 update, and remaining checks. Its dated candidate
sections preserve the earlier evidence.

Adding or retiring a skill updates its catalog row through the
[per-skill checklist](CONTRIBUTING.md). The temporary migration exception closed
when PR #107 merged on 2026-10-10. Later skill contributions use the normal
one-skill PR process. The owner-approved
[display-label follow-up](CONTRIBUTING.md#codex-display-label-follow-up) is a
bounded cosmetic exception.

[`reference/`](reference/) holds starter docs to copy into a consuming project: workspace-setup sections for the tool bibles, the human workflow guide, issue-tracker and triage-label templates, and a UE `.p4ignore` fragment.

## Support

A working team library shared as-is: no support commitments, no roadmap, and releases track this team's needs. Issues and PRs are welcome ([CONTRIBUTING.md](CONTRIBUTING.md)); responses are best-effort. Pin a tag if you need stability.

## Layout

```
myst-agentic-workflow/
├── README.md / CHANGELOG.md / CONTRIBUTING.md / SETUP.md / LICENSE
├── bump.ps1                          # release helper: 2 manifest versions + CHANGELOG check + tag
├── retire-legacy.ps1                 # transitional v4-state cleanup (dies with the stub in a later MINOR)
├── .github/workflows/tests.yml       # CI: PS 5.1 parse, ASCII/BOM, lint, pinned-source verification
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

Every `v*` tag auto-publishes a GitHub Release with that version's CHANGELOG section as the body. The [Releases page](https://github.com/vladSirin/myst-agentic-workflow/releases) lists published versions; the [CHANGELOG](CHANGELOG.md) also carries the unreleased 5.5 preview notes. Tagging 5.5 waits for the owner's daily-use verdict and separate instruction. Architecture decisions live in the ADRs under [`docs/`](docs/); [ADR-0007](docs/adr-0007-lean-library-supersedes-vendor-render-model.md) is the v5 "lean library" restructure and records what it superseded and gave up.

## License

MIT. Bundles content vendored from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) — attribution preserved in [LICENSE](LICENSE) and per-skill provenance notes.
