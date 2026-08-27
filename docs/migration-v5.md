# Migration inventory — v5.0.0 "Lean Library"

Owner of every row: **sxc**. Date: **2026-08-27**. Rule (from the plan, after Gawande): **no
row, no cut** — nothing is deleted, moved, or rewritten unless it has a row here. Plan of
record: `.claude/plans/staged-stirring-tome.md` (owner machine) — six review passes.
Execution: git first (this repo, one release), then depot CLs CL-0 → CL-PRE → CL-SRC →
observe → CL-GATE, one at a time, each human-gated.

Dispositions: **KEEP** (unchanged or minor edit) · **TRANSFORM** (rewritten/generalized/moved
within repo) · **DELETE** (removed; git history is the archive) · **MOVE→DEPOT** (leaves repo,
lands in P4 depot) · **ADD** (new in v5).

## Root

| File | Disposition | Note |
|---|---|---|
| .agents/plugins/marketplace.json | KEEP | Codex-native marketplace manifest (what `codex plugin marketplace add` reads); already minimal — no version/description/count, unchanged |
| .claude-plugin/marketplace.json | KEEP | drop `version`+`description` from entry (per Claude Code docs); description rewrite |
| .gitattributes | KEEP | |
| .gitignore | KEEP | |
| .github/workflows/release.yml | KEEP | CHANGELOG-section check → hard fail; header comment de-tokened |
| .github/workflows/tests.yml | KEEP | ps51-gates: keep checkout/parse/ASCII-BOM steps, delete git-identity + git-pull steps, drop fetch-depth; suites job (:27-140) → new `lint` job; :141-143 comment rewritten |
| .scratch/agentic-scaffold-rejected-upstream.json | DELETE | working state of retired vendoring flow |
| .scratch/revendor-0ab1b63-divergence-ledger.md | DELETE | ADR-0006 ledger; system surrendered (ADR-0007) |
| CHANGELOG.md | KEEP | + v5.0.0 section w/ migration steps; retirement-policy contradiction fixed |
| CONTRIBUTING.md | TRANSFORM | promote-gate → direct-PR gate; version sites → 2; retirement policy re-derived |
| LICENSE | KEEP | |
| README.md | TRANSFORM | no-support clause; per-tool one-liner table; Migrating-from-v4; release-history reworded; v4 sections (§132/§180/§298/§330/§455) + per-skill tables excised; counts removed |
| SETUP.md | TRANSFORM | rewritten as short v5 onboarding page (six depot pointers reference it) |
| manifest-template.json | DELETE | generated-block render system |
| package-manifest.json | DELETE | version site + render machinery |
| vendored-hashes.json | DELETE | provenance ledger; give-up recorded in ADR-0007 |
| promote.ps1 | DELETE | round-trip retired; authoring is now direct-in-repo |
| setup.ps1 | DELETE | |
| update.ps1 | DELETE | |
| upgrade.ps1 | DELETE | |
| setup-devkit.ps1 | TRANSFORM | → 6-line deprecation stub (prints v5 steps, exit 1); dies with retire-legacy in a later MINOR |

## docs/

| File | Disposition | Note |
|---|---|---|
| adr-0001..0006 | KEEP | history; partially superseded — recorded by ADR-0007 |
| adr-0007 (new) | ADD | "lean library supersedes vendor/render model": supersessions in 0001/2/4/5/6 + give-ups (upstream tracking, generated agents, render system) |
| install.md | DELETE | folded into README per-tool table |
| upgrade.md | DELETE | superseded by CHANGELOG migration section |
| perforce-consumer.md | DELETE | superseded by README + depot tool-setup.md |
| tool-capability-matrix.md | DELETE | stale (Codex multi-agent v2 exists now); live facts → README + depot Docs/agents/tool-setup.md |
| migration-v5.md (this file) | ADD | the inventory |

## overlays/ + templates/ → reference/

