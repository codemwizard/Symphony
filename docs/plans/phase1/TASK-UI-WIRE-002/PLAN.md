# TASK-UI-WIRE-002 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TASK-UI-WIRE-002
failure_signature: PHASE1.TASK.UI.WIRE.002.ADAPTER_ALIGNMENT
origin_task_id: TASK-UI-WIRE-002

## Mission
Build a repo-aligned supervisory UI adapter using `/v1` routes, explicit tenant context, and explicit HYBRID fallback behavior.

## Constraints
- Default mode is HYBRID.
- LIVE surfaces must not silently fall back.
- The fallback dataset must be a committed fixture file in the UI tree.

## Verification Commands
- `bash scripts/audit/verify_task_ui_wire_002.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-002 --evidence evidence/phase1/task_ui_wire_002_adapter_alignment.json`

## Approval References
- `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-a.md`
- `evidence/phase1/approval_metadata.json`

## Evidence Paths
- `evidence/phase1/task_ui_wire_002_adapter_alignment.json`

## repro_command
- `bash scripts/audit/verify_task_ui_wire_002.sh`

## verification_commands_run
- `bash scripts/audit/verify_task_ui_wire_002.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-002 --evidence evidence/phase1/task_ui_wire_002_adapter_alignment.json`

## final_status
- `COMPLETED`
