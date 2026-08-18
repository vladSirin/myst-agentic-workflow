<#
.SYNOPSIS
  Measure how many reviewer rounds real reviews actually took.

.DESCRIPTION
  The re-review rules in skills/review-and-submit/RE-REVIEW.md exist to shorten review
  loops by removing causes of rounds. This reports whether that happened, from Claude
  Code transcripts rather than from anyone's recollection.

  Counting unit: rounds PER REVIEWER, not invocations. Two reviewers run per round on a
  mixed change, so raw invocation counts overstate rounds by ~2x -- an error made and
  corrected during 4.38.0's design ("CL 2334 ran 10 passes" was really 4 rounds).
  A subject's round count is the max across its reviewers.

.PARAMETER TranscriptRoot
  Claude Code project transcript dir. Defaults to every project under ~/.claude/projects.

.PARAMETER Since
  Only count transcripts modified on/after this date. Use it to compare before/after.

.PARAMETER SelfTest
  Run the parser assertions and exit. No transcripts are read.

.NOTES
  Known limits, stated rather than hidden:
    - Subject extraction is a heuristic (a CL number in the reviewer prompt). Reviews of
      documents with no CL number are grouped under their doc name if one is present,
      and skipped otherwise.
    - A reviewer invocation that died on an API error still counts. Six such retries
      inflated one CL's raw count during 4.38.0's measurement.
  Both make the number an upper bound. A falling upper bound is still a falling trend.
#>
[CmdletBinding()]
param(
    [string]   $TranscriptRoot,
    [datetime] $Since,
    [switch]   $SelfTest
)

$REVIEWERS = 'architecture-reviewer', 'radical-design-critic'

function Get-Invocations {
    param([string[]] $Lines)
    $out = @()
    foreach ($line in $Lines) {
        # cheap prefilter, then parse -- a reviewer NAME appearing in prose is not an
        # invocation. Matching the name instead of the subagent_type VALUE was this
        # script's own first defect: it read CL 2334 as 10 rounds against a hand-verified 4,
        # because prompts discussing that review also name the reviewer.
        if ($line -notmatch '"subagent_type"') { continue }
        try { $obj = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
        foreach ($call in (Find-AgentCalls -Node $obj)) {
            $type = [string]$call.subagent_type
            $r = $REVIEWERS | Where-Object { $type -match "(^|:)$([regex]::Escape($_))$" }
            if (-not $r) { continue }
            $text = "$($call.prompt) $($call.description)"
            $subject = $null
            if     ($text -match '(?i)\bCL\s*#?\s*(\d{3,7})\b')         { $subject = "CL $($Matches[1])" }
            elseif ($text -match '(?i)\bchangelist\s*#?\s*(\d{3,7})\b') { $subject = "CL $($Matches[1])" }
            elseif ($text -match '([A-Za-z0-9_\-]+\.md)')               { $subject = $Matches[1] }
            if ($subject) { $out += [pscustomobject]@{ Subject = $subject; Reviewer = $r[0] } }
        }
    }
    return $out
}

function Find-AgentCalls {
    # walk the transcript record for any object carrying a subagent_type field
    param($Node, [int] $Depth = 0)
    if ($null -eq $Node -or $Depth -gt 8) { return }
    if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        foreach ($item in $Node) { Find-AgentCalls -Node $item -Depth ($Depth + 1) }
        return
    }
    if ($Node -is [psobject]) {
        $names = $Node.PSObject.Properties.Name
        if ($names -contains 'subagent_type') { $Node; return }
        foreach ($prop in $Node.PSObject.Properties) {
            Find-AgentCalls -Node $prop.Value -Depth ($Depth + 1)
        }
    }
}

function Get-Rounds {
    param($Invocations)
    # rounds per reviewer, then max across reviewers -- never the raw invocation total
    $Invocations | Group-Object Subject | ForEach-Object {
        $perReviewer = $_.Group | Group-Object Reviewer | ForEach-Object { $_.Count }
        [pscustomobject]@{
            Subject     = $_.Name
            Rounds      = ($perReviewer | Measure-Object -Maximum).Maximum
            Reviewers   = ($_.Group | Group-Object Reviewer).Count
            Invocations = $_.Count
        }
    }
}

