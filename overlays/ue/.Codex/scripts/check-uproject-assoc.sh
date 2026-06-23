#!/usr/bin/env bash
# check-uproject-assoc - preflight guard for UE source-tree + Perforce projects.
#
# Fails (exit 1) when a .uproject's "EngineAssociation" is NON-EMPTY (a machine-local
# engine GUID, or a launcher version like "5.7"). In a SOURCE-TREE project the .uproject
# lives beside Engine/, so EngineAssociation MUST be "": UE resolves the co-located engine
# by walking up the directory tree (engine source DesktopPlatformBase.cpp
# GetEngineIdentifierForProject) - no registry, no write, no prompt, portable across every
# synced machine.
#
# A committed non-empty value makes UnrealVersionSelector prompt teammates with "Select
# Unreal Engine Version"; picking one writes back into the read-only (Perforce) .uproject
# and fails with: "Couldn't set association for project. Check the file is writeable."
#
# COVERAGE: catches the agent / p4 CLI / CI submit paths, plus manual runs. It does NOT
# catch an ad-hoc submit made directly in P4V / p4 by a human - that vector needs a
# server-side submit trigger.
#
# Exit codes: 0 = OK (empty), 1 = BLOCKING (non-empty), 2 = no .uproject found.
# Run from the repo root.

# Discover the project's .uproject (nearest the root; first match).
UPROJECT=$(find . -maxdepth 3 -name '*.uproject' 2>/dev/null | sort | head -1)

if [ -z "$UPROJECT" ] || [ ! -f "$UPROJECT" ]; then
  echo "check-uproject-assoc: ERROR - no .uproject found under the repo root (run from repo root)." >&2
  exit 2
fi

# UE writes one JSON field per line; grab the EngineAssociation value.
assoc=$(grep -oE '"EngineAssociation"[[:space:]]*:[[:space:]]*"[^"]*"' "$UPROJECT" \
        | sed -E 's/.*"([^"]*)"$/\1/')

if [ -z "$assoc" ]; then
  echo "check-uproject-assoc: OK - EngineAssociation is empty ($UPROJECT)."
  exit 0
fi

cat >&2 <<EOF
check-uproject-assoc: BLOCKING - EngineAssociation is non-empty: "$assoc"

  File: $UPROJECT
  This is a source-tree project; EngineAssociation MUST be "".
  A non-empty value (machine GUID or launcher version) makes teammates hit:
    "Couldn't set association for project. Check the file is writeable."

  Fix before submitting:
    p4 edit $UPROJECT
    # set the line to:  "EngineAssociation": "",
    # re-run this check, then submit
EOF
exit 1