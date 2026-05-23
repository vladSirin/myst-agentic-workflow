# run-skeleton-preflight.ps1 — Skeleton-phase preflight (plan v1.6 lines 793-802)
#
# Runs the 10-point checklist that gates Skeleton-phase write-mode enablement.
# Read-only: never writes. Exits 0 if all checks pass, 1 if any fail.
param(
    [Parameter(Mandatory=$true)] [string] $TargetRoot,
    [Parameter(Mandatory=$false)][string] $ManifestRelativePath = 'Docs/agents/scaffold-manifest.json'
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
. (Join-Path $here 'lib\Markers.ps1')

$pass = 0; $fail = 0; $skip = 0
function Ok($n,$d='')   { Write-Output ("  PASS  {0}{1}" -f $n,($(if($d){"  ($d)"}else{""}))); $script:pass++ }
function Bad($n,$d='')  { Write-Output ("  FAIL  {0}{1}" -f $n,($(if($d){"  -- $d"}else{""}))); $script:fail++ }
function Skip($n,$d='') { Write-Output ("  SKIP  {0}{1}" -f $n,($(if($d){"  ($d)"}else{""}))); $script:skip++ }

function Prop($obj, $name) {
    if ($null -eq $obj) { return $null }
    if ($obj.PSObject.Properties.Match($name).Count -eq 0) { return $null }
    return $obj.$name
}
function RawSha($p) {
    $b = [System.IO.File]::ReadAllBytes($p)
    $s = [System.Security.Cryptography.SHA256]::Create()
    return 'sha256:' + [BitConverter]::ToString($s.ComputeHash($b)).Replace('-','').ToLowerInvariant()
}
function P4HeadRev($depotPath) {
    # Tolerate native errors (file not in depot, session issues). Returns null
    # for any missing/unknowable head rev rather than crashing under
    # $ErrorActionPreference='Stop'. Callers compare against manifest's
    # depotRevision -- null-vs-null is the expected case for files staged as
    # `p4 add` but not yet submitted.
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $r = & p4 fstat -T headRev $depotPath 2>$null
        foreach ($line in $r) { if ($line -match 'headRev\s+(\d+)') { return [int]$Matches[1] } }
        return $null
    } catch {
        return $null
    } finally {
        $ErrorActionPreference = $prev
    }
}

$manifestPath = Join-Path $TargetRoot $ManifestRelativePath
if (-not (Test-Path -LiteralPath $manifestPath)) { Write-Error "manifest not found: $manifestPath"; exit 2 }

# Detect whether the TARGET is inside a Perforce client view. Checks 4, 5, 6,
# 10 require p4 AND target-in-client; when either is absent we SKIP with a
# clear note rather than FAILing (filesystem-only consumers + fixture tests).
$p4Available = $false
try {
    $info = & p4 info 2>$null
    $infoStr = ($info | Out-String)
    if ($LASTEXITCODE -eq 0 -and $infoStr -match 'Client root:\s+(.+)') {
        $clientRoot = $Matches[1].Trim()
        $targetFull = (Resolve-Path -LiteralPath $TargetRoot).Path
        if ($targetFull.StartsWith($clientRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $p4Available = $true
        }
    }
} catch { $p4Available = $false }

# Build a one-shot map of files open in any pending CL: depot-relative path
# -> action (add/edit/delete/branch/move/add/move/delete/integrate). Checks 4
# and 5 consult this to distinguish "new-in-this-CL" / "pending-delete" from
# real drift / real unmanaged files. Empty hashtable when p4 unavailable.
$pendingOpens = @{}
if ($p4Available) {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    $opened = (& cmd /c "p4 opened 2>nul")
    $ErrorActionPreference = $prev
    foreach ($line in $opened) {
        # Format: //UEPrototype/main/<rel>#<rev> - <action> [default change|change <CL>] (<type>)
        # <action> may contain '/' (move/add, move/delete) — capture greedy-friendly.
        if ($line -match '^//UEPrototype/main/(\S+)#\d+\s+-\s+(\S+)\s') {
            $pendingOpens[$Matches[1]] = $Matches[2]
        }
    }
}

Write-Output "=============================================================="
Write-Output "Skeleton-phase preflight  (plan v1.6 lines 793-802)"
Write-Output "Target: $TargetRoot"
if (-not $p4Available) { Write-Output "Perforce: target not in any p4 client view -- checks 4, 5, 6, 10 will be SKIPPED" }
Write-Output "=============================================================="

# 1. Schema v3 loads.
$bytes = [System.IO.File]::ReadAllBytes($manifestPath)
if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $jsonText = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
} else { $jsonText = [System.Text.Encoding]::UTF8.GetString($bytes) }
$m = $jsonText | ConvertFrom-Json
if ($m.schemaVersion -eq 3) { Ok '1. schema v3 loads' "$($m.files.Count) entries" }
else { Bad '1. schema v3 loads' "schemaVersion=$($m.schemaVersion)" }