if ($SelfTest) {
    $mk = {
        param($type, $prompt)
        (@{ message = @{ content = @(@{ type='tool_use'; name='Agent';
             input = @{ subagent_type = $type; prompt = $prompt } }) } } | ConvertTo-Json -Depth 8 -Compress)
    }
    $fixture = @(
        (& $mk 'myst-dev-kit:architecture-reviewer'  'Review CL 2334')
        (& $mk 'myst-dev-kit:radical-design-critic'  'Review CL 2334')
        (& $mk 'myst-dev-kit:architecture-reviewer'  'SECOND PASS CL 2334')
        (& $mk 'myst-dev-kit:radical-design-critic'  'SECOND PASS CL 2334')
        (& $mk 'myst-dev-kit:architecture-reviewer'  'Review CL 2306')
        (& $mk 'scout' 'go read what radical-design-critic said about CL 9999')
        '{"text":"we should review CL 9999 sometime"}'
    )
    $inv = Get-Invocations -Lines $fixture
    if ($inv.Count -ne 5) { throw "SelfTest: expected 5 invocations, got $($inv.Count)" }

    $rounds = Get-Rounds -Invocations $inv
    $cl2334 = $rounds | Where-Object Subject -eq 'CL 2334'
    # 4 invocations, 2 reviewers, 2 rounds each -> 2 rounds, NOT 4. This is the whole point.
    if ($cl2334.Rounds      -ne 2) { throw "SelfTest: CL 2334 rounds expected 2, got $($cl2334.Rounds)" }
    if ($cl2334.Invocations -ne 4) { throw "SelfTest: CL 2334 invocations expected 4, got $($cl2334.Invocations)" }
    $cl2306 = $rounds | Where-Object Subject -eq 'CL 2306'
    if ($cl2306.Rounds -ne 1) { throw "SelfTest: CL 2306 rounds expected 1, got $($cl2306.Rounds)" }
    if ($rounds | Where-Object Subject -eq 'CL 9999') { throw "SelfTest: a non-reviewer agent whose PROMPT names a reviewer must not count" }

    Write-Host "SelfTest: OK - rounds counted per reviewer, not per invocation"
    exit 0
}

if (-not $TranscriptRoot) { $TranscriptRoot = Join-Path $HOME '.claude\projects' }
if (-not (Test-Path $TranscriptRoot)) { Write-Error "No transcripts at $TranscriptRoot"; exit 1 }

$files = Get-ChildItem -Path $TranscriptRoot -Filter *.jsonl -Recurse -ErrorAction SilentlyContinue
if ($Since) { $files = $files | Where-Object { $_.LastWriteTime -ge $Since } }
if (-not $files) { Write-Host "No transcripts in scope."; exit 0 }

$all = @()
foreach ($f in $files) {
    $all += Get-Invocations -Lines (Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue)
}
if (-not $all) { Write-Host "No reviewer invocations found in $($files.Count) transcript(s)."; exit 0 }

$rounds = Get-Rounds -Invocations $all | Sort-Object Rounds -Descending
$multi  = @($rounds | Where-Object Rounds -gt 1)

Write-Host ""
Write-Host "Reviewed subjects: $($rounds.Count)   multi-round: $($multi.Count)   transcripts: $($files.Count)"
if ($Since) { Write-Host "Since: $($Since.ToString('yyyy-MM-dd'))" }
Write-Host ""
$rounds | Format-Table Subject, Rounds, Reviewers, Invocations -AutoSize | Out-String | Write-Host

if ($multi.Count) {
    $sorted = @($multi.Rounds | Sort-Object)
    $median = if ($sorted.Count % 2) { $sorted[[math]::Floor($sorted.Count/2)] }
              else { ($sorted[$sorted.Count/2 - 1] + $sorted[$sorted.Count/2]) / 2 }
    Write-Host "MEDIAN ROUNDS (multi-round subjects only): $median   n=$($multi.Count)"
    Write-Host "PRE-4.38.0 BASELINE: median 3, n=39 multi-round subjects (measured 2026-08-18)."
    Write-Host "Compare against 3 -- NOT against the '4-6' in the 4.38.0 notes. That figure came"
    Write-Host "from the three worst loops a hand sweep chose to examine, not from the median."
    if ($multi.Count -lt 10) {
        Write-Host "n < 10 -- not yet the sample the 4.38.0 plan pre-committed to. Keep going."
    }
} else {
    Write-Host "No multi-round subjects in scope -- nothing to compare yet."
}
Write-Host ""
Write-Host "Upper bound: API-error retries and re-reviews of the same subject across"
Write-Host "sessions both inflate these counts. A falling upper bound is still a falling trend."
