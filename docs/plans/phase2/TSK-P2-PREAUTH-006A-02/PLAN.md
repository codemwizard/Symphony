# TSK-P2-PREAUTH-006A-02: Add data_authority columns to monitoring_records

**Task:** TSK-P2-PREAUTH-006A-02
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-006A-01
**Blocks:** TSK-P2-PREAUTH-006A-03
**Failure Signature**: Columns not added or defaults not applied => CRITICAL_FAIL

## Objective

Add data_authority, audit_grade, and authority_explanation columns to monitoring_records table. This task enables the system to track data authority for monitoring records, preventing non-auditable data usage.

## Architectural Context

The data_authority, audit_grade, and authority_explanation columns are added to monitoring_records with default 'phase1_indicative_only' for data_authority. This provides canonical data authority tracking for Phase 1 data.

## Pre-conditions

- TSK-P2-PREAUTH-006A-01 is complete
- Migration 0121 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0121_create_data_authority_enum.sql | MODIFY | Add columns to monitoring_records |
| scripts/db/verify_tsk_p2_preauth_006a_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If migration does not add data_authority column
- If audit_grade column is missing
- If authority_explanation column is missing

## Implementation Steps

### [ID tsk_p2_preauth_006a_02_work_item_01] Add columns to migration 0121
Add columns to migration 0121: ALTER TABLE monitoring_records ADD COLUMN data_authority public.data_authority_level NOT NULL DEFAULT 'phase1_indicative_only', ADD COLUMN audit_grade BOOLEAN NOT NULL DEFAULT false, ADD COLUMN authority_explanation TEXT NOT NULL DEFAULT 'Phase 1 data - no execution binding'.

### [ID tsk_p2_preauth_006a_02_work_item_02] Update existing data
Update existing data: UPDATE monitoring_records SET data_authority='phase1_indicative_only' WHERE data_authority IS DISTINCT FROM 'phase1_indicative_only'.

### [ID tsk_p2_preauth_006a_02_work_item_03] Write verification script
Write verify_tsk_p2_preauth_006a_02.sh that runs psql to verify columns exist and have appropriate defaults.

### [ID tsk_p2_preauth_006a_02_work_item_04] Run verification script
Run verify_tsk_p2_preauth_006a_02.sh to confirm migration is successful.

## Verification

```bash
# [ID tsk_p2_preauth_006a_02_work_item_01] [ID tsk_p2_preauth_006a_02_work_item_02]
# [ID tsk_p2_preauth_006a_02_work_item_03] [ID tsk_p2_preauth_006a_02_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_006a_02.sh && bash scripts/db/verify_tsk_p2_preauth_006a_02.sh > evidence/phase2/tsk_p2_preauth_006a_02.json || exit 1

# [ID tsk_p2_preauth_006a_02_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_006a_02.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006a_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- columns_exist
- defaults_applied

## Rollback

Revert column addition from migration 0121:
```bash
git checkout schema/migrations/0121_create_data_authority_enum.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Column types incorrect | Low | Medium | Review column definitions carefully |
| Defaults not applied to existing data | Low | High | Ensure UPDATE statement runs |

## Approval

This task modifies database schema. Requires human review before merge.
