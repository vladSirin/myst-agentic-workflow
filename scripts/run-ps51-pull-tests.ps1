# run-ps51-pull-tests.ps1 -- the Windows PowerShell 5.1 `git pull` regression.
#
# update.ps1 step 1 used to die under PS 5.1 with a raw RemoteException EXACTLY
# when an update existed: git writes its ref-transfer summary ("From <origin>
#  abc..def  main -> origin/main") to STDERR by design, and under EAP='Stop' +
# a stderr redirection Windows PowerShell turns that into a terminating
# NativeCommandError. The fix scopes EAP around the native call and judges
# $LASTEXITCODE (update.ps1 step 1).
#
# This suite rebuilds that exact scenario with NO network: a LOCAL bare origin
# seeded from this package's tree, a clone, a consumer installed from the
# clone, then a fresh commit pushed to origin so the clone's `git pull` HAS
# content -- and runs update.ps1 end-to-end UNDER powershell.exe, asserting
# exit 0 and that the pull really transferred the commit (the crash trigger).
#
# Runnable under pwsh too: the 5.1 part is an explicit powershell.exe child.
# If powershell.exe or git is absent (e.g. non-Windows), prints a LOUD SKIP
# per case and exits 0; the '  SKIP  ' lines surface in the CI job summary.
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0; $skip = 0
function Ok($n)     { Write-Host ("[PASS] {0}" -f $n);         $script:pass++ }
function Bad($n,$w) { Write-Host ("[FAIL] {0}: {1}" -f $n,$w); $script:fail++ }
function Skp($n,$w) { Write-Host ("  SKIP  {0}  ({1})" -f $n,$w); $script:skip++ }

$cases = @(
    'fixture: clone is behind origin before the update',
    'update.ps1 under powershell.exe exits 0 when the pull has content (the 5.1 regression)',
    'git pull actually transferred the new commit (stderr-summary path exercised)',
    'update.ps1 reports Update complete'
)

$ps51 = Get-Command powershell.exe -ErrorAction SilentlyContinue
$git  = Get-Command git -ErrorAction SilentlyContinue
if (-not $ps51 -or -not $git) {
    $why = if (-not $ps51) { 'powershell.exe absent (non-Windows?)' } else { 'git absent' }
    Write-Host ''
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    Write-Host ("!! {0} -- the PS 5.1 pull regression was NOT verified." -f $why)
    Write-Host '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    foreach ($c in $cases) { Skp $c $why }
    Write-Host ''
    Write-Host '=============================================================='
    Write-Host ("PS51 pull tests: 0 passed, 0 failed, {0} SKIPPED" -f $skip)
    Write-Host '=============================================================='
    exit 0
}

# Native git with scoped EAP: this suite itself must run under BOTH pwsh and
# powershell.exe, so every git call takes the same guard update.ps1 now takes.
function Invoke-Git {
    param([Parameter(Mandatory)][string[]] $GitArgs, [string] $WorkDir = $null)
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        if ($WorkDir) { $out = & git -C $WorkDir @GitArgs 2>&1 | Out-String }
        else          { $out = & git @GitArgs 2>&1 | Out-String }
        return [pscustomobject]@{ Code = $LASTEXITCODE; Out = $out }
    } finally { $ErrorActionPreference = $prevEap }
}
$identity = @('-c','user.email=ci@example.invalid','-c','user.name=ps51-suite')

