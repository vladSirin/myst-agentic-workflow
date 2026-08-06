# run-compare-tests.ps1 - compare-with-package.ps1 verification (issue 10)
#
# Builds a synthetic 3-file fixture (package + pinned-snapshot + target) and
# exercises each of the four outcomes plus the meta-conflict path.
#
#   exit 0 : all checks pass
#   exit 1 : one or more checks failed
param()

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$compare = Join-Path $here 'compare-with-package.ps1'

$pass = 0; $fail = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }

function New-Fixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ("compare-fx-" + [guid]::NewGuid().ToString('N'))
    $pkg     = Join-Path $root 'pkg'
    $pinned  = Join-Path $root 'pinned'
    $target  = Join-Path $root 'target'
    foreach ($d in @($pkg,'templates','common','core'),
                    @($pkg,'templates','common','dir'),
                    @($pinned,'templates','common','dir'),
                    @($target,'Docs','agents')) {
        New-Item -ItemType Directory -Path (Join-Path -Path $d[0] -ChildPath ($d[1..($d.Length-1)] -join '\')) -Force | Out-Null
    }

    # Common template content (LF, no BOM).
    $tplA = "alpha-content`n"
    $tplB = "beta-content`n"
    $tplC = "gamma-content`n"

    foreach ($p in @(
        @($pkg,    'templates/common/dir/a.md', $tplA),
        @($pkg,    'templates/common/dir/b.md', $tplB),
        @($pkg,    'templates/common/dir/c.md', $tplC),
        @($pinned, 'templates/common/dir/a.md', $tplA),
        @($pinned, 'templates/common/dir/b.md', $tplB),
        @($pinned, 'templates/common/dir/c.md', $tplC),
        @($target, 'a.md', $tplA),
        @($target, 'b.md', $tplB),
        @($target, 'c.md', $tplC)
    )) {
        $fp = Join-Path $p[0] ($p[1] -replace '/','\')
        New-Item -ItemType Directory -Path (Split-Path $fp -Parent) -Force | Out-Null
        [IO.File]::WriteAllBytes($fp, [Text.Encoding]::UTF8.GetBytes($p[2]))
    }

    $pkgMan = @{ package = @{ name='fx'; version='0.1.0' }; manifestSchema = @{ schemaVersion = 3; overlays = @('core') } } | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText((Join-Path $pkg 'package-manifest.json'), $pkgMan)

    $instMan = @{
        schemaVersion = 3
        installedProject = @{ name='fxproj'; docsRoot='Docs'; gameDocsRoot='Docs' }
        files = @(
            @{ path='a.md'; tool='common'; owner='package'; ownerOverlay='core'; sourceTemplate='templates/common/dir/a.md'; mergeStrategy='copy'; hashPolicy='sha256'; contentHash=$null; localOnly=$false; baselineState='submitted'; depotRevision=1; blockHashPolicy='not-applicable'; blockHash=$null }
            @{ path='b.md'; tool='common'; owner='package'; ownerOverlay='core'; sourceTemplate='templates/common/dir/b.md'; mergeStrategy='copy'; hashPolicy='sha256'; contentHash=$null; localOnly=$false; baselineState='submitted'; depotRevision=1; blockHashPolicy='not-applicable'; blockHash=$null }
            @{ path='c.md'; tool='common'; owner='package'; ownerOverlay='core'; sourceTemplate='templates/common/dir/c.md'; mergeStrategy='copy'; hashPolicy='sha256'; contentHash=$null; localOnly=$false; baselineState='submitted'; depotRevision=1; blockHashPolicy='not-applicable'; blockHash=$null }
        )
    } | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText((Join-Path $target ('Docs/agents/scaffold-manifest.json' -replace '/','\')), $instMan)

    return @{ Root=$root; Pkg=$pkg; Pinned=$pinned; Target=$target }
}

function Invoke-Compare($fx, [string]$Pinned = $null) {
    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$compare,'-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Output','json')
    if ($Pinned) { $argList += @('-PinnedSnapshotRoot',$Pinned) }
    $out = & powershell.exe @argList
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

# 1. ALL CLEAN.
$fx = New-Fixture
$r = Invoke-Compare $fx $fx.Pinned
if ($r.Code -eq 0 -and $r.Out -match '"outcome":\s*"clean"' -and $r.Out -notmatch '"outcome":\s*"conflict"') {
    Ok 'outcome=clean: 3/3 entries clean, exit 0'
} else { Bad 'all-clean' "code=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

# 2. DOWNSTREAM-EDIT.
$fx = New-Fixture
[IO.File]::WriteAllBytes((Join-Path $fx.Target 'a.md'), [Text.Encoding]::UTF8.GetBytes("alpha-LOCAL-EDIT`n"))
$r = Invoke-Compare $fx $fx.Pinned
if ($r.Code -eq 0 -and $r.Out -match '"outcome":\s*"downstream-edit"') {
    Ok 'outcome=downstream-edit: disk diverges, package matches pinned, exit 0'
} else { Bad 'downstream-edit' "code=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

# 3. UPSTREAM-UPDATE.
$fx = New-Fixture
[IO.File]::WriteAllBytes((Join-Path $fx.Pkg ('templates/common/dir/a.md' -replace '/','\')), [Text.Encoding]::UTF8.GetBytes("alpha-UPSTREAM-NEW`n"))
# Now disk (a.md) still matches old pinned/template; but package vs pinned differs;
# however disk doesn't match new package render. Adjust: keep disk byte-equal to PINNED for upstream-update.
# Actually compare-with-package compares disk to RENDERED PACKAGE TEMPLATE, not to pinned. With upstream changed,
# disk no longer matches rendered -- which would be 'downstream-edit' OR 'conflict' depending on upstreamMatches.
# upstreamMatches comes from pinned vs package: pinned != package now -> upstreamMatches = false.
# diskMatches: disk content "alpha-content" vs rendered "alpha-UPSTREAM-NEW" -> false.
# Both false -> 'conflict'. To get 'upstream-update' we'd need diskMatches=true AND upstreamMatches=false:
# disk would need to match the NEW package. Set disk = NEW package content.
[IO.File]::WriteAllBytes((Join-Path $fx.Target 'a.md'), [Text.Encoding]::UTF8.GetBytes("alpha-UPSTREAM-NEW`n"))
$r = Invoke-Compare $fx $fx.Pinned
if ($r.Code -eq 0 -and $r.Out -match '"outcome":\s*"upstream-update"') {
    Ok 'outcome=upstream-update: disk matches new package, pinned diverges from package, exit 0'
} else { Bad 'upstream-update' "code=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

# 4. CONFLICT.
$fx = New-Fixture
[IO.File]::WriteAllBytes((Join-Path $fx.Target 'a.md'), [Text.Encoding]::UTF8.GetBytes("alpha-DOWNSTREAM-EDIT`n"))
[IO.File]::WriteAllBytes((Join-Path $fx.Pkg ('templates/common/dir/a.md' -replace '/','\')), [Text.Encoding]::UTF8.GetBytes("alpha-UPSTREAM-NEW`n"))
$r = Invoke-Compare $fx $fx.Pinned
if ($r.Code -eq 1 -and $r.Out -match '"outcome":\s*"conflict"') {
    Ok 'outcome=conflict: both disk and upstream diverge, exit 1'
} else { Bad 'conflict' "code=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

# 5. META-CONFLICT (schema version mismatch).
$fx = New-Fixture
$badPkgMan = @{ package = @{ name='fx' }; manifestSchema = @{ schemaVersion = 99; overlays = @('core') } } | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText((Join-Path $fx.Pkg 'package-manifest.json'), $badPkgMan)
$r = Invoke-Compare $fx $null
if ($r.Code -eq 1 -and $r.Out -match 'schemaVersion mismatch') {
    Ok 'meta-conflict: schemaVersion mismatch detected, exit 1'
} else { Bad 'meta-conflict' "code=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "=============================================================="
Write-Output "Compare tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
