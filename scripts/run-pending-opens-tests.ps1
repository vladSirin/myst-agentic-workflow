# run-pending-opens-tests.ps1 -- Preflight checks 4 and 5 must distinguish
# pending-CL state (open-for-add, open-for-delete) from real drift / real
# unmanaged files. Uses a fake p4 shim (scripts/fake-p4.ps1) prepended to
# PATH so checks run end-to-end without touching the live depot.
#
# Scenarios:
#   A. Baseline      -- managed file with matching headRev, no opens.   PASS 10/10.
#   B. Pending add   -- manifest entry exists, p4 reports no headRev,
#                       p4 opened says action=add.                       PASS 10/10.
#   C. Pending delete-- depot has file (p4 have), manifest does NOT,
#                       p4 opened says action=delete.                    PASS 10/10.
#   D. Mixed         -- B and C together (simulates structural CL).      PASS 10/10.
#   E. Real drift    -- manifest depotRevision != headRev, no opens.    FAIL on check 4.
#   F. Real unmanaged-- depot file absent from manifest, NOT in opens.  FAIL on check 5.
#   G-I. human-owned / check 6 split (see inline headers).
#   J. Add-then-submit -- entry recorded null while the add was pending;
#                       after submit head=1. Must PASS: null is not a claim.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$pass = 0; $fail = 0
function Ok($n)         { Write-Host ("[PASS] {0}" -f $n);          $script:pass++ }
function Bad($n, $why)  { Write-Host ("[FAIL] {0}: {1}" -f $n,$why); $script:fail++ }