$t = Join-Path $env:TEMP ('ps51pull-' + [guid]::NewGuid().ToString('N'))
$bare     = Join-Path $t 'origin.git'
$seed     = Join-Path $t 'seed'
$clone    = Join-Path $t 'clone'
$consumer = Join-Path $t 'consumer'
try {
    New-Item -ItemType Directory -Path $seed, $consumer -Force | Out-Null

    # Seed working tree: enough of the package for setup + update to run FROM THE
    # CLONE (scripts, templates, overlays, plugins, top-level entry points).
    foreach ($d in 'scripts','templates','overlays','plugins') {
        Copy-Item -Recurse (Join-Path $pkg $d) (Join-Path $seed $d)
    }
    foreach ($f in 'setup.ps1','update.ps1','upgrade.ps1','promote.ps1','manifest-template.json','package-manifest.json','.gitattributes') {
        if (Test-Path -LiteralPath (Join-Path $pkg $f)) { Copy-Item (Join-Path $pkg $f) (Join-Path $seed $f) }
    }

    $r = Invoke-Git @('init', $seed);                          if ($r.Code -ne 0) { throw "git init seed: $($r.Out)" }
    $r = Invoke-Git @('add','-A') $seed;                       if ($r.Code -ne 0) { throw "git add: $($r.Out)" }
    $r = Invoke-Git ($identity + @('commit','-m','seed package tree')) $seed
    if ($r.Code -ne 0) { throw "git commit (seed): $($r.Out)" }
    $r = Invoke-Git @('init','--bare', $bare);                 if ($r.Code -ne 0) { throw "git init --bare: $($r.Out)" }
    $r = Invoke-Git @('remote','add','origin', $bare) $seed;   if ($r.Code -ne 0) { throw "git remote add: $($r.Out)" }
    $r = Invoke-Git @('push','origin','HEAD') $seed;           if ($r.Code -ne 0) { throw "git push (seed): $($r.Out)" }
    # Point the bare repo's HEAD at whatever branch the seed pushed, so clone
    # checks out a branch regardless of the machine's init.defaultBranch.
    $branch = (Invoke-Git @('rev-parse','--abbrev-ref','HEAD') $seed).Out.Trim()
    $r = Invoke-Git @('symbolic-ref','HEAD',"refs/heads/$branch") $bare
    if ($r.Code -ne 0) { throw "git symbolic-ref: $($r.Out)" }
    $r = Invoke-Git @('clone', $bare, $clone);                 if ($r.Code -ne 0) { throw "git clone: $($r.Out)" }

    # Consumer installed FROM THE CLONE (filesystem VC; run under powershell.exe
    # so the whole pipeline is 5.1 end to end).
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $clone 'setup.ps1') `
            -TargetRoot $consumer -ProjectName Ps51Fix -Tools claude -Overlays core -Yes *> (Join-Path $t 'setup.log')
        $setupCode = $LASTEXITCODE
    } finally { $ErrorActionPreference = $prevEap }
    if ($setupCode -ne 0) {
        Bad 'ps51 fixture' "setup.ps1 from clone failed (exit $setupCode)"
        Get-Content (Join-Path $t 'setup.log') -Tail 12 | Write-Host
        throw 'ps51-fixture'
    }

    # Advance origin so the clone's next pull HAS content.
    Set-Content -LiteralPath (Join-Path $seed 'z-ps51-fixture.txt') -Value 'advance the remote so git pull transfers a ref'
    $r = Invoke-Git @('add','-A') $seed;                       if ($r.Code -ne 0) { throw "git add (advance): $($r.Out)" }
    $r = Invoke-Git ($identity + @('commit','-m','advance origin')) $seed
    if ($r.Code -ne 0) { throw "git commit (advance): $($r.Out)" }
    $r = Invoke-Git @('push','origin','HEAD') $seed;           if ($r.Code -ne 0) { throw "git push (advance): $($r.Out)" }

    $seedHead  = (Invoke-Git @('rev-parse','HEAD') $seed).Out.Trim()
    $cloneHead = (Invoke-Git @('rev-parse','HEAD') $clone).Out.Trim()
    if ($seedHead -and $cloneHead -and $seedHead -ne $cloneHead) { Ok $cases[0] }
    else { Bad $cases[0] "seed=$seedHead clone=$cloneHead" }

    # THE regression run: update.ps1 under powershell.exe, EAP semantics live.
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $clone 'update.ps1') `
            -TargetRoot $consumer -Yes 2>&1 | Out-String
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $prevEap }

    if ($code -eq 0) { Ok $cases[1] }
    else { Bad $cases[1] "exit $code`n$($out | Select-Object -Last 1)"; Write-Host $out }

    $cloneHeadAfter = (Invoke-Git @('rev-parse','HEAD') $clone).Out.Trim()
    if ($cloneHeadAfter -eq $seedHead) { Ok $cases[2] }
    else { Bad $cases[2] "clone HEAD $cloneHeadAfter != origin head $seedHead" }

    if ($out -match 'Update complete') { Ok $cases[3] }
    else { Bad $cases[3] 'no "Update complete" in output' }
}
finally { Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue }

Write-Host ''
Write-Host '=============================================================='
Write-Host ("PS51 pull tests: {0} passed, {1} failed, {2} skipped" -f $pass, $fail, $skip)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
