# TSK-HARD-011 PLAN

Task: TSK-HARD-011
origin_task_id: TSK-HARD-011
failure_signature: HARDENING.TSK.HARD.011.METADATA_DRIVEN_INQUIRY_POLICY_REQUIRED

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Implement metadata-driven per-rail inquiry policy loader from a versioned store.
- Enforce policy activation evidence emission and fail-closed update constraints.

## verification_commands_run
- `bash scripts/audit/verify_tsk_hard_011.sh`
- `python3 -c "import json, jsonschema; d=json.load(open('evidence/phase1/hardening/tsk_hard_011.json')); s=json.load(open('evidence/schemas/hardening/tsk_hard_011.schema.json')); jsonschema.validate(d, s); print('schema_ok')"`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
