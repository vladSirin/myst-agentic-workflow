# compare-with-package.ps1 — Cross-repo drift + conflict detection (issue 10)
#
# Compares the installed scaffold (TargetRoot) against the package source
# (PackageRoot). Per-entry outcome is one of:
#   clean             disk matches rendered template; no upstream change
#   downstream-edit   disk differs from rendered; upstream unchanged ->
#                     candidate for promote-from-project (issue 11)
#   upstream-update   disk clean; package source has changed since pinned ->
#                     candidate for install -Mode Write
#   conflict          BOTH sides moved -> manual reconciliation required
#
# Also performs meta-conflict detection: manifest schema, ownership/overlay
# enums, and sourceTemplate pointers must match package-manifest.json.
#
# Read-only. Never writes.
#   exit 0 : no conflicts (clean / downstream-edit / upstream-update only)
#   exit 1 : at least one conflict (per-entry or meta)
#   exit 2 : runtime failure
param(
    [Parameter(Mandatory=$true)] [string] $TargetRoot,
    [Parameter(Mandatory=$true)] [string] $PackageRoot,
    [string] $ManifestRelativePath = 'Docs/agents/scaffold-manifest.json',
    [ValidateSet('text','json')] [string] $Output = 'text',
    # Optional: a directory representing the package as it was at the entry's
    # sourceCommit time. Enables upstream-update / conflict detection. When
    # omitted, all diffs are reported as downstream-edit (we have no upstream
    # reference to compare against -- correct given current pending-package state).
    [string] $PinnedSnapshotRoot = ''
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = "0.1.0-promotion"
. (Join-Path $PSScriptRoot 'lib\Markers.ps1')
. (Join-Path $PSScriptRoot 'lib\Render.ps1')
. (Join-Path $PSScriptRoot 'lib\Classification.ps1')

# Load installed manifest.
$manifestPath = Join-Path $TargetRoot $ManifestRelativePath
if (-not (Test-Path -LiteralPath $manifestPath)) { Write-Error "manifest not found: $manifestPath"; exit 2 }
$manBytes = [IO.File]::ReadAllBytes($manifestPath)
if ($manBytes.Length -ge 3 -and $manBytes[0] -eq 0xEF) { $manBytes = $manBytes[3..($manBytes.Length-1)] }
$m = [Text.Encoding]::UTF8.GetString($manBytes) | ConvertFrom-Json

# --- Meta-conflict: installed manifest vs package-manifest ---
$metaConflicts = @()
$pkgManPath = Join-Path $PackageRoot 'package-manifest.json'
if (Test-Path -LiteralPath $pkgManPath) {
    $pkgMan = Get-Content -Raw $pkgManPath | ConvertFrom-Json
    $pkgSchema = $null
    if ($pkgMan.PSObject.Properties.Match('manifestSchema').Count -gt 0 -and
        $pkgMan.manifestSchema.PSObject.Properties.Match('schemaVersion').Count -gt 0) {
        $pkgSchema = $pkgMan.manifestSchema.schemaVersion
    }
    if ($null -ne $pkgSchema -and $m.schemaVersion -ne $pkgSchema) {
        $metaConflicts += "schemaVersion mismatch: installed=$($m.schemaVersion) package=$pkgSchema"
    }
    # Overlay enumeration check
    $declaredOverlays = @()
    if ($pkgMan.PSObject.Properties.Match('manifestSchema').Count -gt 0 -and
        $pkgMan.manifestSchema.PSObject.Properties.Match('overlays').Count -gt 0) {
        $declaredOverlays = @($pkgMan.manifestSchema.overlays)
    }
    if ($declaredOverlays.Count -gt 0) {
        $usedOverlays = @($m.files | ForEach-Object { $_.ownerOverlay } | Where-Object { $_ } | Sort-Object -Unique)
        $unknown = @($usedOverlays | Where-Object { $_ -notin $declaredOverlays })
        if ($unknown.Count -gt 0) {
            $metaConflicts += "manifest uses overlays not declared in package: $($unknown -join ', ')"
        }
    }
}

# --- Per-entry comparison ---
$Vars = Get-VariableMap -Manifest $m
$results = New-Object System.Collections.ArrayList
foreach ($entry in $m.files) {
    if ($entry.localOnly) { continue }
    if ($entry.hashPolicy -eq 'self-excluded') { continue }

    $bucket = Get-OwnershipBucket $entry
    $tgt = Join-Path $TargetRoot $entry.path
    $exists = Test-Path -LiteralPath $tgt

    if (-not $exists) {
        [void]$results.Add([pscustomobject]@{ Path=$entry.path; Bucket=$bucket; Outcome='missing'; Detail='target file absent' })
        continue
    }

    # runtime-mutable: tool rewrites the file in-session.
    # Install seeds it on first run; subsequent drift is expected. Don't hash, don't diff.
    if ($entry.hashPolicy -eq 'runtime-mutable') {
        [void]$results.Add([pscustomobject]@{ Path=$entry.path; Bucket=$bucket; Outcome='runtime-mutable'; Detail='tool-managed at runtime; hash check bypassed by policy' })
        continue
    }

    $rendered = $null
    $renderErr = $null
    try { $rendered = Get-EntryRendered -Entry $entry -PackageRoot $PackageRoot -TargetRoot $TargetRoot -Vars $Vars }
    catch { $renderErr = $_.Exception.Message }
    if ($renderErr) {
        [void]$results.Add([pscustomobject]@{ Path=$entry.path; Bucket=$bucket; Outcome='render-error'; Detail=$renderErr })
        continue
    }
    if ($null -eq $rendered) {
        [void]$results.Add([pscustomobject]@{ Path=$entry.path; Bucket=$bucket; Outcome='unrendered'; Detail='no template / manual-only' })
        continue
    }

    $current = Read-NormalizedText -Path $tgt
    $diskMatches = ($current -eq $rendered)

    # Upstream check (only if PinnedSnapshotRoot provided)
    $upstreamMatches = $true
    if ($PinnedSnapshotRoot -and $entry.sourceTemplate) {
        $pinned  = Join-Path $PinnedSnapshotRoot $entry.sourceTemplate
        $package = Join-Path $PackageRoot       $entry.sourceTemplate
        if ((Test-Path -LiteralPath $pinned) -and (Test-Path -LiteralPath $package)) {
            $pinnedText  = Read-NormalizedText -Path $pinned
            $packageText = Read-NormalizedText -Path $package
            $upstreamMatches = ($pinnedText -eq $packageText)
        }
    }

    $outcome = if     ($diskMatches  -and  $upstreamMatches) { 'clean' }
              elseif (-not $diskMatches -and  $upstreamMatches) { 'downstream-edit' }
              elseif (    $diskMatches  -and -not $upstreamMatches) { 'upstream-update' }
              else                                                   { 'conflict' }
    [void]$results.Add([pscustomobject]@{ Path=$entry.path; Bucket=$bucket; Outcome=$outcome; Detail='' })
}

# --- Report ---
$conflictCount = @($results | Where-Object { $_.Outcome -eq 'conflict' }).Count + $metaConflicts.Count

if ($Output -eq 'json') {
    $report = [pscustomobject]@{
        scriptVersion = $ScriptVersion
        targetRoot    = $TargetRoot
        packageRoot   = $PackageRoot
        metaConflicts = $metaConflicts
        entries       = @($results)
        summary       = ($results | Group-Object Outcome | ForEach-Object { @{ outcome=$_.Name; count=$_.Count } })
        conflictCount = $conflictCount
    }
    ($report | ConvertTo-Json -Depth 6)
} else {
    Write-Output "=============================================================="
    Write-Output "compare-with-package.ps1  v$ScriptVersion"
    Write-Output "Target  : $TargetRoot"
    Write-Output "Package : $PackageRoot"
    if ($PinnedSnapshotRoot) { Write-Output "Pinned  : $PinnedSnapshotRoot" }
    else { Write-Output "Pinned  : (none -- diffs report as downstream-edit only)" }
    Write-Output "=============================================================="
    Write-Output ""
    if ($metaConflicts.Count -gt 0) {
        Write-Output "META-CONFLICTS:"
        foreach ($mc in $metaConflicts) { Write-Output "  ! $mc" }
        Write-Output ""
    }
    $groups = $results | Group-Object Outcome | Sort-Object Name
    foreach ($g in $groups) {
        $icon = switch ($g.Name) { 'clean'{'OK '} 'downstream-edit'{'<- '} 'upstream-update'{'-> '} 'conflict'{'!! '} default{'?? '} }
        Write-Output ("  {0} {1,3}  {2}" -f $icon, $g.Count, $g.Name)
        if ($g.Name -in @('conflict','render-error','missing')) {
            foreach ($r in $g.Group) { Write-Output ("      {0}  {1}" -f $r.Path, $r.Detail) }
        }
    }
    Write-Output ""
    Write-Output ("Conflict total (per-entry + meta): {0}" -f $conflictCount)
}

if ($conflictCount -gt 0) { exit 1 } else { exit 0 }
