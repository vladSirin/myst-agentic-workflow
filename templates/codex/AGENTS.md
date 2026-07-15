## Codex Workspace Setup

The team AI setup has two layers:

**1. Committed core** (arrives with version-control sync — nothing to do):
- This file (AGENTS.md) — the shared team baseline. Never edit it for personal
  preferences; your personal layer is `~/.codex/AGENTS.md` (additive).
- Team docs — `Docs/MustRead/MustRead_agentic_workflow.md` (the human workflow
  manual), `Docs/agents/` (issue tracker, triage labels, domain).
- Behavioral rules that ALWAYS apply: AngelScript naming per the ScriptStandard
  (a write-time hook enforces it under Claude Code; under Codex, load the
  project's `.claude/rules/angelscriptrules.md` before writing `.as` files);
  `{{game_docs_root}}/_Raw/` is **leads-only** — never modify it;
  PRD/issues/triage come before any multi-CL implementation plan.

**2. Dev kit** (the `myst-dev-kit` plugin — installed once per user):
- All team skills, including the process rules as on-demand skills:
  `review-and-submit`, `changelist-verification`, `plan-priority`,
  `pre-implementation-gate`, `agentic-workflow`, `auto-plan-mode`,
  `design-workflow`, plus the engineering/productivity set (`tdd`,
  `diagnosing-bugs`, `to-prd`, `to-issues`, `triage`, `grilling`, `design`,
  `handoff`, ...).
- **Reviews under Codex**: there are no subagents — use the `review-changes`
  skill (inline review with the same rubrics and the same `Verdict:` contract).
- The plugin's hook delivers the Submit-Audit pre-submit warning to Codex
  sessions automatically.
- Commands: `/sync-build-submit`, `/update-myst-skills`, `/promote-myst-skills`.

**Install** (once):
```
codex plugin marketplace add vladSirin/myst-agentic-workflow
```
then `/plugins` → Myst Team Plugins → install `myst-dev-kit` → start a new
session. Full onboarding for both archetypes: **SETUP.md in the
myst-agentic-workflow repo**.

### Key protocol

Say **"review and submit {changelist name or ID}"** before submitting code —
the `review-and-submit` skill runs the protocol: named-CL organization, review
(inline via `review-changes`), BLOCKING/WARNING/INFO summary, your decision,
then a Review Record block in the CL description and preflight validators.

### Personal layer (never version-controlled)

`~/.codex/AGENTS.md` (additive personal instructions — the Codex analog of a
personal CLAUDE.md). `AGENTS.override.md` REPLACES this file entirely — escape
hatch only, not for preferences. Improvements worth sharing go back via the
package's CONTRIBUTING.md gate.
