# block-unapproved-submit.ps1 -- PreToolUse hook for Claude Code (strict mode)
#
# Enforces the CL-by-CL HARD RULE from .claude/workflows/ChangelistVerification.md:
# every `p4 submit -c <N>` requires an explicit user approval, recorded as
# .scratch/.approved-cl-<N>.marker. The hook blocks any submit attempt without
# the marker, forcing the agent to pause and ask the user first.
#
# Wired up via:
#   {
#     "hooks": {
#       "PreToolUse": [
#         {
#           "matcher": "Bash",
#           "hooks": [
#             { "type": "command",
#               "command": "powershell -NoProfile -ExecutionPolicy Bypass -File .claude/scripts/hooks/block-unapproved-submit.ps1" }
#           ]
#         }
#       ]
#     }
#   }
#
# Input: PreToolUse JSON via stdin (Claude Code passes tool_name, tool_input, etc.)
# Output:
#   exit 0  -- allow the tool call
#   exit 2  -- BLOCK the tool call (Claude Code surfaces the stderr message)
#
# The exit 2 message tells the agent exactly what to do: ask the user, then
# create the marker. The marker is auto-cleaned by a companion PostToolUse hook
# (cleanup-approved-cl.ps1, paired hook), so one approval = one submit.

$ErrorActionPreference = 'Stop'

# Read PreToolUse payload
$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

try {
    $event = $raw | ConvertFrom-Json
} catch {
    # Malformed input -- don't block (fail open on parsing issues; the hook
    # exists to enforce a specific rule, not to be a general gate).
    exit 0
}

# Only inspect Bash tool calls
$toolName = $null
if ($event.PSObject.Properties.Match('tool_name').Count -gt 0) { $toolName = $event.tool_name }
if ($toolName -ne 'Bash') { exit 0 }

$cmd = $null
if ($event.PSObject.Properties.Match('tool_input').Count -gt 0 -and
    $event.tool_input.PSObject.Properties.Match('command').Count -gt 0) {
    $cmd = [string]$event.tool_input.command
}
if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

# Detect `p4 submit -c <CL>` patterns. Match common forms:
#   p4 submit -c 996
#   p4 submit  -c   996
#   p4 -c <client> submit -c 996  (rare)
# Stay conservative: require an explicit CL number after -c.
$rxSubmit = [regex] '\bp4\s+(?:[^|;&]*\s+)?submit\s+-c\s+(?<cl>\d+)\b'
$m = $rxSubmit.Match($cmd)
if (-not $m.Success) {
    # Other p4 submit forms (no -c) are non-CL or interactive -- not the target
    # of this rule. Let them through; CL-by-CL rule only applies to numbered CLs.
    exit 0
}

$cl = $m.Groups['cl'].Value

# Determine project root. PreToolUse hooks run from the project root (Claude
# Code sets cwd), but accept CLAUDE_PROJECT_DIR override if set.
$root = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$markerPath = Join-Path $root ".scratch\.approved-cl-$cl.marker"

if (Test-Path -LiteralPath $markerPath) {
    # Approved. Allow the submit. The PostToolUse companion hook will delete
    # the marker so it can't be reused.
    exit 0
}

# Block. Print to stderr -- Claude Code surfaces stderr from blocked hooks
# back to the agent, so the agent sees the message and knows what to do.
[Console]::Error.WriteLine(@"
BLOCKED: Submit of CL $cl not approved (CL-by-CL HARD RULE).

Per .claude/workflows/ChangelistVerification.md, every submit must be
explicitly approved by the user before running. The approval is recorded
as a marker file the strict-mode hooks check.

To proceed:
  1. Stop. Surface CL $cl to the user (description, file list, diff).
  2. Ask for explicit approval.
  3. After user approves, create the marker:
       New-Item -ItemType File -Path '.scratch/.approved-cl-$cl.marker' -Force | Out-Null
  4. Re-run the submit. The marker is auto-deleted after submit.

If the user has already said "submit it" / "go ahead" / similar but you
hadn't yet shown the diff and asked for explicit OK, do that now. The hook
enforces the protocol; the user-side experience is a single confirmation
beat that previously was easy to skip.

To disable strict mode: edit .claude/settings.local.json and remove the
PreToolUse hook block for block-unapproved-submit.ps1.
"@)
exit 2
