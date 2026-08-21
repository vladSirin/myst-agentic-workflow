# setup-devkit.ps1 -- one command to install AND update the myst dev kit for every
# AI tool on this machine (Claude Code, Codex, OpenCode). Re-run it any time; each
# leg is idempotent. Install and update are the same run.
#
# What each leg does:
#   claude   : drives the native plugin manager (marketplace update + install/update).
#   codex    : drives the native plugin manager (marketplace add/upgrade + plugin add),
#              then generates the two reviewer agents as ~/.codex/agents/*.toml
#              (sandbox_mode = "read-only"; body verbatim from the shared source).
#   opencode : ensures the dedicated package clone at ~/.myst-agentic-workflow is at
#              the latest release tag, registers skills via the schema-validated
#              `skills.paths` config key (replace-not-append), writes the
#              unreal-engine MCP entry and the permission.skill ask-map for the nine
#              designed-manual skills, generates the two reviewer agents as
#              opencode-native files, then self-verifies delivery.
#
# The script only ever moves the git state of the DEDICATED clone
# (~/.myst-agentic-workflow). Any other checkout it happens to run from -- the dev
# repo, the Claude marketplace clone -- is used as-is and never mutated.
#
#   exit 0 : every selected leg succeeded (or was skipped: tool not on PATH)
#   exit 1 : at least one leg failed; the summary names it
param(
    [ValidateSet('auto','claude','codex','opencode')]
    [string] $Tool = 'auto',
    [string] $Version = '',            # pin/roll back to a specific vX.Y.Z tag
    [switch] $Uninstall,               # remove config entries + generated agents (clone stays)
    [switch] $DryRun,                  # print planned actions, change nothing
    # Test-support overrides. Consumers never need these.
    [string] $CloneRoot = '',          # package source root override
    [string] $OpencodeConfigDir = '',  # default: ~/.config/opencode
    [string] $CodexHome = '',          # default: ~/.codex
    [switch] $ForceGitUpdate           # fetch/checkout even when CloneRoot is not the dedicated clone
)

$ErrorActionPreference = 'Stop'

$RepoUrl       = 'https://github.com/vladSirin/myst-agentic-workflow'
$DedicatedPath = Join-Path $HOME '.myst-agentic-workflow'
$MarketplaceId = 'myst'
$PluginId      = 'myst-dev-kit@myst'

# The thirteen skills that are user-invoked by design (disable-model-invocation in the
# skill frontmatter). OpenCode ignores that key, so the same gate is restored as a
# permission.skill ask-map: the model must ask before auto-firing a workflow gate.
$ManualSkills = @('to-spec','to-tickets','triage','implement','handoff',
                  'grill-with-docs','improve-codebase-architecture',
                  'setup-agentic-workflow','wayfinder','to-questionnaire',
                  'grill-me','teach','wait-what')

# Reviewer-agent generation: fixed literal headers (never parsed from the source
# frontmatter -- the shared Claude files carry keys that break other loaders, e.g.
# `color: green` fails opencode's color schema machine-wide). Body ships verbatim.
$AgentMeta = @(
    @{ File = 'architecture-reviewer.md'
       Name = 'architecture-reviewer'
       Desc = 'Reviews written code for architectural quality; returns BLOCKING/WARNING/INFO findings ending with a parseable Verdict line. Read-only reviewer.'
       Color = '#22c55e' },
    @{ File = 'radical-design-critic.md'
       Name = 'radical-design-critic'
       Desc = 'Stress-tests a plan, design doc, or proposal before it is built; returns categorized findings ending with a parseable Verdict line. Read-only reviewer.'
       Color = '#a855f7' }
)

$legResults = @()
function Leg($name, $status, $note) {
    $script:legResults += [pscustomobject]@{ Leg = $name; Status = $status; Note = $note }
    Write-Host ("  [{0}] {1}{2}" -f $status, $name, $(if ($note) { ' -- ' + $note } else { '' }))
}

# Native calls under PS 5.1: EAP='Stop' + stderr output = terminating
# NativeCommandError (git writes progress to stderr by design). Scope EAP around
# the call and judge $LASTEXITCODE -- same pattern as update.ps1.
function Invoke-Native([string]$exe, [string[]]$argv) {
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try     { $out = & $exe @argv 2>&1 | ForEach-Object { $_.ToString() } }
    finally { $ErrorActionPreference = $prevEap }
    return @{ Out = @($out); Code = $LASTEXITCODE }
}

function Test-Cli([string]$name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# --- source root ---------------------------------------------------------------

function Resolve-SourceRoot {
    if ($CloneRoot) { return $CloneRoot }
    $here = $PSScriptRoot
    if ($here -and (Test-Path (Join-Path $here 'plugins/myst-dev-kit'))) { return $here }
    return $DedicatedPath
}

function Get-PackageVersion([string]$root) {
    $mf = Join-Path $root 'package-manifest.json'
    if (-not (Test-Path $mf)) { return '' }
    try { return (Get-Content -Raw $mf | ConvertFrom-Json).package.version } catch { return '' }
}

# Fetch tags and check out the requested (or latest) release. Version-aware sort is
# load-bearing: a lexical sort picks v4.9.0 over v4.40.0.
function Update-Clone([string]$root) {
    if (-not (Test-Path $root)) {
        Write-Host "  Cloning $RepoUrl -> $root"
        if ($DryRun) { return $true }
        $r = Invoke-Native 'git' @('clone', $RepoUrl, $root)
        if ($r.Code -ne 0) { $r.Out | ForEach-Object { Write-Host "    $_" }; return $false }
    }
    $dedicated = ($root -eq $DedicatedPath)
    if (-not ($dedicated -or $ForceGitUpdate)) {
        Write-Host "  Source: $root (not the dedicated clone; git state left untouched)"
        return $true
    }
    if ($DryRun) { Write-Host "  [dry-run] git fetch --tags + checkout latest v* tag in $root"; return $true }
    $before = Get-PackageVersion $root
    $r = Invoke-Native 'git' @('-C', $root, 'fetch', '--tags', '--force')
    if ($r.Code -ne 0) { $r.Out | ForEach-Object { Write-Host "    $_" }; return $false }
    $target = $Version
    if (-not $target) {
        $tags = Invoke-Native 'git' @('-C', $root, 'tag', '--list', 'v*', '--sort=-v:refname')
        $tagList = @($tags.Out | Where-Object { $_ -and $_.Trim() })
        if ($tags.Code -ne 0 -or $tagList.Count -eq 0) { Write-Host '    no v* tags found'; return $false }
        $target = $tagList[0].Trim()
    }
    $r = Invoke-Native 'git' @('-C', $root, 'checkout', '--quiet', $target)
    if ($r.Code -ne 0) { $r.Out | ForEach-Object { Write-Host "    $_" }; return $false }
    $after = Get-PackageVersion $root
    if ($before -and $after -and ($before -ne $after)) {
        Write-Host "  Updated: $before -> $after ($target)"
    } else {
        Write-Host "  At $target (package version $after)"
    }
    return $true
}

# --- JSON helpers (PS 5.1: PSCustomObject, no -AsHashtable) ---------------------

# pwsh 7's ConvertFrom-Json ACCEPTS JSONC (comments, trailing commas), so parsing
# alone cannot detect a config we must not rewrite -- rewriting would silently strip
# the user's comments. Use a strict parser when the runtime has one.
function Test-StrictJson([string]$raw) {
    $stj = 'System.Text.Json.JsonDocument' -as [type]
    if ($stj) {
        try { $doc = $stj::Parse($raw); $doc.Dispose(); return $true } catch { return $false }
    }
    try { $null = $raw | ConvertFrom-Json; return $true } catch { return $false }
}

function Get-Prop($obj, [string]$name) {
    $p = $obj.PSObject.Properties[$name]
    if ($p) { return $p.Value } else { return $null }
}
function Set-Prop($obj, [string]$name, $value) {
    Add-Member -InputObject $obj -NotePropertyName $name -NotePropertyValue $value -Force
}
function Remove-Prop($obj, [string]$name) {
    if ($obj.PSObject.Properties[$name]) { $obj.PSObject.Properties.Remove($name) }
}

# --- agent generation -----------------------------------------------------------

# Body = everything after the closing '---' of the source file's frontmatter.
function Get-AgentBody([string]$path) {
    $lines = Get-Content -LiteralPath $path
    $fence = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') {
            $fence++
            if ($fence -eq 2) {
                return (($lines[($i + 1)..($lines.Count - 1)]) -join "`n").Trim() + "`n"
            }
        }
    }
    return $null
}

