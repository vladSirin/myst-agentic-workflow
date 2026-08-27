# retire-legacy.ps1 -- transitional v4 -> v5 consumer cleanup. Removes the
# per-user state the retired v4 installer created, then you install v5 with
# your tool's one-liner (README.md). Idempotent; -WhatIf reports and changes
# nothing. This script and the installer stub are deleted together in a later
# MINOR release. PS 5.1-clean, ASCII only.
#
# What it touches (and nothing else):
#   1. Journal guard (runs FIRST): scans the workspace for v4 install journals
#      (.scratch/*.journal) and staging dirs (*.agentic-stage). Any journal
#      with committed:false makes the whole run REFUSE (exit 2) -- that state
#      describes real files and only the v4 tooling or a human can resolve it.
#      committed:true journals are deleted.
#   2. OpenCode config (~/.config/opencode/opencode.json): removes the
#      skills.paths entry pointing at the dedicated clone and the dead
#      agent["myst-dev-kit:*"] disable entries. Strict JSON only -- a config
#      that does not parse is left untouched with manual instructions printed.
#      Backs the file up first. NEVER touches mcp.unreal-engine or
#      permission.skill. Also removes *.bak-myst-setup backup files.
#   3. The dedicated clone at ~/.myst-agentic-workflow.
#   4. Generated reviewer agents: ~/.codex/agents/architecture-reviewer.toml
#      and radical-design-critic.toml, and the opencode-generated
#      ~/.config/opencode/agents/myst/ directory.
#   5. Claude install registry (~/.claude/plugins/installed_plugins.json):
#      REPORT-ONLY check for the pre-v4.50.0 duplicate-scope record condition
#      the retired v4 converge script used to fix. Prints recovery
#      instructions; never edits the registry.
#   6. Optional (-PruneCache): old myst-dev-kit versions in the Claude plugin
#      cache (~/.claude/plugins/cache/myst/myst-dev-kit/) -- keeps the newest.
#      Reported always; deleted only with the switch.
#
# The synthetic fixture retire-legacy.fixture.json beside this script is a
# committed:false journal for testing the guard: put it in a scratch
# <root>/.scratch/ and run with -WorkspaceRoot <root> -WhatIf.
param(
    [switch] $WhatIf,
    [string] $WorkspaceRoot = '',    # skip p4 discovery, scan this tree
    [string] $OpenCodeConfig = '',   # config path override (tests)
    [string] $HomeDir = '',          # HOME override (tests) - scopes steps 2-5
    [switch] $PruneCache
)

$ErrorActionPreference = 'Stop'
if (-not $HomeDir) { $HomeDir = $HOME }
$script:acted = $false

function Say([string] $msg) { Write-Host $msg }
function Act([string] $what, [scriptblock] $do) {
    if ($WhatIf) { Say ("WOULD: " + $what) }
    else { Say ("DO:    " + $what); & $do; $script:acted = $true }
}

# --- 1. Workspace discovery + journal guard --------------------------------
$root = $WorkspaceRoot
if (-not $root) {
    $p4 = Get-Command p4 -ErrorAction SilentlyContinue
    if ($p4) {
        try {
            $info = & p4 -ztag info 2>$null
            foreach ($line in $info) {
                if ($line -match '^\.\.\. clientRoot (.+)$') { $root = $Matches[1].Trim(); break }
            }
        } catch { }
    }
    if (-not $root) { Say 'No workspace found (no -WorkspaceRoot, no usable p4 info) - journal scan skipped.' }
}

