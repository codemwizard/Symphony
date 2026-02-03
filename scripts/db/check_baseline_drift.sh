#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASELINE="$ROOT_DIR/schema/baseline.sql"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/baseline_drift.json"

mkdir -p "$EVIDENCE_DIR"

if [[ ! -f "$BASELINE" ]]; then
  echo "Missing baseline: $BASELINE" >&2
  exit 1
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

# Normalize baseline (strip comments, blank lines, and pg_dump restrict lines)
python3 - <<PY
from pathlib import Path
out = []
for line in Path("$BASELINE").read_text().splitlines():
    line = line.split("--", 1)[0].rstrip()
    if not line.strip():
        continue
    if line.startswith("\\\\restrict") or line.startswith("\\\\unrestrict"):
        continue
    out.append(line)
Path("/tmp/symphony_baseline_norm.sql").write_text("\\n".join(sorted(out)) + "\\n")
PY

# Prefer pg_dump from a running DB container to avoid version mismatch
DUMP_CMD=(pg_dump "$DATABASE_URL" --schema-only --no-owner --no-privileges --no-comments --schema=public)

if command -v docker >/dev/null 2>&1; then
  pg_container="$(docker ps --format '{{.Names}}' | grep -E 'postgres' | head -n 1 || true)"
  if [[ -n "$pg_container" ]]; then
    DUMP_CMD=(docker exec "$pg_container" pg_dump "$DATABASE_URL" --schema-only --no-owner --no-privileges --no-comments --schema=public)
  fi
fi

"${DUMP_CMD[@]}" > /tmp/symphony_schema_dump_raw.sql
python3 - <<PY
from pathlib import Path
out = []
for line in Path("/tmp/symphony_schema_dump_raw.sql").read_text().splitlines():
    line = line.split("--", 1)[0].rstrip()
    if not line.strip():
        continue
    if line.startswith("\\\\restrict") or line.startswith("\\\\unrestrict"):
        continue
    out.append(line)
Path("/tmp/symphony_schema_dump.sql").write_text("\\n".join(sorted(out)) + "\\n")
PY

if ! diff -q /tmp/symphony_baseline_norm.sql /tmp/symphony_schema_dump.sql >/dev/null; then
  python3 - <<PY
import json
from pathlib import Path
out = {"status":"fail","reason":"baseline drift"}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY
  echo "Baseline drift detected" >&2
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path
out = {"status":"pass"}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY

echo "Baseline drift check passed. Evidence: $EVIDENCE_FILE"