# 2. Non-self hashes match (whole-file sha256 + block-scoped).
$hash_bad = @()
foreach ($e in $m.files) {
    if ($e.localOnly) { continue }
    if ($e.hashPolicy -eq 'self-excluded') { continue }
    if ($e.hashPolicy -eq 'runtime-mutable') { continue }
    $fp = Join-Path $TargetRoot $e.path
    if (-not (Test-Path -LiteralPath $fp)) { continue }
    if ($e.hashPolicy -eq 'sha256') {
        if ((RawSha $fp) -ne $e.contentHash) { $hash_bad += "$($e.path) (whole-file)" }
    } elseif ($e.hashPolicy -eq 'block-scoped') {
        if ($null -eq $e.blockHash) { $hash_bad += "$($e.path) (block null)"; continue }
        $gid = Prop $e 'generatedBlockId'
        $aid = Prop $e 'appendFragmentId'
        $id  = if ($gid) { $gid } else { $aid }
        try {
            $computed = Get-MarkerBlockHash -Path $fp -Id $id
            if ($computed -ne $e.blockHash) { $hash_bad += "$($e.path) (block mismatch)" }
        } catch { $hash_bad += "$($e.path) (parse error: $($_.Exception.Message))" }
    }
}
if ($hash_bad.Count -eq 0) { Ok '2. all non-self hashes match' }
else { Bad '2. all non-self hashes match' ($hash_bad -join '; ') }

# 3. No generated-block/append-fragment carries a whole-file hash.
$bad3 = @($m.files | Where-Object { $_.mergeStrategy -in @('generated-block','append-fragment') -and $_.contentHash })
if ($bad3.Count -eq 0) { Ok '3. no generated-block/append-fragment carries whole-file hash' }
else { Bad '3. no generated-block/append-fragment carries whole-file hash' (($bad3.path) -join '; ') }

