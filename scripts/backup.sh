#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Consistent online snapshot of the Wakapi SQLite database.
# Safe to run while the container is up — sqlite3 .backup handles live files.
#
# Requires sqlite3 on the host:   sudo apt install sqlite3
# Usage:                          ./scripts/backup.sh [destination_dir]
#   or via mise:                  mise run backup
# -----------------------------------------------------------------------------
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB="$ROOT/data/wakapi.db"
DEST="${1:-$ROOT/backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$DEST/wakapi-$STAMP.db"

if [ ! -f "$DB" ]; then
  echo "Error: database not found at $DB" >&2
  echo "  Is the stack running? Has it written any data yet?" >&2
  exit 1
fi
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "Error: sqlite3 not installed — run: sudo apt install sqlite3" >&2
  exit 1
fi

mkdir -p "$DEST"
sqlite3 "$DB" ".backup '$OUT'"
chmod 600 "$OUT" 2>/dev/null || true
echo "Backup written to $OUT"

# --- OPTIONAL: prune local backups older than 30 days ------------------------
# find "$DEST" -name 'wakapi-*.db' -mtime +30 -delete

# --- OPTIONAL: push offsite (configure your own rclone remote + bucket) ------
# rclone copy "$OUT" REMOTE:YOUR_BUCKET/wakapi/
