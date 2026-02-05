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
  # Detect BEGIN/COMMIT outside dollar-quoted blocks (function bodies).
  python3 - "$f" <<'PY'
import re, sys
path = sys.argv[1]
tag = None
in_block = False

begin_re = re.compile(r'^BEGIN\s*;?\s*$')
commit_re = re.compile(r'^COMMIT\s*;?\s*$')
tag_re = re.compile(r'\$[A-Za-z0-9_]*\$')

with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
    for lineno, line in enumerate(fh, 1):
        # Toggle dollar-quoted blocks
        for m in tag_re.finditer(line):
            tok = m.group(0)
            if not in_block:
                in_block = True
                tag = tok
            elif tok == tag:
                in_block = False
                tag = None
        if in_block:
            continue
        if begin_re.match(line):
            print(f"❌ Migration contains top-level BEGIN: {path}:{lineno}", file=sys.stderr)
            sys.exit(1)
        if commit_re.match(line):
            print(f"❌ Migration contains top-level COMMIT: {path}:{lineno}", file=sys.stderr)
            sys.exit(1)
sys.exit(0)
PY
  if [[ $? -ne 0 ]]; then
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
