# migrate-project-scope-installs.ps1 - converge duplicate plugin installs to one record each.
#
# WHY THIS EXISTS
#   ~/.claude/plugins/installed_plugins.json can hold BOTH a user-scope and a project-scope
#   record for one plugin id. Selection takes the first applicable record in stored-array
#   order whose installPath exists -- there is no scope precedence -- so which payload loads
#   is decided by the order you happened to install things in, and nothing reports the winner.
#   A stale project record that was installed first wins every session, silently.
#
#   Removing the committed `enabledPlugins` entries stops NEW project records being created.
#   It does not remove the ones already on a machine. This does, once.
#
# WHY NOT `claude plugin uninstall --scope project`
#   Measured 2026-08-25 (CLI v2.1.231): under identical preconditions, from the repo root,
#   it removed one plugin's project record and REFUSED for two others -- reporting "installed
#   in user scope, not project" and advising `--scope user`, the flag that deletes the copy
#   you are keeping. The governing rule was never determined. Worse, when it does succeed it
#   also strips the plugin's entry from the project's committed .claude/settings.json and
#   leaves that file modified but not opened for edit -- a version-controlled, team-shared
#   file silently going dirty during someone's setup. So this edits the registry directly.
#
# DRY-RUN by default (lists what it would remove). Use -Apply to act.
#   -Apply writes a timestamped backup beside the registry before touching it.
param(
    [Parameter(Mandatory=$false)] [string] $RegistryPath,
    [Parameter(Mandatory=$false)] [switch] $Apply
)
$ErrorActionPreference = 'Stop'

# CLAUDE_CONFIG_DIR wins when set: a machine that relocated its config would otherwise be
# reported clean while its real registry kept the duplicates.
function Resolve-RegistryPath {
    param([string] $Explicit)
    if ($Explicit) { return $Explicit }
    $base = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
    return (Join-Path $base 'plugins/installed_plugins.json')
}

# A record belongs to a project if it says so EITHER way. scope is what the selector reads;
# projectPath is what the writer stamps. Trusting only one leaves the other kind behind.
function Test-ProjectRecord {
    param($Record)
    if ($null -eq $Record) { return $false }
    if ($Record.PSObject.Properties.Name -contains 'scope' -and $Record.scope -eq 'project') { return $true }
    if ($Record.PSObject.Properties.Name -contains 'projectPath' -and $Record.projectPath) { return $true }
    return $false
}

$registry = Resolve-RegistryPath -Explicit $RegistryPath

Write-Output "=============================================================="
Write-Output "migrate-project-scope-installs - registry: $registry"
Write-Output "mode: $(if ($Apply) { 'APPLY' } else { 'DRY-RUN (no changes)' })"
Write-Output "=============================================================="

# Missing / empty / unparsable all mean "nothing to converge", never a crash. This runs on
# other people's machines during setup; a stack trace there is worse than a stated no-op.
if (-not (Test-Path -LiteralPath $registry)) {
    Write-Output "No registry at that path. Nothing to converge - you're clean."
    exit 0
}
$raw = Get-Content -LiteralPath $registry -Raw -ErrorAction SilentlyContinue
if ([string]::IsNullOrWhiteSpace($raw)) {
    Write-Output "Registry is empty. Nothing to converge - you're clean."
    exit 0
}
try { $data = $raw | ConvertFrom-Json } catch {
    Write-Output "Registry is not valid JSON - leaving it untouched. Nothing to converge."
    exit 0
}
if ($null -eq $data -or -not ($data.PSObject.Properties.Name -contains 'plugins') -or $null -eq $data.plugins) {
    Write-Output "Registry has no plugins map. Nothing to converge - you're clean."
    exit 0
}

$removals = New-Object System.Collections.Generic.List[object]
$orphanRisks = New-Object System.Collections.Generic.List[object]

foreach ($prop in @($data.plugins.PSObject.Properties)) {
    $id = $prop.Name
    $records = @($prop.Value)
    if ($records.Count -eq 0) { continue }

    $project = @($records | Where-Object { Test-ProjectRecord $_ })
    if ($project.Count -eq 0) { continue }

    $keep = @($records | Where-Object { -not (Test-ProjectRecord $_) })

    # NEVER leave a plugin with zero records. If every record for an id is project-scope,
    # removing them uninstalls the plugin outright -- the opposite of converging it. Report
    # and skip: a human decides whether that plugin should be reinstalled at user scope.
    if ($keep.Count -eq 0) {
        $orphanRisks.Add([pscustomobject]@{ Id = $id; Count = $project.Count })
        continue
    }

    foreach ($r in $project) {
        $removals.Add([pscustomobject]@{
            Id      = $id
            Scope   = $(if ($r.PSObject.Properties.Name -contains 'scope') { $r.scope } else { '(none)' })
            Version = $(if ($r.PSObject.Properties.Name -contains 'version') { $r.version } else { '(none)' })
            Path    = $(if ($r.PSObject.Properties.Name -contains 'projectPath') { $r.projectPath } else { '(none)' })
        })
    }
    # PS 5.1 unrolls a one-element filter result to a scalar, and ConvertTo-Json then writes
    # "id": {..} instead of "id": [{..}] -- still valid JSON, but a shape the selector cannot
    # read. Measured on 5.1.26100. This @() and the one on $keep each prevent it independently,
    # so removing either alone is invisible; the round-trip check before the write is what makes
    # the corruption unwritable rather than merely unlikely. Mutation-tested: stripping BOTH
    # wrappers fails run-converge-tests.ps1 AND trips that abort.
    $prop.Value = @($keep)
}

if ($orphanRisks.Count -gt 0) {
    Write-Output "SKIPPED - every record is project-scope, so removing them would uninstall the plugin:"
    foreach ($o in $orphanRisks) { Write-Output "  - $($o.Id)  ($($o.Count) record(s))" }
    Write-Output "  Reinstall these at user scope first (claude plugin install <id>), then re-run."
    Write-Output ""
}

if ($removals.Count -eq 0) {
    Write-Output "No project-scope install records to remove. Nothing to converge - you're clean."
    exit 0
}

Write-Output "Project-scope records ($($removals.Count)):"
foreach ($r in $removals) { Write-Output "  - $($r.Id)  scope=$($r.Scope)  version=$($r.Version)  projectPath=$($r.Path)" }
Write-Output ""

if (-not $Apply) {
    Write-Output "DRY-RUN. Re-run with -Apply to remove them."
    exit 0
}

$stamp  = (Get-Date).ToString('yyyyMMdd-HHmmss')
$backup = "$registry.bak-converge-$stamp"
Copy-Item -LiteralPath $registry -Destination $backup -Force
Write-Output "backup: $backup"

$json = $data | ConvertTo-Json -Depth 20

# Round-trip before declaring success. The failure this catches is not hypothetical: an
# unguarded filter turns a one-element list into an object, and the file stays valid JSON
# while meaning something else entirely. Valid-JSON is not the bar; same-shape is.
try { $check = $json | ConvertFrom-Json } catch {
    Write-Output "ABORTED: serialized registry did not parse back. Original left untouched; backup at $backup"
    exit 1
}
foreach ($prop in @($check.plugins.PSObject.Properties)) {
    if ($prop.Value -isnot [System.Object[]]) {
        Write-Output "ABORTED: '$($prop.Name)' serialized as $($prop.Value.GetType().Name), not a list. Original left untouched; backup at $backup"
        exit 1
    }
}

Set-Content -LiteralPath $registry -Value $json -Encoding UTF8
Write-Output "removed $($removals.Count) project-scope record(s). Re-run to confirm it reports clean."
exit 0
