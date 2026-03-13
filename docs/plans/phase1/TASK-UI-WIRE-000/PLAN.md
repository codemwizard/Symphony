# TASK-UI-WIRE-000 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TASK-UI-WIRE-000
failure_signature: PHASE1.TASK.UI.WIRE.000.SOURCE_OF_TRUTH
origin_task_id: TASK-UI-WIRE-000

## Mission
Freeze the canonical supervisory UI shell and backing-mode matrix for GreenTech4CE demo scope before any route or adapter wiring begins.

## Constraints
- Preserve truthful Phase-1 claims only.
- Mark the thin shell as legacy, not current.
- Treat DEMO prerequisites as capabilities that must be revalidated against the new shell.

## Verification Commands
- `bash scripts/audit/verify_task_ui_wire_000.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-000 --evidence evidence/phase1/task_ui_wire_000_source_of_truth.json`
- `bash scripts/audit/verify_agent_conformance.sh`

## Approval References
- `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-a.md`
- `evidence/phase1/approval_metadata.json`

## Evidence Paths
- `evidence/phase1/task_ui_wire_000_source_of_truth.json`

## repro_command
- `bash scripts/audit/verify_task_ui_wire_000.sh`

## verification_commands_run
- `bash scripts/audit/verify_task_ui_wire_000.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-000 --evidence evidence/phase1/task_ui_wire_000_source_of_truth.json`
- `bash scripts/audit/verify_agent_conformance.sh`

## final_status
- `COMPLETED`
