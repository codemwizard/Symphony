#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMA_FILE="$ROOT_DIR/docs/architecture/evidence_schema.json"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase0/evidence.json"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
REPORT_FILE="$EVIDENCE_DIR/evidence_validation.json"

mkdir -p "$EVIDENCE_DIR"

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "Missing schema: $SCHEMA_FILE" >&2
  exit 1
fi
if [[ ! -f "$EVIDENCE_FILE" ]]; then
  echo "Missing evidence: $EVIDENCE_FILE" >&2
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path
import jsonschema

schema = json.loads(Path("$SCHEMA_FILE").read_text())
evidence = json.loads(Path("$EVIDENCE_FILE").read_text())
jsonschema.validate(instance=evidence, schema=schema)

out = {"status": "pass"}
Path("$REPORT_FILE").write_text(json.dumps(out, indent=2))
print("OK")
PY

echo "Evidence schema validation passed. Evidence: $REPORT_FILE"
