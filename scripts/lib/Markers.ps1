# Markers.ps1 — Marker Specification implementation (plan v1.6 lines 368-405)
#
# Pure, READ-ONLY parser. It never writes a file. Any marker ambiguity is a
# hard error: callers map it to exit code 2 and refuse to write (plan line 391).
#
# Hard rules implemented (plan lines 381-388):
#  - A marker is a WHOLE line after optional leading whitespace (0-3 spaces).
#  - A candidate inside a fenced (``` / ~~~) OR indented (>=4 sp / tab) code
#    block is NOT a marker (documentation examples are inert).
#  - Per id: exactly one BEGIN and one END, BEGIN before END, no nesting,
#    no overlap. Zero / multiple / unbalanced / inverted / nested = hard error.
#  - Line endings normalized to LF; UTF-8 BOM stripped, never reintroduced.
#  - Block content = bytes strictly between the BEGIN line terminator and the
#    END line start, after LF normalization, excluding the marker lines.

Set-StrictMode -Version Latest

# Comment styles. Embedded sha256 on BEGIN is informational redundancy
# (plan line 379): the manifest blockHash is authoritative, so it is optional
# in the pattern and never trusted here.
$script:MarkerStyles = @{
    'html' = @{
        Begin = '^(?<indent>\s*)<!-- AGENTIC-SCAFFOLD:BEGIN id=(?<id>\S+)(?: sha256=(?<sha>\S+))? -->\s*$'
        End   = '^(?<indent>\s*)<!-- AGENTIC-SCAFFOLD:END id=(?<id>\S+) -->\s*$'
    }
    'hash' = @{
        Begin = '^(?<indent>\s*)# AGENTIC-SCAFFOLD:BEGIN id=(?<id>\S+)(?: sha256=(?<sha>\S+))?\s*$'
        End   = '^(?<indent>\s*)# AGENTIC-SCAFFOLD:END id=(?<id>\S+)\s*$'
    }
}

class MarkerAmbiguityException : System.Exception {
    [string] $Category
    MarkerAmbiguityException([string] $category, [string] $message)
        : base($message) { $this.Category = $category }
}

function Get-MarkerStyleForPath {
    param([Parameter(Mandatory)][string] $Path)
    $name = [System.IO.Path]::GetFileName($Path)
    if ($name -ieq '.p4ignore') { return 'hash' }
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    switch ($ext) {
        '.md'  { return 'html' }
        ''     { return 'hash' }   # extensionless (.p4ignore handled above)
        default { return 'hash' }
    }
}

# Read a file as text with LF normalization and BOM stripping (plan line 386).
# Returns the normalized string. Never writes.
function Read-NormalizedText {
    param([Parameter(Mandatory)][string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw [MarkerAmbiguityException]::new('file-missing', "File not found: $Path")
    }
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path))
    # Strip UTF-8 BOM (EF BB BF) if present; do not reintroduce it.
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bytes = $bytes[3..($bytes.Length - 1)]
    }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    # Normalize CRLF and lone CR to LF. CRLF/BOM must never alter the block hash.
    $text = $text -replace "`r`n", "`n"
    $text = $text -replace "`r", "`n"
    return $text
}

# Scan normalized text and return the resolved BEGIN/END line indices for $Id,
# applying every hard rule. Throws MarkerAmbiguityException on any ambiguity.
function Resolve-MarkerSpan {
    param(
        [Parameter(Mandatory)][string] $NormalizedText,
        [Parameter(Mandatory)][string] $Id,
        [Parameter(Mandatory)][ValidateSet('html','hash')][string] $Style
    )
    $pat   = $script:MarkerStyles[$Style]
    # ", 0" = all substrings in BOTH PS editions. ", -1" is a PS7 trap: negative
    # limits split from the END (|-1| = 1 substring = no split), silently breaking
    # marker resolution under pwsh while working under Windows PowerShell 5.1.
    $lines = $NormalizedText -split "`n", 0

    $inFence   = $false
    $fenceChar = $null
    $begins    = New-Object System.Collections.ArrayList
    $ends      = New-Object System.Collections.ArrayList

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Fenced code block toggle: a line whose trimmed content starts with
        # >=3 backticks or >=3 tildes (CommonMark fence).
        $trimmed = $line.TrimStart()
        if ($trimmed -match '^(`{3,}|~{3,})') {
            $thisChar = $trimmed[0]
            if (-not $inFence) { $inFence = $true; $fenceChar = $thisChar }
            elseif ($thisChar -eq $fenceChar) { $inFence = $false; $fenceChar = $null }
            continue
        }
        if ($inFence) { continue }   # tokens inside a fence are inert

        # Indented code block: >=4 leading spaces or a leading tab -> inert.
        if ($line -match '^( {4,}|\t)') { continue }

        $bm = [regex]::Match($line, $pat.Begin)
        if ($bm.Success -and $bm.Groups['id'].Value -eq $Id) {
            [void]$begins.Add($i); continue
        }
        $em = [regex]::Match($line, $pat.End)
        if ($em.Success -and $em.Groups['id'].Value -eq $Id) {
            [void]$ends.Add($i); continue
        }
    }

    if ($begins.Count -eq 0 -and $ends.Count -eq 0) {
        throw [MarkerAmbiguityException]::new('zero-markers',
            "No BEGIN/END markers found for id='$Id'.")
    }
    if ($begins.Count -ne 1) {
        throw [MarkerAmbiguityException]::new('begin-count',
            "Expected exactly one BEGIN for id='$Id', found $($begins.Count).")
    }
    if ($ends.Count -ne 1) {
        throw [MarkerAmbiguityException]::new('end-count',
            "Expected exactly one END for id='$Id', found $($ends.Count).")
    }
    $b = $begins[0]; $e = $ends[0]
    if ($b -ge $e) {
        throw [MarkerAmbiguityException]::new('inverted',
            "BEGIN (line $($b+1)) must precede END (line $($e+1)) for id='$Id'.")
    }
    return [pscustomobject]@{ BeginLine = $b; EndLine = $e; Lines = $lines }
}

