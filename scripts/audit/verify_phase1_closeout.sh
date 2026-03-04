#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
OUT_FILE="${OUT_FILE:-$EVIDENCE_DIR/phase1_closeout.json}"
PHASE1_CONTRACT_SPEC="${PHASE1_CONTRACT_SPEC:-$ROOT_DIR/docs/PHASE1/phase1_contract.yml}"
EVIDENCE_SCHEMA_FILE="${EVIDENCE_SCHEMA_FILE:-$ROOT_DIR/docs/architecture/evidence_schema.json}"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR OUT_FILE PHASE1_CONTRACT_SPEC EVIDENCE_SCHEMA_FILE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 <<'PY'
import json
import os
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
except Exception as exc:
    payload = {
        "check_id": "PHASE1-CLOSEOUT-VERIFICATION",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "failures": [f"yaml_dependency_missing:{exc}"],
    }
    Path(os.environ["OUT_FILE"]).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(1)

root = Path(os.environ["ROOT_DIR"])
out_file = Path(os.environ["OUT_FILE"])
contract = Path(os.environ["PHASE1_CONTRACT_SPEC"])
schema_file = Path(os.environ["EVIDENCE_SCHEMA_FILE"])

failures: list[str] = []
checked: list[dict] = []
required_artifacts: list[str] = []

if not contract.exists():
    failures.append(f"missing_phase1_contract_spec:{contract}")
else:
    try:
        rows = yaml.safe_load(contract.read_text(encoding="utf-8")) or []
        if not isinstance(rows, list):
            failures.append("phase1_contract_not_yaml_list")
            rows = []
        for row in rows:
            if not isinstance(row, dict):
                continue
            if bool(row.get("required")) and str(row.get("evidence_path") or "").strip():
                required_artifacts.append(str(row["evidence_path"]).strip())
    except Exception as exc:
        failures.append(f"phase1_contract_spec_parse_error:{exc}")

required_artifacts = sorted(set(required_artifacts))
if not failures and len(required_artifacts) == 0:
    failures.append("phase1_contract_zero_required_artifacts")

schema_required = ["check_id", "timestamp_utc", "git_sha", "status"]
if schema_file.exists():
    try:
        schema = json.loads(schema_file.read_text(encoding="utf-8"))
        if isinstance(schema, dict) and isinstance(schema.get("required"), list) and schema["required"]:
            schema_required = [str(k) for k in schema["required"]]
    except Exception as exc:
        failures.append(f"evidence_schema_parse_error:{exc}")
else:
    failures.append(f"missing_evidence_schema:{schema_file}")

for rel in required_artifacts:
    path = root / rel
    if not path.exists():
        failures.append(f"missing_evidence:{rel}")
        checked.append({"path": rel, "status": "MISSING"})
        continue
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        failures.append(f"invalid_json:{rel}")
        checked.append({"path": rel, "status": "INVALID_JSON"})
        continue

    if path.name != "approval_metadata.json":
        missing_keys = [k for k in schema_required if k not in payload]
        if missing_keys:
            failures.append(f"schema_required_missing:{rel}:{','.join(missing_keys)}")

    status = str(payload.get("status", "")).upper()
    checked.append({"path": rel, "status": status})

# PERF-006 translation-layer closeout checks:
# ensure KPI report carries settlement_window_compliance_pct and perf_005_reference.
kpi_rel = "evidence/phase1/product_kpi_readiness_report.json"
kpi_path = root / kpi_rel
if not kpi_path.exists():
    failures.append(f"missing_evidence:{kpi_rel}")
else:
    try:
        kpi_payload = json.loads(kpi_path.read_text(encoding="utf-8"))
        kpis = kpi_payload.get("kpis") or {}
        if not isinstance(kpis.get("settlement_window_compliance_pct"), (int, float)):
            failures.append("missing_or_invalid:settlement_window_compliance_pct")
        perf_ref = kpi_payload.get("perf_005_reference") or {}
        if not isinstance(perf_ref, dict):
            failures.append("missing_or_invalid:perf_005_reference")
        else:
            if perf_ref.get("task_id") != "PERF-005":
                failures.append("perf_005_reference_task_id_mismatch")
            if perf_ref.get("evidence_path") != "evidence/phase1/perf_005__regulatory_timing_compliance_gate.json":
                failures.append("perf_005_reference_path_mismatch")
    except Exception as exc:
        failures.append(f"invalid_json:{kpi_rel}:{exc}")

status = "PASS" if not failures else "FAIL"
out = {
    "check_id": "PHASE1-CLOSEOUT-VERIFICATION",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "run_phase1_gates": os.environ.get("RUN_PHASE1_GATES", "0") == "1",
    "contract_file": str(contract),
    "required_artifacts": required_artifacts,
    "checked": checked,
    "failures": failures,
}
out_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print("❌ Phase-1 closeout verification failed", file=sys.stderr)
    for item in failures:
        print(f" - {item}", file=sys.stderr)
    raise SystemExit(1)

print(f"Phase-1 closeout verification passed. Evidence: {out_file}")
PY
