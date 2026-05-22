# update.ps1 -- one-command sync from upstream package into a consumer
#
# Pulls the latest package, compares it to the consumer's installed scaffold,
# previews the changes via dry-run, prompts before writing (unless -Yes), then
# writes -- with Perforce CL wrapping if the consumer's manifest declares
# versionControl='perforce'.
#
# Reads the consumer's existing manifest to derive Tools / Overlays so you
# don't have to repeat what was chosen at setup time. The same overlays
# (and tools) that were installed are what we update.
#
# Exit codes:
#   0 : updated cleanly (or nothing to do)
#   1 : user declined at the write prompt
#   2 : a step failed (git pull, compare, preflight, or install)
param(
    [string] $TargetRoot      = '',
    [string] $PackageRoot     = '',
    [switch] $NoPull,
    [switch] $Yes
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '0.1.0-update'
if ([string]::IsNullOrWhiteSpace($PackageRoot)) { $PackageRoot = $PSScriptRoot }

# --- Resolve TargetRoot ---
if ([string]::IsNullOrWhiteSpace($TargetRoot)) {
    $TargetRoot = (Get-Location).Path
    Write-Host "TargetRoot not specified -- defaulting to current directory: $TargetRoot"
}
if (-not (Test-Path -LiteralPath $TargetRoot)) {
    Write-Error "TargetRoot does not exist: $TargetRoot"; exit 2
}
$TargetRoot = (Resolve-Path $TargetRoot).Path

# --- Read consumer manifest to derive tools + overlays + VC ---
$manPath = Join-Path $TargetRoot 'Docs\agents\scaffold-manifest.json'
if (-not (Test-Path -LiteralPath $manPath)) {
    Write-Error @"
No installed manifest found at:
  $manPath

This consumer has never been installed. Run setup.ps1 first:
  & '$PackageRoot/setup.ps1' -TargetRoot '$TargetRoot'
"@
    exit 2
}
$manBytes = [IO.File]::ReadAllBytes($manPath)
if ($manBytes.Length -ge 3 -and $manBytes[0] -eq 0xEF) { $manBytes = $manBytes[3..($manBytes.Length-1)] }
$man = [Text.Encoding]::UTF8.GetString($manBytes) | ConvertFrom-Json

# Tools: distinct values from manifest.files (excluding 'common')
$tools = @($man.files | ForEach-Object { $_.tool } | Where-Object { $_ -and $_ -ne 'common' } | Sort-Object -Unique)
if ($tools.Count -eq 0) { $tools = @('codex','claude','opencode') }
$Tools = $tools -join ','

# Overlays: distinct ownerOverlay (excluding nulls and 'core' which is implicit)
$overlays = @($man.files | ForEach-Object { $_.ownerOverlay } | Where-Object { $_ } | Sort-Object -Unique)
if ($overlays -notcontains 'core') { $overlays = @('core') + $overlays }
$Overlays = $overlays -join ','

$VersionControl = if ($man.installedProject.PSObject.Properties.Match('versionControl').Count -gt 0) {
                      $man.installedProject.versionControl
                  } else { 'filesystem' }

# --- Banner ---
Write-Host ""
Write-Host "=============================================================="
Write-Host "myst-agentic-workflow update.ps1  v$ScriptVersion"
Write-Host "=============================================================="
Write-Host ("Package        : {0}" -f $PackageRoot)
Write-Host ("Target         : {0}" -f $TargetRoot)
Write-Host ("VersionControl : {0}  (from installed manifest)" -f $VersionControl)
Write-Host ("Tools          : {0}  (from installed manifest)" -f $Tools)
Write-Host ("Overlays       : {0}  (from installed manifest)" -f $Overlays)
Write-Host "=============================================================="
Write-Host ""

# --- Step 1: git pull (unless -NoPull) ---
if (-not $NoPull) {
    Write-Host "[1/4] Refreshing package clone (git pull)..."
    Push-Location $PackageRoot
    try {
        & git pull 2>&1 | ForEach-Object { Write-Host "  $_" }
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git pull failed in $PackageRoot. Resolve manually and rerun, or pass -NoPull to skip."
            exit 2
        }
    } finally { Pop-Location }
} else {
    Write-Host "[1/4] -NoPull set; skipping git pull."
}

# --- Step 2: compare-with-package ---
Write-Host ""
Write-Host "[2/4] Cross-repo drift check (compare-with-package)..."
Write-Host ""
$cmp = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageRoot 'scripts\compare-with-package.ps1') `
    -TargetRoot $TargetRoot -PackageRoot $PackageRoot
$cmpCode = $LASTEXITCODE
$cmp | ForEach-Object { Write-Host $_ }
if ($cmpCode -ne 0) {
    Write-Host ""
    Write-Host "Compare reported conflicts (exit $cmpCode). Resolve them before -Mode Write." -ForegroundColor Yellow
    Write-Host "Conflicts are the 'BOTH sides moved' case -- see docs/install.md sec3."
    Write-Host "Aborting update."
    exit 2
}

# --- Step 3: dry-run install ---
Write-Host ""
Write-Host "[3/4] Dry-run install (preview)..."
Write-Host ""
$dryArgs = @(
    '-TargetRoot', $TargetRoot, '-PackageRoot', $PackageRoot,
    '-Tools', $Tools, '-Overlays', $Overlays, '-Mode', 'DryRun'
)
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageRoot 'scripts\install.ps1') @dryArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Dry-run install failed (exit $LASTEXITCODE). Aborting."
    exit 2
}

# --- Step 4: confirm + write ---
Write-Host ""
Write-Host "=============================================================="
if (-not $Yes) {
    $reply = Read-Host "[4/4] Apply changes via -Mode Write? [y/N]"
    if ($reply -notmatch '^(y|yes)$') {
        Write-Host "Declined. Re-run with -Yes to skip this prompt."
        exit 1
    }
} else {
    Write-Host "[4/4] -Yes specified -- proceeding to write."
}
Write-Host "=============================================================="
Write-Host ""

$writeArgs = @(
    '-TargetRoot', $TargetRoot, '-PackageRoot', $PackageRoot,
    '-Tools', $Tools, '-Overlays', $Overlays, '-Mode', 'Write'
)
if ($VersionControl -eq 'perforce') {
    $writeArgs += @('-UsePerforce', '-Changelist', 'new')
    Write-Host "Perforce detected: wrapping in -UsePerforce -Changelist new"
    Write-Host ""
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageRoot 'scripts\install.ps1') @writeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Write-mode install failed (exit $LASTEXITCODE)."
    exit 2
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "Update complete."
Write-Host "=============================================================="
if ($VersionControl -eq 'perforce') {
    Write-Host "Next: review the resulting P4 changelist, then 'p4 submit -c <CL#>'"
} else {
    Write-Host "Next: review the working tree changes (git diff or your VC tool), commit."
}
exit 0
