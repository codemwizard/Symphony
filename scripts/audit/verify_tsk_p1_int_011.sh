#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INT-011"
PLAN="docs/plans/phase1/TSK-P1-INT-011/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-INT-011/EXEC_LOG.md"
META="tasks/TSK-P1-INT-011/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_int_011_closeout_gate.json"

for f in "$PLAN" "$EXEC_LOG" "$META"; do
  if [[ ! -f "$f" ]]; then
    echo "missing_required_file:$f" >&2
    exit 1
  fi
done

# Refresh only the predecessor verifiers that actually exist in this branch.
# Earlier-wave verifiers are not present in the Wave E split and must be
# consumed via their committed evidence artifacts instead.
bash scripts/audit/verify_tsk_p1_int_010.sh
bash scripts/audit/verify_tsk_p1_int_012.sh

mkdir -p "$(dirname "$EVIDENCE")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE"
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

task_id, evidence_path = sys.argv[1:]
root = Path(".")
failures = []

def load_json(path: str) -> dict:
    file = root / path
    if not file.exists():
        failures.append(f"missing_required_file:{path}")
        return {}
    return json.loads(file.read_text(encoding="utf-8"))

def git_sha() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

int003 = load_json("evidence/phase1/tsk_p1_int_003_tamper_detection.json")
int004 = load_json("evidence/phase1/tsk_p1_int_004_ack_gap_controls.json")
int005 = load_json("evidence/phase1/tsk_p1_int_005_restricted_posture.json")
int006 = load_json("evidence/phase1/tsk_p1_int_006_offline_bridge.json")
int008 = load_json("evidence/phase1/tsk_p1_int_008_offline_verification.json")
int009b = load_json("evidence/phase1/tsk_p1_int_009b_restore_parity.json")
int010 = load_json("evidence/phase1/tsk_p1_int_010_language_sync.json")
int012 = load_json("evidence/phase1/tsk_p1_int_012_retention_policy.json")

def expect(condition: bool, label: str) -> None:
    if not condition:
        failures.append(label)

for name, payload in {
    "int003": int003,
    "int004": int004,
    "int005": int005,
    "int006": int006,
    "int008": int008,
    "int009b": int009b,
    "int010": int010,
    "int012": int012,
}.items():
    expect(payload.get("status") == "PASS", f"{name}_status_not_pass")
    expect(payload.get("pass") is True, f"{name}_pass_flag_false")

tamper = int003.get("tamper_detection_trigger_semantics") or {}
expect(tamper.get("signed_file_tamper") == "CHAIN_PAYLOAD_HASH_INVALID", "int003_signed_file_tamper")
expect(tamper.get("instruction_chain_break") == "CHAIN_CURRENT_HASH_INVALID", "int003_instruction_chain_break")
expect(tamper.get("evidence_event_chain_break") == "CHAIN_CURRENT_HASH_INVALID", "int003_evidence_event_chain_break")
expect(tamper.get("metadata_divergence") == "CHAIN_PAYLOAD_HASH_INVALID", "int003_metadata_divergence")

controls = int004.get("controls") or {}
expect(controls.get("awaiting_execution_state") is True, "int004_awaiting_execution_missing")
expect(controls.get("escalated_state") is True, "int004_escalated_state_missing")
expect(controls.get("settlement_guard_present") is True, "int004_settlement_guard_missing")

details = int005.get("details") or {}
tests = {}
for test in details.get("tests") or []:
    name = test.get("name", test.get("Name"))
    status = test.get("status", test.get("Status"))
    if name is not None:
        tests[name] = status
expect(tests.get("valid_hash_accepted") == "PASS", "int005_valid_hash_accepted")
expect(tests.get("unknown_provider_rejected") == "PASS", "int005_unknown_provider_rejected")
expect(tests.get("pii_field_rejected") == "PASS", "int005_pii_field_rejected")
expect(details.get("retention_class") == "FIC_AML_CUSTOMER_ID", "int005_retention_class")
expect(details.get("retention_class_confirmed") is True, "int005_retention_class_confirmed")

