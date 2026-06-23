# run-provenance-tests.ps1 -- enforce the local-origin vs upstream provenance convention.
#
# Two invariants protect against upstream-sync DRIFT clobbering package-invented content
# (ADR: vendor-and-overlay + core-local). A re-vendor from mattpocock/skills only ever writes
# under templates/{tool}/.{tool}/skills/<upstream-name>/, so:
#   1. Every upstreamDerived=true entry must carry an upstreamLicense (provenance is complete).
#   2. No LOCAL-origin (upstreamDerived=false) SKILL may live under templates/.../skills/ — local
#      skills must live in an overlay (e.g. overlays/core-local/), which re-vendor never touches.
#      (Local non-skill content — commands/workflows/agents/scripts — may stay in templates/,
#      because the upstream skill sync does not target those directories.)
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$m = Get-Content "$pkg\manifest-template.json" -Raw | ConvertFrom-Json
$pass = 0; $fail = 0
function Ok($n)     { Write-Host ("[PASS] {0}" -f $n);         $script:pass++ }
function Bad($n,$w) { Write-Host ("[FAIL] {0}: {1}" -f $n,$w); $script:fail++ }

# 1. upstreamDerived=true => has a license (no anomaly).
$noLicense = @($m.files | Where-Object { $_.upstreamDerived -eq $true -and -not $_.upstreamLicense })
if ($noLicense.Count -eq 0) { Ok 'every upstreamDerived=true entry carries an upstreamLicense' }
else { Bad 'upstreamDerived=true missing license' (($noLicense | ForEach-Object { $_.path }) -join '; ') }

# 2. No local-origin SKILL sourced from templates/.../skills/ (must live in an overlay).
$riskySkills = @($m.files | Where-Object {
    $_.upstreamDerived -eq $false -and
    $_.path -match '^\.(claude|Codex|opencode)/skills/' -and
    $_.sourceTemplate -and ($_.sourceTemplate -match '^templates/')
})
if ($riskySkills.Count -eq 0) { Ok 'no local-origin skill lives under templates/.../skills/ (re-vendor-safe)' }
else { Bad 'local skill in templates/.../skills (re-vendor would clobber it)' (($riskySkills | ForEach-Object { "$($_.path) <- $($_.sourceTemplate)" }) -join '; ') }

# 3. core-local entries are well-formed (owner=overlay, ownerOverlay=core-local, upstreamDerived=false).
$coreLocal = @($m.files | Where-Object { $_.ownerOverlay -eq 'core-local' })
$badCoreLocal = @($coreLocal | Where-Object { $_.owner -ne 'overlay' -or $_.upstreamDerived -ne $false -or ($_.sourceTemplate -and $_.sourceTemplate -notmatch '^overlays/core-local/') })
if ($coreLocal.Count -gt 0 -and $badCoreLocal.Count -eq 0) { Ok "core-local entries well-formed ($($coreLocal.Count) entries)" }
elseif ($coreLocal.Count -eq 0) { Bad 'core-local overlay' 'no core-local entries found (expected at least roundtable)' }
else { Bad 'core-local entries malformed' (($badCoreLocal | ForEach-Object { $_.path }) -join '; ') }

# 4. core-local is a declared overlay.
if ($m.overlays -contains 'core-local') { Ok "core-local declared in manifest overlays list" }
else { Bad 'core-local overlay not declared' ($m.overlays -join ', ') }

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Provenance tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