function Write-OpencodeAgents([string]$srcAgents, [string]$destDir) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $written = 0
    foreach ($meta in $AgentMeta) {
        $src = Join-Path $srcAgents $meta.File
        if (-not (Test-Path $src)) { Write-Host "    missing source $($meta.File); skipped"; continue }
        $body = Get-AgentBody $src
        if (-not $body) { Write-Host "    could not split frontmatter of $($meta.File); skipped"; continue }
        # opencode file-permission gate is the `edit` key; there is no separate
        # `write` permission key in its agent schema.
        $header = @(
            '---',
            ('description: "' + $meta.Desc + '"'),
            'mode: subagent',
            ('color: "' + $meta.Color + '"'),
            'permission:',
            '  edit: deny',
            '---',
            ''
        ) -join "`n"
        [System.IO.File]::WriteAllText((Join-Path $destDir $meta.File), $header + $body)
        $written++
    }
    return $written
}

function Write-CodexAgents([string]$srcAgents, [string]$destDir) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $written = 0
    foreach ($meta in $AgentMeta) {
        $src = Join-Path $srcAgents $meta.File
        if (-not (Test-Path $src)) { Write-Host "    missing source $($meta.File); skipped"; continue }
        $body = Get-AgentBody $src
        if (-not $body) { Write-Host "    could not split frontmatter of $($meta.File); skipped"; continue }
        if ($body.Contains('"""')) {
            # The body is embedded in a TOML multiline basic string; a literal """
            # inside it cannot be represented without mangling the content.
            Write-Host "    $($meta.File) body contains triple quotes; skipped (cannot embed in TOML)"
            continue
        }
        $toml = @(
            ('name = "' + $meta.Name + '"'),
            ('description = "' + $meta.Desc + '"'),
            'sandbox_mode = "read-only"',
            'developer_instructions = """',
            $body.TrimEnd(),
            '"""',
            ''
        ) -join "`n"
        $outFile = Join-Path $destDir ($meta.Name + '.toml')
        [System.IO.File]::WriteAllText($outFile, $toml)
        $written++
    }
    return $written
}

# --- legs -----------------------------------------------------------------------

function Invoke-ClaudeLeg {
    if ($DryRun) {
        Write-Host "  [dry-run] claude plugin marketplace update $MarketplaceId; install-or-update $PluginId"
        Leg 'claude' 'ok' 'dry-run'; return
    }
    $r = Invoke-Native 'claude' @('plugin', 'marketplace', 'update', $MarketplaceId)
    if ($r.Code -ne 0) {
        # Marketplace not registered on this machine yet (no project trust prompt seen).
        $add = Invoke-Native 'claude' @('plugin', 'marketplace', 'add', 'vladSirin/myst-agentic-workflow')
        if ($add.Code -ne 0) {
            $add.Out | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" }
            Leg 'claude' 'FAIL' 'marketplace update and add both failed'; return
        }
    }
    $list = Invoke-Native 'claude' @('plugin', 'list')
    $installed = ($list.Code -eq 0) -and (($list.Out -join "`n") -match 'myst-dev-kit')
    if ($installed) { $r = Invoke-Native 'claude' @('plugin', 'update',  $PluginId) }
    else            { $r = Invoke-Native 'claude' @('plugin', 'install', $PluginId) }
    if ($r.Code -ne 0) {
        $r.Out | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" }
        Leg 'claude' 'FAIL' 'plugin install/update failed'; return
    }
    Leg 'claude' 'ok' 'restart your Claude session to load the new version'
}

