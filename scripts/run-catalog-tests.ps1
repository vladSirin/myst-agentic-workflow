# run-catalog-tests.ps1 -- the README skill catalog must not drift from the tree.
#
# WHY. The catalog claims a total ("31 skills total") and lists each skill with an
# invocation marker (user | model). Both are derived facts that were previously typed:
# when the invocation axis was added, the catalog listed 26 of 31 skills -- the five
# process-rule skills had been described in prose and never catalogued, and nothing
# noticed. The same class of drift the suite-count badge already guards.
#
# Three assertions, all derived from the tree, never from a hand-written list:
#   1. every skill directory has a catalog row, and every row has a directory
#   2. each row's invocation marker matches that skill's disable-model-invocation
#      frontmatter (present+true => user-invoked, else model-invoked)
#   3. the user-invoked set equals setup-devkit.ps1's $ManualSkills -- the OpenCode
#      ask-map that restores the gate on a tool which ignores the frontmatter key
#
#   exit 0 : catalog agrees with the tree
#   exit 1 : drift
param()
$ErrorActionPreference = 'Stop'
$pkg    = (Resolve-Path "$PSScriptRoot\..").Path
$skills = Join-Path $pkg 'plugins\myst-dev-kit\skills'
$readme = Get-Content (Join-Path $pkg 'README.md') -Raw

$pass = 0; $fail = 0
function Ok($n)     { Write-Output "[PASS] $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "[FAIL] $n : $w"; $script:fail++ }

Write-Output "=============================================================="
Write-Output "README catalog vs tree"
Write-Output "=============================================================="

# --- derive truth from the tree ---
$tree = @{}
foreach ($d in Get-ChildItem $skills -Directory) {
    $fm = (Get-Content (Join-Path $d.FullName 'SKILL.md') -Raw) -split '---', 3
    $tree[$d.Name] = if ($fm[1] -match '(?m)^disable-model-invocation:\s*true') { 'user' } else { 'model' }
}

# --- parse the catalog ---
$rows = @{}
foreach ($m in [regex]::Matches($readme, '(?m)^\| \[`/([a-z0-9-]+)`\]\([^)]*\) \| (user|model) \|')) {
    $rows[$m.Groups[1].Value] = $m.Groups[2].Value
}

# 1. coverage, both directions
$missing = @($tree.Keys | Where-Object { -not $rows.ContainsKey($_) })
$extra   = @($rows.Keys | Where-Object { -not $tree.ContainsKey($_) })
if ($missing.Count -eq 0 -and $extra.Count -eq 0) { Ok "every skill is catalogued ($($tree.Count))" }
else { Bad 'catalog coverage' "uncatalogued: $($missing -join ', ') | no such skill: $($extra -join ', ')" }

# 2. invocation marker matches frontmatter
$wrong = @($rows.Keys | Where-Object { $tree.ContainsKey($_) -and $tree[$_] -ne $rows[$_] } |
           ForEach-Object { "$_ (README=$($rows[$_]), frontmatter=$($tree[$_]))" })
if ($wrong.Count -eq 0) { Ok 'every invocation marker matches its frontmatter' }
else { Bad 'invocation markers' ($wrong -join '; ') }

# 3. user-invoked set == setup-devkit's OpenCode ask-map
$sd  = Get-Content (Join-Path $pkg 'setup-devkit.ps1') -Raw
$blk = [regex]::Match($sd, '(?s)\$ManualSkills\s*=\s*@\((.*?)\)').Groups[1].Value
$manual = @([regex]::Matches($blk, "'([a-z0-9-]+)'") | ForEach-Object { $_.Groups[1].Value })
$userSet = @($tree.Keys | Where-Object { $tree[$_] -eq 'user' })
$onlyManual = @($manual | Where-Object { $userSet -notcontains $_ })
$onlyUser   = @($userSet | Where-Object { $manual -notcontains $_ })
if ($onlyManual.Count -eq 0 -and $onlyUser.Count -eq 0) { Ok "user-invoked set == `$ManualSkills ($($userSet.Count))" }
else { Bad 'ManualSkills lockstep' "only in ManualSkills: $($onlyManual -join ', ') | only user-invoked: $($onlyUser -join ', ')" }

Write-Output ""
Write-Output "=============================================================="
Write-Output "Catalog tests: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 }
exit 0
