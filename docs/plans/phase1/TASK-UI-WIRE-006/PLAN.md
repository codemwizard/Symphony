# TASK-UI-WIRE-006 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TASK-UI-WIRE-006
failure_signature: PHASE1.TASK.UI.WIRE.006.DRILLDOWN
origin_task_id: TASK-UI-WIRE-006

## Mission
Replace fake drill-down behavior with a real supervisory instruction-detail route and UI surface.

## Implementation Summary
- Add the real detail route: `GET /v1/supervisory/instructions/{instructionId}/detail`.
- Return interpreted proof state, raw artifact references, supplier/policy context, and ack/interrupt placeholder fields.
- Wire the supervisory slideout to fetch and render the real detail payload in LIVE/HYBRID modes.
- Preserve explicit HYBRID fallback to demo drill data only when the live route fails.

## Constraints
- Route contract is `GET /v1/supervisory/instructions/{instructionId}/detail`.
- View must remain read-only and tenant/programme scoped.
- Ack and interrupt slots must remain present even if real payload state is not projected until TASK-UI-WIRE-008.

## Verification Commands
- `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -nologo`
- `bash scripts/audit/verify_task_ui_wire_006.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-006 --evidence evidence/phase1/task_ui_wire_006_instruction_detail.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-c.md`

## Evidence Paths
- `evidence/phase1/task_ui_wire_006_instruction_detail.json`

## repro_command
- `bash scripts/audit/verify_task_ui_wire_006.sh`

## verification_commands_run
- `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -nologo`
- `bash scripts/audit/verify_task_ui_wire_006.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-006 --evidence evidence/phase1/task_ui_wire_006_instruction_detail.json`

## final_status
- `COMPLETED`
