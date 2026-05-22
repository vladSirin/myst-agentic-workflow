# run-strict-mode-tests.ps1 -- block-unapproved-submit hook + enable-strict-mode tests
#
# Covers:
#   1. Hook ignores non-Bash tool calls.
#   2. Hook ignores Bash commands that aren't `p4 submit -c <N>`.
#   3. Hook BLOCKS p4 submit when marker is missing (exit 2, message to stderr).
#   4. Hook ALLOWS p4 submit when marker is present (exit 0).
#   5. Cleanup hook removes the marker after submit (paired PostToolUse).
#   6. enable-strict-mode.ps1 writes a valid settings.local.json.
#   7. enable-strict-mode.ps1 is idempotent (re-running adds nothing new).
#   8. enable-strict-mode.ps1 -Disable removes the hooks.
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0
function Ok($n)         { Write-Host ("[PASS] {0}" -f $n);          $script:pass++ }
function Bad($n, $why)  { Write-Host ("[FAIL] {0}: {1}" -f $n,$why); $script:fail++ }

function New-Fixture {
    $t = Join-Path $env:TEMP ('strict-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $t -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $t '.scratch') -Force | Out-Null
    return $t
}

function Invoke-Hook($scriptPath, $stdinJson, $projectDir) {
    $env:CLAUDE_PROJECT_DIR = $projectDir
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $stdinFile = New-TemporaryFile
        $outFile   = New-TemporaryFile
        $errFile   = New-TemporaryFile
        Set-Content -LiteralPath $stdinFile -Value $stdinJson -NoNewline
        # PowerShell doesn't support `<` stdin redirection; use cmd /c, with
        # stdout/stderr to separate files to avoid PowerShell wrapping native
        # stderr as error records.
        $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" < `"$stdinFile`" > `"$outFile`" 2> `"$errFile`""
        & cmd /c $cmd | Out-Null
        $code = $LASTEXITCODE
        $stdoutTxt = Get-Content -Raw -LiteralPath $outFile -ErrorAction SilentlyContinue
        if (-not $stdoutTxt) { $stdoutTxt = '' }
        $stderrTxt = Get-Content -Raw -LiteralPath $errFile -ErrorAction SilentlyContinue
        if (-not $stderrTxt) { $stderrTxt = '' }
        Remove-Item -LiteralPath $stdinFile, $outFile, $errFile -Force -ErrorAction SilentlyContinue
        return [pscustomobject]@{ Code = $code; Out = ($stdoutTxt + "`n" + $stderrTxt) }
    } finally {
        $ErrorActionPreference = $prev
        Remove-Item Env:\CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
    }
}

$blockHook = Join-Path $pkg 'templates\claude\.claude\scripts\hooks\block-unapproved-submit.ps1'
$cleanupHook = Join-Path $pkg 'templates\claude\.claude\scripts\hooks\cleanup-approved-cl.ps1'

# --- Test 1: non-Bash tool calls are ignored ---
$t = New-Fixture
$r = Invoke-Hook $blockHook '{"tool_name":"Read","tool_input":{"file_path":"foo.txt"}}' $t
if ($r.Code -eq 0) { Ok 'hook ignores non-Bash tool calls' }
else { Bad 'hook ignores non-Bash tool calls' "exit=$($r.Code) out=$($r.Out)" }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 2: Bash commands that aren't p4 submit are ignored ---
$t = New-Fixture
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"git status"}}' $t
if ($r.Code -eq 0) { Ok 'hook ignores non-submit Bash commands' }
else { Bad 'hook ignores non-submit Bash commands' "exit=$($r.Code) out=$($r.Out)" }

# --- Test 2b: p4 commands other than submit are ignored ---
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 opened"}}' $t
if ($r.Code -eq 0) { Ok 'hook ignores p4 opened' }
else { Bad 'hook ignores p4 opened' "exit=$($r.Code)" }

