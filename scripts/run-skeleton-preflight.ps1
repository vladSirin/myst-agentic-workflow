# run-skeleton-preflight.ps1 — Skeleton-phase preflight (plan v1.6 lines 793-802)
#
# Runs the 10-point checklist that gates Skeleton-phase write-mode enablement.
# Read-only: never writes. Exits 0 if all checks pass, 1 if any fail.
param(
    [Parameter(Mandatory=$true)] [string] $TargetRoot,
    [Parameter(Mandatory=$false)][string] $ManifestRelativePath = 'Docs/agents/scaffold-manifest.json',
    # Package root -- needed by check 5 to test that package/overlay-owned entries
    # still have a live sourceTemplate on disk. Body default (not a param-block
    # default): $PSScriptRoot is empty while param defaults are evaluated under -File.
    [Parameter(Mandatory=$false)][string] $PackageRoot = ''
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
. (Join-Path $here 'lib\Markers.ps1')
. (Join-Path $here 'lib\Render.ps1')
if ([string]::IsNullOrWhiteSpace($PackageRoot)) { $PackageRoot = (Resolve-Path (Join-Path $here '..')).Path }

$pass = 0; $fail = 0; $skip = 0; $warn = 0
function Ok($n,$d='')   { Write-Output ("  PASS  {0}{1}" -f $n,($(if($d){"  ($d)"}else{""}))); $script:pass++ }
function Bad($n,$d='')  { Write-Output ("  FAIL  {0}{1}" -f $n,($(if($d){"  -- $d"}else{""}))); $script:fail++ }
function Skip($n,$d='') { Write-Output ("  SKIP  {0}{1}" -f $n,($(if($d){"  ($d)"}else{""}))); $script:skip++ }
# Report-only findings: visible in the closing banner, never gate a write.
function Warn($n,$d='') { Write-Output ("  WARN  {0}{1}" -f $n,($(if($d){"  -- $d"}else{""}))); $script:warn++ }

function Prop($obj, $name) {
    if ($null -eq $obj) { return $null }
    if ($obj.PSObject.Properties.Match($name).Count -eq 0) { return $null }
    return $obj.$name
}
# contentHash is EOL/BOM-invariant (Get-NormalizedContentHash in Markers.ps1); the
# write-mode gate must validate with the same normalization the manifest writers use.
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
# Depot root for THIS consumer -- never hardcode a depot path in a reusable package.
# `p4 where` maps the local target to its depot path; `p4 info`'s clientRoot is a
# LOCAL path and would silently match nothing, turning checks into false passes.
$depotRoot = $null
if ($p4Available) {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    $whereOut = (& cmd /c "p4 -ztag -F ""%depotFile%"" where ""$TargetRoot/..."" 2>nul")
    $ErrorActionPreference = $prev
    foreach ($line in $whereOut) {
        # Skip exclusion lines ('-//depot/...') emitted for client-view exclusions.
        if ($line -match '^//\S+/\.\.\.$') { $depotRoot = $line -replace '/\.\.\.$',''; break }
    }
    if (-not $depotRoot) {
        Write-Output "  NOTE  depot root unresolved for '$TargetRoot' -- depot-aware checks will SKIP"
    }
}

$pendingOpens = @{}
if ($p4Available -and $depotRoot) {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    $opened = (& cmd /c "p4 opened 2>nul")
    $ErrorActionPreference = $prev
    $openedRx = '^' + [regex]::Escape("$depotRoot/") + '(\S+)#\d+\s+-\s+(\S+)\s'
    foreach ($line in $opened) {
        # Format: <depotRoot>/<rel>#<rev> - <action> [default change|change <CL>] (<type>)
        # <action> may contain '/' (move/add, move/delete) — capture greedy-friendly.
        if ($line -match $openedRx) {
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
$humanOwned2 = 0
foreach ($e in $m.files) {
    if ($e.localOnly) { continue }
    if ($e.hashPolicy -eq 'self-excluded') { continue }
    if ($e.hashPolicy -eq 'runtime-mutable') { continue }
    # human-owned == the installer never writes it. Policing a file the consumer
    # owns turns "someone edited their own doc" into a red write gate, which is
    # the same defect the block-scoped exemption fixed in check 4 -- the shared
    # rule is "if we do not own it, we do not police it". Hash baselines here are
    # bookkeeping (diff-installed annotates with them, never gates), and since
    # upgrade.ps1 keys customization detection on recorded OWNERSHIP rather than
    # hashes, nothing load-bearing depends on them.
    if ($e.writablePolicy -eq 'human-owned') { $humanOwned2++; continue }
    $fp = Join-Path $TargetRoot $e.path
    if (-not (Test-Path -LiteralPath $fp)) { continue }
    if ($e.hashPolicy -eq 'sha256') {
        if ((Get-NormalizedContentHash -Path $fp) -ne $e.contentHash) { $hash_bad += "$($e.path) (whole-file)" }
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
$ho2Note = if ($humanOwned2 -gt 0) { "$humanOwned2 human-owned entr$(if($humanOwned2 -eq 1){'y'}else{'ies'}) not hash-tracked (the installer never writes them)" } else { '' }
if ($hash_bad.Count -eq 0) { Ok '2. all non-self hashes match' $ho2Note }
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
    $blockScoped = 0
    $humanOwned4 = 0
    $pendingAddActions = @('add','branch','move/add')
    foreach ($e in $m.files) {
        if ($e.localOnly) { continue }
        if ($e.hashPolicy -eq 'self-excluded') { continue }
        # Block-scoped files (CLAUDE.md, AGENTS.md, .p4ignore) are SHARED: the
        # installer owns the generated block, humans own everything around it. A
        # human editing their own region legitimately bumps the depot revision, so
        # revision-tracking them means the write gate closes every time someone
        # edits a file they are supposed to edit. Their real guard is check 2's
        # blockHash, which covers exactly the installer-owned bytes and is
        # unaffected by edits outside the markers. Revision drift here is expected
        # behaviour, not drift -- counted and reported, never gating.
        if ($e.hashPolicy -eq 'block-scoped') { $blockScoped++; continue }
        # Same rule, wider: a human-owned file is the consumer's, and they are
        # expected to edit it. Revision-tracking it means every legitimate edit
        # closes the write gate until someone hand-patches the manifest.
        if ($e.writablePolicy -eq 'human-owned') { $humanOwned4++; continue }
        $relKey = $e.path.Replace('\','/')
        if ($pendingOpens.ContainsKey($relKey) -and $pendingAddActions -contains $pendingOpens[$relKey]) {
            continue
        }
        $head = P4HeadRev ("$depotRoot/" + $e.path)
        if ($null -eq $head) {
            if ($null -ne $e.depotRevision) { $drift += "$($e.path) (manifest=$($e.depotRevision) head=missing)" }
            continue
        }
        if ($e.depotRevision -eq $head) { continue }
        # A file open for EDIT in a pending CL is about to become head+1, and the
        # installer records that value at write time so the manifest is correct the
        # instant the CL submits. Tolerate exactly that, and only while the file is
        # actually open -- an abandoned CL leaves head+1 with no open file, which
        # still fails, correctly and loudly. Self-clearing: after submit head catches
        # up and the entry matches exactly.
        $pendingEditActions = @('edit','integrate')
        if ($pendingOpens.ContainsKey($relKey) -and
            $pendingEditActions -contains $pendingOpens[$relKey] -and
            $e.depotRevision -eq ($head + 1)) {
            continue
        }
        $drift += "$($e.path) (manifest=$($e.depotRevision) head=$head)"
    }
    $notes4 = @()
    if ($blockScoped -gt 0) { $notes4 += "$blockScoped block-scoped entr$(if($blockScoped -eq 1){'y'}else{'ies'}) not revision-tracked; blockHash guards them (check 2)" }
    if ($humanOwned4 -gt 0) { $notes4 += "$humanOwned4 human-owned entr$(if($humanOwned4 -eq 1){'y'}else{'ies'}) not revision-tracked (the installer never writes them)" }
    $bsNote = $notes4 -join '; '
    if ($drift.Count -eq 0) { Ok '4. depotRevision == headRev for all managed' $bsNote }
    else { Bad '4. depotRevision == headRev for all managed' ($drift -join '; ') }
}

# 5. Every package/overlay-owned entry still has a live source in the package.
#
#    This replaces an earlier "no unmanaged depot-tracked file under .claude/,
#    Docs/agents/, Docs/MustRead/" scan. That question is unanswerable for a
#    project-agnostic package: every consumer legitimately keeps its OWN rules and
#    scripts under those roots, so the gate grew with content the package does not
#    own and blocked writes for having them. The answerable question runs the other
#    way -- if we claim to own an entry, our template must still exist -- and it is
#    checkable from two independent sources (consumer manifest vs package filesystem),
#    so it can actually fail. Catches the STALE MANAGED ENTRY: still in the manifest,
#    package source retired. It does not catch orphans (files that left the manifest
#    entirely); the report-only scan below is what surfaces those.
$staleManaged = @()
foreach ($e in $m.files) {
    if ($e.owner -ne 'package' -and $e.owner -ne 'overlay') { continue }
    # The manifest's own entry is generated by the installer, never rendered from a
    # template -- same reason check 4 skips it.
    if ($e.hashPolicy -eq 'self-excluded') { continue }
    $src = $e.sourceTemplate
    if ([string]::IsNullOrWhiteSpace($src) -or $src -eq 'None') {
        $staleManaged += "$($e.path) (owner=$($e.owner), no sourceTemplate)"
        continue
    }
    if (-not (Test-Path -LiteralPath (Join-Path $PackageRoot $src))) {
        $staleManaged += "$($e.path) (sourceTemplate missing: $src)"
    }
}
if ($staleManaged.Count -eq 0) {
    Ok '5. package/overlay-owned entries all resolve to a live template' "$(@($m.files | Where-Object { $_.owner -eq 'package' -or $_.owner -eq 'overlay' }).Count) entries"
} else {
    Bad '5. package/overlay-owned entries all resolve to a live template' (($staleManaged | Select-Object -First 5) -join '; ')
}

# 5b. Report-only: depot-tracked files under scaffold roots that no manifest entry
#     names. Consumer-local content is EXPECTED here -- this can never fail a write.
#     Exemption: files open-for-delete in a pending CL are deliberately going away.
if (-not $p4Available -or -not $depotRoot) {
    Skip '5b. unmanaged depot-tracked files under scaffold roots (report-only)' 'p4 client or depot root not resolved'
} else {
    $scanRoots = @('.claude','Docs/agents','Docs/MustRead')
    $manifestPaths = @{}
    foreach ($e in $m.files) { $manifestPaths[$e.path.Replace('\','/')] = $true }
    $pendingDeleteActions = @('delete','move/delete')
    $unmanaged = @(); $unresolvedRoots = @()
    $haveRx = '^' + [regex]::Escape("$depotRoot/") + '(\S+)#\d+'
    foreach ($root in $scanRoots) {
        # `p4 have` writes "file(s) not on client" to STDERR for a root that is not
        # in the client view; cmd /c swallows it before PowerShell can turn it into
        # a terminating error under $ErrorActionPreference='Stop'.
        $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
        $have = (& cmd /c "p4 have ""$depotRoot/$root/..."" 2>nul")
        $rootExit = $LASTEXITCODE
        $ErrorActionPreference = $prev
        # Non-zero covers BOTH "root absent from the view" and "root present but
        # empty", so an empty result is never reported as "nothing to see here".
        if ($rootExit -ne 0 -and @($have).Count -eq 0) { $unresolvedRoots += $root; continue }
        foreach ($line in $have) {
            if ($line -match $haveRx) {
                $rel = $Matches[1]
                if ($manifestPaths.ContainsKey($rel)) { continue }
                if ($pendingOpens.ContainsKey($rel) -and $pendingDeleteActions -contains $pendingOpens[$rel]) { continue }
                $unmanaged += $rel
            }
        }
    }
    $notes = @()
    if ($unmanaged.Count -gt 0)       { $notes += "$($unmanaged.Count) unmanaged: " + (($unmanaged | Select-Object -First 5) -join '; ') }
    if ($unresolvedRoots.Count -gt 0) { $notes += "unresolved roots: " + ($unresolvedRoots -join ', ') }
    if ($notes.Count -eq 0) { Ok '5b. unmanaged depot-tracked files under scaffold roots (report-only)' }
    else { Warn '5b. unmanaged depot-tracked files under scaffold roots (report-only)' ($notes -join ' | ') }
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
    foreach ($t in 'codex','claudeCode') {
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
$summary = "Skeleton preflight: $pass passed, $fail failed, $skip skipped"
if ($warn -gt 0) { $summary += ", $warn warned (report-only, does not gate)" }
Write-Output $summary
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
