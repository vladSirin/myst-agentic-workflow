# run-marketplace-tests.ps1 -- dual marketplace/plugin manifest consistency
#
# The marketplace ships FOUR hand-authored manifests that must agree (we assert
# consistency by test instead of generating both from one source -- one plugin,
# four small files; a generator would be more machinery than the payload):
#   .claude-plugin/marketplace.json                    (Claude Code native)
#   .agents/plugins/marketplace.json                   (Codex native)
#   plugins/myst-dev-kit/.claude-plugin/plugin.json    (Claude plugin manifest)
#   plugins/myst-dev-kit/.codex-plugin/plugin.json     (Codex plugin manifest)
#
#   exit 0 : all checks pass
#   exit 1 : one or more checks failed
param()
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }

function Load($rel) {
    $p = Join-Path $pkg $rel
    if (-not (Test-Path -LiteralPath $p)) { Bad "parse $rel" 'file missing'; return $null }
    try { $j = Get-Content -Raw -LiteralPath $p | ConvertFrom-Json; Ok "parse $rel"; return $j }
    catch { Bad "parse $rel" $_.Exception.Message; return $null }
}

# --- 1. All four manifests parse ---
$cm = Load '.claude-plugin/marketplace.json'
$xm = Load '.agents/plugins/marketplace.json'
$cp = Load 'plugins/myst-dev-kit/.claude-plugin/plugin.json'
$xp = Load 'plugins/myst-dev-kit/.codex-plugin/plugin.json'
if (-not ($cm -and $xm -and $cp -and $xp)) {
    Write-Output "`nMarketplace tests: $pass passed, $fail failed"; exit 1
}

# --- 2. Marketplace names agree (users reference plugin@<marketplace-name>) ---
if ($cm.name -eq $xm.name) { Ok "marketplace name agrees across tools ('$($cm.name)')" }
else { Bad 'marketplace name' "claude='$($cm.name)' codex='$($xm.name)'" }

# --- 3. Plugin identity: same name in all four files ---
$cme = $cm.plugins[0]; $xme = $xm.plugins[0]
$names = @(@($cme.name, $xme.name, $cp.name, $xp.name) | Sort-Object -Unique)
if ($names.Count -eq 1) { Ok "plugin name identical in all 4 manifests ('$($names[0])')" }
else { Bad 'plugin name' ($names -join ' vs ') }

# --- 4. Version lockstep: marketplace entry + both plugin manifests + package-manifest ---
$pkgVer = (Get-Content -Raw (Join-Path $pkg 'package-manifest.json') | ConvertFrom-Json).package.version
$vers = @(@($cme.version, $cp.version, $xp.version, $pkgVer) | Sort-Object -Unique)
if ($vers.Count -eq 1) { Ok "version lockstep across manifests + package-manifest ($($vers[0]))" }
else { Bad 'version lockstep' ($vers -join ' vs ') }

# --- 5. Description agrees (claude marketplace entry + both plugin manifests) ---
$descs = @(@($cme.description, $cp.description, $xp.description) | Sort-Object -Unique)
if ($descs.Count -eq 1) { Ok 'description identical across manifests' }
else { Bad 'description' "$($descs.Count) distinct descriptions" }

# --- 6. Sources resolve to the same plugin dir; both plugin manifests live in it ---
$cSrc = $cme.source            # claude: plain relative string
$xSrc = $xme.source.path       # codex: {source:'local', path:...}
if ($cSrc -eq $xSrc) { Ok "source path agrees ('$cSrc')" } else { Bad 'source path' "claude='$cSrc' codex='$($xSrc)'" }
$pluginDir = Join-Path $pkg ($cSrc -replace '^\./','' -replace '/','\')
foreach ($m in '.claude-plugin\plugin.json', '.codex-plugin\plugin.json') {
    if (Test-Path -LiteralPath (Join-Path $pluginDir $m)) { Ok "source dir carries $m" }
    else { Bad "source dir carries $m" "missing under $pluginDir" }
}

# --- 7. Codex-required policy fields present ---
if ($xme.policy.installation -and $xme.policy.authentication -and $xme.category) {
    Ok "codex policy fields present (installation=$($xme.policy.installation), authentication=$($xme.policy.authentication))"
} else { Bad 'codex policy fields' 'policy.installation / policy.authentication / category are required by the Codex marketplace schema' }

# --- 8. Every skill dir has a SKILL.md ---
$skillDirs = Get-ChildItem -Directory (Join-Path $pluginDir 'skills')
$noSkill = @($skillDirs | Where-Object { -not (Test-Path (Join-Path $_.FullName 'SKILL.md')) })
if ($noSkill.Count -eq 0) { Ok "all $($skillDirs.Count) skill dirs carry SKILL.md" }
else { Bad 'SKILL.md coverage' (($noSkill | ForEach-Object Name) -join ', ') }

# --- 9. hooks.json parses and its bridge script exists + gates before stdin ---
$hooks = Load 'plugins/myst-dev-kit/hooks/hooks.json'
if ($hooks) {
    $cmd = $hooks.hooks.PreToolUse[0].hooks[0].command
    if ($cmd -match '\$\{CLAUDE_PLUGIN_ROOT\}/([^"]+)') {
        $script = Join-Path $pluginDir ($Matches[1] -replace '/','\')
        if (Test-Path -LiteralPath $script) { Ok "hook bridge script exists ($($Matches[1]))" }
        else { Bad 'hook bridge script' "referenced but missing: $($Matches[1])" }
        # the Claude-side no-op gate must precede any stdin read (double-fire guard)
        $body = Get-Content -Raw -LiteralPath $script
        if ($body -match '(?m)^\[ -z "\$\{PLUGIN_ROOT:-\}" \] && exit 0') { Ok 'bridge gates on PLUGIN_ROOT before reading stdin' }
        else { Bad 'bridge gate' 'PLUGIN_ROOT no-op gate not found - Claude Code would double-warn' }
    } else { Bad 'hook command shape' "expected `${CLAUDE_PLUGIN_ROOT}/... in: $cmd" }
}

# --- 10. Upstream attribution travels with the plugin (installs copy only the plugin dir) ---
$lic = Join-Path $pluginDir 'LICENSE'
if ((Test-Path -LiteralPath $lic) -and ((Get-Content -Raw $lic) -match 'Matt Pocock')) {
    Ok 'plugin LICENSE present with upstream (Matt Pocock, MIT) attribution'
} else { Bad 'plugin LICENSE' 'missing or lacks the mattpocock/skills MIT attribution required for redistribution' }

Write-Output ""
Write-Output "=============================================================="
Write-Output "Marketplace tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
