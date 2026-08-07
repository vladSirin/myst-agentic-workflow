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
#   Deliberate divergences are normal and expected -- on a project supporting two
#   harnesses, permanent divergence is the DESIGN, not the defect.
#
# BASELINE MODE (v4.29.0) -- drift detection, not difference detection
#   Reporting every difference forever is how a real detector becomes background noise:
#   a project with sanctioned divergences got this advisory at every single SessionStart,
#   asking for a confirmation it had no way to record. So it can now record one.
#
#   With a baseline file present, this script reports only what CHANGED since that file
#   was written -- which is what the paragraph above always said the useful signal was.
#   Without one, behaviour is unchanged from v4.28.0 and earlier: baseline mode is opt-in
#   by the file's presence and nothing else.
#
#   The recorded signature is a unified diff with the @@ line numbers stripped, so an
#   unrelated edit elsewhere in the section does NOT re-flag the set, while a change to
#   WHICH rules diverge does. It is stored as readable diff text, not a hash, so a
#   reviewer can see exactly what was sanctioned.
#
# USAGE
#   check-rules-alignment.sh [--advisory] [--baseline <file>] [--write-baseline]
#                            [<claude-md>] [<agents-md>]
#     --advisory         print findings, always exit 0 (for SessionStart hooks)
#     --baseline <file>  baseline path (default: .claude/rules-alignment.baseline)
#     --write-baseline   record the CURRENT divergence set as sanctioned, then exit
#
#   exit 0 : sections identical, nothing to check, baseline matched, --advisory, or
#            --write-baseline succeeded
#   exit 1 : the sections differ with no baseline recorded, OR the divergence set
#            changed since the baseline was recorded

set -uo pipefail

ADVISORY=0
WRITE_BASELINE=0
BASELINE=""
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --advisory)       ADVISORY=1 ;;
    --write-baseline) WRITE_BASELINE=1 ;;
    --baseline)       if [ $# -gt 1 ]; then shift; BASELINE="$1"; fi ;;
    --baseline=*)     BASELINE="${1#--baseline=}" ;;
    *)                POSITIONAL+=("$1") ;;
  esac
  shift
done

CLAUDE_MD="${POSITIONAL[0]:-CLAUDE.md}"
AGENTS_MD="${POSITIONAL[1]:-AGENTS.md}"
BASELINE="${BASELINE:-.claude/rules-alignment.baseline}"

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
  if [ "$WRITE_BASELINE" -eq 1 ]; then
    echo "Rules alignment: sections are identical - nothing to record, no baseline written."
    echo "  (with no divergence to sanction, any future difference is news and should be loud)"
    exit 0
  fi
  echo "Rules alignment: hard-rules sections are identical."
  exit 0
fi

tmp_a="$(mktemp)"; tmp_b="$(mktemp)"
trap 'rm -f "$tmp_a" "$tmp_b"' EXIT
printf '%s\n' "$a" > "$tmp_a"
printf '%s\n' "$b" > "$tmp_b"

# The signature: unified diff minus its two header lines (mktemp names are random, so
# they can never be part of a stable signature) and minus the @@ line numbers.
# tail -n +3 rather than a grep on '^---' / '^+++': a REMOVED markdown rule renders as
# '----', which such a grep would silently eat.
signature="$(diff -u "$tmp_a" "$tmp_b" 2>/dev/null | tail -n +3 | sed 's/^@@ .*/@@/')"
hunks="$(printf '%s\n' "$signature" | grep -c '^@@' || true)"

if [ "$WRITE_BASELINE" -eq 1 ]; then
  dir="$(dirname "$BASELINE")"
  if [ ! -d "$dir" ] && ! mkdir -p "$dir" 2>/dev/null; then
    echo "Rules alignment: cannot create $dir - baseline NOT written." >&2
    exit 1
  fi
  {
    echo "# rules-alignment baseline -- the SANCTIONED per-tool divergences between the"
    echo "# hard rules of $CLAUDE_MD and $AGENTS_MD, recorded deliberately."
    echo "#"
    echo "# Generated by: check-rules-alignment.sh --write-baseline"
    echo "#"
    echo "# Below is a unified diff with line numbers stripped. An unrelated edit elsewhere"
    echo "# in the section does NOT re-flag the set; a change to WHICH rules diverge does."
    echo "# Re-record only after confirming the new divergence is intentional."
    printf '%s\n' "$signature"
  } > "$BASELINE" || { echo "Rules alignment: could not write $BASELINE." >&2; exit 1; }
  echo "Rules alignment: baseline recorded - ${hunks:-?} sanctioned divergence(s) -> $BASELINE"
  exit 0
fi

# Comment lines are stripped from the recorded file before comparing. A diff body line
# can begin with ' ', '-', '+', '@' or '\', never '#', so this cannot eat signature data.
baseline_sig=""
if [ -f "$BASELINE" ]; then
  baseline_sig="$(grep -v '^#' "$BASELINE" 2>/dev/null || true)"
fi

if [ -n "$baseline_sig" ]; then
  if [ "$signature" = "$baseline_sig" ]; then
    echo "Rules alignment: OK - ${hunks:-?} sanctioned divergence(s), unchanged."
    exit 0
  fi
  base_hunks="$(printf '%s\n' "$baseline_sig" | grep -c '^@@' || true)"
  echo "Rules alignment: hard-rules divergence CHANGED since the recorded baseline."
  echo "  Baseline ($BASELINE) sanctioned ${base_hunks:-?} hunk(s); the files now differ in ${hunks:-?}."
  echo "  Review the change, then re-record it if it is deliberate:"
  echo "    diff <(sed -n '/## Hard rules/,/^## /p' $CLAUDE_MD) <(sed -n '/## Hard rules/,/^## /p' $AGENTS_MD)"
  echo "    bash $0 --write-baseline"
  [ "$ADVISORY" -eq 1 ] && exit 0
  exit 1
fi

echo "Rules alignment: $CLAUDE_MD and $AGENTS_MD hard rules differ in ${hunks:-?} hunk(s)."
echo "  Confirm each is a deliberate per-tool difference, not drift:"
echo "    diff <(sed -n '/## Hard rules/,/^## /p' $CLAUDE_MD) <(sed -n '/## Hard rules/,/^## /p' $AGENTS_MD)"
echo "  Once confirmed, record them so only CHANGES to the set are reported:"
echo "    bash $0 --write-baseline"

[ "$ADVISORY" -eq 1 ] && exit 0
exit 1
