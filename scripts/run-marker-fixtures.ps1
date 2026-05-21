# run-marker-fixtures.ps1 — Marker Specification verification (plan v1.6 line 403-405)
#
# Proves the installer REFUSES TO WRITE under every pathological case, with
# exit code 2 and ZERO file mutation. Also proves CRLF/BOM normalization
# equivalence (plan line 386) and append-fragment idempotence + pre-existing
# pattern preservation (plan line 401).
#
#   exit 0 : all fixtures pass
#   exit 1 : one or more fixtures failed
param()

$ErrorActionPreference = 'Stop'
$here     = $PSScriptRoot
$validate = Join-Path $here 'validate-markers.ps1'
. (Join-Path $here 'lib\Markers.ps1')

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("marker-fx-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

$pass = 0; $fail = 0
function Ok($n)   { Write-Output "  PASS  $n"; $script:pass++ }
function Bad($n,$why) { Write-Output "  FAIL  $n  -- $why"; $script:fail++ }

function Write-Bytes($path, [byte[]]$bytes) {
    [System.IO.File]::WriteAllBytes($path, $bytes)
}
function Utf8($s)     { [System.Text.Encoding]::UTF8.GetBytes($s) }
function Utf8Bom($s)  {
    $body = [System.Text.Encoding]::UTF8.GetBytes($s)
    $out  = New-Object byte[] ($body.Length + 3)
    $out[0] = 0xEF; $out[1] = 0xBB; $out[2] = 0xBF
    [Array]::Copy($body, 0, $out, 3, $body.Length)
    return ,$out
}
function RawSha($p)   {
    $b = [System.IO.File]::ReadAllBytes($p)
    $s = [System.Security.Cryptography.SHA256]::Create()
    [BitConverter]::ToString($s.ComputeHash($b)).Replace('-','').ToLowerInvariant()
}
function Run-Validate($file, $id) {
    $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validate -File $file -Id $id 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($o -join "`n") }
}

$ID = 'test-block'

# ---- Negative fixtures: each MUST exit 2 with zero mutation -----------------
$neg = @{}
$neg['missing-end'] = @"
# Doc
<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->
content
no end marker here
"@
$neg['duplicate-begin'] = @"
<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->
a
<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->
b
<!-- AGENTIC-SCAFFOLD:END id=$ID -->
"@
$neg['inverted-order'] = @"
<!-- AGENTIC-SCAFFOLD:END id=$ID -->
middle
<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->
"@
$neg['nested-same-id'] = @"
<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->
outer
<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->
inner
<!-- AGENTIC-SCAFFOLD:END id=$ID -->
<!-- AGENTIC-SCAFFOLD:END id=$ID -->
"@
$neg['marker-in-fence'] = @"
# Doc
``````
<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->
<!-- AGENTIC-SCAFFOLD:END id=$ID -->
``````
prose
"@
$neg['marker-midline'] = @"
# Doc
prefix text <!-- AGENTIC-SCAFFOLD:BEGIN id=$ID --> trailing
inline <!-- AGENTIC-SCAFFOLD:END id=$ID --> stuff
"@

foreach ($k in $neg.Keys) {
    $f = Join-Path $tmp "$k.md"
    Write-Bytes $f (Utf8 ($neg[$k] -replace "`r`n","`n"))
    $pre = RawSha $f
    $r = Run-Validate $f $ID
    $post = RawSha $f
    if ($r.Code -eq 2 -and $pre -eq $post) { Ok "neg/$k (exit 2, zero mutation)" }
    else { Bad "neg/$k" "exit=$($r.Code) preEqPost=$($pre -eq $post)" }
}

# CRLF + missing END: normalization must NOT mask the ambiguity.
$crlfBroken = Join-Path $tmp 'crlf-broken.md'
Write-Bytes $crlfBroken (Utf8 ("# Doc`r`n<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->`r`nbody`r`nno end`r`n"))
$pre = RawSha $crlfBroken; $r = Run-Validate $crlfBroken $ID; $post = RawSha $crlfBroken
if ($r.Code -eq 2 -and $pre -eq $post) { Ok "neg/crlf-broken (exit 2, zero mutation)" }
else { Bad "neg/crlf-broken" "exit=$($r.Code) preEqPost=$($pre -eq $post)" }