function Invoke-CodexLeg([string]$srcRoot) {
    $codexHomeDir = $CodexHome
    if (-not $codexHomeDir) { $codexHomeDir = Join-Path $HOME '.codex' }
    $agentsDir = Join-Path $codexHomeDir 'agents'
    if ($Uninstall) {
        if (-not $DryRun) {
            foreach ($meta in $AgentMeta) {
                $f = Join-Path $agentsDir ($meta.Name + '.toml')
                if (Test-Path $f) { Remove-Item -LiteralPath $f -Force }
            }
        }
        Leg 'codex' 'ok' 'generated agents removed (plugin untouched; use codex plugin remove for that)'
        return
    }
    if ($DryRun) {
        Write-Host "  [dry-run] codex plugin marketplace add/upgrade; plugin add $PluginId; generate agents -> $agentsDir"
        Leg 'codex' 'ok' 'dry-run'; return
    }
    # -CodexHome set = test sandbox: generate files only, never drive the real CLI
    # (a test must not mutate the user's actual plugin/marketplace state).
    if ((Test-Cli 'codex') -and -not $CodexHome) {
        # `marketplace add` on an already-registered marketplace errors; tolerate it.
        $null = Invoke-Native 'codex' @('plugin', 'marketplace', 'add', 'vladSirin/myst-agentic-workflow')
        $up = Invoke-Native 'codex' @('plugin', 'marketplace', 'upgrade')
        if ($up.Code -ne 0) {
            $up.Out | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" }
            Leg 'codex' 'FAIL' 'marketplace upgrade failed'; return
        }
        # Always attempt the add -- codex errors harmlessly when already installed.
        # Never gate on grepping the plugin NAME out of `codex plugin list`: the name
        # appears in the table even when its row says "not installed" (measured), and
        # the command can exit non-zero while printing a valid table. The row TEXT
        # after the add is the only reliable signal.
        $null = Invoke-Native 'codex' @('plugin', 'add', $PluginId)
        $listNow = Invoke-Native 'codex' @('plugin', 'list')
        if (($listNow.Out -join "`n") -match ([regex]::Escape($PluginId) + '\s+not\s+installed')) {
            $listNow.Out | Select-Object -Last 4 | ForEach-Object { Write-Host "    $_" }
            Leg 'codex' 'FAIL' 'plugin still not installed after add'; return
        }
    }
    $n = Write-CodexAgents (Join-Path $srcRoot 'plugins/myst-dev-kit/agents') $agentsDir
    Leg 'codex' 'ok' "$n reviewer agent(s) generated (sandbox_mode read-only)"
}

