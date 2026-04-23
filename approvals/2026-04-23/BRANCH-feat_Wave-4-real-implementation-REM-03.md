# REM-03 Approval - Fix Idempotency Constraint

## Approval Summary

**Approval ID**: BRANCH-feat_Wave-4-real-implementation-REM-03
**Approval Date**: 2026-04-23
**Approval Status**: STAGE A PENDING
**Regulatory Surface**: DB_SCHEMA (schema/migrations/**)
**Blast Radius**: DATABASE_SCHEMA

## Context

This is a Stage A approval for TSK-P2-PREAUTH-005-REM-03, which fixes the idempotency constraint in the state_transitions table. The current weak constraint `UNIQUE(entity_type, entity_id, execution_id)` allows multiple transitions if execution is reused. This task replaces it with a strong hash-based constraint `UNIQUE(entity_type, entity_id, transition_hash)` as required by Wave-5-for-Devin.md.

## Changes Approved

### Migration File to Modify
- `schema/migrations/0137_create_state_transitions.sql` - Replace UNIQUE constraint

### Specific Change
- **Delete**: `CONSTRAINT unique_entity_execution UNIQUE (entity_type, entity_id, execution_id)`
- **Add**: `CONSTRAINT unique_entity_hash UNIQUE (entity_type, entity_id, transition_hash)`

### MIGRATION_HEAD Update
- Update from 0144 to 0145

## Risk Assessment

**Risk Class**: INTEGRITY
**Current State**: MIGRATION ALREADY APPLIED (0137)
**Verification Status**: MIGRATION VERIFIED IN DATABASE

**Risks**:
- Constraint change may affect existing data if duplicate transition_hash values exist
- MIGRATION_HEAD increment must be tracked carefully

**Mitigation**:
- Database will be checked for duplicate transition_hash values before applying
- Verification script will confirm constraint is correctly applied

## Approval Conditions

This Stage A approval is granted under the following conditions:

1. **Regulated Surface Compliance**: schema/migrations/** is a regulated surface per REGULATED_SURFACE_PATHS.yml
2. **Remediation Trace Compliance**: Task PLAN.md/EXEC_LOG.md pair satisfies remediation trace requirement per REMEDIATION_TRACE_WORKFLOW.md
3. **Verification**: Verification script must pass before merge
4. **Stage B Approval**: Stage B approval required after PR is opened

## Human Approval

**Approver**: human_reviewer
**Approval Rationale**: This constraint change is required by Wave-5-for-Devin.md to ensure proper idempotency. The change is well-understood and has a clear verification path.

## Canonical References

- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/REGULATED_SURFACE_PATHS.yml`
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `docs/operations/approval_metadata.schema.json`
- `docs/plans/phase2/TSK-P2-PREAUTH-005-REM-03/PLAN.md`
