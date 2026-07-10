# run-classification-tests.ps1 — Ownership bucket verification (issue 09)
#
#   exit 0 : all checks pass
#   exit 1 : one or more checks failed
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Classification.ps1')

$pass = 0; $fail = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }

# Synthesize entries via pscustomobject; only relevant fields matter.
function Mk { param([hashtable] $h) [pscustomobject]$h }

# 1. Each bucket is reachable from a minimal entry.
$tests = @(
    @{ Name='local-only via localOnly';            Entry=Mk @{ localOnly=$true; ownerOverlay='core'; owner='package' }; Expected='local-only' }
    @{ Name='project-owned via manual-only';       Entry=Mk @{ mergeStrategy='manual-only'; ownerOverlay='core'; owner='package' }; Expected='project-owned' }
    @{ Name='project-owned via human-owned';       Entry=Mk @{ writablePolicy='human-owned'; ownerOverlay='core'; owner='package' }; Expected='project-owned' }
    @{ Name='project-owned via owner=project';     Entry=Mk @{ owner='project'; ownerOverlay='myst-project' }; Expected='project-owned' }
    @{ Name='package-core via core+package';       Entry=Mk @{ ownerOverlay='core'; owner='package'; mergeStrategy='copy' }; Expected='package-core' }
    @{ Name='overlay via myst-project';            Entry=Mk @{ ownerOverlay='myst-project'; owner='overlay'; mergeStrategy='copy' }; Expected='overlay' }
    @{ Name='overlay via perforce';                Entry=Mk @{ ownerOverlay='perforce'; owner='overlay'; mergeStrategy='copy' }; Expected='overlay' }
    @{ Name='overlay via tool-capability';         Entry=Mk @{ ownerOverlay='tool-capability'; owner='overlay'; mergeStrategy='manual-only' }; Expected='project-owned' }  # manual-only wins
)
foreach ($t in $tests) {
    $got = Get-OwnershipBucket $t.Entry
    if ($got -eq $t.Expected) { Ok $t.Name } else { Bad $t.Name "expected $($t.Expected) got $got" }
}

# 2. Priority: localOnly beats every other signal (even manual-only + project owner).
$prio = Mk @{ localOnly=$true; mergeStrategy='manual-only'; owner='project'; ownerOverlay='myst-project' }
if ((Get-OwnershipBucket $prio) -eq 'local-only') { Ok 'priority: localOnly beats all other gates' }
else { Bad 'priority: localOnly' "got $(Get-OwnershipBucket $prio)" }

# 3. Priority: project-owned beats overlay/core when both apply (e.g., owner=project in any overlay).
$prio2 = Mk @{ owner='project'; ownerOverlay='core' }
if ((Get-OwnershipBucket $prio2) -eq 'project-owned') { Ok 'priority: project-owned beats core' }
else { Bad 'priority: project-owned vs core' "got $(Get-OwnershipBucket $prio2)" }

# 4. Empty/missing field robustness: an entry with only the required fields still classifies.
$empty = Mk @{ ownerOverlay='core' }
if ((Get-OwnershipBucket $empty) -eq 'package-core') { Ok 'robust: minimal entry (core, no other fields) -> package-core' }
else { Bad 'robust: minimal core entry' "got $(Get-OwnershipBucket $empty)" }

# 5. Mutual exclusivity: every entry maps to exactly one bucket (4 buckets, set of valid values).
$valid = @('local-only','project-owned','package-core','overlay')
$all = @()
foreach ($t in $tests) { $all += Get-OwnershipBucket $t.Entry }
$invalid = @($all | Where-Object { $_ -notin $valid })
if ($invalid.Count -eq 0) { Ok 'mutual exclusivity: all results in the 4-bucket set' }
else { Bad 'mutual exclusivity' "$($invalid.Count) entries outside the set: $($invalid -join ',')" }

