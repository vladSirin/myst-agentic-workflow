# run-wrapper-tests.ps1 -- top-level update.ps1 + promote.ps1 round-trip tests
#
# Verifies the one-command update + promote orchestrators wrap the underlying
# scripts correctly: derive tools/overlays/VC from the consumer manifest,
# auto-infer classification on promote, exit correctly on no-op and on
# successful write.
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0
function Ok($n)      { Write-Host ("[PASS] {0}" -f $n);          $script:pass++ }
function Bad($n,$w)  { Write-Host ("[FAIL] {0}: {1}" -f $n,$w);  $script:fail++ }

function New-TempTarget {
    $t = Join-Path $env:TEMP ('wrap-' + [guid]::NewGuid().ToString('N'))
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
function Restore-PackageFile($rel) {
    Push-Location $pkg
    & git checkout -- $rel 2>&1 | Out-Null
    Pop-Location
}

# --- Test 1: update.ps1 -NoPull -Yes against fresh install (no-op) ---
$t = New-TempTarget
$null = Invoke-PS (Join-Path $pkg 'setup.ps1') @('-TargetRoot',$t,'-ProjectName','U1','-Yes')
$r = Invoke-PS (Join-Path $pkg 'update.ps1') @('-TargetRoot',$t,'-NoPull','-Yes')
if ($r.Code -eq 0) { Ok 'update.ps1 -NoPull -Yes exit 0 (no-op against fresh install)' }
else { Bad 'update.ps1 -NoPull -Yes no-op' "exit=$($r.Code)`n$($r.Out)" }
if ($r.Out -match 'Update complete') { Ok 'update.ps1 reports completion' }
else { Bad 'update.ps1 reports completion' 'banner missing' }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 2: update.ps1 derives Tools / Overlays from manifest ---
$t = New-TempTarget
$null = Invoke-PS (Join-Path $pkg 'setup.ps1') @('-TargetRoot',$t,'-ProjectName','U2','-Yes')
$r = Invoke-PS (Join-Path $pkg 'update.ps1') @('-TargetRoot',$t,'-NoPull','-Yes')
if ($r.Out -match 'Tools\s*:\s*claude|claude.*codex|codex.*opencode') { Ok 'update.ps1 derives Tools from manifest' }
else { Bad 'update.ps1 derives Tools' 'Tools line not found' }
if ($r.Out -match 'Overlays\s*:\s*core') { Ok 'update.ps1 derives Overlays from manifest' }
else { Bad 'update.ps1 derives Overlays' 'Overlays line not found' }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 3: promote.ps1 infers classification from manifest ---
$t = New-TempTarget
$null = Invoke-PS (Join-Path $pkg 'setup.ps1') @('-TargetRoot',$t,'-ProjectName','P1','-Yes')

# Mark a tracked file as locally modified
$localFile = Join-Path $t '.claude\skills\diagnosing-bugs\SKILL.md'
Add-Content -Path $localFile -Value "`n# Test marker $(Get-Date -Format 'HHmmss')"

$r = Invoke-PS (Join-Path $pkg 'promote.ps1') @(
    '-TargetRoot', $t, '-Paths', '.claude/skills/diagnosing-bugs/SKILL.md', '-Yes'
)
if ($r.Code -eq 0) { Ok 'promote.ps1 -Yes exit 0' }
else { Bad 'promote.ps1 -Yes exit 0' "exit=$($r.Code)`n$($r.Out)" }
if ($r.Out -match 'reusable-core\s+\(inferred\)') { Ok 'promote.ps1 inferred classification' }
else { Bad 'promote.ps1 inferred classification' 'inference marker not present' }

# Verify package file got the change
$pkgFile = Join-Path $pkg 'templates\claude\.claude\skills\diagnosing-bugs\SKILL.md'
if (Select-String -Path $pkgFile -Pattern 'Test marker' -Quiet) { Ok 'promote.ps1 wrote change to package tree' }
else { Bad 'promote.ps1 wrote change' 'package file does not show marker' }

# Cleanup: restore the package file
Restore-PackageFile 'templates/claude/.claude/skills/diagnosing-bugs/SKILL.md'
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 4: promote.ps1 errors clearly when classification cannot be inferred ---
$t = New-TempTarget
$null = Invoke-PS (Join-Path $pkg 'setup.ps1') @('-TargetRoot',$t,'-ProjectName','P2','-Yes')
# Make a brand-new file not in manifest
$newFile = Join-Path $t 'NewArbitraryFile.md'
Set-Content -Path $newFile -Value "# new file not in manifest" -Encoding UTF8

$r = Invoke-PS (Join-Path $pkg 'promote.ps1') @('-TargetRoot',$t,'-Paths','NewArbitraryFile.md','-Yes')
if ($r.Code -eq 2 -and $r.Out -match 'Cannot infer classification') {
    Ok 'promote.ps1 errors when path not in manifest'
} else {
    Bad 'promote.ps1 errors when path not in manifest' "exit=$($r.Code)"
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 5: promote.ps1 accepts explicit -Classification ---
$t = New-TempTarget
$null = Invoke-PS (Join-Path $pkg 'setup.ps1') @('-TargetRoot',$t,'-ProjectName','P3','-Yes')
# Same scenario as test 4, but provide explicit classification
$newFile = Join-Path $t 'NewArbitraryFile.md'
Set-Content -Path $newFile -Value "# new file not in manifest" -Encoding UTF8

$r = Invoke-PS (Join-Path $pkg 'promote.ps1') @(
    '-TargetRoot', $t, '-Paths', 'NewArbitraryFile.md',
    '-Classification', 'reject-local', '-Yes'
)
# We expect promote-from-project to handle 'reject-local' (a known classification).
# It may exit 0 or non-zero depending on its semantics for reject-local; the key
# thing is the wrapper didn't bail at the inference step.
if ($r.Out -match 'explicit\)') { Ok 'promote.ps1 accepts explicit -Classification' }
else { Bad 'promote.ps1 accepts explicit -Classification' "(explicit) marker not found in output" }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Summary ---
Write-Host ""
Write-Host "=============================================================="
Write-Host ("Wrapper (update.ps1 + promote.ps1) tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
