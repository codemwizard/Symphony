# TSK-HARD-010 PLAN

Task: TSK-HARD-010
origin_task_id: TSK-HARD-010
failure_signature: HARDENING.TSK.HARD.010.INQUIRY_POLICY_FRAMEWORK_REQUIRED

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Define metadata-driven rail inquiry policy framework and rail scenario matrix.
- Ensure scenario rows include required columns and valid implementing task IDs.

## verification_commands_run
- `bash scripts/audit/verify_tsk_hard_010.sh`
- `python3 -c "import json, jsonschema; d=json.load(open('evidence/phase1/hardening/tsk_hard_010.json')); s=json.load(open('evidence/schemas/hardening/tsk_hard_010.schema.json')); jsonschema.validate(d, s); print('schema_ok')"`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
