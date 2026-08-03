# fake-p4.ps1 -- Test-only p4 shim. Dispatched by a sibling p4.bat that is
# prepended to PATH for the duration of a test. Scenarios are seeded via
# environment variables, NOT shared with the real depot. Used by
# run-pending-opens-tests.ps1 to exercise preflight checks 4 and 5 in
# isolation.
#
# Recognized env vars (all optional, default to empty/nothing):
#   FAKE_P4_CLIENT_ROOT          -- Client root path returned by 'p4 info'.
#   FAKE_P4_OPENED               -- Newline-joined lines for 'p4 opened'.
#   FAKE_P4_OPENED_DEFAULT       -- Lines for 'p4 opened -c default'.
#   FAKE_P4_HAVE                 -- Lines for 'p4 have <root>/...'.
#   FAKE_P4_FSTAT                -- Map of depot paths to headRev, formatted
#                                   as "<depot>=<rev>" entries joined by `;`.
#   FAKE_P4_DEPOT_ROOT           -- Depot root returned by 'p4 where'. Defaults to
#                                   //UEPrototype/main to match the existing fixtures.
$ErrorActionPreference = 'Continue'
$argv = $args

if ($argv.Count -eq 0) { exit 0 }

# Strip p4's GLOBAL flags before dispatching on the verb. The preflight invokes
# `p4 -ztag -F "%depotFile%" where ...`; without this the switch below saw
# '-ztag' as the verb and fell through to `default { exit 0 }`, silently
# returning nothing. That is what made every depot-aware scenario in
# run-pending-opens-tests.ps1 fail after the depot root stopped being hardcoded.
$skip = 0
while ($skip -lt $argv.Count) {
    if ($argv[$skip] -eq '-ztag') { $skip++; continue }
    if ($argv[$skip] -eq '-F')    { $skip += 2; continue }
    break
}
if ($skip -gt 0) { $argv = @($argv[$skip..($argv.Count - 1)]) }
if ($argv.Count -eq 0) { exit 0 }

switch ($argv[0]) {
    'where' {
        # Real p4 maps a local path to its depot path; the preflight takes the
        # first non-exclusion line and strips the trailing '/...'.
        $root = $env:FAKE_P4_DEPOT_ROOT
        if (-not $root) { $root = '//UEPrototype/main' }
        Write-Output ($root + '/...')
        exit 0
    }
    'info' {
        $root = $env:FAKE_P4_CLIENT_ROOT
        if (-not $root) { exit 0 }
        Write-Output ("Client root: " + $root)
        exit 0
    }
    'opened' {
        # 'p4 opened' or 'p4 opened -c default'
        if ($argv.Count -ge 3 -and $argv[1] -eq '-c' -and $argv[2] -eq 'default') {
            if ($env:FAKE_P4_OPENED_DEFAULT) { Write-Output $env:FAKE_P4_OPENED_DEFAULT }
            exit 0
        }
        if ($env:FAKE_P4_OPENED) { Write-Output $env:FAKE_P4_OPENED }
        exit 0
    }
    'have' {
        if ($env:FAKE_P4_HAVE) { Write-Output $env:FAKE_P4_HAVE }
        exit 0
    }
    'fstat' {
        # Expected: fstat -T headRev <depot-path>
        $depot = $null
        for ($i = 1; $i -lt $argv.Count; $i++) {
            if ($argv[$i] -like '//*') { $depot = $argv[$i]; break }
        }
        if (-not $depot) { exit 0 }
        $map = $env:FAKE_P4_FSTAT
        if (-not $map) { exit 0 }
        foreach ($entry in $map.Split(';')) {
            if (-not $entry) { continue }
            $kv = $entry.Split('=', 2)
            if ($kv.Count -ne 2) { continue }
            if ($kv[0] -eq $depot) {
                Write-Output ("... headRev " + $kv[1])
                exit 0
            }
        }
        exit 0
    }
    default { exit 0 }
}
