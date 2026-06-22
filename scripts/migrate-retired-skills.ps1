# migrate-retired-skills.ps1 — remove skills retired/renamed by the upstream convergence (v2.5.0–v2.11.x)
#
# The installer adds/updates manifest entries but does NOT delete files removed from the
# manifest. When upgrading an OLD consumer install, the retired skills linger as orphans —
# and in Perforce write-mode, preflight check 5 ("no unmanaged scaffold files") will BLOCK
# the upgrade until they're gone. Run this once before/with the upgrade.
#
# Retired: zoom-out, caveman, write-a-skill (removed) and diagnose (renamed -> diagnosing-bugs).
#
# DRY-RUN by default (lists what it would remove). Use -Apply to act.
#   Filesystem consumers: -Apply removes the files.
#   Perforce consumers:   pass -UsePerforce; the script EMITS `p4 delete` commands for you to
#                         run inside a named changelist (it does not touch Perforce itself).
param(
    [Parameter(Mandatory=$true)]  [string] $TargetRoot,
    [Parameter(Mandatory=$false)] [switch] $Apply,
    [Parameter(Mandatory=$false)] [switch] $UsePerforce
)
$ErrorActionPreference = 'Stop'

$toolDirs = @('.claude', '.Codex', '.opencode')
$retiredSkills   = @('zoom-out', 'caveman', 'write-a-skill', 'diagnose')   # diagnose -> diagnosing-bugs
$retiredCommands = @('caveman.md', 'write-a-skill.md')                      # old command wrappers, if present

$found = New-Object System.Collections.Generic.List[object]
foreach ($td in $toolDirs) {
    foreach ($s in $retiredSkills) {
        $p = Join-Path $TargetRoot "$td/skills/$s"
        if (Test-Path -LiteralPath $p) { $found.Add([pscustomobject]@{ Path = ($p -replace '\\','/'); IsDir = $true }) }
    }
    foreach ($c in $retiredCommands) {
        $p = Join-Path $TargetRoot "$td/commands/$c"
        if (Test-Path -LiteralPath $p) { $found.Add([pscustomobject]@{ Path = ($p -replace '\\','/'); IsDir = $false }) }
    }
}

Write-Output "=============================================================="
Write-Output "migrate-retired-skills — target: $TargetRoot"
Write-Output "mode: $(if ($Apply) { 'APPLY' } else { 'DRY-RUN (no changes)' })$(if ($UsePerforce) { ' [Perforce]' })"
Write-Output "=============================================================="
if ($found.Count -eq 0) {
    Write-Output "No retired skills/commands found. Nothing to migrate — you're clean."
    exit 0
}
Write-Output "Retired items present ($($found.Count)):"
$found | ForEach-Object { Write-Output "  - $($_.Path)" }
Write-Output ""

if ($UsePerforce) {
    Write-Output "Perforce: run these in a named changelist (then submit), e.g. after 'p4 change -o':"
    foreach ($f in $found) {
        $arg = if ($f.IsDir) { "`"$($f.Path)/...`"" } else { "`"$($f.Path)`"" }
        Write-Output "  p4 delete -c <CL> $arg"
    }
    Write-Output ""
    Write-Output "This script does not modify Perforce. Copy the commands above, then run update.ps1."
    exit 0
}

if (-not $Apply) {
    Write-Output "DRY-RUN. Re-run with -Apply to remove these (filesystem), or -UsePerforce for p4 commands."
    exit 0
}
foreach ($f in $found) {
    Remove-Item -LiteralPath $f.Path -Recurse -Force
    Write-Output "removed: $($f.Path)"
}
Write-Output ""
Write-Output "Done. Now run update.ps1 to install the current skill set."
exit 0
