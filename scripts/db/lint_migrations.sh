#!/usr/bin/env bash
# ============================================================
# lint_migrations.sh — Prevent BEGIN/COMMIT in migration files
# ============================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIG_DIR="$ROOT_DIR/schema/migrations"

fail=0

shopt -s nullglob
for f in "$MIG_DIR"/*.sql; do
  # Ignore BEGIN/COMMIT inside dollar-quoted blocks? We keep it simple and strict:
  # If your migration truly needs explicit transaction control, it must be handled
  # by the runner, not in the file.
  # Relaxed rule: Only catch unindented BEGIN/COMMIT (assumes blocks are indented)
  if grep -nE '^BEGIN\s*;?\s*$' "$f" >/dev/null; then
    echo "❌ Migration contains top-level BEGIN (unindented): $f" >&2
    fail=1
  fi
  if grep -nE '^COMMIT\s*;?\s*$' "$f" >/dev/null; then
    echo "❌ Migration contains top-level COMMIT (unindented): $f" >&2
    fail=1
  fi
done

if [[ $fail -ne 0 ]]; then
  exit 1
fi

echo "✅ Migration lint OK"
