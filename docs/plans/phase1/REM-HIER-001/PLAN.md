# REM-HIER-001 PLAN

failure_signature: PHASE1.HIER.PROMPT.UPDATE
origin_task_id: TSK-P1-HIER-001

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## Scope
- Align the Phase-1 hierarchy prompt with existing Phase-0 tenancy tables.
- Update `docs/tasks/phase1_prompts.md` (TSK-P1-HIER-001 section) to reuse `public.programs` and `public.tenant_members`, document verifier expectations, and extend metadata block.
- Provide deterministic remediation documentation for this governance-level change.

## verification_commands_run
- `bash scripts/audit/verify_remediation_trace.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- planned