$refused = @()
$journals = @()
if ($root -and (Test-Path $root)) {
    Say ("Workspace: " + $root)
    $scratch = Join-Path $root '.scratch'
    if (Test-Path $scratch) {
        $journals += @(Get-ChildItem -Path $scratch -Filter '*.journal' -File -ErrorAction SilentlyContinue)
    }
    $stages = @(Get-ChildItem -Path $root -Recurse -Filter '*.agentic-stage' -ErrorAction SilentlyContinue)

    foreach ($j in $journals) {
        $data = $null
        try {
            # Real journals carry a UTF-8 BOM; ReadAllText honors it.
            $data = [IO.File]::ReadAllText($j.FullName) | ConvertFrom-Json
        } catch {
            $refused += ("{0}: does not parse as JSON - resolve by hand" -f $j.FullName)
            continue
        }
        if ($data.PSObject.Properties['committed'] -and -not $data.committed) {
            $detail = ("{0}: committed:false" -f $j.FullName)
            if ($data.PSObject.Properties['openedFiles'] -and $data.openedFiles) {
                $detail += ("`n  openedFiles: " + (@($data.openedFiles) -join ', '))
            }
            if ($data.PSObject.Properties['stages'] -and $data.stages) {
                $detail += ("`n  stages: " + (@($data.stages) -join ', '))
            }
            $refused += $detail
        }
    }

    if ($refused.Count -gt 0) {
        Say ''
        Say 'REFUSING: uncommitted v4 install journal(s) found. They describe real files'
        Say 'this script must not delete. Resolve them (or their opened files) first:'
        foreach ($r in $refused) { Say ('  ' + $r) }
        exit 2
    }

    foreach ($j in $journals) {
        Act ("delete committed journal " + $j.FullName) { Remove-Item -Force $j.FullName }.GetNewClosure()
    }
    foreach ($s in $stages) {
        Act ("delete staging leftover " + $s.FullName) { Remove-Item -Recurse -Force $s.FullName }.GetNewClosure()
    }
}

# --- 2. OpenCode config -----------------------------------------------------
$ocPath = $OpenCodeConfig
if (-not $ocPath) { $ocPath = Join-Path $HomeDir '.config/opencode/opencode.json' }
$cloneToken = '.myst-agentic-workflow'

if (Test-Path $ocPath) {
    $raw = [IO.File]::ReadAllText($ocPath)
    $cfg = $null
    try { $cfg = $raw | ConvertFrom-Json } catch { $cfg = $null }
    if ($null -eq $cfg) {
        Say ("OpenCode config at {0} is not strict JSON (JSONC?). Left untouched. Manual edit:" -f $ocPath)
        Say ('  - remove the skills.paths entry containing "' + $cloneToken + '"')
        Say ('  - remove any agent entries named "myst-dev-kit:*"')
        Say ('  - do NOT touch mcp.unreal-engine or permission.skill')
    } else {
        $changed = $false

        if ($cfg.PSObject.Properties['skills'] -and $cfg.skills.PSObject.Properties['paths']) {
            $keep = @($cfg.skills.paths | Where-Object { $_ -notlike ('*' + $cloneToken + '*') })
            if ($keep.Count -ne @($cfg.skills.paths).Count) {
                $changed = $true
                if ($keep.Count -gt 0) { $cfg.skills.paths = $keep }
                else {
                    $cfg.skills.PSObject.Properties.Remove('paths')
                    if (@($cfg.skills.PSObject.Properties).Count -eq 0) { $cfg.PSObject.Properties.Remove('skills') }
                }
            }
        }

        if ($cfg.PSObject.Properties['agent']) {
            $dead = @($cfg.agent.PSObject.Properties | Where-Object { $_.Name -like 'myst-dev-kit:*' })
            foreach ($d in $dead) {
                $changed = $true
                $cfg.agent.PSObject.Properties.Remove($d.Name)
            }
            if (@($cfg.agent.PSObject.Properties).Count -eq 0) { $cfg.PSObject.Properties.Remove('agent') }
        }

        if ($changed) {
            $bak = $ocPath + '.bak-myst-retire'
            Act ("clean OpenCode config (backup at {0})" -f $bak) {
                Copy-Item $ocPath $bak -Force
                $cfg | ConvertTo-Json -Depth 32 | Set-Content -Path $ocPath -Encoding UTF8
            }.GetNewClosure()
        } else {
            Say 'OpenCode config: nothing of ours in it.'
        }
    }

    $ocDir = Split-Path $ocPath -Parent
    foreach ($b in @(Get-ChildItem -Path $ocDir -Filter '*.bak-myst-setup' -File -ErrorAction SilentlyContinue)) {
        Act ("delete old setup backup " + $b.FullName) { Remove-Item -Force $b.FullName }.GetNewClosure()
    }
} else {
    Say 'No OpenCode config - skipped.'
}