# --- Test 2c: p4 submit without -c (interactive) is ignored ---
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit"}}' $t
if ($r.Code -eq 0) { Ok 'hook ignores p4 submit (no -c)' }
else { Bad 'hook ignores p4 submit (no -c)' "exit=$($r.Code)" }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 3: p4 submit -c <N> is BLOCKED without marker ---
$t = New-Fixture
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit -c 1234"}}' $t
if ($r.Code -eq 2) { Ok 'hook BLOCKS p4 submit -c without marker (exit 2)' }
else { Bad 'hook BLOCKS p4 submit -c without marker' "exit=$($r.Code) out=$($r.Out)" }
if ($r.Out -match 'CL 1234') { Ok 'block message references the actual CL number' }
else { Bad 'block message includes CL number' "missing 'CL 1234' in: $($r.Out)" }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 4: p4 submit -c <N> ALLOWED when marker present ---
$t = New-Fixture
$marker = Join-Path $t '.scratch\.approved-cl-1234.marker'
New-Item -ItemType File -Path $marker -Force | Out-Null
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit -c 1234"}}' $t
if ($r.Code -eq 0) { Ok 'hook ALLOWS p4 submit -c when marker exists' }
else { Bad 'hook ALLOWS p4 submit -c when marker exists' "exit=$($r.Code) out=$($r.Out)" }

