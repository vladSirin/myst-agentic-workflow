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
    $_.path -match '^\.(claude|Codex)/skills/' -and
    $_.sourceTemplate -and ($_.sourceTemplate -match '^templates/')
})
if ($riskySkills.Count -eq 0) { Ok 'no local-origin skill lives under templates/.../skills/ (re-vendor-safe)' }
else { Bad 'local skill in templates/.../skills (re-vendor would clobber it)' (($riskySkills | ForEach-Object { "$($_.path) <- $($_.sourceTemplate)" }) -join '; ') }

# 3. Local-origin skills live in the PLUGIN (v4.0.0; core-local overlay retired) and
#    keep the re-vendor-safety property: a mattpocock re-vendor can never clobber them.
$localOrigin = @('roundtable', 'setup-agentic-workflow')
$missing = @($localOrigin | Where-Object { -not (Test-Path "$PSScriptRoot\..\plugins\myst-dev-kit\skills\$_\SKILL.md") })
if ($missing.Count -eq 0) { Ok "local-origin skills present in the plugin ($($localOrigin -join ', '))" }
else { Bad 'local-origin skills in plugin' ($missing -join ', ') }

# 4. No manifest entry still references the retired core-local overlay paths.
$staleCl = @($m.files | Where-Object { $_.sourceTemplate -and $_.sourceTemplate -match '^overlays/core-local/' })
if ($staleCl.Count -eq 0) { Ok 'no manifest entry references retired overlays/core-local/' }
else { Bad 'stale core-local sourceTemplates' (($staleCl | ForEach-Object { $_.path }) -join '; ') }

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Provenance tests: {0} passed, {1} failed" -f $pass, $fail)
Write-Host '=============================================================='
if ($fail -gt 0) { exit 1 } else { exit 0 }
