# run-migrate-tests.ps1 -- tests for migrate-retired-skills.ps1 (upgrade helper)
#
# Verifies the retired-skill migration utility: dry-run detects + lists orphans without
# changing anything; -UsePerforce emits correct `p4 delete` commands; -Apply removes the
# orphans (filesystem) while leaving current skills intact; a clean target reports nothing.
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$helper = Join-Path $pkg 'scripts/migrate-retired-skills.ps1'
$pass = 0; $fail = 0
function Ok($n)     { Write-Host ("[PASS] {0}" -f $n);         $script:pass++ }
function Bad($n,$w) { Write-Host ("[FAIL] {0}: {1}" -f $n,$w); $script:fail++ }

function New-Consumer {
    $t = Join-Path $env:TEMP ('mig-' + [guid]::NewGuid().ToString('N'))
    foreach ($d in '.claude/skills','.claude/commands') { New-Item -ItemType Directory -Path (Join-Path $t $d) -Force | Out-Null }
    # current skill that must survive
    New-Item -ItemType Directory -Path (Join-Path $t '.claude/skills/diagnosing-bugs') -Force | Out-Null
    Set-Content (Join-Path $t '.claude/skills/diagnosing-bugs/SKILL.md') 'keep'
    # retired orphans
    foreach ($s in 'zoom-out','caveman','write-a-skill','diagnose') {
        New-Item -ItemType Directory -Path (Join-Path $t ".claude/skills/$s") -Force | Out-Null
        Set-Content (Join-Path $t ".claude/skills/$s/SKILL.md") "stale $s"
    }
    Set-Content (Join-Path $t '.claude/commands/caveman.md') 'stale cmd'
    return $t
}
function Run($targetArgs) {
    $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $helper @targetArgs 2>&1
    return ($o | Out-String)
}

# 1. dry-run lists the 5 orphans and changes nothing
$t = New-Consumer
$out = Run @('-TargetRoot', $t)
if ($out -match 'Retired items present \(5\)') { Ok 'dry-run lists 5 orphans' } else { Bad 'dry-run count' $out }
if ((Test-Path (Join-Path $t '.claude/skills/zoom-out')) -and (Test-Path (Join-Path $t '.claude/skills/diagnose'))) { Ok 'dry-run changed nothing' } else { Bad 'dry-run mutated' 'orphans missing after dry-run' }

# 2. -UsePerforce emits p4 delete commands (dir + file forms) and changes nothing
$out = Run @('-TargetRoot', $t, '-UsePerforce')
if (($out -match 'p4 delete -c <CL> .*skills/zoom-out/\.\.\.') -and ($out -match 'p4 delete -c <CL> .*commands/caveman\.md"')) { Ok 'perforce emits dir + file p4 commands' } else { Bad 'perforce emit' $out }
if (Test-Path (Join-Path $t '.claude/skills/zoom-out')) { Ok 'perforce mode changed nothing' } else { Bad 'perforce mutated' 'orphan removed in emit mode' }

# 3. -Apply removes orphans, keeps current skills
$out = Run @('-TargetRoot', $t, '-Apply')
$gone = -not (Test-Path (Join-Path $t '.claude/skills/zoom-out')) -and -not (Test-Path (Join-Path $t '.claude/skills/caveman')) -and -not (Test-Path (Join-Path $t '.claude/skills/write-a-skill')) -and -not (Test-Path (Join-Path $t '.claude/skills/diagnose')) -and -not (Test-Path (Join-Path $t '.claude/commands/caveman.md'))
if ($gone) { Ok 'apply removed all retired orphans' } else { Bad 'apply incomplete' 'an orphan survived' }
if (Test-Path (Join-Path $t '.claude/skills/diagnosing-bugs/SKILL.md')) { Ok 'apply kept current skill (diagnosing-bugs)' } else { Bad 'apply over-deleted' 'diagnosing-bugs removed' }

# 4. clean target reports nothing
$out = Run @('-TargetRoot', $t)
if ($out -match 'Nothing to migrate') { Ok 'clean target reports nothing' } else { Bad 'clean-state' $out }
Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Migrate-helper tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
