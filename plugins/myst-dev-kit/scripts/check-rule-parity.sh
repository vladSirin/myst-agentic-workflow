#!/usr/bin/env bash
# check-rule-parity.sh -- always-on Claude rules must have a Codex counterpart.
#
# WHY THIS EXISTS
#   Claude Code auto-loads every .claude/rules/*.md that has no `paths:` frontmatter,
#   on every session. Codex has no equivalent mechanism: it reads AGENTS.md and
#   nothing else. So a rule added to .claude/rules/ reaches Claude teammates
#   immediately and Codex teammates never -- silently, with no error anywhere.
#
#   That is not hypothetical. BlueprintPinVerification.md (3 KB, a HARD rule that
#   exists because two changelists shipped five wrong Blueprint-pin claims) sat in
#   .claude/rules/ with zero mentions in AGENTS.md, as did PreImplementationGate.md.
#
# WHAT IT PROVES -- AND WHAT IT DOES NOT
#   It greps AGENTS.md for each always-on rule's FILENAME. That proves the rule is
#   *mentioned*. It does NOT prove the Codex text is equivalent, current, or even
#   coherent: a line reading `TODO: BlueprintPinVerification` satisfies it.
#   A content/length floor was considered and rejected -- it would be brittle
#   (rules legitimately compress to a paragraph for Codex) without being much
#   harder to game. Treat green as "someone wrote a counterpart", not "the
#   counterpart is good".
#
#   The filename is the anchor deliberately: no frontmatter is added to any rule
#   file (introducing an unknown key risks the loader skipping the rule -- which
#   would manufacture the exact failure this check prevents), and citing the file
#   by path is useful to a human Codex reader anyway.
#
# USAGE
#   check-rule-parity.sh [--advisory] [<agents-md-path>]
#     --advisory   print findings, always exit 0 (for SessionStart hooks)
#     <path>       AGENTS.md to check; defaults to ./AGENTS.md. The argument
#                  exists so the failure branch can be tested against a scratch
#                  copy instead of editing a version-controlled file.
#
#   exit 0 : parity holds, or nothing to check, or --advisory
#   exit 1 : an always-on rule has no counterpart in AGENTS.md

set -uo pipefail

ADVISORY=0
AGENTS_MD=""
for arg in "$@"; do
  case "$arg" in
    --advisory) ADVISORY=1 ;;
    *)          AGENTS_MD="$arg" ;;
  esac
done

RULES_DIR=".claude/rules"
[ -n "$AGENTS_MD" ] || AGENTS_MD="AGENTS.md"

# A consumer with no rules dir, or one that doesn't use Codex at all, has nothing
# to be out of parity with. Say so and succeed -- this ships to every consumer.
if [ ! -d "$RULES_DIR" ]; then
  echo "Rule parity: no $RULES_DIR — nothing to check."
  exit 0
fi
if [ ! -f "$AGENTS_MD" ]; then
  echo "Rule parity: no $AGENTS_MD (Codex not set up here) — nothing to check."
  exit 0
fi

missing=()
advisory_missing=()
checked=0

for rule in "$RULES_DIR"/*.md; do
  [ -e "$rule" ] || continue
  stem=$(basename "$rule" .md)

  # Always-on == no `paths:` key in the frontmatter block. Only inspect the first
  # few lines: a `paths:` mention in prose further down is not frontmatter.
  if head -n 10 "$rule" | grep -qE '^paths:'; then
    scoped=1
  else
    scoped=0
  fi

  checked=$((checked + 1))
  if grep -q -- "$stem" "$AGENTS_MD"; then
    continue
  fi

  if [ "$scoped" -eq 1 ]; then
    advisory_missing+=("$stem")
  else
    missing+=("$stem")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  # Path-scoped rules are summarised, never enumerated, when nothing is actually
  # wrong. They load on match for Claude, so their absence from AGENTS.md is a
  # nuance, not a defect -- and this runs at every SessionStart. Printing the same
  # two names forever is how a channel stops being read, which then hides the
  # finding that matters.
  if [ ${#advisory_missing[@]} -gt 0 ]; then
    echo "Rule parity: OK — $checked rule(s) checked (${#advisory_missing[@]} path-scoped rule(s) have no $AGENTS_MD mention; they load on match for Claude, so this is informational only)."
  else
    echo "Rule parity: all $checked rule(s) have an $AGENTS_MD counterpart."
  fi
  exit 0
fi

if [ ${#advisory_missing[@]} -gt 0 ]; then
  echo "Rule parity: ${#advisory_missing[@]} path-scoped rule(s) not named in $AGENTS_MD (advisory, these load on match for Claude):"
  for r in "${advisory_missing[@]}"; do echo "  - $r"; done
fi

if [ ${#missing[@]} -gt 0 ]; then
  echo "Rule parity: ${#missing[@]} ALWAYS-ON rule(s) missing from $AGENTS_MD — Codex teammates never see them:"
  for r in "${missing[@]}"; do echo "  - $r  (fix: cite \`$RULES_DIR/$r.md\` in a hard rule)"; done
  [ "$ADVISORY" -eq 1 ] && exit 0
  exit 1
fi

exit 0
