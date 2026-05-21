# init-consumer.ps1 -- bootstrap a fresh consumer project from manifest-template.json
#
# Generates Docs/agents/scaffold-manifest.json for a new consumer based on the
# package's canonical manifest-template.json. Filters entries by selected
# -Overlays + -Tools, injects the consumer's installedProject block, resolves
# sourceCommit to the package's current git HEAD (or package-manifest.json).
#
# Idempotent guard: refuses to overwrite an existing manifest unless -Force.
#
# Exit codes:
#   0 : manifest written
#   1 : refused (manifest exists; pass -Force to overwrite)
#   2 : runtime failure (template not found, invalid args, etc.)
param(
    [Parameter(Mandatory=$true)]  [string] $TargetRoot,
    [Parameter(Mandatory=$false)] [string] $PackageRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [Parameter(Mandatory=$false)] [string] $ProjectName = '',
    [Parameter(Mandatory=$false)] [string] $DocsRoot    = 'Docs',
    [Parameter(Mandatory=$false)] [string] $GameDocsRoot = '',
    [ValidateSet('perforce','git','filesystem')]
    [string] $VersionControl = 'filesystem',
    [Parameter(Mandatory=$false)] [string] $Tools     = 'all',
    [Parameter(Mandatory=$false)] [string] $Overlays  = 'core',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = '0.1.0-init-consumer'

# --- Resolve params ---
if (-not (Test-Path -LiteralPath $TargetRoot)) {
    Write-Error "TargetRoot does not exist: $TargetRoot"
    exit 2
}
$TargetRoot = (Resolve-Path $TargetRoot).Path

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Split-Path $TargetRoot -Leaf
}
if ([string]::IsNullOrWhiteSpace($GameDocsRoot)) {
    $GameDocsRoot = "$ProjectName/Docs"
}

$TemplatePath = Join-Path $PackageRoot 'manifest-template.json'
if (-not (Test-Path -LiteralPath $TemplatePath)) {
    Write-Error "manifest-template.json not found at $TemplatePath"
    exit 2
}

$ManifestPath = Join-Path $TargetRoot 'Docs\agents\scaffold-manifest.json'
if ((Test-Path -LiteralPath $ManifestPath) -and -not $Force) {
    Write-Error @"
Manifest already exists at:
  $ManifestPath

Refusing to overwrite. To replace it, pass -Force (existing manifest will be
overwritten without backup).

If you just want to update the package SHA or refresh the entries, use
compare-with-package.ps1 + install.ps1 instead.
"@
    exit 1
}

# --- Load template ---
$tplRaw = Get-Content -Raw $TemplatePath
$tpl    = $tplRaw | ConvertFrom-Json

# --- Resolve package sourceCommit ---
# Prefer the package repo's git HEAD; fall back to package-manifest.json.
$pkgSha = $null
try {
    Push-Location $PackageRoot
    $pkgSha = & git rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0) { $pkgSha = $null }
} catch { $pkgSha = $null } finally { Pop-Location }

if (-not $pkgSha) {
    $pkgManPath = Join-Path $PackageRoot 'package-manifest.json'
    if (Test-Path -LiteralPath $pkgManPath) {
        $pkgMan = Get-Content -Raw $pkgManPath | ConvertFrom-Json
        if ($pkgMan.package.PSObject.Properties.Match('sourceCommit').Count -gt 0) {
            $pkgSha = $pkgMan.package.sourceCommit
        }
    }
}
if (-not $pkgSha) { $pkgSha = 'unknown' }

# --- Resolve tool / overlay selection ---
$selectedTools = if ($Tools -eq 'all') { @('codex','claude','opencode','common') }
                 else { @(($Tools -split ',') | ForEach-Object { $_.Trim().ToLower() }) }
$selectedOverlays = @(($Overlays -split ',') | ForEach-Object { $_.Trim().ToLower() })

