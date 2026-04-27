# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.GOVERNANCE.TASK_PLAN_LOG

origin_gate_id: pre_ci.verify_task_plans_present
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.
- Resolve the `pre_ci.verify_task_plans_present` gate failure.
- Resolve the `verify_task_meta_schema.sh` strict-mode failure on 5 legacy tasks to ensure clean pipeline convergence.

## Root Cause 1: Missing Plans
- The `pre_ci.verify_task_plans_present` gate failed because the Wave 7 implementation plans (`PLAN.md` and `EXEC_LOG.md`) were deleted when `generate_w7_strict_tasks.py` was executed in destructive mode.

## Root Cause 2: Non-Conformant Legacy Tasks
- The `verify_task_meta_schema.sh` strict-mode gate is failing because 5 legacy tasks (`TSK-P2-W6-REM-16b`, `16c`, `17b-beta`, `17c-beta`, `TSK-TEST-001`) are missing mandatory audit fields (`client`, `model`, `assigned_agent`, `acceptance_criteria`, etc.) required by the v1 schema.

## Fix Sequence
1. Restore all 14 Wave 7 `PLAN.md` and `EXEC_LOG.md` files (Already Completed).
2. Patch the 5 failing `meta.yml` files to comply with the v1 strict schema by adding the missing audit and enforcement fields.
3. Clear the DRD lockout.
4. Verify `pre_ci.sh` executes successfully.
