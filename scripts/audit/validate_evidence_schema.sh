#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMA_FILE="$ROOT_DIR/docs/architecture/evidence_schema.json"
APPROVAL_SCHEMA_FILE="$ROOT_DIR/docs/operations/approval_metadata.schema.json"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_DIR_PHASE1="$ROOT_DIR/evidence/phase1"
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

default_schema = json.loads(Path("$SCHEMA_FILE").read_text())
approval_schema_path = Path("$APPROVAL_SCHEMA_FILE")
approval_schema = None
if approval_schema_path.exists():
    approval_schema = json.loads(approval_schema_path.read_text())
dirs = ["$EVIDENCE_DIR", "$EVIDENCE_DIR_PHASE1"]
files = []
for d in dirs:
    if Path(d).exists():
        files.extend(sorted(glob.glob(os.path.join(d, "*.json"))))
errors = []
schema_usage = []

if not files:
    errors.append({"file": None, "error": "no evidence files found"})
else:
    for f in files:
        try:
            evidence = json.loads(Path(f).read_text())
            selected_schema = default_schema
            schema_id = "default"
            basename = Path(f).name
            if basename == "approval_metadata.json":
                if approval_schema is None:
                    raise RuntimeError("approval_metadata.schema.json missing")
                try:
                    jsonschema.validate(instance=evidence, schema=approval_schema)
                    schema_id = "approval_metadata"
                except Exception:
                    jsonschema.validate(instance=evidence, schema=default_schema)
                    schema_id = "approval_metadata_fallback_default"
            else:
                jsonschema.validate(instance=evidence, schema=selected_schema)
            schema_usage.append({"file": f, "schema": schema_id})
        except Exception as e:
            errors.append({"file": f, "error": str(e)})
            schema_usage.append({"file": f, "schema": "error"})

status = "PASS" if not errors else "FAIL"
out = {
    "check_id": "EVIDENCE-SCHEMA-VALIDATION",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "checked_dirs": dirs,
    "checked_files": files,
    "schema_usage": schema_usage,
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
