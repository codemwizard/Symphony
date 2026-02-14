#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT_FILE="${CONTRACT_FILE:-$ROOT_DIR/docs/PHASE1/phase1_contract.yml}"
CP_FILE="${CP_FILE:-$ROOT_DIR/docs/control_planes/CONTROL_PLANES.yml}"
SCHEMA_FILE="${SCHEMA_FILE:-$ROOT_DIR/docs/architecture/evidence_schema.json}"
APPROVAL_SCHEMA_FILE="${APPROVAL_SCHEMA_FILE:-$ROOT_DIR/docs/operations/approval_metadata.schema.json}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$ROOT_DIR/evidence/phase1}"
EVIDENCE_FILE="${EVIDENCE_FILE:-$EVIDENCE_DIR/phase1_contract_status.json}"
RUN_PHASE1_GATES="${RUN_PHASE1_GATES:-0}"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

ROOT_DIR="$ROOT_DIR" CONTRACT_FILE="$CONTRACT_FILE" CP_FILE="$CP_FILE" SCHEMA_FILE="$SCHEMA_FILE" APPROVAL_SCHEMA_FILE="$APPROVAL_SCHEMA_FILE" EVIDENCE_FILE="$EVIDENCE_FILE" RUN_PHASE1_GATES="$RUN_PHASE1_GATES" python3 - <<'PY'
import json
import os
from pathlib import Path

try:
    import yaml  # type: ignore
    import jsonschema  # type: ignore
except Exception as e:
    out = {
        "check_id": "PHASE1-CONTRACT-STATUS",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "errors": [f"dependency_missing:{e}"],
    }
    Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n")
    raise SystemExit(1)

contract_file = Path(os.environ["CONTRACT_FILE"])
cp_file = Path(os.environ["CP_FILE"])
schema_file = Path(os.environ["SCHEMA_FILE"])
approval_schema_file = Path(os.environ["APPROVAL_SCHEMA_FILE"])
evidence_file = Path(os.environ["EVIDENCE_FILE"])
root_dir = Path(os.environ["ROOT_DIR"])
run_phase1 = os.environ.get("RUN_PHASE1_GATES", "0") == "1"

errors = []
checked = []
required_rows = 0
required_checked = 0

if not contract_file.exists():
    errors.append(f"contract_missing:{contract_file}")
    contract = []
else:
    try:
        contract = yaml.safe_load(contract_file.read_text(encoding="utf-8")) or []
    except Exception as e:
        errors.append(f"contract_parse_error:{e}")
        contract = []

if not isinstance(contract, list):
    errors.append("contract_not_list")
    contract = []

if not cp_file.exists():
    errors.append(f"control_planes_missing:{cp_file}")
    cp = {}
else:
    cp = yaml.safe_load(cp_file.read_text(encoding="utf-8")) or {}

if not schema_file.exists():
    errors.append(f"evidence_schema_missing:{schema_file}")
    schema = {}
else:
    schema = json.loads(schema_file.read_text(encoding="utf-8"))

if not approval_schema_file.exists():
    errors.append(f"approval_schema_missing:{approval_schema_file}")
    approval_schema = {}
else:
    approval_schema = json.loads(approval_schema_file.read_text(encoding="utf-8"))

gate_map = {}
for plane in (cp.get("control_planes") or {}).values():
    for gate in plane.get("required_gates") or []:
        gid = str((gate or {}).get("gate_id", "")).strip()
        if gid:
            gate_map[gid] = gate

reserved_not_wired = {"INT-G25", "INT-G26", "INT-G27"}

for row in contract:
    if not isinstance(row, dict):
        errors.append("row_not_mapping")
        continue
    iid = str(row.get("invariant_id", "")).strip()
    status = str(row.get("status", "")).strip()
    required = bool(row.get("required", False))
    gate_id = str(row.get("gate_id", "")).strip()
    verifier = str(row.get("verifier", "")).strip()
    evidence_path = str(row.get("evidence_path", "")).strip()

    if not iid:
        errors.append("row_missing_invariant_id")
        continue

    for f in ("status", "required", "gate_id", "verifier", "evidence_path"):
        if f not in row:
            errors.append(f"{iid}:missing_field:{f}")

    if gate_id:
        if gate_id not in gate_map:
            if not (gate_id in reserved_not_wired and not required):
                errors.append(f"{iid}:gate_not_declared:{gate_id}")

    if required and status in ("planned", "pending"):
        errors.append(f"{iid}:required_cannot_be_{status}")

    if required:
        required_rows += 1

    if not evidence_path:
        checked.append({"invariant_id": iid, "status": "SKIPPED", "reason": "no_evidence_path"})
        continue

    # Phase-1 rows must point at phase1 evidence paths.
    if status != "phase0_prerequisite" and not evidence_path.startswith("evidence/phase1/"):
        errors.append(f"{iid}:phase1_evidence_path_required:{evidence_path}")
    if status == "phase0_prerequisite" and not evidence_path.startswith("evidence/phase0/"):
        errors.append(f"{iid}:phase0_prerequisite_evidence_path_required:{evidence_path}")

    ev_path = Path(evidence_path)
    if not ev_path.is_absolute():
        ev_path = root_dir / ev_path

    # Fail-closed required rows only when phase1 gates enabled.
    should_enforce = required and run_phase1
    if should_enforce:
        if not ev_path.exists():
            errors.append(f"{iid}:missing_evidence:{evidence_path}")
            checked.append({"invariant_id": iid, "status": "FAIL", "reason": "missing_evidence"})
            continue
        try:
            payload = json.loads(ev_path.read_text(encoding="utf-8"))
            schema_used = "default"
            selected_schema = schema
            if Path(evidence_path).name == "approval_metadata.json":
                try:
                    jsonschema.validate(instance=payload, schema=approval_schema)
                    schema_used = "approval_metadata"
                except Exception:
                    jsonschema.validate(instance=payload, schema=schema)
                    schema_used = "approval_metadata_fallback_default"
            else:
                jsonschema.validate(instance=payload, schema=selected_schema)
            required_checked += 1
            checked.append({"invariant_id": iid, "status": "PASS", "evidence_path": evidence_path, "schema": schema_used})
        except Exception as e:
            errors.append(f"{iid}:schema_validation_failed:{e}")
            checked.append({"invariant_id": iid, "status": "FAIL", "reason": "schema_validation_failed"})
    else:
        checked.append({"invariant_id": iid, "status": "SKIPPED", "reason": "not_required_or_phase1_disabled"})

overall = "PASS" if not errors else "FAIL"
out = {
    "check_id": "PHASE1-CONTRACT-STATUS",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": overall,
    "run_phase1_gates": run_phase1,
    "required_rows": required_rows,
    "required_rows_checked": required_checked,
    "checked": checked,
    "errors": errors,
}
evidence_file.write_text(json.dumps(out, indent=2) + "\n")

if errors:
    print("❌ Phase-1 contract verification failed")
    for e in errors:
        print(f" - {e}")
    raise SystemExit(1)

print(f"Phase-1 contract verification passed. Evidence: {evidence_file}")
PY
