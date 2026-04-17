# TSK-P2-PREAUTH-006C-03: Add DataAuthority and AuditGrade to AssetBatch and StateTransition read models

**Task:** TSK-P2-PREAUTH-006C-03
**Owner:** ARCHITECT
**Depends on:** TSK-P2-PREAUTH-006C-02
**Blocks:** TSK-P2-PREAUTH-007-00
**Failure Signature**: Properties not added or types incorrect => CRITICAL_FAIL

## Objective

Add DataAuthority and AuditGrade properties to the AssetBatch and StateTransition read models. This task enables the C# layer to track data authority for these entities, preventing non-auditable data usage.

## Architectural Context

The DataAuthority property of type DataAuthorityLevel and AuditGrade property of type bool are added to AssetBatch and StateTransition read models with appropriate defaults.

## Pre-conditions

- TSK-P2-PREAUTH-006C-02 is complete
- DataAuthorityLevel enum exists in C# codebase

## Files to Change

| Path | Type | Change |
|------|------|--------|
| src/Symphony/Models/AssetBatch.cs | MODIFY | Add DataAuthority and AuditGrade properties |
| src/Symphony/Models/StateTransition.cs | MODIFY | Add DataAuthority and AuditGrade properties |
| scripts/audit/verify_tsk_p2_preauth_006c_03.sh | CREATE | Verification script for this task |

## Stop Conditions

- If DataAuthority property is not added to AssetBatch
- If DataAuthority property is not added to StateTransition
- If properties do not have appropriate types

## Implementation Steps

### [ID tsk_p2_preauth_006c_03_work_item_01] Add DataAuthority property to AssetBatch
Add DataAuthority property of type DataAuthorityLevel to AssetBatch read model with default Phase1IndicativeOnly.

### [ID tsk_p2_preauth_006c_03_work_item_02] Add AuditGrade property to AssetBatch
Add AuditGrade property of type bool to AssetBatch read model with default false.

### [ID tsk_p2_preauth_006c_03_work_item_03] Add DataAuthority property to StateTransition
Add DataAuthority property of type DataAuthorityLevel to StateTransition read model with default NonReproducible.

### [ID tsk_p2_preauth_006c_03_work_item_04] Add AuditGrade property to StateTransition
Add AuditGrade property of type bool to StateTransition read model with default false.

### [ID tsk_p2_preauth_006c_03_work_item_05] Write verification script
Write verify_tsk_p2_preauth_006c_03.sh that runs grep to verify properties exist and have correct types.

### [ID tsk_p2_preauth_006c_03_work_item_06] Run verification script
Run verify_tsk_p2_preauth_006c_03.sh to confirm properties are added correctly.

## Verification

```bash
# [ID tsk_p2_preauth_006c_03_work_item_01] [ID tsk_p2_preauth_006c_03_work_item_02]
# [ID tsk_p2_preauth_006c_03_work_item_03] [ID tsk_p2_preauth_006c_03_work_item_04]
# [ID tsk_p2_preauth_006c_03_work_item_05] [ID tsk_p2_preauth_006c_03_work_item_06]
test -x scripts/audit/verify_tsk_p2_preauth_006c_03.sh && bash scripts/audit/verify_tsk_p2_preauth_006c_03.sh > evidence/phase2/tsk_p2_preauth_006c_03.json || exit 1

# [ID tsk_p2_preauth_006c_03_work_item_01]
grep -q "DataAuthority" src/Symphony/Models/AssetBatch.cs || exit 1

# [ID tsk_p2_preauth_006c_03_work_item_03]
grep -q "DataAuthority" src/Symphony/Models/StateTransition.cs || exit 1

# [ID tsk_p2_preauth_006c_03_work_item_06]
test -f evidence/phase2/tsk_p2_preauth_006c_03.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006c_03.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- data_authority_in_asset_batch
- data_authority_in_state_transition

## Rollback

Revert property additions:
```bash
git checkout src/Symphony/Models/AssetBatch.cs
git checkout src/Symphony/Models/StateTransition.cs
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Property types incorrect | Low | Critical | Review property definitions carefully |
| Defaults not set | Low | Medium | Ensure defaults match DB defaults |

## Approval

This task modifies C# code. Requires human review before merge.
