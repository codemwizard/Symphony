# TASK-UI-WIRE-004 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TASK-UI-WIRE-004
failure_signature: PHASE1.TASK.UI.WIRE.004.OPERATOR_ACTIONS
origin_task_id: TASK-UI-WIRE-004

## Mission
Start Wave B by removing admin-secret exposure from the browser bootstrap and routing privileged operator actions through same-origin pilot-demo proxy endpoints.

## Constraints
- The browser must not receive `SYMPHONY_UI_ADMIN_API_KEY`.
- The browser must not send `x-admin-api-key`.
- Privileged actions must use same-origin proxy routes.
- This branch slice does not yet claim full verify-ref or full action wiring completion.

## Verification Commands
- `bash scripts/audit/verify_task_ui_wire_004.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-004 --evidence evidence/phase1/task_ui_wire_004_operator_action_wiring.json`

## Approval References
- `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-b.md`
- `evidence/phase1/approval_metadata.json`

## Evidence Paths
- `evidence/phase1/task_ui_wire_004_operator_action_wiring.json`

## repro_command
- `bash scripts/audit/verify_task_ui_wire_004.sh`

## verification_commands_run
- `PENDING_IMPLEMENTATION`

## final_status
- `IN_PROGRESS`
