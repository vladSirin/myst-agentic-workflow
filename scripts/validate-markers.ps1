# validate-markers.ps1 - read-only marker gate (plan v1.6 line 391)
#
# Decides whether the installer is allowed to write a block-scoped file.
# It NEVER writes. On ANY marker ambiguity it refuses and exits 2 (never a
# partial write). On a clean single BEGIN/END pair it prints the authoritative
# blockHash and exits 0.
#
#   exit 0 : markers resolve cleanly; blockHash printed on stdout
#   exit 2 : marker ambiguity (refuse to write) OR runtime failure
param(
    [Parameter(Mandatory=$true)] [string] $File,
    [Parameter(Mandatory=$true)] [string] $Id,
    [Parameter(Mandatory=$false)][ValidateSet('html','hash')] [string] $Style
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Markers.ps1')

# Integrity guard: prove zero mutation. We hash the raw bytes before and after;
# a read-only path must leave them byte-identical.
function Get-RawSha($path) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $b = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $path))
    $s = [System.Security.Cryptography.SHA256]::Create()
    return [BitConverter]::ToString($s.ComputeHash($b)).Replace('-','').ToLowerInvariant()
}

$preHash = Get-RawSha $File
try {
    if (-not $Style) { $Style = Get-MarkerStyleForPath -Path $File }
    $blockHash = Get-MarkerBlockHash -Path $File -Id $Id -Style $Style
    $postHash = Get-RawSha $File
    if ($preHash -ne $postHash) {
        Write-Error "FATAL: validate-markers mutated the file (pre=$preHash post=$postHash). This must never happen."
        exit 2
    }
    Write-Output $blockHash
    exit 0
}
catch [MarkerAmbiguityException] {
    $cat = $_.Exception.Category
    $postHash = Get-RawSha $File
    Write-Output "=============================================================="
    Write-Output "MARKER AMBIGUITY - REFUSING TO WRITE (exit 2)"
    Write-Output "  file    : $File"
    Write-Output "  id      : $Id"
    Write-Output "  category: $cat"
    Write-Output "  message : $($_.Exception.Message)"
    Write-Output "  mutation: $(if ($preHash -eq $postHash) { 'NONE (verified byte-identical)' } else { 'DETECTED - INVESTIGATE' })"
    Write-Output "=============================================================="
    exit 2
}
catch {
    $postHash = Get-RawSha $File
    Write-Output "RUNTIME FAILURE (exit 2): $($_.Exception.Message)"
    Write-Output "  mutation: $(if ($preHash -eq $postHash) { 'NONE' } else { 'DETECTED - INVESTIGATE' })"
    exit 2
}
