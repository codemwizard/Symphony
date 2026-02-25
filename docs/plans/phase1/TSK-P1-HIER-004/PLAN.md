# TSK-P1-HIER-004 PLAN

Task: TSK-P1-HIER-004
Title: Person model explicit + enrollment model
Origin: docs/tasks/phase1_prompts.md (Execution Metadata Patch Block)

## Objective
Implement append-only `member_device_events` anchored to ingress attestations with deterministic FK/check/trigger verification evidence.

## Scope
- Add migration `0049_hier_004_member_device_events_append_only.sql`.
- Add verifier `scripts/db/verify_tsk_p1_hier_004.sh`.
- Emit evidence `evidence/phase1/tsk_p1_hier_004__person_model_explicit_enrollment.json`.
- Add task metadata and execution log for closeout traceability.

## Verification Commands
- `bash scripts/db/verify_tsk_p1_hier_004.sh --evidence evidence/phase1/tsk_p1_hier_004__person_model_explicit_enrollment.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification_commands_run
- `bash scripts/db/verify_tsk_p1_hier_004.sh --evidence evidence/phase1/tsk_p1_hier_004__person_model_explicit_enrollment.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
