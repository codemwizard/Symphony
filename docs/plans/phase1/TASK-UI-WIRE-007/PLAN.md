# TASK-UI-WIRE-007 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TASK-UI-WIRE-007
failure_signature: PHASE1.TASK.UI.WIRE.007.EXPORT
origin_task_id: TASK-UI-WIRE-007

## Mission
Expose a real synchronous export transport for the supervisory shell while preserving DEMO-009 reporting-pack behavior.

## Constraints
- Transport is synchronous.
- Route output must be compared against DEMO-009 generator output.

## Verification Commands
- `bash scripts/audit/verify_task_ui_wire_007.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-007 --evidence evidence/phase1/task_ui_wire_007_export.json`

## Approval References
- `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-b.md`
- `evidence/phase1/approval_metadata.json`

## Evidence Paths
- `evidence/phase1/task_ui_wire_007_export.json`

## repro_command
- `bash scripts/audit/verify_task_ui_wire_007.sh`

## verification_commands_run
- `PENDING_IMPLEMENTATION`

## final_status
- `PLANNED`
