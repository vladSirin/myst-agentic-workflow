# promote.ps1 -- one-command promotion of local improvements upstream
#
# Wraps the dry-run + write sequence of scripts/promote-from-project.ps1.
# Auto-infers classification per path from the consumer's manifest when
# possible, so the user only has to provide explicit -Classification for
# paths that aren't already manifest-tracked.
#
# Classification inference (when omitted):
#   owner=package, ownerOverlay=core           -> reusable-core
#   ownerOverlay=perforce                      -> perforce-overlay
#   ownerOverlay=ue                            -> ue-overlay
#   ownerOverlay=myst-project                  -> myst-project-overlay
#   ownerOverlay=ue-perforce (legacy)          -> ue-perforce-overlay
#   not in manifest                            -> ERROR; pass -Classification
#
# Exit codes:
#   0 : promoted cleanly to the package working tree
#   1 : user declined at the write prompt
#   2 : a step failed
param(
    [Parameter(Mandatory=$true)] [string[]] $Paths,
    [string[]] $Classification = @(),
    [string]   $TargetRoot     = '',
    [string]   $PackageRoot    = '',
    [switch]   $Yes,
    # -Force forwards promote-from-project.ps1's upstream-divergence override.
    # It used to be hard-coded on every write, silently bypassing that refusal
    # (audit 2026-08-06); now it is a deliberate choice.
    [switch]   $Force,
    # Proceed even when the clone is behind origin/main (freshness gate below).
    [switch]   $AllowStale
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '0.1.0-promote'
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

# --- Infer classifications from the consumer manifest ---
$manPath = Join-Path $TargetRoot 'Docs\agents\scaffold-manifest.json'
$manifestByPath = @{}
if (Test-Path -LiteralPath $manPath) {
    $manBytes = [IO.File]::ReadAllBytes($manPath)
    if ($manBytes.Length -ge 3 -and $manBytes[0] -eq 0xEF) { $manBytes = $manBytes[3..($manBytes.Length-1)] }
    $man = [Text.Encoding]::UTF8.GetString($manBytes) | ConvertFrom-Json
    foreach ($e in $man.files) { $manifestByPath[$e.path.Replace('\','/')] = $e }
}

function Resolve-Classification($path) {
    $k = $path.Replace('\','/')
    if (-not $manifestByPath.ContainsKey($k)) { return $null }
    $e = $manifestByPath[$k]
    $owner   = $e.owner
    $overlay = $e.ownerOverlay
    if ($owner -eq 'package' -and $overlay -eq 'core') { return 'reusable-core' }
    switch ($overlay) {
        'perforce'      { return 'perforce-overlay' }
        'ue'            { return 'ue-overlay' }
        'myst-project'  { return 'myst-project-overlay' }
        'ue-perforce'   { return 'ue-perforce-overlay' }   # legacy
    }
    return $null
}

# Build classification array, filling gaps from manifest inference
$resolved = @()
$inferred = @()
for ($i = 0; $i -lt $Paths.Count; $i++) {
    $p = $Paths[$i]
    $c = if ($Classification.Count -gt $i -and $Classification[$i]) { $Classification[$i] } else { '' }
    if (-not $c) {
        $c = Resolve-Classification $p
        if ($c) { $inferred += "$p -> $c" }
        else {
            Write-Host ""
            Write-Host "ERROR: Cannot infer classification for path: $p" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "The path is not in the consumer's manifest, so we don't know whether it's"
            Write-Host "generic (reusable-core), Perforce-only (perforce-overlay), UE-only"
            Write-Host "(ue-overlay), or project-specific (myst-project-overlay)."
            Write-Host ""
            Write-Host "Provide -Classification explicitly for each path, e.g.:"
            Write-Host "  & '$PSScriptRoot/promote.ps1' -Paths `"$p`" -Classification `"reusable-core`""
            Write-Host ""
            exit 2
        }
    }
    $resolved += $c
}

# --- Banner ---
Write-Host ""
Write-Host "=============================================================="
Write-Host "myst-agentic-workflow promote.ps1  v$ScriptVersion"
Write-Host "=============================================================="
Write-Host ("Package : {0}" -f $PackageRoot)
Write-Host ("Target  : {0}" -f $TargetRoot)
Write-Host "Paths   :"
for ($i = 0; $i -lt $Paths.Count; $i++) {
    $tag = if ($inferred -contains "$($Paths[$i]) -> $($resolved[$i])") { '(inferred)' } else { '(explicit)' }
    Write-Host ("  {0,-50} -> {1,-22} {2}" -f $Paths[$i], $resolved[$i], $tag)
}
Write-Host "=============================================================="
Write-Host ""

# --- Step 0: freshness gate ---
# Promoting from a stale clone silently overwrites newer upstream template
# content in the working tree (audit 2026-08-06). Fetch, then refuse when the
# clone is behind origin/main; -AllowStale overrides deliberately.
Write-Host "[0/3] Freshness check (git fetch)..."
$fetchOk = $false; $behind = 0
$prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
try {
    Push-Location $PackageRoot
    try {
        & git fetch origin 2>&1 | Out-Null
        $fetchOk = ($LASTEXITCODE -eq 0)
        if ($fetchOk) {
            $counts = & git rev-list --left-right --count 'HEAD...origin/main' 2>$null
            if ($LASTEXITCODE -eq 0 -and "$counts" -match '^\s*(\d+)\s+(\d+)') { $behind = [int]$Matches[2] }
        }
    } finally { Pop-Location }
} finally { $ErrorActionPreference = $prevEap }
if (-not $fetchOk) {
    Write-Host "  WARNING: git fetch failed (offline?). Proceeding against the local clone;" -ForegroundColor Yellow
    Write-Host "  verify freshness manually before opening a PR." -ForegroundColor Yellow
} elseif ($behind -gt 0) {
    if ($AllowStale) {
        Write-Host "  Clone is $behind commit(s) behind origin/main; -AllowStale set, continuing." -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "ERROR: package clone is $behind commit(s) behind origin/main." -ForegroundColor Yellow
        Write-Host "Promoting now could overwrite newer upstream content. Update first:"
        Write-Host "  git -C '$PackageRoot' pull"
        Write-Host "or pass -AllowStale to proceed deliberately."
        exit 2
    }
} else {
    Write-Host "  Clone is up to date with origin/main."
}
Write-Host ""

# --- Step 1: dry-run promote ---
Write-Host "[1/3] Dry-run promote (preview)..."
Write-Host ""
$dryArgs = @(
    '-TargetRoot', $TargetRoot, '-PackageRoot', $PackageRoot,
    '-Paths') + $Paths + @('-Classification') + $resolved + @('-Mode','DryRun')
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageRoot 'scripts\promote-from-project.ps1') @dryArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Dry-run promote failed (exit $LASTEXITCODE). Aborting."
    exit 2
}

# --- Step 2: confirm + write ---
Write-Host ""
Write-Host "=============================================================="
$forceNote = if ($Force) { ' -Force' } else { '' }
if (-not $Yes) {
    $reply = Read-Host "[2/3] Promote to package via -Mode Write$forceNote? [y/N]"
    if ($reply -notmatch '^(y|yes)$') {
        Write-Host "Declined. Re-run with -Yes to skip this prompt."
        exit 1
    }
} else {
    Write-Host "[2/3] -Yes specified -- proceeding to write."
}
Write-Host "=============================================================="
Write-Host ""

$writeArgs = @(
    '-TargetRoot', $TargetRoot, '-PackageRoot', $PackageRoot,
    '-Paths') + $Paths + @('-Classification') + $resolved + @('-Mode','Write')
if ($Force) { $writeArgs += '-Force' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PackageRoot 'scripts\promote-from-project.ps1') @writeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "If the refusal was 'upstream divergence', review the package-side change," -ForegroundColor Yellow
    Write-Host "merge your edit on top of it, or re-run with -Force to overwrite deliberately." -ForegroundColor Yellow
    Write-Error "Write-mode promote failed (exit $LASTEXITCODE)."
    exit 2
}

Write-Host ""
Write-Host "=============================================================="
Write-Host "Promotion complete -- package working tree updated."
Write-Host "=============================================================="
Write-Host "Next steps:"
Write-Host "  cd $PackageRoot"
Write-Host "  git diff                    # eyeball the change"
Write-Host "  git checkout -b improve-<topic>"
Write-Host "  git add -A; git commit -m 'improve: <message>'"
Write-Host "  git push -u origin improve-<topic>"
Write-Host "  gh pr create --fill         # or merge straight to main"
Write-Host "  # bump CHANGELOG.md + package-manifest.json + tag if publishing"
Write-Host ""
exit 0