# --- Fake-p4 shim: write a p4.bat wrapper in a temp dir, point it at fake-p4.ps1.
$shimDir = Join-Path $env:TEMP ('p4-shim-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $shimDir -Force | Out-Null
$shimBat = Join-Path $shimDir 'p4.bat'
@"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$here\fake-p4.ps1" %*
"@ | Set-Content -Path $shimBat -Encoding ASCII

$origPath = $env:PATH

function Reset-Env {
    Remove-Item Env:FAKE_P4_CLIENT_ROOT,Env:FAKE_P4_OPENED,Env:FAKE_P4_OPENED_DEFAULT,`
                Env:FAKE_P4_HAVE,Env:FAKE_P4_FSTAT -ErrorAction SilentlyContinue
}

function New-FixtureRoot {
    $r = Join-Path $env:TEMP ('preflight-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $r -Force | Out-Null
    return $r
}

function Write-Fixture-File($root, $relPath, $content) {
    $full = Join-Path $root $relPath
    $parent = Split-Path -Parent $full
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($full, $content, [System.Text.UTF8Encoding]::new($false))
    # Raw-byte hash. Fixtures here are LF-only + no BOM, so this equals the EOL/BOM-invariant
    # contentHash the preflight/audit now compute (Get-NormalizedContentHash). If a CRLF or
    # BOM fixture is ever added, switch this to Get-NormalizedContentHash to stay honest.
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return 'sha256:' + [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','').ToLowerInvariant()
}

function Write-Fixture-Manifest($root, $files) {
    $manifestRel = 'Docs/agents/scaffold-manifest.json'
    $manifestFull = Join-Path $root $manifestRel
    $manifestDir = Split-Path -Parent $manifestFull
    if (-not (Test-Path -LiteralPath $manifestDir)) {
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    }
    # FLATTEN. Callers pass e.g. @( (New-Entry ...), (New-LocalOnlyEntries) ) where
    # the helper returns an ARRAY -- without this the manifest gets a nested array
    # as a single "entry", and $e.<field> then member-enumerates into Object[].
    # It went unnoticed because every earlier check skipped that pseudo-entry via a
    # truthy $e.localOnly; the first check to read $e.owner instead crashed on it.
    $flat = @($files | ForEach-Object { $_ })
    $obj = [pscustomobject]@{
        schemaVersion = 3
        toolCapabilities = [pscustomobject]@{}
        files = $flat
    }
    $json = $obj | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($manifestFull, $json, [System.Text.UTF8Encoding]::new($false))

    # Materialise a fake PACKAGE root alongside the fixture, holding one file per
    # sourceTemplate. Check 5 asserts that every package/overlay-owned entry still
    # resolves to a live template, so a fixture whose templates do not exist would
    # fail for a reason the scenario is not about.
    foreach ($e in $flat) {
        if (-not $e.sourceTemplate) { continue }
        $tpl = Join-Path (Join-Path $root '_fakepkg') $e.sourceTemplate
        $tplDir = Split-Path -Parent $tpl
        if (-not (Test-Path -LiteralPath $tplDir)) { New-Item -ItemType Directory -Path $tplDir -Force | Out-Null }
        Set-Content -LiteralPath $tpl -Value 'fixture template' -NoNewline
    }
}

function Invoke-Preflight($root) {
    $env:PATH = "$shimDir;$origPath"
    $env:FAKE_P4_CLIENT_ROOT = (Resolve-Path -LiteralPath $root).Path
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass `
            -File (Join-Path $here 'run-skeleton-preflight.ps1') -TargetRoot $root `
            -PackageRoot (Join-Path $root '_fakepkg') 2>&1
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out | Out-String) }
    } finally {
        $ErrorActionPreference = $prev
        $env:PATH = $origPath
    }
}

# A standard entry for managed files. Schema mirrors the real consumer's
# manifest (init-consumer emits all fields). Markers.ps1 sets StrictMode
# Latest, which propagates to preflight -- missing properties throw.
function New-Entry($relPath, $contentHash, $depotRevision, [bool]$localOnly = $false) {
    [pscustomobject]@{
        path              = $relPath
        tool              = 'common'
        owner             = 'package'
        ownerOverlay      = $null
        sourceTemplate    = "templates/test/$relPath"
        sourceCommit      = 'test'
        contentHash       = $contentHash
        hashPolicy        = 'sha256'
        mergeStrategy     = 'full-file-override'
        localOnly         = $localOnly
        writablePolicy    = 'installer-owned'
        baselineState     = 'submitted'
        conflictReport    = $null
        lastCheckedAt     = '2026-05-23T00:00:00Z'
        pendingChangelist = $null
        depotRevision     = $depotRevision
        upstreamDerived   = $false
        upstreamLicense   = $null
        blockHashPolicy   = 'not-applicable'
        blockHash         = $null
    }
}

# Two localOnly entries to mirror the real consumer (9 entries). Single-item
# pipeline output from Where-Object yields one PSCustomObject under strict
# mode; .Count then throws (PropertyNotFoundStrict). Two entries guarantee
# the pipeline result is array-shaped, matching production.
function New-LocalOnlyEntries() {
    @(
        (New-Entry '.claude/settings.local.json' 'sha256:0' $null $true),
        (New-Entry '.claude/scheduled_tasks.lock' 'sha256:0' $null $true)
    )
}

###############################################################################
# Scenario A: Baseline (no pending opens, head matches manifest)
###############################################################################
Reset-Env
$rootA = New-FixtureRoot
$hashA1 = Write-Fixture-File $rootA '.claude/skills/a.md' "alpha`n"
Write-Fixture-Manifest $rootA @(
    (New-Entry '.claude/skills/a.md' $hashA1 1),
    (New-LocalOnlyEntries)
)
$env:FAKE_P4_FSTAT = "//UEPrototype/main/.claude/skills/a.md=1"
$env:FAKE_P4_HAVE  = "//UEPrototype/main/.claude/skills/a.md#1"
$resA = Invoke-Preflight $rootA
if ($resA.Code -eq 0) { Ok 'A. baseline preflight passes 10/10' }
else { Bad 'A. baseline preflight passes 10/10' "code=$($resA.Code)`n$($resA.Out)" }

###############################################################################
# Scenario B: Pending add (manifest entry exists, no headRev, opened-for-add)
###############################################################################
Reset-Env
$rootB = New-FixtureRoot
$hashB1 = Write-Fixture-File $rootB '.claude/skills/b.md' "beta`n"
Write-Fixture-Manifest $rootB @(
    (New-Entry '.claude/skills/b.md' $hashB1 1),
    (New-LocalOnlyEntries)
)
# headRev is empty (file not yet submitted), p4 opened reports open-for-add.
$env:FAKE_P4_FSTAT  = ""
$env:FAKE_P4_HAVE   = ""
$env:FAKE_P4_OPENED = "//UEPrototype/main/.claude/skills/b.md#1 - add change 999 (text)"
$resB = Invoke-Preflight $rootB
if ($resB.Code -eq 0) { Ok 'B. pending-add does not flag check 4 as drift' }
else { Bad 'B. pending-add does not flag check 4 as drift' "code=$($resB.Code)`n$($resB.Out)" }

###############################################################################
# Scenario C: Pending delete (depot has file, not in manifest, opened-for-delete)
###############################################################################
Reset-Env
$rootC = New-FixtureRoot
$hashC1 = Write-Fixture-File $rootC '.claude/skills/c.md' "gamma`n"
Write-Fixture-Manifest $rootC @(
    (New-Entry '.claude/skills/c.md' $hashC1 1),
    (New-LocalOnlyEntries)
)
# Depot still has another file (c-old.md) that has been removed from manifest
# and opened-for-delete in a pending CL.
$env:FAKE_P4_FSTAT = "//UEPrototype/main/.claude/skills/c.md=1"
$env:FAKE_P4_HAVE = @(
    "//UEPrototype/main/.claude/skills/c.md#1",
    "//UEPrototype/main/.claude/skills/c-old.md#3"
) -join "`n"
$env:FAKE_P4_OPENED = "//UEPrototype/main/.claude/skills/c-old.md#3 - delete change 999 (text)"
$resC = Invoke-Preflight $rootC
if ($resC.Code -eq 0) { Ok 'C. pending-delete does not flag check 5 as unmanaged' }
else { Bad 'C. pending-delete does not flag check 5 as unmanaged' "code=$($resC.Code)`n$($resC.Out)" }

###############################################################################
# Scenario D: Mixed structural CL (one add + one delete in the same scenario)
###############################################################################
Reset-Env
$rootD = New-FixtureRoot
$hashD1 = Write-Fixture-File $rootD '.claude/skills/d-new.md' "new`n"
Write-Fixture-Manifest $rootD @(
    (New-Entry '.claude/skills/d-new.md' $hashD1 1),
    (New-LocalOnlyEntries)
)
$env:FAKE_P4_FSTAT  = ""
$env:FAKE_P4_HAVE   = "//UEPrototype/main/.claude/skills/d-old.md#7"
$env:FAKE_P4_OPENED = @(
    "//UEPrototype/main/.claude/skills/d-new.md#1 - add change 1000 (text)",
    "//UEPrototype/main/.claude/skills/d-old.md#7 - delete change 1000 (text)"
) -join "`n"
$resD = Invoke-Preflight $rootD
if ($resD.Code -eq 0) { Ok 'D. mixed structural CL (add + delete) passes 10/10' }
else { Bad 'D. mixed structural CL (add + delete) passes 10/10' "code=$($resD.Code)`n$($resD.Out)" }

###############################################################################
# Scenario E: Real drift (regression check -- check 4 must still fail)
###############################################################################
Reset-Env
$rootE = New-FixtureRoot
$hashE1 = Write-Fixture-File $rootE '.claude/skills/e.md' "epsilon`n"
Write-Fixture-Manifest $rootE @(
    (New-Entry '.claude/skills/e.md' $hashE1 1),
    (New-LocalOnlyEntries)
)
# Manifest says depotRevision=1 but head is 5; no pending opens.
$env:FAKE_P4_FSTAT = "//UEPrototype/main/.claude/skills/e.md=5"
$env:FAKE_P4_HAVE  = "//UEPrototype/main/.claude/skills/e.md#5"
$resE = Invoke-Preflight $rootE
if ($resE.Code -ne 0 -and $resE.Out -match 'FAIL\s+4\.') { Ok 'E. real drift still fails check 4 (no false negatives)' }
else { Bad 'E. real drift still fails check 4' "code=$($resE.Code)`n$($resE.Out)" }

###############################################################################
# Scenario F: Real unmanaged (regression check -- check 5 must still fail)
###############################################################################
Reset-Env
$rootF = New-FixtureRoot
$hashF1 = Write-Fixture-File $rootF '.claude/skills/f.md' "phi`n"
Write-Fixture-Manifest $rootF @(
    (New-Entry '.claude/skills/f.md' $hashF1 1),
    (New-LocalOnlyEntries)
)
# Depot has an extra file not in manifest and not in opens -- real unmanaged.
$env:FAKE_P4_FSTAT = "//UEPrototype/main/.claude/skills/f.md=1"
$env:FAKE_P4_HAVE = @(
    "//UEPrototype/main/.claude/skills/f.md#1",
    "//UEPrototype/main/.claude/skills/stray.md#1"
) -join "`n"
$resF = Invoke-Preflight $rootF
# Semantics changed deliberately in 4.16.0: an unmanaged depot-tracked file under a
# scaffold root is REPORTED by check 5b and no longer gates. A consumer's own rules
# and scripts legitimately live under those roots, so failing on them made the write
# gate unusable for every project that owns anything there. What must NOT regress is
# the reporting: silence would hide a genuine orphan.
if ($resF.Code -eq 0 -and $resF.Out -match 'WARN\s+5b\.' -and $resF.Out -match 'stray\.md') {
    Ok 'F. real unmanaged is reported by check 5b and does not gate'
} else {
    Bad 'F. real unmanaged is reported by check 5b and does not gate' "code=$($resF.Code)`n$($resF.Out)"
}

###############################################################################
# Scenario G: human-owned files are the CONSUMER'S. The installer never writes
# them, so neither their hash nor their revision may gate a write. Without this,
# editing a doc you own closes the gate until someone hand-patches the manifest --
# the same defect the block-scoped exemption fixed, one category wider.
###############################################################################
Reset-Env
$rootG = New-FixtureRoot
$null = Write-Fixture-File $rootG '.claude/rules/TeamRule.md' "the team's own rule`n"  # real hash discarded on purpose
$entryG = New-Entry '.claude/rules/TeamRule.md' 'sha256:deliberately-stale' 3
$entryG.writablePolicy = 'human-owned'
$entryG.mergeStrategy  = 'manual-only'
$entryG.owner          = 'project'
$entryG.sourceTemplate = $null          # project-owned: no package template backs it
Write-Fixture-Manifest $rootG @($entryG, (New-LocalOnlyEntries))
# Depot says rev 7; the manifest says 3; the on-disk hash matches neither. A file
# the installer owns would fail both checks here -- a human-owned one must not.
$env:FAKE_P4_FSTAT = "//UEPrototype/main/.claude/rules/TeamRule.md=7"
$env:FAKE_P4_HAVE  = "//UEPrototype/main/.claude/rules/TeamRule.md#7"
$resG = Invoke-Preflight $rootG
if ($resG.Code -eq 0 -and $resG.Out -notmatch 'FAIL\s+2\.' -and $resG.Out -notmatch 'FAIL\s+4\.') {
    Ok 'G. human-owned file with stale hash AND stale revision does not gate checks 2/4'
} else {
    Bad 'G. human-owned file does not gate checks 2/4' "code=$($resG.Code)`n$($resG.Out)"
}

###############################################################################
# Scenario H: check 6 split (2026-08-06) -- a DEPOT-TRACKED localOnly file
# (the reference consumer commits .claude/settings.json as team config) open
# for EDIT in a pending CL is legitimate workflow -> preflight passes.
###############################################################################
Reset-Env
$rootH = New-FixtureRoot
$hashH1 = Write-Fixture-File $rootH '.claude/skills/h.md' "eta`n"
Write-Fixture-File $rootH '.claude/settings.json' "{}`n" | Out-Null
Write-Fixture-Manifest $rootH @(
    (New-Entry '.claude/skills/h.md' $hashH1 1),
    (New-Entry '.claude/settings.json' 'sha256:0' $null $true),
    (New-LocalOnlyEntries)
)
$env:FAKE_P4_FSTAT  = "//UEPrototype/main/.claude/skills/h.md=1;//UEPrototype/main/.claude/settings.json=8"
$env:FAKE_P4_HAVE   = "//UEPrototype/main/.claude/skills/h.md#1`n//UEPrototype/main/.claude/settings.json#8"
$env:FAKE_P4_OPENED = "//UEPrototype/main/.claude/settings.json#8 - edit change 999 (text+w)"
$resH = Invoke-Preflight $rootH
if ($resH.Code -eq 0 -and $resH.Out -match 'legitimate') { Ok 'H. depot-tracked localOnly open for edit passes check 6' }
else { Bad 'H. depot-tracked localOnly open for edit passes check 6' "code=$($resH.Code)`n$($resH.Out)" }

###############################################################################
# Scenario I: check 6 regression -- localOnly state NOT in the depot, opened
# for ADD (local state being swept into a CL) must still FAIL.
###############################################################################
Reset-Env
$rootI = New-FixtureRoot
$hashI1 = Write-Fixture-File $rootI '.claude/skills/i.md' "iota`n"
Write-Fixture-File $rootI '.claude/settings.local.json' "{}`n" | Out-Null
Write-Fixture-Manifest $rootI @(
    (New-Entry '.claude/skills/i.md' $hashI1 1),
    (New-LocalOnlyEntries)
)
$env:FAKE_P4_FSTAT  = "//UEPrototype/main/.claude/skills/i.md=1"
$env:FAKE_P4_HAVE   = "//UEPrototype/main/.claude/skills/i.md#1"
$env:FAKE_P4_OPENED = "//UEPrototype/main/.claude/settings.local.json#1 - add change 999 (text)"
$resI = Invoke-Preflight $rootI
if ($resI.Code -ne 0 -and $resI.Out -match 'pending ADD of local state') { Ok 'I. pending-ADD of local state still fails check 6' }
else { Bad 'I. pending-ADD of local state still fails check 6' "code=$($resI.Code)`n$($resI.Out)" }

###############################################################################
# Scenario J: pending-ADD then SUBMIT (2026-08-07). An entry created while its
# file was a pending add carries depotRevision=null -- correct at that moment,
# and check 4 skips it while the add is still open (scenario B). But once the CL
# SUBMITS, head becomes 1 and null matches nothing, so the entry gated the
# consumer's routine update path permanently. The only exit was upgrade.ps1 --
# the heavyweight path a routine update exists to avoid.
#
# Contrast the pending-EDIT tolerance directly above it in check 4, which records
# head+1 and therefore self-clears on submit by construction. The add path had no
# such value: null is the ABSENCE of a recorded revision, not a claim that can
# contradict the depot.
#
# Observed live on the reference consumer during the v4.29.0 propagation:
# .claude/scripts/check-rules-alignment.sh, added by upgrade in change 2142 and
# submitted as change 2145, blocked the next update.ps1 run outright.
###############################################################################
Reset-Env
$rootJ = New-FixtureRoot
$hashJ1 = Write-Fixture-File $rootJ '.claude/skills/j.md' "jota`n"
Write-Fixture-Manifest $rootJ @(
    (New-Entry '.claude/skills/j.md' $hashJ1 $null),
    (New-LocalOnlyEntries)
)
# The add has SUBMITTED: head exists and nothing is open any more.
$env:FAKE_P4_FSTAT = "//UEPrototype/main/.claude/skills/j.md=1"
$env:FAKE_P4_HAVE  = "//UEPrototype/main/.claude/skills/j.md#1"
$resJ = Invoke-Preflight $rootJ
if ($resJ.Code -eq 0) { Ok 'J. null depotRevision after submit does not gate the write path' }
else { Bad 'J. null depotRevision after submit does not gate the write path' "code=$($resJ.Code)`n$($resJ.Out)" }

# Cleanup fake-p4 dir.
Reset-Env
$env:PATH = $origPath
Remove-Item -Recurse -Force $shimDir -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=============================================================="
Write-Host ("pending-opens tests: {0} passed, {1} failed" -f $pass,$fail)
Write-Host "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }

