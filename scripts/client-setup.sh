#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Write ~/.wakatime.cfg so this machine reports to your Wakapi server.
# Reads WAKAPI_PUBLIC_URL and WAKAPI_API_KEY from .env.
# Backs up any existing cfg. Safe to re-run.
#
# WARNING: This replaces ~/.wakatime.cfg entirely. A timestamped backup is
# created first. If you had custom WakaTime settings (exclude, proxy,
# projectmap, hidefilenames, etc.) check the backup and restore them manually.
# -----------------------------------------------------------------------------
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env ]; then
  echo "No .env found. Run: mise run init" >&2
  exit 1
fi
set -a
# shellcheck disable=SC1091
. ./.env
set +a

: "${WAKAPI_PUBLIC_URL:?set WAKAPI_PUBLIC_URL in .env}"
: "${WAKAPI_API_KEY:?set WAKAPI_API_KEY in .env (copy from Wakapi Settings page)}"

API_URL="${WAKAPI_PUBLIC_URL%/}/api"

# Resolve home directory — works on Linux, macOS, and native Windows shells
TARGET_HOME="${HOME:-${USERPROFILE:-}}"
[ -n "$TARGET_HOME" ] || { echo "Could not resolve home directory." >&2; exit 1; }
CFG="$TARGET_HOME/.wakatime.cfg"

if [ -f "$CFG" ]; then
  BACKUP="$CFG.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$CFG" "$BACKUP"
  echo "Backed up existing cfg: $BACKUP"
  echo "WARNING: ~/.wakatime.cfg will be fully replaced."
  echo "  Restore custom settings (exclude, proxy, projectmap) from the backup if needed."
fi

cat > "$CFG" <<CFGEOF
[settings]
api_url = $API_URL
api_key = $WAKAPI_API_KEY
CFGEOF
chmod 600 "$CFG" 2>/dev/null || true

echo "Wrote $CFG -> $API_URL"
echo "Install or enable the WakaTime plugin in your editor; it picks this up automatically."
echo
echo "WSL2 note: run this script inside the Linux shell, not PowerShell —"
echo "  your editor's WakaTime plugin runs under Remote-WSL and reads the Linux home dir."
