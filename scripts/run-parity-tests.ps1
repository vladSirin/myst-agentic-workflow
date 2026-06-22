# run-parity-tests.ps1 -- cross-tool parity audit
#
# Verifies that files which should exist across multiple tools (Claude /
# Codex / OpenCode) are in fact present in each, by walking an explicit
# parity matrix. Documented deviations are allowed; anything NOT in the
# matrix and NOT in the deviation list is flagged as drift.
#
# Why explicit-list instead of auto-discovery:
#   - OpenCode has format differences (skills as subdirs/SKILL.md vs flat .md)
#   - AGENTS.md is shared between Codex and OpenCode (single physical file)
#   - Some Claude/Codex files are intentionally NOT in OpenCode
# The matrix makes the cross-tool layout explicit, which is the point.
#
# Exit codes:
#   0 : all parity expectations met
#   1 : drift detected (one or more files missing where the matrix expects them)
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0
function Ok($n)         { Write-Host ("[PASS] {0}" -f $n);          $script:pass++ }
function Bad($n, $why)  { Write-Host ("[FAIL] {0}: {1}" -f $n,$why); $script:fail++ }

# --- Parity matrix ---
# Each row: a logical item + the relative path in each tool's template dir.
# Use $null to indicate "this tool does not have an equivalent" -- but that
# should be paired with an entry in $deviations explaining why.
#
# Format-only differences (OpenCode uses subdir/SKILL.md) are encoded
# directly here -- no separate "format" mechanism needed.
$matrix = @(
    # Skills (9, three-way parity)
    @{ Id='skill:diagnosing-bugs';                       Claude='templates/claude/.claude/skills/diagnosing-bugs/SKILL.md';                       Codex='templates/codex/.Codex/skills/diagnosing-bugs/SKILL.md';                       OpenCode='templates/opencode/.opencode/skills/diagnosing-bugs/SKILL.md' }
    # diagnosing-bugs companion script (faithful vendoring incl. non-.md companions, ADR-0002) — three-way
    @{ Id='skill:diagnosing-bugs/hitl-loop-script';      Claude='templates/claude/.claude/skills/diagnosing-bugs/scripts/hitl-loop.template.sh';   Codex='templates/codex/.Codex/skills/diagnosing-bugs/scripts/hitl-loop.template.sh';   OpenCode='templates/opencode/.opencode/skills/diagnosing-bugs/scripts/hitl-loop.template.sh' }
    @{ Id='skill:grill-with-docs';                Claude='templates/claude/.claude/skills/grill-with-docs/SKILL.md';                Codex='templates/codex/.Codex/skills/grill-with-docs/SKILL.md';                OpenCode='templates/opencode/.opencode/skills/grill-with-docs/SKILL.md' }
    @{ Id='skill:improve-codebase-architecture';  Claude='templates/claude/.claude/skills/improve-codebase-architecture/SKILL.md';  Codex='templates/codex/.Codex/skills/improve-codebase-architecture/SKILL.md';  OpenCode='templates/opencode/.opencode/skills/improve-codebase-architecture/SKILL.md' }
    @{ Id='skill:roundtable';                     Claude='templates/claude/.claude/skills/roundtable/SKILL.md';                     Codex='templates/codex/.Codex/skills/roundtable/SKILL.md';                     OpenCode='templates/opencode/.opencode/skills/roundtable/SKILL.md' }
    @{ Id='skill:tdd';                            Claude='templates/claude/.claude/skills/tdd/SKILL.md';                            Codex='templates/codex/.Codex/skills/tdd/SKILL.md';                            OpenCode='templates/opencode/.opencode/skills/tdd/SKILL.md' }
    @{ Id='skill:to-issues';                      Claude='templates/claude/.claude/skills/to-issues/SKILL.md';                      Codex='templates/codex/.Codex/skills/to-issues/SKILL.md';                      OpenCode='templates/opencode/.opencode/skills/to-issues/SKILL.md' }
    @{ Id='skill:to-prd';                         Claude='templates/claude/.claude/skills/to-prd/SKILL.md';                         Codex='templates/codex/.Codex/skills/to-prd/SKILL.md';                         OpenCode='templates/opencode/.opencode/skills/to-prd/SKILL.md' }
    @{ Id='skill:triage';                         Claude='templates/claude/.claude/skills/triage/SKILL.md';                         Codex='templates/codex/.Codex/skills/triage/SKILL.md';                         OpenCode='templates/opencode/.opencode/skills/triage/SKILL.md' }
    @{ Id='skill:zoom-out';                       Claude='templates/claude/.claude/skills/zoom-out/SKILL.md';                       Codex='templates/codex/.Codex/skills/zoom-out/SKILL.md';                       OpenCode='templates/opencode/.opencode/skills/zoom-out/SKILL.md' }

    # Productivity skills (4, three-way parity, added in v2.0.0)
    @{ Id='skill:caveman';                        Claude='templates/claude/.claude/skills/caveman/SKILL.md';                        Codex='templates/codex/.Codex/skills/caveman/SKILL.md';                        OpenCode='templates/opencode/.opencode/skills/caveman/SKILL.md' }
    @{ Id='skill:grill-me';                       Claude='templates/claude/.claude/skills/grill-me/SKILL.md';                       Codex='templates/codex/.Codex/skills/grill-me/SKILL.md';                       OpenCode='templates/opencode/.opencode/skills/grill-me/SKILL.md' }
    @{ Id='skill:handoff';                        Claude='templates/claude/.claude/skills/handoff/SKILL.md';                        Codex='templates/codex/.Codex/skills/handoff/SKILL.md';                        OpenCode='templates/opencode/.opencode/skills/handoff/SKILL.md' }
    @{ Id='skill:write-a-skill';                  Claude='templates/claude/.claude/skills/write-a-skill/SKILL.md';                  Codex='templates/codex/.Codex/skills/write-a-skill/SKILL.md';                  OpenCode='templates/opencode/.opencode/skills/write-a-skill/SKILL.md' }

    # Phase A: vendored faithfully from upstream HEAD (ADR-0002), three-way + companions
    @{ Id='skill:domain-modeling';                Claude='templates/claude/.claude/skills/domain-modeling/SKILL.md';                Codex='templates/codex/.Codex/skills/domain-modeling/SKILL.md';                OpenCode='templates/opencode/.opencode/skills/domain-modeling/SKILL.md' }
    @{ Id='skill:domain-modeling/ADR-FORMAT';     Claude='templates/claude/.claude/skills/domain-modeling/ADR-FORMAT.md';            Codex='templates/codex/.Codex/skills/domain-modeling/ADR-FORMAT.md';            OpenCode='templates/opencode/.opencode/skills/domain-modeling/ADR-FORMAT.md' }
    @{ Id='skill:domain-modeling/CONTEXT-FORMAT'; Claude='templates/claude/.claude/skills/domain-modeling/CONTEXT-FORMAT.md';        Codex='templates/codex/.Codex/skills/domain-modeling/CONTEXT-FORMAT.md';        OpenCode='templates/opencode/.opencode/skills/domain-modeling/CONTEXT-FORMAT.md' }
    @{ Id='skill:grilling';                       Claude='templates/claude/.claude/skills/grilling/SKILL.md';                       Codex='templates/codex/.Codex/skills/grilling/SKILL.md';                       OpenCode='templates/opencode/.opencode/skills/grilling/SKILL.md' }
    @{ Id='skill:teach';                          Claude='templates/claude/.claude/skills/teach/SKILL.md';                          Codex='templates/codex/.Codex/skills/teach/SKILL.md';                          OpenCode='templates/opencode/.opencode/skills/teach/SKILL.md' }
    @{ Id='skill:teach/GLOSSARY-FORMAT';          Claude='templates/claude/.claude/skills/teach/GLOSSARY-FORMAT.md';                 Codex='templates/codex/.Codex/skills/teach/GLOSSARY-FORMAT.md';                 OpenCode='templates/opencode/.opencode/skills/teach/GLOSSARY-FORMAT.md' }
    @{ Id='skill:teach/LEARNING-RECORD-FORMAT';   Claude='templates/claude/.claude/skills/teach/LEARNING-RECORD-FORMAT.md';          Codex='templates/codex/.Codex/skills/teach/LEARNING-RECORD-FORMAT.md';          OpenCode='templates/opencode/.opencode/skills/teach/LEARNING-RECORD-FORMAT.md' }
    @{ Id='skill:teach/MISSION-FORMAT';           Claude='templates/claude/.claude/skills/teach/MISSION-FORMAT.md';                  Codex='templates/codex/.Codex/skills/teach/MISSION-FORMAT.md';                  OpenCode='templates/opencode/.opencode/skills/teach/MISSION-FORMAT.md' }
    @{ Id='skill:teach/RESOURCES-FORMAT';         Claude='templates/claude/.claude/skills/teach/RESOURCES-FORMAT.md';                Codex='templates/codex/.Codex/skills/teach/RESOURCES-FORMAT.md';                OpenCode='templates/opencode/.opencode/skills/teach/RESOURCES-FORMAT.md' }
    # Phase B new vendors (ADR-0002/0003) — faithful from upstream HEAD, three-way
    @{ Id='skill:codebase-design'; Claude='templates/claude/.claude/skills/codebase-design/SKILL.md'; Codex='templates/codex/.Codex/skills/codebase-design/SKILL.md'; OpenCode='templates/opencode/.opencode/skills/codebase-design/SKILL.md' }
    @{ Id='skill:codebase-design/DEEPENING'; Claude='templates/claude/.claude/skills/codebase-design/DEEPENING.md'; Codex='templates/codex/.Codex/skills/codebase-design/DEEPENING.md'; OpenCode='templates/opencode/.opencode/skills/codebase-design/DEEPENING.md' }
    @{ Id='skill:codebase-design/DESIGN-IT-TWICE'; Claude='templates/claude/.claude/skills/codebase-design/DESIGN-IT-TWICE.md'; Codex='templates/codex/.Codex/skills/codebase-design/DESIGN-IT-TWICE.md'; OpenCode='templates/opencode/.opencode/skills/codebase-design/DESIGN-IT-TWICE.md' }
    @{ Id='skill:writing-great-skills'; Claude='templates/claude/.claude/skills/writing-great-skills/SKILL.md'; Codex='templates/codex/.Codex/skills/writing-great-skills/SKILL.md'; OpenCode='templates/opencode/.opencode/skills/writing-great-skills/SKILL.md' }
    @{ Id='skill:writing-great-skills/GLOSSARY'; Claude='templates/claude/.claude/skills/writing-great-skills/GLOSSARY.md'; Codex='templates/codex/.Codex/skills/writing-great-skills/GLOSSARY.md'; OpenCode='templates/opencode/.opencode/skills/writing-great-skills/GLOSSARY.md' }
    @{ Id='skill:setup-matt-pocock-skills'; Claude='templates/claude/.claude/skills/setup-matt-pocock-skills/SKILL.md'; Codex='templates/codex/.Codex/skills/setup-matt-pocock-skills/SKILL.md'; OpenCode='templates/opencode/.opencode/skills/setup-matt-pocock-skills/SKILL.md' }
    @{ Id='skill:setup-matt-pocock-skills/domain'; Claude='templates/claude/.claude/skills/setup-matt-pocock-skills/domain.md'; Codex='templates/codex/.Codex/skills/setup-matt-pocock-skills/domain.md'; OpenCode='templates/opencode/.opencode/skills/setup-matt-pocock-skills/domain.md' }
    @{ Id='skill:setup-matt-pocock-skills/issue-tracker-github'; Claude='templates/claude/.claude/skills/setup-matt-pocock-skills/issue-tracker-github.md'; Codex='templates/codex/.Codex/skills/setup-matt-pocock-skills/issue-tracker-github.md'; OpenCode='templates/opencode/.opencode/skills/setup-matt-pocock-skills/issue-tracker-github.md' }
    @{ Id='skill:setup-matt-pocock-skills/issue-tracker-gitlab'; Claude='templates/claude/.claude/skills/setup-matt-pocock-skills/issue-tracker-gitlab.md'; Codex='templates/codex/.Codex/skills/setup-matt-pocock-skills/issue-tracker-gitlab.md'; OpenCode='templates/opencode/.opencode/skills/setup-matt-pocock-skills/issue-tracker-gitlab.md' }
    @{ Id='skill:setup-matt-pocock-skills/issue-tracker-local'; Claude='templates/claude/.claude/skills/setup-matt-pocock-skills/issue-tracker-local.md'; Codex='templates/codex/.Codex/skills/setup-matt-pocock-skills/issue-tracker-local.md'; OpenCode='templates/opencode/.opencode/skills/setup-matt-pocock-skills/issue-tracker-local.md' }
    @{ Id='skill:setup-matt-pocock-skills/triage-labels'; Claude='templates/claude/.claude/skills/setup-matt-pocock-skills/triage-labels.md'; Codex='templates/codex/.Codex/skills/setup-matt-pocock-skills/triage-labels.md'; OpenCode='templates/opencode/.opencode/skills/setup-matt-pocock-skills/triage-labels.md' }
    @{ Id='skill:edit-article'; Claude='templates/claude/.claude/skills/edit-article/SKILL.md'; Codex='templates/codex/.Codex/skills/edit-article/SKILL.md'; OpenCode='templates/opencode/.opencode/skills/edit-article/SKILL.md' }
    @{ Id='skill:obsidian-vault'; Claude='templates/claude/.claude/skills/obsidian-vault/SKILL.md'; Codex='templates/codex/.Codex/skills/obsidian-vault/SKILL.md'; OpenCode='templates/opencode/.opencode/skills/obsidian-vault/SKILL.md' }
    @{ Id='skill:resolving-merge-conflicts'; Claude='templates/claude/.claude/skills/resolving-merge-conflicts/SKILL.md'; Codex='templates/codex/.Codex/skills/resolving-merge-conflicts/SKILL.md'; OpenCode='templates/opencode/.opencode/skills/resolving-merge-conflicts/SKILL.md' }
    @{ Id='skill:implement'; Claude='templates/claude/.claude/skills/implement/SKILL.md'; Codex='templates/codex/.Codex/skills/implement/SKILL.md'; OpenCode='templates/opencode/.opencode/skills/implement/SKILL.md' }
    # resolving-merge-conflicts P4 companion: perforce overlay, Claude+Codex (OpenCode opts out)
    @{ Id='overlay:perforce/resolving-merge-conflicts-P4-NOTES'; Claude='overlays/perforce/.claude/skills/resolving-merge-conflicts/P4-NOTES.md'; Codex='overlays/perforce/.Codex/skills/resolving-merge-conflicts/P4-NOTES.md'; OpenCode=$null }

    # Workflows (4: AgenticWorkflow/PlanPriority/PreImplementationGate three-way; AutoPlanMode two-way)
    @{ Id='workflow:AgenticWorkflow';             Claude='templates/claude/.claude/workflows/AgenticWorkflow.md';             Codex='templates/codex/.Codex/workflows/AgenticWorkflow.md';             OpenCode='templates/opencode/.opencode/workflows/AgenticWorkflow.md' }
    @{ Id='workflow:PlanPriority';                Claude='templates/claude/.claude/workflows/PlanPriority.md';                Codex='templates/codex/.Codex/workflows/PlanPriority.md';                OpenCode='templates/opencode/.opencode/workflows/PlanPriority.md' }
    @{ Id='workflow:PreImplementationGate';       Claude='templates/claude/.claude/workflows/PreImplementationGate.md';       Codex='templates/codex/.Codex/workflows/PreImplementationGate.md';       OpenCode='templates/opencode/.opencode/workflows/PreImplementationGate.md' }
    @{ Id='workflow:AutoPlanMode';                Claude='templates/claude/.claude/workflows/AutoPlanMode.md';                Codex='templates/codex/.Codex/workflows/AutoPlanMode.md';                OpenCode=$null }

    # Agent (1, three-way parity)
    @{ Id='agent:radical-design-critic';          Claude='templates/claude/.claude/agents/radical-design-critic.md';          Codex='templates/codex/.Codex/agents/radical-design-critic.md';          OpenCode='templates/opencode/.opencode/agents/radical-design-critic.md' }

    # Slash commands (2, three-way parity)
    @{ Id='command:update-myst-skills';           Claude='templates/claude/.claude/commands/update-myst-skills.md';           Codex='templates/codex/.Codex/commands/update-myst-skills.md';           OpenCode='templates/opencode/.opencode/commands/update-myst-skills.md' }
    @{ Id='command:promote-myst-skills';          Claude='templates/claude/.claude/commands/promote-myst-skills.md';          Codex='templates/codex/.Codex/commands/promote-myst-skills.md';          OpenCode='templates/opencode/.opencode/commands/promote-myst-skills.md' }

    # OpenCode-only convenience commands (wrappers around the same-name skill)
    @{ Id='command:design (opencode-only)';       Claude=$null; Codex=$null; OpenCode='templates/opencode/.opencode/commands/design.md' }
    @{ Id='command:roundtable (opencode-only)';   Claude=$null; Codex=$null; OpenCode='templates/opencode/.opencode/commands/roundtable.md' }

    # Bible (tool-specific by design, but each tool MUST have its bible-equivalent)
    @{ Id='bible:Claude';                         Claude='templates/claude/CLAUDE.md';                                        Codex=$null;                                                             OpenCode=$null }
    @{ Id='bible:AGENTS';                         Claude=$null;                                                               Codex='templates/codex/AGENTS.md';                                       OpenCode=$null }

    # Perforce overlay workflows (Claude + Codex; OpenCode opts out per deviation)
    @{ Id='overlay:perforce/ChangelistVerification'; Claude='overlays/perforce/.claude/workflows/ChangelistVerification.md'; Codex='overlays/perforce/.Codex/workflows/ChangelistVerification.md'; OpenCode=$null }
    @{ Id='overlay:perforce/ReviewAndSubmit';        Claude='overlays/perforce/.claude/workflows/ReviewAndSubmit.md';        Codex='overlays/perforce/.Codex/workflows/ReviewAndSubmit.md';        OpenCode=$null }

    # UE overlay (sync-build-submit three-way; UnrealMCPRule three-way with per-tool layout:
    # Claude/Codex carry it as rules/unrealmcprules.md, OpenCode as workflows/UnrealMCPRule.md)
    @{ Id='overlay:ue/sync-build-submit';         Claude='overlays/ue/.claude/commands/sync-build-submit.md';                 Codex='overlays/ue/.Codex/commands/sync-build-submit.md';                OpenCode='overlays/ue/.opencode/commands/sync-build-submit.md' }
    @{ Id='overlay:ue/UnrealMCPRule';             Claude='overlays/ue/.claude/rules/unrealmcprules.md';                       Codex='overlays/ue/.Codex/rules/unrealmcprules.md';                      OpenCode='overlays/ue/.opencode/workflows/UnrealMCPRule.md' }
    # diagnosing-bugs UE/Perforce companion: faithful-base + overlay tailoring (ADR-0002) — three-way
    @{ Id='overlay:ue/diagnosing-bugs-UE-NOTES';         Claude='overlays/ue/.claude/skills/diagnosing-bugs/UE-NOTES.md';                   Codex='overlays/ue/.Codex/skills/diagnosing-bugs/UE-NOTES.md';                  OpenCode='overlays/ue/.opencode/skills/diagnosing-bugs/UE-NOTES.md' }

    # Myst-project overlay (Claude + Codex; OpenCode minimal)
    @{ Id='overlay:myst/architecture-reviewer';   Claude='overlays/myst-project/.claude/agents/architecture-reviewer.md';   Codex='overlays/myst-project/.Codex/agents/architecture-reviewer.md';   OpenCode='overlays/myst-project/.opencode/agents/architecture-reviewer.md' }
    @{ Id='overlay:myst/angelscriptrules';        Claude='overlays/myst-project/.claude/rules/angelscriptrules.md';         Codex='overlays/myst-project/.Codex/rules/angelscriptrules.md';         OpenCode=$null }
    @{ Id='overlay:myst/design';                  Claude='overlays/myst-project/.claude/skills/design/SKILL.md';                   Codex='overlays/myst-project/.Codex/skills/design/SKILL.md';                   OpenCode='overlays/myst-project/.opencode/skills/design/SKILL.md' }
    @{ Id='overlay:myst/DesignWorkflow';          Claude='overlays/myst-project/.claude/workflows/DesignWorkflow.md';        Codex='overlays/myst-project/.Codex/workflows/DesignWorkflow.md';        OpenCode=$null }
    @{ Id='overlay:myst/DocumentStandard';        Claude='overlays/myst-project/.claude/workflows/DocumentStandard.md';      Codex='overlays/myst-project/.Codex/workflows/DocumentStandard.md';      OpenCode=$null }
    @{ Id='overlay:myst/RawMaterialsProtection';  Claude='overlays/myst-project/.claude/workflows/RawMaterialsProtection.md';Codex='overlays/myst-project/.Codex/workflows/RawMaterialsProtection.md';OpenCode=$null }
    @{ Id='overlay:myst/ScriptStandard';          Claude='overlays/myst-project/.claude/workflows/ScriptStandard.md';        Codex='overlays/myst-project/.Codex/workflows/ScriptStandard.md';        OpenCode=$null }
)

