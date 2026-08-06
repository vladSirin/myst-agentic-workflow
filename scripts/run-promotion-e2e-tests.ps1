# run-promotion-e2e-tests.ps1 - Phase 4 verification gate (issue 12)
#
# Two scenarios, end-to-end in a filesystem-only fixture (no Perforce):
#   1. Edit -> classify -> promote -> verify parity (compare reports clean)
#   2. Bilateral edit -> conflict detected -> promote refused without -Force
#
#   exit 0 : both scenarios pass
#   exit 1 : either scenario fails
param()

$ErrorActionPreference = 'Stop'
$here    = $PSScriptRoot
$promote = Join-Path $here 'promote-from-project.ps1'
$compare = Join-Path $here 'compare-with-package.ps1'

$pass = 0; $fail = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }

function New-E2EFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ("e2e-fx-" + [guid]::NewGuid().ToString('N'))
    $pkg     = Join-Path $root 'pkg'
    $pinned  = Join-Path $root 'pinned'
    $target  = Join-Path $root 'target'
    foreach ($d in @(
        (Join-Path $pkg     'templates/common/dir'),
        (Join-Path $pinned  'templates/common/dir'),
        (Join-Path $target  'Docs/agents'),
        (Join-Path $target  '.scratch')
    )) { New-Item -ItemType Directory -Path $d -Force | Out-Null }

    # 3-file scaffold with one var: {{game_docs_root}}.
    $files = @(
        @{ Name='a.md'; Tpl="# A`nuse {{game_docs_root}}/a.md`n"; Disk="# A`nuse FxDocs/a.md`n" },
        @{ Name='b.md'; Tpl="# B`nuse {{game_docs_root}}/b.md`n"; Disk="# B`nuse FxDocs/b.md`n" },
        @{ Name='c.md'; Tpl="# C`nuse {{game_docs_root}}/c.md`n"; Disk="# C`nuse FxDocs/c.md`n" }
    )
    foreach ($f in $files) {
        $tplPath = Join-Path $pkg    ("templates/common/dir/" + $f.Name)
        $pinPath = Join-Path $pinned ("templates/common/dir/" + $f.Name)
        $dskPath = Join-Path $target $f.Name
        [IO.File]::WriteAllBytes($tplPath, [Text.Encoding]::UTF8.GetBytes($f.Tpl))
        [IO.File]::WriteAllBytes($pinPath, [Text.Encoding]::UTF8.GetBytes($f.Tpl))
        [IO.File]::WriteAllBytes($dskPath, [Text.Encoding]::UTF8.GetBytes($f.Disk))
    }

    $pkgMan = @{ package=@{name='fx';version='0.1.0'}; manifestSchema=@{schemaVersion=3; overlays=@('core')} } | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText((Join-Path $pkg 'package-manifest.json'), $pkgMan)

    $entries = $files | ForEach-Object {
        @{ path=$_.Name; tool='common'; owner='package'; ownerOverlay='core'; sourceTemplate=("templates/common/dir/" + $_.Name);
           mergeStrategy='copy'; hashPolicy='sha256'; contentHash=$null; localOnly=$false; baselineState='submitted';
           depotRevision=1; blockHashPolicy='not-applicable'; blockHash=$null }
    }
    $instMan = @{ schemaVersion=3; installedProject=@{name='fxproj';docsRoot='Docs';gameDocsRoot='FxDocs'}; files=$entries } | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText((Join-Path $target ('Docs/agents/scaffold-manifest.json' -replace '/','\')), $instMan)

    return @{ Root=$root; Pkg=$pkg; Pinned=$pinned; Target=$target }
}

function Run($script, $argList) {
    $full = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$script) + $argList
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $out = & powershell.exe @full 2>&1; $code = $LASTEXITCODE } finally { $ErrorActionPreference = $prev }
    return [pscustomobject]@{ Code = $code; Out = (($out | ForEach-Object { [string]$_ }) -join "`n") }
}

