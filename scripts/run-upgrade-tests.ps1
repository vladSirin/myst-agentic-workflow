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
    #  (a) PRESERVE: customize a core-bootstrap doc (on-disk now differs from manifest baseline)
    $tdd = "$t\Docs\agents\issue-tracker.md"
    Add-Content -LiteralPath $tdd -Value "`n<!-- my local customization -->"
    $tddCustom = GH $tdd
    #  (b) ADD: delete a core doc from disk so upgrade re-adds it from the template
    Remove-Item -LiteralPath "$t\Docs\agents\triage-labels.md" -Force
    #  (c) REMOVE: inject a retired skill (on disk + manifest, unmodified) not in the current template
    New-Item -ItemType Directory -Path "$t\.claude\skills\zoom-out" -Force | Out-Null
    Set-Content -LiteralPath "$t\.claude\skills\zoom-out\SKILL.md" -Value 'retired skill body'
    $zoomHash = GH "$t\.claude\skills\zoom-out\SKILL.md"
    #  (d) PRESERVE-BY-OWNERSHIP: a file the consumer marked human-owned whose on-disk
    #      content MATCHES its recorded baseline. The hash guard cannot fire here -- the
    #      baseline was taken from the already-forked bytes, which is what happens when a
    #      file is customized before bootstrap, or any time install.ps1 re-baselines.
    #      Only the installed manifest's ownership says "don't touch this". The package
    #      template claims this path as installer-owned/copy, so without that carry-forward
    #      the regenerated manifest silently overrules the consumer and the content is lost.
    $ownDoc = "$t\Docs\agents\domain.md"
    Set-Content -LiteralPath $ownDoc -Value "team-specific domain model - do not clobber" -NoNewline
    $ownHash = GH $ownDoc

    $mp = "$t\Docs\agents\scaffold-manifest.json"
    $mb = [IO.File]::ReadAllBytes($mp); if ($mb[0] -eq 0xEF) { $mb = $mb[3..($mb.Length-1)] }
    $man = [Text.Encoding]::UTF8.GetString($mb) | ConvertFrom-Json
    foreach ($fe in $man.files) {
        if ($fe.path -eq 'Docs/agents/domain.md') {
            $fe.contentHash    = $ownHash          # baseline == disk: hash guard is blind
            $fe.writablePolicy = 'human-owned'     # the consumer's decision
            $fe.mergeStrategy  = 'manual-only'
        }
    }
    $entry = [pscustomobject]@{
        path='.claude/skills/zoom-out/SKILL.md'; tool='claude'; owner='package'; ownerOverlay='core'
        sourceTemplate=$null; sourceCommit='retired'; hashPolicy='sha256'; contentHash=$zoomHash
        mergeStrategy='copy'; localOnly=$false; writablePolicy='installer-owned'; baselineState='test'
        upstreamDerived=$false; upstreamLicense=$null; blockHashPolicy='not-applicable'
    }
    $man.files += $entry
    [IO.File]::WriteAllText($mp, ($man | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding($true)))

    # 3. Preview must not change anything
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\upgrade.ps1" -TargetRoot $t *> (Join-Path $t 'preview.log')
    if ((-not (Test-Path "$t\Docs\agents\triage-labels.md")) -and (Test-Path "$t\.claude\skills\zoom-out\SKILL.md")) { Ok 'preview made no changes' } else { Bad 'preview' 'preview mutated the consumer' }

    # 4. Apply
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\upgrade.ps1" -TargetRoot $t -Apply -Yes *> (Join-Path $t 'apply.log')
    if ($LASTEXITCODE -eq 0) { Ok 'upgrade -Apply exit 0' } else { Bad 'apply exit' "exit $LASTEXITCODE"; Get-Content (Join-Path $t 'apply.log') -Tail 12 | Write-Host }

    # 5. Assertions
    if ((Test-Path $tdd) -and (GH $tdd) -eq $tddCustom) { Ok 'PRESERVE: customized issue-tracker kept byte-for-byte' } else { Bad 'preserve' 'issue-tracker customization was overwritten' }
    if ((Test-Path $ownDoc) -and (GH $ownDoc) -eq $ownHash) {
        Ok 'PRESERVE: human-owned file with baseline == disk survives (template ownership must not overrule the consumer)'
    } else {
        Bad 'preserve-by-ownership' 'a file marked human-owned in the installed manifest was overwritten from the template'
    }
    if (Test-Path "$t\Docs\agents\triage-labels.md") { Ok 'ADD: deleted core doc (triage-labels) re-added' } else { Bad 'add' 'triage-labels not re-added' }
    if (-not (Test-Path "$t\.claude\skills\zoom-out")) { Ok 'REMOVE: retired skill (zoom-out) removed + dir pruned - the CL 3.6 detrack path' } else { Bad 'remove' 'zoom-out still present' }

    # 6. Preflight clean
    $pf = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\scripts\run-skeleton-preflight.ps1" -TargetRoot $t 2>&1 | Out-String
    if ($pf -match '0 failed') { Ok 'preflight clean after upgrade (0 failed)' } else { Bad 'preflight' (($pf -split "`r?`n" | Where-Object {$_ -match 'FAIL'}) -join ' / ') }
}
finally { Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue }

# --- ADOPT-path cases (Perforce reconcile) -----------------------------------
# Pins two behaviors of upgrade.ps1's ADOPT scan:
#   (a) an entry already present in the INSTALLED manifest as owner=project is
#       kept VERBATIM through the reconcile -- custom fields (notes),
#       baselineState and sourceCommit survive; only contentHash/depotRevision
#       are recomputed;
#   (b) a pending-add (fstat record with an EMPTY headRev field) adopts with
#       depotRevision null -- NOT 0 (the unguarded [int]'' coercion).
# Uses the fake-p4 shim (scripts/fake-p4.ps1: FAKE_P4_WHERE_FILE +
# FAKE_P4_FSTAT_RECORDS) so no live depot is involved. The package side is a
# COPY whose install.ps1 is a stub: the unit under test is the reconcile and
# the manifest write, which upgrade.ps1 completes BEFORE the install phase;
# install behavior has its own suites.
$t2       = Join-Path $env:TEMP ('upgt-adopt-' + [guid]::NewGuid().ToString('N'))
$fpkgRoot = Join-Path $t2 'pkg'
$cons     = Join-Path $t2 'consumer'
$shim2    = Join-Path $t2 'p4shim'
$origPath2 = $env:PATH
try {
    New-Item -ItemType Directory -Path $fpkgRoot, $cons, $shim2 -Force | Out-Null
    Copy-Item -Recurse (Join-Path $pkg 'scripts') (Join-Path $fpkgRoot 'scripts')
    Copy-Item (Join-Path $pkg 'manifest-template.json') $fpkgRoot
    Copy-Item (Join-Path $pkg 'package-manifest.json') $fpkgRoot
    Set-Content -LiteralPath (Join-Path $fpkgRoot 'scripts\install.ps1') -Value "# test stub: the ADOPT cases assert on the reconciled manifest, which upgrade.ps1 writes before install runs`nexit 0"

    # TWO dispatchers, deliberately. upgrade.ps1's fstat format string carries
    # '|' characters; routing that through a .bat means cmd.exe re-parses the
    # argument and an unquoted '|' becomes a pipe operator (real p4.exe never
    # goes through cmd, so only a .bat shim hits this). PowerShell resolves the
    # .ps1 ahead of the .bat, so in-PowerShell p4 calls get intact args, while
    # upgrade's `cmd /c "p4 change -i < spec"` still finds the .bat.
    @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$pkg\scripts\fake-p4.ps1" %*
"@ | Set-Content -Path (Join-Path $shim2 'p4.bat') -Encoding ASCII
    @"
& "$pkg\scripts\fake-p4.ps1" @args
exit `$LASTEXITCODE
"@ | Set-Content -Path (Join-Path $shim2 'p4.ps1') -Encoding ASCII

    # Old consumer manifest via the real init-consumer (VC=perforce), then mutated.
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fpkgRoot 'scripts\init-consumer.ps1') `
        -TargetRoot $cons -PackageRoot $fpkgRoot -ProjectName AdoptTest `
        -VersionControl perforce -Tools claude -Overlays core *> (Join-Path $t2 'init.log')
    if ($LASTEXITCODE -ne 0) { Bad 'ADOPT fixture' 'init-consumer failed'; Get-Content (Join-Path $t2 'init.log') -Tail 10 | Write-Host; throw 'adopt-fixture' }

    $mp2 = Join-Path $cons 'Docs\agents\scaffold-manifest.json'
    $mb2 = [IO.File]::ReadAllBytes($mp2); if ($mb2[0] -eq 0xEF) { $mb2 = $mb2[3..($mb2.Length-1)] }
    $man2 = [Text.Encoding]::UTF8.GetString($mb2) | ConvertFrom-Json
    $man2.files += [pscustomobject]@{
        path='.claude/rules/TeamRule.md'; tool='common'; owner='project'; ownerOverlay=$null
        sourceTemplate=$null; sourceCommit='project-local'; hashPolicy='sha256'
        contentHash='sha256:stale'; depotRevision=3; mergeStrategy='manual-only'; localOnly=$false
        writablePolicy='human-owned'; baselineState='adopted-on-upgrade'
        upstreamDerived=$false; upstreamLicense=$null; blockHashPolicy='not-applicable'
        notes='evidence: reviewed in CL 999; do not clobber'
    }
    [IO.File]::WriteAllText($mp2, ($man2 | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding($true)))

    # On-disk files: TeamRule exists at depot head; PendingRule exists but is a
    # pending add (its fstat record below carries an EMPTY headRev).
    New-Item -ItemType Directory -Path (Join-Path $cons '.claude\rules') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $cons '.claude\rules\TeamRule.md') -Value 'team rule body' -NoNewline
    Set-Content -LiteralPath (Join-Path $cons '.claude\rules\PendingRule.md') -Value 'pending-add body' -NoNewline

    $env:PATH = "$shim2;$origPath2"
    $env:FAKE_P4_WHERE_FILE    = '//fake/depot/Docs/agents/scaffold-manifest.json'
    $env:FAKE_P4_FSTAT_RECORDS = "//fake/depot/.claude/rules/TeamRule.md|7|edit`n//fake/depot/.claude/rules/PendingRule.md||add"

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $pkg 'upgrade.ps1') `
        -TargetRoot $cons -PackageRoot $fpkgRoot -Apply -Yes *> (Join-Path $t2 'apply.log')
    if ($LASTEXITCODE -eq 0) { Ok 'ADOPT: perforce upgrade -Apply exit 0 under the fake-p4 shim' }
    else { Bad 'ADOPT: apply exit' "exit $LASTEXITCODE"; Get-Content (Join-Path $t2 'apply.log') -Tail 15 | Write-Host }

    $mb3 = [IO.File]::ReadAllBytes($mp2); if ($mb3[0] -eq 0xEF) { $mb3 = $mb3[3..($mb3.Length-1)] }
    $man3 = [Text.Encoding]::UTF8.GetString($mb3) | ConvertFrom-Json
    $team = $man3.files | Where-Object { $_.path -eq '.claude/rules/TeamRule.md' }
    $pend = $man3.files | Where-Object { $_.path -eq '.claude/rules/PendingRule.md' }

    if ($team -and $team.notes -eq 'evidence: reviewed in CL 999; do not clobber' -and
        $team.baselineState -eq 'adopted-on-upgrade' -and $team.sourceCommit -eq 'project-local' -and
        $team.writablePolicy -eq 'human-owned') {
        Ok 'ADOPT (a): project-owned entry kept verbatim -- notes/baselineState/sourceCommit survive'
    } else { Bad 'ADOPT (a): field preservation' ("entry=" + ($team | ConvertTo-Json -Compress)) }
    if ($team -and $team.depotRevision -eq 7 -and $team.contentHash -ne 'sha256:stale') {
        Ok 'ADOPT (a): recomputed fields refreshed (depotRevision=headRev, contentHash re-baselined)'
    } else { Bad 'ADOPT (a): recomputed fields' ("entry=" + ($team | ConvertTo-Json -Compress)) }
    if ($pend -and $null -eq $pend.depotRevision -and $pend.owner -eq 'project' -and $pend.baselineState -eq 'adopted-on-upgrade') {
        Ok 'ADOPT (b): pending-add (empty headRev) adopts with depotRevision null, NOT 0'
    } else { Bad 'ADOPT (b): pending-add depotRevision' ("entry=" + ($pend | ConvertTo-Json -Compress)) }
}
finally {
    $env:PATH = $origPath2
    Remove-Item Env:FAKE_P4_WHERE_FILE, Env:FAKE_P4_FSTAT_RECORDS -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $t2 -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Upgrade tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