# --- Deviations: justify each $null in the matrix above ---
# This is the audit trail. If a tool's column is $null but no deviation is
# recorded here, the test still passes (because the matrix says null = no
# equivalent), but the deviations doc captures *why*. Update both when
# adding new asymmetries.
$deviations = @{
    'bible:Claude'                        = 'Claude reads CLAUDE.md; Codex+OpenCode share AGENTS.md (one physical file in the consumer, served by both tools)'
    'bible:AGENTS'                        = 'AGENTS.md is shared between Codex and OpenCode; one file at consumer root serves both. Claude has its own CLAUDE.md.'
    'overlay:perforce/ChangelistVerification' = 'OpenCode does not mirror Claude/Codex workflow files one-for-one (see toolCapabilities deviation). Perforce rules carried via AGENTS.md.'
    'overlay:perforce/ReviewAndSubmit'    = 'OpenCode does not mirror Claude/Codex workflow files one-for-one (see toolCapabilities deviation).'
    'workflow:AutoPlanMode'               = 'AutoPlanMode targets the Claude/Codex plan-mode capability (manifest ownerOverlay=tool-capability, capabilityProfile=claude-plan-mode). OpenCode has no equivalent plan-mode workflow.'
    'overlay:perforce/resolving-merge-conflicts-P4-NOTES' = 'OpenCode opts out of the perforce overlay (toolCapabilities deviation); P4 merge notes are Claude/Codex only.'
    'overlay:myst/angelscriptrules'       = 'OpenCode does not use Claude/Codex rules/* convention; project rules carried via AGENTS.md or skill descriptions.'
    'overlay:myst/DesignWorkflow'         = 'OpenCode does not mirror Claude/Codex workflow files one-for-one (see toolCapabilities deviation).'
    'overlay:myst/DocumentStandard'       = 'OpenCode does not mirror Claude/Codex workflow files one-for-one (see toolCapabilities deviation).'
    'overlay:myst/RawMaterialsProtection' = 'OpenCode does not mirror Claude/Codex workflow files one-for-one (see toolCapabilities deviation).'
    'overlay:myst/ScriptStandard'         = 'OpenCode does not mirror Claude/Codex workflow files one-for-one (see toolCapabilities deviation).'
    'command:design (opencode-only)'      = 'OpenCode pattern: a skill that is frequently invoked also gets a thin command/ wrapper for shorthand access. design and roundtable both follow this pattern. Claude+Codex invoke the skill directly without a command wrapper.'
    'command:roundtable (opencode-only)'  = 'OpenCode pattern: a skill that is frequently invoked also gets a thin command/ wrapper for shorthand access. design and roundtable both follow this pattern. Claude+Codex invoke the skill directly without a command wrapper.'
}

