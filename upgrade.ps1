# upgrade.ps1 -- bring an EXISTING consumer up to the current package while
# preserving local customizations.
#
# Why this exists (setup.ps1 / update.ps1 can't do it):
#   - setup.ps1 skips manifest bootstrap when one already exists, and update.ps1
#     never regenerates the manifest -- both drive install.ps1 from the STALE
#     installed manifest, so NEW skills are never added and RETIRED skills are
#     re-created. install.ps1 -Mode Write is also gated by preflight check 2
#     (on-disk hash must equal manifest hash), which any local edit trips.
#
# What this does:
#   1. Regenerates the manifest from the current template (into a temp dir, so a
#      preview never touches the consumer) -- picks up new skills, drops retired.
#   2. Re-baselines every existing managed file's recorded hash to its ON-DISK
#      content, so preflight check 2 passes and install can edit/add cleanly.
#   3. Detects files you have CUSTOMIZED (on-disk differs from the OLD manifest
#      baseline) and marks them manual-only/human-owned -> install SKIPS them
#      (your work is preserved). Everything you did NOT touch is refreshed to the
#      current package version. New skills are added; retired skills are removed.
#   4. Perforce-aware: wraps the manifest edit, retired deletes, and install
#      writes in ONE reviewable changelist. Nothing is permanent until you submit.
#
# DRY-RUN by default (prints the plan, no changes). Use -Apply to execute.
param(
    [Parameter(Mandatory=$true)] [string] $TargetRoot,
    [string] $PackageRoot = '',
    [switch] $Apply,
    [switch] $Yes
)
$ErrorActionPreference = 'Stop'
$ScriptVersion = '0.1.0-upgrade'
# $PSScriptRoot is unreliable as a param default under `powershell.exe -File`; resolve here (cf. update.ps1).
if ([string]::IsNullOrWhiteSpace($PackageRoot)) { $PackageRoot = $PSScriptRoot }
$ScriptsDir = Join-Path $PackageRoot 'scripts'
. (Join-Path $ScriptsDir 'lib\Markers.ps1')   # Get-MarkerBlockHash

function Get-Hash([string]$p) {
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    $b = [IO.File]::ReadAllBytes([IO.Path]::GetFullPath($p))
    $s = [Security.Cryptography.SHA256]::Create()
    return "sha256:" + [BitConverter]::ToString($s.ComputeHash($b)).Replace('-','').ToLower()
}
function Read-Manifest([string]$p) {
    $b = [IO.File]::ReadAllBytes($p)
    if ($b.Length -ge 3 -and $b[0] -eq 0xEF) { $b = $b[3..($b.Length-1)] }
    return [Text.Encoding]::UTF8.GetString($b) | ConvertFrom-Json
}
function Write-Manifest($obj, [string]$p) {
    $json = $obj | ConvertTo-Json -Depth 100
    [IO.File]::WriteAllText($p, $json, (New-Object Text.UTF8Encoding($true)))  # BOM, matches init-consumer
}
function Prop($o, $n) { if ($o.PSObject.Properties.Match($n).Count -gt 0) { $o.$n } else { $null } }

# --- Resolve + read old manifest ---
if (-not (Test-Path -LiteralPath $TargetRoot)) { Write-Error "TargetRoot does not exist: $TargetRoot"; exit 2 }
$TargetRoot = (Resolve-Path $TargetRoot).Path
$manRel  = 'Docs\agents\scaffold-manifest.json'
$manPath = Join-Path $TargetRoot $manRel
if (-not (Test-Path -LiteralPath $manPath)) {
    Write-Error "No installed manifest at $manPath. This is not an existing consumer -- use setup.ps1 for a fresh install."
    exit 2
}
$old = Read-Manifest $manPath
$ProjectName  = Prop $old.installedProject 'name'
$VC           = Prop $old.installedProject 'versionControl'; if (-not $VC) { $VC = 'filesystem' }
$DocsRoot     = Prop $old.installedProject 'docsRoot';     if (-not $DocsRoot) { $DocsRoot = 'Docs' }
$GameDocsRoot = Prop $old.installedProject 'gameDocsRoot'; if (-not $GameDocsRoot) { $GameDocsRoot = 'Docs' }
$Tools    = @($old.files | ForEach-Object { $_.tool } | Where-Object { $_ -and $_ -ne 'common' } | Sort-Object -Unique) -join ','
$Overlays = @($old.overlays) -join ','
$oldHash = @{}; foreach ($e in $old.files) { if ($e.hashPolicy -eq 'sha256' -and $e.contentHash) { $oldHash[$e.path] = $e.contentHash } }

