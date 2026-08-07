# run-hook-tests.ps1 -- branch tests for the PACKAGE-shipped bash hook scripts
# (plugins/myst-dev-kit/scripts/*.sh), run via Git Bash.
#
# PACKAGE .sh ONLY, on purpose: the project-owned hook scripts a Myst consumer
# also carries (check-script-standard.sh, submit-audit-warn.sh, ...) live in
# that project's Perforce depot, which a GitHub runner cannot see -- a package
# suite claiming to cover them would be green-with-skips forever. Their test
# matrices ship consumer-side (.claude/scripts/test-hooks.sh) instead.
#
# Every case pins its EXPECTED exit code WITH its fixture present. The one
# missing-fixture branch (check-uproject-assoc with no .uproject) is pinned as
# an explicit NEGATIVE case (exit 2) so it can never masquerade as a pass.
#
# Requires bash on PATH (Git Bash on Windows). If bash is absent this suite
# prints a LOUD SKIP per case and exits 0; the '  SKIP  ' lines surface in the
# CI job summary (tests.yml counts '^\s*SKIP\s' matches and flags the suite).
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$hookDir = Join-Path $pkg 'plugins\myst-dev-kit\scripts'
$pass = 0; $fail = 0; $skip = 0
function Ok($n)     { Write-Host ("[PASS] {0}" -f $n);         $script:pass++ }
function Bad($n,$w) { Write-Host ("[FAIL] {0}: {1}" -f $n,$w); $script:fail++ }
function Skp($n,$w) { Write-Host ("  SKIP  {0}  ({1})" -f $n,$w); $script:skip++ }

$cases = @(
    'doc-audit raw package copy: loud UNRENDERED error + exit 0',
    'doc-audit rendered: violation table + exit 0',
    'check-rule-parity --advisory (matching stems): exit 0',
    'check-rules-alignment --advisory (no-op): exit 0',
    'check-uproject-assoc: allowed association -> exit 0',
    'check-uproject-assoc: NO .uproject -> exit 2 (negative pin)',
    'submit-audit-bridge: CLAUDECODE=1 -> traced no-op, exit 0',
    'check-rules-alignment: baseline recorded -> quiet OK, exit 0',
    'check-rules-alignment: divergence set changed -> loud, exit 1',
    'check-rules-alignment: changed + --advisory -> loud, exit 0',
    'check-rules-alignment: NO baseline -> legacy hunk advisory, exit 1'
)

# Resolve bash: PATH first, then Git-for-Windows' bin/ next to git.exe, then the
# default install location. Skipping while Git Bash is actually installed would
# be a silent-skip of exactly the kind this suite exists to prevent.
$bashExe = $null
$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCmd) { $bashExe = $bashCmd.Source }
if (-not $bashExe) {
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $cand = Join-Path (Split-Path -Parent (Split-Path -Parent $gitCmd.Source)) 'bin\bash.exe'
        if (Test-Path -LiteralPath $cand) { $bashExe = $cand }
    }
}
if (-not $bashExe) {
    $cand = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
    if (Test-Path -LiteralPath $cand) { $bashExe = $cand }
}
if (-not $bashExe) {
    Write-Host ''
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    Write-Host '!! bash not on PATH -- the hook suite verified NOTHING.     !!'
    Write-Host '!! Install Git Bash to run the package hook-script tests.   !!'
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    foreach ($c in $cases) { Skp $c 'bash absent' }
    Write-Host ''
    Write-Host '=============================================================='
    Write-Host ("Hook tests: 0 passed, 0 failed, {0} SKIPPED (bash absent)" -f $skip)
    Write-Host '=============================================================='
    exit 0
}

# Run a bash script with an optional working dir and env vars; capture merged
# output + exit code. EAP is scoped to Continue around the native call so a
# stderr write from the hook is data, not a terminating error (PS 5.1 trap).
function Invoke-Hook {
    param(
        [Parameter(Mandatory)][string] $Script,
        [string[]] $HookArgs = @(),
        [string] $Cwd = $null,
        [hashtable] $EnvVars = @{}
    )
    $saved = @{}
    foreach ($k in $EnvVars.Keys) {
        $saved[$k] = [Environment]::GetEnvironmentVariable($k)
        [Environment]::SetEnvironmentVariable($k, $EnvVars[$k])
    }
    if ($Cwd) { Push-Location $Cwd }
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $out = & $script:bashExe ($Script -replace '\\','/') @HookArgs 2>&1 | Out-String
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out }
    } finally {
        $ErrorActionPreference = $prevEap
        if ($Cwd) { Pop-Location }
        foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
    }
}

