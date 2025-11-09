#!/usr/bin/env bash
# ============================================================
# log_monitor.sh - Day 3: Log Monitoring and Alerting
# ============================================================
# Usage:
#   sudo ./log_monitor.sh
#
# Description:
#   Scans key system logs for errors, warnings, and failed logins.
#   Generates a summary report in the logs directory.
#
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
LOG_DIR="$(dirname "$0")/../logs"
REPORT_FILE="$LOG_DIR/log_monitor_report.txt"
MAIN_LOG="$LOG_DIR/log_monitor.log"

# Logs to scan (common Debian/Ubuntu locations)
LOG_FILES=(
  "/var/log/syslog"
  "/var/log/auth.log"
  "/var/log/kern.log"
)

# Keywords to detect
KEYWORDS=(
  "error"
  "failed"
  "critical"
  "unauthorized"
  "denied"
  "panic"
  "segfault"
)

# --- Functions ---
timestamp() { date '+%Y-%m-%d_%H-%M-%S'; }

log() {
    mkdir -p "$LOG_DIR"
    echo "$(timestamp)  $*" | tee -a "$MAIN_LOG"
}

# --- Safety check ---
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)."
    exit 1
fi

log "=== Starting log monitoring ==="

# --- Initialize report ---
echo "==== System Log Monitoring Report ($(timestamp)) ====" > "$REPORT_FILE"
echo >> "$REPORT_FILE"

# --- Scan each log file ---
for file in "${LOG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Analyzing: $file" >> "$REPORT_FILE"
        for keyword in "${KEYWORDS[@]}"; do
            matches=$(grep -i "$keyword" "$file" | tail -n 10 || true)
            if [ -n "$matches" ]; then
                echo "---- Matches for '$keyword' ----" >> "$REPORT_FILE"
                echo "$matches" >> "$REPORT_FILE"
                echo >> "$REPORT_FILE"
            fi
        done
        echo "--------------------------------------------" >> "$REPORT_FILE"
    else
        echo "Log file not found: $file" >> "$REPORT_FILE"
    fi
done

# --- Summary ---
echo >> "$REPORT_FILE"
echo "==== End of Report ====" >> "$REPORT_FILE"

log "Monitoring completed. Report saved at $REPORT_FILE"
echo "✅ Log monitoring complete. Check: $REPORT_FILE"
exit 0
