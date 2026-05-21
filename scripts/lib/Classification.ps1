# Classification.ps1 — Ownership bucket taxonomy (issue 09)
#
# Maps every manifest entry to exactly one of four mutually-exclusive ownership
# buckets, used by diff-installed.ps1, promote-from-project.ps1, and
# compare-with-package.ps1 (issue 10).
#
# Buckets are orthogonal to drift state. A file can be both 'package-core' (by
# ownership) and 'drift-package-owned' (by drift state). Each axis answers a
# different question:
#   - bucket  -> "who owns this and where would a promoted change land?"
#   - drift   -> "is the disk content what we expect right now?"
#
# Priority order (a file matching multiple gates is classified by the first):
#   1. local-only      (localOnly:true)             never reported as drift, never promoted
#   2. project-owned   (manual-only / human-owned)  reported for awareness, never promoted
#   3. package-core    (ownerOverlay:core)          promotes to templates/{tool|common}/
#   4. overlay         (ownerOverlay:non-core)      promotes to overlays/{ownerOverlay}/
#
# Note: this library does NOT set strict mode. Each consumer can opt in.

function Get-EntryProperty {
    param([Parameter(Mandatory)] $Entry, [Parameter(Mandatory)][string] $Name, $Default = $null)
    if ($null -eq $Entry) { return $Default }
    if ($Entry.PSObject.Properties.Match($Name).Count -eq 0) { return $Default }
    return $Entry.$Name
}

function Get-OwnershipBucket {
    param([Parameter(Mandatory)] $Entry)

    if ((Get-EntryProperty $Entry 'localOnly' $false)) { return 'local-only' }

    $mergeStrategy  = Get-EntryProperty $Entry 'mergeStrategy'
    $writablePolicy = Get-EntryProperty $Entry 'writablePolicy'
    $owner          = Get-EntryProperty $Entry 'owner'
    $ownerOverlay   = Get-EntryProperty $Entry 'ownerOverlay'

    if ($mergeStrategy -eq 'manual-only' -or $writablePolicy -eq 'human-owned' -or $owner -eq 'project') {
        return 'project-owned'
    }
    if ($ownerOverlay -eq 'core') { return 'package-core' }
    return 'overlay'
}

# For a given bucket, where would an upstream promotion of this entry land?
# Returns the relative path inside the package (templates/... or overlays/...).
function Get-PromotionTarget {
    param([Parameter(Mandatory)] $Entry)
    $bucket = Get-OwnershipBucket $Entry
    if ($bucket -in @('local-only','project-owned')) { return $null }
    $sourceTemplate = Get-EntryProperty $Entry 'sourceTemplate'
    if ($sourceTemplate) { return $sourceTemplate }
    # Fallback: build from bucket + path
    if ($bucket -eq 'package-core') {
        $tool = Get-EntryProperty $Entry 'tool'
        if ($tool -eq 'common') { return "templates/common/$($Entry.path)" }
        return "templates/$tool/$($Entry.path)"
    }
    $ownerOverlay = Get-EntryProperty $Entry 'ownerOverlay'
    return "overlays/$ownerOverlay/$($Entry.path)"
}

# True if entries of this bucket are eligible for upstream promotion.
function Test-IsPromotable {
    param([Parameter(Mandatory)][string] $Bucket)
    return $Bucket -in @('package-core','overlay')
}
