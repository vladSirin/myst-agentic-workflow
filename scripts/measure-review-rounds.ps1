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

  A round is a reviewer SPAWN or a RESUMPTION. Re-reviewing by SendMessage to a live
  reviewer is a round -- it costs a pass and preserves the reviewer's context, so it is
  the cheaper way to iterate and the tail concentrates there. Counting spawns only read
  a hand-verified 9-round review of CL 2601 as 2 rounds (measured 2026-08-24), which
  inverted this script's own error model: for a resumed review the count was a LOWER
  bound, not an upper one.

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
    - Resumption is resolved WITHIN a transcript. A review resumed in a later session
      cannot be linked to its spawn, so cross-session re-reviews still undercount.
  The first two inflate; the third deflates. The number is no longer a clean bound in
  either direction -- say which way a given comparison could be wrong, do not assert
  'upper bound' as this file used to.
#>
[CmdletBinding()]
param(
    [string]   $TranscriptRoot,
    [datetime] $Since,
    [switch]   $SelfTest
)

$REVIEWERS = 'architecture-reviewer', 'radical-design-critic'

function Get-Subject {
    param([string] $Text)
    if     ($Text -match '(?i)\bCL\s*#?\s*(\d{3,7})\b')         { return "CL $($Matches[1])" }
    elseif ($Text -match '(?i)\bchangelist\s*#?\s*(\d{3,7})\b') { return "CL $($Matches[1])" }
    elseif ($Text -match '([A-Za-z0-9_\-]+\.md)')               { return $Matches[1] }
    return $null
}

function Find-ToolUses {
    # walk a transcript record for tool_use nodes -- they carry both `name` and `input`
    param($Node, [int] $Depth = 0)
    if ($null -eq $Node -or $Depth -gt 8) { return }
    if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        foreach ($item in $Node) { Find-ToolUses -Node $item -Depth ($Depth + 1) }
        return
    }
    if ($Node -is [psobject]) {
        $names = $Node.PSObject.Properties.Name
        if (($names -contains 'name') -and ($names -contains 'input')) { $Node; return }
        foreach ($prop in $Node.PSObject.Properties) {
            Find-ToolUses -Node $prop.Value -Depth ($Depth + 1)
        }
    }
}

function Find-ToolResults {
    param($Node, [int] $Depth = 0)
    if ($null -eq $Node -or $Depth -gt 8) { return }
    if ($Node -is [System.Collections.IEnumerable] -and $Node -isnot [string]) {
        foreach ($item in $Node) { Find-ToolResults -Node $item -Depth ($Depth + 1) }
        return
    }
    if ($Node -is [psobject]) {
        if ($Node.PSObject.Properties.Name -contains 'tool_use_id') { $Node; return }
        foreach ($prop in $Node.PSObject.Properties) {
            Find-ToolResults -Node $prop.Value -Depth ($Depth + 1)
        }
    }
}

function Get-Invocations {
    param([string[]] $Lines)
    $out      = [System.Collections.Generic.List[object]]::new()
    $byId     = @{}   # spawn tool_use id  -> invocation record
    $byHandle = @{}   # agent name/agentId -> invocation record

    $objs = [System.Collections.Generic.List[object]]::new()
    foreach ($line in $Lines) {
        # cheap prefilter. SendMessage and agentId join subagent_type here because a
        # RESUMED reviewer is a round and its record carries neither of the other two.
        if ($line -notmatch '"subagent_type"|SendMessage|agentId') { continue }
        try { $objs.Add(($line | ConvertFrom-Json -ErrorAction Stop)) } catch { continue }
    }

    # -- pass 1: reviewer SPAWNS. Match the subagent_type VALUE, never the reviewer
    # name: a name appearing in prose is not an invocation. That was this script's own
    # first defect (it read CL 2334 as 10 rounds against a hand-verified 4).
    foreach ($obj in $objs) {
        foreach ($tu in (Find-ToolUses -Node $obj)) {
            $in = $tu.input
            if ($null -eq $in) { continue }
            if ($in.PSObject.Properties.Name -notcontains 'subagent_type') { continue }
            $type = [string]$in.subagent_type
            $r = $REVIEWERS | Where-Object { $type -match "(^|:)$([regex]::Escape($_))$" }
            if (-not $r) { continue }
            $subject = Get-Subject "$($in.prompt) $($in.description)"
            if (-not $subject) { continue }
            $rec = [pscustomobject]@{ Subject = $subject; Reviewer = [string](@($r)[0]) }
            $out.Add($rec)
            if ($tu.id)   { $byId[[string]$tu.id]       = $rec }
            if ($in.name) { $byHandle[[string]$in.name] = $rec }
        }
    }

    # -- pass 2: learn each spawn's agentId from its own tool_result, so a resumption
    # addressed by raw id resolves as well as one addressed by the agent's name.
    if ($byId.Count) {
        foreach ($obj in $objs) {
            foreach ($tr in (Find-ToolResults -Node $obj)) {
                $id = [string]$tr.tool_use_id
                if (-not $byId.ContainsKey($id)) { continue }
                $txt = $tr | ConvertTo-Json -Depth 8 -Compress
                foreach ($m in [regex]::Matches($txt, 'agentId\W+([A-Za-z0-9_-]{8,})')) {
                    $byHandle[$m.Groups[1].Value] = $byId[$id]
                }
            }
        }
    }

    # -- pass 3: RESUMPTIONS. A SendMessage to a live reviewer is another round on the
    # same subject -- same reviewer, same CL, one more pass -- and it is the CHEAPER way
    # to re-review, so the tail concentrates here. Counting spawns alone read a 9-round
    # review of CL 2601 as 2 rounds (measured 2026-08-24). The subject is inherited from
    # the spawn rather than re-parsed: a resumption is by definition the same review, and
    # its message text need not name the CL.
    if ($byHandle.Count) {
        foreach ($obj in $objs) {
            foreach ($tu in (Find-ToolUses -Node $obj)) {
                if ([string]$tu.name -ne 'SendMessage') { continue }
                $to = [string]$tu.input.to
                if ($to -and $byHandle.ContainsKey($to)) { $out.Add($byHandle[$to]) }
            }
        }
    }

    return $out.ToArray()
}

