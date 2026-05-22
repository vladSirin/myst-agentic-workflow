# enable-strict-mode.ps1 -- merge strict-mode hooks into .claude/settings.local.json
#
# Strict mode enforces the CL-by-CL HARD RULE via Claude Code PreToolUse hooks:
# every `p4 submit -c <N>` requires .scratch/.approved-cl-<N>.marker to be
# present before the submit can run. The marker is created by the agent after
# the user explicitly approves the CL; it's auto-deleted after the submit so
# each approval is one-shot.
#
# This script writes/merges the hook configuration into
# .claude/settings.local.json (NOT settings.json -- the .local variant is
# per-machine, not checked into VC, which is correct for hook config).
#
# Idempotent: re-running adds nothing new. Safe to run after every update.ps1.
#
# Exit codes:
#   0 : strict mode enabled (settings.local.json now has the hooks)
#   1 : declined by user at the merge-confirmation prompt
#   2 : error (missing prerequisite, can't parse existing JSON, etc.)
param(
    [string] $TargetRoot = '',
    [switch] $Yes,
    [switch] $Disable
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '0.1.0-strict-mode'

# --- Resolve TargetRoot ---
if ([string]::IsNullOrWhiteSpace($TargetRoot)) {
    $TargetRoot = (Get-Location).Path
    Write-Host "TargetRoot not specified -- defaulting to current directory: $TargetRoot"
}
if (-not (Test-Path -LiteralPath $TargetRoot)) {
    Write-Error "TargetRoot does not exist: $TargetRoot"; exit 2
}
$TargetRoot = (Resolve-Path $TargetRoot).Path

# --- Prerequisite: hook scripts must be installed in the consumer ---
$hookDir = Join-Path $TargetRoot '.claude\scripts\hooks'
$blockHook   = Join-Path $hookDir 'block-unapproved-submit.ps1'
$cleanupHook = Join-Path $hookDir 'cleanup-approved-cl.ps1'

if (-not $Disable) {
    if (-not (Test-Path -LiteralPath $blockHook)) {
        Write-Error @"
Hook scripts not found at:
  $hookDir

These ship with the package and are installed by setup.ps1 / update.ps1 as
part of the .claude/ template. Run update.ps1 first, then re-run this script.
"@
        exit 2
    }
}

$settingsPath = Join-Path $TargetRoot '.claude\settings.local.json'

# --- Load existing settings (or create empty) ---
$existing = $null
if (Test-Path -LiteralPath $settingsPath) {
    try {
        $existing = Get-Content -Raw $settingsPath | ConvertFrom-Json
    } catch {
        Write-Error "Failed to parse $settingsPath as JSON: $($_.Exception.Message)"
        exit 2
    }
} else {
    # File doesn't exist; we'll create it
    $existing = [pscustomobject]@{}
}

# --- Strict-mode hook block ---
$preToolUseBlock = [pscustomobject]@{
    matcher = 'Bash'
    hooks   = @(
        [pscustomobject]@{
            type    = 'command'
            command = 'powershell -NoProfile -ExecutionPolicy Bypass -File .claude/scripts/hooks/block-unapproved-submit.ps1'
        }
    )
}
$postToolUseBlock = [pscustomobject]@{
    matcher = 'Bash'
    hooks   = @(
        [pscustomobject]@{
            type    = 'command'
            command = 'powershell -NoProfile -ExecutionPolicy Bypass -File .claude/scripts/hooks/cleanup-approved-cl.ps1'
        }
    )
}

# --- Merge in or remove ---
if ($Disable) {
    # Find any hook entries pointing at our scripts and remove
    if ($existing.PSObject.Properties.Match('hooks').Count -gt 0) {
        foreach ($evt in @('PreToolUse','PostToolUse')) {
            if ($existing.hooks.PSObject.Properties.Match($evt).Count -gt 0) {
                $kept = @($existing.hooks.$evt | Where-Object {
                    $allCmds = @($_.hooks | ForEach-Object { $_.command })
                    -not ($allCmds -join ' ' -match 'block-unapproved-submit\.ps1|cleanup-approved-cl\.ps1')
                })
                $existing.hooks.$evt = $kept
            }
        }
        Write-Host "Strict-mode hooks removed from $settingsPath."
    } else {
        Write-Host "No hooks block present; nothing to disable."
    }
} else {
    # Ensure hooks branch exists
    if ($existing.PSObject.Properties.Match('hooks').Count -eq 0) {
        $existing | Add-Member -NotePropertyName 'hooks' -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    foreach ($evt in @(@('PreToolUse', $preToolUseBlock), @('PostToolUse', $postToolUseBlock))) {
        $evtName = $evt[0]; $block = $evt[1]
        if ($existing.hooks.PSObject.Properties.Match($evtName).Count -eq 0) {
            $existing.hooks | Add-Member -NotePropertyName $evtName -NotePropertyValue @() -Force
        }
        # Check if our hook is already present (idempotency)
        $alreadyPresent = $false
        foreach ($h in @($existing.hooks.$evtName)) {
            if ($h -and $h.PSObject.Properties.Match('hooks').Count -gt 0) {
                $cmds = @($h.hooks | ForEach-Object { $_.command })
                if (($cmds -join ' ') -match 'block-unapproved-submit\.ps1|cleanup-approved-cl\.ps1') {
                    if ($evtName -eq 'PreToolUse'  -and ($cmds -join ' ') -match 'block-unapproved-submit') { $alreadyPresent = $true }
                    if ($evtName -eq 'PostToolUse' -and ($cmds -join ' ') -match 'cleanup-approved-cl')    { $alreadyPresent = $true }
                }
            }
        }
        if (-not $alreadyPresent) {
            $existing.hooks.$evtName = @($existing.hooks.$evtName) + $block
        }
    }
}

# --- Confirm + write ---
$newJson = $existing | ConvertTo-Json -Depth 20

Write-Host ""
Write-Host "=============================================================="
Write-Host "enable-strict-mode.ps1  v$ScriptVersion"
Write-Host "=============================================================="
Write-Host ("Target           : {0}" -f $TargetRoot)
Write-Host ("Settings file    : {0}" -f $settingsPath)
Write-Host ("Action           : {0}" -f $(if ($Disable) { 'DISABLE' } else { 'ENABLE' }))
Write-Host "=============================================================="
Write-Host ""

if (-not $Yes) {
    $reply = Read-Host "Proceed to write merged settings.local.json? [y/N]"
    if ($reply -notmatch '^(y|yes)$') {
        Write-Host "Declined. Re-run with -Yes to skip this prompt."
        exit 1
    }
}

# Ensure directory exists
$settingsDir = Split-Path $settingsPath -Parent
if (-not (Test-Path -LiteralPath $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

[IO.File]::WriteAllText($settingsPath, $newJson, [Text.Encoding]::UTF8)

Write-Host ""
Write-Host "=============================================================="
if ($Disable) {
    Write-Host "Strict mode DISABLED."
    Write-Host "p4 submit commands will no longer require approval markers."
} else {
    Write-Host "Strict mode ENABLED."
    Write-Host ""
    Write-Host "From this point, every 'p4 submit -c <CL>' in this project will"
    Write-Host "be blocked unless preceded by an explicit user approval recorded"
    Write-Host "as .scratch/.approved-cl-<CL>.marker."
    Write-Host ""
    Write-Host "Agent workflow:"
    Write-Host "  1. Agent prepares a CL"
    Write-Host "  2. Agent surfaces CL contents to you for review"
    Write-Host "  3. You explicitly approve"
    Write-Host "  4. Agent creates .scratch/.approved-cl-<N>.marker"
    Write-Host "  5. Agent runs p4 submit -c <N>"
    Write-Host "  6. Marker auto-deleted by PostToolUse companion hook"
    Write-Host ""
    Write-Host "To disable: re-run this script with -Disable."
}
Write-Host "=============================================================="
exit 0
