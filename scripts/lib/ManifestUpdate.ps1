# ManifestUpdate.ps1 - Update-ManifestForChanges (issue 08)
#
# Surgical line-level rewrite of scaffold-manifest.json so that the per-entry
# hash fields reflect what was actually just written to disk. Called as the
# ManifestUpdateAction passed to Complete-JournalCommit, so it runs as the
# single commit point: a throw here causes Complete-JournalCommit to restore
# every staged target from its bak (the BLOCKING-2 transactional restore).
#
# Hashes are computed by re-reading the on-disk file (not the in-memory
# rendered string), per issue 08 triage note #1: catches encoding/BOM/EOL
# anomalies before the manifest commits and matches what the next preflight
# check 2 will see.
#
# Surgical: only `contentHash` / `blockHash` / `lastCheckedAt` lines of
# changed entries are rewritten. Every other byte of the manifest is preserved.

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Markers.ps1')

function Get-RawFileHash {
    param([Parameter(Mandatory)][string] $Path)
    # EOL/BOM-invariant (see Get-NormalizedContentHash in Markers.ps1). Named "Raw"
    # historically; the contentHash is now normalized so it survives CRLF<->LF sync.
    return Get-NormalizedContentHash -Path $Path
}

function Update-ManifestForChanges {
    param(
        [Parameter(Mandatory)][string] $ManifestPath,
        # Each change must carry: .Path, .Strategy, .Target, and (for block-scoped)
        # one of .GeneratedBlockId / .AppendFragmentId.
        [Parameter(Mandatory)][array]  $Changes,
        # Optional provenance stamp (audit 2026-08-06): nothing on the update path
        # ever refreshed package.version/sourceCommit, so the consumer manifest
        # said "1.0.0 @ 7489cad" forever while running 4.x content and every
        # staleness diagnosis lied. Callers pass the version/SHA just installed.
        [string] $PackageVersion = '',
        [string] $PackageSourceCommit = ''
    )

    # 1. Read manifest preserving BOM + line-ending convention.
    $raw = [System.IO.File]::ReadAllBytes($ManifestPath)
    $hasBom = ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF)
    if ($hasBom) {
        $body = New-Object byte[] ($raw.Length - 3)
        [Array]::Copy($raw, 3, $body, 0, $body.Length)
        $text = [System.Text.Encoding]::UTF8.GetString($body)
    } else {
        $text = [System.Text.Encoding]::UTF8.GetString($raw)
    }
    $crlf = $text.Contains("`r`n")
    $nl   = if ($crlf) { "`r`n" } else { "`n" }

    # 2. Build the new-hash-by-path map (re-hashing from disk per triage note 1).
    $hashByPath = @{}
    foreach ($c in $Changes) {
        if ($c.Strategy -eq 'copy') {
            $hashByPath[$c.Path] = @{ Field = 'contentHash'; Value = (Get-RawFileHash $c.Target) }
        } elseif ($c.Strategy -in @('generated-block','append-fragment')) {
            $id = if ($c.Strategy -eq 'generated-block') { $c.GeneratedBlockId } else { $c.AppendFragmentId }
            $hashByPath[$c.Path] = @{ Field = 'blockHash'; Value = (Get-MarkerBlockHash -Path $c.Target -Id $id) }
        }
    }

    # 2b. Optional depotRevision, supplied by the CALLER -- this library stays
    #     Perforce-free so filesystem-only consumers are unaffected. Without this,
    #     a write left the manifest naming the pre-submit revision forever: preflight
    #     check 4 went red, the write gate refused every subsequent run, and someone
    #     had to hand-edit the numbers. install.ps1 passes head+1 for an edit and 1
    #     for an add; check 4 tolerates that while the file is open, and it becomes
    #     exact on submit.
    $revByPath = @{}
    foreach ($c in $Changes) {
        if ($null -ne $c.PSObject.Properties['DepotRevision'] -and $null -ne $c.DepotRevision) {
            $revByPath[$c.Path] = [int]$c.DepotRevision
        }
    }
    $now = (Get-Date).ToString('o')

    # 3. Walk lines (LF-normalized for matching). Track current entry by its
    #    `"path": "..."` line. Rewrite only the targeted hash field plus
    #    lastCheckedAt for entries in $hashByPath.
    $linesArr = ($text -replace "`r`n","`n" -replace "`r","`n").Split("`n")
    $cur = $null
    $inPackage = $false
    for ($i = 0; $i -lt $linesArr.Count; $i++) {
        $ln = $linesArr[$i]
        # Package-provenance stamp, scoped STRICTLY to the "package": { block --
        # a bare "version" match would also hit the installer block below it.
        if ($ln -match '^\s+"package":\s*\{\s*$') { $inPackage = $true; continue }
        if ($inPackage) {
            if ($PackageVersion -and $ln -match '^(\s+"version":\s+)"[^"]*"(,?\s*)$') {
                $linesArr[$i] = $Matches[1] + '"' + $PackageVersion + '"' + $Matches[2]; continue
            }
            if ($PackageSourceCommit -and $ln -match '^(\s+"sourceCommit":\s+)"[^"]*"(,?\s*)$') {
                $linesArr[$i] = $Matches[1] + '"' + $PackageSourceCommit + '"' + $Matches[2]; continue
            }
            if ($ln -match '^\s+\},?\s*$') { $inPackage = $false }
            continue
        }
        if ($ln -match '^\s+"path":\s+"([^"]+)",\s*$') {
            $cur = $Matches[1]
            continue
        }
        if ($null -eq $cur) { continue }

        # depotRevision is independent of the hash map: a caller may supply a
        # revision for an entry whose hash did not change (and vice versa).
        if ($revByPath.ContainsKey($cur) -and $ln -match '^(\s+"depotRevision":\s+)([^,]*?)(,?\s*)$') {
            $linesArr[$i] = $Matches[1] + [string]$revByPath[$cur] + $Matches[3]
            continue
        }

        if (-not $hashByPath.ContainsKey($cur)) { continue }
        $info = $hashByPath[$cur]

        if ($info.Field -eq 'contentHash' -and $ln -match '^(\s+"contentHash":\s+)([^,]*?)(,?\s*)$') {
            $linesArr[$i] = $Matches[1] + '"' + $info.Value + '"' + $Matches[3]
        } elseif ($info.Field -eq 'blockHash' -and $ln -match '^(\s+"blockHash":\s+)([^,}]*?)(,?\s*)$') {
            $linesArr[$i] = $Matches[1] + '"' + $info.Value + '"' + $Matches[3]
        } elseif ($ln -match '^(\s+"lastCheckedAt":\s+)"[^"]+"(,?\s*)$') {
            $linesArr[$i] = $Matches[1] + '"' + $now + '"' + $Matches[2]
        }
    }

    # 4. Write back, restoring BOM + EOL.
    $newText = $linesArr -join $nl
    $body = [System.Text.Encoding]::UTF8.GetBytes($newText)
    if ($hasBom) {
        $out = New-Object byte[] ($body.Length + 3)
        $out[0] = 0xEF; $out[1] = 0xBB; $out[2] = 0xBF
        [Array]::Copy($body, 0, $out, 3, $body.Length)
        [System.IO.File]::WriteAllBytes($ManifestPath, $out)
    } else {
        [System.IO.File]::WriteAllBytes($ManifestPath, $body)
    }
}
