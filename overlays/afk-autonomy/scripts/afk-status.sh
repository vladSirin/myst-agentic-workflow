#!/usr/bin/env bash
# AFK Status — surfaces AFK auto-submit state and recent log activity.
# Designed to run as a SessionStart hook alongside doc-audit.sh.

LOGS_DIR=".claude/logs"
STATE_DIR=".claude/state"
MODE_FILE="$STATE_DIR/afk-mode.txt"
COUNTER_FILE="$STATE_DIR/afk-cl-counter.txt"

# Determine current AFK mode (default: dry-run if file missing)
if [ -f "$MODE_FILE" ]; then
  mode=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
  mode="dry-run"
fi

# CL counter (default: 0)
if [ -f "$COUNTER_FILE" ]; then
  counter=$(cat "$COUNTER_FILE" | tr -d '[:space:]')
else
  counter=0
fi

# Most recent log file (if any)
latest_log=""
if [ -d "$LOGS_DIR" ]; then
  latest_log=$(ls -1 "$LOGS_DIR"/afk-submits-*.md 2>/dev/null | sort -r | head -1)
fi

# If no logs and no state, AFK has never run — stay silent
if [ -z "$latest_log" ] && [ ! -f "$MODE_FILE" ] && [ ! -f "$COUNTER_FILE" ]; then
  exit 0
fi

# Summarize the latest log
submitted=0
hitl_queued=0
dry_run_count=0
reverts_pending=0

if [ -n "$latest_log" ] && [ -f "$latest_log" ]; then
  submitted=$(grep -c '\[SUBMITTED\]' "$latest_log" 2>/dev/null || echo 0)
  hitl_queued=$(grep -c '\[HITL-QUEUED\]' "$latest_log" 2>/dev/null || echo 0)
  dry_run_count=$(grep -c '\[DRY-RUN' "$latest_log" 2>/dev/null || echo 0)
fi

# Output summary
echo "AFK status: mode=$mode | CLs submitted to date: $counter"

if [ -n "$latest_log" ]; then
  log_date=$(basename "$latest_log" | sed 's/afk-submits-\(.*\)\.md/\1/')
  if [ "$dry_run_count" -gt 0 ]; then
    echo "  Latest log ($log_date): $dry_run_count dry-run entries — see $latest_log"
  elif [ "$submitted" -gt 0 ] || [ "$hitl_queued" -gt 0 ]; then
    echo "  Latest log ($log_date): $submitted submitted, $hitl_queued queued for HITL — see $latest_log"
  fi
fi

# Re-calibration check: at multiples of 100 (post-submit), expect dry-run mode
if [ "$counter" -gt 0 ] && [ $((counter % 100)) -eq 0 ] && [ "$mode" != "dry-run" ]; then
  echo "  Note: $counter CLs submitted — periodic re-calibration due (next 10 should be dry-run)"
fi

exit 0
