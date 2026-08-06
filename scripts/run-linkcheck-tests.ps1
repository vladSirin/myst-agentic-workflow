# run-linkcheck-tests.ps1 -- intra-package link-existence lint (ADR-0002 principle #4)
#
# Enforces "completeness is part of faithful - no dangling references": every
# relative markdown link from a skill/workflow/command file to a package file
# (a companion like CONTEXT-FORMAT.md / AGENT-BRIEF.md / scripts/*.sh, or a
# sibling workflow) must resolve to a file that actually ships in the package.
#
# Consumer artifacts (CONTEXT.md, docs/adr/*, Docs/*, .scratch/*, /src/*,
# {{var}} paths) are NOT package files -- the agent creates them in the
# consumer repo -- so they are skipped.
#
# Known, not-yet-reconciled drifts live in $allow (keyed tool-agnostically so a
# single entry covers claude/codex). Each entry shrinks the backlog;
# remove it when the drift is fixed. A reference that is neither resolvable nor
# allow-listed fails the suite.
#
# Exit codes:  0 = all links resolve (or are allow-listed)  |  1 = dangling ref
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
$pass = 0; $fail = 0
function Ok($n)        { $script:pass++ }
function Bad($n, $why) { Write-Host ("[FAIL] {0}: {1}" -f $n,$why); $script:fail++ }

# --- Allow-list: known dangling refs pending reconciliation (ADR-0002 drifts) ---
# Key: "<tool-agnostic-source>|<rawTarget>".  Value: reason.
# EMPTY as of the v7.0.0 sweep: the workflows/AgenticWorkflow.md-era cross-overlay
# entries matched nothing on the current tree (those workflow files became plugin
# skills) and were pruned. Add entries ONLY for a known, accepted drift, with a
# reason; each entry is debt.
$allow = @{}

# Consumer artifacts (created in the consumer repo, never shipped) -> skip
function Test-ConsumerArtifact([string] $target) {
    if ($target -match '\{\{') { return $true }                     # {{var}} placeholder
    $b = [IO.Path]::GetFileName($target)
    if ($b -in @('CONTEXT.md','CONTEXT-MAP.md','AGENTS.md','CLAUDE.md')) { return $true }
    if ($target -match '(^|/)docs/adr/') { return $true }
    if ($target -match '(^|/)src/') { return $true }
    if ($target -match '(^|/)\.scratch/') { return $true }
    if ($target -match '(^|/)Docs/') { return $true }               # install-space project docs
    return $false
}

function Get-ToolAgnosticSource([string] $relPath) {
    $r = $relPath -replace '\\','/'
    $r = $r -replace '^templates/[^/]+/\.[^/]+/',''
    $r = $r -replace '^overlays/[^/]+/\.[^/]+/',''
    return $r
}

$roots = @('templates','overlays','plugins') | ForEach-Object { Join-Path $pkg $_ }
$files = foreach ($root in $roots) {
    if (Test-Path $root) { Get-ChildItem -Path $root -Recurse -File -Filter '*.md' }
}

$linkRx = [regex]'\]\(([^)]+)\)'
foreach ($f in $files) {
    $rel = $f.FullName.Substring($pkg.Length).TrimStart('\','/').Replace('\','/')
    $src = Get-ToolAgnosticSource $rel
    $text = [IO.File]::ReadAllText($f.FullName)
    foreach ($m in $linkRx.Matches($text)) {
        $raw = $m.Groups[1].Value.Trim()
        $target = ($raw -split '#',2)[0].Trim()       # strip anchor
        if ([string]::IsNullOrWhiteSpace($target)) { continue }
        if ($target -match '^(https?:|mailto:|#)') { continue }
        if ($target -notmatch '\.(md|sh|ps1|txt|json|template\.[a-z]+)$') { continue }
        if (Test-ConsumerArtifact $target) { continue }
        # resolve relative to the file's directory
        $resolved = [IO.Path]::GetFullPath((Join-Path $f.DirectoryName $target))
        if (Test-Path -LiteralPath $resolved) { Ok "$src|$target"; continue }
        $key = "$src|$target"
        if ($allow.ContainsKey($key)) { Ok $key; continue }
        Bad "$rel" "dangling reference -> '$target' (resolved: $($resolved.Substring($pkg.Length)))"
    }
}

Write-Host ''
Write-Host '=============================================================='
Write-Host ("Link-check: {0} links resolve, {1} dangling | {2} allow-listed drifts pending" -f $pass, $fail, $allow.Count)
Write-Host '=============================================================='
if ($fail -gt 0) {
    Write-Host ''
    Write-Host 'A reference points at a package file that does not ship. Either add the'
    Write-Host 'file (faithful restore), re-point the link, or - if it is a known, accepted'
    Write-Host 'drift - add it to $allow with a reason. Consumer artifacts are auto-skipped.'
    exit 1
}
exit 0
