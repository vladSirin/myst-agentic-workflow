#!/usr/bin/env bash
# check-rules-alignment.sh -- CLAUDE.md and AGENTS.md hard rules must stay diffable.
#
# WHY THIS EXISTS
#   check-rule-parity.sh proves a rule is *mentioned* in AGENTS.md. It says so in its own
#   header, deliberately. It would exit 0 with the hard-rules section completely rewritten.
#
#   Projects that keep a shared hard-rules baseline across both tools therefore have an
#   invariant nothing checks: the two files' rule sections should differ only by per-tool
#   pointers. Left as prose, that invariant is correct on the day it is written and
#   silently wrong later -- which is the same failure mode check-rule-parity.sh exists to
#   prevent, one level up.
#
# WHAT IT PROVES -- AND WHAT IT DOES NOT
#   It extracts the hard-rules section from both files and diffs them. It reports the
#   hunks; it does NOT judge whether a hunk is a legitimate per-tool difference, because
#   that requires reading. Treat output as "here is where they diverge, confirm each is
#   deliberate", not as "these are defects".
#
#   Deliberate divergences are normal and expected. A project that documents its sanctioned
#   ones (e.g. in Docs/agents/agent-context-parity.md) can diff this output against that
#   list; a project that does not should expect a stable, small set of hunks and should
#   look when the set changes.
#
# USAGE
#   check-rules-alignment.sh [--advisory] [<claude-md>] [<agents-md>]
#     --advisory   print findings, always exit 0 (for SessionStart hooks)
#
#   exit 0 : sections identical, nothing to check, or --advisory
#   exit 1 : the sections differ (see caveat above -- differing is not the same as wrong)

set -uo pipefail

ADVISORY=0
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --advisory) ADVISORY=1 ;;
    *)          POSITIONAL+=("$arg") ;;
  esac
done

CLAUDE_MD="${POSITIONAL[0]:-CLAUDE.md}"
AGENTS_MD="${POSITIONAL[1]:-AGENTS.md}"

# The section heading both files must share for this check to mean anything. Projects
# that do not use this convention get a clean no-op, not a false finding.
HEADING='^## Hard rules'

for f in "$CLAUDE_MD" "$AGENTS_MD"; do
  if [ ! -f "$f" ]; then
    echo "Rules alignment: no $f — nothing to check."
    exit 0
  fi
done

# Extract from the hard-rules heading up to (not including) the next level-2 heading.
extract_rules() {
  awk -v pat="$HEADING" '
    $0 ~ pat        { inblock = 1; next }
    inblock && /^## / { exit }
    inblock         { print }
  ' "$1"
}

a="$(extract_rules "$CLAUDE_MD")"
b="$(extract_rules "$AGENTS_MD")"

if [ -z "$a" ] || [ -z "$b" ]; then
  echo "Rules alignment: no '## Hard rules' section in both files — nothing to check."
  exit 0
fi

if [ "$a" = "$b" ]; then
  echo "Rules alignment: hard-rules sections are identical."
  exit 0
fi

# Count divergent hunks rather than dumping the whole diff at every SessionStart.
tmp_a="$(mktemp)"; tmp_b="$(mktemp)"
printf '%s\n' "$a" > "$tmp_a"
printf '%s\n' "$b" > "$tmp_b"
hunks="$(diff -u "$tmp_a" "$tmp_b" 2>/dev/null | grep -c '^@@' || true)"
rm -f "$tmp_a" "$tmp_b"

echo "Rules alignment: $CLAUDE_MD and $AGENTS_MD hard rules differ in ${hunks:-?} hunk(s)."
echo "  Confirm each is a deliberate per-tool difference, not drift:"
echo "    diff <(sed -n '/## Hard rules/,/^## /p' $CLAUDE_MD) <(sed -n '/## Hard rules/,/^## /p' $AGENTS_MD)"

[ "$ADVISORY" -eq 1 ] && exit 0
exit 1
