#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Restore the Wakapi SQLite database from a backup snapshot.
#
# IMPORTANT: The stack MUST be stopped before restoring to avoid corruption.
#
# Usage:  ./scripts/restore.sh <path/to/backup.db>
#   or:   mise run restore ./backups/wakapi-20260101-120000.db
# -----------------------------------------------------------------------------
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_TARGET="$ROOT/data/wakapi.db"
BACKUP="${1:-}"

if [ -z "$BACKUP" ]; then
  echo "Usage: $0 <path/to/backup.db>" >&2
  echo
  echo "Available backups:"
  FOUND_BACKUPS="$(find "$ROOT/backups" -maxdepth 1 -type f -name 'wakapi-*.db' -print 2>/dev/null | sort | head -10 || true)"
  if [ -n "$FOUND_BACKUPS" ]; then
    printf '%s\n' "$FOUND_BACKUPS"
  else
    echo "  (none found in ./backups/ — run: mise run backup first)" >&2
  fi
  exit 1
fi

if [ ! -f "$BACKUP" ]; then
  echo "Error: backup file not found: $BACKUP" >&2
  exit 1
fi

# Safety check — refuse to restore if the Wakapi container is running.
if docker ps --filter "name=wakapi" --format '{{.Names}}' | grep -Fxq "wakapi"; then
  echo "Error: containers are still running." >&2
  echo "  Stop the stack first: mise run down" >&2
  exit 1
fi

mkdir -p "$(dirname "$DB_TARGET")"

# Keep the current database as a safety backup before overwriting
if [ -f "$DB_TARGET" ]; then
  PRE_RESTORE="$DB_TARGET.pre-restore.$(date +%Y%m%d-%H%M%S)"
  cp "$DB_TARGET" "$PRE_RESTORE"
  echo "Pre-restore backup: $PRE_RESTORE"
fi

cp "$BACKUP" "$DB_TARGET"
echo "Restored: $BACKUP -> $DB_TARGET"
echo "Start the stack: mise run up"
