# diff-installed.ps1 — myst-agentic-workflow drift detection (skeleton phase)
# Compares installed scaffold state against manifest. Read-only; never writes.
param(
    [Parameter(Mandatory=$true)]  [string] $TargetRoot,
    [Parameter(Mandatory=$false)] [string] $Manifest = "Docs/agents/scaffold-manifest.json",
    [ValidateSet("text","json")]  [string] $Output = "text"
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = "0.2.0-promotion"
. (Join-Path $PSScriptRoot 'lib\Classification.ps1')
. (Join-Path $PSScriptRoot 'lib\Markers.ps1')

function Get-Hash($path) {
    if (-not (Test-Path $path)) { return $null }
    # EOL/BOM-invariant contentHash (see Get-NormalizedContentHash in Markers.ps1).
    return Get-NormalizedContentHash -Path (Resolve-Path -LiteralPath $path).Path
}

$ManifestPath = Join-Path $TargetRoot $Manifest
if (-not (Test-Path $ManifestPath)) {
    Write-Error "Manifest not found: $ManifestPath"
    exit 2
}
$m = Get-Content -Raw $ManifestPath | ConvertFrom-Json

$results = [System.Collections.ArrayList]@()

foreach ($entry in $m.files) {
    $fp = Join-Path $TargetRoot $entry.path
    $exists = Test-Path $fp
    $diskHash = if ($exists) { Get-Hash $fp } else { $null }

    $result = [PSCustomObject]@{
        Path               = $entry.path
        BaselineState      = $entry.baselineState
        Owner              = $entry.owner
        Overlay            = $entry.ownerOverlay
        Bucket             = (Get-OwnershipBucket $entry)   # issue 09: ownership axis (orthogonal to Category)
        MergeStrategy      = $entry.mergeStrategy
        HashPolicy         = $entry.hashPolicy
        Exists             = $exists
        DiskHash           = $diskHash
        ManifestHash       = if ($entry.contentHash) { $entry.contentHash } else { $null }
        BlockHashPolicy    = $entry.blockHashPolicy
        ManifestBlockHash  = $entry.blockHash
        DepotRevision      = $entry.depotRevision
        LocalOnly          = $entry.localOnly
        Category           = ""
        Detail             = ""
    }

    # --- Classify ---
    if ($entry.localOnly -eq $true) {
        $result.Category = "local-only"
        $result.Detail = "excluded from tracking"
        [void]$results.Add($result)
        continue
    }

    # Check for depot-revision divergence (out-of-band edits like CL 883)
    if ($entry.depotRevision -ne $null) {
        # Depot revision binding: if this file was submitted at a known rev
        # but the disk hash still matches the manifest, it's in sync.
        # If it doesn't match AND depotRevision is set, this is flagged for review.
        # Full p4 fstat integration is deferred to the post-skeleton phase.
        if ($entry.hashPolicy -eq "sha256" -and $diskHash -ne $entry.contentHash) {
            $result.Detail += " [depotRevision=$($entry.depotRevision); hash-mismatch]"
        }
    }

    if (-not $exists) {
        $result.Category = if ($entry.owner -in @("package","overlay")) { "missing-package-file" } else { "missing" }
        $result.Detail += "file absent from target"
        [void]$results.Add($result)
        continue
    }

    if ($entry.hashPolicy -eq "self-excluded") {
        $result.Category = "self-excluded"
        $result.Detail = "manifest self-entry; validated by schema check, not hash"
        [void]$results.Add($result)
        continue
    }

    if ($entry.hashPolicy -eq "not-applicable") {
        $result.Category = "unmanaged"
        $result.Detail = "no hash policy declared"
        [void]$results.Add($result)
        continue
    }

    if ($entry.hashPolicy -eq "block-scoped") {
        if ($entry.blockHash -eq $null) {
            $result.Category = "unverifiable-pending-markers"
            $result.Detail = "markers not present; block hash not yet computable"
        } else {
            $result.Category = "block-scoped"
            $result.Detail = "block hash populated (markers present)"
        }
        [void]$results.Add($result)
        continue
    }

    # sha256 whole-file
    if ($entry.hashPolicy -eq "sha256" -and $entry.mergeStrategy -in @("generated-block","append-fragment")) {
        $result.Category = "SCHEMA-VIOLATION"
        $result.Detail = "generated-block/append-fragment with whole-file sha256 — invalid schema v3+"
        [void]$results.Add($result)
        continue
    }

    if ($diskHash -eq $entry.contentHash) {
        $result.Category = "clean"
        $result.Detail = "hash match"
    } else {
        if ($entry.owner -eq "project") {
            $result.Category = "project-edited"
            $result.Detail = "project-owned file; hash differs from manifest"
        } elseif ($entry.mergeStrategy -eq "manual-only") {
            $result.Category = "human-edited"
            $result.Detail = "manual-only file; human-owned, drift reported only"
        } elseif ($entry.writablePolicy -eq "human-owned") {
            $result.Category = "human-edited"
            $result.Detail = "human-owned file"
        } else {
            $result.Category = "drift-package-owned"
            $result.Detail = "package-owned file; hash differs — requires resolution"
        }
    }
    [void]$results.Add($result)
}

# --- Output ---
if ($Output -eq "json") {
    ($results | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $TargetRoot ".scratch/agentic-scaffold-drift.json") -Encoding UTF8
    Write-Output "JSON written to .scratch/agentic-scaffold-drift.json"
} else {
    # Text summary
    $cats = $results | Group-Object Category | Sort-Object Count -Descending
    Write-Output "=============================================================="
    Write-Output "diff-installed.ps1  v$ScriptVersion"
    Write-Output "Target: $TargetRoot | Files analyzed: $($results.Count)"
    Write-Output "=============================================================="
    Write-Output ""
    foreach ($c in $cats) {
        $icon = switch ($c.Name) {
            "clean" { "  OK" }
            "local-only" { "  --" }
            "self-excluded" { "  --" }
            "human-edited" { "  ! " }
            "project-edited" { "  ! " }
            "drift-package-owned" { " ** " }
            "missing-package-file" { " ?? " }
            "unverifiable-pending-markers" { " ?? " }
            "SCHEMA-VIOLATION" { " ERR" }
            default { "    " }
        }
        Write-Output "$icon $($c.Count) $($c.Name)"
        if ($c.Name -in @("drift-package-owned","SCHEMA-VIOLATION","missing-package-file")) {
            foreach ($r in $c.Group) {
                Write-Output "     $($r.Path)  $($r.Detail)"
            }
        }
    }
    Write-Output ""
    $unverifiable = ($results | Where-Object { $_.Category -eq "unverifiable-pending-markers" }).Count
    if ($unverifiable -gt 0) {
        Write-Output "NOTE: $unverifiable files are block-scoped without populated blockHash."
        Write-Output "      Markers must be added to CLAUDE.md / AGENTS.md / .p4ignore first."
    }
    $violations = ($results | Where-Object { $_.Category -eq "SCHEMA-VIOLATION" }).Count
    if ($violations -gt 0) {
        Write-Output "CRITICAL: $violations SCHILE-VIOLATION entries found. Manifest must be repaired."
    }
    Write-Output ""
    Write-Output @"
Category legend (drift state):
  OK = clean      ! = human/project-edited (expected)    ** = package drift (review)
  ?? = unverifiable/missing    ERR = schema violation      -- = excluded/self
"@
    # Issue 09: report the ownership bucket as a second axis, alongside drift state.
    $bucketGroups = $results | Group-Object Bucket | Sort-Object Name
    Write-Output ""
    Write-Output "Ownership buckets (orthogonal to drift state):"
    foreach ($g in $bucketGroups) {
        $promotable = if (Test-IsPromotable $g.Name) { 'promotable' } else { 'never-promote' }
        Write-Output ("  {0,-14} {1,3}  ({2})" -f $g.Name, $g.Count, $promotable)
    }
}
