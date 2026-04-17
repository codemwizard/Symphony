# TSK-P2-PREAUTH-006C-02: Add DataAuthority and AuditGrade to MonitoringRecord read model

**Task:** TSK-P2-PREAUTH-006C-02
**Owner:** ARCHITECT
**Depends on:** TSK-P2-PREAUTH-006C-01
**Blocks:** TSK-P2-PREAUTH-006C-03
**Failure Signature**: Properties not added or types incorrect => CRITICAL_FAIL

## Objective

Add DataAuthority and AuditGrade properties to the MonitoringRecord read model. This task enables the C# layer to track data authority for monitoring records, preventing non-auditable data usage.

## Architectural Context

The DataAuthority property of type DataAuthorityLevel and AuditGrade property of type bool are added to MonitoringRecord read model with appropriate defaults.

## Pre-conditions

- TSK-P2-PREAUTH-006C-01 is complete
- DataAuthorityLevel enum exists in C# codebase

## Files to Change

| Path | Type | Change |
|------|------|--------|
| src/Symphony/Models/MonitoringRecord.cs | MODIFY | Add DataAuthority and AuditGrade properties |
| scripts/audit/verify_tsk_p2_preauth_006c_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If DataAuthority property is not added to MonitoringRecord
- If AuditGrade property is not added to MonitoringRecord
- If properties do not have appropriate types

## Implementation Steps

### [ID tsk_p2_preauth_006c_02_work_item_01] Add DataAuthority property to MonitoringRecord
Add DataAuthority property of type DataAuthorityLevel to MonitoringRecord read model with default Phase1IndicativeOnly.

### [ID tsk_p2_preauth_006c_02_work_item_02] Add AuditGrade property to MonitoringRecord
Add AuditGrade property of type bool to MonitoringRecord read model with default false.

### [ID tsk_p2_preauth_006c_02_work_item_03] Write verification script
Write verify_tsk_p2_preauth_006c_02.sh that runs grep to verify properties exist and have correct types.

### [ID tsk_p2_preauth_006c_02_work_item_04] Run verification script
Run verify_tsk_p2_preauth_006c_02.sh to confirm properties are added correctly.

## Verification

```bash
# [ID tsk_p2_preauth_006c_02_work_item_01] [ID tsk_p2_preauth_006c_02_work_item_02]
# [ID tsk_p2_preauth_006c_02_work_item_03] [ID tsk_p2_preauth_006c_02_work_item_04]
test -x scripts/audit/verify_tsk_p2_preauth_006c_02.sh && bash scripts/audit/verify_tsk_p2_preauth_006c_02.sh > evidence/phase2/tsk_p2_preauth_006c_02.json || exit 1

# [ID tsk_p2_preauth_006c_02_work_item_01]
grep -q "DataAuthority" src/Symphony/Models/MonitoringRecord.cs || exit 1
grep -q "DataAuthorityLevel" src/Symphony/Models/MonitoringRecord.cs || exit 1

# [ID tsk_p2_preauth_006c_02_work_item_02]
grep -q "AuditGrade" src/Symphony/Models/MonitoringRecord.cs || exit 1
grep -q "bool" src/Symphony/Models/MonitoringRecord.cs || exit 1

# [ID tsk_p2_preauth_006c_02_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_006c_02.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006c_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- data_authority_property_exists
- audit_grade_property_exists

## Rollback

Revert property additions:
```bash
git checkout src/Symphony/Models/MonitoringRecord.cs
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Property types incorrect | Low | Critical | Review property definitions carefully |
| Defaults not set | Low | Medium | Ensure defaults match DB defaults |

## Approval

This task modifies C# code. Requires human review before merge.
