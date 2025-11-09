#!/usr/bin/env bash
# ============================================================
# install.sh - Setup and Automation (Fixed version)
# ============================================================
# Usage:
#   sudo ./install.sh
#
# Works both from the project root or from within the scripts/ folder.
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# --- Detect base directories ---
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "$SCRIPT_PATH")" == "scripts" ]]; then
    BASE_DIR="$(dirname "$SCRIPT_PATH")"
    SCRIPTS_DIR="$SCRIPT_PATH"
else
    BASE_DIR="$SCRIPT_PATH"
    SCRIPTS_DIR="$BASE_DIR/scripts"
fi

LOG_DIR="$BASE_DIR/logs"
BACKUP_DIR="/var/backups/system-maintenance-suite"

timestamp() { date '+%Y-%m-%d_%H-%M-%S'; }
log() { echo "$(timestamp)  $*"; }

# --- Safety Check ---
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)."
    exit 1
fi

log "Starting installation..."

# --- Create directories ---
mkdir -p "$LOG_DIR" "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

log "Created log directory at: $LOG_DIR"
log "Created backup directory at: $BACKUP_DIR"

# --- Make all scripts executable ---
if [ -d "$SCRIPTS_DIR" ]; then
    chmod +x "$SCRIPTS_DIR"/*.sh
    log "Set executable permissions on scripts in: $SCRIPTS_DIR"
else
    log "WARNING: Script directory not found at $SCRIPTS_DIR"
fi

# --- Optional cron setup ---
read -rp "Do you want to schedule daily maintenance at 2 AM? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    (crontab -l 2>/dev/null; echo "0 2 * * * sudo $SCRIPTS_DIR/maintenance_menu.sh >> $LOG_DIR/cron_run.log 2>&1") | crontab -
    log "Cron job added: runs maintenance_menu.sh daily at 02:00."
else
    log "Cron setup skipped."
fi

log "Installation completed successfully!"
echo "✅ All scripts ready. Run with: sudo $SCRIPTS_DIR/maintenance_menu.sh"
exit 0