# 4. Every managed file's depotRevision matches current headRev.
#    Exemption: files open-for-add/branch/move-add in a pending CL have no
#    headRev yet (depot doesn't know about them until submit). Manifest may
#    already list them with depotRevision=1 (or null); skip head comparison.
if (-not $p4Available) {
    Skip '4. depotRevision == headRev for all managed' 'p4 client not reachable'
} else {
    $drift = @()
    $pendingAddActions = @('add','branch','move/add')
    foreach ($e in $m.files) {
        if ($e.localOnly) { continue }
        if ($e.hashPolicy -eq 'self-excluded') { continue }
        $relKey = $e.path.Replace('\','/')
        if ($pendingOpens.ContainsKey($relKey) -and $pendingAddActions -contains $pendingOpens[$relKey]) {
            continue
        }
        $head = P4HeadRev ("//UEPrototype/main/" + $e.path)
        if ($null -eq $head) {
            if ($null -ne $e.depotRevision) { $drift += "$($e.path) (manifest=$($e.depotRevision) head=missing)" }
            continue
        }
        if ($e.depotRevision -ne $head) { $drift += "$($e.path) (manifest=$($e.depotRevision) head=$head)" }
    }
    if ($drift.Count -eq 0) { Ok '4. depotRevision == headRev for all managed' }
    else { Bad '4. depotRevision == headRev for all managed' ($drift -join '; ') }
}

# 5. No unmanaged scaffold-like files in the depot.
#    Exemption: depot files open-for-delete/move-delete in a pending CL are
#    deliberately being removed; the manifest no longer references them, and
#    that's the correct state. Don't flag them as unmanaged.
if (-not $p4Available) {
    Skip '5. no unmanaged scaffold-like files (depot-tracked)' 'p4 client not reachable'
} else {
    $managedRoots = @('.claude','.Codex','.opencode','Docs/agents','Docs/MustRead')
    $manifestPaths = @{}
    foreach ($e in $m.files) { $manifestPaths[$e.path.Replace('\','/')] = $true }
    $pendingDeleteActions = @('delete','move/delete')
    $unmanaged = @()
    foreach ($root in $managedRoots) {
        $have = & p4 have ("//UEPrototype/main/" + $root + "/...") 2>$null
        foreach ($line in $have) {
            if ($line -match '^//UEPrototype/main/(\S+)#\d+') {
                $rel = $Matches[1]
                if ($manifestPaths.ContainsKey($rel)) { continue }
                if ($pendingOpens.ContainsKey($rel) -and $pendingDeleteActions -contains $pendingOpens[$rel]) { continue }
                $unmanaged += $rel
            }
        }
    }
    if ($unmanaged.Count -eq 0) { Ok '5. no unmanaged scaffold-like files (depot-tracked)' }
    else { Bad '5. no unmanaged scaffold-like files' (($unmanaged | Select-Object -First 5) -join '; ') }
}

# 6. Local-only files are ignored (i.e., not opened in P4).
if (-not $p4Available) {
    Skip '6. local-only files are not in P4 opens' 'p4 client not reachable'
} else {
    $openedLocal = @()
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    $opened = (& cmd /c "p4 opened 2>nul")
    $ErrorActionPreference = $prev
    foreach ($e in $m.files) {
        if (-not $e.localOnly) { continue }
        $needle = $e.path.Replace('\','/')
        if ($opened -match [regex]::Escape($needle)) { $openedLocal += $needle }
    }
    if ($openedLocal.Count -eq 0) { Ok '6. local-only files are not in P4 opens' "$(($m.files | Where-Object {$_.localOnly}).Count) localOnly entries" }
    else { Bad '6. local-only files are not in P4 opens' ($openedLocal -join '; ') }
}

# 7. Tool capability deviations reported (informational unless missing).
$devs = @()
$tc = Prop $m 'toolCapabilities'
if ($tc) {
    foreach ($t in 'codex','claudeCode','openCode') {
        $sub  = Prop $tc $t
        $devsForT = Prop $sub 'deviations'
        if ($devsForT) { foreach ($d in @($devsForT)) { $devs += "${t}: $d" } }
    }
}
Ok '7. tool-capability deviations recorded' "$($devs.Count) deviation(s)"
foreach ($d in $devs) { Write-Output "         - $d" }

# 8. Block-scoped files with null blockHash are reported, never clean.
$bsNull = @($m.files | Where-Object { $_.blockHashPolicy -eq 'sha256' -and $null -eq $_.blockHash })
if ($bsNull.Count -eq 0) { Ok '8. block-scoped null-blockHash reporting (none present)' }
else {
    Ok '8. block-scoped null-blockHash entries exist and are tracked' "$($bsNull.Count) flagged as unverifiable-pending-markers"
    foreach ($e in $bsNull) { Write-Output "         - $($e.path)" }
}

# 9. Marker Specification fixtures pass.
$mfx = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'run-marker-fixtures.ps1') 2>&1
if ($LASTEXITCODE -eq 0) { Ok '9. Marker Specification fixtures pass' }
else { Bad '9. Marker Specification fixtures pass' "exit=$LASTEXITCODE" }

# 10. p4 opened -c default is clean.
if (-not $p4Available) {
    Skip '10. p4 opened -c default is clean' 'p4 client not reachable'
} else {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    $default = (& cmd /c "p4 opened -c default 2>nul") 2>$null
    $ErrorActionPreference = $prev
    $defaultFiles = @($default | Where-Object { $_ -match 'default change' })
    if ($defaultFiles.Count -eq 0) { Ok '10. p4 opened -c default is clean' }
    else {
        Bad '10. p4 opened -c default is clean' "$($defaultFiles.Count) file(s) in default change"
        foreach ($f in $defaultFiles) { Write-Output "         - $f" }
    }
}

Write-Output ""
Write-Output "=============================================================="
Write-Output "Skeleton preflight: $pass passed, $fail failed, $skip skipped"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
