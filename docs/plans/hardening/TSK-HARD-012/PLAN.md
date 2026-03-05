# TSK-HARD-012 PLAN

Task: TSK-HARD-012
origin_task_id: TSK-HARD-012
failure_signature: HARDENING.TSK.HARD.012.INQUIRY_STATE_MACHINE_REQUIRED

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Implement inquiry lifecycle state machine enforcement and fail-closed auto-finalize guard.
- Ensure max-attempt threshold is policy-resolved, not hardcoded.

## verification_commands_run
- `bash scripts/audit/verify_tsk_hard_012.sh`
- `python3 -c "import json, jsonschema; d=json.load(open('evidence/phase1/hardening/tsk_hard_012.json')); s=json.load(open('evidence/schemas/hardening/tsk_hard_012.schema.json')); jsonschema.validate(d, s); print('schema_ok')"`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
