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

# --- 5. Description: lockstep on the Claude side; the Codex manifest MAY diverge, but only
# on the record. The two tools genuinely do not receive the same capabilities, so forcing one
# string across both manifests forces one of them to lie. v4.25.1 diverged the Codex
# description deliberately (to state that the Markdown reviewer agents do not run there) and
# turned this check red; it stayed red through v4.25.2 because nobody re-read the suite after
# merging. Allowing the divergence unconditionally would just delete the check, so: divergence
# is legal exactly when the Codex description points at the doc that explains it.
$claudeDescs = @(@($cme.description, $cp.description) | Sort-Object -Unique)
if ($claudeDescs.Count -ne 1) {
    Bad 'description (claude side)' "$($claudeDescs.Count) distinct - marketplace entry and plugin manifest must agree"
}
elseif ($xp.description -eq $cp.description) {
    Ok 'description identical across all manifests'
}
elseif ($xp.description -match 'tool-capability-matrix') {
    Ok 'description diverges for Codex, and cites tool-capability-matrix.md for why'
}
else {
    Bad 'description (codex)' 'diverges from the Claude manifests without citing docs/tool-capability-matrix.md - state the capability difference on the record or keep the strings identical'
}

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
        # The Claude-side no-op gate must precede any stdin read (double-fire guard), AND it
        # must test a variable that actually exists. Until 4.26.0 this test asserted the literal
        # `[ -z "${PLUGIN_ROOT:-}" ] && exit 0` - a gate on a variable no host ever sets, so it
        # was always true and the bridge never ran the audit for anyone. The test did not merely
        # miss that: it PINNED it, because any correct fix reported as a regression. A test that
        # asserts an implementation string cannot notice the string is wrong. So assert the two
        # PROPERTIES instead, and name the host explicitly.
        $body = Get-Content -Raw -LiteralPath $script
        $gateLine = ($body -split "`n" | Select-String -Pattern 'exit 0' | Select-Object -First 1)
        $stdinLine = ($body -split "`n" | Select-String -Pattern 'exec bash' | Select-Object -First 1)
        if ($body -match 'CLAUDECODE') {
            if ($gateLine -and $stdinLine -and $gateLine.LineNumber -lt $stdinLine.LineNumber) {
                Ok 'bridge gates on CLAUDECODE (a var Claude Code really exports) before reading stdin'
            } else { Bad 'bridge gate order' 'gate must precede the exec that hands stdin to the audit' }
        }
        elseif ($body -match 'PLUGIN_ROOT:-') {
            Bad 'bridge gate' 'gates on PLUGIN_ROOT, which NO host sets (verified against codex.exe 0.146.0) - the bridge would never run the audit on any host'
        }
        else { Bad 'bridge gate' 'no recognisable host gate - Claude Code would double-warn' }
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