$t = Join-Path $env:TEMP ('hookt-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $t -Force | Out-Null
try {
    # 1. doc-audit.sh RAW from the package: its docs-root token is unrendered, so
    #    the loud broken-install ERROR branch must fire -- and the advisory
    #    always-exit-0 contract must hold. Run from an empty cwd so the optional
    #    .claude/scripts parity sub-checks are absent no-ops.
    $cw1 = Join-Path $t 'raw'; New-Item -ItemType Directory -Path $cw1 -Force | Out-Null
    $r = Invoke-Hook -Script (Join-Path $hookDir 'doc-audit.sh') -Cwd $cw1
    if ($r.Code -eq 0 -and $r.Out -match 'UNRENDERED' -and $r.Out -notmatch 'all clean') {
        Ok $cases[0]
    } else { Bad $cases[0] "code=$($r.Code) out=$($r.Out)" }

    # 2. doc-audit.sh with the token substituted (the install-render equivalent of
    #    sed) to a fixture docs dir: one clean file + one Banned_Suffix _Updated.md.
    #    Expect exit 0, the violation table naming the banned suffix, and NO
    #    'all clean'.
    $cw2 = Join-Path $t 'rendered'; New-Item -ItemType Directory -Path (Join-Path $cw2 'docs') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw2 'docs\design_good.md'), "# Good`n**Status**: COMPLETE`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw2 'docs\design_stuff_Updated.md'), "# Banned suffix fixture`n**Status**: COMPLETE`n", [Text.UTF8Encoding]::new($false))
    $rendered = [IO.File]::ReadAllText((Join-Path $hookDir 'doc-audit.sh')).Replace('{{game_docs_root}}', 'docs').Replace("`r`n", "`n")
    $renderedPath = Join-Path $cw2 'doc-audit-rendered.sh'
    [IO.File]::WriteAllText($renderedPath, $rendered, [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script $renderedPath -Cwd $cw2
    if ($r.Code -eq 0 -and $r.Out -match 'design_stuff_Updated\.md' -and $r.Out -match "_Updated" -and $r.Out -match '\| File \| Issue \|' -and $r.Out -notmatch 'all clean') {
        Ok $cases[1]
    } else { Bad $cases[1] "code=$($r.Code) out=$($r.Out)" }

    # 3. check-rule-parity.sh --advisory with a rules dir + AGENTS.md whose stems
    #    match: parity holds, exit 0.
    $cw3 = Join-Path $t 'parity'; New-Item -ItemType Directory -Path (Join-Path $cw3 '.claude\rules') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw3 '.claude\rules\TestRule.md'), "# Test rule (always-on: no paths frontmatter)`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw3 'AGENTS.md'), "# Agents`nSee .claude/rules/TestRule.md for the always-on rule.`n", [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rule-parity.sh') -HookArgs @('--advisory') -Cwd $cw3
    if ($r.Code -eq 0 -and $r.Out -match 'counterpart') {
        Ok $cases[2]
    } else { Bad $cases[2] "code=$($r.Code) out=$($r.Out)" }

    # 4. check-rules-alignment.sh --advisory no-op: both files exist, neither has
    #    a '## Hard rules' section -> clean nothing-to-check, exit 0.
    $cw4 = Join-Path $t 'align'; New-Item -ItemType Directory -Path $cw4 -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw4 'CLAUDE.md'), "# Bible`nNo hard-rules section here.`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw4 'AGENTS.md'), "# Agents`nNo hard-rules section here either.`n", [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--advisory') -Cwd $cw4
    if ($r.Code -eq 0 -and $r.Out -match 'nothing to check') {
        Ok $cases[3]
    } else { Bad $cases[3] "code=$($r.Code) out=$($r.Out)" }

    # 5a. check-uproject-assoc.sh with a fixture .uproject carrying the ALLOWED
    #     association (empty string) -> exit 0.
    $cw5 = Join-Path $t 'uproj'; New-Item -ItemType Directory -Path $cw5 -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw5 'Game.uproject'), "{`n  `"FileVersion`": 3,`n  `"EngineAssociation`": `"`"`n}`n", [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-uproject-assoc.sh') -Cwd $cw5
    if ($r.Code -eq 0 -and $r.Out -match 'OK - EngineAssociation is empty') {
        Ok $cases[4]
    } else { Bad $cases[4] "code=$($r.Code) out=$($r.Out)" }

    # 5b. NEGATIVE pin: with NO .uproject the script must exit 2 (its documented
    #     missing-fixture branch). Without this pin, a fixture that silently
    #     failed to land would let case 5a's branch go unexercised forever.
    $cw5b = Join-Path $t 'uproj-none'; New-Item -ItemType Directory -Path $cw5b -Force | Out-Null
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-uproject-assoc.sh') -Cwd $cw5b
    if ($r.Code -eq 2 -and $r.Out -match 'no \.uproject found') {
        Ok $cases[5]
    } else { Bad $cases[5] "code=$($r.Code) out=$($r.Out)" }

    # 6. submit-audit-bridge.sh under CLAUDECODE=1: must no-op with exit 0, and
    #    with MYST_AUDIT_DEBUG=1 it must SAY so (the bridge announces every exit
    #    path -- total silence would be indistinguishable from never running).
    $cw6 = Join-Path $t 'bridge'; New-Item -ItemType Directory -Path $cw6 -Force | Out-Null
    $r = Invoke-Hook -Script (Join-Path $hookDir 'submit-audit-bridge.sh') -Cwd $cw6 -EnvVars @{ CLAUDECODE = '1'; MYST_AUDIT_DEBUG = '1' }
    if ($r.Code -eq 0 -and $r.Out -match 'no-op') {
        Ok $cases[6]
    } else { Bad $cases[6] "code=$($r.Code) out=$($r.Out)" }

    # 7. check-rules-alignment.sh BASELINE MODE (v4.29.0).
    #    Fixture: two bibles whose hard-rules sections differ ONLY by a deliberate
    #    per-tool qualifier -- the permanent, correct state of any project that
    #    supports both harnesses. Before baseline mode the check reported that
    #    difference at every SessionStart forever, asking for a confirmation no
    #    consumer could record.
    $cw7 = Join-Path $t 'align-base'; New-Item -ItemType Directory -Path $cw7 -Force | Out-Null
    $claudeRules = "# Bible`n`n## Hard rules`n`n1. Never touch the vendor tree.`n2. Agent writes are hook-blocked at write time.`n3. Start every task in a new named CL.`n`n## Deeper docs`n"
    $agentsRules = "# Agents`n`n## Hard rules`n`n1. Never touch the vendor tree.`n2. Agent writes are hook-blocked at write time for Claude only.`n3. Start every task in a new named CL.`n`n## Deeper docs`n"
    [IO.File]::WriteAllText((Join-Path $cw7 'CLAUDE.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw7 'AGENTS.md'), $agentsRules, [Text.UTF8Encoding]::new($false))

    # 7a. Record the sanctioned set, then re-run: QUIET, exit 0, no 'Confirm each' nag.
    $w = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--write-baseline') -Cwd $cw7
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--advisory') -Cwd $cw7
    if ($w.Code -eq 0 -and (Test-Path -LiteralPath (Join-Path $cw7 '.claude\rules-alignment.baseline')) -and
        $r.Code -eq 0 -and $r.Out -match 'unchanged' -and $r.Out -notmatch 'Confirm each') {
        Ok $cases[7]
    } else { Bad $cases[7] "write=$($w.Code) check=$($r.Code) out=$($r.Out)" }

    # 7b. THE CASE THAT MATTERS: real drift still fires. Add a SECOND divergence the
    #     baseline never recorded -> loud, exit 1. A baseline that silenced genuine
    #     drift would be worse than the noise it replaced.
    $agentsDrift = $agentsRules -replace '3\. Start every task in a new named CL\.', '3. Start every task in a new named CL; under Codex use the supplement.'
    [IO.File]::WriteAllText((Join-Path $cw7 'AGENTS.md'), $agentsDrift, [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -Cwd $cw7
    if ($r.Code -eq 1 -and $r.Out -match 'changed since') {
        Ok $cases[8]
    } else { Bad $cases[8] "code=$($r.Code) out=$($r.Out)" }

    # 7c. Same stale state under --advisory: still loud, but exit 0. The SessionStart
    #     contract (never fail a session start) outranks the finding.
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--advisory') -Cwd $cw7
    if ($r.Code -eq 0 -and $r.Out -match 'changed since') {
        Ok $cases[9]
    } else { Bad $cases[9] "code=$($r.Code) out=$($r.Out)" }

    # 7d. BACKWARD-COMPAT pin: a consumer that never records a baseline keeps the
    #     pre-4.29.0 behaviour verbatim -- hunk count, 'Confirm each' guidance,
    #     exit 1. Baseline mode is opt-in by the file's presence and nothing else.
    $cw7d = Join-Path $t 'align-nobase'; New-Item -ItemType Directory -Path $cw7d -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw7d 'CLAUDE.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw7d 'AGENTS.md'), $agentsRules, [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -Cwd $cw7d
    if ($r.Code -eq 1 -and $r.Out -match 'hunk\(s\)' -and $r.Out -match 'Confirm each') {
        Ok $cases[10]
    } else { Bad $cases[10] "code=$($r.Code) out=$($r.Out)" }
}
finally { Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue }

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Hook tests: {0} passed, {1} failed, {2} skipped" -f $pass, $fail, $skip)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
