# TSK-P2-PREAUTH-006A-01: Create data_authority_level ENUM type

**Task:** TSK-P2-PREAUTH-006A-01
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-006A-00
**Blocks:** TSK-P2-PREAUTH-006A-02
**Failure Signature**: Migration fails or ENUM values missing => CRITICAL_FAIL

## Objective

Create the data_authority_level ENUM type to track data authority levels across the system. This task enables the system to enforce data authority constraints, preventing non-auditable data usage.

## Architectural Context

The data_authority_level ENUM type stores 7 authority levels: phase1_indicative_only, non_reproducible, derived_unverified, policy_bound_unsigned, authoritative_signed, superseded, invalidated. This provides a canonical reference for data authority across the system.

## Pre-conditions

- TSK-P2-PREAUTH-006A-00 PLAN.md exists and passes verification
- Migration 0121 does not exist yet
- MIGRATION_HEAD exists and contains current migration number

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0121_create_data_authority_enum.sql | CREATE | Migration creating data_authority_level ENUM |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0121 |
| scripts/db/verify_tsk_p2_preauth_006a_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration 0121 does not create data_authority_level ENUM
- If ENUM values are missing or incorrect
- If MIGRATION_HEAD is not updated to 0121

## Implementation Steps

### [ID tsk_p2_preauth_006a_01_work_item_01] Write migration 0121
Write migration 0121 at schema/migrations/0121_create_data_authority_enum.sql creating data_authority_level ENUM type with values: 'phase1_indicative_only', 'non_reproducible', 'derived_unverified', 'policy_bound_unsigned', 'authoritative_signed', 'superseded', 'invalidated'.

### [ID tsk_p2_preauth_006a_01_work_item_02] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0121: echo 0121 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_preauth_006a_01_work_item_03] Write verification script
Write verify_tsk_p2_preauth_006a_01.sh that runs psql to verify ENUM type exists and contains all 7 values.

### [ID tsk_p2_preauth_006a_01_work_item_04] Run verification script
Run verify_tsk_p2_preauth_006a_01.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_006a_01_work_item_01] [ID tsk_p2_preauth_006a_01_work_item_02]
# [ID tsk_p2_preauth_006a_01_work_item_03] [ID tsk_p2_preauth_006a_01_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_006a_01.sh && bash scripts/db/verify_tsk_p2_preauth_006a_01.sh > evidence/phase2/tsk_p2_preauth_006a_01.json || exit 1

# [ID tsk_p2_preauth_006a_01_work_item_02]
test $(cat schema/migrations/MIGRATION_HEAD) = "0121" || exit 1

# [ID tsk_p2_preauth_006a_01_work_item_01]
psql -c "SELECT enumlabel FROM pg_enum WHERE enumtypid='data_authority_level'::regtype" | grep -c 'phase1_indicative_only' || exit 1

# [ID tsk_p2_preauth_006a_01_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_006a_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006a_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- enum_exists
- enum_values_present
- migration_head

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0121_create_data_authority_enum.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration syntax error | Low | Medium | Test migration on dev database first |
| ENUM values missing | Low | Critical | Review ENUM values carefully |

## Approval

This task modifies database schema. Requires human review before merge.