bridge = int006.get("bridge_claim") or {}
expect(bridge.get("signed_instruction_generated_and_verifiable") is True, "int006_signed_instruction")
expect(bridge.get("modified_copy_fails_verification") == "CHAIN_PAYLOAD_HASH_INVALID", "int006_modified_copy_semantics")
expect(bridge.get("awaiting_execution_and_ack_gap_explicit") is True, "int006_awaiting_execution_ack_gap")
expect(bridge.get("tier3_escalation_present") is True, "int006_tier3_escalation")
expect(bridge.get("governed_control_path_not_workaround") is True, "int006_governed_control_path")

expect(int008.get("offline_only") is True, "int008_offline_only")
expect(int008.get("network_required") is False, "int008_network_required")
expect(int008.get("live_runtime_required") is False, "int008_live_runtime_required")
expect(int008.get("tamper_rejection_pass") is True, "int008_tamper_rejection")

expect(isinstance(int009b.get("declared_rto_seconds"), int) and int009b.get("declared_rto_seconds") > 0, "int009b_declared_rto_seconds")
expect(isinstance(int009b.get("restore_elapsed_seconds"), int) and int009b.get("restore_elapsed_seconds") > 0, "int009b_restore_elapsed_seconds")
expect(int009b.get("storage_backend") == "seaweedfs", "int009b_storage_backend")
expect(int009b.get("integrity_verifier_parity_pass") is True, "int009b_integrity_parity")
expect(int009b.get("rto_met") is True, "int009b_rto_met")

expect(int010.get("tamper_evident_language_present") is True, "int010_tamper_evident_language")
expect(int010.get("signed_offline_bridge_language_present") is True, "int010_signed_offline_bridge_language")
expect(int010.get("acknowledgement_dependency_present") is True, "int010_acknowledgement_dependency")
expect(int010.get("awaiting_execution_state_visible") is True, "int010_awaiting_execution_state")

expect(int012.get("active_retention_days") == 90, "int012_active_retention_days")
expect(int012.get("archived_retention_years") == 7, "int012_archived_retention_years")
expect(int012.get("historical_retention_years") == 10, "int012_historical_retention_years")
expect(int012.get("machine_checkable_triggers_present") is True, "int012_machine_checkable_triggers")
expect(int012.get("dr_bundle_policy_link_present") is True, "int012_dr_bundle_policy_link")

status = "PASS" if not failures else "FAIL"
payload = {
    "check_id": "TSK-P1-INT-011-CLOSEOUT-GATE",
    "task_id": task_id,
    "run_id": os.environ.get("SYMPHONY_RUN_ID", f"int011-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"),
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": status,
    "pass": status == "PASS",
    "validated_evidence": {
        "int003": "evidence/phase1/tsk_p1_int_003_tamper_detection.json",
        "int004": "evidence/phase1/tsk_p1_int_004_ack_gap_controls.json",
        "int005": "evidence/phase1/tsk_p1_int_005_restricted_posture.json",
        "int006": "evidence/phase1/tsk_p1_int_006_offline_bridge.json",
        "int008": "evidence/phase1/tsk_p1_int_008_offline_verification.json",
        "int009b": "evidence/phase1/tsk_p1_int_009b_restore_parity.json",
        "int010": "evidence/phase1/tsk_p1_int_010_language_sync.json",
        "int012": "evidence/phase1/tsk_p1_int_012_retention_policy.json",
    },
    "semantic_closeout": {
        "tamper_trigger_semantics_verified": not any(f.startswith("int003_") for f in failures),
        "bridge_governance_states_verified": not any(f.startswith("int004_") for f in failures),
        "restricted_path_proof_verified": not any(f.startswith("int005_") for f in failures),
        "offline_bridge_claim_verified": not any(f.startswith("int006_") for f in failures),
        "shared_nothing_offline_verification_verified": not any(f.startswith("int008_") for f in failures),
        "restore_parity_verified": not any(f.startswith("int009b_") for f in failures),
        "language_sync_verified": not any(f.startswith("int010_") for f in failures),
        "retention_boundary_verified": not any(f.startswith("int012_") for f in failures),
    },
    "failures": failures,
    "mode": "semantic_closeout_validation",
}
Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")

if failures:
    raise SystemExit("semantic_closeout_failures:" + ",".join(failures))
PY

echo "TSK-P1-INT-011 verification passed. Evidence: $EVIDENCE"