Write-Host "=============================================================="
Write-Host "myst-agentic-workflow upgrade.ps1  v$ScriptVersion"
Write-Host "=============================================================="
Write-Host ("Target         : {0}" -f $TargetRoot)
Write-Host ("From version   : {0}  (commit {1})" -f $old.package.version, ($old.package.sourceCommit.Substring(0,[Math]::Min(7,$old.package.sourceCommit.Length))))
Write-Host ("VersionControl : {0}" -f $VC)
Write-Host ("Tools/Overlays : {0}  |  {1}" -f $Tools, $Overlays)
Write-Host ("Mode           : {0}" -f $(if ($Apply) { 'APPLY' } else { 'DRY-RUN (preview only)' }))
Write-Host "=============================================================="

# --- Regenerate the new manifest into a temp dir (never touches the consumer) ---
$tmp = Join-Path $env:TEMP ('upg-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptsDir 'init-consumer.ps1') `
        -TargetRoot $tmp -PackageRoot $PackageRoot -ProjectName $ProjectName `
        -DocsRoot $DocsRoot -GameDocsRoot $GameDocsRoot -VersionControl $VC `
        -Tools $Tools -Overlays $Overlays -Force *> (Join-Path $tmp 'init.log')
    if ($LASTEXITCODE -ne 0) { Get-Content (Join-Path $tmp 'init.log') | Write-Host; Write-Error "init-consumer failed."; exit 2 }
    $new = Read-Manifest (Join-Path $tmp $manRel)
} finally { }

# --- Reconcile in memory: build the plan + the rewritten manifest ---
$add=@(); $refresh=@(); $preserve=@(); $blockRefresh=@(); $newPaths=@{}
foreach ($e in $new.files) {
    $newPaths[$e.path] = $true
    # Skip policies preflight check 2 also ignores (so no re-baseline needed).
    if ($e.localOnly -or $e.hashPolicy -eq 'self-excluded' -or $e.hashPolicy -eq 'runtime-mutable') { continue }
    $fp = Join-Path $TargetRoot $e.path
    $exists = Test-Path -LiteralPath $fp
    if ($e.hashPolicy -eq 'sha256') {
        if (-not $exists) {
            if ($e.mergeStrategy -ne 'manual-only') { $add += $e.path }   # new installable file -> ADD
            continue                                                       # manual-only absent: install won't create it
        }
        # Re-baseline EVERY on-disk sha256 entry (incl. manual-only, e.g. tool-capability
        # profiles with empty contentHash) so preflight check 2 passes.
        $disk = Get-Hash $fp
        $e.contentHash = $disk
        if ($e.mergeStrategy -eq 'manual-only') { $preserve += "$($e.path) (human-owned)"; continue }
        $base = $oldHash[$e.path]
        if ($base -and $disk -ne $base) {                                 # user customized -> PRESERVE
            $e.mergeStrategy  = 'manual-only'
            $e.writablePolicy = 'human-owned'
            $preserve += $e.path
        } else {
            $refresh += $e.path                                           # untouched -> install refreshes if package changed it
        }
    } elseif ($e.hashPolicy -eq 'block-scoped') {
        if (-not $exists) { continue }
        $id = Prop $e 'generatedBlockId'; if (-not $id) { $id = Prop $e 'appendFragmentId' }
        try { $e.blockHash = Get-MarkerBlockHash -Path $fp -Id $id; $blockRefresh += $e.path }
        catch { $e.mergeStrategy = 'manual-only'; $preserve += "$($e.path) (block markers absent)" }
    }
}
# Retired = old package/overlay files no longer in the new manifest, still on disk
$retired=@(); $orphanCustom=@()
foreach ($e in $old.files) {
    if ($e.owner -notin @('package','overlay') -or $e.localOnly -or $newPaths[$e.path]) { continue }
    $fp = Join-Path $TargetRoot $e.path
    if (-not (Test-Path -LiteralPath $fp)) { continue }
    $base = $oldHash[$e.path]; $disk = Get-Hash $fp
    if ($base -and $disk -ne $base) { $orphanCustom += $e.path }          # customized retired file -> keep + warn
    else { $retired += $e.path }
}
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

