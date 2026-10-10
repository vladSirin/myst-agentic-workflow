# reference/ — starter docs for a consuming project

Copy these into your project, or point your agent here and ask it to migrate them.
Nothing in this tree installs itself; it is reading material with a shape worth
reusing.

- `claude/CLAUDE.md` — a Claude Code workspace-setup section for a project's
  team bible.
- `codex/AGENTS.md` — the Codex/OpenCode equivalent (both tools read `AGENTS.md`).
- `docs/MustRead/MustRead_agentic_workflow.md` — the human workflow guide
  (discussion → spec → tickets → triage → implement → verify → review/submit).
- `docs/agents/` — issue-tracker, triage-labels, domain, and grill-context doc
  templates the workflow skills expect a project to define.
- `ue/p4ignore.fragment` — a `.p4ignore` fragment for Unreal Engine projects
  (stack-specific but project-agnostic).

These templates are snapshots, frozen at release time; where your project's live
copies have moved on, the live copies win.

Wrappers that load agentic-workflow's
[local integration contract](../plugins/myst-dev-kit/skills/agentic-workflow/LOCAL-INTEGRATION.md)
need that skill's whole directory plus their declared skill dependencies in a
copy install. Missing dependencies must be reported, not replaced by a same-name
skill from another package. Project domain templates require explicit local
pointers before use; they do not rename existing vocabulary files.
