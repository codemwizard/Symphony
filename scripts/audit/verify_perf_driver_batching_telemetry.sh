#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase1/perf_driver_batching_telemetry.json"

python3 - <<PY
import json
from pathlib import Path

p = Path(r"$EVIDENCE_FILE")
if not p.exists():
    raise SystemExit("missing_evidence:perf_driver_batching_telemetry.json")

data = json.loads(p.read_text())
required_top = ["check_id", "timestamp_utc", "git_sha", "status", "details"]
missing = [k for k in required_top if k not in data]
if missing:
    raise SystemExit(f"missing_top_fields:{missing}")

if data["check_id"] != "TSK-P1-057":
    raise SystemExit("invalid_check_id")

details = data.get("details", {})
required_details = [
  "runtime_version", "batching_enabled", "batched_operations", "non_batched_operations",
  "workload_profile", "telemetry_source", "deterministic"
]
missing_details = [k for k in required_details if k not in details]
if missing_details:
    raise SystemExit(f"missing_detail_fields:{missing_details}")

if details.get("deterministic") is not True:
    raise SystemExit("determinism_not_proven")
if not details.get("batching_enabled"):
    raise SystemExit("batching_not_enabled")
if int(details.get("batched_operations", 0)) <= 0:
    raise SystemExit("no_batched_operations")
if int(details.get("non_batched_operations", 0)) <= 0:
    raise SystemExit("no_non_batched_operations")

if "placeholder" in json.dumps(data).lower():
    raise SystemExit("placeholder_detected")

if data.get("status") != "PASS":
    raise SystemExit("telemetry_status_not_pass")

print("perf driver batching telemetry verification passed")
PY
