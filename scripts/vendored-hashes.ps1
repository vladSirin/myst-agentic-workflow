# vendored-hashes.ps1 -- prove "verbatim except the recorded remaps" mechanically.
#
# WHY THIS EXISTS. ADR-0002/0006 say vendored skills stay byte-faithful to a pinned upstream
# commit, and that every divergence is written down. Until v4.43.0 that was prose: nothing
# failed if a vendored file quietly drifted. run-provenance-tests.ps1 cannot cover it (it walks
# manifest entries, and plugin skills are not manifest-tracked -- see that script's header).
#
# TWO MODES
#   -Verify (default)  every vendored file's hash matches vendored-hashes.json. Fails on drift.
#   -Update            regenerate vendored-hashes.json from the working tree, but REFUSE to
#                      record any file that differs from upstream unless its path is already
#                      listed in the ledger's divergences. That refusal is the teeth: you cannot
#                      silently regenerate a divergence away, and a new one has to be declared.
#
# HASHING. Reuses Get-NormalizedContentHash (scripts/lib/Markers.ps1) -- EOL/BOM-invariant.
# A naive Get-FileHash/git-hash-object scheme false-reports drift on any clone whose autocrlf
# differs; this repo already shipped that bug twice (v4.8.0 and its BLOCKING follow-up).
[CmdletBinding()]
param(
    [switch] $Update,
    [switch] $Verify,
    [switch] $AllowLocalAddition
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\Markers.ps1"
. "$PSScriptRoot\lib\SkillRoster.ps1"

# -Update is pinned to PowerShell 7+. Not a portability oversight: 5.1 and 7 ship different
# ConvertTo-Json formatters (5.1 indents deeper, double-spaces after the colon, and escapes
# `>` as >), so regenerating on the other engine rewrites all ~279 lines with no semantic
# change and two maintainers would ping-pong the whole file. Encoding is not the issue -- the
# writer below is already LF/no-BOM on both. -Verify stays 5.1-compatible, which is what
# matters: CI and the release checklist only ever verify.
if ($Update -and $PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "[ABORT] -Update requires PowerShell 7+ (this is $($PSVersionTable.PSVersion))." -ForegroundColor Red
    Write-Host "        5.1's ConvertTo-Json formats differently and would rewrite the whole ledger." -ForegroundColor Red
    Write-Host "        Run: pwsh scripts/vendored-hashes.ps1 -Update    (-Verify works on 5.1)" -ForegroundColor Red
    exit 2
}

$pkg       = (Resolve-Path "$PSScriptRoot\..").Path
$hashFile  = Join-Path $pkg 'vendored-hashes.json'
$skillsDir = Join-Path $pkg 'plugins\myst-dev-kit\skills'
if (-not $Update) { $Verify = $true }

# Upstream layout: skills/<category>/<name>/. Ours flattens to skills/<name>/.
$categories = @('engineering', 'productivity', 'misc', 'in-progress')

function Get-UpstreamHash {
    param([string] $Rev, [string] $UpstreamPath)
    # cmd redirect is byte-exact; PowerShell's pipeline would mangle the trailing newline.
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        cmd /c "git show `"$Rev`:$UpstreamPath`" > `"$tmp`" 2>nul" | Out-Null
        if ($LASTEXITCODE -ne 0 -or (Get-Item $tmp).Length -eq 0) { return $null }
        return Get-NormalizedContentHash -Path $tmp
    } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

function Find-UpstreamPath {
    param([string] $Rev, [string] $Relative)   # e.g. "grilling/SKILL.md"
    foreach ($c in $categories) {
        $candidate = "skills/$c/$Relative"
        cmd /c "git cat-file -e `"$Rev`:$candidate`" 2>nul" | Out-Null
        if ($LASTEXITCODE -eq 0) { return $candidate }
    }
    return $null
}

$existing = if (Test-Path $hashFile) { Get-Content $hashFile -Raw | ConvertFrom-Json } else { $null }
$pin = if ($existing) { $existing.pinnedCommit } else { (& git rev-parse upstream/main).Trim() }

# Paths allowed to differ from upstream, each with the reason. Adding to this list is a
# divergence decision: ADR-0006 requires a rationale, a reviewer pass and owner confirmation.
$declaredDivergences = if ($existing -and $existing.divergences) {
    $existing.divergences
} else {
    @(
        [ordered]@{ path = 'tdd/SKILL.md';        line = 38;      reason = 'ref remap: `code-review` -> `review-changes` (we do not vendor code-review)' }
        [ordered]@{ path = 'implement/SKILL.md';  line = 13;      reason = 'ref remap: /code-review -> /review-changes (unremapped it RESOLVES to the git-diff review plugin)' }
        [ordered]@{ path = 'to-spec/SKILL.md';    line = 9;       reason = 'ref remap: /setup-matt-pocock-skills -> /setup-agentic-workflow' }
        [ordered]@{ path = 'to-tickets/SKILL.md'; line = '11,60'; reason = 'ref remap: /setup-matt-pocock-skills -> /setup-agentic-workflow' }
        [ordered]@{ path = 'triage/SKILL.md';     line = 43;      reason = 'ref remap: /setup-matt-pocock-skills -> /setup-agentic-workflow' }
        [ordered]@{ path = 'wayfinder/SKILL.md';  line = 25;      reason = 'ref remap: /setup-matt-pocock-skills -> /setup-agentic-workflow' }
    )
}
$divergentPaths = @($declaredDivergences | ForEach-Object { $_.path })

