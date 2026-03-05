# TSK-OPS-A1-STABILITY-GATE PLAN

Task: TSK-OPS-A1-STABILITY-GATE
origin_task_id: TSK-OPS-A1-STABILITY-GATE
failure_signature: HARDENING.TSK.OPS.A1.STABILITY_GATE_REQUIRED

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Verify A1 substrate stability before Wave-1 runtime hardening tasks close.
- Require passing manifest validation and schema-valid sandbox deploy dry-run evidence.

## verification_commands_run
- `bash scripts/audit/verify_program_a1_stability_gate.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
