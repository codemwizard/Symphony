# TASK-UI-WIRE-008 Plan

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective
Project AWAITING_EXECUTION, acknowledgement, escalation, and supervisor interrupt state into the reveal/detail API and the v3 supervisory shell.

## Scope
- add read-model and API projection for completed INT-004 control state
- render projected state in the shell
- verify with seeded scenarios

## Verification
- bash scripts/audit/verify_task_ui_wire_008.sh
- python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-008 --evidence evidence/phase1/task_ui_wire_008_ack_interrupt.json
