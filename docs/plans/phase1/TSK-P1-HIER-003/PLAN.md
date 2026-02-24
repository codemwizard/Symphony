# TSK-P1-HIER-003 PLAN

Task: TSK-P1-HIER-003
Title: Distribution entities + tenant denorm + ceilings
Origin: docs/tasks/phase1_prompts.md (Execution Metadata Patch Block)

## Objective
Implement `member_devices` with tenant denormalization, member binding, active lookup indexes, and deterministic verifier evidence.

## Scope
- Add migration `0048_hier_003_member_devices_distribution_ceiling.sql`.
- Add verifier `scripts/db/verify_tsk_p1_hier_003.sh`.
- Emit evidence `evidence/phase1/tsk_p1_hier_003__distribution_entities_tenant_denorm_ceilings.json`.
- Add task metadata and execution log for closeout traceability.

## Verification Commands
- `bash scripts/db/verify_tsk_p1_hier_003.sh --evidence evidence/phase1/tsk_p1_hier_003__distribution_entities_tenant_denorm_ceilings.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
