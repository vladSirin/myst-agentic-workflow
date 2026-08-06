# InstallJournal.ps1 - install crash/recovery model (plan v1.6 lines 598-606)
#
# A killed or interrupted install must never leave a half-written scaffold
# with no recovery path. This module provides:
#   - an exclusive lock (concurrency guard, stale-lock reclaim)
#   - a staged write journal (temp + flush + atomic rename)
#   - a single commit point (the installed manifest update)
#   - incomplete-run detection + rollback (revert staged temps; p4 revert)
#
# The p4-revert action is injected so this module has zero Perforce coupling
# and the skeleton phase never touches a live depot.

Set-StrictMode -Version Latest

# ---- Exclusive lock --------------------------------------------------------
# Acquire before ANY validation or write. A second concurrent run must fail
# immediately (caller maps to exit 2). A stale lock (dead pid) is only
# reclaimable with -ReclaimStale.
function New-InstallLock {
    param(
        [Parameter(Mandatory)][string] $LockPath,
        [switch] $ReclaimStale
    )
    $dir = Split-Path -Parent $LockPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if (Test-Path -LiteralPath $LockPath) {
        $existing = $null
        try { $existing = Get-Content -Raw $LockPath | ConvertFrom-Json } catch { $existing = $null }
        $pid_ = if ($existing) { [int]$existing.pid } else { -1 }
        $alive = $false
        if ($pid_ -gt 0) {
            $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
            $alive = ($null -ne $proc)
        }
        if ($alive) {
            throw "LOCK-HELD: install already running (pid=$pid_, since=$($existing.startedAt)). Concurrent runs are not allowed."
        }
        if (-not $ReclaimStale) {
            throw "LOCK-STALE: a previous run did not release the lock (pid=$pid_). Re-run with -ReclaimStale to reclaim."
        }
        Remove-Item -LiteralPath $LockPath -Force
    }

    $info = [pscustomobject]@{
        pid       = $PID
        startedAt = (Get-Date).ToString('o')
        host      = $env:COMPUTERNAME
        cleanExit = $false
    }
    ($info | ConvertTo-Json -Compress) | Set-Content -LiteralPath $LockPath -Encoding UTF8
    return $LockPath
}

function Complete-InstallLock {
    # Mark a clean shutdown (distinguishes graceful end from a crash).
    param([Parameter(Mandatory)][string] $LockPath)
    if (Test-Path -LiteralPath $LockPath) {
        $i = Get-Content -Raw $LockPath | ConvertFrom-Json
        $i.cleanExit = $true
        ($i | ConvertTo-Json -Compress) | Set-Content -LiteralPath $LockPath -Encoding UTF8
    }
}

function Remove-InstallLock {
    param([Parameter(Mandatory)][string] $LockPath)
    if (Test-Path -LiteralPath $LockPath) { Remove-Item -LiteralPath $LockPath -Force }
}

