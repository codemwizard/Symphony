#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES_FILE="$ROOT_DIR/docs/architecture/batching_rules.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/batching_rules.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

if [[ ! -f "$RULES_FILE" ]]; then
  echo "Missing batching rules file: $RULES_FILE" >&2
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path
import yaml

rules = yaml.safe_load(Path("$RULES_FILE").read_text())
if not rules or "batching" not in rules:
    raise SystemExit("Missing 'batching' section")

b = rules["batching"]
required_ints = ["max_batch_size", "max_wait_ms", "flush_interval_ms", "max_in_flight"]
for key in required_ints:
    if key not in b or not isinstance(b[key], int) or b[key] <= 0:
        raise SystemExit(f"Invalid or missing {key}")

if "backpressure" not in b or not isinstance(b["backpressure"], dict):
    raise SystemExit("Missing backpressure configuration")
if "enabled" not in b["backpressure"]:
    raise SystemExit("Missing backpressure.enabled")
if "strategy" not in b["backpressure"] or not isinstance(b["backpressure"]["strategy"], str):
    raise SystemExit("Missing backpressure.strategy")

out = {
    "check_id": "BATCHING-RULES",
    "timestamp_utc": "$EVIDENCE_TS",
    "git_sha": "$EVIDENCE_GIT_SHA",
    "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
    "status": "PASS",
    "batching": b,
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
print("OK")
PY

echo "Batching rules validation passed. Evidence: $EVIDENCE_FILE"
