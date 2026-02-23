#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH="${EVIDENCE_PATH:-$ROOT_DIR/evidence/phase1/perf_006__operational_risk_framework_translation_layer.json}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "unknown_arg:$1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$(dirname "$EVIDENCE_PATH")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

# Translation layer: regenerate KPI evidence with PERF-005 coupling enforced.
KPI_REQUIRE_PERF005=1 "$ROOT_DIR/scripts/audit/verify_product_kpi_readiness.sh"

ROOT_DIR="$ROOT_DIR" EVIDENCE_PATH="$EVIDENCE_PATH" EVIDENCE_TS="$EVIDENCE_TS" EVIDENCE_GIT_SHA="$EVIDENCE_GIT_SHA" EVIDENCE_SCHEMA_FP="$EVIDENCE_SCHEMA_FP" python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
out = Path(os.environ["EVIDENCE_PATH"])
kpi_path = root / "evidence/phase1/product_kpi_readiness_report.json"
perf5_path = root / "evidence/phase1/perf_005__regulatory_timing_compliance_gate.json"
closeout_script = root / "scripts/audit/verify_phase1_closeout.sh"

errors = []
if not kpi_path.exists():
    errors.append("missing_kpi_evidence")
if not perf5_path.exists():
    errors.append("missing_perf005_evidence")

kpi = {}
perf5 = {}
if not errors:
    kpi = json.loads(kpi_path.read_text(encoding="utf-8"))
    perf5 = json.loads(perf5_path.read_text(encoding="utf-8"))

    settlement = (kpi.get("kpis") or {}).get("settlement_window_compliance_pct")
    if not isinstance(settlement, (int, float)):
        errors.append("missing_settlement_window_compliance_pct")

    ref = kpi.get("perf_005_reference") or {}
    if ref.get("task_id") != "PERF-005":
        errors.append("missing_perf005_task_reference")
    if ref.get("evidence_path") != "evidence/phase1/perf_005__regulatory_timing_compliance_gate.json":
        errors.append("missing_perf005_path_reference")

    expected = ((perf5.get("details") or {}).get("compliance_pct"))
    if isinstance(settlement, (int, float)) and isinstance(expected, (int, float)):
        if round(float(settlement), 2) != round(float(expected), 2):
            errors.append("settlement_window_compliance_pct_mismatch")

# Ensure closeout verifier contains explicit KPI checks introduced by PERF-006.
text = closeout_script.read_text(encoding="utf-8") if closeout_script.exists() else ""
for needle in ["settlement_window_compliance_pct", "perf_005_reference"]:
    if needle not in text:
        errors.append(f"closeout_missing_check:{needle}")

status = "PASS" if not errors else "FAIL"
payload = {
    "check_id": "PERF-006",
    "task_id": "PERF-006",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "pass": status == "PASS",
    "details": {
        "kpi_evidence": "evidence/phase1/product_kpi_readiness_report.json",
        "perf_005_evidence": "evidence/phase1/perf_005__regulatory_timing_compliance_gate.json",
        "closeout_script": "scripts/audit/verify_phase1_closeout.sh",
        "translation_layer_verified": status == "PASS",
        "errors": errors,
    },
}
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
if status != "PASS":
    raise SystemExit(1)
print(f"PERF-006 evidence: {out}")
PY
