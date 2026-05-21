# install.ps1 — myst-agentic-workflow scaffold installer
# Applies package templates + overlays to a consuming project. -Mode Write is
# gated by run-skeleton-preflight.ps1 (10/10 required) and uses InstallJournal
# for atomic-rename across the staged set.
param(
    [Parameter(Mandatory=$true)]  [string] $TargetRoot,
    [Parameter(Mandatory=$false)] [string] $Tools = "all",
    [Parameter(Mandatory=$false)] [string] $Overlays = "core",
    [ValidateSet("DryRun","Write")] [string] $Mode = "DryRun",
    [switch] $UsePerforce,
    [string] $Changelist = "",
    [string] $ManifestRelativePath = "Docs/agents/scaffold-manifest.json",
    # B1 (issue 15 review): docs prescribe -PackageRoot as the bridge between
    # the consuming-project workflow and the package's scripts/ dir. Default
    # resolves the script's own ../ so users running scripts in-place still work.
    [string] $PackageRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = "0.2.0-extract-core"
. (Join-Path $PSScriptRoot 'lib\Markers.ps1')
. (Join-Path $PSScriptRoot 'lib\InstallJournal.ps1')
. (Join-Path $PSScriptRoot 'lib\ManifestUpdate.ps1')
. (Join-Path $PSScriptRoot 'lib\Render.ps1')

###############################################################################
# Runtime preflight gate -- Write mode requires 10/10 preflight green
###############################################################################
if ($Mode -eq "Write") {
    Write-Output "Write mode requested -- running Skeleton preflight as gate..."
    $preflight = Join-Path $PSScriptRoot 'run-skeleton-preflight.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $preflight -TargetRoot $TargetRoot | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error @"

==============================================================
WRITE MODE REFUSED -- preflight FAILED (exit $LASTEXITCODE)
==============================================================

Run the preflight directly to see which check(s) failed:
  ./scripts/run-skeleton-preflight.ps1 -TargetRoot '$TargetRoot'

Re-run install with -Mode DryRun to see what would change without writing.
==============================================================
"@
        exit 2
    }
    Write-Output "Preflight green (10/10). Proceeding with write phase."
}

###############################################################################
# Helpers
###############################################################################
function Format-TableReport($rows, $headers) {
    # Simple column-aligned text table.
    $widths = @{}
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $maxCol = 0
        foreach ($r in $rows) {
            if ($r -is [array] -and $r.Length -ge ($i+1)) {
                $len = $r[$i].Length
                if ($len -gt $maxCol) { $maxCol = $len }
            }
        }
        $widths[$i] = if ($headers[$i].Length -gt $maxCol) { $headers[$i].Length } else { $maxCol }
    }
    $sep = ($headers | ForEach-Object { "-" * $widths[[array]::IndexOf($headers, $_)] }) -join "-+-"
    $out = " | " + (0..($headers.Count-1) | ForEach-Object { $headers[$_].PadRight($widths[$_]) }) -join " | "
    $out += "`n" + "-+-" + $sep + "-+`n"
    foreach ($r in $rows) {
        if ($r -is [string]) { $out += $r + "`n" }
        else {
            $out += " | " + (0..($headers.Count-1) | ForEach-Object { $r[$_].PadRight($widths[$_]) }) -join " | "
            $out += "`n"
        }
    }
    $out
}

