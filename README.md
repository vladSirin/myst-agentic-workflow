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

The spine, so you know what's here without a catalog:

- **Delivery workflow** — `agentic-workflow` (the stage map), plus the stage skills it names (spec, tickets, triage, implement, wayfinding).
- **Publication protocol** — `review-and-submit` (two-axis review, Review Record, human-gated publish; Perforce and git forms) and `changelist-verification` (multi-changeset execution, one verify gate between each). The review engine is the vendored `code-review` skill — cite it namespaced as `myst-dev-kit:code-review`; the bare name resolves to the official git-diff review plugin.
- **Engineering + productivity** — TDD, bug diagnosis, design docs, domain modeling, grilling, handoffs, research, and more.

Vendored content comes verbatim from [mattpocock/skills](https://github.com/mattpocock/skills) with a per-skill provenance note; the rest is local-origin. Adding a skill is one directory — no prose to update, no counts to bump.

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
