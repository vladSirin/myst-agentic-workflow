# check-mattpocock-updates.ps1 — myst-agentic-workflow upstream checker (skeleton phase)
# Compares pinned mattpocock/skills commit against remote HEAD. Read-only.
param(
    [Parameter(Mandatory=$false)] [string] $Repo = "https://github.com/mattpocock/skills",
    [Parameter(Mandatory=$false)] [string] $Branch = "main",
    [Parameter(Mandatory=$false)] [string] $PinnedCommit = "e74f0061bb67222181640effa98c675bdb2fdaa7"
)

$ErrorActionPreference = 'Stop'
$ScriptVersion = "0.1.0-skeleton"

Write-Output "=============================================================="
Write-Output "check-mattpocock-updates.ps1  v$ScriptVersion"
Write-Output "Repository: $Repo  |  Branch: $Branch"
Write-Output "Pinned commit: $PinnedCommit"
Write-Output "=============================================================="

# Fetch remote HEAD via git ls-remote (read-only, no clone)
$remoteHead = $null
try {
    $remoteRef = git ls-remote $Repo "refs/heads/$Branch" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Output "WARNING: git ls-remote failed. Is git installed and available in PATH?"
        Write-Output "Error: $remoteRef"
        $remoteHead = "unreachable"
        $upstreamChangedFiles = @("unreachable")
    } else {
        $remoteHead = ($remoteRef -split "\s+")[0]
        $upstreamChangedFiles = @()
        if ($remoteHead -ne $PinnedCommit) {
            Write-Output ""
            Write-Output "Remote HEAD ($remoteHead) differs from pinned commit ($PinnedCommit)."
            Write-Output "Upstream has changed. Use git diff between the two commits to enumerate"
            Write-Output "changed files. This check does not clone the repo (read-only)."
            Write-Output ""
            Write-Output "To list changed files (requires a local clone):"
            Write-Output "  git clone $Repo && cd skills"
            Write-Output "  git diff --name-only $PinnedCommit $remoteHead"
        } else {
            Write-Output "Pinned commit matches remote HEAD. No upstream changes."
        }
    }
} catch {
    Write-Output "WARNING: Could not contact $Repo"
    Write-Output "Error: $_"
    $remoteHead = "unreachable"
    $upstreamChangedFiles = @("unreachable")
}

# --- Rejection memory (content-hash-keyed, not commit-SHA-keyed) ---
$rejectLogPath = Join-Path $PSScriptRoot "..\.scratch\agentic-scaffold-rejected-upstream.json"
$rejectedHunks = @{}
if (Test-Path $rejectLogPath) {
    $rejected = Get-Content $rejectLogPath | ConvertFrom-Json
    foreach ($r in $rejected) {
        if ($r.hunkContentHash) {
            $rejectedHunks[$r.hunkContentHash] = $r
        }
    }
    Write-Output "Rejection memory loaded: $($rejectedHunks.Count) previously-rejected hunks"
}

# --- Output ---
Write-Output ""
Write-Output "=============================================================="
Write-Output "SUMMARY"
Write-Output "=============================================================="
Write-Output "  Tracked branch          : $Branch"
Write-Output "  Pinned commit           : $PinnedCommit"
Write-Output "  Current remote HEAD     : $remoteHead"
$changedDisplay = if ($upstreamChangedFiles.Count -eq 1 -and $upstreamChangedFiles[0] -eq 'unreachable') { 'not available (no git or no network)' } else { $upstreamChangedFiles.Count }
Write-Output "  Changed upstream files  : $changedDisplay"
Write-Output ""

if ($remoteHead -eq $PinnedCommit) {
    Write-Output "Decision: no action required. Upstream is at the pinned commit."
} elseif ($remoteHead -eq "unreachable") {
    Write-Output "Decision: needs-human-review. Remote is unreachable."
    Write-Output "  Verify network connectivity and git availability."
    Write-Output "  This is expected in skeleton phase if git is not installed locally."
} else {
    Write-Output "Decision: needs-human-review."
    Write-Output "  Classification workflow:"
    Write-Output "    1. Clone $Repo"
    Write-Output "    2. git diff --name-only $PinnedCommit $remoteHead"
    Write-Output "    3. For each changed file, classify: adopt | adapt | reject"
    Write-Output "    4. Rejected changes: record hunk content hash in rejection memory"
    Write-Output "       so previously-rejected hunks are auto-classified on next run."
    Write-Output "    5. Update pinned commit in manifest to $remoteHead after curation."
}

Write-Output ""
Write-Output "Note: This script is read-only. No files are modified."
Write-Output "      Provenance tracking requires real package commits (currently pending-package)."