function Get-Hash($path) {
    if (-not (Test-Path $path)) { return $null }
    $bytes = [System.IO.File]::ReadAllBytes([System.IO.Path]::GetFullPath($path))
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return "sha256:" + [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace("-","").ToLower()
}

###############################################################################
# Load package + installed manifests
###############################################################################
$PackageManifestPath = Join-Path $PSScriptRoot "..\package-manifest.json"
if (-not (Test-Path $PackageManifestPath)) {
    Write-Error "package-manifest.json not found at $PackageManifestPath"
    exit 2
}
$PackageManifest = Get-Content -Raw $PackageManifestPath | ConvertFrom-Json

$InstalledManifestPath = Join-Path $TargetRoot $ManifestRelativePath
if (-not (Test-Path $InstalledManifestPath)) {
    Write-Error "Installed scaffold-manifest.json not found at $InstalledManifestPath"
    exit 2
}
$InstalledManifest = Get-Content -Raw $InstalledManifestPath | ConvertFrom-Json

$TargetTools = if ($Tools -eq "all") { @("codex", "claude", "opencode") } else { $Tools -split "," | ForEach-Object { $_.Trim().ToLower() } }
$TargetOverlays = $Overlays -split "," | ForEach-Object { $_.Trim().ToLower() }

Write-Output "=============================================================="
Write-Output "myst-agentic-workflow install.ps1  v$ScriptVersion"
Write-Output ("Mode: {0}  |  Write-mode: {1}" -f $Mode, $(if ($Mode -eq 'Write') { 'ENABLED (preflight-gated)' } else { 'inactive (DryRun)' }))
Write-Output "Target: $TargetRoot"
Write-Output "Tools: $($TargetTools -join ', ') | Overlays: $($TargetOverlays -join ', ')"
Write-Output "Installed manifest: schema v$($InstalledManifest.schemaVersion) | $($InstalledManifest.files.Count) entries"
Write-Output "=============================================================="

###############################################################################
# Analyze every file in installed manifest
###############################################################################
$report = @()

foreach ($entry in $InstalledManifest.files) {
    $filePath = Join-Path $TargetRoot $entry.path
    $exists = Test-Path $filePath
    $diskHash = if ($exists) { Get-Hash $filePath } else { $null }
    $toolOk = ($entry.tool -eq "common") -or ($TargetTools -contains $entry.tool)
    $overlayOk = ($entry.ownerOverlay -eq $null) -or ($TargetOverlays -contains $entry.ownerOverlay)

    # --- Classification ---
    if ($entry.localOnly -eq $true) {
        $report += ,@($entry.path, "local-only", "-", "excluded from install/drift")
        continue
    }
    if (-not $toolOk) {
        $report += ,@($entry.path, "skipped", $entry.tool, "not in selected tools")
        continue
    }
    if (-not $overlayOk) {
        $report += ,@($entry.path, "skipped", $entry.ownerOverlay, "not in selected overlays")
        continue
    }

    # Manual-only: report-only, never written
    if ($entry.mergeStrategy -eq "manual-only") {
        if ($entry.writablePolicy -eq "human-owned") {
            $report += ,@($entry.path, "human-owned", $entry.writablePolicy, "tracked for awareness; never modified")
        } else {
            $report += ,@($entry.path, "report-only", $entry.writablePolicy, "tracked; drift reported, never written")
        }
        continue
    }

    # Block-scoped files without markers yet -> unverifiable
    if (($entry.mergeStrategy -in @("generated-block","append-fragment")) -and ($entry.blockHash -eq $null)) {
        $report += ,@($entry.path, "UNVERIFIABLE", $entry.mergeStrategy, "markers not yet present; block hash pending Marker Specification implementation")
        continue
    }

    # Package-owned (copy/full-file-override or block-scoped with populated hash)
    if ($entry.owner -in @("package","overlay") -and $entry.writablePolicy -in @("installer-owned","generated-block-only")) {
        if (-not $exists) {
            $report += ,@($entry.path, "MISSING", $entry.mergeStrategy, "package-owned file absent from target")
        } elseif ($entry.hashPolicy -eq "block-scoped") {
            # block-scoped: check blockHash only (once populated)
            $report += ,@($entry.path, "pending-block", $entry.mergeStrategy, "block-hash validation deferred (markers not yet present)")
        } elseif ($entry.hashPolicy -eq "sha256" -and $diskHash -ne $entry.contentHash) {
            $report += ,@($entry.path, "DRIFT", $entry.mergeStrategy, "installed hash differs from manifest")
        } else {
            $report += ,@($entry.path, "clean", $entry.mergeStrategy, "hash match")
        }
        continue
    }

    # Unmanaged scaffold-like files
    if ($entry.owner -eq "project") {
        $report += ,@($entry.path, "project-owned", $entry.mergeStrategy, "project-local; never modified")
        continue
    }

    # Unknown / uncategorized
    $report += ,@($entry.path, "unknown", $entry.mergeStrategy, "unclassified; review required")
}

###############################################################################
# Missing package files (in manifest scope but template not populated)
###############################################################################
$missingPackageFiles = @($InstalledManifest.files | Where-Object {
    $_.owner -in @("package","overlay") -and $_.sourceCommit -eq "pending-package"
}).Count

###############################################################################
# Report
###############################################################################
$headers = @("File", "Status", "Strategy", "Detail")
Write-Output ""
Write-Output (Format-TableReport $report $headers)

Write-Output ""
Write-Output "=============================================================="
Write-Output "SUMMARY"
Write-Output "=============================================================="

$summaryCategories = ($report | ForEach-Object { $_[1] }) | Group-Object
foreach ($cat in $summaryCategories) {
    Write-Output "  $($cat.Count) $($cat.Name)"
}

Write-Output "  $missingPackageFiles files with sourceCommit=pending-package (unpopulated templates)"
Write-Output ""
if ($PackageManifest.manifestSchema.hashScopeRule) {
    Write-Output "PROVENANCE: UNVERIFIED (pending-package)"
    Write-Output "  Until the package repository has a real URL and commit, provenance on"
    Write-Output "  ~80 manifest entries cannot be verified. This is expected in the skeleton phase."
}
Write-Output ""
###############################################################################
# Write phase  (Extract Reusable Core)
###############################################################################
$Vars = Get-VariableMap -Manifest $InstalledManifest

$Changes = New-Object System.Collections.ArrayList
foreach ($entry in $InstalledManifest.files) {
    if ($entry.localOnly) { continue }
    if ($entry.hashPolicy -eq 'self-excluded') { continue }
    if ($entry.mergeStrategy -eq 'manual-only') { continue }
    $toolOk    = ($entry.tool -eq 'common') -or ($TargetTools -contains $entry.tool)
    $overlayOk = ($null -eq $entry.ownerOverlay) -or ($TargetOverlays -contains $entry.ownerOverlay)
    if (-not $toolOk -or -not $overlayOk) { continue }

    $rendered = Get-EntryRendered -Entry $entry -PackageRoot $PackageRoot -TargetRoot $TargetRoot -Vars $Vars
    if ($null -eq $rendered) { continue }
    $tgt = Join-Path $TargetRoot $entry.path
    $current = if (Test-Path -LiteralPath $tgt) { Read-NormalizedText -Path $tgt } else { '' }
    if ($rendered -ne $current) {
        $gid = if ($entry.PSObject.Properties.Match('generatedBlockId').Count -gt 0) { $entry.generatedBlockId } else { $null }
        $aid = if ($entry.PSObject.Properties.Match('appendFragmentId').Count -gt 0) { $entry.appendFragmentId } else { $null }
        [void]$Changes.Add([pscustomobject]@{
            Path     = $entry.path; Strategy = $entry.mergeStrategy
            CurLen   = $current.Length; NewLen = $rendered.Length
            Rendered = $rendered; Target = $tgt
            GeneratedBlockId = $gid; AppendFragmentId = $aid
        })
    }
}

Write-Output ""
Write-Output "=============================================================="
Write-Output "WRITE PHASE  ($Mode)"
Write-Output "=============================================================="
if ($Changes.Count -eq 0) {
    Write-Output "  NO CHANGES -- all targets already match rendered templates."
    Write-Output "  Re-install would be a no-op."
} else {
    Write-Output ("  {0} file(s) would change:" -f $Changes.Count)
    foreach ($c in $Changes) {
        Write-Output ("    {0}  ({1})  {2} -> {3} chars" -f $c.Path, $c.Strategy, $c.CurLen, $c.NewLen)
    }
    if ($Mode -eq 'Write') {
        # (Issue 08: WARNING-4 guard removed. ManifestUpdateAction now
        # recomputes contentHash / blockHash / lastCheckedAt for written
        # entries via Update-ManifestForChanges -- see lib/ManifestUpdate.ps1.
        # Transactional: a throw inside that action triggers the BLOCKING-2
        # restore-from-baks in Complete-JournalCommit.)

        # BLOCKING 6: Perforce integration (or refuse if read-only targets without -UsePerforce)
        if (-not $UsePerforce) {
            $readOnly = @($Changes | Where-Object { (Test-Path -LiteralPath $_.Target) -and (Get-ItemProperty -LiteralPath $_.Target).IsReadOnly })
            if ($readOnly.Count -gt 0) {
                Write-Error @"

==============================================================
WRITE MODE REFUSED -- read-only targets without -UsePerforce
==============================================================

$($readOnly.Count) target file(s) are read-only (likely Perforce-managed).
Atomic-rename would fail mid-loop. Re-run with -UsePerforce -Changelist <id|new>.

Read-only targets:
$( ($readOnly | Select-Object -First 5 | ForEach-Object { '  - ' + $_.Path }) -join "`n" )
==============================================================
"@
                exit 2
            }
        }

        if ($UsePerforce -and -not $Changelist) {
            Write-Error "-UsePerforce requires -Changelist <id|new>"; exit 2
        }
        $targetCL = $Changelist
        if ($UsePerforce -and $targetCL -eq 'new') {
            $spec = & p4 change -o
            # W4 (issue 15 review): parameterize the CL tag prefix via the consuming
            # project's installedProject.clTagPrefix. Default to neutral [scaffold]
            # so the description is editable before submit (see perforce-consumer.md §3).
            $clTag = "[scaffold]"
            if ($InstalledManifest.PSObject.Properties.Match('installedProject').Count -gt 0 -and
                $InstalledManifest.installedProject.PSObject.Properties.Match('clTagPrefix').Count -gt 0 -and
                $InstalledManifest.installedProject.clTagPrefix) {
                $clTag = [string]$InstalledManifest.installedProject.clTagPrefix
            }
            $newDesc = "$clTag Agentic scaffolding - install -Mode Write phase`n`n## What`n- install.ps1 v$ScriptVersion writing $($Changes.Count) file(s) per package manifest.`n`n## Why`n- Apply current package templates/overlays to the consuming project.`n`n## Notes`n- Generated by install.ps1. Manually verify diff before submit."
            $specWithDesc = $spec -replace '<enter description here>', ($newDesc -replace "`n", "`n`t")
            $created = $specWithDesc | & p4 change -i
            if ($created -match 'Change (\d+) created') { $targetCL = $Matches[1] }
            else { Write-Error "failed to create new CL: $created"; exit 2 }
            Write-Output "  Created CL $targetCL for write phase."
        }

        Write-Output ""
        Write-Output "  Applying via InstallJournal (atomic rename)..."
        $lockPath = Join-Path $TargetRoot '.scratch\agentic-scaffold-install.lock'
        $jrnPath  = Join-Path $TargetRoot '.scratch\agentic-scaffold-install.journal'
        $null = New-InstallLock -LockPath $lockPath
        $null = New-WriteJournal -JournalPath $jrnPath

        # p4 revert action -- real when -UsePerforce, no-op otherwise.
        $p4Revert = if ($UsePerforce) {
            { param($files) foreach ($f in $files) { & p4 revert -c $targetCL $f | Out-Null } }
        } else { { param($files) } }

        $writeOk = $false
        $newFiles = @()
        try {
            # Pre-write: p4 edit existing files (makes them writable; opens them in $targetCL).
            if ($UsePerforce) {
                foreach ($c in $Changes) {
                    if (Test-Path -LiteralPath $c.Target) {
                        & p4 edit -c $targetCL $c.Target | Out-Null
                        Register-OpenedFile -JournalPath $jrnPath -Path $c.Target
                    } else {
                        $newFiles += $c.Target   # p4 add deferred until after commit (file must exist)
                    }
                }
            }

            foreach ($c in $Changes) { Add-JournalStage -JournalPath $jrnPath -Target $c.Target -Content $c.Rendered }
            $manifestPathForAction = $InstalledManifestPath
            $changesForAction      = @($Changes)
            $manifestUpdate = { Update-ManifestForChanges -ManifestPath $manifestPathForAction -Changes $changesForAction }.GetNewClosure()
            Complete-JournalCommit -JournalPath $jrnPath -ManifestUpdateAction $manifestUpdate

            # Post-commit: p4 add the now-created files.
            if ($UsePerforce -and $newFiles.Count -gt 0) {
                foreach ($f in $newFiles) {
                    & p4 add -c $targetCL $f | Out-Null
                    Register-OpenedFile -JournalPath $jrnPath -Path $f
                }
            }

            Write-Output "  Write phase committed.$( if ($UsePerforce) { ' P4 CL: ' + $targetCL } else { '' } )"
            $writeOk = $true
        } catch {
            Write-Output "  Write FAILED: $($_.Exception.Message)"
            $null = Invoke-JournalRollback -JournalPath $jrnPath -P4RevertAction $p4Revert
            throw
        } finally {
            # BLOCKING 1 fix: only mark clean exit on success. On failure leave
            # the lock as an incomplete-exit marker for Test-IncompleteInstall.
            if ($writeOk) {
                Complete-InstallLock -LockPath $lockPath
                Remove-InstallLock -LockPath $lockPath
            }
        }
    } else {
        Write-Output ""
        Write-Output "  DryRun: no files modified. Re-run with -Mode Write to apply."
    }
}
Write-Output ""

Write-Output "Next steps:"
Write-Output "  - Run compare-with-package.ps1 to verify cross-repo drift status."
Write-Output "  - See docs/install.md for the full install / update / promote workflow."
Write-Output "  - For UE/Perforce consumers: docs/perforce-consumer.md."