# ----------------------------------------------------------------------------
# Scenario 1: edit -> classify -> promote -> parity
# ----------------------------------------------------------------------------
$fx = New-E2EFixture
# Step 1: edit one disk file.
$editedDisk = "# A`nuse FxDocs/a.md`nLOCAL-IMPROVEMENT`n"
[IO.File]::WriteAllBytes((Join-Path $fx.Target 'a.md'), [Text.Encoding]::UTF8.GetBytes($editedDisk))

# Step 2: classify via compare -- expect downstream-edit for a.md, clean for b/c.
$r = Run $compare @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-PinnedSnapshotRoot',$fx.Pinned,'-Output','json')
$matchesEdit  = ($r.Out -match '"path":\s*"a\.md"[\s\S]*?"outcome":\s*"downstream-edit"')
$bClean       = ($r.Out -match '"path":\s*"b\.md"[\s\S]*?"outcome":\s*"clean"')
$cClean       = ($r.Out -match '"path":\s*"c\.md"[\s\S]*?"outcome":\s*"clean"')
if ($r.Code -eq 0 -and $matchesEdit -and $bClean -and $cClean) { Ok 'scenario 1 step 2: classify reports downstream-edit for a.md only' }
else { Bad 'scenario 1 classify' "code=$($r.Code) matchesEdit=$matchesEdit bClean=$bClean cClean=$cClean" }

# Step 3: promote a.md. -Force is required by current design: any real promotion
# changes the package source, which (without a pinned-snapshot baseline) cannot
# be distinguished from "someone else changed pkg upstream". -Force = user
# acknowledges the diff (issue 11 follow-up: distinguish expected vs unexpected
# divergence via per-entry sourceCommit baseline once published).
$r = Run $promote @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Paths','a.md','-Classification','reusable-core','-Mode','Write','-Force')
if ($r.Code -eq 0) { Ok 'scenario 1 step 3: promote succeeds' }
else { Bad 'scenario 1 promote' "code=$($r.Code) out=$($r.Out)" }

# Step 4: parity -- compare again, expect all 3 entries clean.
$r = Run $compare @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Output','json')
$conflictTotal = if ($r.Out -match '"conflictCount":\s*(\d+)') { [int]$Matches[1] } else { -1 }
if ($r.Code -eq 0 -and $r.Out -notmatch '"outcome":\s*"downstream-edit"' -and $conflictTotal -eq 0) {
    Ok 'scenario 1 step 4: post-promote parity -- all entries clean'
} else { Bad 'scenario 1 parity' "code=$($r.Code) conflictTotal=$conflictTotal out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

# ----------------------------------------------------------------------------
# Scenario 2: bilateral edit -> conflict -> promote refused without -Force
# ----------------------------------------------------------------------------
$fx = New-E2EFixture
# Edit disk.
[IO.File]::WriteAllBytes((Join-Path $fx.Target 'a.md'), [Text.Encoding]::UTF8.GetBytes("# A`nuse FxDocs/a.md`nDOWNSTREAM-EDIT`n"))
# Edit upstream package template differently (pinned snapshot remains the old version).
[IO.File]::WriteAllBytes((Join-Path $fx.Pkg ('templates/common/dir/a.md' -replace '/','\')), [Text.Encoding]::UTF8.GetBytes("# A`nuse {{game_docs_root}}/a.md`nUPSTREAM-EDIT`n"))

# Compare with pinned: expect conflict on a.md, exit 1.
$r = Run $compare @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-PinnedSnapshotRoot',$fx.Pinned,'-Output','json')
if ($r.Code -eq 1 -and $r.Out -match '"outcome":\s*"conflict"') {
    Ok 'scenario 2 step 1: compare detects bilateral conflict, exit 1'
} else { Bad 'scenario 2 compare' "code=$($r.Code) out=$($r.Out)" }

# Promote without -Force: refused.
$r = Run $promote @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Paths','a.md','-Classification','reusable-core','-Mode','Write')
if ($r.Code -ne 0 -and $r.Out -match 'Upstream divergence') {
    Ok 'scenario 2 step 2: promote refused without -Force'
} else { Bad 'scenario 2 promote refusal' "code=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "=============================================================="
Write-Output "Promotion e2e tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