# ---- Write journal ---------------------------------------------------------
function New-WriteJournal {
    param([Parameter(Mandatory)][string] $JournalPath)
    $dir = Split-Path -Parent $JournalPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $j = [pscustomobject]@{
        startedAt    = (Get-Date).ToString('o')
        stages       = @()     # @{ target; temp } pending atomic rename
        openedFiles  = @()     # files opened via p4 edit/add this run
        committed    = $false  # the single commit point (manifest updated)
    }
    ($j | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $JournalPath -Encoding UTF8
    return $JournalPath
}

# Stage one target: write content to a sibling temp, flush. Atomic rename is
# deferred to the commit phase so a crash mid-staging leaves the live file
# untouched.
function Add-JournalStage {
    param(
        [Parameter(Mandatory)][string] $JournalPath,
        [Parameter(Mandatory)][string] $Target,
        [Parameter(Mandatory)][AllowEmptyString()][string] $Content
    )
    $temp = "$Target.agentic-stage"
    # Ensure parent directory exists (fresh install case for nested target paths).
    $dir = Split-Path -Parent $Target
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($Content -replace "`r`n","`n"))
    $fs = [System.IO.File]::Open($temp, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    try { $fs.Write($bytes, 0, $bytes.Length); $fs.Flush($true) } finally { $fs.Dispose() }

    $j = Get-Content -Raw $JournalPath | ConvertFrom-Json
    $j.stages = @($j.stages) + @([pscustomobject]@{ target = $Target; temp = $temp })
    ($j | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $JournalPath -Encoding UTF8
}

function Register-OpenedFile {
    param([Parameter(Mandatory)][string] $JournalPath, [Parameter(Mandatory)][string] $Path)
    $j = Get-Content -Raw $JournalPath | ConvertFrom-Json
    $j.openedFiles = @($j.openedFiles) + @($Path)
    ($j | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $JournalPath -Encoding UTF8
}

# Commit point: atomically rename every staged temp into place, THEN run the
# manifest-update action. The manifest update is the single commit point. To
# achieve set-level transactional behavior across N files on NTFS (which only
# offers per-file atomic Replace), we KEEP every .agentic-bak until the entire
# loop AND the ManifestUpdateAction succeed. On any mid-set failure we restore
# all previously-renamed targets from their baks; new files (no bak) are
# deleted. Only on full success do we delete the bak set.
function Complete-JournalCommit {
    param(
        [Parameter(Mandatory)][string] $JournalPath,
        [Parameter(Mandatory)][scriptblock] $ManifestUpdateAction
    )
    $j = Get-Content -Raw $JournalPath | ConvertFrom-Json
    $applied = New-Object System.Collections.ArrayList   # @{ Target; Bak (or $null for new) }
    try {
        foreach ($s in @($j.stages)) {
            $bak = "$($s.target).agentic-bak"
            if (Test-Path -LiteralPath $s.target) {
                [System.IO.File]::Replace($s.temp, $s.target, $bak)    # atomic on NTFS
                [void]$applied.Add(@{ Target = $s.target; Bak = $bak; Created = $false })
            } else {
                [System.IO.File]::Move($s.temp, $s.target)
                [void]$applied.Add(@{ Target = $s.target; Bak = $null; Created = $true })
            }
        }
        & $ManifestUpdateAction
    } catch {
        # Restore: walk applied in reverse, restore each from bak (or delete if new).
        for ($i = $applied.Count - 1; $i -ge 0; $i--) {
            $a = $applied[$i]
            if ($a.Created) {
                if (Test-Path -LiteralPath $a.Target) { Remove-Item -LiteralPath $a.Target -Force }
            } else {
                if (Test-Path -LiteralPath $a.Bak) {
                    if (Test-Path -LiteralPath $a.Target) { Remove-Item -LiteralPath $a.Target -Force }
                    Move-Item -LiteralPath $a.Bak -Destination $a.Target -Force
                }
            }
        }
        throw
    }
    # Success: delete all baks; mark journal committed.
    foreach ($a in $applied) {
        if ($a.Bak -and (Test-Path -LiteralPath $a.Bak)) { Remove-Item -LiteralPath $a.Bak -Force }
    }
    $j.committed = $true
    ($j | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $JournalPath -Encoding UTF8
}

# ---- Recovery --------------------------------------------------------------
# Incomplete if: lock present without a clean exit, OR staged temps still
# present, OR a journal exists that never reached the commit point.
function Test-IncompleteInstall {
    param([Parameter(Mandatory)][string] $LockPath, [Parameter(Mandatory)][string] $JournalPath)
    $reasons = @()
    if (Test-Path -LiteralPath $LockPath) {
        $lk = $null
        try { $lk = Get-Content -Raw $LockPath | ConvertFrom-Json } catch {}
        if (-not $lk -or -not $lk.cleanExit) { $reasons += "lock present without clean shutdown" }
    }
    if (Test-Path -LiteralPath $JournalPath) {
        $j = Get-Content -Raw $JournalPath | ConvertFrom-Json
        if (-not $j.committed) { $reasons += "journal never reached commit point" }
        foreach ($s in @($j.stages)) {
            if (Test-Path -LiteralPath $s.temp) { $reasons += "staged temp present: $($s.temp)" }
        }
    }
    return [pscustomobject]@{ Incomplete = ($reasons.Count -gt 0); Reasons = $reasons }
}

# Roll back: delete staged temps (live files were never renamed yet) and run
# the injected p4-revert action on files opened by the aborted run. Never
# silently continues.
function Invoke-JournalRollback {
    param(
        [Parameter(Mandatory)][string] $JournalPath,
        [Parameter(Mandatory)][scriptblock] $P4RevertAction
    )
    $j = Get-Content -Raw $JournalPath | ConvertFrom-Json
    foreach ($s in @($j.stages)) {
        if (Test-Path -LiteralPath $s.temp) { Remove-Item -LiteralPath $s.temp -Force }
    }
    $opened = @($j.openedFiles)
    if ($opened.Count -gt 0) { & $P4RevertAction $opened }
    return [pscustomobject]@{ RevertedTemps = @($j.stages).Count; RevertedOpened = $opened.Count }
}
