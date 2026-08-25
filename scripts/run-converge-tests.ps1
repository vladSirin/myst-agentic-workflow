# run-converge-tests.ps1 -- tests for migrate-project-scope-installs.ps1
#
# Verifies the converge utility: dry-run reports without changing; -Apply removes ONLY
# project-scope records; user-scope records survive; a plugin whose records are ALL
# project-scope is skipped rather than uninstalled; the registry keeps its list shape on
# PS 5.1 (where an unguarded one-element filter serializes as an object and corrupts it);
# missing / empty / unparsable registries are stated no-ops, not crashes; and
# CLAUDE_CONFIG_DIR is honoured when -RegistryPath is omitted.
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$helper = Join-Path $pkg 'scripts/migrate-project-scope-installs.ps1'
$pass = 0; $fail = 0
function Ok($n)     { Write-Host ("[PASS] {0}" -f $n);         $script:pass++ }
function Bad($n,$w) { Write-Host ("[FAIL] {0}: {1}" -f $n,$w); $script:fail++ }

function New-Registry {
    param([string] $Json)
    $d = Join-Path $env:TEMP ('conv-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $d -Force | Out-Null
    $p = Join-Path $d 'installed_plugins.json'
    if ($null -ne $Json) { Set-Content -LiteralPath $p -Value $Json -Encoding UTF8 }
    return $p
}
function Run($argv) {
    # 5.1 deliberately: it is the version whose array unrolling corrupts the registry.
    $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $helper @argv 2>&1
    return ($o | Out-String)
}

$MIXED = @'
{
  "version": 2,
  "plugins": {
    "alpha@mkt": [
      { "scope": "user", "installPath": "/u/alpha/1.0.0", "version": "1.0.0" },
      { "scope": "project", "installPath": "/p/alpha/0.9.0", "version": "0.9.0", "projectPath": "c:\\repo" }
    ],
    "beta@mkt": [
      { "scope": "user", "installPath": "/u/beta/2.0.0", "version": "2.0.0" }
    ],
    "gamma@mkt": [
      { "scope": "project", "installPath": "/p/gamma/1.0.0", "version": "1.0.0", "projectPath": "c:\\repo" }
    ]
  }
}
'@

# 1. dry-run reports and changes nothing
$reg = New-Registry $MIXED
$before = Get-Content -LiteralPath $reg -Raw
$out = Run @('-RegistryPath', $reg)
if ($out -match 'Project-scope records \(1\)') { Ok 'dry-run counts only the removable record' } else { Bad 'dry-run count' $out }
if ($out -match 'alpha@mkt') { Ok 'dry-run names the plugin' } else { Bad 'dry-run naming' $out }
if ((Get-Content -LiteralPath $reg -Raw) -eq $before) { Ok 'dry-run changed nothing' } else { Bad 'dry-run mutated the registry' '' }

# 2. gamma has ONLY a project record -> skipped, never uninstalled
if ($out -match 'SKIPPED' -and $out -match 'gamma@mkt') { Ok 'all-project plugin is skipped, not uninstalled' } else { Bad 'orphan guard' $out }

# 3. -Apply removes the project record, keeps the user one, keeps gamma
$out = Run @('-RegistryPath', $reg, '-Apply')
$d = Get-Content -LiteralPath $reg -Raw | ConvertFrom-Json
$alpha = @($d.plugins.'alpha@mkt')
if ($alpha.Count -eq 1 -and $alpha[0].scope -eq 'user') { Ok 'apply removed project record, kept user record' } else { Bad 'apply filtering' ($alpha | ConvertTo-Json -Depth 5) }
if (@($d.plugins.'beta@mkt').Count -eq 1) { Ok 'untouched plugin survives intact' } else { Bad 'beta damaged' '' }
if (@($d.plugins.'gamma@mkt').Count -eq 1) { Ok 'skipped all-project plugin still present' } else { Bad 'gamma uninstalled' '' }

# 4. THE PS 5.1 CORRUPTION GUARD: alpha now has ONE record and must still be a JSON LIST.
#    Unguarded, ConvertTo-Json writes "alpha@mkt": { .. } and the selector can no longer read it.
$rawAfter = Get-Content -LiteralPath $reg -Raw
if ($rawAfter -match '"alpha@mkt"\s*:\s*\[') { Ok 'single remaining record still serializes as a LIST (5.1 guard)' } else { Bad '5.1 array unrolling' $rawAfter }

# 5. backup was written
if (Get-ChildItem -LiteralPath (Split-Path $reg) -Filter '*.bak-converge-*') { Ok 'apply wrote a timestamped backup' } else { Bad 'no backup' '' }

# 6. idempotent: a second run reports clean and does not re-remove
$out = Run @('-RegistryPath', $reg, '-Apply')
if ($out -match "Nothing to converge") { Ok 'second run is idempotent' } else { Bad 'not idempotent' $out }

# 7. user-scope-only registry is a stated no-op
$reg2 = New-Registry '{ "version": 2, "plugins": { "solo@mkt": [ { "scope": "user", "version": "1.0.0" } ] } }'
$out = Run @('-RegistryPath', $reg2)
if ($out -match "Nothing to converge") { Ok 'clean machine reports clean' } else { Bad 'clean machine' $out }

# 8. missing / empty / unparsable are stated no-ops, never crashes
$out = Run @('-RegistryPath', (Join-Path $env:TEMP ('nope-' + [guid]::NewGuid().ToString('N') + '.json')))
if ($out -match 'No registry at that path') { Ok 'missing registry is a stated no-op' } else { Bad 'missing registry' $out }

$reg3 = New-Registry ''
$out = Run @('-RegistryPath', $reg3)
if ($out -match 'Registry is empty') { Ok 'empty registry is a stated no-op' } else { Bad 'empty registry' $out }

$reg4 = New-Registry '{ this is not json'
$before4 = Get-Content -LiteralPath $reg4 -Raw
$out = Run @('-RegistryPath', $reg4, '-Apply')
if ($out -match 'not valid JSON') { Ok 'unparsable registry is a stated no-op' } else { Bad 'unparsable registry' $out }
if ((Get-Content -LiteralPath $reg4 -Raw) -eq $before4) { Ok 'unparsable registry left untouched' } else { Bad 'unparsable mutated' '' }

# 9. a record carrying projectPath but no scope field is still caught (writer stamps one,
#    selector reads the other -- trusting only one leaves the other kind behind)
$reg5 = New-Registry '{ "version": 2, "plugins": { "delta@mkt": [ { "scope": "user", "version": "1.0" }, { "installPath": "/p", "version": "0.9", "projectPath": "c:\\repo" } ] } }'
$out = Run @('-RegistryPath', $reg5)
if ($out -match 'Project-scope records \(1\)') { Ok 'projectPath without scope is still detected' } else { Bad 'projectPath detection' $out }

# 10. CLAUDE_CONFIG_DIR is honoured when -RegistryPath is omitted. Without this the default
#     path is never exercised: every other test passes -RegistryPath and returns before that
#     branch is reached, so a relocated config could be reported clean while the real registry
#     kept its duplicates.
$cfg = Join-Path $env:TEMP ('cfg-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $cfg 'plugins') -Force | Out-Null
$regEnv = Join-Path $cfg 'plugins/installed_plugins.json'
Set-Content -LiteralPath $regEnv -Value $MIXED -Encoding UTF8
$prev = $env:CLAUDE_CONFIG_DIR
try {
    $env:CLAUDE_CONFIG_DIR = $cfg
    $out = Run @()
} finally { $env:CLAUDE_CONFIG_DIR = $prev }
if ($out -match [regex]::Escape($regEnv)) { Ok 'CLAUDE_CONFIG_DIR is used when -RegistryPath is omitted' } else { Bad 'CLAUDE_CONFIG_DIR ignored' $out }
if ($out -match 'Project-scope records \(1\)') { Ok 'and it actually reads that registry' } else { Bad 'env registry not read' $out }

Write-Host ''
Write-Host '=============================================='
Write-Host ("Converge tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host '=============================================='
if ($fail -gt 0) { exit 1 }
exit 0
