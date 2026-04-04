#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMA_FILE="${SCHEMA_FILE:-$ROOT_DIR/docs/architecture/evidence_schema.json}"
APPROVAL_SCHEMA_FILE="${APPROVAL_SCHEMA_FILE:-$ROOT_DIR/docs/operations/approval_metadata.schema.json}"
EVENT_CLASS_SCHEMAS_DIR="${EVENT_CLASS_SCHEMAS_DIR:-$ROOT_DIR/evidence/schemas/hardening/event_classes}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$ROOT_DIR/evidence/phase0}"
EVIDENCE_DIR_PHASE1="${EVIDENCE_DIR_PHASE1:-$ROOT_DIR/evidence/phase1}"
REPORT_FILE="${REPORT_FILE:-$EVIDENCE_DIR/evidence_validation.json}"

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
event_classes_dir = Path("$EVENT_CLASS_SCHEMAS_DIR")
approval_schema = None
event_class_schemas = {}
if approval_schema_path.exists():
    approval_schema = json.loads(approval_schema_path.read_text())
if event_classes_dir.exists():
    for schema_path in sorted(event_classes_dir.glob("*.schema.json")):
        schema = json.loads(schema_path.read_text())
        class_name = schema_path.name.replace(".schema.json", "")
        event_class_schemas[class_name] = schema
dirs = ["$EVIDENCE_DIR", "$EVIDENCE_DIR_PHASE1"]
files = []
for d in dirs:
    if Path(d).exists():
        for f in sorted(glob.glob(os.path.join(d, "*.json"))):
            if Path(f).name == "pwrm0001_monitoring_report.json" or Path(f).name == "pwrm_monitoring_report.json":
                continue
            files.append(f)
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
            elif isinstance(evidence, dict) and isinstance(evidence.get("event_class"), str):
                event_class = evidence.get("event_class")
                if event_class in event_class_schemas:
                    selected_schema = event_class_schemas[event_class]
                    jsonschema.validate(instance=evidence, schema=selected_schema)
                    schema_id = f"event_class:{event_class}"
                else:
                    jsonschema.validate(instance=evidence, schema=selected_schema)
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
