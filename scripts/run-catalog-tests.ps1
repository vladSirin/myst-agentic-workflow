# run-catalog-tests.ps1 -- the README skill catalog must not drift from the tree.
#
# WHY. The catalog is organised by who invokes a skill: one section for the ones you type,
# one for the ones the agent reaches for on its own. Which section a skill belongs in is a
# DERIVED fact (its disable-model-invocation frontmatter), and derived facts that are typed
# by hand rot. When the invocation axis was first added, the catalog listed 26 of 31 skills:
# the five team-process skills were described in prose and never catalogued, and nothing
# noticed. Same class of drift the suite-count badge already guards.
#
# Three assertions, all derived from the tree, never from a hand-written list:
#   1. every skill directory appears in the catalog, and every catalog row is a real skill
#   2. each skill sits in the section its frontmatter says it belongs in
#   3. the user-invoked set equals setup-devkit.ps1's $ManualSkills -- the OpenCode ask-map
#      that restores the gate on the one tool that ignores the frontmatter key
#
#   exit 0 : catalog agrees with the tree
#   exit 1 : drift
param()
$ErrorActionPreference = 'Stop'
$pkg    = (Resolve-Path "$PSScriptRoot\..").Path
$skills = Join-Path $pkg 'plugins\myst-dev-kit\skills'

$pass = 0; $fail = 0
function Ok($n)     { Write-Output "[PASS] $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "[FAIL] $n : $w"; $script:fail++ }

Write-Output "=============================================================="
Write-Output "README catalog vs tree"
Write-Output "=============================================================="

# --- truth: the tree ---
$tree = @{}
foreach ($d in Get-ChildItem $skills -Directory) {
    $fm = (Get-Content (Join-Path $d.FullName 'SKILL.md') -Raw) -split '---', 3
    $tree[$d.Name] = if ($fm[1] -match '(?m)^disable-model-invocation:\s*true') { 'user' } else { 'model' }
}

# --- claim: the catalog, read section by section ---
# A row's section is whichever "Skills you invoke" / "Skills the agent reaches for" heading
# most recently preceded it, so moving a row between sections is what the test sees.
$rows = @{}
$section = $null
foreach ($line in (Get-Content (Join-Path $pkg 'README.md'))) {
    if ($line -match '^####\s+Skills you invoke')          { $section = 'user';  continue }
    if ($line -match '^####\s+Skills the agent reaches for'){ $section = 'model'; continue }
    if ($line -match '^###\s' -and $line -notmatch '^####') { $section = $null;   continue }
    if ($section -and $line -match '^\| \[`/([a-z0-9-]+)`\]\(') { $rows[$Matches[1]] = $section }
}

# 1. coverage, both directions
$missing = @($tree.Keys | Where-Object { -not $rows.ContainsKey($_) })
$extra   = @($rows.Keys | Where-Object { -not $tree.ContainsKey($_) })
if ($missing.Count -eq 0 -and $extra.Count -eq 0) { Ok "every skill is catalogued ($($tree.Count))" }
else { Bad 'catalog coverage' "uncatalogued: $($missing -join ', ') | no such skill: $($extra -join ', ')" }

# 2. section membership matches frontmatter
$wrong = @($rows.Keys | Where-Object { $tree.ContainsKey($_) -and $tree[$_] -ne $rows[$_] } |
           ForEach-Object { "$_ (listed under '$($rows[$_])', frontmatter says '$($tree[$_])')" })
if ($wrong.Count -eq 0) {
    $u = @($tree.Keys | Where-Object { $tree[$_] -eq 'user' }).Count
    Ok "every skill is in the right section ($u user-invoked, $($tree.Count - $u) model-invoked)"
} else { Bad 'section membership' ($wrong -join '; ') }

# 3. user-invoked set == setup-devkit's OpenCode ask-map
$blk = [regex]::Match((Get-Content (Join-Path $pkg 'setup-devkit.ps1') -Raw),
                      '(?s)\$ManualSkills\s*=\s*@\((.*?)\)').Groups[1].Value
$manual  = @([regex]::Matches($blk, "'([a-z0-9-]+)'") | ForEach-Object { $_.Groups[1].Value })
$userSet = @($tree.Keys | Where-Object { $tree[$_] -eq 'user' })
$onlyManual = @($manual  | Where-Object { $userSet -notcontains $_ })
$onlyUser   = @($userSet | Where-Object { $manual  -notcontains $_ })
if ($onlyManual.Count -eq 0 -and $onlyUser.Count -eq 0) { Ok "user-invoked set == `$ManualSkills ($($userSet.Count))" }
else { Bad 'ManualSkills lockstep' "only in ManualSkills: $($onlyManual -join ', ') | only user-invoked: $($onlyUser -join ', ')" }

Write-Output ""
Write-Output "=============================================================="
Write-Output "Catalog tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 }
exit 0
