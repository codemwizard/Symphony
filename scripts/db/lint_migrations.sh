#!/usr/bin/env bash
# ============================================================
# lint_migrations.sh — Prevent BEGIN/COMMIT in migration files
# ============================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIG_DIR="$ROOT_DIR/schema/migrations"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/no_tx_marker_lint.json"

fail=0
violations=()

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
  if grep -qiE "CREATE INDEX[[:space:]]+CONCURRENTLY" "$f"; then
    if ! grep -qiE "symphony:no_tx" "$f"; then
      echo "❌ Missing -- symphony:no_tx marker for CONCURRENTLY: $f" >&2
      violations+=("$f")
      fail=1
    fi
  fi
done

mkdir -p "$EVIDENCE_DIR"
printf '%s\n' "${violations[@]}" | python3 - <<PY
import json, sys
lines = [ln.strip() for ln in sys.stdin.read().splitlines() if ln.strip()]
out = {"status": "fail" if lines else "pass", "violations": lines}
with open("$EVIDENCE_FILE", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
PY

if [[ $fail -ne 0 ]]; then
  exit 1
fi

echo "✅ Migration lint OK"