# --- Report the plan ---
function Show($title, $items) {
    Write-Host ""
    Write-Host ("{0}: {1}" -f $title, @($items).Count)
    @($items) | Sort-Object | ForEach-Object { Write-Host "    $_" }
}
Show "ADD (new from package)"          $add
Show "REFRESH (untouched -> package)"  $refresh
Show "PRESERVE (your customizations)"  $preserve
Show "BLOCK-REFRESH (managed block)"   $blockRefresh
Show "REMOVE (retired)"                $retired
if ($orphanCustom.Count -gt 0) { Show "KEPT but RETIRED upstream (you customized; review)" $orphanCustom }

Write-Host ""
Write-Host "=============================================================="
if (-not $Apply) {
    Write-Host "DRY-RUN complete. No changes made."
    Write-Host "Re-run with -Apply to execute$(if ($VC -eq 'perforce') { ' (wrapped in a Perforce changelist you review before submit)' })."
    Write-Host "=============================================================="
    exit 0
}
if (-not $Yes) {
    $reply = Read-Host "Apply the plan above? [y/N]"
    if ($reply -notmatch '^(y|yes)$') { Write-Host "Declined."; exit 1 }
}

# --- APPLY ---
$cl = $null
if ($VC -eq 'perforce') {
    $clTag = Prop $old.installedProject 'clTagPrefix'; if (-not $clTag) { $clTag = '[scaffold]' }
    $spec = & p4 change -o
    $desc = "$clTag Upgrade agentic scaffold to current package`n`n## What`n- upgrade.ps1 v${ScriptVersion}: +$($add.Count) new, ~$($refresh.Count) refreshed, $($preserve.Count) preserved, -$($retired.Count) retired.`n`n## Notes`n- Generated by upgrade.ps1. Review the diff before submit; 'p4 revert -c <CL> //...' to abort."
    $created = ($spec -replace '<enter description here>', ($desc -replace "`n","`n`t")) | & p4 change -i
    if ($created -match 'Change (\d+) created') { $cl = $Matches[1] } else { Write-Error "failed to create CL: $created"; exit 2 }
    Write-Host "Created changelist $cl."
    & p4 edit -c $cl $manPath | Out-Null
}
Write-Manifest $new $manPath
Write-Host "Manifest regenerated + reconciled (preserving $($preserve.Count) customized file(s))."

$prunedDirs = @{}
foreach ($r in $retired) {
    $rp = Join-Path $TargetRoot $r
    if ($VC -eq 'perforce') { & p4 delete -c $cl $rp | Out-Null }
    else { Remove-Item -LiteralPath $rp -Force -ErrorAction SilentlyContinue }
    $prunedDirs[(Split-Path -Parent $rp)] = $true
}
# Prune now-empty skill/command dirs left behind (harmless for Perforce; dirs aren't depot-tracked).
foreach ($d in @($prunedDirs.Keys)) {
    if ((Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue)) {
        Remove-Item -LiteralPath $d -Force -ErrorAction SilentlyContinue
    }
}
if ($retired.Count -gt 0) { Write-Host "Removed $($retired.Count) retired file(s)." }

$instArgs = @('-TargetRoot', $TargetRoot, '-PackageRoot', $PackageRoot, '-Tools', $Tools, '-Overlays', $Overlays, '-Mode', 'Write')
if ($VC -eq 'perforce') { $instArgs += @('-UsePerforce', '-Changelist', $cl) }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptsDir 'install.ps1') @instArgs
if ($LASTEXITCODE -ne 0) { Write-Error "install.ps1 failed (exit $LASTEXITCODE). $(if ($cl) { "Review/abort CL $cl (p4 revert -c $cl //...)." })"; exit 2 }

Write-Host ""
Write-Host "=============================================================="
Write-Host "Upgrade complete."
if ($VC -eq 'perforce') { Write-Host "Review changelist $cl, then 'p4 submit -c $cl' (or 'p4 revert -c $cl //...' to abort)." }
else { Write-Host "Review the working-tree changes, then commit." }
Write-Host "=============================================================="
exit 0
