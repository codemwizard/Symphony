# TSK-P1-HIER-005 PLAN

Task: TSK-P1-HIER-005
Title: Member devices with tenant-safe reverse lookup indexes
Origin: docs/tasks/phase1_prompts.md (Execution Metadata Patch Block)

## Objective
Implement `verify_instruction_hierarchy()` and deterministic SQLSTATE verification evidence for tenant-safe hierarchy linkage checks.

## Scope
- Add migration `0050_hier_005_instruction_hierarchy_verifier.sql`.
- Add verifier `scripts/db/verify_tsk_p1_hier_005.sh`.
- Emit evidence `evidence/phase1/tsk_p1_hier_005__member_devices_tenant_safe_reverse_lookup.json`.
- Update task metadata and execution log for closeout traceability.

## Verification Commands
- `bash scripts/db/verify_tsk_p1_hier_005.sh --evidence evidence/phase1/tsk_p1_hier_005__member_devices_tenant_safe_reverse_lookup.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification_commands_run
- `bash scripts/db/verify_tsk_p1_hier_005.sh --evidence evidence/phase1/tsk_p1_hier_005__member_devices_tenant_safe_reverse_lookup.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
