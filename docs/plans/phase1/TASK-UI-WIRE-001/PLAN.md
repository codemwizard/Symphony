# TASK-UI-WIRE-001 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TASK-UI-WIRE-001
failure_signature: PHASE1.TASK.UI.WIRE.001.SHELL_PORT
origin_task_id: TASK-UI-WIRE-001

## Mission
Port the v3 supervisory shell into the repo and serve it as the primary pilot-demo supervisory route while preserving DEMO-008 verifier compatibility.

## Constraints
- Use `/pilot-demo/supervisory` and `/pilot-demo/supervisory-legacy` only.
- Return 404 outside pilot-demo.
- Preserve or alias the DEMO-008 compatibility IDs.
- Avoid forbidden unsupported-claim substrings.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_demo_008.sh`
- `bash scripts/audit/verify_task_ui_wire_001.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-001 --evidence evidence/phase1/task_ui_wire_001_shell_port.json`

## Approval References
- `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-a.md`
- `evidence/phase1/approval_metadata.json`

## Evidence Paths
- `evidence/phase1/task_ui_wire_001_shell_port.json`

## repro_command
- `bash scripts/audit/verify_task_ui_wire_001.sh`

## verification_commands_run
- `bash scripts/audit/verify_tsk_p1_demo_008.sh`
- `bash scripts/audit/verify_task_ui_wire_001.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-001 --evidence evidence/phase1/task_ui_wire_001_shell_port.json`

## final_status
- `COMPLETED`
