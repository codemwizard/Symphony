# TSK-HARD-002 PLAN

Task: TSK-HARD-002
origin_task_id: TSK-HARD-002
failure_signature: HARDENING.TSK.HARD.002.EVENT_SCHEMA_REGISTRATION_REQUIRED

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Register the 10 hardening event-class schemas in `evidence/schemas/hardening/event_classes/`.
- Ensure `validate_evidence_schema.sh` auto-loads event-class schemas and validates by `event_class`.

## verification_commands_run
- `bash scripts/audit/verify_tsk_hard_002.sh`
- `python3 -c "import json, jsonschema; d=json.load(open('evidence/phase1/hardening/tsk_hard_002.json')); s=json.load(open('evidence/schemas/hardening/tsk_hard_002.schema.json')); jsonschema.validate(d, s); print('schema_ok')"`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
