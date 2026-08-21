# run-vendor-hash-tests.ps1 -- CI wrapper so suite discovery picks up the vendored-hash gate.
#
# WHY A WRAPPER. CI discovers suites with `Get-ChildItem scripts/run-*-tests.ps1`
# (.github/workflows/tests.yml). vendored-hashes.ps1 does not match that glob, so without
# this file the gate runs only when a human types it from the CONTRIBUTING checklist --
# which is precisely the failure v4.43.0 was written to fix ("the detector existed and
# worked; it just was not on any checklist"). Adding a second unrun detector would have
# repeated the mistake in the same release that diagnosed it.
#
#   exit 0 : every vendored file matches its recorded hash
#   exit 1 : drift, a dropped file, or an undeclared divergence
param()
$ErrorActionPreference = 'Stop'

Write-Output "=============================================================="
Write-Output "Vendored-hash gate (ADR-0006: verbatim except recorded remaps)"
Write-Output "=============================================================="

& "$PSScriptRoot\vendored-hashes.ps1" -Verify
exit $LASTEXITCODE
