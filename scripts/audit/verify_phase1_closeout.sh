#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
OUT_FILE="$EVIDENCE_DIR/phase1_closeout.json"
PHASE1_CONTRACT_FILE="$EVIDENCE_DIR/phase1_contract_status.json"
PHASE0_STATUS_FILE="$ROOT_DIR/evidence/phase0/phase0_contract_evidence_status.json"
PHASE1_CONTRACT_SPEC="$ROOT_DIR/docs/PHASE1/phase1_contract.yml"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP OUT_FILE PHASE1_CONTRACT_FILE PHASE0_STATUS_FILE PHASE1_CONTRACT_SPEC

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
        "failures": [f"dependency_missing:{exc}"],
    }
    Path(os.environ["OUT_FILE"]).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(1)

root = Path(os.environ["ROOT_DIR"])
out_file = Path(os.environ["OUT_FILE"])
phase1_contract_file = Path(os.environ["PHASE1_CONTRACT_FILE"])
phase0_status_file = Path(os.environ["PHASE0_STATUS_FILE"])
phase1_contract_spec = Path(os.environ["PHASE1_CONTRACT_SPEC"])

required_phase1 = {
    "regulator_demo_pack": root / "evidence/phase1/regulator_demo_pack.json",
    "tier1_pilot_demo_pack": root / "evidence/phase1/tier1_pilot_demo_pack.json",
    "instruction_finality_runtime": root / "evidence/phase1/instruction_finality_runtime.json",
    "pii_decoupling_runtime": root / "evidence/phase1/pii_decoupling_runtime.json",
    "rail_sequence_runtime": root / "evidence/phase1/rail_sequence_runtime.json",
    "anchor_sync_resume_semantics": root / "evidence/phase1/anchor_sync_resume_semantics.json",
    "evidence_pack_api_contract": root / "evidence/phase1/evidence_pack_api_contract.json",
    "exception_case_pack_generation": root / "evidence/phase1/exception_case_pack_generation.json",
    "pilot_harness_replay": root / "evidence/phase1/pilot_harness_replay.json",
    "product_kpi_readiness": root / "evidence/phase1/product_kpi_readiness_report.json",
}

required_phase0 = {
    "phase0_contract_evidence_status": phase0_status_file,
    "boz_observability_role": root / "evidence/phase0/boz_observability_role.json",
    "pii_leakage_payloads": root / "evidence/phase0/pii_leakage_payloads.json",
    "anchor_sync_hooks": root / "evidence/phase0/anchor_sync_hooks.json",
}

failures = []
checked = []

def validate_pass(name: str, path: Path):
    if not path.exists():
        failures.append(f"missing_evidence:{name}:{path}")
        checked.append({"name": name, "path": str(path), "status": "MISSING"})
        return
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        failures.append(f"invalid_json:{name}:{path}")
        checked.append({"name": name, "path": str(path), "status": "INVALID_JSON"})
        return
    status = (payload.get("status") or "").upper()
    checked.append({"name": name, "path": str(path.relative_to(root) if path.is_relative_to(root) else path), "status": status})
    if status != "PASS":
        failures.append(f"evidence_not_pass:{name}:{status}")

for n, p in required_phase0.items():
    validate_pass(n, p)
for n, p in required_phase1.items():
    validate_pass(n, p)

if not phase1_contract_file.exists():
    failures.append(f"missing_phase1_contract_status:{phase1_contract_file}")
else:
    try:
        payload = json.loads(phase1_contract_file.read_text(encoding="utf-8"))
        if payload.get("status") != "PASS":
            failures.append("phase1_contract_status_not_pass")
        if payload.get("run_phase1_gates") is not True:
            failures.append("phase1_contract_not_executed_with_phase1_gates")
    except Exception:
        failures.append("phase1_contract_status_invalid_json")

if not phase1_contract_spec.exists():
    failures.append(f"missing_phase1_contract_spec:{phase1_contract_spec}")
else:
    try:
        rows = yaml.safe_load(phase1_contract_spec.read_text(encoding="utf-8")) or []
        by_id = {str(r.get("invariant_id")): r for r in rows if isinstance(r, dict) and r.get("invariant_id")}
        for invariant in ("INV-039", "INV-048"):
            row = by_id.get(invariant)
            if row is None:
                failures.append(f"missing_deferred_row:{invariant}")
                continue
            if str(row.get("status")) != "deferred_to_phase2":
                failures.append(f"deferred_status_mismatch:{invariant}:{row.get('status')}")
            if bool(row.get("required", False)):
                failures.append(f"deferred_row_required_true:{invariant}")
    except Exception as exc:
        failures.append(f"phase1_contract_spec_parse_error:{exc}")

status = "PASS" if not failures else "FAIL"

payload = {
    "check_id": "PHASE1-CLOSEOUT-VERIFICATION",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "run_phase1_gates": os.environ.get("RUN_PHASE1_GATES", "0") == "1",
    "checked": checked,
    "failures": failures,
}

out_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print("❌ Phase-1 closeout verification failed", file=sys.stderr)
    for item in failures:
        print(f" - {item}", file=sys.stderr)
    sys.exit(1)

print(f"Phase-1 closeout verification passed. Evidence: {out_file}")
PY
