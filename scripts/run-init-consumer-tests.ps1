# run-init-consumer-tests.ps1 -- init-consumer + setup.ps1 round-trip tests
#
# Verifies that init-consumer.ps1 produces a manifest that install.ps1 can act
# on, and that the full one-command flow (setup.ps1) lands files correctly.
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0
function Ok($name)        { Write-Host ("[PASS] {0}" -f $name);                 $script:pass++ }
function Bad($name, $why) { Write-Host ("[FAIL] {0}: {1}" -f $name, $why);      $script:fail++ }

function New-TempTarget {
    $t = Join-Path $env:TEMP ('init-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $t -Force | Out-Null
    return $t
}

function Invoke-PS($file, [string[]] $a) {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $file @a 2>&1
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($o | Out-String) }
    } finally { $ErrorActionPreference = $prev }
}

# --- Test 1: init-consumer writes a valid manifest ---
$t = New-TempTarget
$r = Invoke-PS (Join-Path $pkg 'scripts\init-consumer.ps1') @(
    '-TargetRoot', $t, '-PackageRoot', $pkg,
    '-ProjectName', 'Acme', '-GameDocsRoot', 'Acme/Docs',
    '-VersionControl', 'filesystem', '-Tools', 'all', '-Overlays', 'core'
)
if ($r.Code -ne 0) { Bad 'init-consumer exits 0' $r.Out }
else {
    $manPath = Join-Path $t 'Docs\agents\scaffold-manifest.json'
    if (-not (Test-Path $manPath)) { Bad 'init-consumer writes manifest' 'file not found' }
    else {
        $m = Get-Content -Raw $manPath | ConvertFrom-Json
        if ($m.schemaVersion -ne 3) { Bad 'manifest schemaVersion=3' "got $($m.schemaVersion)" }
        else { Ok 'manifest schemaVersion=3' }
        if ($m.installedProject.name -ne 'Acme') { Bad 'installedProject.name' "got $($m.installedProject.name)" }
        else { Ok 'installedProject.name injected' }
        if ($m.installedProject.gameDocsRoot -ne 'Acme/Docs') { Bad 'gameDocsRoot' "got $($m.installedProject.gameDocsRoot)" }
        else { Ok 'installedProject.gameDocsRoot injected' }
        if ($m.files.Count -lt 11) { Bad 'entry count' "got $($m.files.Count) (expected >= 11 for the committed-core bootstrap; the kit ships via the plugin since v4.0.0, and Docs/agents/ica/ was removed in v4.9.0)" }
        else { Ok ("entry count = {0}" -f $m.files.Count) }
        if ($m.files | Where-Object { $_.sourceCommit -eq '<resolved-by-init-consumer>' }) {
            Bad 'sourceCommit placeholders resolved' 'placeholder still present'
        } else { Ok 'sourceCommit placeholders resolved' }
    }
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 2: init-consumer refuses to overwrite existing manifest ---
$t = New-TempTarget
$null = Invoke-PS (Join-Path $pkg 'scripts\init-consumer.ps1') @('-TargetRoot',$t,'-PackageRoot',$pkg,'-ProjectName','One')
$r = Invoke-PS (Join-Path $pkg 'scripts\init-consumer.ps1') @('-TargetRoot',$t,'-PackageRoot',$pkg,'-ProjectName','Two')
if ($r.Code -eq 1) { Ok 'second run refuses without -Force' }
else { Bad 'second run refuses without -Force' "exit=$($r.Code)" }
$r = Invoke-PS (Join-Path $pkg 'scripts\init-consumer.ps1') @('-TargetRoot',$t,'-PackageRoot',$pkg,'-ProjectName','Three','-Force')
if ($r.Code -eq 0) { Ok 'third run with -Force overwrites' }
else { Bad 'third run with -Force overwrites' "exit=$($r.Code)" }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 3: marker stubs created for generated-block / append-fragment ---
$t = New-TempTarget
$null = Invoke-PS (Join-Path $pkg 'scripts\init-consumer.ps1') @(
    '-TargetRoot', $t, '-PackageRoot', $pkg, '-ProjectName', 'StubTest',
    '-VersionControl', 'perforce', '-Tools', 'all', '-Overlays', 'core,perforce,ue'
)
$claudeMd = Join-Path $t 'CLAUDE.md'
$p4ignore = Join-Path $t '.p4ignore'
if (Test-Path $claudeMd) { Ok 'CLAUDE.md stub created' } else { Bad 'CLAUDE.md stub created' 'not present' }
if (Test-Path $p4ignore) { Ok '.p4ignore stub created' } else { Bad '.p4ignore stub created' 'not present' }
if ((Get-Content -Raw $claudeMd) -match 'AGENTIC-SCAFFOLD:BEGIN') {
    Ok 'CLAUDE.md stub has BEGIN marker'
} else { Bad 'CLAUDE.md stub has BEGIN marker' 'marker not found' }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 4: full setup.ps1 -Yes round-trip lands sentinels ---
$t = New-TempTarget
$r = Invoke-PS (Join-Path $pkg 'setup.ps1') @('-TargetRoot',$t,'-ProjectName','RoundTrip','-Yes')
if ($r.Code -eq 0) { Ok 'setup.ps1 -Yes round-trip exits 0' }
else { Bad 'setup.ps1 -Yes round-trip exits 0' "exit=$($r.Code)`n$($r.Out)" }

$sentinels = @(
    @{ Tool='claude'; Path=(Join-Path $t '.claude\scripts\doc-audit.sh') }
    @{ Tool='common'; Path=(Join-Path $t 'Docs\agents\issue-tracker.md') }
)
foreach ($s in $sentinels) {
    if (Test-Path $s.Path) { Ok "setup landed $($s.Tool) sentinel" }
    else { Bad "setup landed $($s.Tool) sentinel" "missing at $($s.Path)" }
}
# v4.0.0: the skills kit ships via the plugin, NOT file-copy - .Codex/ and
# .claude/skills/ must NOT be created by the installer anymore
if (-not (Test-Path (Join-Path $t '.Codex')) -and -not (Test-Path (Join-Path $t '.claude\skills'))) {
    Ok 'setup does NOT file-copy the plugin-owned kit (.Codex/, .claude/skills absent)'
} else { Bad 'plugin-owned kit file-copied' 'installer still writes .Codex/ or .claude/skills/' }

# Verify CLAUDE.md got its block populated (was 289 stub, should be >1000 after write)
$claudeMd = Join-Path $t 'CLAUDE.md'
if (Test-Path $claudeMd) {
    $size = (Get-Item $claudeMd).Length
    if ($size -gt 1000) { Ok ("CLAUDE.md block populated ({0} bytes)" -f $size) }
    else { Bad 'CLAUDE.md block populated' "size=$size (still stub-sized)" }
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 5: compare-with-package reports clean after round-trip ---
$t = New-TempTarget
$null = Invoke-PS (Join-Path $pkg 'setup.ps1') @('-TargetRoot',$t,'-ProjectName','CmpTest','-Yes')
$r = Invoke-PS (Join-Path $pkg 'scripts\compare-with-package.ps1') @('-TargetRoot',$t,'-PackageRoot',$pkg,'-Output','json')
if ($r.Code -eq 0) {
    $start = $r.Out.IndexOf('{')
    $j = $r.Out.Substring($start) | ConvertFrom-Json
    if ($j.conflictCount -eq 0) { Ok 'compare-with-package: 0 conflicts after setup' }
    else { Bad 'compare-with-package: 0 conflicts after setup' "conflictCount=$($j.conflictCount)" }
} else {
    Bad 'compare-with-package exit 0' "exit=$($r.Code)"
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 6: perforce-only (non-UE Perforce consumer) ---
$t = New-TempTarget
$r = Invoke-PS (Join-Path $pkg 'scripts\init-consumer.ps1') @(
    '-TargetRoot', $t, '-PackageRoot', $pkg, '-ProjectName', 'FilmStudio',
    '-VersionControl', 'perforce', '-Tools', 'all', '-Overlays', 'core,perforce'
)
if ($r.Code -eq 0) { Ok 'init-consumer: perforce-only (no ue)' }
else { Bad 'init-consumer: perforce-only' "exit=$($r.Code)`n$($r.Out)" }
$m = Get-Content -Raw (Join-Path $t 'Docs\agents\scaffold-manifest.json') | ConvertFrom-Json
$ueEntries = @($m.files | Where-Object { $_.ownerOverlay -eq 'ue' })
if ($ueEntries.Count -eq 0) { Ok 'perforce-only excludes ue entries' }
else { Bad 'perforce-only excludes ue entries' "got $($ueEntries.Count) ue entries" }
$pfEntries = @($m.files | Where-Object { $_.ownerOverlay -eq 'perforce' })
if ($pfEntries.Count -eq 0) { Ok 'perforce overlay retired: selecting it installs nothing (v4.0.0: content lives in the plugin)' }
else { Bad 'perforce overlay retired' "got $($pfEntries.Count) entries (should be 0)" }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 7: legacy ue-perforce alias expands to perforce + ue ---
$t = New-TempTarget
$r = Invoke-PS (Join-Path $pkg 'scripts\init-consumer.ps1') @(
    '-TargetRoot', $t, '-PackageRoot', $pkg, '-ProjectName', 'LegacyAlias',
    '-VersionControl', 'perforce', '-Tools', 'all', '-Overlays', 'core,ue-perforce'
)
if ($r.Code -eq 0) { Ok 'init-consumer accepts legacy ue-perforce alias' }
else { Bad 'init-consumer ue-perforce alias' "exit=$($r.Code)`n$($r.Out)" }
$m = Get-Content -Raw (Join-Path $t 'Docs\agents\scaffold-manifest.json') | ConvertFrom-Json
$hasUe = @($m.files | Where-Object { $_.ownerOverlay -eq 'ue' }).Count -gt 0
if ($hasUe) { Ok 'ue-perforce alias still parses; ue entries land (perforce retired, installs nothing)' }
else { Bad 'ue-perforce alias' 'no ue entries landed' }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Summary ---
Write-Host ""
Write-Host "=============================================================="
Write-Host ("init-consumer + setup.ps1 tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
