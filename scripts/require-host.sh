#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Guard: abort immediately if ROLE != host.
# Source this or call it at the top of host-only tasks so client machines get
# a clear, early error instead of silently running Docker commands.
# Usage:  ./scripts/require-host.sh   (called from mise tasks)
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

if [ "${ROLE:-}" != "host" ]; then
  echo "This task is host-only (requires ROLE=host in .env)." >&2
  echo "Current ROLE='${ROLE:-unset}'. Nothing done." >&2
  exit 1
fi
