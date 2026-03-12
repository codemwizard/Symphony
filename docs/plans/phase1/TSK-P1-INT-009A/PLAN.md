# TSK-P1-INT-009A Plan

Task ID: TSK-P1-INT-009A

## objective
Storage policy rescope and RTO discipline before SeaweedFS cutover

## scope
1. Dependency completion: TSK-P1-INT-001.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Define storage migration posture as infrastructure/durability work, not trust-root semantics.
2. Define Phase-1 RTO policy with hard cap and signoff exception rule.
3. Define STOR-001 acceptance vocabulary for backend-neutral retention controls.
4. Wire verifier/evidence registry mapping before implementation cutover.

## acceptance_criteria
- Storage trust language is explicitly tamper-evident architecture and not backend immutability claims.
- RTO policy is explicit (default cap 4 hours) with signoff requirement when exceeded.
- STOR-001 criteria include post-cutover smoke IO and parity checks as mandatory gates.
- Registry contains verifier-to-evidence mapping for INT-009A, STOR-001, and INT-009B scripts.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_009A.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_009a.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_int_009a.sh
- python3 scripts/audit/validate_evidence.py --task TSK-P1-INT-009A --evidence evidence/phase1/tsk_p1_int_009a_storage_policy_rescope.json
final_status: planned
origin_task_id: TSK-P1-INT-009A
origin_gate_id: TSK_P1_INT_009A
