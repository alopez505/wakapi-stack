#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Role dispatcher. Reads ROLE from .env and does the right thing per machine.
#   ROLE=host    -> runs the Docker stack (Wakapi + chosen profiles)
#   ROLE=client  -> writes ~/.wakatime.cfg pointing at the server; starts nothing
#
# ROLE has no default. An unset ROLE fails fast — this prevents silently
# starting the Docker stack on a machine that should only be a client.
#
# Usage:  ./scripts/role.sh up    (normally invoked via: mise run up)
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

# Require explicit ROLE — no default. Prevents accidental host behavior.
: "${ROLE:?set ROLE=host or ROLE=client in .env}"

ACTION="${1:-up}"

case "$ROLE" in
  host)
    case "$ACTION" in
      up) docker compose up -d ;;
      *)  docker compose "$ACTION" ;;
    esac
    ;;
  client)
    case "$ACTION" in
      up)
        echo "ROLE=client — writing WakaTime client config (no stack to start)."
        "${ROOT}/scripts/client-setup.sh"
        ;;
      *)
        echo "ROLE=client: task '$ACTION' is host-only. Nothing done." >&2
        exit 0
        ;;
    esac
    ;;
  *)
    echo "Unknown ROLE='$ROLE' (expected: host | client)." >&2
    exit 1
    ;;
esac
