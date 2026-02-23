# REM-CHECKPOINT-001 PLAN

failure_signature: PHASE1.DAG.CHECKPOINT.SECTION_MISSING
origin_task_id: checkpoint/ESC

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## Scope
- Remediation trace for production-affecting regulated-surface changes in `docs/tasks/` and `scripts/audit/`.
- Add execution-grade prompt-pack sections for all DAG `checkpoint/*` nodes.
- Add a deterministic checkpoint verifier that can be invoked by the prompt pack.

## Constraints
- No new DAG nodes (do not invent tasks).
- Do not weaken gates; fix must be fail-closed.
- Preserve canonical governance references: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`.

## verification_commands_run
- `bash scripts/audit/verify_task_evidence_contract.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- planned

