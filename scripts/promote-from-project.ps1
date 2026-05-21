# promote-from-project.ps1 — myst-agentic-workflow promotion tool (skeleton phase)
# Copies proven downstream improvements back into the package. DryRun only until
# classification is provided for every path. Write mode is gated.
param(
    [Parameter(Mandatory=$true)]  [string] $TargetRoot,
    [Parameter(Mandatory=$true)]  [string[]] $Paths,
    [ValidateSet("reusable-core","perforce-overlay","ue-overlay","ue-perforce-overlay","myst-project-overlay","reject-local")]
    [string[]] $Classification = @(),
    [ValidateSet("DryRun","Write")] [string] $Mode = "DryRun",
    [string] $PackageRoot = $null,
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = "0.3.0-promotion-write"
. (Join-Path $PSScriptRoot 'lib\Classification.ps1')
. (Join-Path $PSScriptRoot 'lib\Markers.ps1')
. (Join-Path $PSScriptRoot 'lib\Render.ps1')
. (Join-Path $PSScriptRoot 'lib\InstallJournal.ps1')

Write-Output "=============================================================="
Write-Output "promote-from-project.ps1  v$ScriptVersion"
Write-Output "Target: $TargetRoot | Mode: $Mode"
Write-Output "=============================================================="

if (($Paths.Count -ne $Classification.Count) -or ($Classification.Count -eq 0)) {
    Write-Error @"
Each path requires a classification. Provide -Classification for each -Path.

Valid classifications:
  reusable-core           — generic, no project/VC assumptions; move into templates/
  perforce-overlay        — Perforce-specific (CL workflow); move into overlays/perforce/
  ue-overlay              — Unreal-Engine specific (build, p4ignore); move into overlays/ue/
  myst-project-overlay    — this-project specific; move into overlays/myst-project/
  ue-perforce-overlay     — DEPRECATED v1.2.0; use perforce-overlay or ue-overlay
  reject-local            — intentionally project-local; record reason in reject log

Usage:
  ./promote-from-project.ps1 -TargetRoot <path> `
    -Paths "file1.md","file2.md" `
    -Classification "reusable-core","perforce-overlay" `
    -Mode DryRun
"@
    exit 2
}

# Issue 09: derive ownership bucket from the manifest in addition to the
# caller-supplied -Classification (which becomes an override / hint).
$manifestPath = Join-Path $TargetRoot 'Docs/agents/scaffold-manifest.json'
$manifestByPath = @{}
if (Test-Path -LiteralPath $manifestPath) {
    $manBytes = [IO.File]::ReadAllBytes($manifestPath)
    if ($manBytes.Length -ge 3 -and $manBytes[0] -eq 0xEF) { $manBytes = $manBytes[3..($manBytes.Length-1)] }
    $manText = [System.Text.Encoding]::UTF8.GetString($manBytes)
    $man = $manText | ConvertFrom-Json
    foreach ($e in $man.files) { $manifestByPath[$e.path.Replace('\','/')] = $e }
}

# --- Validate each path exists + classify ---
$results = @()
for ($i = 0; $i -lt $Paths.Count; $i++) {
    $p = $Paths[$i]
    $c = $Classification[$i]
    $fp = Join-Path $TargetRoot $p
    $exists = Test-Path $fp

    $entry = $manifestByPath[$p.Replace('\','/')]
    $bucket = if ($entry) { Get-OwnershipBucket $entry } else { 'unmanaged' }
    $promotable = ($bucket -ne 'unmanaged') -and (Test-IsPromotable $bucket)
    $target = if ($entry) { Get-PromotionTarget $entry } else { $null }

    $status = if (-not $exists) { 'MISSING' }
        elseif ($c -eq 'reject-local') { 'REJECTED' }
        elseif (-not $promotable) { 'REFUSED' }
        else { 'READY to promote' }
    $detail = if (-not $exists) { 'file not found' }
        elseif ($c -eq 'reject-local') { 'intentionally local; must record reason' }
        elseif ($bucket -eq 'local-only') { 'local-only: never promote' }
        elseif ($bucket -eq 'project-owned') { 'project-owned: never promote' }
        elseif ($bucket -eq 'unmanaged') { 'no manifest entry; classify manually first' }
        else { "would copy to package -> $target" }

    $results += [PSCustomObject]@{
        Path           = $p
        Exists         = $exists
        Classification = $c
        Bucket         = $bucket
        Status         = $status
        Detail         = $detail
    }
}

foreach ($r in $results) {
    Write-Output ("  {0,-18} bucket={1,-13} path={2}" -f $r.Status, $r.Bucket, $r.Path)
    Write-Output ("    -> {0}" -f $r.Detail)
}

if ($Mode -eq "Write") {
    if (-not $PackageRoot) {
        Write-Error "-Mode Write requires -PackageRoot <path-to-package-source>"; exit 2
    }
    if (-not (Test-Path -LiteralPath $PackageRoot)) {
        Write-Error "PackageRoot not found: $PackageRoot"; exit 2
    }

    # Refuse any non-READY-to-promote entries (REFUSED / REJECTED / MISSING).
    $blockers = @($results | Where-Object { $_.Status -ne 'READY to promote' })
    if ($blockers.Count -gt 0) {
        Write-Error ("WRITE MODE REFUSED -- $($blockers.Count) entries are not promotable. See report above. " +
                     "Re-run with only promotable paths.")
        exit 2
    }

    # Build the substitution variable map from the installed manifest.
    if (-not $manifestByPath -or $manifestByPath.Count -eq 0) {
        Write-Error "Installed manifest is empty; cannot build substitution vars."; exit 2
    }
    $vars = Get-VariableMap -Manifest $man

    # Plan each write: extract source content, reverse-substitute, roundtrip-verify,
    # check upstream divergence (refuse without -Force), enqueue.
    $plans = @()
    foreach ($r in $results) {
        $entry = $manifestByPath[$r.Path.Replace('\','/')]
        $tgtFile = Join-Path $TargetRoot $r.Path
        $diskNormalized = Read-NormalizedText -Path $tgtFile

        # Extract the content that should become the package source.
        $contentToTemplatize = switch ($entry.mergeStrategy) {
            'copy'            { $diskNormalized }
            'generated-block' { Get-MarkerBlockContent -NormalizedText $diskNormalized -Id $entry.generatedBlockId -Style (Get-MarkerStyleForPath -Path $tgtFile) }
            'append-fragment' { Get-MarkerBlockContent -NormalizedText $diskNormalized -Id $entry.appendFragmentId -Style (Get-MarkerStyleForPath -Path $tgtFile) }
            default { throw "unsupported mergeStrategy for promotion: $($entry.mergeStrategy)" }
        }

        # Reverse-substitute concrete project values to {{vars}}.
        $newTplText = Reverse-SubstituteVars -Text $contentToTemplatize -Vars $vars

        # Roundtrip safety: rendering the new template forward MUST equal the
        # original disk-extracted content. Otherwise the reverse substitution
        # was ambiguous (e.g., literal substring that happened to match a var value).
        $reRendered = Expand-TemplateVars -Text $newTplText -Vars $vars
        if ($reRendered -ne $contentToTemplatize) {
            Write-Error ("Round-trip safety FAILED for '$($r.Path)': reverse-substitution introduced ambiguity. " +
                         "Refusing to write. Inspect the file for substring collisions with var values.")
            exit 2
        }

        # Upstream divergence check.
        $pkgTplRel = $entry.sourceTemplate
        if (-not $pkgTplRel) { Write-Error "no sourceTemplate for $($r.Path); cannot promote"; exit 2 }
        $pkgTplPath = Join-Path $PackageRoot $pkgTplRel
        if ((Test-Path -LiteralPath $pkgTplPath) -and -not $Force) {
            $current = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($pkgTplPath))
            $current = ($current -replace "`r`n","`n") -replace "`r","`n"
            if ($current -ne $newTplText) {
                # W1 (issue 15 review): clarify that divergence is EXPECTED for any
                # real promotion (the disk-derived template differs from current
                # upstream -- that's why we're promoting). -Force = user has
                # inspected the diff and accepts the overwrite.
                Write-Error ("Upstream divergence for '$($r.Path)' (this is EXPECTED for a real promotion: " +
                             "your disk-derived template differs from current upstream at '$pkgTplPath'). " +
                             "Re-run with -Force after inspecting the diff; use compare-with-package.ps1 " +
                             "-PinnedSnapshotRoot <pinned> to distinguish your edit from an unexpected upstream change.")
                exit 2
            }
        }

        $plans += [pscustomobject]@{ Path = $r.Path; Target = $pkgTplPath; Content = $newTplText; Bucket = $r.Bucket }
    }

    # Stage and commit via InstallJournal -- atomic across the set, restore-on-failure.
    $lockPath = Join-Path $TargetRoot '.scratch\agentic-scaffold-promote.lock'
    $jrnPath  = Join-Path $TargetRoot '.scratch\agentic-scaffold-promote.journal'
    $null = New-InstallLock -LockPath $lockPath
    $null = New-WriteJournal -JournalPath $jrnPath
    $writeOk = $false
    try {
        foreach ($p in $plans) {
            # Ensure target dir exists (templates may go into deep paths)
            $dir = Split-Path -Parent $p.Target
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            Add-JournalStage -JournalPath $jrnPath -Target $p.Target -Content $p.Content
        }
        Complete-JournalCommit -JournalPath $jrnPath -ManifestUpdateAction { }
        $writeOk = $true
        Write-Output ""
        Write-Output "  Promoted $($plans.Count) file(s) to PackageRoot."
        foreach ($p in $plans) { Write-Output ("    {0,-13} {1} -> {2}" -f $p.Bucket, $p.Path, $p.Target) }
    } catch {
        Write-Output ""
        Write-Output "  Promotion FAILED: $($_.Exception.Message)"
        $null = Invoke-JournalRollback -JournalPath $jrnPath -P4RevertAction { param($files) }
        throw
    } finally {
        if ($writeOk) {
            Complete-InstallLock -LockPath $lockPath
            Remove-InstallLock -LockPath $lockPath
        }
    }
}
