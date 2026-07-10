#!/usr/bin/env bash
# submit-audit-bridge - Codex delivery vehicle for the client-side Submit-Audit warning.
#
# The audit logic itself lives in the CONSUMER project's committed governance core
# (.claude/scripts/submit-audit-warn.sh, tracked in Perforce). This bridge only
# routes a Codex PreToolUse(Bash) hook to that script, so there is exactly ONE
# copy of the audit logic per project and the plugin never drifts from it.
#
# Why the tool gate: under Claude Code the project's committed .claude/settings.json
# ALREADY registers submit-audit-warn.sh as a PreToolUse hook - if this plugin hook
# also ran it, every p4 submit would warn twice. Codex is the only tool that needs
# the plugin as its hook carrier.
#   - Codex exports PLUGIN_ROOT (native name) alongside CLAUDE_PLUGIN_ROOT (compat).
#   - Claude Code exports only CLAUDE_PLUGIN_ROOT.
# So: no PLUGIN_ROOT -> we are under Claude Code -> no-op (core hook owns the warn).
#
# NOTE: gate on env BEFORE touching stdin - the audit script reads the hook JSON
# from stdin, so this bridge must exec it with stdin intact.

[ -z "${PLUGIN_ROOT:-}" ] && exit 0

# Locate the consumer project's governance core. Hooks run with cwd = project root;
# prefer the explicit project-dir variable when the tool provides one.
PROJ="${CLAUDE_PROJECT_DIR:-$PWD}"
AUDIT="$PROJ/.claude/scripts/submit-audit-warn.sh"

# Generic consumers without the Myst Perforce governance core: nothing to audit.
[ -f "$AUDIT" ] || exit 0

exec bash "$AUDIT"