function Invoke-OpencodeLeg([string]$srcRoot) {
    $cfgDir = $OpencodeConfigDir
    if (-not $cfgDir) { $cfgDir = Join-Path (Join-Path $HOME '.config') 'opencode' }
    $cfgFile    = Join-Path $cfgDir 'opencode.json'
    $agentsDir  = Join-Path (Join-Path $cfgDir 'agents') 'myst'
    $skillsPath = ((Join-Path $srcRoot 'plugins/myst-dev-kit/skills') -replace '\\', '/')

    # Load (or start) the global config. A file that does not parse as strict JSON
    # (user JSONC) is never touched: print the snippet and let the user paste it.
    $cfg = $null
    if (Test-Path $cfgFile) {
        $rawCfg = Get-Content -Raw -LiteralPath $cfgFile
        if (Test-StrictJson $rawCfg) { $cfg = $rawCfg | ConvertFrom-Json }
        else {
            Write-Host "  $cfgFile did not parse as strict JSON (comments?). NOT touching it."
            Write-Host '  Merge this yourself:'
            Write-Host ('    "skills": { "paths": ["' + $skillsPath + '"] },')
            Write-Host '    "mcp": { "unreal-engine": { "type": "remote", "url": "http://127.0.0.1:8092/mcp", "enabled": true } }'
            Leg 'opencode' 'FAIL' 'config is not strict JSON; snippet printed for manual paste'
            return
        }
    }
    if (-not $cfg) { $cfg = New-Object psobject }

    if ($Uninstall) {
        $skills = Get-Prop $cfg 'skills'
        if ($skills) {
            $paths = @(@(Get-Prop $skills 'paths') | Where-Object {
                $_ -and (($_.ToString() -replace '\\', '/') -notmatch 'myst-agentic-workflow|myst-dev-kit/skills') })
            if ($paths.Count -gt 0) { Set-Prop $skills 'paths' ([object[]]$paths) }
            else { Remove-Prop $skills 'paths'; if ($skills.PSObject.Properties.Name.Count -eq 0) { Remove-Prop $cfg 'skills' } }
        }
        $mcp = Get-Prop $cfg 'mcp'
        if ($mcp) { Remove-Prop $mcp 'unreal-engine'; if ($mcp.PSObject.Properties.Name.Count -eq 0) { Remove-Prop $cfg 'mcp' } }
        $perm = Get-Prop $cfg 'permission'
        if ($perm) {
            $skillPerm = Get-Prop $perm 'skill'
            if ($skillPerm) {
                foreach ($s in $ManualSkills) { Remove-Prop $skillPerm $s }
                if ($skillPerm.PSObject.Properties.Name.Count -eq 0) { Remove-Prop $perm 'skill' }
            }
            if ($perm.PSObject.Properties.Name.Count -eq 0) { Remove-Prop $cfg 'permission' }
        }
        $agentCfg = Get-Prop $cfg 'agent'
        if ($agentCfg) {
            foreach ($meta in $AgentMeta) { Remove-Prop $agentCfg ('myst-dev-kit:' + $meta.Name) }
            if ($agentCfg.PSObject.Properties.Name.Count -eq 0) { Remove-Prop $cfg 'agent' }
        }
        if ((-not $DryRun) -and (Test-Path $agentsDir)) {
            Remove-Item -LiteralPath $agentsDir -Recurse -Force
        }
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
            [System.IO.File]::WriteAllText($cfgFile, (ConvertTo-Json -InputObject $cfg -Depth 100))
        }
        Leg 'opencode' 'ok' 'config entries and generated agents removed (clone left in place)'
        return
    }

    if ($DryRun) {
        Write-Host "  [dry-run] merge skills.paths/mcp/permission.skill into $cfgFile; generate agents -> $agentsDir"
        Leg 'opencode' 'ok' 'dry-run'; return
    }

    # skills.paths: REPLACE any existing myst entry, never append -- duplicate skill
    # names resolve last-scanned-wins in opencode, silently.
    $skills = Get-Prop $cfg 'skills'
    if (-not $skills) { $skills = New-Object psobject; Set-Prop $cfg 'skills' $skills }
    $kept = @(@(Get-Prop $skills 'paths') | Where-Object {
        $_ -and (($_.ToString() -replace '\\', '/') -notmatch 'myst-agentic-workflow|myst-dev-kit/skills') })
    Set-Prop $skills 'paths' ([object[]]($kept + $skillsPath))

    $mcp = Get-Prop $cfg 'mcp'
    if (-not $mcp) { $mcp = New-Object psobject; Set-Prop $cfg 'mcp' $mcp }
    $ue = New-Object psobject
    Set-Prop $ue 'type' 'remote'
    Set-Prop $ue 'url' 'http://127.0.0.1:8092/mcp'
    Set-Prop $ue 'enabled' $true
    Set-Prop $mcp 'unreal-engine' $ue

    $perm = Get-Prop $cfg 'permission'
    if (-not $perm) { $perm = New-Object psobject; Set-Prop $cfg 'permission' $perm }
    $skillPerm = Get-Prop $perm 'skill'
    if (-not $skillPerm) { $skillPerm = New-Object psobject; Set-Prop $perm 'skill' $skillPerm }
    foreach ($s in $ManualSkills) { Set-Prop $skillPerm $s 'ask' }

    # OpenCode also consumes installed CLAUDE plugins (measured on 1.18.19): the
    # plugin's reviewer agents surface as 'myst-dev-kit:<name>' subagents that
    # resolve with edit:true -- Claude's `tools:` string does not restrict them
    # there. Disable those writable twins; the generated myst/<name> variants
    # (edit deny) are the ones to spawn.
    $agentCfg = Get-Prop $cfg 'agent'
    if (-not $agentCfg) { $agentCfg = New-Object psobject; Set-Prop $cfg 'agent' $agentCfg }
    foreach ($meta in $AgentMeta) {
        $twin = 'myst-dev-kit:' + $meta.Name
        $entry = Get-Prop $agentCfg $twin
        if (-not $entry) { $entry = New-Object psobject; Set-Prop $agentCfg $twin $entry }
        Set-Prop $entry 'disable' $true
    }

    New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
    if (Test-Path $cfgFile) { Copy-Item -LiteralPath $cfgFile -Destination ($cfgFile + '.bak-myst-setup') -Force }
    [System.IO.File]::WriteAllText($cfgFile, (ConvertTo-Json -InputObject $cfg -Depth 100))

    $n = Write-OpencodeAgents (Join-Path $srcRoot 'plugins/myst-dev-kit/agents') $agentsDir

    # Self-verify: prove delivery, do not assume it. Filesystem first, CLI when present.
    $problems = @()
    try { $null = Get-Content -Raw -LiteralPath $cfgFile | ConvertFrom-Json }
    catch { $problems += 'written config does not parse back' }
    if (-not (Test-Path (Join-Path $skillsPath 'tdd/SKILL.md'))) { $problems += "skills path looks wrong: $skillsPath" }
    if ($n -lt $AgentMeta.Count) { $problems += "only $n of $($AgentMeta.Count) agents generated" }
    if ((Test-Cli 'opencode') -and -not $OpencodeConfigDir) {
        # Only meaningful against the real global config; a test sandbox is invisible
        # to the opencode CLI, which reads the real one.
        $sk = Invoke-Native 'opencode' @('debug', 'skill')
        if ($sk.Code -eq 0 -and (($sk.Out -join "`n") -notmatch 'review-changes|tdd')) {
            $problems += 'opencode debug skill does not list the kit skills'
        }
        $ag = Invoke-Native 'opencode' @('agent', 'list')
        if ($ag.Code -eq 0 -and (($ag.Out -join "`n") -notmatch 'architecture-reviewer')) {
            $problems += 'opencode agent list does not show the generated reviewers'
        }
    }
    if ($problems.Count -gt 0) { Leg 'opencode' 'FAIL' ($problems -join '; '); return }
    Leg 'opencode' 'ok' "skills registered, MCP + ask-map written, $n agent(s) generated"
}

