#!/usr/bin/env bash
# Doc Audit — validates {{game_docs_root}}/ docs against .claude/rules/DocumentStandard.md
# Runs as a SessionStart hook so every session starts with a real check.
#
# Advisory by design: always exits 0. It reports, it never blocks a session.
#
# WHY IT RECURSES (it used to glob only the top level): a non-recursive audit
# reported "all clean" over a tree holding 7 lifecycle violations, because every
# subdirectory was invisible to it. A check that cannot see most of what it claims
# to cover is worse than no check — people trust it.

DOCS_DIR="{{game_docs_root}}"
# game_direction_ is a real, in-use prefix alongside the four in DocumentStandard.md.
VALID_PREFIXES="^(design|guide|plan|ref|game_direction|ToBeDeleted)_"
BANNED_SUFFIXES="_(Updated|Deprecated|Final|New)\.md$"

# Directories whose naming is deliberately NOT ours to dictate:
#   adr/   numbered ADR convention (0001-...), an established standard
#   _Raw/  leads-only raw source material (research_*, transcripts) — names come
#          from the source, not from us
# They are exempt from the PREFIX check only; banned suffixes and lifecycle still apply.
PREFIX_EXEMPT_DIRS="/(adr|_Raw)/"

violations=()

# Read a declared status from the front matter of a doc.
# Tolerant on purpose — this repo writes it as `**Status**: WIP`, `**Status** WIP`,
# `**Status:** Draft`, sometimes with a trailing emoji or a long parenthetical.
# Case-insensitive, first match wins, value is its first word.
#
# The 20-line window is measured, not guessed: a deprecation banner above the title
# pushes the metadata block down (one real doc declares its status on line 11, and an
# 8-line window silently missed it — a false negative on exactly the drift this check
# exists to find). Widening from 12 to 30 lines changed nothing on a 60-file tree, so
# 20 buys the catch without inviting prose false-positives.
STATUS_SCAN_LINES=20
get_status() {
  local line
  line=$(head -n "$STATUS_SCAN_LINES" "$1" 2>/dev/null | grep -i -m1 'status')
  [ -n "$line" ] || return 0
  echo "$line" \
    | sed -E 's/.*[Ss][Tt][Aa][Tt][Uu][Ss]//' \
    | sed -E 's/^[*:[:space:]]+//' \
    | grep -oE '^[A-Za-z-]+' \
    | tr '[:lower:]' '[:upper:]'
}

while IFS= read -r file; do
  [ -f "$file" ] || continue
  basename=$(basename "$file")

  # --- Naming ---
  if ! echo "$file" | grep -qE "$PREFIX_EXEMPT_DIRS"; then
    if ! echo "$basename" | grep -qE "$VALID_PREFIXES"; then
      violations+=("$basename|Missing type prefix (design_, guide_, plan_, ref_)")
    fi
  fi

  if echo "$basename" | grep -qE "$BANNED_SUFFIXES"; then
    suffix=$(echo "$basename" | grep -oE '_(Updated|Deprecated|Final|New)')
    violations+=("$basename|Banned suffix '${suffix}' — remove it or use _WIP / _v{N}")
  fi

  # --- Lifecycle: does the declared status contradict the filename? ---
  # This is the drift mode filename checks cannot catch: a doc that says COMPLETE
  # while still named _WIP, or a ToBeDeleted_ file nobody ever marked.
  status=$(get_status "$file")

  case "$basename" in
    ToBeDeleted_*)
      if [ -z "$status" ]; then
        violations+=("$basename|ToBeDeleted_ but no Status line — say why it is going, or rename it")
      elif [ "$status" = "COMPLETE" ] || [ "$status" = "WIP" ]; then
        violations+=("$basename|ToBeDeleted_ but Status is ${status} — delete it or drop the prefix")
      fi
      ;;
    *_WIP.md)
      if [ "$status" = "COMPLETE" ] || [ "$status" = "DEPRECATED" ]; then
        violations+=("$basename|Status ${status} but filename still says _WIP — rename it")
      fi
      ;;
    *)
      if [ "$status" = "WIP" ]; then
        violations+=("$basename|Status WIP but filename has no _WIP suffix — rename it")
      fi
      ;;
  esac
done < <(find "$DOCS_DIR" -type f -name '*.md' 2>/dev/null | sort)

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

exit 0
