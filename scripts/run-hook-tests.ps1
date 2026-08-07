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
    'check-rules-alignment: NO baseline -> legacy hunk advisory, exit 1',
    'check-rules-alignment: sanctioned divergences DISAPPEARED -> loud, exit 1',
    'check-rules-alignment: hard-rules section GONE -> loud, exit 1',
    'check-rules-alignment: lockstep edit near a divergence stays quiet',
    'check-rules-alignment: --write-baseline refuses over a stale baseline',
    'check-rules-alignment: a bible FILE is gone -> loud, exit 1',
    'check-rules-alignment: signature-less baseline -> loud CORRUPT, exit 1'
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

    # 7e. THE INCIDENT CLASS THIS CHECK EXISTS FOR. Someone "makes the two files
    #     match" and every sanctioned per-tool qualifier vanishes from AGENTS.md --
    #     the silent-reversal shape. The sections are now identical, so the pre-4.31
    #     code returned "sections are identical", exit 0: its single most reassuring
    #     message, emitted at the exact moment Codex lost its rules. A baseline
    #     asserting N sanctioned divergences is positive evidence they should still
    #     be there, and it was sitting on disk unread.
    $cw7e = Join-Path $t 'align-collapse'; New-Item -ItemType Directory -Path $cw7e -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw7e 'CLAUDE.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw7e 'AGENTS.md'), $agentsRules, [Text.UTF8Encoding]::new($false))
    $null = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--write-baseline') -Cwd $cw7e
    # AGENTS.md is overwritten from CLAUDE.md: the divergence is gone, not resolved.
    [IO.File]::WriteAllText((Join-Path $cw7e 'AGENTS.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -Cwd $cw7e
    if ($r.Code -eq 1 -and $r.Out -match 'DISAPPEARED') {
        Ok $cases[11]
    } else { Bad $cases[11] "code=$($r.Code) out=$($r.Out)" }

    # 7f. Same blind spot, second door: the '## Hard rules' heading is renamed or the
    #     section deleted from AGENTS.md. Extraction returns empty and the pre-4.31
    #     code said "nothing to check", exit 0 -- while a baseline recorded that there
    #     WAS something to check. (The old message also claimed "in both files" when
    #     it fires if EITHER is empty.)
    $cw7f = Join-Path $t 'align-gone'; New-Item -ItemType Directory -Path $cw7f -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw7f 'CLAUDE.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw7f 'AGENTS.md'), $agentsRules, [Text.UTF8Encoding]::new($false))
    $null = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--write-baseline') -Cwd $cw7f
    [IO.File]::WriteAllText((Join-Path $cw7f 'AGENTS.md'), "# Agents`n`n## House rules`n`n1. Never touch the vendor tree.`n`n## Deeper docs`n", [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -Cwd $cw7f
    if ($r.Code -eq 1 -and $r.Out -match 'DISAPPEARED|GONE|no longer') {
        Ok $cases[12]
    } else { Bad $cases[12] "code=$($r.Code) out=$($r.Out)" }

    # 7g. The property the header CLAIMS: an edit that leaves the divergence SET alone
    #     must not re-flag. With 3 lines of diff context in the signature this was
    #     false -- an identical, lockstep reword within 3 lines of a divergence fired
    #     the alarm even though nothing diverged differently. Measured on the real
    #     bibles before the fix: 14 of 31 signature lines were context, so ~39% of the
    #     section was false-alarm surface. False alarms are how --write-baseline
    #     becomes muscle memory, which is how the whole mechanism dies.
    $cw7g = Join-Path $t 'align-lockstep'; New-Item -ItemType Directory -Path $cw7g -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw7g 'CLAUDE.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw7g 'AGENTS.md'), $agentsRules, [Text.UTF8Encoding]::new($false))
    $null = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--write-baseline') -Cwd $cw7g
    # Rule 1 is adjacent to the rule-2 divergence. Edit it IDENTICALLY in both files:
    # the divergence set is provably unchanged, so this must stay quiet.
    foreach ($f in @('CLAUDE.md','AGENTS.md')) {
        $p = Join-Path $cw7g $f
        $txt = [IO.File]::ReadAllText($p).Replace('1. Never touch the vendor tree.', '1. Never touch the vendored engine tree.')
        [IO.File]::WriteAllText($p, $txt, [Text.UTF8Encoding]::new($false))
    }
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--advisory') -Cwd $cw7g
    if ($r.Code -eq 0 -and $r.Out -match 'unchanged') {
        Ok $cases[13]
    } else { Bad $cases[13] "code=$($r.Code) out=$($r.Out)" }

    # 7h. --write-baseline must not leave a STALE baseline in place when the sections
    #     have collapsed to identical. The old code printed "nothing to record" and
    #     returned 0, leaving the previous signature on disk -- so the 7e state
    #     persisted silently even after someone tried to re-record.
    $cw7h = Join-Path $t 'align-staleWrite'; New-Item -ItemType Directory -Path $cw7h -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw7h 'CLAUDE.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw7h 'AGENTS.md'), $agentsRules, [Text.UTF8Encoding]::new($false))
    $null = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--write-baseline') -Cwd $cw7h
    [IO.File]::WriteAllText((Join-Path $cw7h 'AGENTS.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--write-baseline') -Cwd $cw7h
    if ($r.Code -ne 0 -and $r.Out -match 'DISAPPEARED|refus') {
        Ok $cases[14]
    } else { Bad $cases[14] "code=$($r.Code) out=$($r.Out)" }

    # 7i. The THIRD door into the same incident class, and the widest: the bible FILE
    #     is gone, not just its section. 4.31.0 hoisted the baseline read above the
    #     two "nothing to compare" branches but left the file-existence loop above
    #     THAT, so a deleted AGENTS.md still exited 0 with "nothing to check" while a
    #     baseline sat on disk recording that Codex had rules. With the section merely
    #     collapsed Codex still reads Claude's rules; with the file deleted it reads
    #     nothing at all.
    #
    #     The legitimate silence this branch exists for -- a project that never set
    #     Codex up -- is exactly the case with NO baseline, so the baseline is what
    #     tells the two apart.
    $cw7i = Join-Path $t 'align-nofile'; New-Item -ItemType Directory -Path $cw7i -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw7i 'CLAUDE.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw7i 'AGENTS.md'), $agentsRules, [Text.UTF8Encoding]::new($false))
    $null = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -HookArgs @('--write-baseline') -Cwd $cw7i
    Remove-Item -LiteralPath (Join-Path $cw7i 'AGENTS.md') -Force
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -Cwd $cw7i
    if ($r.Code -eq 1 -and $r.Out -match 'DISAPPEARED') {
        Ok $cases[15]
    } else { Bad $cases[15] "code=$($r.Code) out=$($r.Out)" }

    # 7j. A baseline that EXISTS but carries no signature -- emptied, truncated, or
    #     left as comments by a three-way merge of a unified diff -- silently reverted
    #     to no-baseline mode, because "" is indistinguishable from "never recorded".
    #     Combined with a collapse that put the incident-class silence straight back:
    #     "hard-rules sections are identical", exit 0. Absence and corruption are
    #     different states and must not share a code path.
    $cw7j = Join-Path $t 'align-corrupt'; New-Item -ItemType Directory -Path $cw7j -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw7j 'CLAUDE.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $cw7j 'AGENTS.md'), $claudeRules, [Text.UTF8Encoding]::new($false))
    New-Item -ItemType Directory -Path (Join-Path $cw7j '.claude') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $cw7j '.claude\rules-alignment.baseline'), "# only a header survived the merge`n#`n", [Text.UTF8Encoding]::new($false))
    $r = Invoke-Hook -Script (Join-Path $hookDir 'check-rules-alignment.sh') -Cwd $cw7j
    if ($r.Code -eq 1 -and $r.Out -match 'CORRUPT') {
        Ok $cases[16]
    } else { Bad $cases[16] "code=$($r.Code) out=$($r.Out)" }
}
finally { Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue }

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Hook tests: {0} passed, {1} failed, {2} skipped" -f $pass, $fail, $skip)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