# Return the canonical block content (LF, no marker lines) for $Id.
function Get-MarkerBlockContent {
    param(
        [Parameter(Mandatory)][string] $NormalizedText,
        [Parameter(Mandatory)][string] $Id,
        [Parameter(Mandatory)][ValidateSet('html','hash')][string] $Style
    )
    $span = Resolve-MarkerSpan -NormalizedText $NormalizedText -Id $Id -Style $Style
    $inner = @()
    for ($i = $span.BeginLine + 1; $i -lt $span.EndLine; $i++) { $inner += $span.Lines[$i] }
    # Strictly between the BEGIN terminator and the END line start.
    return ($inner -join "`n")
}

# Expand {{var}} placeholders in template text. Pure: text in -> text out.
# Substitution is exact-string match on `{{name}}` -- no escaping, no regex,
# no conditionals. Per Q3 decision (issue 07): simple substitution only.
function Expand-TemplateVars {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string] $Text,
        [Parameter(Mandatory)][hashtable] $Vars
    )
    foreach ($k in $Vars.Keys) { $Text = $Text.Replace("{{$k}}", [string]$Vars[$k]) }
    return $Text
}

# SHA-256 of an arbitrary block string (LF). Authoritative blockHash form.
function Get-BlockStringHash {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $Block)
    $sha  = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Block))
    return 'sha256:' + ([BitConverter]::ToString($hash).Replace('-','').ToLowerInvariant())
}

# Deterministically insert or in-place update an append-fragment (plan lines
# 395-401). PURE: text in -> text out, no disk I/O. First install appends at
# EOF; re-runs update content between existing markers WITHOUT relocating;
# pre-existing lines and their order are never touched. Marker ambiguities
# other than "not present yet" propagate as hard errors (refuse).
function Set-AppendFragment {
    param(
        [Parameter(Mandatory)][string] $NormalizedText,
        [Parameter(Mandatory)][string] $Id,
        [Parameter(Mandatory)][string] $FragmentText,
        [Parameter(Mandatory)][ValidateSet('html','hash')][string] $Style
    )
    $frag = ($FragmentText -replace "`r`n","`n") -replace "`r","`n"
    $frag = $frag.TrimEnd("`n")
    $blockHash = Get-BlockStringHash $frag
    if ($Style -eq 'html') {
        $beginLine = "<!-- AGENTIC-SCAFFOLD:BEGIN id=$Id sha256=$blockHash -->"
        $endLine   = "<!-- AGENTIC-SCAFFOLD:END id=$Id -->"
    } else {
        $beginLine = "# AGENTIC-SCAFFOLD:BEGIN id=$Id sha256=$blockHash"
        $endLine   = "# AGENTIC-SCAFFOLD:END id=$Id"
    }

    $span = $null
    try {
        $span = Resolve-MarkerSpan -NormalizedText $NormalizedText -Id $Id -Style $Style
    }
    catch [MarkerAmbiguityException] {
        if ($_.Exception.Category -ne 'zero-markers') { throw }  # refuse on real ambiguity
    }

    if ($null -ne $span) {
        # In-place update: keep marker line positions, replace only inner + refresh BEGIN.
        $lines = $span.Lines
        $out = @()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -eq $span.BeginLine) {
                $out += $beginLine
                foreach ($fl in ($frag -split "`n", 0)) { $out += $fl }
            } elseif ($i -gt $span.BeginLine -and $i -lt $span.EndLine) {
                continue   # old inner content dropped
            } elseif ($i -eq $span.EndLine) {
                $out += $endLine
            } else {
                $out += $lines[$i]   # pre-existing content untouched, order preserved
            }
        }
        return ($out -join "`n")
    }

    # First install: append at EOF, fragment preceded by its BEGIN marker.
    $base = $NormalizedText.TrimEnd("`n")
    $appended = $base + "`n" + $beginLine + "`n" + $frag + "`n" + $endLine + "`n"
    return $appended
}

# SHA-256 of the block content. This is the authoritative blockHash value.
function Get-MarkerBlockHash {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $Id,
        [Parameter(Mandatory=$false)][ValidateSet('html','hash')][string] $Style
    )
    if (-not $Style) { $Style = Get-MarkerStyleForPath -Path $Path }
    $text  = Read-NormalizedText -Path $Path
    $block = Get-MarkerBlockContent -NormalizedText $text -Id $Id -Style $Style
    $sha   = [System.Security.Cryptography.SHA256]::Create()
    $hash  = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($block))
    return 'sha256:' + ([BitConverter]::ToString($hash).Replace('-','').ToLowerInvariant())
}
