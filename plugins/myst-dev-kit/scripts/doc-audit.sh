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
#
# WHY SINGLE-PASS (2026-08-06): the old per-file get_status pipeline spawned ~6
# processes per file; measured 15-19s over 58 files on MSYS's slow fork, against
# a 30s SessionStart hook timeout — and it re-ran at every /clear and /compact.
# Filename checks are now pure bash (zero subprocesses per file); status
# extraction + lifecycle checks run as ONE awk process over the whole tree.

DOCS_DIR="{{game_docs_root}}"
# game_direction_ is a real, in-use prefix alongside the four in DocumentStandard.md.
VALID_PREFIXES='^(design|guide|plan|ref|game_direction|ToBeDeleted)_'
BANNED_SUFFIXES='_(Updated|Deprecated|Final|New)\.md$'

# Directories whose naming is deliberately NOT ours to dictate:
#   adr/   numbered ADR convention (0001-...), an established standard
#   _Raw/  leads-only raw source material (research_*, transcripts) — names come
#          from the source, not from us
# They are exempt from the PREFIX check only; banned suffixes and lifecycle still apply.
PREFIX_EXEMPT_DIRS='/(adr|_Raw)/'

# --- Docs-root sanity, two tiers (audit 2026-08-06) ---
# Unrendered install token -> LOUD: the audit found this package-source copy
# "auditing" a literal '{{game_docs_root}}' directory, finding nothing, and
# printing "all clean" — a false-clean. Configured-but-absent dir -> quiet note
# (legitimate for a new adopter). Both keep the advisory always-exit-0 contract.
case "$DOCS_DIR" in
  *'{{'*)
    echo "Doc audit: ERROR - docs root token is UNRENDERED ('$DOCS_DIR')." >&2
    echo "This copy ran from the package source or a broken install; run update.ps1 / upgrade.ps1 to render it. Audit skipped." >&2
    exit 0
    ;;
esac
if [ ! -d "$DOCS_DIR" ]; then
  echo "Doc audit: docs root '$DOCS_DIR' not found - nothing to audit."
  exit 0
fi

violations=()

# --- Collect files: one find ---
files=()
while IFS= read -r f; do files+=("$f"); done < <(find "$DOCS_DIR" -type f -name '*.md' 2>/dev/null | sort)

# --- Filename checks: pure bash, zero subprocesses per file ---
for file in "${files[@]}"; do
  base="${file##*/}"
  if ! [[ "$file" =~ $PREFIX_EXEMPT_DIRS ]]; then
    if ! [[ "$base" =~ $VALID_PREFIXES ]]; then
      violations+=("$base|Missing type prefix (design_, guide_, plan_, ref_, game_direction_)")
    fi
  fi
  if [[ "$base" =~ $BANNED_SUFFIXES ]]; then
    violations+=("$base|Banned suffix '_${BASH_REMATCH[1]}' — remove it or use _WIP / _v{N}")
  fi
done