| File | Disposition | Note |
|---|---|---|
| overlays/README.md | TRANSFORM | → reference/, scrubbed to v5 truth |
| overlays/myst-project/** (6 files) | DELETE | project-specific; live home = depot's rendered copies (agnostic-repo policy) |
| overlays/ue/p4ignore.fragment | TRANSFORM | → reference/ (stack-level = agnostic) |
| templates/README.md | TRANSFORM | → reference/; stale "OpenCode support was retired" claim removed |
| templates/claude/CLAUDE.md | TRANSFORM | → reference/, scrubbed (dead tokens :11,:20; two-file doc model superseded); refreshed to @AGENTS.md shape in v5.0.1 after CL-SRC |
| templates/codex/AGENTS.md | TRANSFORM | → reference/, same refresh cycle |
| templates/common/docs/MustRead/MustRead_agentic_workflow.md | TRANSFORM | → reference/, scrubbed (dead tokens :9,:13) |
| templates/common/docs/agents/{domain, issue-tracker, triage-labels, grill-with-docs-context-format}.md | TRANSFORM | → reference/ (agnostic team-doc templates) |

## plugins/myst-dev-kit/ — non-skill content

| File | Disposition | Note |
|---|---|---|
| .claude-plugin/plugin.json | KEEP | version site (1 of 2); description rewritten, count removed |
| .codex-plugin/plugin.json | KEEP | version site (2 of 2); description fully rewritten (drops TOML-generation promise + matrix cite) |
| LICENSE | KEEP | |
| agents/architecture-reviewer.md | DELETE | replaced by vendored code-review engine (canon archived in history) |
| agents/radical-design-critic.md | DELETE | same; Docs-alignment brief folds into review-and-submit |
| commands/promote-myst-skills.md | DELETE | |
| commands/update-project-scaffold.md | DELETE | resurrection vector closed |
| commands/sync-build-submit.md | MOVE→DEPOT | → .claude/commands/sync-build-submit.md under whitelist (CL-SRC) |
| hooks/hooks.json | DELETE | plugin ships zero hooks |
| scripts/check-rule-parity.sh | DELETE | orphaned source template (resurrection vector) |
| scripts/check-rules-alignment.sh | DELETE | same |
| scripts/doc-audit.sh | DELETE | dead copy; depot copy is hand-owned now |
| scripts/check-uproject-assoc.sh | DELETE | dead copy; depot copy also deleted (CL-SRC) |
| scripts/submit-audit-bridge.sh | DELETE | client-side audit warning retired; server audit remains |

## plugins/myst-dev-kit/skills/

| Skill | Disposition | Note |
|---|---|---|
| setup-agentic-workflow | DELETE | 100% front-end over deleted scripts |
| pre-implementation-gate | DELETE | depot rule absorbs shelve mechanics (CL-SRC) |
| review-changes | DELETE | premise verified: OpenCode + Codex (multi-agent v2) both spawn sub-agents |
| review-and-submit | TRANSFORM | generalized VCS-agnostic (dual P4/git sections); Standards axis → myst-dev-kit:code-review; Docs-alignment brief folded inline; inline-review guard sentence |
| changelist-verification | TRANSFORM | generalized: multi-changeset (CL/PR/commit-batch) |
| design | TRANSFORM | D8 scrub: (Myst_Proto\|FrogEvent\|split_fiction) generalized in place; :118,:122 "CL X.n" → "changeset X.n" |
| agentic-workflow | TRANSFORM | D8 scrub + one agnostic gate paragraph (workflow spine for public consumers) |
| code-review (new) | ADD | vendored VERBATIM from mattpocock/skills (engineering/code-review) + provenance note; cited namespaced `myst-dev-kit:code-review` |
| all remaining skills + companion files (codebase-design, diagnosing-bugs, domain-modeling, grill-me, grill-with-docs, grilling, handoff, implement, improve-codebase-architecture, prototype, research, resolving-merge-conflicts, roundtable, tdd, teach, to-questionnaire, to-spec, to-tickets, triage, wait-what, wayfinder, wizard, writing-for-agents) | KEEP | retired-name refs swept by lint (to-spec:9, to-tickets:11,60, triage:43, wayfinder:25, tdd:38, implement:13) |

## scripts/ (all 44: 37 workers/runners + 7 lib)

| File(s) | Disposition | Note |
|---|---|---|
| scripts/** (44 files incl. lib/) | DELETE | test runners, render/install/journal/marker/P4Spec libs, migrate/promote workers, vendored-hash + mattpocock-update checkers — the machinery tax |

## New root scripts

| File | Disposition | Note |
|---|---|---|
| bump.ps1 | ADD | updates 2 plugin.json versions + CHANGELOG-section check + git tag |
| retire-legacy.ps1 | ADD | transitional consumer cleanup; -WhatIf; journal guard (utf-8-sig, refuse on committed:false); OpenCode key table per plan; deleted with the stub in a later MINOR |
| retire-legacy.fixture.json | ADD | synthetic committed:false journal fixture |

## Untracked-local (recorded, not in git)

| Item | Note |
|---|---|
| fixtures/ | empty dir, untracked |
| err.log | untracked scratch |

## Depot files (P4 — executed as CL-0 → CL-PRE → CL-SRC → CL-GATE, each human-gated)

| CL | Files | Action |
|---|---|---|
| CL-0 | Tools/P4Triggers/p4-submit-audit-server.sh | remove check 5 (ranges per plan; DEPOT_ROOT rename ×3; bash -n) |
| CL-0 | .claude/scripts/test-hooks.sh | hoist SA/SCOUT/SALOG, delete :105-245 |
| CL-PRE | AGENTS.md | tool-neutral rewrite; fence taxonomy; slimmed supplement; markers :147,:175 out; install text |
| CL-PRE | Docs/agents/tool-setup.md | ADD (per-tool setup mechanics moved out of AGENTS.md; Codex multi_agent_v2 note) |
| CL-SRC | CLAUDE.md | → @AGENTS.md + Claude section; markers :82,:104 out |
| CL-SRC | .claude/scripts/{check-rule-parity.sh, check-rules-alignment.sh} | p4 delete |
| CL-SRC | .claude/scripts/doc-audit.sh | :115-130 out; staleness nudge hardened; + dead-ref grep (sunset ticketed) |
| CL-SRC | .claude/scripts/check-uproject-assoc.sh | p4 delete (unwired orphan) |
| CL-SRC | .claude/scripts/test-hooks.sh | delete :83-103 |
| CL-SRC | .claude/rules-alignment.baseline | p4 delete (parity doc §186 procedure) |
| CL-SRC | .claude/rules/PreImplementationGate.md | absorb shelve mechanics; skill pointers (:73,:83) out |
| CL-SRC | .p4ignore | :67-70 out; whitelist negation + comment in; markers :137,:150 out |
| CL-SRC | Docs/agents/{agent-context-parity.md, scaffold-manifest.json} | p4 delete |
| CL-SRC | .claude/commands/sync-build-submit.md | ADD (moved from plugin) |
| CL-SRC | Docs/MustRead/MustRead_ai_tools_for_creatives.md | 3 edits × 2 languages (ranges per plan; fence-count check) |
| CL-SRC | Docs/MustRead/MustRead_agentic_workflow.md | :90 version floor → 5.0.0 |
| CL-SRC | Docs/CI_Stage1_Runbook.md | :159 retired-name sweep |
| CL-SRC | Myst_Proto/Docs/plan_agentic_scaffolding_packaging_WIP.md | superseded banner + :3 Status flip |
| CL-SRC | .scratch/ (devkit trees) | full triage per plan (game trees excluded; 07 = user-only) |
| CL-GATE | .claude/scripts/check-script-standard.sh | p4 delete (§A client guard retired) |
| CL-GATE | .claude/settings.json | remove check-script-standard hook entry only |
| CL-GATE | .claude/scripts/test-hooks.sh | delete §A section (:32-55 region) |
| CL-GATE | CLAUDE.md, AGENTS.md, .claude/rules/angelscriptrules.md | "blocks" → "server-audited post-submit" (:45-46, :57, :63) |
