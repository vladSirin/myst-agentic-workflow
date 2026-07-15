## Claude Code Workspace Setup

The team AI setup has two layers:

**1. Committed core** (arrives with version-control sync — nothing to do):
- `.claude/settings.json` — team hooks (session doc-audit, AngelScript write
  validator, Submit-Audit pre-submit warning) + plugin marketplace registration.
- `.claude/rules/` — auto-loaded rules committed in this repo (the set varies
  by project; the Myst repo ships all five): `angelscriptrules` (AS conventions),
  `unrealmcprules` (use `mcp__unreal-engine__*` for `/Game` assets, never
  Read/Grep), `DocumentStandard` (doc naming), `RawMaterialsProtection`
  (**HARD RULE**: `{{game_docs_root}}/_Raw/` is leads-only),
  `PreImplementationGate` (**HARD RULE**: PRD/issues/triage before any
  multi-CL plan).
- `.claude/scripts/` — the hook validators the settings wire up.
- Team docs — `Docs/MustRead/MustRead_agentic_workflow.md` (the human workflow
  manual), `Docs/agents/` (issue tracker, triage labels, domain).

**2. Dev kit** (the `myst-dev-kit` plugin — installed once per user):
- All team skills, including the process rules as on-demand skills:
  `review-and-submit`, `changelist-verification`, `plan-priority`,
  `pre-implementation-gate`, `agentic-workflow`, `auto-plan-mode`,
  `design-workflow`, plus the engineering/productivity set (`tdd`,
  `diagnosing-bugs`, `to-prd`, `to-issues`, `triage`, `grilling`, `design`,
  `handoff`, ...).
- Reviewer agents: `architecture-reviewer` (code), `radical-design-critic`
  (designs/docs). Sessions without agents use the `review-changes` skill.
- Commands: `/sync-build-submit`, `/update-myst-skills`, `/promote-myst-skills`.

**Install** (first session): accept the plugin prompt on trusting the repo, or
run `/plugin install myst-dev-kit@myst`. Full onboarding for both archetypes
(standard sync-and-go, poweruser personal layers): **SETUP.md in the
myst-agentic-workflow repo**.

### Key protocol

Say **"review and submit {changelist name or ID}"** before submitting code —
the `review-and-submit` skill runs the protocol: named-CL organization,
reviewer routing, BLOCKING/WARNING/INFO summary, your decision, then a
Review Record block in the CL description and preflight validators.

### Personal layer (never version-controlled)

`~/.claude/CLAUDE.md` and `CLAUDE.local.md` (additive personal instructions),
`.claude/settings.local.json` (personal hooks/permissions — to remove a hook
locally, DELETE the key; an empty array is an active override), personal
skills/plugins. Improvements worth sharing go back via the package's
CONTRIBUTING.md gate.
