# run-manifest-update-tests.ps1 - Update-ManifestForChanges verification (issue 08)
#
#   exit 0 : all checks pass
#   exit 1 : one or more checks failed
param()

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
. (Join-Path $here 'lib\Markers.ps1')
. (Join-Path $here 'lib\InstallJournal.ps1')
. (Join-Path $here 'lib\ManifestUpdate.ps1')

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("manupd-fx-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$pass = 0; $fail = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }

# ----------------------------------------------------------------------------
# Build a minimal v3 manifest in $tmp with 2 entries:
#   - copy:            CONFIG.md  (initial contentHash = sha256(disk))
#   - generated-block: NOTES.md   (initial blockHash = sha256(block bytes))
# ----------------------------------------------------------------------------
function New-MinimalManifest {
    param([string]$Root)

    $config = Join-Path $Root 'CONFIG.md'
    $notes  = Join-Path $Root 'NOTES.md'
    Set-Content -LiteralPath $config -Value 'INITIAL-CONFIG' -NoNewline -Encoding UTF8
    $notesText = "# Notes`n`n<!-- AGENTIC-SCAFFOLD:BEGIN id=test-block sha256=sha256:ignored -->`nINITIAL-INNER`n<!-- AGENTIC-SCAFFOLD:END id=test-block -->`n"
    [IO.File]::WriteAllBytes($notes, [Text.Encoding]::UTF8.GetBytes($notesText))

    $initConfigHash = 'sha256:' + ([BitConverter]::ToString(
        [Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($config))
    ).Replace('-','').ToLowerInvariant())
    $initBlockHash = Get-MarkerBlockHash -Path $notes -Id 'test-block'

    $manifestPath = Join-Path $Root 'manifest.json'
    $obj = [ordered]@{
        schemaVersion = 3
        files = @(
            [ordered]@{
                path             = 'CONFIG.md'
                tool             = 'common'
                mergeStrategy    = 'copy'
                hashPolicy       = 'sha256'
                contentHash      = $initConfigHash
                lastCheckedAt    = '2026-01-01T00:00:00+00:00'
                blockHashPolicy  = 'not-applicable'
                blockHash        = $null
            },
            [ordered]@{
                path             = 'NOTES.md'
                tool             = 'common'
                mergeStrategy    = 'generated-block'
                hashPolicy       = 'block-scoped'
                contentHash      = $null
                generatedBlockId = 'test-block'
                lastCheckedAt    = '2026-01-01T00:00:00+00:00'
                blockHashPolicy  = 'sha256'
                blockHash        = $initBlockHash
            }
        )
    }
    ($obj | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    return @{ Manifest = $manifestPath; Config = $config; Notes = $notes; InitConfig = $initConfigHash; InitBlock = $initBlockHash }
}

$ctx = New-MinimalManifest -Root $tmp

# Snapshot original manifest bytes for "surgical" verification.
$origBytes = [IO.File]::ReadAllBytes($ctx.Manifest)

# ----------------------------------------------------------------------------
# 1. Modify CONFIG.md and NOTES.md (block) on disk, then run the update.
# ----------------------------------------------------------------------------
Set-Content -LiteralPath $ctx.Config -Value 'UPDATED-CONFIG-VALUE' -NoNewline -Encoding UTF8
$newNotes = "# Notes`n`n<!-- AGENTIC-SCAFFOLD:BEGIN id=test-block sha256=sha256:ignored -->`nUPDATED-INNER-LINE-1`nUPDATED-INNER-LINE-2`n<!-- AGENTIC-SCAFFOLD:END id=test-block -->`n"
[IO.File]::WriteAllBytes($ctx.Notes, [Text.Encoding]::UTF8.GetBytes($newNotes))

$changes = @(
    [pscustomobject]@{ Path='CONFIG.md'; Strategy='copy';            Target=$ctx.Config }
    [pscustomobject]@{ Path='NOTES.md';  Strategy='generated-block'; Target=$ctx.Notes; GeneratedBlockId='test-block' }
)
Update-ManifestForChanges -ManifestPath $ctx.Manifest -Changes $changes

# ----------------------------------------------------------------------------
# 2. Validate: manifest entries have NEW hashes, both differ from initial.
# ----------------------------------------------------------------------------
$m = Get-Content -Raw $ctx.Manifest | ConvertFrom-Json
$newConfigEntry = $m.files | Where-Object { $_.path -eq 'CONFIG.md' }
$newNotesEntry  = $m.files | Where-Object { $_.path -eq 'NOTES.md'  }

# contentHash is EOL/BOM-invariant (Get-NormalizedContentHash), same normalization as blockHash.
$expectedConfig = Get-NormalizedContentHash -Path $ctx.Config
$expectedBlock  = Get-MarkerBlockHash -Path $ctx.Notes -Id 'test-block'

if ($newConfigEntry.contentHash -eq $expectedConfig -and $newConfigEntry.contentHash -ne $ctx.InitConfig) {
    Ok 'copy contentHash recomputed from disk'
} else { Bad 'copy contentHash recomputed' "got=$($newConfigEntry.contentHash)  expected=$expectedConfig" }

if ($newNotesEntry.blockHash -eq $expectedBlock -and $newNotesEntry.blockHash -ne $ctx.InitBlock) {
    Ok 'generated-block blockHash recomputed from disk'
} else { Bad 'generated-block blockHash recomputed' "got=$($newNotesEntry.blockHash)  expected=$expectedBlock" }

if ($newConfigEntry.lastCheckedAt -ne '2026-01-01T00:00:00+00:00') {
    Ok 'lastCheckedAt advanced past initial'
} else { Bad 'lastCheckedAt advanced' 'unchanged' }

# ----------------------------------------------------------------------------
# 3. Surgical: only the 6 touched lines should differ (2 hashes + 2
#    lastCheckedAt + nothing else). Diff at the byte level.
# ----------------------------------------------------------------------------
$newBytes = [IO.File]::ReadAllBytes($ctx.Manifest)
$origText = [Text.Encoding]::UTF8.GetString($origBytes)
$newText  = [Text.Encoding]::UTF8.GetString($newBytes)
$origLines = ($origText -replace "`r`n","`n").Split("`n")
$newLines  = ($newText  -replace "`r`n","`n").Split("`n")
if ($origLines.Count -ne $newLines.Count) {
    Bad 'surgical line count preserved' "orig=$($origLines.Count) new=$($newLines.Count)"
} else {
    $changed = 0
    for ($i = 0; $i -lt $origLines.Count; $i++) {
        if ($origLines[$i] -ne $newLines[$i]) { $changed++ }
    }
    # Expected: 4 lines (2 contentHash/blockHash + 2 lastCheckedAt)
    if ($changed -le 4) { Ok "surgical rewrite: only $changed line(s) changed (expected <=4)" }
    else { Bad 'surgical rewrite' "$changed lines changed (expected <=4)" }
}

# ----------------------------------------------------------------------------
# 4. Negative: throw from Update-ManifestForChanges via a missing file;
#    Complete-JournalCommit BLOCKING-2 fix restores. We simulate by passing
#    a bogus target.
# ----------------------------------------------------------------------------
$jrnPath = Join-Path $tmp '.scratch\j.journal'
New-WriteJournal -JournalPath $jrnPath | Out-Null
Set-Content -LiteralPath $ctx.Config -Value 'ORIG' -NoNewline -Encoding UTF8
Add-JournalStage -JournalPath $jrnPath -Target $ctx.Config -Content 'STAGED-NEW'

$bogusChanges = @(
    [pscustomobject]@{ Path='CONFIG.md'; Strategy='copy'; Target='Z:\definitely-not-a-real-path.bogus' }
)
$threw = $false
try {
    Complete-JournalCommit -JournalPath $jrnPath -ManifestUpdateAction ([scriptblock]::Create("Update-ManifestForChanges -ManifestPath '$($ctx.Manifest)' -Changes `$args[0]")).GetNewClosure()
} catch { $threw = $true }
# Use a simpler approach: pre-bake a scriptblock that throws via Update-ManifestForChanges
# with the bogus change. Reset and retry.
$jrn2 = Join-Path $tmp '.scratch\j2.journal'
New-WriteJournal -JournalPath $jrn2 | Out-Null
Set-Content -LiteralPath $ctx.Config -Value 'BEFORE-STAGE' -NoNewline -Encoding UTF8
Add-JournalStage -JournalPath $jrn2 -Target $ctx.Config -Content 'NEW-FROM-STAGE'
$throwAction = { Update-ManifestForChanges -ManifestPath $ctx.Manifest -Changes $bogusChanges }.GetNewClosure()
$threw2 = $false
try { Complete-JournalCommit -JournalPath $jrn2 -ManifestUpdateAction $throwAction } catch { $threw2 = $true }
$afterContent = Get-Content -Raw $ctx.Config
if ($threw2 -and $afterContent -eq 'BEFORE-STAGE') {
    Ok 'failure in ManifestUpdateAction rolls back file rename (BLOCKING-2 restore confirmed end-to-end)'
} else { Bad 'rollback on action failure' "threw=$threw2  content='$afterContent'" }

# ----------------------------------------------------------------------------
# 5. EOL/BOM invariance: Get-NormalizedContentHash must be identical across LF,
#    CRLF, and BOM+CRLF encodings of the same content. An LF-only git checkout
#    cannot exercise CRLF, so assert it explicitly here - this is what guards the
#    five contentHash sites against a raw-byte regression (a CRLF consumer would
#    otherwise false-report drift; see CHANGELOG 4.8.0).
# ----------------------------------------------------------------------------
$eolBase  = "line one`nline two`nline three`n"
$lfFile   = Join-Path $tmp 'eol-lf.md'
$crlfFile = Join-Path $tmp 'eol-crlf.md'
$bomFile  = Join-Path $tmp 'eol-bom-crlf.md'
[IO.File]::WriteAllBytes($lfFile,   [Text.Encoding]::UTF8.GetBytes($eolBase))
[IO.File]::WriteAllBytes($crlfFile, [Text.Encoding]::UTF8.GetBytes(($eolBase -replace "`n","`r`n")))
[IO.File]::WriteAllBytes($bomFile,  (([byte[]](0xEF,0xBB,0xBF)) + [Text.Encoding]::UTF8.GetBytes(($eolBase -replace "`n","`r`n"))))
$hLf   = Get-NormalizedContentHash -Path $lfFile
$hCrlf = Get-NormalizedContentHash -Path $crlfFile
$hBom  = Get-NormalizedContentHash -Path $bomFile
if ($hLf -eq $hCrlf -and $hLf -eq $hBom) {
    Ok 'contentHash is EOL/BOM-invariant (LF == CRLF == BOM+CRLF)'
} else { Bad 'contentHash EOL/BOM-invariant' "lf=$hLf crlf=$hCrlf bom=$hBom" }

# ----------------------------------------------------------------------------
# 6. depotRevision is written only when the CALLER supplies one.
#    The library must stay Perforce-free: a filesystem-only consumer passes no
#    revision and its manifest must come back untouched in that field. When a
#    revision IS supplied (install.ps1 does it under -UsePerforce), it must land,
#    even for an entry whose content hash did not change -- otherwise the manifest
#    keeps naming the pre-submit revision, preflight check 4 stays red, and the
#    write gate refuses every later run.
# ----------------------------------------------------------------------------
$revDir  = Join-Path $tmp 'revcase'
New-Item -ItemType Directory -Force -Path $revDir | Out-Null
$revTarget = Join-Path $revDir 'tracked.md'
Set-Content -LiteralPath $revTarget -Value "hello" -NoNewline
$revManifest = Join-Path $revDir 'manifest.json'
$revJson = @'
{
  "schemaVersion": 3,
  "files": [
    {
      "path": "tracked.md",
      "hashPolicy": "sha256",
      "contentHash": "sha256:stale",
      "depotRevision": 7,
      "lastCheckedAt": "2020-01-01T00:00:00.0000000+00:00"
    },
    {
      "path": "untouched.md",
      "hashPolicy": "sha256",
      "contentHash": "sha256:keepme",
      "depotRevision": 3,
      "lastCheckedAt": "2020-01-01T00:00:00.0000000+00:00"
    }
  ]
}
'@
Set-Content -LiteralPath $revManifest -Value $revJson

# (a) caller supplies a revision -> it lands
$withRev = [pscustomobject]@{ Path='tracked.md'; Strategy='copy'; Target=$revTarget; DepotRevision=8 }
Update-ManifestForChanges -ManifestPath $revManifest -Changes @($withRev)
$after = Get-Content -Raw $revManifest | ConvertFrom-Json
$tracked   = $after.files | Where-Object { $_.path -eq 'tracked.md' }
$untouched = $after.files | Where-Object { $_.path -eq 'untouched.md' }
if ($tracked.depotRevision -eq 8) { Ok 'depotRevision written when the caller supplies one' }
else { Bad 'depotRevision written when supplied' "got $($tracked.depotRevision), expected 8" }
if ($tracked.contentHash -ne 'sha256:stale') { Ok 'contentHash still refreshed alongside the revision' }
else { Bad 'contentHash refreshed alongside revision' 'hash was not updated' }
if ($untouched.depotRevision -eq 3 -and $untouched.contentHash -eq 'sha256:keepme') {
    Ok 'entries not in the change set are left alone'
} else { Bad 'entries not in the change set are left alone' "rev=$($untouched.depotRevision) hash=$($untouched.contentHash)" }

# (b) no revision supplied (filesystem-only consumer) -> field untouched
Set-Content -LiteralPath $revManifest -Value $revJson
$noRev = [pscustomobject]@{ Path='tracked.md'; Strategy='copy'; Target=$revTarget }
Update-ManifestForChanges -ManifestPath $revManifest -Changes @($noRev)
$after2 = (Get-Content -Raw $revManifest | ConvertFrom-Json).files | Where-Object { $_.path -eq 'tracked.md' }
if ($after2.depotRevision -eq 7) { Ok 'depotRevision untouched when no revision is supplied (filesystem-only path)' }
else { Bad 'depotRevision untouched without a supplied revision' "got $($after2.depotRevision), expected 7" }

Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "=============================================================="
Write-Output "Manifest-update tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