# OpenCode-generated agent variants.
$ocAgents = Join-Path $HomeDir '.config/opencode/agents/myst'
if (Test-Path $ocAgents) {
    Act ("delete generated OpenCode agents at " + $ocAgents) { Remove-Item -Recurse -Force $ocAgents }
}

# --- 3. The dedicated clone -------------------------------------------------
$clone = Join-Path $HomeDir $cloneToken
if (Test-Path $clone) {
    $here = $PSScriptRoot
    if ($here -and $here.StartsWith((Resolve-Path $clone).Path, [StringComparison]::OrdinalIgnoreCase)) {
        Say ("This script is RUNNING FROM the clone; delete it yourself afterwards:")
        Say ('  Remove-Item -Recurse -Force "' + $clone + '"')
    } else {
        Act ("delete dedicated clone " + $clone) { Remove-Item -Recurse -Force $clone }
    }
} else {
    Say 'No dedicated clone - skipped.'
}

# --- 4. Generated Codex reviewer agents ------------------------------------
foreach ($name in @('architecture-reviewer', 'radical-design-critic')) {
    $toml = Join-Path $HomeDir ('.codex/agents/' + $name + '.toml')
    if (Test-Path $toml) {
        Act ("delete generated Codex agent " + $toml) { Remove-Item -Force $toml }.GetNewClosure()
    }
}

# --- 5. Claude install registry (report only - never edited here) -----------
$reg = Join-Path $HomeDir '.claude/plugins/installed_plugins.json'
if (Test-Path $reg) {
    $dupes = @()
    $regOk = $true
    try {
        $regData = [IO.File]::ReadAllText($reg) | ConvertFrom-Json
        if ($regData.PSObject.Properties['plugins']) {
            foreach ($p in $regData.plugins.PSObject.Properties) {
                $records = @($p.Value)
                if ($records.Count -gt 1) {
                    $scopes = @($records | ForEach-Object { $_.scope }) -join ', '
                    $dupes += ("{0} ({1} records: {2})" -f $p.Name, $records.Count, $scopes)
                }
            }
        }
    } catch {
        $regOk = $false
        Say ("Install registry at {0} could not be read - duplicate-record check skipped." -f $reg)
    }
    if ($regOk -and $dupes.Count -gt 0) {
        Say 'Install registry holds more than one record for the same plugin id (the'
        Say 'pre-v4.50.0 condition: which record wins is decided by stored order, silently).'
        Say 'This script never edits the registry. Recover the v4 converge script from'
        Say 'git history and run it (dry-run by default, -Apply to act):'
        Say '  git show v4.50.1:scripts/migrate-project-scope-installs.ps1 > converge.ps1'
        Say 'Affected ids:'
        foreach ($d in $dupes) { Say ('  ' + $d) }
    }
}

# --- 6. Claude plugin cache (report always, prune only on -PruneCache) ------
$cache = Join-Path $HomeDir '.claude/plugins/cache/myst/myst-dev-kit'
if (Test-Path $cache) {
    $versions = @(Get-ChildItem -Path $cache -Directory | Sort-Object {
        $parts = $_.Name.Split('.')
        if ($parts.Count -eq 3) { [int]$parts[0] * 1000000 + [int]$parts[1] * 1000 + [int]$parts[2] } else { -1 }
    })
    if ($versions.Count -gt 1) {
        $old = @($versions | Select-Object -First ($versions.Count - 1))
        Say ("Plugin cache holds {0} versions; {1} old one(s) prunable (newest kept: {2})." -f $versions.Count, $old.Count, $versions[-1].Name)
        if ($PruneCache) {
            foreach ($v in $old) {
                Act ("prune cached version " + $v.FullName) { Remove-Item -Recurse -Force $v.FullName }.GetNewClosure()
            }
        } else {
            Say '  (re-run with -PruneCache to delete them)'
        }
    }
}

Say ''
if ($WhatIf) { Say 'Report only - nothing was changed. Re-run without -WhatIf to act.' }
elseif ($script:acted) { Say 'Done. Now run your tool''s install one-liner (README.md).' }
else { Say 'Nothing to clean - machine already at v5 state.' }
exit 0
