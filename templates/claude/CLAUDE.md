## Claude Code Workspace Setup

All Claude Code agentic configuration lives under `.claude/`. This section documents every component so any team member can understand and use the full setup.

OpenCode is also supported as a secondary agentic tool. Its configuration lives in `opencode.json` and `.opencode/`.

**CRITICAL**: At the start of EVERY session, read and follow ALL workflow files listed below.

### `.claude/` Directory Map

```
.claude/
├── agents/          # Custom subagent definitions (auto-loaded by Claude Code)
│   ├── architecture-reviewer.md   — Code/architecture review agent
│   └── radical-design-critic.md   — Design/UX critical review agent
├── commands/        # Slash commands (user-invocable via /command-name)
│   └── sync-build-submit.md       — Full sync → build → submit pipeline
├── rules/           # Auto-loaded rules (triggered by model decisions)
│   └── angelscriptrules.md        — AngelScript coding conventions
├── scripts/         # Shell automation (used by hooks and manual runs)
│   └── doc-audit.sh               — Session-start doc freshness check
├── skills/          # Skills (user-invocable via /skill-name)
│   ├── design.md                  — /design: Create design docs with reviewer feedback
│   └── roundtable.md              — /roundtable: Multi-perspective design discussion
└── workflows/       # Mandatory workflow rules (agent reads on every session)
    ├── AutoPlanMode.md             — Enter plan mode for non-trivial tasks
    ├── ChangelistVerification.md   — HARD RULE: CL-by-CL verification, no batching
    ├── DesignWorkflow.md           — Design/planning document creation flow
    ├── DocumentStandard.md         — Doc naming conventions and lifecycle
    ├── PlanPriority.md             — HARD RULE: Use existing plans before creating new ones
    ├── RawMaterialsProtection.md   — HARD RULE: Docs/_Raw is read-only; warn and require lead approval
    ├── ReviewAndSubmit.md          — Pre-submit review protocol with agent routing
    ├── ScriptStandard.md           — MANDATORY: AngelScript file naming and folder rules
    ├── AgenticWorkflow.md          — Discussion → PRD → issues → triage workflow
    └── VersionControlRule.md       — Perforce versioning workflow

# Auto-generated local files (not checked in, omitted from map):
# settings.local.json, settings.json, scheduled_tasks.lock
```

### Workflows (Mandatory)

These are rules Claude follows autonomously on every session. **All are mandatory.**

| Workflow | Purpose |
|----------|---------|
| `AutoPlanMode.md` | Enter plan mode before non-trivial implementation |
| `VersionControlRule.md` | Perforce checkout/submit conventions |
| `DesignWorkflow.md` | How to create and route design documents |
| `PlanPriority.md` | **HARD RULE**: Always use existing plans first |
| `ReviewAndSubmit.md` | Pre-submit review protocol with CL description standard |
| `ChangelistVerification.md` | **HARD RULE**: Execute CLs one at a time, verify between |
| `DocumentStandard.md` | Naming and lifecycle rules for docs |
| `RawMaterialsProtection.md` | **HARD RULE**: `Docs/_Raw/` is read-only; warn and require project-lead approval before any change |
| `ScriptStandard.md` | **MANDATORY**: AngelScript naming, type suffixes, folder structure |
| `AgenticWorkflow.md` | Discussion → PRD → issues → triage → implementation → verification → review/submit |

### Agents (Auto-loaded)

Custom subagents available via the Agent tool. Claude routes to these automatically based on content type.

| Agent | Triggers On | Purpose |
|-------|-------------|---------|
| `architecture-reviewer` | Code/architecture changes, post-implementation review | Reviews for Code Complete principles, SOLID, UE5 patterns, FrogEvent integration |
| `radical-design-critic` | Design docs, UX proposals, feature specs | Stress-tests designs for edge cases, UX friction, hidden complexity |

### Skills (User-invocable)

| Skill | Purpose |
|-------|---------|
| `/design` | Creates design doc in `{{game_docs_root}}/`, launches both reviewer agents, iterates |
| `/roundtable` | Multi-perspective design discussion with different expert viewpoints |
| `/to-prd` | Turns current context into a PRD under `.scratch/<feature>/PRD.md` |
| `/to-issues` | Breaks PRDs/plans into vertical-slice issues under `.scratch/<feature>/issues/` |
| `/triage` | Moves issues through the repo status workflow (issues live as version-controlled markdown under `.scratch/`) |
| `/tdd` | Implements one behavior-tested vertical slice at a time |
| `/diagnose` | Debugs bugs/regressions by building a reproducible feedback loop first |
| `/improve-codebase-architecture` | Finds architecture improvements informed by project docs |
| `/zoom-out` | Maps an unfamiliar code area before local changes |
| `/grill-with-docs` | Stress-tests plans and updates context/ADR docs as decisions solidify |

### Commands (User-invocable)

| Command | Purpose |
|---------|---------|
| `/sync-build-submit` | Full pipeline: P4 sync → build → submit binaries |

### Rules (Auto-triggered)

| Rule | Trigger | Purpose |
|------|---------|---------|
| `angelscriptrules.md` | When writing AngelScript code | Enforces AS coding conventions and patterns |

### Key Protocols

**Review and Submit** — Say **"review and submit {changelist name or ID}"** before submitting code:
1. Organizes files into a named CL with comprehensive description (What/Why/Notes)
2. Routes to reviewer agent(s) based on content type
3. Presents BLOCKING/WARNING/INFO summary
4. Waits for your decision: Submit, Fix & Re-review, Fix Specific, or Defer

### First-Time Setup for New Team Members

> **Prerequisite**: Bash must be available (Git Bash, WSL, or similar) for hooks and scripts.

1. **Sync the repo** — all `.claude/` files are in Perforce
2. **Add hooks to `.claude/settings.local.json`** (local only, not checked in). If the file already exists, merge in the `hooks` block — the `permissions` block is machine-specific and accumulates as you use Claude Code:
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "hooks": [
             {
               "type": "command",
               "command": "bash .claude/scripts/doc-audit.sh",
               "timeout": 30
             }
           ]
         }
       ]
     }
   }
   ```
3. **Start a Claude Code session** — agents, rules, and workflows load automatically
4. **Verify**: Ask Claude "what agents and skills are available?" to confirm everything loaded