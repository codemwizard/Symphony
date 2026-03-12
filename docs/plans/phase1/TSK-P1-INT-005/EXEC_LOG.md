# TSK-P1-INT-005 Execution Log

failure_signature: PHASE1.TSK_P1_INT_005.EXECUTION_FAILURE
origin_task_id: TSK-P1-INT-005
Plan: docs/plans/phase1/TSK-P1-INT-005/PLAN.md

## repro_command
`bash scripts/audit/verify_tsk_p1_int_005.sh`

## verification_commands_run
- `bash scripts/audit/verify_tsk_p1_int_005.sh` -> PASS

## final_status
COMPLETED

## execution_notes
- Updated `docs/security/SOVEREIGN_VPC_POSTURE.md` with a Phase-1 restricted-path proof section limited to implemented guarded paths.
- Reused the existing KYC hash bridge self-test as the implemented restricted/offline proof surface.
- Produced evidence at `evidence/phase1/tsk_p1_int_005_restricted_posture.json`.

## Final Summary
- Restricted-mode proof is explicitly scoped to the file-backed KYC hash bridge guarded path.
- The proof demonstrates no required DB dependency, no required external network dependency, and no raw regulated payload emission in the off-domain artifact.
- Guarded-path rejection is proven by the existing `pii_field_rejected` case on the implemented endpoint.