# Legacy alias: 'ue-perforce' (v1.0.0 - v1.1.0) expands to 'perforce' + 'ue'.
if ($selectedOverlays -contains 'ue-perforce') {
    $selectedOverlays = @($selectedOverlays | Where-Object { $_ -ne 'ue-perforce' })
    if ($selectedOverlays -notcontains 'perforce') { $selectedOverlays += 'perforce' }
    if ($selectedOverlays -notcontains 'ue')       { $selectedOverlays += 'ue' }
}

# tool-capability is implicit metadata; always include.
if ($selectedOverlays -notcontains 'tool-capability') {
    $selectedOverlays += 'tool-capability'
}

# --- Filter entries ---
$filtered = @()
foreach ($e in $tpl.files) {
    $tool = if ($e.tool) { $e.tool.ToLower() } else { 'common' }
    $overlay = if ($e.ownerOverlay) { $e.ownerOverlay.ToLower() } else { 'core' }

    # localOnly entries are tool-specific local state; keep if their tool is selected.
    if ($e.localOnly) {
        if ($selectedTools -contains $tool) { $filtered += ,$e }
        continue
    }

    # Owner = package (core) entries: always keep if tool selected.
    if ($e.owner -eq 'package') {
        if ($selectedTools -contains $tool -or $tool -eq 'common') { $filtered += ,$e }
        continue
    }

    # Owner = overlay entries: keep if overlay selected AND tool selected.
    if ($e.owner -eq 'overlay') {
        if (($selectedOverlays -contains $overlay) -and
            ($selectedTools -contains $tool -or $tool -eq 'common')) {
            $filtered += ,$e
        }
        continue
    }
}

# --- Inject sourceCommit into entries ---
foreach ($e in $filtered) {
    if ($e.sourceCommit -eq '<resolved-by-init-consumer>') {
        $e.sourceCommit = $pkgSha
    }
    # Re-add stripped fields with null defaults so install.ps1 can populate.
    $e | Add-Member -NotePropertyName 'contentHash'       -NotePropertyValue $null -Force
    $e | Add-Member -NotePropertyName 'blockHash'         -NotePropertyValue $null -Force
    $e | Add-Member -NotePropertyName 'depotRevision'     -NotePropertyValue $null -Force
    $e | Add-Member -NotePropertyName 'pendingChangelist' -NotePropertyValue $null -Force
    $e | Add-Member -NotePropertyName 'lastCheckedAt'     -NotePropertyValue $null -Force
    $e | Add-Member -NotePropertyName 'conflictReport'    -NotePropertyValue $null -Force
}

# --- Build output manifest ---
$installedProject = [pscustomobject]@{
    name            = $ProjectName
    versionControl  = $VersionControl
    docsRoot        = $DocsRoot
    gameDocsRoot    = $GameDocsRoot
}

$out = [pscustomobject]@{
    schemaVersion    = 3
    package          = $tpl.package
    installer        = [pscustomobject]@{
        version     = $ScriptVersion
        lastRunAt   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss+00:00")
        lastRunMode = 'init-consumer-bootstrap'
    }
    installedProject = $installedProject
    tools            = $tpl.tools
    overlays         = $tpl.overlays
    upstreams        = $tpl.upstreams
    toolCapabilities = $tpl.toolCapabilities
    conflictReports  = @()
    files            = $filtered
    notes            = @(
        "Bootstrap manifest generated by init-consumer.ps1 v$ScriptVersion.",
        "Selected tools: $($selectedTools -join ', ')",
        "Selected overlays: $($selectedOverlays -join ', ')",
        "Package SHA at bootstrap: $pkgSha",
        "Run install.ps1 -Mode DryRun next to preview installation; -Mode Write to apply."
    )
}

