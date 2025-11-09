#!/usr/bin/env bash
# ============================================================
# system_update_and_cleanup.sh - Day 2: System Maintenance
# ============================================================
# Usage:
#   sudo ./system_update_and_cleanup.sh [--dry-run]
#
# Description:
#   Updates the system packages, removes unnecessary files,
#   cleans caches, rotates old logs, and records all actions.
#   Use --dry-run to simulate actions safely.
#
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
LOG_DIR="$(dirname "$0")/../logs"
LOGFILE="$LOG_DIR/system_update.log"
DRY_RUN=false

# --- Functions ---
timestamp() { date '+%Y-%m-%d_%H-%M-%S'; }

log() {
    mkdir -p "$LOG_DIR"
    echo "$(timestamp)  $*" | tee -a "$LOGFILE"
}

run_cmd() {
    local cmd="$1"
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would execute: $cmd"
    else
        log "Running: $cmd"
        eval "$cmd" >>"$LOGFILE" 2>&1 || log "Warning: command failed - $cmd"
    fi
}

# --- Parse arguments ---
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
fi

# --- Safety check ---
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)."
    exit 1
fi

log "=== Starting system update and cleanup (dry-run=$DRY_RUN) ==="

# --- 1. Update package lists and upgrade ---
run_cmd "apt update -y"
run_cmd "apt upgrade -y"
run_cmd "apt full-upgrade -y"

# --- 2. Remove unnecessary packages and clean caches ---
run_cmd "apt autoremove -y"
run_cmd "apt autoclean -y"
run_cmd "apt clean -y"

# --- 3. Rotate or compress old apt logs ---
APT_LOG_DIR="/var/log/apt"
if [ -d "$APT_LOG_DIR" ]; then
    run_cmd "find $APT_LOG_DIR -type f -name '*.log.*' -mtime +14 -delete"
    run_cmd "gzip -f $APT_LOG_DIR/*.log || true"
    log "Apt logs cleaned and compressed (older than 14 days removed)."
else
    log "Apt log directory not found at $APT_LOG_DIR."
fi

# --- 4. Clear general system logs older than 30 days (optional) ---
run_cmd "find /var/log -type f -name '*.log' -mtime +30 -exec rm -f {} +"

# --- 5. Update system information database ---
run_cmd "updatedb"

log "=== System update and cleanup completed successfully ==="
echo "✅ System update and cleanup complete. Check $LOGFILE for details."
exit 0
