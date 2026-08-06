<#
.SYNOPSIS
    Assert the plugin's cross-tool capability contract against the package tree.

.DESCRIPTION
    myst-dev-kit ships one tree and two manifests. The loaders differ, so the two tools
    do not receive the same capabilities -- deliberately. docs/tool-capability-matrix.md
    is the record of which; this script asserts that record against what is on disk.

    WHAT IT PROVES -- AND WHAT IT DOES NOT
      It checks declarations and files: every capability directory has a matrix row, the
      manifests declare what the matrix says they declare, and neither description promises
      a capability its own tool cannot run. It CANNOT verify runtime behaviour in either
      host -- that is what the matrix's evidence column is for, and why 'unverified' rows
      exist. A green run means "the contract is internally consistent", never "both tools
      behave identically".

      This is the same distinction check-rule-parity.sh draws for rules: it proves the
      counterpart exists, not that it is good.

.PARAMETER PackageRoot
    Package root. Defaults to the parent of this script's directory.

.PARAMETER Advisory
    Report findings and always exit 0. For use in a pre-commit or CI reporting step.

.EXAMPLE
    ./scripts/check-plugin-parity.ps1
    ./scripts/check-plugin-parity.ps1 -Advisory
#>
[CmdletBinding()]
param(
    [string]$PackageRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Advisory
)

$ErrorActionPreference = 'Stop'
$findings = @()

$plugin   = Join-Path $PackageRoot 'plugins/myst-dev-kit'
$matrixMd = Join-Path $PackageRoot 'docs/tool-capability-matrix.md'
$claudeMf = Join-Path $plugin '.claude-plugin/plugin.json'
$codexMf  = Join-Path $plugin '.codex-plugin/plugin.json'

foreach ($p in @($matrixMd, $claudeMf, $codexMf)) {
    if (-not (Test-Path $p)) {
        Write-Host "Plugin parity: missing $p - nothing to check."
        exit 0
    }
}

$matrix = Get-Content $matrixMd -Raw
$claude = Get-Content $claudeMf -Raw | ConvertFrom-Json
$codex  = Get-Content $codexMf  -Raw | ConvertFrom-Json

# --- 1. every capability directory in the plugin has a matrix row -------------------
# A directory nobody wrote down is the failure this file exists to prevent: it reaches
# one tool, silently misses the other, and no one finds out until it matters.
$capDirs = Get-ChildItem -Path $plugin -Directory |
           Where-Object { $_.Name -notmatch '^\.' } |
           Select-Object -ExpandProperty Name

foreach ($d in $capDirs) {
    if ($matrix -notmatch [regex]::Escape("``$d/``")) {
        $findings += "capability directory '$d/' has no row in docs/tool-capability-matrix.md"
    }
}

# --- 2. the manifests declare what the matrix says they declare ---------------------
# Asymmetric declaration is correct (the loaders differ). Undocumented asymmetry is not.
if (-not $codex.PSObject.Properties.Name.Contains('skills')) {
    $findings += ".codex-plugin/plugin.json no longer declares 'skills' - Codex discovers nothing by convention"
}
if (-not $codex.PSObject.Properties.Name.Contains('hooks')) {
    $findings += ".codex-plugin/plugin.json no longer declares 'hooks' - the Submit-Audit bridge will not reach Codex"
}

# --- 3. no description promises a capability its own tool cannot run ----------------
# v4.25.0: the Codex description advertised both reviewer agents. Codex has no subagent
# mechanism, so they ship inert. A user reading it would never learn review-changes is
# the actual path.
$agentsDir = Join-Path $plugin 'agents'
if (Test-Path $agentsDir) {
    $agentNames = Get-ChildItem $agentsDir -Filter *.md |
                  ForEach-Object { $_.BaseName }
    foreach ($a in $agentNames) {
        if ($codex.description -match [regex]::Escape($a)) {
            # Naming an agent is only a defect if the description does not also say it is
            # Claude-only / point at the inline fallback.
            if ($codex.description -notmatch 'Claude-only' -and
                $codex.description -notmatch 'review-changes') {
                $findings += "Codex plugin description names agent '$a' without stating it is Claude-only or naming the inline fallback"
            }
        }
    }
    if ($claude.description -notmatch 'agent') {
        $findings += "Claude plugin description does not mention the reviewer agents, which are a Claude-only capability worth advertising"
    }
}

# --- 4. matrix and manifests agree on version-independent facts --------------------
if ($claude.name -ne $codex.name) {
    $findings += "plugin name differs between manifests: '$($claude.name)' vs '$($codex.name)'"
}
if ($claude.version -ne $codex.version) {
    $findings += "plugin version differs between manifests: '$($claude.version)' vs '$($codex.version)'"
}

# --- 5. the matrix Count column matches the tree ------------------------------------
# Section 1 only proves a ROW exists; a stale count (e.g. '30' skills surviving the v7.0.0
# removals) sailed through. Numeric Count cells are asserted against the number of entries
# in the capability directory; non-numeric cells (hooks/ says '1 entry') are skipped.
foreach ($line in ($matrix -split "`n")) {
    if ($line -match '^\|\s*`([A-Za-z0-9-]+)/`\s*\|\s*([^|]+)\|') {
        $capName  = $Matches[1]
        $countRaw = $Matches[2].Trim()
        if ($countRaw -notmatch '^\d+$') { continue }   # tolerate prose cells like '1 entry'
        $capPath = Join-Path $plugin $capName
        if (-not (Test-Path $capPath)) { continue }     # missing dirs are section 1's finding
        $actual = @(Get-ChildItem -Path $capPath).Count
        if ($actual -ne [int]$countRaw) {
            $findings += "matrix Count for '$capName/' says $countRaw but the tree has $actual entries"
        }
    }
}

# --- report -----------------------------------------------------------------------
if ($findings.Count -eq 0) {
    Write-Host "Plugin parity: OK - $($capDirs.Count) capability dir(s) documented, manifests consistent."
    Write-Host "  (Declarations and files only. Runtime behaviour is the matrix's evidence column;"
    Write-Host "   rows marked 'unverified' have never been run in the live host.)"
    exit 0
}

Write-Host "Plugin parity: $($findings.Count) finding(s):"
foreach ($f in $findings) { Write-Host "  - $f" }
Write-Host ""
Write-Host "  See docs/tool-capability-matrix.md for the contract these assert."

if ($Advisory) { exit 0 }
exit 1