# --- Marker stubs for generated-block / append-fragment entries ---
# install.ps1 requires existing markers in the target before it can inject a
# block. For a fresh consumer, no such files exist yet -- create minimal stubs.
# Do not overwrite existing files. Pre-populate blockHash with the sha of the
# empty block so preflight check 2 passes; install.ps1 updates on first write.
$stubsCreated = @()
foreach ($e in $filtered) {
    if ($e.mergeStrategy -notin @('generated-block','append-fragment')) { continue }
    $targetFile = Join-Path $TargetRoot $e.path
    if (Test-Path -LiteralPath $targetFile) { continue }

    $parent = Split-Path $targetFile -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $blockId = if ($e.PSObject.Properties.Match('generatedBlockId').Count -gt 0 -and $e.generatedBlockId) {
                   $e.generatedBlockId
               } elseif ($e.PSObject.Properties.Match('appendFragmentId').Count -gt 0 -and $e.appendFragmentId) {
                   $e.appendFragmentId
               } else { 'agentic-block' }

    $fileName = Split-Path $targetFile -Leaf
    $ext = [IO.Path]::GetExtension($fileName).ToLowerInvariant()
    $isHash = ($fileName -ieq '.p4ignore') -or ($ext -eq '' -and $fileName -notlike '*.*') -or ($ext -ne '.md')

    if ($isHash) {
        $body = @(
            "# $fileName -- project-specific entries above this line.",
            "# The block below is managed by myst-agentic-workflow's install.ps1.",
            "",
            "# AGENTIC-SCAFFOLD:BEGIN id=$blockId",
            "# AGENTIC-SCAFFOLD:END id=$blockId",
            ""
        ) -join "`n"
    } else {
        $body = @(
            "# $ProjectName",
            "",
            "Project-authored content above; agentic-scaffold-managed block below.",
            "Edit freely outside the markers; the block is rewritten by install.ps1.",
            "",
            "<!-- AGENTIC-SCAFFOLD:BEGIN id=$blockId -->",
            "<!-- AGENTIC-SCAFFOLD:END id=$blockId -->",
            ""
        ) -join "`n"
    }

    [IO.File]::WriteAllText($targetFile, $body, [Text.Encoding]::UTF8)
    $stubsCreated += $e.path

    # sha256 of the empty block content (inner bytes between BEGIN and END
    # markers, exclusive). Lets preflight check 2 pass on these stubs --
    # install.ps1 will rewrite the block and update the hash on first run.
    $emptyBlockSha = 'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
    $e | Add-Member -NotePropertyName 'blockHash' -NotePropertyValue $emptyBlockSha -Force
}

# --- Ensure target directory + write manifest ---
$manifestDir = Split-Path $ManifestPath -Parent
if (-not (Test-Path -LiteralPath $manifestDir)) {
    New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
}

$json = $out | ConvertTo-Json -Depth 20
[IO.File]::WriteAllText($ManifestPath, $json, [Text.Encoding]::UTF8)

# --- Report ---
Write-Output "=============================================================="
Write-Output "init-consumer.ps1  v$ScriptVersion"
Write-Output "Target  : $TargetRoot"
Write-Output "Package : $PackageRoot  (SHA $($pkgSha.Substring(0,[Math]::Min(8,$pkgSha.Length))))"
Write-Output "Project : $ProjectName  ($VersionControl)"
Write-Output "DocsRoot: $DocsRoot     GameDocsRoot: $GameDocsRoot"
Write-Output "Tools   : $($selectedTools -join ', ')"
Write-Output "Overlays: $($selectedOverlays -join ', ')"
Write-Output "=============================================================="
Write-Output "Wrote bootstrap manifest with $($filtered.Count) entries:"
Write-Output "  $ManifestPath"
if ($stubsCreated.Count -gt 0) {
    Write-Output ""
    Write-Output "Created $($stubsCreated.Count) marker stub file(s) for generated-block / append-fragment:"
    foreach ($p in $stubsCreated) { Write-Output "  $p" }
}
Write-Output ""
Write-Output "Next: install.ps1 -TargetRoot '$TargetRoot' -PackageRoot '$PackageRoot' -Mode DryRun"
Write-Output "(then -Mode Write when the dry-run looks right)"
exit 0