# BOM + duplicate BEGIN: BOM stripped, ambiguity still caught.
$bomBroken = Join-Path $tmp 'bom-broken.md'
Write-Bytes $bomBroken (Utf8Bom "<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->`na`n<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->`nb`n<!-- AGENTIC-SCAFFOLD:END id=$ID -->`n")
$pre = RawSha $bomBroken; $r = Run-Validate $bomBroken $ID; $post = RawSha $bomBroken
if ($r.Code -eq 2 -and $pre -eq $post) { Ok "neg/bom-broken (exit 2, zero mutation)" }
else { Bad "neg/bom-broken" "exit=$($r.Code) preEqPost=$($pre -eq $post)" }

# ---- Positive fixtures: clean LF/CRLF/BOM -> exit 0, identical blockHash ----
$cleanBody = "# Doc`n`n<!-- AGENTIC-SCAFFOLD:BEGIN id=$ID -->`nline one`nline two`n<!-- AGENTIC-SCAFFOLD:END id=$ID -->`n`ntail`n"
$pLf  = Join-Path $tmp 'clean-lf.md';   Write-Bytes $pLf  (Utf8 $cleanBody)
$pCr  = Join-Path $tmp 'clean-crlf.md'; Write-Bytes $pCr  (Utf8 ($cleanBody -replace "`n","`r`n"))
$pBom = Join-Path $tmp 'clean-bom.md';  Write-Bytes $pBom (Utf8Bom $cleanBody)

$hashes = @{}
foreach ($pf in @(@('clean-lf',$pLf),@('clean-crlf',$pCr),@('clean-bom',$pBom))) {
    $pre = RawSha $pf[1]; $r = Run-Validate $pf[1] $ID; $post = RawSha $pf[1]
    if ($r.Code -eq 0 -and $pre -eq $post) {
        $hashes[$pf[0]] = ($r.Out.Trim() -split "`n")[-1]
        Ok "pos/$($pf[0]) (exit 0, zero mutation)"
    } else { Bad "pos/$($pf[0])" "exit=$($r.Code) preEqPost=$($pre -eq $post) out=$($r.Out)" }
}
if ($hashes.Count -eq 3 -and $hashes['clean-lf'] -eq $hashes['clean-crlf'] -and $hashes['clean-lf'] -eq $hashes['clean-bom']) {
    Ok "normalization-equivalence (LF==CRLF==BOM blockHash; plan line 386)"
} else {
    Bad "normalization-equivalence" "hashes=$($hashes | Out-String)"
}

# ---- Append-fragment: idempotence + pre-existing pattern preservation ------
$baseIgnore = "# existing`nBuild/`nbinary.exe`nIntermediate/`n"
$fragment   = "settings.json`nsettings.local.json`nscheduled_tasks.lock"
$r1 = Set-AppendFragment -NormalizedText $baseIgnore -Id 'p4ignore-scaffold' -FragmentText $fragment -Style 'hash'
$r2 = Set-AppendFragment -NormalizedText $r1         -Id 'p4ignore-scaffold' -FragmentText $fragment -Style 'hash'
if ($r1 -eq $r2) { Ok "p4ignore/idempotent (two installs byte-identical; plan line 401)" }
else { Bad "p4ignore/idempotent" "r1 != r2" }
$preLines = ($baseIgnore -split "`n") | Where-Object { $_ -ne '' }
$haystack = $r1
$allPreserved = $true
$idx = -1
foreach ($ln in $preLines) {
    $found = $haystack.IndexOf($ln)
    if ($found -lt 0 -or $found -lt $idx) { $allPreserved = $false; break }
    $idx = $found
}
if ($allPreserved) { Ok "p4ignore/pre-existing patterns preserved in original order (plan line 401)" }
else { Bad "p4ignore/pre-existing patterns preserved" "order or content changed" }

Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "=============================================================="
Write-Output "Marker fixtures: $pass passed, $fail failed"
Write-Output "=============================================================="
if ($fail -gt 0) { exit 1 } else { exit 0 }