function Get-Rounds {
    param($Invocations)
    # rounds per reviewer, then max across reviewers -- never the raw invocation total
    $Invocations | Group-Object Subject | ForEach-Object {
        $perReviewer = $_.Group | Group-Object Reviewer | ForEach-Object { $_.Count }
        [pscustomobject]@{
            Subject     = $_.Name
            Rounds      = ($perReviewer | Measure-Object -Maximum).Maximum
            Reviewers   = @($_.Group | Group-Object Reviewer).Count
            Invocations = $_.Count
        }
    }
}

if ($SelfTest) {
    $mk = {
        param($type, $prompt, $agentName, $useId)
        (@{ message = @{ content = @(@{ type='tool_use'; name='Agent'; id = $useId;
             input = @{ subagent_type = $type; prompt = $prompt; name = $agentName } }) } } | ConvertTo-Json -Depth 8 -Compress)
    }
    $mkSend = {
        param($to)
        (@{ message = @{ content = @(@{ type='tool_use'; name='SendMessage';
             input = @{ to = $to; message = 'RE-REVIEW next pass' } }) } } | ConvertTo-Json -Depth 8 -Compress)
    }
    $mkResult = {
        param($useId, $text)
        (@{ message = @{ content = @(@{ type='tool_result'; tool_use_id = $useId; content = $text }) } } | ConvertTo-Json -Depth 8 -Compress)
    }
    $fixture = @(
        (& $mk 'myst-dev-kit:architecture-reviewer'  'Review CL 2334')
        (& $mk 'myst-dev-kit:radical-design-critic'  'Review CL 2334')
        (& $mk 'myst-dev-kit:architecture-reviewer'  'SECOND PASS CL 2334')
        (& $mk 'myst-dev-kit:radical-design-critic'  'SECOND PASS CL 2334')
        (& $mk 'myst-dev-kit:architecture-reviewer'  'Review CL 2306')
        (& $mk 'scout' 'go read what radical-design-critic said about CL 9999')
        '{"text":"we should review CL 9999 sometime"}'
        # A RESUMED reviewer -- the case that made a 9-round review report as 2.
        # One spawn, two SendMessage rounds by NAME, one more by raw agentId = 4 rounds.
        (& $mk 'myst-dev-kit:architecture-reviewer' 'Review CL 2601' 'arch-2601' 'tu_2601')
        (& $mkSend 'arch-2601')
        (& $mkSend 'arch-2601')
        (& $mkResult 'tu_2601' 'agentId: a7185f0f325d67b4f (use SendMessage to continue)')
        (& $mkSend 'a7185f0f325d67b4f')
        (& $mkSend 'scout-helper')
    )
    $inv = Get-Invocations -Lines $fixture
    if ($inv.Count -ne 9) { throw "SelfTest: expected 9 invocations, got $($inv.Count)" }

    $rounds = Get-Rounds -Invocations $inv
    $cl2334 = $rounds | Where-Object Subject -eq 'CL 2334'
    # 4 invocations, 2 reviewers, 2 rounds each -> 2 rounds, NOT 4. This is the whole point.
    if ($cl2334.Rounds      -ne 2) { throw "SelfTest: CL 2334 rounds expected 2, got $($cl2334.Rounds)" }
    if ($cl2334.Invocations -ne 4) { throw "SelfTest: CL 2334 invocations expected 4, got $($cl2334.Invocations)" }
    $cl2306 = $rounds | Where-Object Subject -eq 'CL 2306'
    if ($cl2306.Rounds -ne 1) { throw "SelfTest: CL 2306 rounds expected 1, got $($cl2306.Rounds)" }
    if ($rounds | Where-Object Subject -eq 'CL 9999') { throw "SelfTest: a non-reviewer agent whose PROMPT names a reviewer must not count" }

    $cl2601 = $rounds | Where-Object Subject -eq 'CL 2601'
    if ($cl2601.Rounds -ne 4) { throw "SelfTest: CL 2601 rounds expected 4 (1 spawn + 2 by name + 1 by agentId), got $($cl2601.Rounds)" }
    if ($byHandleLeak = $rounds | Where-Object Subject -eq 'scout-helper') { throw "SelfTest: SendMessage to a NON-reviewer must not count" }

    Write-Host "SelfTest: OK - rounds counted per reviewer, spawns AND resumptions"
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
Write-Host "Bounds run BOTH ways: API-error retries inflate, and a review resumed in a"
Write-Host "later session cannot be linked to its spawn, which deflates. Rounds now count"
Write-Host "reviewer SPAWNS and RESUMPTIONS (SendMessage to a live reviewer). Counts from"
Write-Host "before 2026-08-24 were spawn-only and undercount every resumed review."
