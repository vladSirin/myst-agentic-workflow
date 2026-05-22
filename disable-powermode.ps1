# disable-powermode.ps1 -- deactivate powermode early (removes the marker)
#
# Companion to enable-powermode.ps1. Removes the .scratch/.powermode.marker so
# the per-CL approval gate is back in force.
#
# Exit codes:
#   0 : marker removed (or never existed -- idempotent)
#   1 : user declined at confirmation prompt
#   2 : runtime error
param(
    [string] $TargetRoot = '',
    [switch] $Yes
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($TargetRoot)) {
    $TargetRoot = (Get-Location).Path
}
if (-not (Test-Path -LiteralPath $TargetRoot)) {
    Write-Error "TargetRoot does not exist: $TargetRoot"; exit 2
}
$TargetRoot = (Resolve-Path $TargetRoot).Path

$markerPath = Join-Path $TargetRoot '.scratch\.powermode.marker'

if (-not (Test-Path -LiteralPath $markerPath)) {
    Write-Host "Powermode: already inactive (no marker at $markerPath). Nothing to do."
    exit 0
}

if (-not $Yes) {
    $reply = Read-Host "Disable powermode now? [y/N]"
    if ($reply -notmatch '^(y|yes)$') {
        Write-Host "Declined."
        exit 1
    }
}

Remove-Item -LiteralPath $markerPath -Force
Write-Host "Powermode DEACTIVATED. Per-CL approval gate is back in force."
exit 0
