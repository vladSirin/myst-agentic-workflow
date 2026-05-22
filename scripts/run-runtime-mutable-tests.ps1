# run-runtime-mutable-tests.ps1 -- hashPolicy='runtime-mutable' behavior
#
# Verifies the v1.7.0 policy for files that tools mutate at runtime
# (e.g., opencode.json's permission block). Expected behavior:
#   1. preflight check 2 ignores the entry (no hash check).
#   2. compare-with-package reports 'runtime-mutable' outcome (not
#      'downstream-edit', not 'clean'); exit code 0.
#   3. install.ps1 seeds the file when missing; preserves it when present.
#   4. The entry stays tracked in the manifest (not local-only).
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0
function Ok($n)         { Write-Host ("[PASS] {0}" -f $n);          $script:pass++ }
function Bad($n, $why)  { Write-Host ("[FAIL] {0}: {1}" -f $n,$why); $script:fail++ }

function New-Fixture {
    $t = Join-Path $env:TEMP ('rm-test-' + [guid]::NewGuid().ToString('N'))
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

# --- Bootstrap a fresh consumer; opencode.json template carries
#     hashPolicy=runtime-mutable per v1.7.0. ---
$t = New-Fixture
$r = Invoke-PS (Join-Path $pkg 'scripts\init-consumer.ps1') @(
    '-TargetRoot', $t, '-PackageRoot', $pkg,
    '-ProjectName', 'RuntimeTest', '-Tools', 'all', '-Overlays', 'core',
    '-VersionControl', 'filesystem'
)
if ($r.Code -ne 0) {
    Bad 'init-consumer exit 0' "code=$($r.Code) out=$($r.Out)"
} else {
    $man = Get-Content -Raw (Join-Path $t 'Docs\agents\scaffold-manifest.json') | ConvertFrom-Json
    $oc = $man.files | Where-Object { $_.path -eq 'opencode.json' } | Select-Object -First 1
    if ($oc -and $oc.hashPolicy -eq 'runtime-mutable') {
        Ok 'opencode.json hashPolicy=runtime-mutable in bootstrap manifest'
    } else {
        Bad 'opencode.json runtime-mutable in bootstrap' "got hashPolicy=$($oc.hashPolicy)"
    }
}

# --- First install: opencode.json should land (seed-on-first-install) ---
$r = Invoke-PS (Join-Path $pkg 'scripts\install.ps1') @(
    '-TargetRoot', $t, '-PackageRoot', $pkg,
    '-Tools', 'all', '-Overlays', 'core', '-Mode', 'Write'
)
if ($r.Code -ne 0) { Bad 'install -Mode Write exit 0' "code=$($r.Code)`n$($r.Out)" }
elseif (Test-Path -LiteralPath (Join-Path $t 'opencode.json')) {
    Ok 'first install seeds opencode.json from template'
} else {
    Bad 'first install seeds opencode.json' 'file not present after Mode=Write'
}

# --- Simulate runtime mutation: append a permission line OpenCode might add ---
$ocPath = Join-Path $t 'opencode.json'
$originalContent = Get-Content -Raw $ocPath
$mutated = $originalContent -replace '"mcp"', '"lsp": true,`n  "mcp"'
[IO.File]::WriteAllText($ocPath, $mutated, [Text.Encoding]::UTF8)

# --- compare-with-package: should report opencode.json as 'runtime-mutable',
#     and conflictCount should still be 0 ---
$r = Invoke-PS (Join-Path $pkg 'scripts\compare-with-package.ps1') @(
    '-TargetRoot', $t, '-PackageRoot', $pkg, '-Output', 'json'
)
if ($r.Code -ne 0) {
    Bad 'compare-with-package exit 0 with runtime-mutable drift' "code=$($r.Code)`n$($r.Out)"
} else {
    $jsonStart = $r.Out.IndexOf('{')
    $j = $r.Out.Substring($jsonStart) | ConvertFrom-Json
    $ocOut = $j.entries | Where-Object { $_.Path -eq 'opencode.json' } | Select-Object -First 1
    if ($ocOut -and $ocOut.Outcome -eq 'runtime-mutable') {
        Ok 'compare reports opencode.json as runtime-mutable (not downstream-edit)'
    } else {
        Bad 'compare runtime-mutable outcome' "got Outcome=$($ocOut.Outcome)"
    }
    if ($j.conflictCount -eq 0) {
        Ok 'compare conflictCount=0 (runtime-mutable does not count as conflict)'
    } else {
        Bad 'compare conflictCount=0' "got $($j.conflictCount)"
    }
}

# --- Second install: opencode.json should NOT be overwritten (mutated state preserved) ---
$preInstall = Get-Content -Raw $ocPath
$r = Invoke-PS (Join-Path $pkg 'scripts\install.ps1') @(
    '-TargetRoot', $t, '-PackageRoot', $pkg,
    '-Tools', 'all', '-Overlays', 'core', '-Mode', 'Write'
)
if ($r.Code -ne 0) { Bad 'second install exit 0' "code=$($r.Code)`n$($r.Out)" }
else {
    $postInstall = Get-Content -Raw $ocPath
    if ($postInstall -eq $preInstall) {
        Ok 'second install preserves runtime-mutated opencode.json content'
    } else {
        Bad 'second install preserves content' 'opencode.json was rewritten by install'
    }
}

# --- preflight: should pass check 2 even with mutated opencode.json
#     (runtime-mutable entries skipped) ---
$r = Invoke-PS (Join-Path $pkg 'scripts\run-skeleton-preflight.ps1') @('-TargetRoot', $t)
if ($r.Out -match 'PASS\s+2\.\s+all non-self hashes match') {
    Ok 'preflight check 2 passes despite mutated opencode.json'
} else {
    Bad 'preflight check 2 passes' 'check 2 still failing on opencode.json'
}

Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Runtime-mutable tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
