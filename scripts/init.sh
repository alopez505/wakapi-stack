#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bootstrap a local .env from .env.example with a freshly generated salt.
# Refuses to clobber an existing .env.
# Usage:  ./scripts/init.sh   (or: mise run init)
# -----------------------------------------------------------------------------
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -f .env ]; then
  echo ".env already exists — refusing to overwrite. Delete it first to re-init." >&2
  exit 1
fi
[ -f .env.example ] || { echo "Error: .env.example not found." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "Error: openssl not found." >&2; exit 1; }

SALT="$(openssl rand -base64 32)"
# Portable sed — '|' delimiter avoids clashing with base64 '/' characters
sed \
  -e "s|^WAKAPI_SALT=.*|WAKAPI_SALT=${SALT}|" \
  -e "s|^# WAKAPI_UID=.*|WAKAPI_UID=$(id -u)|" \
  -e "s|^# WAKAPI_GID=.*|WAKAPI_GID=$(id -g)|" \
  .env.example > .env

echo "Created .env with a generated WAKAPI_SALT."

# Pre-create local state directories so Docker does not create them as root,
# which would prevent the nonroot container user from writing SQLite data.
mkdir -p data backups
if [ "$(id -u)" -ne 0 ]; then
  chown "$(id -u):$(id -g)" data backups 2>/dev/null || true
fi
chmod 700 data backups 2>/dev/null || true

echo
echo "Next — open .env and set:"
echo "  ROLE=host   (the server machine)"
echo "    WAKAPI_PUBLIC_URL, and CF_TUNNEL_TOKEN if COMPOSE_PROFILES includes tunnel"
echo "    then: mise run up"
echo
echo "  ROLE=client (all other machines)"
echo "    WAKAPI_PUBLIC_URL + WAKAPI_API_KEY (from Settings on the host)"
echo "    then: mise run up   (writes ~/.wakatime.cfg)"
echo
echo "First-run only: set WAKAPI_ALLOW_SIGNUP=true, create your account, then set false."
