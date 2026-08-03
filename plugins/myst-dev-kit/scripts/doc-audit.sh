#!/usr/bin/env bash
# Doc Audit — validates {{game_docs_root}}/ filenames against Claude/DocumentStandard.md
# Runs as a SessionStart hook so every Claude session starts with a clean check.

DOCS_DIR="{{game_docs_root}}"
VALID_PREFIXES="^(design|guide|plan|ref|ToBeDeleted)_"
BANNED_SUFFIXES="_(Updated|Deprecated|Final|New)\.md$"

violations=()

for file in "$DOCS_DIR"/*.md; do
  [ -f "$file" ] || continue
  basename=$(basename "$file")

  # Check: must start with a valid type prefix
  if ! echo "$basename" | grep -qE "$VALID_PREFIXES"; then
    violations+=("$basename|Missing type prefix (design_, guide_, plan_, ref_)")
  fi

  # Check: must not use banned suffixes
  if echo "$basename" | grep -qE "$BANNED_SUFFIXES"; then
    suffix=$(echo "$basename" | grep -oE '_(Updated|Deprecated|Final|New)')
    violations+=("$basename|Banned suffix '${suffix}' — remove it or use _WIP / _v{N}")
  fi
done

# Claude/Codex rule parity. Failure-isolated on purpose: this runs at every
# teammate's SessionStart under a timeout, so a bug in the parity check must not
# degrade session start. --advisory keeps it reporting-only here; run the script
# directly (no flag) for a gating exit code.
if [ -x ".claude/scripts/check-rule-parity.sh" ] || [ -f ".claude/scripts/check-rule-parity.sh" ]; then
  bash .claude/scripts/check-rule-parity.sh --advisory || true
fi

if [ ${#violations[@]} -eq 0 ]; then
  echo "Doc audit: all clean."
else
  echo "Doc audit: ${#violations[@]} violation(s) found"
  echo ""
  echo "| File | Issue |"
  echo "|------|-------|"
  for v in "${violations[@]}"; do
    IFS='|' read -r fname issue <<< "$v"
    echo "| $fname | $issue |"
  done
fi
