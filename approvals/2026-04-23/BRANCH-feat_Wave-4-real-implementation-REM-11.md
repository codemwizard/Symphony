# REM-11 Approval - Fix Projection Architecture and Trigger Naming

## Approval Summary

**Approval ID**: BRANCH-feat_Wave-4-real-implementation-REM-11
**Approval Date**: 2026-04-23
**Approval Status**: STAGE A PENDING
**Regulatory Surface**: DB_SCHEMA (schema/migrations/**)
**Blast Radius**: DATABASE_SCHEMA

## Context

This is a Stage A approval for TSK-P2-PREAUTH-005-REM-11, which fixes the projection architecture and trigger naming. The current state_current table has PK as `project_id` which is incorrect per Wave-5-for-Devin.md - it should be `(entity_type, entity_id)` for a generic entity model. Additionally, the trigger name `trg_update_current_state` lacks explicit ordering - it should be `trg_06_update_current`.

## Changes Approved

### Migration Files to Modify
- `schema/migrations/0138_create_state_current.sql` - Change PK from `project_id` to `(entity_type, entity_id)`
- `schema/migrations/0144_create_update_current_state.sql` - Update trigger to use correct PK, rename to `trg_06_update_current`, use DROP TRIGGER IF EXISTS / CREATE TRIGGER

### Specific Changes
- **0138**: Change PRIMARY KEY from `project_id` to `(entity_type, entity_id)`
- **0138**: Add `entity_type` and `entity_id` columns
- **0144**: Update trigger to use `(entity_type, entity_id)` instead of `project_id`
- **0144**: Rename trigger from `trg_update_current_state` to `trg_06_update_current`
- **0144**: Use DROP TRIGGER IF EXISTS / CREATE TRIGGER for idempotency

### MIGRATION_HEAD Update
- Update from 0149 to 0150

## Risk Assessment

**Risk Class**: INTEGRITY
**Current State**: MIGRATIONS ALREADY APPLIED (0138, 0144)
**Verification Status**: MIGRATIONS VERIFIED IN DATABASE

**Risks**:
- PK change may affect existing data if state_current table has data
- Trigger name change may affect dependent code

**Mitigation**:
- Verification script will confirm PK is correctly changed
- Verification script will confirm trigger name is correctly renamed

## Approval Conditions

This Stage A approval is granted under the following conditions:

1. **Regulated Surface Compliance**: schema/migrations/** is a regulated surface per REGULATED_SURFACE_PATHS.yml
2. **Remediation Trace Compliance**: Task PLAN.md/EXEC_LOG.md pair satisfies remediation trace requirement per REMEDIATION_TRACE_WORKFLOW.md
3. **Verification**: Verification script must pass before merge
4. **Stage B Approval**: Stage B approval required after PR is opened

## Human Approval

**Approver**: human_reviewer
**Approval Rationale**: This PK change and trigger naming are required by Wave-5-for-Devin.md to ensure proper generic entity model and explicit trigger ordering. The changes are well-understood and have clear verification paths.

## Canonical References

- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/REGULATED_SURFACE_PATHS.yml`
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `docs/operations/approval_metadata.schema.json`
- `docs/plans/phase2/TSK-P2-PREAUTH-005-REM-11/PLAN.md`
