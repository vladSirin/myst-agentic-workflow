# run-devkit-setup-tests.ps1 -- setup-devkit.ps1 behaviour
#
# Everything runs against throwaway sandboxes: a fixture package tree, a fixture
# git repo (for tag selection), and a temp opencode/codex config root. The real
# user config, the real dedicated clone, and this repo's git state are never
# touched (-CloneRoot bypasses the dedicated-clone logic; -OpencodeConfigDir /
# -CodexHome redirect every write).
#
# The named defects these cases pin:
#   - lexical tag sort picks v4.9.0 over v4.40.0 (version-aware sort required)
#   - PS 5.1 ConvertTo-Json default -Depth 2 silently flattens deep foreign config
#   - append-instead-of-replace in skills.paths -> duplicate skills, last-wins
#   - one broken CLI aborting the other tools' legs
#
#   exit 0 : all checks pass
#   exit 1 : one or more checks failed
param()
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$setup = Join-Path $pkg 'setup-devkit.ps1'

$pass = 0; $fail = 0; $skip = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }
function Skp($n,$w) { Write-Output "  SKIP  $n  ($w)"; $script:skip++ }

Write-Output "=============================================================="
Write-Output "setup-devkit tests"
Write-Output "=============================================================="

$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("devkit-setup-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $sandbox | Out-Null

# --- fixture package tree ----------------------------------------------------
# Just enough of plugins/myst-dev-kit for the script: one skill (self-verify
# checks tdd/SKILL.md) and the two agent sources with known bodies.
function New-FixturePackage([string]$root, [string]$reviewerBody) {
    $skills = Join-Path $root 'plugins/myst-dev-kit/skills/tdd'
    $agents = Join-Path $root 'plugins/myst-dev-kit/agents'
    New-Item -ItemType Directory -Force -Path $skills, $agents | Out-Null
    Set-Content -Path (Join-Path $skills 'SKILL.md') -Value "---`nname: tdd`ndescription: fixture`n---`nbody"
    Set-Content -Path (Join-Path $agents 'architecture-reviewer.md') -Value ("---`nname: architecture-reviewer`ntools: Read, Grep`nmodel: opus`ncolor: green`n---`n" + $reviewerBody)
    Set-Content -Path (Join-Path $agents 'radical-design-critic.md') -Value "---`nname: radical-design-critic`ncolor: purple`n---`nCritic body line one.`nLine two."
    Set-Content -Path (Join-Path $root 'package-manifest.json') -Value '{ "package": { "version": "0.0.0-fixture" } }'
}

$fixture = Join-Path $sandbox 'fixture-pkg'
New-FixturePackage $fixture "Reviewer body line one.`nLine two with detail."

$ocDir  = Join-Path $sandbox 'oc-config'
$cxHome = Join-Path $sandbox 'codex-home'
$cfgFile = Join-Path $ocDir 'opencode.json'

function Invoke-Setup([string[]]$extra) {
    $argv = @('-NoProfile', '-File', $setup, '-CloneRoot', $fixture,
              '-OpencodeConfigDir', $ocDir, '-CodexHome', $cxHome) + $extra
    $out = & pwsh @argv 2>&1 | Out-String
    return @{ Out = $out; Code = $LASTEXITCODE }
}

# --- 1. fresh setup (opencode + codex legs, no CLIs involved) -----------------
$r = Invoke-Setup @('-Tool', 'opencode')
if ($r.Code -eq 0) { Ok 'fresh opencode setup exits 0' } else { Bad 'fresh opencode setup exits 0' "exit $($r.Code): $($r.Out)" }

$raw = Get-Content -Raw $cfgFile
$cfg = $raw | ConvertFrom-Json
$expectedSkills = ((Join-Path $fixture 'plugins/myst-dev-kit/skills') -replace '\\', '/')

if (@($cfg.skills.paths).Count -eq 1 -and $cfg.skills.paths[0] -eq $expectedSkills) { Ok 'skills.paths holds exactly the fixture path' }
else { Bad 'skills.paths holds exactly the fixture path' ($raw) }

# PS ConvertTo-Json unwraps single-element arrays via the pipeline; the script must
# not fall into that -- paths has one entry and must still serialize as an array.
if ($raw -match '"paths":\s*\[') { Ok 'single-element skills.paths serializes as an array' }
else { Bad 'single-element skills.paths serializes as an array' 'no [ after "paths":' }

if ($cfg.mcp.'unreal-engine'.url -eq 'http://127.0.0.1:8092/mcp' -and $cfg.mcp.'unreal-engine'.type -eq 'remote') { Ok 'mcp.unreal-engine written' }
else { Bad 'mcp.unreal-engine written' $raw }

$askCount = 0
foreach ($p in $cfg.permission.skill.PSObject.Properties) { if ($p.Value -eq 'ask') { $askCount++ } }
# Derived, never hardcoded: the roster grows every time a gated skill is adopted, and a
# hardcoded count turns that into a spurious test failure (it did, at v4.43.0).
$declaredManual = ([regex]::Match(
    (Get-Content "$PSScriptRoot\..\setup-devkit.ps1" -Raw),
    '(?s)\$ManualSkills\s*=\s*@\((.*?)\)').Groups[1].Value -split ',' |
    Where-Object { $_.Trim() -match "^'" }).Count
if ($askCount -eq $declaredManual) { Ok "permission.skill ask-map matches ManualSkills roster ($declaredManual skills)" }
else { Bad "permission.skill ask-map matches ManualSkills roster ($declaredManual skills)" "found $askCount" }

# OpenCode consumes installed Claude plugins; the plugin's reviewer twins resolve
# writable there. The script must ship them disabled.
$twinA = $cfg.agent.'myst-dev-kit:architecture-reviewer'
$twinB = $cfg.agent.'myst-dev-kit:radical-design-critic'
if ($twinA.disable -eq $true -and $twinB.disable -eq $true) { Ok 'writable Claude-plugin agent twins are disabled' }
else { Bad 'writable Claude-plugin agent twins are disabled' $raw }

$ocAgent = Join-Path $ocDir 'agents/myst/architecture-reviewer.md'
if (Test-Path $ocAgent) {
    $a = Get-Content -Raw $ocAgent
    $headOk = ($a -match '(?m)^mode: subagent$') -and ($a -match '(?m)^  edit: deny$') -and ($a -match 'color: "#[0-9a-f]{6}"')
    $noLeak = ($a -notmatch '(?m)^tools:') -and ($a -notmatch '(?m)^model:') -and ($a -notmatch 'color: green')
    if ($headOk -and $noLeak) { Ok 'opencode agent has the fixed frontmatter (no Claude keys leaked)' }
    else { Bad 'opencode agent has the fixed frontmatter (no Claude keys leaked)' $a }
    if ($a -match [regex]::Escape("Reviewer body line one.`nLine two with detail.")) { Ok 'opencode agent body is verbatim' }
    else { Bad 'opencode agent body is verbatim' $a }
} else { Bad 'opencode agent generated' 'file missing' }

# --- 2. idempotent re-run ----------------------------------------------------
$before = Get-Content -Raw $cfgFile
$r = Invoke-Setup @('-Tool', 'opencode')
$after = Get-Content -Raw $cfgFile
if (($r.Code -eq 0) -and ($before -eq $after)) { Ok 're-run is a byte-identical no-op' }
else { Bad 're-run is a byte-identical no-op' "exit $($r.Code), identical=$($before -eq $after)" }

# --- 3. replace-not-append from a different clone path ------------------------
$fixture2 = Join-Path $sandbox 'fixture-pkg-2'
New-FixturePackage $fixture2 'Second clone body.'
$argv = @('-NoProfile', '-File', $setup, '-CloneRoot', $fixture2, '-OpencodeConfigDir', $ocDir, '-CodexHome', $cxHome, '-Tool', 'opencode')
$null = & pwsh @argv 2>&1 | Out-String
$cfg = Get-Content -Raw $cfgFile | ConvertFrom-Json
$mystEntries = @($cfg.skills.paths | Where-Object { $_ -match 'myst-dev-kit/skills' })
if ($mystEntries.Count -eq 1 -and $mystEntries[0] -match 'fixture-pkg-2') { Ok 'second run from a different clone replaces, never appends' }
else { Bad 'second run from a different clone replaces, never appends' ($cfg.skills.paths -join ' | ') }

# --- 4. deep foreign config survives the merge (the -Depth trap) --------------
Remove-Item -Recurse -Force $ocDir; New-Item -ItemType Directory -Force -Path $ocDir | Out-Null
$foreign = '{ "keep": { "l2": { "l3": { "l4": { "l5": "deep-value", "arr": [1, 2, 3] } } } }, "skills": { "paths": ["/keep/other-skills"] }, "theme": "dark" }'
Set-Content -Path $cfgFile -Value $foreign
$r = Invoke-Setup @('-Tool', 'opencode')
$raw = Get-Content -Raw $cfgFile
$cfg = $raw | ConvertFrom-Json
if ($cfg.keep.l2.l3.l4.l5 -eq 'deep-value' -and @($cfg.keep.l2.l3.l4.arr).Count -eq 3 -and $cfg.theme -eq 'dark') { Ok 'foreign keys survive at depth 5' }
else { Bad 'foreign keys survive at depth 5' $raw }
if ($raw -notmatch 'System\.Object') { Ok 'no System.Object depth-truncation artifacts' }
else { Bad 'no System.Object depth-truncation artifacts' $raw }
if (@($cfg.skills.paths) -contains '/keep/other-skills') { Ok 'foreign skills path kept alongside ours' }
else { Bad 'foreign skills path kept alongside ours' ($cfg.skills.paths -join ' | ') }

# --- 5. uninstall round-trip --------------------------------------------------
$r = Invoke-Setup @('-Tool', 'opencode', '-Uninstall')
$raw = Get-Content -Raw $cfgFile
$cfg = $raw | ConvertFrom-Json
$stillMyst = @($cfg.skills.paths | Where-Object { $_ -match 'myst' }).Count
$agentsGone = -not (Test-Path (Join-Path $ocDir 'agents/myst'))
$mcpGone = -not ($cfg.PSObject.Properties['mcp'] -and $cfg.mcp.PSObject.Properties['unreal-engine'])
$twinsGone = -not ($cfg.PSObject.Properties['agent'] -and $cfg.agent.PSObject.Properties['myst-dev-kit:architecture-reviewer'])
if (($r.Code -eq 0) -and ($stillMyst -eq 0) -and $agentsGone -and $mcpGone -and $twinsGone) { Ok 'uninstall removes ours' }
else { Bad 'uninstall removes ours' "exit $($r.Code) mystPaths=$stillMyst agentsGone=$agentsGone mcpGone=$mcpGone twinsGone=$twinsGone" }
if ($cfg.keep.l2.l3.l4.l5 -eq 'deep-value' -and $cfg.theme -eq 'dark' -and (@($cfg.skills.paths) -contains '/keep/other-skills')) { Ok 'uninstall leaves foreign keys intact' }
else { Bad 'uninstall leaves foreign keys intact' $raw }

# --- 6. JSONC config is never touched -----------------------------------------
$jsonc = "{`n  // my comment`n  `"theme`": `"dark`"`n}"
Set-Content -Path $cfgFile -Value $jsonc
$bytesBefore = [System.IO.File]::ReadAllBytes($cfgFile)
$r = Invoke-Setup @('-Tool', 'opencode')
$bytesAfter = [System.IO.File]::ReadAllBytes($cfgFile)
$untouched = ([Convert]::ToBase64String($bytesBefore) -eq [Convert]::ToBase64String($bytesAfter))
if (($r.Code -ne 0) -and $untouched -and ($r.Out -match 'Merge this yourself')) { Ok 'JSONC config: untouched, snippet printed, exit 1' }
else { Bad 'JSONC config: untouched, snippet printed, exit 1' "exit $($r.Code) untouched=$untouched" }
Remove-Item $cfgFile -Force

# --- 7. codex agent TOML generation -------------------------------------------
# -CodexHome marks the sandbox: the leg generates files and never drives the real
# codex CLI, so this is deterministic whether or not codex is installed here.
$r = Invoke-Setup @('-Tool', 'codex')
$toml = Join-Path $cxHome 'agents/architecture-reviewer.toml'
if (Test-Path $toml) {
    $t = Get-Content -Raw $toml
    $ok = ($t -match '(?m)^name = "architecture-reviewer"$') -and
          ($t -match '(?m)^sandbox_mode = "read-only"$') -and
          ($t -match [regex]::Escape('Reviewer body line one.')) -and
          ($t -match '(?ms)developer_instructions = """.*"""')
    if ($ok) { Ok 'codex TOML agent generated (read-only, verbatim body)' }
    else { Bad 'codex TOML agent generated (read-only, verbatim body)' $t }
} else {
    Bad 'codex TOML agent generated' "no TOML written: $($r.Out)"
}

# --- 8. TOML guard: a body containing triple quotes is skipped, loudly ---------
$fixture3 = Join-Path $sandbox 'fixture-pkg-poison'
New-FixturePackage $fixture3 ('Poisoned body with """ inside.')
$argv = @('-NoProfile', '-File', $setup, '-CloneRoot', $fixture3, '-OpencodeConfigDir', (Join-Path $sandbox 'oc3'), '-CodexHome', (Join-Path $sandbox 'cx3'), '-Tool', 'codex')
$out = & pwsh @argv 2>&1 | Out-String
$poisoned = Join-Path $sandbox 'cx3/agents/architecture-reviewer.toml'
$cleanOne = Join-Path $sandbox 'cx3/agents/radical-design-critic.toml'
if ((-not (Test-Path $poisoned)) -and ($out -match 'triple quotes')) { Ok 'TOML guard skips a """ body with a visible warning' }
else { Bad 'TOML guard skips a """ body with a visible warning' $out }
if (Test-Path $cleanOne) { Ok 'clean sibling agent still generated' }
else { Bad 'clean sibling agent still generated' $out }

# --- 9. tag selection: version-aware, not lexical ------------------------------
$gitOk = [bool](Get-Command git -ErrorAction SilentlyContinue)
if (-not $gitOk) {
    Skp 'version-aware tag selection' 'git not available'
} else {
    $srcRepo = Join-Path $sandbox 'tag-src'
    New-Item -ItemType Directory -Force -Path $srcRepo | Out-Null
    Push-Location $srcRepo
    try {
        $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        & git init --quiet 2>&1 | Out-Null
        & git config user.email 't@example.invalid' 2>&1 | Out-Null
        & git config user.name 'tests' 2>&1 | Out-Null
        New-FixturePackage $srcRepo 'Tag fixture body.'
        Set-Content 'package-manifest.json' '{ "package": { "version": "4.9.0" } }'
        & git add -A 2>&1 | Out-Null; & git commit -qm 'v4.9.0' 2>&1 | Out-Null; & git tag v4.9.0 2>&1 | Out-Null
        Set-Content 'package-manifest.json' '{ "package": { "version": "4.40.0" } }'
        & git add -A 2>&1 | Out-Null; & git commit -qm 'v4.40.0' 2>&1 | Out-Null; & git tag v4.40.0 2>&1 | Out-Null
        $ErrorActionPreference = $prevEap
    } finally { Pop-Location }

    $work = Join-Path $sandbox 'tag-work'
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & git clone --quiet $srcRepo $work 2>&1 | Out-Null
    & git -C $work checkout --quiet v4.9.0 2>&1 | Out-Null
    $ErrorActionPreference = $prevEap

    $argv = @('-NoProfile', '-File', $setup, '-CloneRoot', $work, '-ForceGitUpdate',
              '-OpencodeConfigDir', (Join-Path $sandbox 'oc-tags'), '-CodexHome', (Join-Path $sandbox 'cx-tags'), '-Tool', 'opencode')
    $null = & pwsh @argv 2>&1 | Out-String
    $v = (Get-Content -Raw (Join-Path $work 'package-manifest.json') | ConvertFrom-Json).package.version
    if ($v -eq '4.40.0') { Ok 'latest tag resolves to v4.40.0, not lexical v4.9.0' }
    else { Bad 'latest tag resolves to v4.40.0, not lexical v4.9.0' "landed on $v" }
}

# --- 10. dispatch: dry-run legs + continuation past a failing leg --------------
$stubs = Join-Path $sandbox 'stubs'
New-Item -ItemType Directory -Force -Path $stubs | Out-Null
Set-Content -Path (Join-Path $stubs 'claude.cmd') -Value "@echo claude stub failing`r`n@exit /b 1"
Set-Content -Path (Join-Path $stubs 'codex.cmd')  -Value "@echo codex stub`r`n@exit /b 0"
Set-Content -Path (Join-Path $stubs 'opencode.cmd') -Value "@echo opencode stub`r`n@exit /b 0"

$prevPath = $env:PATH
try {
    $env:PATH = $stubs + [System.IO.Path]::PathSeparator + $env:PATH

    $oc4 = Join-Path $sandbox 'oc4'
    $argv = @('-NoProfile', '-File', $setup, '-CloneRoot', $fixture, '-OpencodeConfigDir', $oc4, '-CodexHome', (Join-Path $sandbox 'cx4'), '-DryRun')
    $out = & pwsh @argv 2>&1 | Out-String
    $legs = @('claude', 'codex', 'opencode') | Where-Object { $out -match "\[dry-run\].*$_" }
    if (@($legs).Count -eq 3) { Ok 'dry-run plans all three detected legs' }
    else { Bad 'dry-run plans all three detected legs' $out }
    if (-not (Test-Path (Join-Path $oc4 'opencode.json'))) { Ok 'dry-run writes nothing' }
    else { Bad 'dry-run writes nothing' 'config file appeared' }

    # Real run: claude stub fails; the opencode leg must still complete.
    $oc5 = Join-Path $sandbox 'oc5'
    $argv = @('-NoProfile', '-File', $setup, '-CloneRoot', $fixture, '-OpencodeConfigDir', $oc5, '-CodexHome', (Join-Path $sandbox 'cx5'))
    $out = & pwsh @argv 2>&1 | Out-String
    $code = $LASTEXITCODE
    $ocDone = Test-Path (Join-Path $oc5 'opencode.json')
    if (($code -ne 0) -and $ocDone -and ($out -match '\[FAIL\] claude')) { Ok 'a failing claude leg does not abort the opencode leg; aggregate exit is 1' }
    else { Bad 'a failing claude leg does not abort the opencode leg' "exit $code ocDone=$ocDone`n$out" }
} finally {
    $env:PATH = $prevPath
}

# --- cleanup -------------------------------------------------------------------
try { Remove-Item -Recurse -Force $sandbox } catch { }

Write-Output ""
Write-Output "=============================================================="
Write-Output "setup-devkit tests: $pass passed, $fail failed, $skip skipped"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
