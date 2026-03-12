#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/tsk_p1_int_006_offline_bridge.json"
BRIDGE_DOC="$ROOT_DIR/docs/operations/STORAGE_AND_INTEGRITY_POSITION_MINIO_TO_SEAWEEDFS.md"

bash "$ROOT_DIR/scripts/audit/verify_tsk_p1_int_002.sh"
bash "$ROOT_DIR/scripts/audit/verify_tsk_p1_int_003.sh"
bash "$ROOT_DIR/scripts/audit/verify_tsk_p1_int_004.sh"

rg -n "deliberate Phase-1 control path, not a workaround" "$BRIDGE_DOC" >/dev/null
rg -n "AWAITING_EXECUTION" "$BRIDGE_DOC" >/dev/null

python3 - <<'PY' "$ROOT_DIR" "$EVIDENCE"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
evidence_path = Path(sys.argv[2])

int002 = json.loads((root / "evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json").read_text(encoding="utf-8"))
int003 = json.loads((root / "evidence/phase1/tsk_p1_int_003_tamper_detection.json").read_text(encoding="utf-8"))
int004 = json.loads((root / "evidence/phase1/tsk_p1_int_004_ack_gap_controls.json").read_text(encoding="utf-8"))
bridge_doc = (root / "docs/operations/STORAGE_AND_INTEGRITY_POSITION_MINIO_TO_SEAWEEDFS.md").read_text(encoding="utf-8")

pass_all = (
    int002.get("status") == "PASS" and
    int003.get("status") == "PASS" and
    int004.get("status") == "PASS" and
    int002["domains"]["governed_instruction"]["chain_record_present"] is True and
    int003["tamper_detection_trigger_semantics"]["signed_file_tamper"] == "CHAIN_PAYLOAD_HASH_INVALID" and
    int004["controls"]["settlement_guard_present"] is True and
    "deliberate Phase-1 control path, not a workaround" in bridge_doc
)

payload = {
    "check_id": "TSK-P1-INT-006-OFFLINE-BRIDGE",
    "task_id": "TSK-P1-INT-006",
    "status": "PASS" if pass_all else "FAIL",
    "pass": pass_all,
    "bridge_claim": {
        "signed_instruction_generated_and_verifiable": int002["domains"]["governed_instruction"]["chain_record_present"],
        "modified_copy_fails_verification": int003["tamper_detection_trigger_semantics"]["signed_file_tamper"],
        "awaiting_execution_and_ack_gap_explicit": int004["controls"]["awaiting_execution_state"],
        "tier3_escalation_present": int004["controls"]["escalated_state"],
        "governed_control_path_not_workaround": "deliberate Phase-1 control path, not a workaround" in bridge_doc,
    },
    "source_evidence": [
        "evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json",
        "evidence/phase1/tsk_p1_int_003_tamper_detection.json",
        "evidence/phase1/tsk_p1_int_004_ack_gap_controls.json",
    ],
}
evidence_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
if not pass_all:
    raise SystemExit(1)
PY

echo "TSK-P1-INT-006 verification passed. Evidence: $EVIDENCE"
