# TSK-P1-INT-001 Plan

Task ID: TSK-P1-INT-001

## objective
Reframe integrity model from storage immutability to tamper-evident architecture

## scope
1. Dependency completion: none.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Replace WORM/immutability-first language in Phase-1 integrity and storage docs.
2. Explicitly distinguish tamper-evident vs tamper-resistant guarantees.
3. Explicitly define external execution acknowledgement within the trust boundary model.

## acceptance_criteria
- No Phase-1 integrity document treats storage backend as primary trust guarantee.
- Banned language is absent or explicitly qualified.
- Trust basis is stated as signed artifacts, append-only history, verifiable chain-of-custody, and acknowledgement visibility.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_001.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_001.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_int_001.sh
final_status: planned
origin_task_id: TSK-P1-INT-001
origin_gate_id: TSK_P1_INT_001
