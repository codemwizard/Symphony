#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMA_FILE="$ROOT_DIR/docs/architecture/evidence_schema.json"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
REPORT_FILE="$EVIDENCE_DIR/evidence_validation.json"

mkdir -p "$EVIDENCE_DIR"

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "Missing schema: $SCHEMA_FILE" >&2
  exit 1
fi

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<PY
import json
import glob
from pathlib import Path
import jsonschema
import os

schema = json.loads(Path("$SCHEMA_FILE").read_text())
files = sorted(glob.glob(os.path.join("$EVIDENCE_DIR", "*.json")))
errors = []

if not files:
    errors.append({"file": None, "error": "no evidence files found"})
else:
    for f in files:
        try:
            evidence = json.loads(Path(f).read_text())
            jsonschema.validate(instance=evidence, schema=schema)
        except Exception as e:
            errors.append({"file": f, "error": str(e)})

status = "PASS" if not errors else "FAIL"
out = {
    "check_id": "EVIDENCE-SCHEMA-VALIDATION",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "checked_files": files,
    "errors": errors,
}
Path("$REPORT_FILE").write_text(json.dumps(out, indent=2))
print(status)
PY

if grep -q "\"status\": \"FAIL\"" "$REPORT_FILE"; then
  echo "Evidence schema validation failed. Evidence: $REPORT_FILE" >&2
  exit 1
fi

echo "Evidence schema validation passed. Evidence: $REPORT_FILE"
