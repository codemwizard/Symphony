#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
OUT_FILE="$EVIDENCE_DIR/p1_057_final_perf_promotion.json"
SMOKE_FILE="$EVIDENCE_DIR/perf_smoke_profile.json"
BATCH_FILE="$EVIDENCE_DIR/perf_driver_batching_telemetry.json"
AOT_FILE="$EVIDENCE_DIR/native_aot_compilation_report.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

if [[ -x "$ROOT_DIR/scripts/audit/run_perf_smoke.sh" ]]; then
  "$ROOT_DIR/scripts/audit/run_perf_smoke.sh"
else
  echo "missing_runner:scripts/audit/run_perf_smoke.sh" >&2
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path

smoke_path = Path(r"$SMOKE_FILE")
batch_path = Path(r"$BATCH_FILE")
aot_path = Path(r"$AOT_FILE")
out_path = Path(r"$OUT_FILE")

errors = []
details = {}

def load_json(path: Path, name: str):
    if not path.exists():
        errors.append(f"missing_evidence:{name}")
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"invalid_json:{name}:{exc}")
        return {}

smoke = load_json(smoke_path, "perf_smoke_profile.json")
batch = load_json(batch_path, "perf_driver_batching_telemetry.json")
aot = load_json(aot_path, "native_aot_compilation_report.json")

promotion = smoke.get("promotion", {}) if isinstance(smoke, dict) else {}
details["baseline_locked"] = bool(promotion.get("baseline_locked", False))
details["regression_enforced"] = bool(promotion.get("regression_enforced", False))
details["regression_detected"] = bool(promotion.get("regression_detected", False))
details["smoke_status"] = smoke.get("status")
details["batch_status"] = batch.get("status")
details["aot_status"] = aot.get("status")
details["smoke_check_id"] = smoke.get("check_id")
details["batch_check_id"] = batch.get("check_id")
details["aot_check_id"] = aot.get("check_id")

if smoke.get("check_id") != "PHASE1-PERF-SMOKE-PROFILE":
    errors.append("invalid_smoke_check_id")
if smoke.get("status") != "PASS":
    errors.append("smoke_not_pass")
if not details["baseline_locked"]:
    errors.append("baseline_not_locked")
if not details["regression_enforced"]:
    errors.append("regression_not_enforced")

if batch.get("check_id") != "TSK-P1-057":
    errors.append("invalid_batch_check_id")
if batch.get("status") != "PASS":
    errors.append("batch_not_pass")
batch_details = batch.get("details", {}) if isinstance(batch.get("details"), dict) else {}
if batch_details.get("telemetry_source") != "OpenTelemetry":
    errors.append("telemetry_source_not_opentelemetry")
if int(batch_details.get("batched_operations", 0)) <= 0:
    errors.append("no_batched_operations")

if aot.get("check_id") != "TSK-P1-057-NATIVE-AOT":
    errors.append("invalid_aot_check_id")
if aot.get("status") != "PASS":
    errors.append("aot_not_pass")

out = {
    "check_id": "TSK-P1-057-FINAL",
    "task_id": "TSK-P1-057-FINAL",
    "timestamp_utc": "$EVIDENCE_TS",
    "git_sha": "$EVIDENCE_GIT_SHA",
    "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
    "status": "PASS" if not errors else "FAIL",
    "pass": len(errors) == 0,
    "details": details,
    "errors": errors,
    "inputs": {
        "smoke_profile": "evidence/phase1/perf_smoke_profile.json",
        "batching_telemetry": "evidence/phase1/perf_driver_batching_telemetry.json",
        "native_aot_report": "evidence/phase1/native_aot_compilation_report.json",
    },
}

out_path.write_text(json.dumps(out, indent=2) + "\\n", encoding="utf-8")

if errors:
    print("TSK-P1-057-FINAL verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)

print(f"TSK-P1-057-FINAL verification passed. Evidence: {out_path}")
PY
