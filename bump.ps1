# bump.ps1 -- release helper. Sets the version in BOTH plugin manifests (the
# only two version sites), verifies CHANGELOG.md has the matching section, and
# with -Commit creates the release commit and tag. Without -Commit it edits the
# manifests and prints the commands to finish. PS 5.1-clean, ASCII only.
#
#   .\bump.ps1 -Version 5.0.0            # edit manifests, verify, print next steps
#   .\bump.ps1 -Version 5.0.0 -Commit    # also: git add + commit + tag v5.0.0
param(
    [Parameter(Mandatory = $true)][string] $Version,
    [switch] $Commit
)

$ErrorActionPreference = 'Stop'

if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
    Write-Error "Version must be X.Y.Z (got '$Version')"
    exit 1
}

$repo = $PSScriptRoot
$manifests = @(
    (Join-Path $repo 'plugins/myst-dev-kit/.claude-plugin/plugin.json'),
    (Join-Path $repo 'plugins/myst-dev-kit/.codex-plugin/plugin.json')
)

# CHANGELOG section gate first: tag it or don't bump it, and release.yml now
# hard-fails on a missing section -- catch that here, before anything is edited.
$changelog = Join-Path $repo 'CHANGELOG.md'
$found = Select-String -Path $changelog -Pattern ('^## \[' + [regex]::Escape($Version) + '\]') -Quiet
if (-not $found) {
    Write-Error "CHANGELOG.md has no '## [$Version]' section. Write it first."
    exit 1
}

foreach ($m in $manifests) {
    $raw = [IO.File]::ReadAllText($m)
    $new = [regex]::new('("version"\s*:\s*")[^"]+(")').Replace($raw, ('${1}' + $Version + '${2}'), 1)
    if ($new -eq $raw -and $raw -notmatch [regex]::Escape('"' + $Version + '"')) {
        Write-Error "No version field replaced in $m"
        exit 1
    }
    [IO.File]::WriteAllText($m, $new)
    Write-Host ("set {0} -> {1}" -f $m, $Version)
}

$tag = 'v' + $Version
if ($Commit) {
    git -C $repo add -- $manifests
    if ($LASTEXITCODE -ne 0) { exit 1 }
    git -C $repo commit -m ("chore: bump to {0}" -f $tag)
    if ($LASTEXITCODE -ne 0) { exit 1 }
    git -C $repo tag $tag
    if ($LASTEXITCODE -ne 0) { exit 1 }
    Write-Host ("committed and tagged {0}. Push with: git push origin main {0}" -f $tag)
} else {
    Write-Host 'Manifests updated. To finish:'
    Write-Host ('  git add plugins/myst-dev-kit/.claude-plugin/plugin.json plugins/myst-dev-kit/.codex-plugin/plugin.json')
    Write-Host ('  git commit -m "chore: bump to {0}"' -f $tag)
    Write-Host ('  git tag {0} ; git push origin main {0}' -f $tag)
}
exit 0
