# REM-2026-02-24 CHECKPOINT CS-0 PLAN

failure_signature: checkpoint_evidence_missing_check_id
origin_gate_id: EVIDENCE-SCHEMA-VALIDATION
origin_task_id: checkpoint/CS-0

## repro_command
- bash scripts/audit/validate_evidence_schema.sh

## scope
- Ensure checkpoint evidence payloads include schema-required `check_id`.
- Keep checkpoint dependency/pass semantics unchanged.

## implementation_steps
1. Update scripts/audit/verify_checkpoint.sh to emit `check_id`.
2. Regenerate evidence/phase1/checkpoint__CS-0.json.
3. Re-run evidence schema validation.

## verification_commands_run
- bash scripts/audit/verify_tsk_p1_059.sh --evidence evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json
- bash scripts/audit/verify_checkpoint.sh --checkpoint checkpoint/CS-0 --evidence evidence/phase1/checkpoint__CS-0.json
- bash scripts/audit/validate_evidence_schema.sh

## final_status
- in_progress
