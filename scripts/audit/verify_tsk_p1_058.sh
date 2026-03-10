#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-058"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/outbox_retry_semantics.json}"

source "$ROOT_DIR/scripts/lib/evidence.sh"
ts="$(evidence_now_utc)"
git_sha_val="$(git_sha)"
schema_fp="$(schema_fingerprint)"
mkdir -p "$(dirname "$EVIDENCE_PATH")"

python3 - <<'PY' "$ROOT_DIR" "$TASK_ID" "$EVIDENCE_PATH" "$ts" "$git_sha_val" "$schema_fp"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
task_id = sys.argv[2]
evidence_path = Path(sys.argv[3])
ts = sys.argv[4]
git_sha = sys.argv[5]
schema_fp = sys.argv[6]

errors = []
details = {}

def read_json(rel: str):
    p = root / rel
    if not p.exists():
        errors.append(f"missing_evidence:{rel}")
        return None
    return json.loads(p.read_text(encoding="utf-8"))

perf = read_json("evidence/phase1/perf_002_regression_detection_warmup.json")
batch = read_json("evidence/phase1/perf_driver_batching_telemetry.json")
claim = read_json("evidence/phase0/outbox_claim_semantics.json")
lease = read_json("evidence/phase0/outbox_lease_fencing.json")
zombie = read_json("evidence/phase0/idempotency_zombie.json")

for name, payload in [
    ("perf_002", perf),
    ("driver_batching", batch),
    ("outbox_claim_semantics", claim),
    ("outbox_lease_fencing", lease),
    ("idempotency_zombie", zombie),
]:
    if payload is None:
        continue
    status = str(payload.get("status", "")).upper()
    details[f"{name}_status"] = status
    if status != "PASS":
        errors.append(f"evidence_not_pass:{name}:{status}")

trigger_met = False
trigger_reason = "missing_telemetry"
if batch is not None:
    d = batch.get("details", {})
    batched = int(d.get("batched_operations", 0))
    non_batched = int(d.get("non_batched_operations", 0))
    # Conditional optimization trigger: only when retries dominate and batching is weak.
    # Current phase-1 telemetry remains healthy, so task closes as a recorded no-op.
    trigger_met = non_batched > 500 and batched < non_batched
    trigger_reason = (
        "retry_heavy_contention_detected" if trigger_met else "telemetry_below_contention_threshold"
    )

optimization_applied = False
if trigger_met and not optimization_applied:
    errors.append("trigger_met_but_optimization_not_applied")

details["telemetry_trigger_met"] = trigger_met
details["trigger_reason"] = trigger_reason
details["optimization_applied"] = optimization_applied
details["decision"] = (
    "NO_CHANGE_APPLIED_PHASE1"
    if not optimization_applied
    else "OPTIMIZATION_APPLIED"
)

out = {
    "check_id": "TSK-P1-058-OUTBOX-RETRY-SEMANTICS",
    "task_id": task_id,
    "timestamp_utc": ts,
    "git_sha": git_sha,
    "schema_fingerprint": schema_fp,
    "status": "PASS" if not errors else "FAIL",
    "pass": not errors,
    "details": details,
    "errors": errors,
}
evidence_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(f"TSK-P1-058 verifier status: {out['status']}")
print(f"Evidence: {evidence_path}")
raise SystemExit(0 if out["pass"] else 1)
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task "$TASK_ID" --evidence "$EVIDENCE_PATH"
