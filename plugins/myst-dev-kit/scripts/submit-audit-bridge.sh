#!/usr/bin/env bash
# submit-audit-bridge - non-Claude delivery vehicle for the client-side Submit-Audit warning.
#
# The audit logic itself lives in the CONSUMER project's committed governance core
# (.claude/scripts/submit-audit-warn.sh, tracked in Perforce). This bridge only
# routes a plugin PreToolUse(Bash) hook to that script, so there is exactly ONE
# copy of the audit logic per project and the plugin never drifts from it.
#
# HOST GATE -- and why it tests for the host it EXCLUDES.
#
# Under Claude Code the project's committed .claude/settings.json ALREADY registers
# submit-audit-warn.sh as a PreToolUse hook. If this plugin hook also ran it, every
# p4 submit would warn twice. So the bridge must no-op under Claude Code and run
# everywhere else (Codex today; anything else that loads this plugin tomorrow).
#
# It gates on CLAUDECODE - a marker of the host to EXCLUDE - never on a marker of the
# host to include. That direction is the whole point: an UNKNOWN host now RUNS the audit,
# where the worst case is one duplicate advisory warning. The inverse fails SILENT, which
# is exactly how the bug described below survived unnoticed.
#
# Measured 2026-08-06, not inferred:
#   - CLAUDECODE is exported by Claude Code (read from a live Claude Code shell).
#   - `strings` of codex.exe 0.146.0 (323 MB): CLAUDECODE 0, CLAUDE_PROJECT_DIR 0,
#     CLAUDE_PID 0, AI_AGENT 0 -- Codex aliases NO Claude host marker, unlike
#     CLAUDE_PLUGIN_ROOT, which it DOES alias for compat.
#   - Control proving a zero is meaningful (env names are stored in the clear):
#     CODEX_HOME appears 53 times in the same binary.
#
# THE BUG THIS REPLACES. The previous gate was:
#     [ -z "${PLUGIN_ROOT:-}" ] && exit 0
# on the belief, documented in this file's own header, that "Codex exports PLUGIN_ROOT
# (native name) alongside CLAUDE_PLUGIN_ROOT (compat)". It does not. PLUGIN_ROOT occurs
# exactly ONCE in codex.exe, as a substring of CLAUDE_PLUGIN_ROOT; CODEX_PLUGIN_ROOT
# occurs zero times. PLUGIN_ROOT was therefore unset on EVERY host, the gate was always
# true, and this bridge never once ran the audit -- for anyone, on any host, since it
# shipped. A Codex teammate submitted with no client-side audit, in a state
# indistinguishable from clean. The belief was sourced from this header: hearsay about
# the tool, from the tool.
#
# VERIFYING A FIX HERE. A rename is not the fix; an OBSERVED run is. Set MYST_AUDIT_DEBUG=1
# and make a hook fire - every exit path below announces itself. Total silence means the
# script never ran at all, which is a DIFFERENT and still-open failure: nobody has yet
# observed ANY plugin hook firing under Codex.
#
# NOTE: gate on env BEFORE touching stdin - the audit script reads the hook JSON
# from stdin, so this bridge must exec it with stdin intact.

trace() { [ -n "${MYST_AUDIT_DEBUG:-}" ] && echo "submit-audit-bridge: $*" >&2; return 0; }

if [ -n "${CLAUDECODE:-}" ]; then
  trace "host=claude-code -> no-op (the project's .claude/settings.json hook owns the warn)"
  exit 0
fi

# Locate the consumer project's governance core. Hooks run with cwd = project root;
# prefer the explicit project-dir variable when the tool provides one. Codex does NOT
# set CLAUDE_PROJECT_DIR (0 hits in the binary), so under Codex this IS the $PWD path.
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
AUDIT="$PROJ/.claude/scripts/submit-audit-warn.sh"

# Generic consumers without the Myst Perforce governance core: nothing to audit.
# This test cannot distinguish "no governance core" from "cwd was not the project root",
# and on the $PWD path above the second case is a real possibility - hence the trace.
if [ ! -f "$AUDIT" ]; then
  trace "no audit at $AUDIT (no governance core, or cwd is not the project root) -> no-op"
  exit 0
fi

trace "host=non-claude, running $AUDIT"
exec bash "$AUDIT"
