# run-newuser-e2e-tests.ps1 — Phase 5 verification gate (issue 16)
#
# Simulates a new adopter following docs/install.md against a fresh empty
# target. Uses a synthetic 3-file package (one sentinel per tool) so the test
# stays fast and the assertions are readable.
#
# Filesystem-only (no Perforce). Preflight skips checks 4/6/10 gracefully
# when p4 isn't reachable (Phase 5 review finding fix).
#
#   exit 0 : both scenarios pass
#   exit 1 : any scenario fails
param()

$ErrorActionPreference = 'Stop'
$here    = $PSScriptRoot
$install = Join-Path $here 'install.ps1'
$compare = Join-Path $here 'compare-with-package.ps1'

$pass = 0; $fail = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }

function New-NewuserFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ("newuser-fx-" + [guid]::NewGuid().ToString('N'))
    $pkg     = Join-Path $root 'pkg'
    $target  = Join-Path $root 'target'

    # Synthetic per-tool sentinel templates (one each so we verify both tools).
    $tpls = @(
        @{ Rel='templates/codex/.Codex/skills/diagnose.md';    Body="# Codex diagnose`nuse {{game_docs_root}}/some.md`n" },
        @{ Rel='templates/claude/.claude/skills/diagnose.md';  Body="# Claude diagnose`nuse {{game_docs_root}}/some.md`n" }
    )
    foreach ($t in $tpls) {
        $p = Join-Path $pkg ($t.Rel -replace '/','\')
        New-Item -ItemType Directory -Path (Split-Path $p -Parent) -Force | Out-Null
        [IO.File]::WriteAllBytes($p, [Text.Encoding]::UTF8.GetBytes($t.Body))
    }

    $pkgMan = @{ package=@{name='fx';version='0.1.0'}; manifestSchema=@{schemaVersion=3; overlays=@('core')} } | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText((Join-Path $pkg 'package-manifest.json'), $pkgMan)

    # Bootstrap installed manifest: 3 entries, no hashes (fresh install).
    # Full v3 schema fields per package-manifest.json:requiredFileFields.
    New-Item -ItemType Directory -Path (Join-Path $target 'Docs\agents') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $target '.scratch') -Force | Out-Null
    function MkEntry($path, $tool, $tpl) {
        @{
            path=$path; tool=$tool; owner='package'; ownerOverlay='core'
            sourceTemplate=$tpl; sourceCommit='pending-package'
            contentHash=$null; hashPolicy='sha256'
            blockHash=$null; blockHashPolicy='not-applicable'
            depotRevision=$null
            mergeStrategy='copy'; localOnly=$false
            upstreamDerived=$false; upstreamLicense=$null
            writablePolicy='installer-owned'; baselineState='future-package'
            pendingChangelist=$null; conflictReport=$null
            lastCheckedAt='2026-05-21T00:00:00+00:00'
        }
    }
    $entries = @(
        MkEntry '.Codex/skills/diagnose.md'           'codex'    'templates/codex/.Codex/skills/diagnose.md'
        MkEntry '.claude/skills/diagnose.md'          'claude'   'templates/claude/.claude/skills/diagnose.md'
    )
    $instMan = @{ schemaVersion=3; installedProject=@{name='Acme_Game'; docsRoot='Docs'; gameDocsRoot='Acme_Game/Docs'}; files=$entries } | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText((Join-Path $target ('Docs/agents/scaffold-manifest.json' -replace '/','\')), $instMan)

    return @{ Root=$root; Pkg=$pkg; Target=$target }
}

function Run($script, $argList) {
    $full = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$script) + $argList
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { $out = & powershell.exe @full 2>&1; $code = $LASTEXITCODE } finally { $ErrorActionPreference = $prev }
    return [pscustomobject]@{ Code = $code; Out = (($out | ForEach-Object { [string]$_ }) -join "`n") }
}

# Scenario: fresh install lands both tool sentinels and compare reports clean.
$fx = New-NewuserFixture
$r = Run $install @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Tools','all','-Overlays','core','-Mode','Write')

# Check install command succeeded.
if ($r.Code -eq 0) { Ok 'install -Mode Write succeeded (preflight skipped p4 checks gracefully)' }
else { Bad 'install -Mode Write' "code=$($r.Code) out=$($r.Out)" }

# Check each per-tool sentinel landed.
$sentinels = @(
    @{ Tool='codex';    Path=(Join-Path $fx.Target '.Codex\skills\diagnose.md');           ExpectedHead='# Codex diagnose' }
    @{ Tool='claude';   Path=(Join-Path $fx.Target '.claude\skills\diagnose.md');          ExpectedHead='# Claude diagnose' }
)
foreach ($s in $sentinels) {
    if (-not (Test-Path -LiteralPath $s.Path)) {
        Bad "sentinel landed: $($s.Tool)" "expected file at $($s.Path)"
        continue
    }
    $content = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($s.Path))
    if ($content.StartsWith($s.ExpectedHead)) { Ok "sentinel landed: $($s.Tool) ($($s.ExpectedHead))" }
    else { Bad "sentinel landed: $($s.Tool)" "content mismatch (got: $($content.Substring(0,[Math]::Min(30,$content.Length))))" }
}

# Verify substitution worked: {{game_docs_root}} should be replaced with the project's value (Acme_Game/Docs).
$codexFile = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes((Join-Path $fx.Target '.Codex\skills\diagnose.md')))
if ($codexFile -match 'Acme_Game/Docs' -and $codexFile -notmatch '\{\{game_docs_root\}\}') {
    Ok 'substitution: {{game_docs_root}} resolved to installedProject.gameDocsRoot'
} else { Bad 'substitution' "codex sentinel content: $codexFile" }

# Run compare-with-package -- expect 0 conflicts (3 clean, 0 drift).
$r = Run $compare @('-TargetRoot',$fx.Target,'-PackageRoot',$fx.Pkg,'-Output','json')
if ($r.Code -eq 0 -and $r.Out -match '"conflictCount":\s*0') {
    Ok 'compare-with-package: clean (parity confirmed; phase 5 gate condition met)'
} else { Bad 'compare-with-package: parity' "code=$($r.Code) out=$($r.Out)" }

Remove-Item -Recurse -Force $fx.Root -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "=============================================================="
Write-Output "Newuser e2e tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
