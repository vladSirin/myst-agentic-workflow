# run-journal-tests.ps1 - crash/recovery model verification (plan v1.6 lines 598-606)
#
#   exit 0 : all checks pass
#   exit 1 : one or more checks failed
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\InstallJournal.ps1')

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("journal-fx-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$lock    = Join-Path $tmp '.scratch\agentic-scaffold-install.lock'
$journal = Join-Path $tmp '.scratch\agentic-scaffold-install.journal'

$pass = 0; $fail = 0
function Ok($n)      { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w)  { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }

# 1. Lock acquire + clean release.
try {
    New-InstallLock -LockPath $lock | Out-Null
    if (Test-Path $lock) { Ok "lock acquired" } else { Bad "lock acquired" "no lock file" }
    Complete-InstallLock -LockPath $lock
    Remove-InstallLock -LockPath $lock
    if (-not (Test-Path $lock)) { Ok "lock released" } else { Bad "lock released" "still present" }
} catch { Bad "lock acquire/release" $_.Exception.Message }

# 2. Concurrent run with a LIVE pid -> LOCK-HELD (caller maps to exit 2).
try {
    $live = [pscustomobject]@{ pid = $PID; startedAt = (Get-Date).ToString('o'); host = 'x'; cleanExit = $false }
    ($live | ConvertTo-Json -Compress) | Set-Content -LiteralPath $lock -Encoding UTF8
    try { New-InstallLock -LockPath $lock | Out-Null; Bad "concurrent-run rejected" "did not throw" }
    catch { if ($_.Exception.Message -like 'LOCK-HELD*') { Ok "concurrent run rejected (LOCK-HELD)" } else { Bad "concurrent-run rejected" $_.Exception.Message } }
} finally { Remove-Item -LiteralPath $lock -Force -ErrorAction SilentlyContinue }

# 3. Stale lock (dead pid): refused without flag, reclaimed with -ReclaimStale.
$deadPid = (Start-Process powershell.exe -ArgumentList '-NoProfile','-Command','exit' -PassThru -Wait).Id
$stale = [pscustomobject]@{ pid = $deadPid; startedAt = (Get-Date).ToString('o'); host = 'x'; cleanExit = $false }
($stale | ConvertTo-Json -Compress) | Set-Content -LiteralPath $lock -Encoding UTF8
try { New-InstallLock -LockPath $lock | Out-Null; Bad "stale-lock refused w/o flag" "did not throw" }
catch { if ($_.Exception.Message -like 'LOCK-STALE*') { Ok "stale lock refused without -ReclaimStale" } else { Bad "stale-lock refused" $_.Exception.Message } }
($stale | ConvertTo-Json -Compress) | Set-Content -LiteralPath $lock -Encoding UTF8
try { New-InstallLock -LockPath $lock -ReclaimStale | Out-Null; Ok "stale lock reclaimed with -ReclaimStale" }
catch { Bad "stale-lock reclaim" $_.Exception.Message }
Remove-InstallLock -LockPath $lock

# 4. Staging does NOT touch the live file until the commit point.
$target = Join-Path $tmp 'CONFIG.md'
Set-Content -LiteralPath $target -Value "ORIGINAL" -NoNewline -Encoding UTF8
New-WriteJournal -JournalPath $journal | Out-Null
Add-JournalStage -JournalPath $journal -Target $target -Content "NEWCONTENT"
$liveAfterStage = Get-Content -Raw $target
if ($liveAfterStage -eq "ORIGINAL" -and (Test-Path "$target.agentic-stage")) {
    Ok "staging leaves live file untouched (temp written)"
} else { Bad "staging" "live='$liveAfterStage'" }

# 5. Crash BEFORE commit -> detected incomplete; rollback reverts temps + p4.
$detect = Test-IncompleteInstall -LockPath $lock -JournalPath $journal
if ($detect.Incomplete -and ($detect.Reasons -join ';') -match 'commit point|staged temp') {
    Ok "incomplete run detected (not silently continued)"
} else { Bad "incomplete detection" ($detect | ConvertTo-Json -Compress) }

Register-OpenedFile -JournalPath $journal -Path $target
$script:reverted = @()
$p4revert = { param($files) $script:reverted = $files }
$rb = Invoke-JournalRollback -JournalPath $journal -P4RevertAction $p4revert
$liveAfterRb = Get-Content -Raw $target
if (-not (Test-Path "$target.agentic-stage") -and $liveAfterRb -eq "ORIGINAL" -and $script:reverted.Count -eq 1) {
    Ok "rollback removed staged temp, preserved live file, called p4 revert on opened files"
} else { Bad "rollback" "temp?$(Test-Path "$target.agentic-stage") live='$liveAfterRb' reverted=$($script:reverted.Count)" }

# 6. Happy path: commit performs atomic rename + manifest action = single commit point.
$target2 = Join-Path $tmp 'CONFIG2.md'
Set-Content -LiteralPath $target2 -Value "OLD" -NoNewline -Encoding UTF8
$journal2 = Join-Path $tmp '.scratch\j2.journal'
New-WriteJournal -JournalPath $journal2 | Out-Null
Add-JournalStage -JournalPath $journal2 -Target $target2 -Content "COMMITTED"
$script:manifestUpdated = $false
Complete-JournalCommit -JournalPath $journal2 -ManifestUpdateAction { $script:manifestUpdated = $true }
$j2 = Get-Content -Raw $journal2 | ConvertFrom-Json
if ((Get-Content -Raw $target2) -eq "COMMITTED" -and $script:manifestUpdated -and $j2.committed) {
    Ok "commit point: atomic rename applied + manifest updated + journal committed"
} else { Bad "commit point" "live='$(Get-Content -Raw $target2)' mani=$script:manifestUpdated committed=$($j2.committed)" }

# 7. BLOCKING-2 regression: mid-commit failure restores ALL prior renames from baks.
$tA = Join-Path $tmp 'A.md'; $tB = Join-Path $tmp 'B.md'; $tC = Join-Path $tmp 'C.md'
Set-Content -LiteralPath $tA -Value 'A-orig' -NoNewline -Encoding UTF8
Set-Content -LiteralPath $tB -Value 'B-orig' -NoNewline -Encoding UTF8
Set-Content -LiteralPath $tC -Value 'C-orig' -NoNewline -Encoding UTF8
$jrn3 = Join-Path $tmp '.scratch\j3.journal'
New-WriteJournal -JournalPath $jrn3 | Out-Null
Add-JournalStage -JournalPath $jrn3 -Target $tA -Content 'A-NEW'
Add-JournalStage -JournalPath $jrn3 -Target $tB -Content 'B-NEW'
Add-JournalStage -JournalPath $jrn3 -Target $tC -Content 'C-NEW'
$threw = $false
try {
    Complete-JournalCommit -JournalPath $jrn3 -ManifestUpdateAction { throw 'simulated manifest-update failure after all renames' }
} catch { $threw = $true }
$rA = Get-Content -Raw $tA; $rB = Get-Content -Raw $tB; $rC = Get-Content -Raw $tC
$j3 = Get-Content -Raw $jrn3 | ConvertFrom-Json
if ($threw -and $rA -eq 'A-orig' -and $rB -eq 'B-orig' -and $rC -eq 'C-orig' -and -not $j3.committed) {
    Ok "BLOCKING-2 fix: mid-commit failure restores ALL prior renames from baks"
} else { Bad "BLOCKING-2 fix" "threw=$threw  A='$rA' B='$rB' C='$rC' committed=$($j3.committed)" }

Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
Write-Output ""
Write-Output "=============================================================="
Write-Output "Journal/recovery tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
