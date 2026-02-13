# TSK-P1-006 Execution Log

failure_signature: PHASE1.TSK.P1.006
origin_task_id: TSK-P1-006

## repro_command
`scripts/dev/pre_ci.sh`

## verification_commands_run
- `bash scripts/audit/verify_phase1_contract.sh`
- `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_contract.sh`
- `bash scripts/audit/verify_control_planes_drift.sh`
- `bash scripts/audit/validate_evidence_schema.sh`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## final_status
COMPLETED