# --- Test 5: cleanup hook removes the marker after submit ---
$r = Invoke-Hook $cleanupHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit -c 1234"}}' $t
if ($r.Code -eq 0 -and -not (Test-Path -LiteralPath $marker)) {
    Ok 'cleanup hook removes the marker after submit'
} else {
    Bad 'cleanup hook removes the marker' "exit=$($r.Code); marker still present=$(Test-Path $marker)"
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 6: enable-strict-mode.ps1 writes valid settings.local.json ---
$t = New-Fixture
# Need the hook scripts in the consumer for enable-strict-mode to accept the run
$consumerHookDir = Join-Path $t '.claude\scripts\hooks'
New-Item -ItemType Directory -Path $consumerHookDir -Force | Out-Null
Copy-Item $blockHook $consumerHookDir
Copy-Item $cleanupHook $consumerHookDir

$enable = Join-Path $pkg 'enable-strict-mode.ps1'
$r = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $enable -TargetRoot $t -Yes 2>&1
$rcode = $LASTEXITCODE
if ($rcode -eq 0) { Ok 'enable-strict-mode.ps1 exits 0' }
else { Bad 'enable-strict-mode.ps1 exits 0' "exit=$rcode out=$($r | Out-String)" }

$settingsPath = Join-Path $t '.claude\settings.local.json'
if (Test-Path -LiteralPath $settingsPath) {
    $cfg = Get-Content -Raw $settingsPath | ConvertFrom-Json
    if ($cfg.hooks.PSObject.Properties.Match('PreToolUse').Count -gt 0) {
        Ok 'settings.local.json has PreToolUse block'
    } else {
        Bad 'settings.local.json has PreToolUse block' 'missing'
    }
} else {
    Bad 'settings.local.json written' 'file not present'
}

# --- Test 7: idempotency ---
$beforeSize = (Get-Item $settingsPath).Length
$r = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $enable -TargetRoot $t -Yes 2>&1
$afterSize = (Get-Item $settingsPath).Length
if ($beforeSize -eq $afterSize) {
    Ok 'enable-strict-mode.ps1 is idempotent (size unchanged on second run)'
} else {
    Bad 'enable-strict-mode.ps1 is idempotent' "size before=$beforeSize after=$afterSize"
}

# --- Test 8: -Disable removes the hooks ---
$r = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $enable -TargetRoot $t -Yes -Disable 2>&1
$rcode = $LASTEXITCODE
if ($rcode -eq 0) {
    $cfg = Get-Content -Raw $settingsPath | ConvertFrom-Json
    $hasHook = $false
    foreach ($evt in @('PreToolUse','PostToolUse')) {
        if ($cfg.hooks.PSObject.Properties.Match($evt).Count -gt 0) {
            foreach ($block in $cfg.hooks.$evt) {
                $cmds = @($block.hooks | ForEach-Object { $_.command })
                if (($cmds -join ' ') -match 'block-unapproved-submit|cleanup-approved-cl') {
                    $hasHook = $true
                }
            }
        }
    }
    if (-not $hasHook) { Ok 'enable-strict-mode.ps1 -Disable removes the hooks' }
    else { Bad 'enable-strict-mode.ps1 -Disable removes the hooks' 'hook entries still present' }
} else {
    Bad 'enable-strict-mode.ps1 -Disable exits 0' "exit=$rcode"
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# --- Test 9-15: powermode (count + time) ---
$enablePM  = Join-Path $pkg 'enable-powermode.ps1'
$disablePM = Join-Path $pkg 'disable-powermode.ps1'

# Test 9: enable-powermode writes a valid marker
$t = New-Fixture
$r = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $enablePM -TargetRoot $t -SubmitCount 3 -DurationMinutes 10 -Reason 'test' -Yes 2>&1
$rcode = $LASTEXITCODE
$markerPath = Join-Path $t '.scratch\.powermode.marker'
if ($rcode -eq 0 -and (Test-Path $markerPath)) {
    $pm = Get-Content -Raw $markerPath | ConvertFrom-Json
    if ($pm.submitsRemaining -eq 3 -and $pm.reason -eq 'test') {
        Ok 'enable-powermode writes valid marker (count=3, reason set)'
    } else {
        Bad 'enable-powermode marker contents' "got remaining=$($pm.submitsRemaining) reason=$($pm.reason)"
    }
} else {
    Bad 'enable-powermode exits 0 + writes marker' "exit=$rcode marker present=$(Test-Path $markerPath)"
}

# Test 10: powermode allows submit; decrements count
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit -c 555"}}' $t
if ($r.Code -eq 0) {
    $pm = Get-Content -Raw $markerPath | ConvertFrom-Json
    if ($pm.submitsRemaining -eq 2) {
        Ok 'powermode allows submit + decrements counter (3 -> 2)'
    } else {
        Bad 'powermode decrements counter' "expected 2 got $($pm.submitsRemaining)"
    }
} else {
    Bad 'powermode allows submit' "exit=$($r.Code) out=$($r.Out)"
}

# Test 11: powermode exhaustion deletes marker
$null = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit -c 556"}}' $t
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit -c 557"}}' $t
if ($r.Code -eq 0 -and -not (Test-Path $markerPath)) {
    Ok 'powermode exhaustion deletes marker after 3rd submit'
} else {
    Bad 'powermode exhaustion' "exit=$($r.Code) marker present=$(Test-Path $markerPath)"
}

# Test 12: after exhaustion, hook blocks again
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit -c 558"}}' $t
if ($r.Code -eq 2) { Ok 'hook blocks again after powermode exhaustion' }
else { Bad 'hook blocks again after exhaustion' "exit=$($r.Code)" }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# Test 13: expired powermode is ignored
$t = New-Fixture
$scratch = Join-Path $t '.scratch'
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
$pastIso = (Get-Date).ToUniversalTime().AddMinutes(-5).ToString("yyyy-MM-ddTHH:mm:ss") + 'Z'
$expiredPm = @{ enabled = $true; submitsRemaining = 10; expiresAt = $pastIso; reason = 'expired' } | ConvertTo-Json
Set-Content -LiteralPath (Join-Path $scratch '.powermode.marker') -Value $expiredPm -Encoding UTF8
$r = Invoke-Hook $blockHook '{"tool_name":"Bash","tool_input":{"command":"p4 submit -c 600"}}' $t
if ($r.Code -eq 2) {
    Ok 'expired powermode marker is ignored (hook blocks)'
} else {
    Bad 'expired powermode ignored' "exit=$($r.Code) (expected 2)"
}
if (-not (Test-Path (Join-Path $scratch '.powermode.marker'))) {
    Ok 'expired marker is cleaned up by hook'
} else {
    Bad 'expired marker cleaned up' 'still present'
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# Test 14: disable-powermode removes the marker
$t = New-Fixture
$null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $enablePM -TargetRoot $t -SubmitCount 5 -Yes 2>&1
$markerPath = Join-Path $t '.scratch\.powermode.marker'
if (Test-Path $markerPath) {
    $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $disablePM -TargetRoot $t -Yes 2>&1
    if (-not (Test-Path $markerPath)) {
        Ok 'disable-powermode removes the marker'
    } else {
        Bad 'disable-powermode removes the marker' 'marker still present'
    }
} else {
    Bad 'disable-powermode test setup' 'marker not created by enable-powermode'
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

# Test 15: status mode (no write) reports correctly
$t = New-Fixture
$null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $enablePM -TargetRoot $t -SubmitCount 7 -Reason 'status-test' -Yes 2>&1
$r = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $enablePM -TargetRoot $t -Status 2>&1
$out = $r | Out-String
if ($out -match 'ACTIVE' -and $out -match 'submitsRemaining\s*:\s*7' -and $out -match 'status-test') {
    Ok 'enable-powermode -Status reports active state'
} else {
    Bad 'enable-powermode -Status output' "missing expected fields: $out"
}
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Strict-mode tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
