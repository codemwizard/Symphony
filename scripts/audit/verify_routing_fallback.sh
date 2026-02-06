#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES_FILE="$ROOT_DIR/docs/architecture/routing_fallback.yml"
SCHEMA_FILE="$ROOT_DIR/docs/architecture/routing_fallback.schema.json"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/routing_fallback.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -f "$RULES_FILE" ]]; then
  echo "Missing routing fallback rules: $RULES_FILE" >&2
  exit 1
fi
if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "Missing routing fallback schema: $SCHEMA_FILE" >&2
  exit 1
fi

# Validate YAML against schema using python (pyyaml + jsonschema)
python3 - <<PY
import json, sys, os
from pathlib import Path

try:
    import yaml
    import jsonschema
except Exception as e:
    print(f"Missing dependency: {e}", file=sys.stderr)
    sys.exit(1)

rules = Path("$RULES_FILE").read_text()
obj = yaml.safe_load(rules)
if obj is None:
    print("routing_fallback.yml is empty", file=sys.stderr)
    sys.exit(1)

schema = json.loads(Path("$SCHEMA_FILE").read_text())
jsonschema.validate(instance=obj, schema=schema)

# Required field checks for Phase-0
required = ["fallback_mode", "slo_thresholds", "routing_actions", "evidence"]
missing = [r for r in required if r not in obj]
if missing:
    print(f"Missing required fields: {missing}", file=sys.stderr)
    sys.exit(1)

out = {
    "check_id": "ROUTING-FALLBACK",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS",
    "required_fields": required,
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
print("OK")
PY

echo "Routing fallback validation passed. Evidence: $EVIDENCE_FILE"
