#!/usr/bin/env bash
set -euo pipefail

ACTIVE=$(psql "$DATABASE_URL" -t -c \
  "SELECT count(*) FROM kill_switches WHERE is_active = true;")

if [[ "$ACTIVE" != "0" ]]; then
  echo "🚨 Kill-switch active. CI blocked."
  exit 1
fi

echo "✅ No active kill-switch"
