# REM-07 Approval - Add Authority Validation Logic

## Approval Summary

**Approval ID**: BRANCH-feat_Wave-4-real-implementation-REM-07
**Approval Date**: 2026-04-23
**Approval Status**: STAGE A PENDING
**Regulatory Surface**: DB_SCHEMA (schema/migrations/**)
**Blast Radius**: DATABASE_SCHEMA

## Context

This is a Stage A approval for TSK-P2-PREAUTH-005-REM-07, which adds authority validation logic to the enforce_transition_authority trigger. The current trigger only checks if policy_decision_id is present but doesn't validate actual authority. This task adds a JOIN to the policy_decisions table to verify that entity type and decision type match.

## Changes Approved

### Migration File to Modify
- `schema/migrations/0140_create_enforce_transition_authority.sql` - Add JOIN logic to policy_decisions table

### Specific Change
- **Replace**: Hollow trigger with actual validation logic
- **Add**: Query to verify entity type and decision type match against policy_decisions table
- **Use**: CREATE OR REPLACE FUNCTION for idempotency

### MIGRATION_HEAD Update
- Update from 0146 to 0147

## Risk Assessment

**Risk Class**: INTEGRITY
**Current State**: MIGRATION ALREADY APPLIED (0140)
**Verification Status**: MIGRATION VERIFIED IN DATABASE

**Risks**:
- JOIN logic may affect performance if policy_decisions table is large
- Validation logic may reject previously allowed transitions

**Mitigation**:
- Verification script will confirm JOIN logic is correctly applied
- Behavioral negative test will confirm invalid authority is rejected

## Approval Conditions

This Stage A approval is granted under the following conditions:

1. **Regulated Surface Compliance**: schema/migrations/** is a regulated surface per REGULATED_SURFACE_PATHS.yml
2. **Remediation Trace Compliance**: Task PLAN.md/EXEC_LOG.md pair satisfies remediation trace requirement per REMEDIATION_TRACE_WORKFLOW.md
3. **Verification**: Verification script must pass before merge
4. **Stage B Approval**: Stage B approval required after PR is opened

## Human Approval

**Approver**: human_reviewer
**Approval Rationale**: This JOIN logic is required by Wave-5-for-Devin.md to ensure proper authority validation. The change adds actual business logic to a hollow stub.

## Canonical References

- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/REGULATED_SURFACE_PATHS.yml`
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `docs/operations/approval_metadata.schema.json`
- `docs/plans/phase2/TSK-P2-PREAUTH-005-REM-07/PLAN.md`
