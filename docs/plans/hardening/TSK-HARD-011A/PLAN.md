# TSK-HARD-011A PLAN

Task: TSK-HARD-011A
origin_task_id: TSK-HARD-011A
failure_signature: HARDENING.TSK.HARD.011A.POLICY_SNAPSHOT_DECISION_EVIDENCE_REQUIRED

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Ensure decision-time `policy_version_id` snapshot capture for inquiry/dispatch decisions.
- Prove historical decision records are unchanged after active policy version changes.

## verification_commands_run
- `bash scripts/audit/verify_tsk_hard_011a.sh`
- `python3 -c "import json, jsonschema; d=json.load(open('evidence/phase1/hardening/tsk_hard_011a.json')); s=json.load(open('evidence/schemas/hardening/tsk_hard_011a.schema.json')); jsonschema.validate(d, s); print('schema_ok')"`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
