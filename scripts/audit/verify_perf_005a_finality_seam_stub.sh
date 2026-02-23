#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_FILE="$ROOT_DIR/evidence/phase1/perf_005a_finality_seam_stub.json"
mkdir -p "$(dirname "$OUT_FILE")"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

if [[ ! -x "$ROOT_DIR/scripts/perf/finality_seam_stub.sh" ]]; then
  echo "missing_finality_seam_stub" >&2
  exit 1
fi
if [[ ! -x "$ROOT_DIR/scripts/perf/verify_perf_005.sh" ]]; then
  echo "missing_perf_005_verifier" >&2
  exit 1
fi

"$ROOT_DIR/scripts/perf/verify_perf_005.sh" --evidence "$ROOT_DIR/evidence/phase1/perf_005__regulatory_timing_compliance_gate.json"

ROOT_DIR="$ROOT_DIR" OUT_FILE="$OUT_FILE" EVIDENCE_TS="$EVIDENCE_TS" EVIDENCE_GIT_SHA="$EVIDENCE_GIT_SHA" EVIDENCE_SCHEMA_FP="$EVIDENCE_SCHEMA_FP" python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
perf005_path = root / "evidence/phase1/perf_005__regulatory_timing_compliance_gate.json"
out_file = Path(os.environ["OUT_FILE"])

payload = json.loads(perf005_path.read_text(encoding="utf-8"))
rails = (payload.get("details") or {}).get("rails") or []

errors = []
if not rails:
    errors.append("rails_missing")

for row in rails:
    if row.get("finality_source") != "simulated_stub":
        errors.append(f"invalid_finality_source:{row.get('rail')}")
    if row.get("live_rail_wiring_status") != "pending_phase2":
        errors.append(f"invalid_live_wiring_status:{row.get('rail')}")
    if row.get("measurement_truth") != "simulated_finality_stub":
        errors.append(f"invalid_measurement_truth:{row.get('rail')}")

status = "PASS" if not errors else "FAIL"
out = {
    "check_id": "PERF-005A",
    "task_id": "PERF-005A",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "pass": status == "PASS",
    "details": {
        "source_evidence": "evidence/phase1/perf_005__regulatory_timing_compliance_gate.json",
        "finality_source": "simulated_stub",
        "live_rail_wiring_status": "pending_phase2",
        "rails_checked": len(rails),
        "errors": errors,
    },
}
out_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    raise SystemExit(1)
print(f"PERF-005A seam evidence: {out_file}")
PY