# --- main -----------------------------------------------------------------------

Write-Host 'myst-dev-kit setup'
Write-Host '=================='

$wantClaude   = ($Tool -eq 'claude')   -or ($Tool -eq 'auto' -and (Test-Cli 'claude'))
$wantCodex    = ($Tool -eq 'codex')    -or ($Tool -eq 'auto' -and (Test-Cli 'codex'))
$wantOpencode = ($Tool -eq 'opencode') -or ($Tool -eq 'auto' -and (Test-Cli 'opencode'))

if (-not ($wantClaude -or $wantCodex -or $wantOpencode)) {
    Write-Host 'No supported AI CLI found on PATH (claude, codex, opencode) and no -Tool given.'
    exit 1
}

# Codex agent generation and everything opencode need the package source on disk.
$srcRoot = $null
if ($wantCodex -or $wantOpencode) {
    $srcRoot = Resolve-SourceRoot
    Write-Host "Package source: $srcRoot"
    $srcOk = $false
    try { $srcOk = Update-Clone $srcRoot } catch { Write-Host "  $($_.Exception.Message)" }
    if (-not $srcOk) {
        Leg 'source' 'FAIL' 'could not prepare the package clone'
        if ($wantCodex)    { Leg 'codex'    'skip' 'no package source' }
        if ($wantOpencode) { Leg 'opencode' 'skip' 'no package source' }
        $wantCodex = $false; $wantOpencode = $false
    }
}

# Per-leg isolation: one tool's broken CLI must not abort the others' updates.
if ($wantClaude) {
    try { Invoke-ClaudeLeg } catch { Leg 'claude' 'FAIL' $_.Exception.Message }
} elseif ($Tool -eq 'auto') { Leg 'claude' 'skip' 'not on PATH' }

if ($wantCodex) {
    try { Invoke-CodexLeg $srcRoot } catch { Leg 'codex' 'FAIL' $_.Exception.Message }
} elseif ($Tool -eq 'auto') { Leg 'codex' 'skip' 'not on PATH' }

if ($wantOpencode) {
    try { Invoke-OpencodeLeg $srcRoot } catch { Leg 'opencode' 'FAIL' $_.Exception.Message }
} elseif ($Tool -eq 'auto') { Leg 'opencode' 'skip' 'not on PATH' }

Write-Host ''
Write-Host 'Summary:'
$legResults | ForEach-Object { Write-Host ("  {0,-8} {1,-6} {2}" -f $_.Leg, $_.Status, $_.Note) }

$failed = @($legResults | Where-Object { $_.Status -eq 'FAIL' })
if ($failed.Count -gt 0) { exit 1 } else { exit 0 }