# --- Status + lifecycle: ONE awk process over the whole tree ---
# Status is FIELD-ANCHORED on purpose: the old "first line containing 'status'"
# grab let prose mentioning status inside the 20-line scan window shadow the
# real field below it (false lifecycle verdicts). A real field starts a line OR
# a pipe-separated segment of a metadata row — both forms are measured in this
# repo (2026-08-06):
#   **Status**: WIP  |  Status: ready-for-agent  |  - Status: X
#   **Version**: v1.0 | **Updated**: 2026-04-15 | **Status**: SUPERSEDED
# The 20-line window is measured, not guessed (see git history of this check).
if [ ${#files[@]} -gt 0 ]; then
  while IFS= read -r vline; do
    [ -n "$vline" ] && violations+=("$vline")
  done < <(awk '
    function verdict(f, s,    b) {
      b = f; sub(/.*\//, "", b)
      if (b ~ /^ToBeDeleted_/) {
        if (s == "")
          print b "|ToBeDeleted_ but no Status line — say why it is going, or rename it"
        else if (s == "COMPLETE" || s == "WIP")
          print b "|ToBeDeleted_ but Status is " s " — delete it or drop the prefix"
      } else if (b ~ /_WIP\.md$/) {
        if (s == "COMPLETE" || s == "DEPRECATED")
          print b "|Status " s " but filename still says _WIP — rename it"
      } else {
        if (s == "WIP")
          print b "|Status WIP but filename has no _WIP suffix — rename it"
      }
    }
    FNR == 1 { if (prev != "") verdict(prev, st); prev = FILENAME; st = "" }
    FNR > 20 { nextfile }
    st != "" { next }
    {
      line = $0
      sub(/\r$/, "", line)
      n = split(line, seg, /\|/)
      for (i = 1; i <= n; i++) {
        s = seg[i]
        if (s ~ /^[[:space:]]*([-*>][[:space:]]+)?(\*\*|__)?[Ss][Tt][Aa][Tt][Uu][Ss]/) {
          v = s
          sub(/^[[:space:]]*([-*>][[:space:]]+)?(\*\*|__)?[Ss][Tt][Aa][Tt][Uu][Ss](\*\*|__)?/, "", v)
          sub(/^[*:[:space:]]+/, "", v)
          if (match(v, /^[A-Za-z-]+/)) { st = toupper(substr(v, RSTART, RLENGTH)); break }
        }
      }
    }
    END { if (prev != "") verdict(prev, st) }
  ' "${files[@]}")
fi

# Claude/Codex rule parity. Failure-isolated on purpose: this runs at every
# teammate's SessionStart under a timeout, so a bug in the parity check must not
# degrade session start. --advisory keeps it reporting-only here; run the script
# directly (no flag) for a gating exit code.
if [ -x ".claude/scripts/check-rule-parity.sh" ] || [ -f ".claude/scripts/check-rule-parity.sh" ]; then
  bash .claude/scripts/check-rule-parity.sh --advisory || true
fi

# Hard-rules alignment. Sibling of the parity check, separate on purpose: parity
# proves a rule is MENTIONED in AGENTS.md, this proves the shared hard-rules
# section has not drifted between the two files. Same failure isolation, same
# advisory-here / gating-when-run-directly contract. No-ops on projects that do
# not keep a shared '## Hard rules' section.
if [ -x ".claude/scripts/check-rules-alignment.sh" ] || [ -f ".claude/scripts/check-rules-alignment.sh" ]; then
  bash .claude/scripts/check-rules-alignment.sh --advisory || true
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

# --- Plugin version-staleness nudge (audit 2026-08-06) ---
# LOCAL files only, no network: compares the installed plugin version against
# the local marketplace clone's declared version. Catches installed-vs-clone lag
# (the audit's own demonstrated blind spot: cache at 4.27.0 for hours while the
# clone held 4.27.1). A release nobody has pulled from GitHub is out of scope —
# that still needs the release announcement. Silent when current or undetectable.
ipj="$HOME/.claude/plugins/installed_plugins.json"
mpj="$HOME/.claude/plugins/marketplaces/myst/.claude-plugin/marketplace.json"
if [ -f "$ipj" ] && [ -f "$mpj" ]; then
  inst=$(grep -A8 '"myst-dev-kit@myst"' "$ipj" 2>/dev/null | grep -m1 '"version"' | sed -E 's/.*"version"[^"]*"([^"]*)".*/\1/')
  avail=$(grep -m1 '"version"' "$mpj" 2>/dev/null | sed -E 's/.*"version"[^"]*"([^"]*)".*/\1/')
  if [ -n "$inst" ] && [ -n "$avail" ] && [ "$inst" != "$avail" ]; then
    echo "Plugin nudge: myst-dev-kit $inst installed, $avail in the local marketplace clone — run: claude plugin marketplace update myst && claude plugin update myst-dev-kit@myst (then restart)."
  fi
fi

exit 0
