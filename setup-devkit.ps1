# v5 retired this installer. Migration is two steps (see CHANGELOG v5.0.0):
#   1. .\retire-legacy.ps1 -WhatIf   (then without -WhatIf to clean v4 state)
#   2. your tool's one-line install from README.md
Write-Host 'v5: this installer is retired. Run retire-legacy.ps1, then your tool''s one-liner (see README.md).'
exit 1
