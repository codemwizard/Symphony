# TSK-P1-INT-006 Plan

Task ID: TSK-P1-INT-006

## objective
Signed offline/pre-rail bridge proof pack

## scope
1. Dependency completion: TSK-P1-INT-002, TSK-P1-INT-004.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Aggregate signed instruction generation proof.
2. Aggregate tamper-failure proof for modified artifacts.
3. Aggregate AWAITING_EXECUTION and missing-ack escalation proof.
4. Prove chain-of-custody visibility for offline handoff.

## acceptance_criteria
- Signed instruction file is generated and verifiable.
- Modified copy fails verification (CHECKSUM_BREAK or equivalent).
- Missing acknowledgement remains explicit and escalates by policy.
- Evidence shows bridge as governed control path, not workaround.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_006.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_006.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_int_002.sh
- python3 - <<'PY'
  import json
  from pathlib import Path
  path = Path("evidence/phase1/tsk_p1_int_006_offline_bridge.json")
  payload = json.loads(path.read_text(encoding="utf-8"))
  assert payload["status"] == "PASS"
  assert payload["bridge_claim"]["governed_control_path_not_workaround"] is True
  print("PASS")
  PY
- bash scripts/audit/verify_tsk_p1_int_006.sh
final_status: planned
origin_task_id: TSK-P1-INT-006
origin_gate_id: TSK_P1_INT_006
