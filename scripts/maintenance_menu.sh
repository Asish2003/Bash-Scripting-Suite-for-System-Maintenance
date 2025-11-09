#!/usr/bin/env bash
# ============================================================
# maintenance_menu.sh - Unified Maintenance Dashboard (Fixed)
# ============================================================
# Usage:
#   sudo ./maintenance_menu.sh
#
# Description:
#   Provides an interactive menu to run:
#     - Backup
#     - System Update & Cleanup
#     - Log Monitoring
#     - View Logs & Reports
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"
UPDATE_SCRIPT="$SCRIPT_DIR/system_update_and_cleanup.sh"
MONITOR_SCRIPT="$SCRIPT_DIR/log_monitor.sh"

# --- Utility Functions ---
timestamp() { date '+%Y-%m-%d_%H-%M-%S'; }

pause() {
    echo
    read -rp "Press Enter to continue..."
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root (sudo)."
        exit 1
    fi
}

log() {
    mkdir -p "$LOG_DIR"
    echo "$(timestamp)  $*" | tee -a "$LOG_DIR/menu.log"
}

# --- Menu Functions ---
run_backup() {
    echo
    read -rp "Enter the directory path(s) to back up (space-separated): " path_list
    if [ -z "$path_list" ]; then
        echo "No paths entered. Returning to menu."
        return
    fi

    log "User initiated backup for: $path_list"

    # ✅ FIX: Properly split input into an array for multiple paths
    IFS=' ' read -r -a path_array <<< "$path_list"

    # Run backup script with array-expanded arguments
    sudo "$BACKUP_SCRIPT" "${path_array[@]}"

    pause
}

run_update() {
    echo
    read -rp "Run in dry-run mode first? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        sudo "$UPDATE_SCRIPT" --dry-run
    else
        sudo "$UPDATE_SCRIPT"
    fi
    pause
}

run_monitor() {
    log "Running log monitor..."
    sudo "$MONITOR_SCRIPT"
    pause
}

view_logs() {
    echo
    echo "Available logs in $LOG_DIR:"
    ls -1 "$LOG_DIR" || true
    echo
    read -rp "Enter log/report filename to view (or press Enter to cancel): " file
    if [ -n "$file" ]; then
        if [ -f "$LOG_DIR/$file" ]; then
            echo
            echo "---- Showing last 50 lines of $file ----"
            tail -n 50 "$LOG_DIR/$file"
        else
            echo "File not found: $LOG_DIR/$file"
        fi
    fi
    pause
}

# --- Main Menu Loop ---
check_root
mkdir -p "$LOG_DIR"

while true; do
    clear
    echo "==============================================="
    echo "🧰  System Maintenance Suite  (Day 4 - Fixed)"
    echo "==============================================="
    echo "1️⃣  Run Backup"
    echo "2️⃣  Run System Update & Cleanup"
    echo "3️⃣  Run Log Monitoring"
    echo "4️⃣  View Logs / Reports"
    echo "5️⃣  Exit"
    echo "==============================================="
    read -rp "Choose an option [1-5]: " choice

    case "$choice" in
        1) run_backup ;;
        2) run_update ;;
        3) run_monitor ;;
        4) view_logs ;;
        5)
            echo "Exiting Maintenance Menu. Goodbye!"
            log "Menu exited by user."
            exit 0
            ;;
        *)
            echo "Invalid option. Try again."
            sleep 1
            ;;
    esac
done

