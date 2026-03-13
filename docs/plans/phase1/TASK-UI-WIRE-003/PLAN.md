# TASK-UI-WIRE-003 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TASK-UI-WIRE-003
failure_signature: PHASE1.TASK.UI.WIRE.003.REVEAL_WIRING
origin_task_id: TASK-UI-WIRE-003

## Mission
Wire the main supervisory reveal panels to the repo's real reveal API.

## Constraints
- Use `/v1/supervisory/programmes/{programId}/reveal`.
- Bind only to repo-native payload keys.
- HYBRID fallback must remain visibly labeled.

## Verification Commands
- `bash scripts/audit/verify_task_ui_wire_003.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-003 --evidence evidence/phase1/task_ui_wire_003_reveal_live_wiring.json`

## Approval References
- `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-b.md`
- `evidence/phase1/approval_metadata.json`

## Evidence Paths
- `evidence/phase1/task_ui_wire_003_reveal_live_wiring.json`

## repro_command
- `bash scripts/audit/verify_task_ui_wire_003.sh`

## verification_commands_run
- `PENDING_IMPLEMENTATION`

## final_status
- `PLANNED`
