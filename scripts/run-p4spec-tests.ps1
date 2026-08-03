# run-p4spec-tests.ps1 -- installer change-spec construction
#
# Covers the two defects that made install.ps1's CL creation unsafe, plus the
# behaviour that actually matters (a new CL does not inherit the default one).
#
# Why a unit test rather than a live `-Mode Write` run: the CL-creation code sits
# inside the `else` of `if ($Changes.Count -eq 0)`, so a no-op install never
# creates a changelist and never exercises the fix. Reaching it live requires an
# install that genuinely overwrites consumer files -- too destructive for a suite.
#
# The P4-dependent cases are SKIPPED (not failed) when no client is reachable, so
# filesystem-only consumers can still run the suite.
#
#   exit 0 : all checks pass (or skip)
#   exit 1 : one or more checks failed
param()
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path "$PSScriptRoot\..").Path
. (Join-Path $PSScriptRoot 'lib\P4Spec.ps1')

$pass = 0; $fail = 0; $skip = 0
function Ok($n)     { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$w) { Write-Output "  FAIL  $n  -- $w"; $script:fail++ }
function Skp($n,$w) { Write-Output "  SKIP  $n  ($w)"; $script:skip++ }

Write-Output "=============================================================="
Write-Output "P4 change-spec tests"
Write-Output "=============================================================="

# --- 1. Shape: no Files: section, ever. -------------------------------------
$spec = New-P4ChangeSpecText -TagPrefix '[scaffold][install]' -ScriptVersion '9.9.9' -FileCount 3
if ($spec -match '(?m)^\s*Files:') { Bad 'spec carries no Files: section' 'Files: found' }
else { Ok 'spec carries no Files: section' }

if ($spec -match '(?m)^Change:\s+new\s*$') { Ok 'spec declares Change: new' }
else { Bad 'spec declares Change: new' 'missing' }

# Description continuation lines must be TAB-indented or p4 rejects the spec.
$descLines = @($spec -split "`n" | Select-Object -Skip 3)
$badIndent = @($descLines | Where-Object { $_ -ne '' -and -not $_.StartsWith("`t") })
if ($badIndent.Count -eq 0) { Ok 'description lines are tab-indented' }
else { Bad 'description lines are tab-indented' "$($badIndent.Count) line(s) not tabbed" }

if ($spec -match '\[scaffold\]\[install\]') { Ok 'tag prefix survives into the description' }
else { Bad 'tag prefix survives into the description' 'not found' }

# The audit greps for [jobFamily][name]; a single [tag] fails it.
if ($spec -match '(?m)^\t\[[^\]]+\]\[[^\]]+\]') { Ok 'default tag satisfies [jobFamily][name]' }
else { Bad 'default tag satisfies [jobFamily][name]' 'first description line is not double-tagged' }

# --- 2. Bytes: no BOM. -------------------------------------------------------
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("p4spec-test-" + [System.Guid]::NewGuid().ToString('N') + ".spec")
try {
    Write-P4SpecFile -Path $tmp -Text $spec
    $bytes = [System.IO.File]::ReadAllBytes($tmp)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Bad 'spec file has no UTF-8 BOM' 'BOM present -- p4 would reject with "Unknown field name"'
    } else { Ok 'spec file has no UTF-8 BOM' }
} finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
}

# --- 3. Behaviour: p4 accepts it, and the new CL does NOT inherit default. ----
$p4Available = $false
try {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    $null = & cmd /c "p4 info 2>nul"
    $p4Available = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $prev
} catch { $p4Available = $false }

if (-not $p4Available) {
    Skp 'p4 change -i accepts the spec' 'no p4 client reachable'
    Skp 'new CL does not inherit the default changelist' 'no p4 client reachable'
} else {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
    $defaultBefore = @(& cmd /c "p4 opened -c default 2>nul" | Where-Object { $_ -match 'default change' })
    $ErrorActionPreference = $prev

    $tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ("p4spec-live-" + [System.Guid]::NewGuid().ToString('N') + ".spec")
    $liveSpec = New-P4ChangeSpecText -TagPrefix '[scaffold][selftest]' -ScriptVersion '0.0.0-test' -FileCount 0
    $newCL = $null
    try {
        Write-P4SpecFile -Path $tmp2 -Text $liveSpec
        $created = & cmd /c "p4 change -i < ""$tmp2"""
        if ($created -match 'Change (\d+) created') {
            $newCL = $Matches[1]
            Ok 'p4 change -i accepts the spec'
        } else {
            Bad 'p4 change -i accepts the spec' ($created -join ' ')
        }

        if ($newCL) {
            $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
            $inNew = @(& cmd /c "p4 opened -c $newCL 2>nul" | Where-Object { $_ -match 'change ' })
            $defaultAfter = @(& cmd /c "p4 opened -c default 2>nul" | Where-Object { $_ -match 'default change' })
            $ErrorActionPreference = $prev

            # The real anti-sweep assertion. With `p4 change -o` as the source, any
            # file open in default would appear in $inNew and vanish from default.
            if ($inNew.Count -ne 0) {
                Bad 'new CL does not inherit the default changelist' "$($inNew.Count) file(s) swept into CL $newCL"
            } elseif ($defaultAfter.Count -ne $defaultBefore.Count) {
                Bad 'new CL does not inherit the default changelist' "default went from $($defaultBefore.Count) to $($defaultAfter.Count) file(s)"
            } elseif ($defaultBefore.Count -eq 0) {
                Ok 'new CL does not inherit the default changelist (default was empty -- shape assertion only)'
            } else {
                Ok "new CL does not inherit the default changelist ($($defaultBefore.Count) file(s) stayed put)"
            }
        }
    } finally {
        if (Test-Path -LiteralPath $tmp2) { Remove-Item -LiteralPath $tmp2 -Force }
        if ($newCL) {
            $prev = $ErrorActionPreference; $ErrorActionPreference = 'SilentlyContinue'
            & cmd /c "p4 change -d $newCL 2>nul" | Out-Null
            $ErrorActionPreference = $prev
        }
    }
}

Write-Output ""
Write-Output "=============================================================="
Write-Output "P4 change-spec tests: $pass passed, $fail failed, $skip skipped"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
