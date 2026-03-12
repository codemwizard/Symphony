# TSK-P1-074 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TSK-P1-074
failure_signature: PHASE1.TSK.P1.074.HOOK_SOURCE_NORMALIZATION
origin_task_id: TSK-P1-074

## Goal
Normalize the local hook topology so the tracked hook source and the active installed hook destination are explicit, documented, and mechanically verifiable.

## Scope
- Define the tracked hook source model.
- Define the active installed hook destination model.
- Normalize installer behavior to match the documented model.
- Add a verifier that fails when hook topology drifts.

## Acceptance Criteria
- One tracked hook source is documented.
- One active installed destination is documented.
- Installer behavior matches the documented topology.
- A verifier fails if hook source, installation path, or docs diverge.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_074.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## repro_command
- `bash scripts/audit/verify_tsk_p1_074.sh`

## verification_commands_run
- `bash scripts/audit/verify_tsk_p1_074.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## final_status
- `planned`