# --- Walk the matrix ---
foreach ($row in $matrix) {
    foreach ($tool in @('Claude','Codex','OpenCode')) {
        $rel = $row[$tool]
        if ($null -eq $rel) {
            # Deviation expected -- check it's in the documented list
            $key = $row.Id
            if ($deviations.ContainsKey($key)) {
                # Documented; ok
            } else {
                Bad "$($row.Id) [$tool] = null" 'no deviation entry justifies absence'
            }
            continue
        }
        $abs = Join-Path $pkg $rel
        if (Test-Path -LiteralPath $abs) {
            $script:pass++
        } else {
            Bad "$($row.Id) [$tool]" "expected file missing: $rel"
        }
    }
}

# --- Discover unexpected files (files in tool templates not in the matrix) ---
# Build the expected-paths set from the matrix
$expected = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($row in $matrix) {
    foreach ($tool in @('Claude','Codex','OpenCode')) {
        if ($row[$tool]) { [void]$expected.Add($row[$tool].ToLower().Replace('\','/')) }
    }
}

# Walk the actual files
$toolRoots = @(
    'templates/claude/.claude'
    'templates/codex/.Codex'
    'templates/opencode/.opencode'
    'overlays/perforce/.claude'
    'overlays/perforce/.Codex'
    'overlays/ue/.claude'
    'overlays/ue/.Codex'
    'overlays/ue/.opencode'
    'overlays/myst-project/.claude'
    'overlays/myst-project/.Codex'
    'overlays/myst-project/.opencode'
)
foreach ($root in $toolRoots) {
    $abs = Join-Path $pkg $root
    if (-not (Test-Path -LiteralPath $abs)) { continue }
    $files = Get-ChildItem -Path $abs -Recurse -File -Filter '*.md'
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($pkg.Length).TrimStart('\','/').Replace('\','/').ToLower()
        # Strip any leading "templates/" or "overlays/" so we compare lowercase normalized
        if (-not $expected.Contains($rel)) {
            # Allow CLAUDE.md / AGENTS.md at template root
            if ($rel -in @('templates/claude/claude.md', 'templates/codex/agents.md')) { continue }
            Bad 'unexpected file' "$rel is in a tool dir but not in the parity matrix; add to matrix or document"
        }
    }
}

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Parity tests: {0} pass, {1} fail" -f $pass, $fail)
Write-Host '=============================================================='
if ($fail -gt 0) {
    Write-Host ''
    Write-Host 'If failures indicate intentional asymmetry, add the item to'
    Write-Host '$deviations in this script with a one-line justification.'
    Write-Host 'Otherwise, copy the missing file across so parity holds.'
    exit 1
}
exit 0
