# TSK-P1-INT-009B Plan

Task ID: TSK-P1-INT-009B

## objective
Post-cutover restore-time proof and integrity parity validation

## scope
1. Dependency completion: TSK-P1-STOR-001.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Validate measured restore behavior on post-cutover backend using declared RTO policy.
2. Verify PITR evidence includes elapsed-seconds metrics and fail-closed behavior when missing.
3. Verify storage substitution does not regress integrity verifier behavior.
4. Verify STOR-001 evidence is consumed as predecessor proof for backend context.

## acceptance_criteria
- Evidence records declared_rto_seconds, restore_elapsed_seconds, rto_met, and optional rto_signoff_ref when cap is exceeded.
- PITR verifier fails when restore_elapsed_seconds is missing or invalid.
- Restore proof is measured on post-cutover backend and is linked to STOR-001 evidence.
- Integrity verifier parity passes after cutover.

## remediation_trace
failure_signature: PHASE1.TSK_P1_INT_009B.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_int_009b.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_int_009b.sh
- python3 scripts/audit/validate_evidence.py --task TSK-P1-INT-009B --evidence evidence/phase1/tsk_p1_int_009b_restore_parity.json
final_status: planned
origin_task_id: TSK-P1-INT-009B
origin_gate_id: TSK_P1_INT_009B
