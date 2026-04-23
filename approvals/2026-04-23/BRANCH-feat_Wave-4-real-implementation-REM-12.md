# REM-12 Approval - Fix Append-Only Error String

## Approval Summary

**Approval ID**: BRANCH-feat_Wave-4-real-implementation-REM-12
**Approval Date**: 2026-04-23
**Approval Status**: STAGE A PENDING
**Regulatory Surface**: DB_SCHEMA (schema/migrations/**)
**Blast Radius**: DATABASE_SCHEMA

## Context

This is a Stage A approval for TSK-P2-PREAUTH-005-REM-12, which fixes the error string in the deny_state_transitions_mutation trigger. The current error messages are specific but do not match the exact "state_transitions is append-only" string required by the verifier script. This task changes the error string to match the exact requirement.

## Changes Approved

### Migration File to Modify
- `schema/migrations/0143_create_deny_state_transitions_mutation.sql` - Change error string to exact "state_transitions is append-only", use CREATE OR REPLACE FUNCTION

### Specific Change
- **Change**: Error messages from specific strings to exact "state_transitions is append-only"
- **Use**: CREATE OR REPLACE FUNCTION for idempotency

### MIGRATION_HEAD Update
- Update from 0150 to 0151

## Risk Assessment

**Risk Class**: INTEGRITY
**Current State**: MIGRATION ALREADY APPLIED (0143)
**Verification Status**: MIGRATION VERIFIED IN DATABASE

**Risks**:
- Error string change may affect downstream consumers
- Verification script may fail if it expects specific error messages

**Mitigation**:
- Verification script will confirm error string matches exactly
- Behavioral negative test will confirm UPDATE/DELETE are rejected with exact error string

## Approval Conditions

This Stage A approval is granted under the following conditions:

1. **Regulated Surface Compliance**: schema/migrations/** is a regulated surface per REGULATED_SURFACE_PATHS.yml
2. **Remediation Trace Compliance**: Task PLAN.md/EXEC_LOG.md pair satisfies remediation trace requirement per REMEDIATION_TRACE_WORKFLOW.md
3. **Verification**: Verification script must pass before merge
4. **Stage B Approval**: Stage B approval required after PR is opened

## Human Approval

**Approver**: human_reviewer
**Approval Rationale**: This error string change is required by Wave-5-for-Devin.md and verifier scripts to ensure proper negative test verification. The change is well-understood and has a clear verification path.

## Canonical References

- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/REGULATED_SURFACE_PATHS.yml`
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `docs/operations/approval_metadata.schema.json`
- `docs/plans/phase2/TSK-P2-PREAUTH-005-REM-12/PLAN.md`
