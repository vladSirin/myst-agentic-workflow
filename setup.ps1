# setup.ps1 -- one-command install for a brand-new consumer
#
# Wraps init-consumer.ps1 + install.ps1 + sensible defaults so a new adopter
# can land the scaffold without hand-authoring a bootstrap manifest.
#
# Auto-detection:
#   -- TargetRoot defaults to current directory
#   -- ProjectName defaults to Split-Path -Leaf of TargetRoot
#   -- VersionControl auto-detected: 'perforce' if TargetRoot contains .p4ignore
#      or sits in a p4 client, 'git' if a .git dir exists, else 'filesystem'
#   -- Overlays auto-include 'ue-perforce' when VersionControl='perforce'
#
# Flow:
#   1. If no installed manifest exists -> call init-consumer.ps1 (writes bootstrap)
#   2. Call install.ps1 -Mode DryRun, show the change summary
#   3. Prompt for write (skip prompt if -Yes); else call install.ps1 -Mode Write
#
# Exit codes:
#   0 : installed cleanly
#   1 : user declined to proceed at the prompt
#   2 : a step failed (bootstrap, preflight, or install)
param(
    [string] $TargetRoot      = '',
    [string] $ProjectName     = '',
    [string] $DocsRoot        = 'Docs',
    [string] $GameDocsRoot    = '',
    [ValidateSet('','perforce','git','filesystem')]
    [string] $VersionControl  = '',
    [string] $Tools           = 'all',
    [string] $Overlays        = '',
    [switch] $Yes,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '0.1.0-setup'
$PkgRoot = $PSScriptRoot

# --- Resolve TargetRoot ---
if ([string]::IsNullOrWhiteSpace($TargetRoot)) {
    $TargetRoot = (Get-Location).Path
    Write-Host "TargetRoot not specified -- defaulting to current directory: $TargetRoot"
}
if (-not (Test-Path -LiteralPath $TargetRoot)) {
    Write-Error "TargetRoot does not exist: $TargetRoot"
    exit 2
}
$TargetRoot = (Resolve-Path $TargetRoot).Path

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Split-Path $TargetRoot -Leaf
}
if ([string]::IsNullOrWhiteSpace($GameDocsRoot)) {
    $GameDocsRoot = "$ProjectName/$DocsRoot"
}

# --- Auto-detect VersionControl ---
if ([string]::IsNullOrWhiteSpace($VersionControl)) {
    if (Test-Path (Join-Path $TargetRoot '.p4ignore')) {
        $VersionControl = 'perforce'
    } else {
        $p4Info = & p4 -F "%clientRoot%" -ztag info 2>$null
        if ($LASTEXITCODE -eq 0 -and $p4Info -and $TargetRoot.ToLower().StartsWith(([string]$p4Info).ToLower())) {
            $VersionControl = 'perforce'
        } elseif (Test-Path (Join-Path $TargetRoot '.git')) {
            $VersionControl = 'git'
        } else {
            $VersionControl = 'filesystem'
        }
    }
}

# --- Default overlays per VC type + UE detection ---
if ([string]::IsNullOrWhiteSpace($Overlays)) {
    $parts = @('core')
    if ($VersionControl -eq 'perforce') { $parts += 'perforce' }
    # UE detection: .uproject in TargetRoot (top-level or one subdir deep, the
    # common UE pattern of <Root>/<GameName>/<GameName>.uproject).
    $uproj = @(Get-ChildItem -Path $TargetRoot -Filter '*.uproject' -File -ErrorAction SilentlyContinue -Depth 1) | Select-Object -First 1
    if ($uproj) { $parts += 'ue' }
    $Overlays = $parts -join ','
}

# --- Banner ---
Write-Host ""
Write-Host "=============================================================="
Write-Host "myst-agentic-workflow setup.ps1  v$ScriptVersion"
Write-Host "=============================================================="
Write-Host ("Package        : {0}" -f $PkgRoot)
Write-Host ("Target         : {0}" -f $TargetRoot)
Write-Host ("Project name   : {0}" -f $ProjectName)
Write-Host ("VersionControl : {0}  (auto-detected)" -f $VersionControl)
Write-Host ("DocsRoot       : {0}" -f $DocsRoot)
Write-Host ("GameDocsRoot   : {0}" -f $GameDocsRoot)
Write-Host ("Tools          : {0}" -f $Tools)
Write-Host ("Overlays       : {0}" -f $Overlays)
Write-Host "=============================================================="
Write-Host ""

# --- Step 1: bootstrap manifest if missing ---
$ManifestPath = Join-Path $TargetRoot 'Docs\agents\scaffold-manifest.json'
if (Test-Path -LiteralPath $ManifestPath) {
    Write-Host "[1/3] Manifest already exists at $ManifestPath -- skipping bootstrap."
} else {
    Write-Host "[1/3] No installed manifest found. Bootstrapping via init-consumer.ps1..."
    Write-Host ""
    $initArgs = @(
        '-TargetRoot', $TargetRoot
        '-PackageRoot', $PkgRoot
        '-ProjectName', $ProjectName
        '-DocsRoot', $DocsRoot
        '-GameDocsRoot', $GameDocsRoot
        '-VersionControl', $VersionControl
        '-Tools', $Tools
        '-Overlays', $Overlays
    )
    if ($Force) { $initArgs += '-Force' }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PkgRoot 'scripts\init-consumer.ps1') @initArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "init-consumer failed (exit $LASTEXITCODE). Aborting."
        exit 2
    }
}

# --- Step 2: dry-run preview ---
Write-Host ""
Write-Host "[2/3] Running install.ps1 -Mode DryRun (preview)..."
Write-Host ""
$dryArgs = @(
    '-TargetRoot', $TargetRoot
    '-PackageRoot', $PkgRoot
    '-Tools', $Tools
    '-Overlays', $Overlays
    '-Mode', 'DryRun'
)
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PkgRoot 'scripts\install.ps1') @dryArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Dry-run install failed (exit $LASTEXITCODE). Aborting before write."
    exit 2
}

# --- Step 3: confirm + write ---
Write-Host ""
Write-Host "=============================================================="
if (-not $Yes) {
    $reply = Read-Host "[3/3] Proceed to -Mode Write? [y/N]"
    if ($reply -notmatch '^(y|yes)$') {
        Write-Host "Declined. Re-run with -Yes to skip this prompt, or rerun setup later."
        exit 1
    }
} else {
    Write-Host "[3/3] -Yes specified -- proceeding to write."
}
Write-Host "=============================================================="
Write-Host ""

$writeArgs = @(
    '-TargetRoot', $TargetRoot
    '-PackageRoot', $PkgRoot
    '-Tools', $Tools
    '-Overlays', $Overlays
    '-Mode', 'Write'
)
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PkgRoot 'scripts\install.ps1') @writeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Write-mode install failed (exit $LASTEXITCODE)."
    exit 2
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "Setup complete."
Write-Host "=============================================================="
Write-Host "Next steps:"
Write-Host "  - Review the changes (git diff / p4 opened) before submitting."
Write-Host "  - Read docs/install.md for update / promote workflows."
if ($VersionControl -eq 'perforce') {
    Write-Host "  - Read docs/perforce-consumer.md for UE+P4 specifics."
}
Write-Host ""
exit 0
