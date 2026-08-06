# run-promote-tests.ps1 - promote-from-project.ps1 write-mode verification (issue 11)
#
#   exit 0 : all checks pass
#   exit 1 : one or more checks failed
param()

$ErrorActionPreference = 'Stop'
$here    = $PSScriptRoot
$promote = Join-Path $here 'promote-from-project.ps1'
$install = Join-Path $here 'install.ps1'

$pass = 0; $fail = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }

function New-PromoteFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ("prom-fx-" + [guid]::NewGuid().ToString('N'))
    $pkg    = Join-Path $root 'pkg'
    $target = Join-Path $root 'target'
    New-Item -ItemType Directory -Path (Join-Path $pkg 'templates/common/dir')   -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $target 'Docs/agents')         -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $target '.scratch')            -Force | Out-Null

    # Package template that uses {{game_docs_root}}.
    $tpl = "header`nuse {{game_docs_root}}/some.md to learn more`nfooter`n"
    [IO.File]::WriteAllBytes((Join-Path $pkg 'templates/common/dir/a.md'),     [Text.Encoding]::UTF8.GetBytes($tpl))

    # Installed disk content: substituted.
    $disk = "header`nuse FxDocs/some.md to learn more`nfooter`n"
    [IO.File]::WriteAllBytes((Join-Path $target 'a.md'), [Text.Encoding]::UTF8.GetBytes($disk))

    # A local-only file to test the refusal path.
    [IO.File]::WriteAllBytes((Join-Path $target 'local.json'), [Text.Encoding]::UTF8.GetBytes("{}"))

    $instMan = @{
        schemaVersion = 3
        installedProject = @{ name='fxproj'; docsRoot='Docs'; gameDocsRoot='FxDocs' }
        files = @(
            @{ path='a.md';      tool='common'; owner='package'; ownerOverlay='core'; sourceTemplate='templates/common/dir/a.md'; mergeStrategy='copy'; hashPolicy='sha256'; contentHash=$null; localOnly=$false; baselineState='submitted'; depotRevision=1; blockHashPolicy='not-applicable'; blockHash=$null }
            @{ path='local.json'; tool='common'; owner='package'; ownerOverlay='core'; sourceTemplate=$null;                          mergeStrategy='manual-only'; hashPolicy='not-applicable'; contentHash=$null; localOnly=$true; baselineState='local-only'; depotRevision=$null; blockHashPolicy='not-applicable'; blockHash=$null }
        )
    } | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText((Join-Path $target ('Docs/agents/scaffold-manifest.json' -replace '/','\')), $instMan)

    return @{ Root=$root; Pkg=$pkg; Target=$target }
}

function Run($script, $argList) {
    $full = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$script) + $argList
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & powershell.exe @full 2>&1
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $prevPref }
    return [pscustomobject]@{ Code = $code; Out = (($out | ForEach-Object { [string]$_ }) -join "`n") }
}

# 1. Copy-strategy round-trip: edit disk -> promote -> verify package template updated.
$fx = New-PromoteFixture
$editedDisk = "header`nuse FxDocs/some.md to learn more`nEDITED-LINE`nfooter`n"
[IO.File]::WriteAllBytes((Join-Path $fx.Target 'a.md'), [Text.Encoding]::UTF8.GetBytes($editedDisk))
$r = Run $promote @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Paths','a.md','-Classification','reusable-core','-Mode','Write','-Force')
$newTpl = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes((Join-Path $fx.Pkg 'templates/common/dir/a.md')))
$newTpl = ($newTpl -replace "`r`n","`n") -replace "`r","`n"
$expected = "header`nuse {{game_docs_root}}/some.md to learn more`nEDITED-LINE`nfooter`n"
if ($r.Code -eq 0 -and $newTpl -eq $expected) {
    Ok 'copy roundtrip: edit disk -> promote -> template carries edit with {{var}} reverse-substituted'
} else { Bad 'copy roundtrip' "code=$($r.Code)  tpl=$newTpl" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

# 2. Refuses local-only entry.
$fx = New-PromoteFixture
$r = Run $promote @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Paths','local.json','-Classification','reusable-core','-Mode','Write')
if ($r.Code -ne 0 -and $r.Out -match 'WRITE MODE REFUSED') {
    Ok 'refuses local-only entry: exit non-zero with explanatory message'
} else { Bad 'refuse local-only' "code=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

# 3. Refuses upstream divergence without -Force.
$fx = New-PromoteFixture
# Modify both: disk gets edit, package template gets a DIFFERENT change.
$editedDisk = "header`nuse FxDocs/some.md`nDISK-EDIT`nfooter`n"
[IO.File]::WriteAllBytes((Join-Path $fx.Target 'a.md'), [Text.Encoding]::UTF8.GetBytes($editedDisk))
$divergedTpl = "header`nuse {{game_docs_root}}/some.md`nUPSTREAM-EDIT`nfooter`n"
[IO.File]::WriteAllBytes((Join-Path $fx.Pkg 'templates/common/dir/a.md'), [Text.Encoding]::UTF8.GetBytes($divergedTpl))
$r = Run $promote @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Paths','a.md','-Classification','reusable-core','-Mode','Write')
if ($r.Code -ne 0 -and $r.Out -match 'Upstream divergence') {
    Ok 'refuses upstream divergence without -Force'
} else { Bad 'refuse upstream divergence' "code=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

# 4. -Force overrides upstream divergence: same setup as test 3 but with -Force.
# Disk and upstream both moved; with -Force, disk-derived template overwrites upstream.
$fx = New-PromoteFixture
$editedDisk = "header`nuse FxDocs/some.md`nDISK-EDIT`nfooter`n"
[IO.File]::WriteAllBytes((Join-Path $fx.Target 'a.md'), [Text.Encoding]::UTF8.GetBytes($editedDisk))
$divergedTpl = "header`nuse {{game_docs_root}}/some.md`nUPSTREAM-EDIT`nfooter`n"
[IO.File]::WriteAllBytes((Join-Path $fx.Pkg 'templates/common/dir/a.md'), [Text.Encoding]::UTF8.GetBytes($divergedTpl))
$r = Run $promote @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Paths','a.md','-Classification','reusable-core','-Mode','Write','-Force')
$newTpl = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes((Join-Path $fx.Pkg 'templates/common/dir/a.md')))
$newTpl = ($newTpl -replace "`r`n","`n") -replace "`r","`n"
$expectedAfterForce = "header`nuse {{game_docs_root}}/some.md`nDISK-EDIT`nfooter`n"
if ($r.Code -eq 0 -and $newTpl -eq $expectedAfterForce) {
    Ok '-Force overrides upstream divergence: writes disk-derived template'
} else { Bad '-Force override' "code=$($r.Code) tpl=$newTpl" }
Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "=============================================================="
Write-Output "Promote tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