# 6. Total partition: classify every entry in the real installed manifest and
#    assert no entry returns $null and every result is in the bucket set.
$realManifest = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'UE_Blank_Proto\Docs\agents\scaffold-manifest.json'
# Path may not exist in CI; skip this check gracefully.
if (Test-Path -LiteralPath $realManifest) {
    $raw = [IO.File]::ReadAllBytes($realManifest)
    if ($raw.Length -ge 3 -and $raw[0] -eq 0xEF) { $raw = $raw[3..($raw.Length-1)] }
    $m = [System.Text.Encoding]::UTF8.GetString($raw) | ConvertFrom-Json
    $bucketCounts = @{ 'local-only'=0; 'project-owned'=0; 'package-core'=0; 'overlay'=0 }
    $unclassified = @()
    foreach ($e in $m.files) {
        if ((Get-EntryProperty $e 'hashPolicy') -eq 'self-excluded') { continue }   # manifest self-entry
        $b = Get-OwnershipBucket $e
        if ($null -eq $b -or $b -notin $valid) { $unclassified += $e.path; continue }
        $bucketCounts[$b]++
    }
    if ($unclassified.Count -eq 0) {
        $total = ($bucketCounts.Values | Measure-Object -Sum).Sum
        $detail = ($bucketCounts.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' '
        Ok "real manifest: every entry classified ($total total; $detail)"
    } else {
        Bad 'real manifest: total partition' "$($unclassified.Count) unclassified: $($unclassified -join '; ')"
    }
}
else {
    Write-Output "  SKIP  real manifest test (no live manifest at $realManifest)"
}

# 7. Get-PromotionTarget returns the manifest sourceTemplate when present.
$pt = Mk @{ ownerOverlay='core'; owner='package'; mergeStrategy='copy'; sourceTemplate='templates/codex/AGENTS.md' }
$target = Get-PromotionTarget $pt
if ($target -eq 'templates/codex/AGENTS.md') { Ok 'Get-PromotionTarget: returns sourceTemplate' }
else { Bad 'Get-PromotionTarget: sourceTemplate' "got $target" }

# 8. Get-PromotionTarget returns $null for non-promotable buckets.
$loc = Mk @{ localOnly=$true; sourceTemplate='ignored' }
if ((Get-PromotionTarget $loc) -eq $null) { Ok 'Get-PromotionTarget: returns null for local-only' }
else { Bad 'Get-PromotionTarget: local-only' "should be null" }

# 8b. Fallback (no sourceTemplate), package-core: strips the per-tool dir and
#     lands in the shared source at plugins/myst-dev-kit/ (both tools -> same file).
$fbClaude = Mk @{ ownerOverlay='core'; owner='package'; mergeStrategy='copy'; tool='claude'; path='.claude/skills/x/SKILL.md' }
$fbCodex  = Mk @{ ownerOverlay='core'; owner='package'; mergeStrategy='copy'; tool='codex';  path='.Codex/skills/x/SKILL.md' }
if ((Get-PromotionTarget $fbClaude) -eq 'plugins/myst-dev-kit/skills/x/SKILL.md' -and
    (Get-PromotionTarget $fbCodex)  -eq 'plugins/myst-dev-kit/skills/x/SKILL.md') {
    Ok 'Get-PromotionTarget: core fallback strips tool dir -> plugins/myst-dev-kit/ (both tools converge)'
} else { Bad 'Get-PromotionTarget: core fallback' "claude=$(Get-PromotionTarget $fbClaude) codex=$(Get-PromotionTarget $fbCodex)" }

# 8c. Fallback, overlay bucket: same strip, lands in overlays/<name>/.
$fbOv = Mk @{ ownerOverlay='perforce'; owner='overlay'; mergeStrategy='copy'; tool='claude'; path='.claude/workflows/ReviewAndSubmit.md' }
if ((Get-PromotionTarget $fbOv) -eq 'overlays/perforce/workflows/ReviewAndSubmit.md') {
    Ok 'Get-PromotionTarget: overlay fallback strips tool dir'
} else { Bad 'Get-PromotionTarget: overlay fallback' "got $(Get-PromotionTarget $fbOv)" }

# 9. Test-IsPromotable
if ((Test-IsPromotable 'package-core') -and (Test-IsPromotable 'overlay') -and -not (Test-IsPromotable 'local-only') -and -not (Test-IsPromotable 'project-owned')) {
    Ok 'Test-IsPromotable: correct for all 4 buckets'
} else { Bad 'Test-IsPromotable' 'wrong for one of the 4 buckets' }

Write-Output ""
Write-Output "=============================================================="
Write-Output "Classification tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
