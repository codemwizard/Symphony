#!/usr/bin/env bash
set -euo pipefail

# Check if kill_switches table exists
TABLE_EXISTS=$(psql "$DATABASE_URL" -tAc \
  "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'kill_switches');" \
  | xargs)

if [[ "$TABLE_EXISTS" != "t" ]]; then
  echo "⚠️  kill_switches table does not exist (schema not applied yet)"
  echo "✅ No active kill-switch (table not initialized)"
  exit 0
fi

ACTIVE=$(psql "$DATABASE_URL" -tAc \
  "SELECT count(*) FROM kill_switches WHERE is_active = true;" \
  | xargs)

if [[ "$ACTIVE" != "0" ]]; then
  echo "🚨 Kill-switch active. CI blocked."
  psql "$DATABASE_URL" -c \
    "SELECT id, scope, reason, activated_at FROM kill_switches WHERE is_active = true;"
  exit 1
fi

echo "✅ No active kill-switch"
