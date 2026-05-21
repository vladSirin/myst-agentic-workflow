# Render.ps1 — shared render pipeline (issue 10)
#
# Single source of truth for "what does a template render to, when installed
# into this target project?" Used by install.ps1 (to write) and
# compare-with-package.ps1 (to read-and-diff). Same pipeline on both sides
# guarantees install + compare see identical bytes.
#
# Pipeline per entry:
#   1. Load template/overlay file from $PackageRoot / entry.sourceTemplate
#   2. Strip UTF-8 BOM, normalize CRLF/CR to LF
#   3. Apply {{var}} substitution via Expand-TemplateVars
#   4. Strategy-specific composition:
#      - copy             -> rendered template is the whole file
#      - generated-block  -> splice rendered text between markers in target;
#                            require markers to exist (no EOF-append)
#      - append-fragment  -> Set-AppendFragment (EOF-append on first install;
#                            in-place replace on re-install)

# Note: this library does NOT set strict mode -- each consumer opts in.

. (Join-Path $PSScriptRoot 'Markers.ps1')

# Build the substitution variable map from a parsed manifest.
# Adds vars from installedProject. Robust to missing fields.
function Get-VariableMap {
    param([Parameter(Mandatory)] $Manifest)
    $ip = $null
    if ($Manifest.PSObject.Properties.Match('installedProject').Count -gt 0) {
        $ip = $Manifest.installedProject
    }
    $map = @{}
    foreach ($pair in @(
        @{ Key='project_name';   Field='name'          }
        @{ Key='docs_root';      Field='docsRoot'      }
        @{ Key='game_docs_root'; Field='gameDocsRoot'  }
    )) {
        $val = $null
        if ($ip -and $ip.PSObject.Properties.Match($pair.Field).Count -gt 0) {
            $val = $ip.($pair.Field)
        }
        if ($null -ne $val) { $map[$pair.Key] = [string]$val }
    }
    return $map
}

# Reverse of Expand-TemplateVars: replace each concrete value with its {{var}}
# placeholder. Used by promote-from-project.ps1 to turn disk content into a
# package-installable template. Round-trip safety is the caller's responsibility:
# render the result back forward and verify it equals the original disk content.
function Reverse-SubstituteVars {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string] $Text,
        [Parameter(Mandatory)][hashtable] $Vars
    )
    # Sort keys by descending value length so longer values substitute first
    # (prevents a prefix match clobbering a longer var that contains it).
    $ordered = @($Vars.Keys | Sort-Object -Property @{Expression={([string]$Vars[$_]).Length}; Descending=$true})
    foreach ($k in $ordered) {
        $val = [string]$Vars[$k]
        if (-not [string]::IsNullOrEmpty($val)) {
            $Text = $Text.Replace($val, "{{$k}}")
        }
    }
    return $Text
}

function Resolve-EntryTemplate {
    param([Parameter(Mandatory)] $Entry, [Parameter(Mandatory)][string] $PackageRoot)
    if ($Entry.PSObject.Properties.Match('sourceTemplate').Count -eq 0) { return $null }
    $st = $Entry.sourceTemplate
    if ([string]::IsNullOrEmpty($st)) { return $null }
    return (Join-Path $PackageRoot $st)
}

# Render a single entry: returns the bytes that should appear at $entry.path
# under $TargetRoot after install. Returns $null if no template is resolvable
# (e.g., manual-only entries, missing sourceTemplate).
function Get-EntryRendered {
    param(
        [Parameter(Mandatory)] $Entry,
        [Parameter(Mandatory)][string] $PackageRoot,
        [Parameter(Mandatory)][string] $TargetRoot,
        [Parameter(Mandatory)][hashtable] $Vars
    )
    $tplPath = Resolve-EntryTemplate -Entry $Entry -PackageRoot $PackageRoot
    if (-not $tplPath -or -not (Test-Path -LiteralPath $tplPath)) { return $null }

    $tplBytes = [IO.File]::ReadAllBytes($tplPath)
    if ($tplBytes.Length -ge 3 -and $tplBytes[0] -eq 0xEF -and $tplBytes[1] -eq 0xBB -and $tplBytes[2] -eq 0xBF) {
        $tplBytes = $tplBytes[3..($tplBytes.Length - 1)]
    }
    $tplText = [Text.Encoding]::UTF8.GetString($tplBytes)
    $tplText = ($tplText -replace "`r`n","`n") -replace "`r","`n"
    $rendered = Expand-TemplateVars -Text $tplText -Vars $Vars

    $tgt = Join-Path $TargetRoot $Entry.path

    switch ($Entry.mergeStrategy) {
        'copy' { return $rendered }
        'generated-block' {
            if (-not (Test-Path -LiteralPath $tgt)) { return $rendered }
            $current = Read-NormalizedText -Path $tgt
            $style   = Get-MarkerStyleForPath -Path $tgt
            # generated-block: refuse EOF-append if markers absent (WARNING-3)
            try { $null = Resolve-MarkerSpan -NormalizedText $current -Id $Entry.generatedBlockId -Style $style }
            catch [MarkerAmbiguityException] {
                throw "generated-block target '$($Entry.path)' has marker ambiguity ($($_.Exception.Category)); refusing to render."
            }
            return Set-AppendFragment -NormalizedText $current -Id $Entry.generatedBlockId -FragmentText $rendered -Style $style
        }
        'append-fragment' {
            if (-not (Test-Path -LiteralPath $tgt)) { return $null }
            $current = Read-NormalizedText -Path $tgt
            $style   = Get-MarkerStyleForPath -Path $tgt
            return Set-AppendFragment -NormalizedText $current -Id $Entry.appendFragmentId -FragmentText $rendered -Style $style
        }
        default { return $null }
    }
}
