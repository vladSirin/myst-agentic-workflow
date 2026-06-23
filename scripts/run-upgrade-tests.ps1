# run-upgrade-tests.ps1 -- tests for upgrade.ps1 (existing-consumer upgrade with customization preservation)
#
# Builds a synthetic "old" consumer (fresh install, then: customize one file, delete one skill
# to force an ADD, inject a retired skill into the manifest+disk), runs upgrade.ps1 -Apply, and
# asserts: customizations preserved, new/absent skills added, retired removed, preflight clean.
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0
function Ok($n)     { Write-Host ("[PASS] {0}" -f $n);         $script:pass++ }
function Bad($n,$w) { Write-Host ("[FAIL] {0}: {1}" -f $n,$w); $script:fail++ }
function GH($p) { $b=[IO.File]::ReadAllBytes($p); "sha256:"+[BitConverter]::ToString(([Security.Cryptography.SHA256]::Create()).ComputeHash($b)).Replace('-','').ToLower() }

$t = Join-Path $env:TEMP ('upgt-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $t -Force | Out-Null
try {
    # 1. Fresh install = a valid current consumer (filesystem, claude, core)
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\setup.ps1" -TargetRoot $t -ProjectName UpgTest -Tools claude -Overlays core -Yes *> (Join-Path $t 'setup.log')
    if ($LASTEXITCODE -ne 0) { Bad 'setup fixture' 'setup.ps1 failed'; Get-Content (Join-Path $t 'setup.log') -Tail 10 | Write-Host; throw 'fixture' }

    # 2. Simulate an OLD consumer:
    #  (a) PRESERVE: customize tdd/SKILL.md (on-disk now differs from manifest baseline)
    $tdd = "$t\.claude\skills\tdd\SKILL.md"
    Add-Content -LiteralPath $tdd -Value "`n<!-- my local customization -->"
    $tddCustom = GH $tdd
    #  (b) ADD: delete the teach skill from disk so upgrade re-adds it from the template
    Remove-Item -LiteralPath "$t\.claude\skills\teach" -Recurse -Force
    #  (c) REMOVE: inject a retired skill (on disk + manifest, unmodified) not in the current template
    New-Item -ItemType Directory -Path "$t\.claude\skills\zoom-out" -Force | Out-Null
    Set-Content -LiteralPath "$t\.claude\skills\zoom-out\SKILL.md" -Value 'retired skill body'
    $zoomHash = GH "$t\.claude\skills\zoom-out\SKILL.md"
    $mp = "$t\Docs\agents\scaffold-manifest.json"
    $mb = [IO.File]::ReadAllBytes($mp); if ($mb[0] -eq 0xEF) { $mb = $mb[3..($mb.Length-1)] }
    $man = [Text.Encoding]::UTF8.GetString($mb) | ConvertFrom-Json
    $entry = [pscustomobject]@{
        path='.claude/skills/zoom-out/SKILL.md'; tool='claude'; owner='package'; ownerOverlay='core'
        sourceTemplate=$null; sourceCommit='retired'; hashPolicy='sha256'; contentHash=$zoomHash
        mergeStrategy='copy'; localOnly=$false; writablePolicy='installer-owned'; baselineState='test'
        upstreamDerived=$false; upstreamLicense=$null; blockHashPolicy='not-applicable'
    }
    $man.files += $entry
    [IO.File]::WriteAllText($mp, ($man | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding($true)))

    # 3. Preview must not change anything
    $teachBeforePreview = Test-Path "$t\.claude\skills\teach\SKILL.md"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\upgrade.ps1" -TargetRoot $t *> (Join-Path $t 'preview.log')
    if ((-not (Test-Path "$t\.claude\skills\teach\SKILL.md")) -and (Test-Path "$t\.claude\skills\zoom-out\SKILL.md")) { Ok 'preview made no changes' } else { Bad 'preview' 'preview mutated the consumer' }

    # 4. Apply
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\upgrade.ps1" -TargetRoot $t -Apply -Yes *> (Join-Path $t 'apply.log')
    if ($LASTEXITCODE -eq 0) { Ok 'upgrade -Apply exit 0' } else { Bad 'apply exit' "exit $LASTEXITCODE"; Get-Content (Join-Path $t 'apply.log') -Tail 12 | Write-Host }

    # 5. Assertions
    if ((Test-Path $tdd) -and (GH $tdd) -eq $tddCustom) { Ok 'PRESERVE: customized tdd kept byte-for-byte' } else { Bad 'preserve' 'tdd customization was overwritten' }
    if (Test-Path "$t\.claude\skills\teach\SKILL.md") { Ok 'ADD: deleted skill (teach) re-added' } else { Bad 'add' 'teach not re-added' }
    if (-not (Test-Path "$t\.claude\skills\zoom-out")) { Ok 'REMOVE: retired skill (zoom-out) removed + dir pruned' } else { Bad 'remove' 'zoom-out still present' }

    # 6. Preflight clean
    $pf = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\scripts\run-skeleton-preflight.ps1" -TargetRoot $t 2>&1 | Out-String
    if ($pf -match '0 failed') { Ok 'preflight clean after upgrade (0 failed)' } else { Bad 'preflight' (($pf -split "`r?`n" | Where-Object {$_ -match 'FAIL'}) -join ' / ') }
}
finally { Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue }

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Upgrade tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