# Local-origin skills are ours; they are not vendored and carry no upstream hash.
# ONE source of truth, shared with run-provenance-tests.ps1: a skill listed in one script
# and not the other silently mis-scopes this sweep (it would fall through to the
# local-addition branch below instead of being hashed).
$localOrigin = Get-LocalOriginSkills

$pass = 0; $fail = 0; $records = @()
$skillDirs = Get-ChildItem $skillsDir -Directory | Where-Object { $localOrigin -notcontains $_.Name }

foreach ($dir in $skillDirs) {
    $files = Get-ChildItem $dir.FullName -File -Recurse
    foreach ($f in $files) {
        $rel      = $f.FullName.Substring($skillsDir.Length + 1) -replace '\\', '/'
        $ourHash  = Get-NormalizedContentHash -Path $f.FullName
        $isDiverg = $divergentPaths -contains $rel

        if ($Update) {
            $up = Find-UpstreamPath -Rev $pin -Relative $rel
            if (-not $up) {
                if (-not $AllowLocalAddition) {
                    Write-Host "[REFUSE] $rel has no counterpart at the pinned upstream." -ForegroundColor Red
                    Write-Host "         A renamed skill dir launders content past this gate, so this is refused, not warned." -ForegroundColor Red
                    Write-Host "         If it is genuinely local, re-run with -AllowLocalAddition (and say so in the ledger)." -ForegroundColor Red
                    $fail++
                    continue
                }
                Write-Host "[WARN] no upstream file for $rel (recorded as a local addition)" -ForegroundColor Yellow
                $records += [ordered]@{ path = $rel; hash = $ourHash; upstream = $null }
                continue
            }
            $upHash = Get-UpstreamHash -Rev $pin -UpstreamPath $up
            if ($upHash -ne $ourHash -and -not $isDiverg) {
                Write-Host "[REFUSE] $rel differs from upstream and is NOT a declared divergence." -ForegroundColor Red
                Write-Host "         Declare it in the ledger (ADR-0006: rationale + reviewer + owner) or restore verbatim." -ForegroundColor Red
                $fail++
                continue
            }
            $records += [ordered]@{ path = $rel; hash = $ourHash; upstream = $up; divergent = $isDiverg }
        } else {
            $rec = $existing.files | Where-Object { $_.path -eq $rel }
            if (-not $rec)                { Write-Host "[FAIL] $rel is not recorded in vendored-hashes.json" -ForegroundColor Red; $fail++ }
            elseif ($rec.hash -ne $ourHash) { Write-Host "[FAIL] $rel drifted from its recorded hash" -ForegroundColor Red; $fail++ }
            else                          { $pass++ }
        }
    }
}

if ($Update) {
    if ($fail -gt 0) { Write-Host "`nRefused $fail undeclared divergence(s); vendored-hashes.json NOT written." -ForegroundColor Red; exit 1 }
    $out = [ordered]@{
        _comment      = 'EOL/BOM-invariant hashes of every vendored skill file. Regenerate with scripts/vendored-hashes.ps1 -Update; the generator refuses to record a file that differs from the pinned upstream unless it is declared below.'
        pinnedCommit  = $pin
        generatedFrom = 'upstream/main'
        divergences   = $declaredDivergences
        files         = $records
    }
    # Byte-stable across shells: PowerShell 5.1's -Encoding utf8 emits a BOM and 7's does not,
    # and both write CRLF -- so Set-Content here would make every regeneration a whole-file diff
    # on the other shell. A script whose whole point is EOL/BOM invariance must not write a
    # variant artifact. Same idiom as scripts/lib/P4Spec.ps1.
    $json = ($out | ConvertTo-Json -Depth 6) -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($hashFile, $json + "`n", [System.Text.UTF8Encoding]::new($false))
    Write-Host "Wrote $hashFile -- $($records.Count) file(s), $($declaredDivergences.Count) declared divergence(s)." -ForegroundColor Green
    exit 0
}

# Verify mode. The loop above walks the DISK ("is each file recorded?"); this walks the
# LEDGER ("is each recorded file still there?"). Without it, deleting a vendored file just
# lowers the check count and still prints [PASS] -- measured, and a dropped file is a
# divergence class ADR-0006 names outright.
foreach ($rec in $existing.files) {
    if (-not (Test-Path (Join-Path $skillsDir ($rec.path -replace '/', '\')))) {
        Write-Host "[FAIL] $($rec.path) is recorded but missing from the tree (dropped without declaration)" -ForegroundColor Red
        $fail++
    } else { $pass++ }
}

# Also confirm every declared divergence still corresponds to a real file.
foreach ($d in $declaredDivergences) {
    if (-not (Test-Path (Join-Path $skillsDir ($d.path -replace '/', '\')))) {
        Write-Host "[FAIL] declared divergence $($d.path) no longer exists (stale ledger entry)" -ForegroundColor Red; $fail++
    } else { $pass++ }
}
Write-Host ""
if ($fail -eq 0) { Write-Host "[PASS] $pass check(s): every vendored file matches its recorded hash." -ForegroundColor Green; exit 0 }
Write-Host "[FAIL] $fail problem(s), $pass ok." -ForegroundColor Red; exit 1
