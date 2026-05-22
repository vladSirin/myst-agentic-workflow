# cleanup-approved-cl.ps1 -- PostToolUse companion to block-unapproved-submit.ps1
#
# After a `p4 submit -c <N>` runs (successfully or otherwise), delete the
# .scratch/.approved-cl-<N>.marker file. This makes each approval one-shot --
# the agent can't reuse an old approval to skip the CL-by-CL gate on the
# next submit.
#
# Always exits 0 (PostToolUse should never block; the action is already done).
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
try { $event = $raw | ConvertFrom-Json } catch { exit 0 }

if ($event.tool_name -ne 'Bash') { exit 0 }
$cmd = [string]$event.tool_input.command
if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

$rxSubmit = [regex] '\bp4\s+(?:[^|;&]*\s+)?submit\s+-c\s+(?<cl>\d+)\b'
$m = $rxSubmit.Match($cmd)
if (-not $m.Success) { exit 0 }

$cl = $m.Groups['cl'].Value
$root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$markerPath = Join-Path $root ".scratch\.approved-cl-$cl.marker"
if (Test-Path -LiteralPath $markerPath) {
    Remove-Item -LiteralPath $markerPath -Force -ErrorAction SilentlyContinue
}
exit 0
