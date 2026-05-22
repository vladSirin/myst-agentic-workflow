# enable-powermode.ps1 -- grant batch CL-submit approval (count + time bounded)
#
# When strict mode is enabled (via enable-strict-mode.ps1), every `p4 submit
# -c <N>` requires a per-CL approval marker. That's too much friction for
# autonomous batch work like a /goal-driven bugfix sprint.
#
# Powermode is a separate marker that bypasses the per-CL check for a bounded
# number of submits within a bounded time window. The hook checks powermode
# first; if active and within quota, allows the submit and decrements the
# counter. Either limit tripping deactivates powermode automatically.
#
# Usage:
#   enable-powermode.ps1 -SubmitCount 5 -DurationMinutes 30 -Reason "bugfix"
#   enable-powermode.ps1 -SubmitCount 10                  # default 60 min
#   enable-powermode.ps1 -DurationMinutes 15              # no count limit; clock-only
#   enable-powermode.ps1 -Status                          # show current state
#
# Exit codes:
#   0 : powermode enabled (or status shown)
#   1 : user declined at confirmation prompt
#   2 : invalid args / runtime error
param(
    [string] $TargetRoot       = '',
    [int]    $SubmitCount      = 5,
    [int]    $DurationMinutes  = 60,
    [string] $Reason           = '',
    [switch] $Status,
    [switch] $Yes
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '0.1.0-powermode'

if ([string]::IsNullOrWhiteSpace($TargetRoot)) {
    $TargetRoot = (Get-Location).Path
}
if (-not (Test-Path -LiteralPath $TargetRoot)) {
    Write-Error "TargetRoot does not exist: $TargetRoot"; exit 2
}
$TargetRoot = (Resolve-Path $TargetRoot).Path

$markerPath = Join-Path $TargetRoot '.scratch\.powermode.marker'

# --- Status mode: just report current state and exit ---
if ($Status) {
    if (-not (Test-Path -LiteralPath $markerPath)) {
        Write-Host "Powermode: INACTIVE (no marker at $markerPath)"
        exit 0
    }
    $pm = Get-Content -Raw $markerPath | ConvertFrom-Json
    $now = (Get-Date).ToUniversalTime()
    $expires = $null
    $expired = $false
    if ($pm.PSObject.Properties.Match('expiresAt').Count -gt 0 -and $pm.expiresAt) {
        try { $expires = [datetime]::Parse($pm.expiresAt).ToUniversalTime() } catch {}
        if ($expires -and $now -ge $expires) { $expired = $true }
    }
    $remaining = if ($pm.PSObject.Properties.Match('submitsRemaining').Count -gt 0) { $pm.submitsRemaining } else { 'unlimited' }
    Write-Host "Powermode marker: $markerPath"
    Write-Host ("  submitsRemaining : {0}" -f $remaining)
    Write-Host ("  expiresAt        : {0}  (UTC)" -f $pm.expiresAt)
    Write-Host ("  reason           : {0}" -f $pm.reason)
    Write-Host ("  status           : {0}" -f $(if ($expired) { 'EXPIRED' } elseif ($remaining -is [int] -and $remaining -le 0) { 'EXHAUSTED' } else { 'ACTIVE' }))
    exit 0
}

# --- Validate bounds ---
if ($SubmitCount -lt 1)     { Write-Error "-SubmitCount must be >= 1 (got $SubmitCount)"; exit 2 }
if ($DurationMinutes -lt 1) { Write-Error "-DurationMinutes must be >= 1 (got $DurationMinutes)"; exit 2 }
if ($SubmitCount -gt 100)   { Write-Error "-SubmitCount > 100 looks like a mistake (got $SubmitCount). Cap is informational; re-run with -Yes if intended."; if (-not $Yes) { exit 2 } }
if ($DurationMinutes -gt 480) { Write-Error "-DurationMinutes > 480 (8 hours) looks excessive. Cap is informational; re-run with -Yes if intended."; if (-not $Yes) { exit 2 } }

$expiresAt = (Get-Date).ToUniversalTime().AddMinutes($DurationMinutes).ToString("yyyy-MM-ddTHH:mm:ss") + 'Z'

$pm = [pscustomobject]@{
    enabled          = $true
    submitsRemaining = $SubmitCount
    expiresAt        = $expiresAt
    reason           = if ($Reason) { $Reason } else { '(no reason given)' }
    createdAt        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") + 'Z'
}

# --- Banner + confirmation ---
Write-Host ""
Write-Host "=============================================================="
Write-Host "enable-powermode.ps1  v$ScriptVersion"
Write-Host "=============================================================="
Write-Host ("Target           : {0}" -f $TargetRoot)
Write-Host ("Submits granted  : {0}" -f $SubmitCount)
Write-Host ("Duration         : {0} minute(s)  (expires {1} UTC)" -f $DurationMinutes, $expiresAt)
Write-Host ("Reason           : {0}" -f $pm.reason)
Write-Host "=============================================================="
Write-Host ""

if (-not $Yes) {
    $reply = Read-Host "Enable powermode? (allows up to $SubmitCount submits without per-CL approval) [y/N]"
    if ($reply -notmatch '^(y|yes)$') {
        Write-Host "Declined. Re-run with -Yes to skip this prompt."
        exit 1
    }
}

# --- Write marker ---
$scratchDir = Join-Path $TargetRoot '.scratch'
if (-not (Test-Path -LiteralPath $scratchDir)) {
    New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null
}
$pm | ConvertTo-Json | Set-Content -LiteralPath $markerPath -Encoding UTF8

Write-Host ""
Write-Host "POWERMODE ACTIVE."
Write-Host ""
Write-Host "Up to $SubmitCount p4 submit -c <N> calls will skip the per-CL approval"
Write-Host "gate. Powermode auto-deactivates when:"
Write-Host "  - the counter hits 0 (after $SubmitCount submits), OR"
Write-Host "  - the expiry time passes (in $DurationMinutes minute(s))."
Write-Host ""
Write-Host "Disable early:    & '$PSScriptRoot/disable-powermode.ps1' -TargetRoot '$TargetRoot' -Yes"
Write-Host "Check status:     & '$PSScriptRoot/enable-powermode.ps1'  -TargetRoot '$TargetRoot' -Status"
exit 0
