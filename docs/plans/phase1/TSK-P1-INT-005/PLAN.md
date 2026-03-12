# TSK-P1-INT-005 Plan

Task ID: TSK-P1-INT-005

## objective
Restricted/offline posture proof on implemented guarded paths

## scope
1. Dependency completion: TSK-P1-INT-001.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Prove restricted-mode run without required DB dependency.
2. Prove no required external network dependency in restricted scenario.
3. Prove off-domain artifacts exclude raw regulated payloads.
4. Prove guarded path rejection for forbidden fields on implemented endpoints.

## acceptance_criteria
- Restricted mode succeeds without required DB/network dependencies.
- Off-domain artifacts contain verification material without raw regulated payloads.
- Guarded paths reject forbidden regulated fields with evidence.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_005.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_005.sh
verification_commands_run:
- bash scripts/audit/verify_led_004_kyc_hash_bridge_endpoint.sh
- python3 - <<'PY'
  import json
  from pathlib import Path
  path = Path("evidence/phase1/tsk_p1_int_005_restricted_posture.json")
  payload = json.loads(path.read_text(encoding="utf-8"))
  assert payload["status"] == "PASS"
  assert payload["details"]["retention_class"] == "FIC_AML_CUSTOMER_ID"
  print("PASS")
  PY
- bash scripts/audit/verify_tsk_p1_int_005.sh
final_status: planned
origin_task_id: TSK-P1-INT-005
origin_gate_id: TSK_P1_INT_005
