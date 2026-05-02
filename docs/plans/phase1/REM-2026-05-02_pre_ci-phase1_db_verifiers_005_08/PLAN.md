# REMEDIATION PLAN

failure_signature: PRECI.DB.ENVIRONMENT
root_cause: The behavioral test in verify_tsk_p2_preauth_005_08.sh inserts into execution_records without the entity_type and entity_id columns, which became NOT NULL after migrations 0199 (expand) and 0201 (constrain) from TSK-P2-W5-REM-01. The test INSERT was never updated to include these columns.

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: SKIP_DOTNET_QUALITY_LINT=1 bash scripts/dev/pre_ci.sh
final_status: PENDING

## Scope
- Update the behavioral test INSERT in scripts/db/verify_tsk_p2_preauth_005_08.sh to include entity_type and entity_id.
- Address baseline drift from migration 0199-0202 additions.
- No changes to pre_ci.sh or any other regulated surface.

## Root Cause Detail
Migration 0199 added nullable entity_type (TEXT) and entity_id (UUID) columns to execution_records.
Migration 0201 enforced NOT NULL on both columns.
The behavioral test in verify_tsk_p2_preauth_005_08.sh (line 46-47) inserts a test row without these columns, triggering:
  ERROR: null value in column "entity_type" of relation "execution_records" violates not-null constraint

## Fix
Add entity_type and entity_id to the INSERT statement on line 46-47 of verify_tsk_p2_preauth_005_08.sh.
The test already declares v_entity UUID (line 34), which can be reused for entity_id.
entity_type will use 'TEST_ENTITY' to match the test's existing entity_type usage in state_transitions.
