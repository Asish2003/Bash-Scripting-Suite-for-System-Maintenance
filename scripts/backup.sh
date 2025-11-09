#!/usr/bin/env bash
# ============================================================
# backup.sh - Automated Backup Script (Day 1 - Assignment 5)
# ============================================================
# Usage:
#   sudo ./backup.sh /path/to/source [another/source ...]
#
# Description:
#   Creates a timestamped compressed archive (.tar.gz)
#   of the given directories/files and saves it to the
#   backup directory. Keeps only the latest 7 backups.
#
# ============================================================

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
BACKUP_DIR="/var/backups/system-maintenance-suite"
LOG_DIR="$(dirname "$0")/../logs"
LOGFILE="$LOG_DIR/backup.log"
RETENTION_COUNT=7   # Keep last 7 backups

# --- Functions ---
timestamp() { date '+%Y-%m-%d_%H-%M-%S'; }

log() {
    mkdir -p "$LOG_DIR"
    echo "$(timestamp)  $*" | tee -a "$LOGFILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# --- Validations ---
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 /path/to/source [another/source ...]"
    exit 2
fi

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo) to access all directories."
    exit 3
fi

# --- Prepare Backup Directory ---
sudo mkdir -p "$BACKUP_DIR"
sudo chmod 700 "$BACKUP_DIR"

SRC_LIST=("$@")
SAFE_NAME=$(printf "%s_" "${SRC_LIST[@]##*/}" | sed 's/[^A-Za-z0-9_-]//g' | sed 's/_$//')
ARCHIVE_NAME="${SAFE_NAME}_$(timestamp).tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

log "Starting backup of: ${SRC_LIST[*]}"

# --- Validate each source path ---
for path in "${SRC_LIST[@]}"; do
    if [ ! -e "$path" ]; then
        error_exit "Source path not found: $path"
    fi
done

# --- Create Backup (correct tar order) ---
if tar --warning=no-file-changed --ignore-failed-read \
       --exclude=/proc --exclude=/sys --exclude=/dev \
       -czf "$ARCHIVE_PATH" "${SRC_LIST[@]}" 2>>"$LOGFILE"; then
    chmod 600 "$ARCHIVE_PATH"
    SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    log "Backup created: $ARCHIVE_PATH ($SIZE)"
else
    error_exit "Tar command failed while backing up ${SRC_LIST[*]}"
fi

# --- Rotate old backups ---
mapfile -t files < <(ls -1t "$BACKUP_DIR"/"${SAFE_NAME}"_*.tar.gz 2>/dev/null || true)
if [ "${#files[@]}" -gt "$RETENTION_COUNT" ]; then
    to_delete=("${files[@]:$RETENTION_COUNT}")
    for f in "${to_delete[@]}"; do
        rm -f -- "$f" && log "Removed old backup: $f"
    done
fi

log "Backup completed successfully for: ${SRC_LIST[*]}"
echo "✅ Backup complete. Archive saved to: $ARCHIVE_PATH"
exit 0

