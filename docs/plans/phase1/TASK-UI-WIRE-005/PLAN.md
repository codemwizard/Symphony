# TASK-UI-WIRE-005 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TASK-UI-WIRE-005
failure_signature: PHASE1.TASK.UI.WIRE.005.PROOF_MODEL
origin_task_id: TASK-UI-WIRE-005

## Mission
Expand the supervisory reveal payload to the canonical PT-001 through PT-004 proof model required by the v3 shell.

## Implementation Summary
- Extend the reveal read model with canonical PT-001 through PT-004 proof rows.
- Preserve the existing top-level reveal fields used by earlier demo consumers.
- Add rich proof status values (`PRESENT`, `MISSING`, `FAILED`, `FLAGGED`) plus GPS/MSISDN-related fields where applicable.
- Document the new reveal contract in `docs/operations/SUPERVISORY_REVEAL_API_V2.md`.
- Prove the model through the supervisory read-model self-test and the Wave C task verifier.

## Constraints
- Preserve compatibility with existing reveal consumers.
- Proof rows must align to PT-001, PT-002, PT-003, and PT-004.
- Rich statuses must include FAILED and FLAGGED.
- The proof model must be backed by real read-model inputs, not client-side invention.

## Verification Commands
- `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -nologo`
- `bash scripts/audit/verify_task_ui_wire_005.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-005 --evidence evidence/phase1/task_ui_wire_005_proof_model.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-c.md`

## Evidence Paths
- `evidence/phase1/task_ui_wire_005_proof_model.json`

## repro_command
- `bash scripts/audit/verify_task_ui_wire_005.sh`

## verification_commands_run
- `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -nologo`
- `bash scripts/audit/verify_task_ui_wire_005.sh`
- `python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-005 --evidence evidence/phase1/task_ui_wire_005_proof_model.json`

## final_status
- `COMPLETED`
