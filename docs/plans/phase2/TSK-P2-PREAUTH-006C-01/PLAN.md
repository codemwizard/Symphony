# TSK-P2-PREAUTH-006C-01: Add DataAuthorityLevel enum to C# codebase

**Task:** TSK-P2-PREAUTH-006C-01
**Owner:** ARCHITECT
**Depends on:** TSK-P2-PREAUTH-006C-00
**Blocks:** TSK-P2-PREAUTH-006C-02
**Failure Signature**: Enum not created or values missing => CRITICAL_FAIL

## Objective

Add the DataAuthorityLevel enum to the C# codebase with values matching the DB ENUM. This task enables the C# layer to represent data authority levels, preventing type mismatches between DB and application layer.

## Architectural Context

The DataAuthorityLevel enum stores 7 authority levels matching the DB ENUM. This provides a canonical reference for data authority in the C# layer.

## Pre-conditions

- TSK-P2-PREAUTH-006C-00 PLAN.md exists and passes verification
- Data authority_level ENUM exists in database

## Files to Change

| Path | Type | Change |
|------|------|--------|
| src/Symphony/Core/DataAuthorityLevel.cs | CREATE | DataAuthorityLevel enum file |
| scripts/audit/verify_tsk_p2_preauth_006c_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- If DataAuthorityLevel enum does not exist in C# codebase
- If enum values do not match DB ENUM values
- If enum is not in correct namespace

## Implementation Steps

### [ID tsk_p2_preauth_006c_01_work_item_01] Create DataAuthorityLevel enum
Create DataAuthorityLevel enum at src/Symphony/Core/DataAuthorityLevel.cs with values: Phase1IndicativeOnly, NonReproducible, DerivedUnverified, PolicyBoundUnsigned, AuthoritativeSigned, Superseded, Invalidated.

### [ID tsk_p2_preauth_006c_01_work_item_02] Write verification script
Write verify_tsk_p2_preauth_006c_01.sh that runs grep to verify enum exists and contains all 7 values.

### [ID tsk_p2_preauth_006c_01_work_item_03] Run verification script
Run verify_tsk_p2_preauth_006c_01.sh to confirm enum is created correctly.

## Verification

```bash
# [ID tsk_p2_preauth_006c_01_work_item_01] [ID tsk_p2_preauth_006c_01_work_item_02]
# [ID tsk_p2_preauth_006c_01_work_item_03]
test -x scripts/audit/verify_tsk_p2_preauth_006c_01.sh && bash scripts/audit/verify_tsk_p2_preauth_006c_01.sh > evidence/phase2/tsk_p2_preauth_006c_01.json || exit 1

# [ID tsk_p2_preauth_006c_01_work_item_01]
test -f src/Symphony/Core/DataAuthorityLevel.cs || exit 1
grep -q "Phase1IndicativeOnly" src/Symphony/Core/DataAuthorityLevel.cs || exit 1
grep -q "AuthoritativeSigned" src/Symphony/Core/DataAuthorityLevel.cs || exit 1

# [ID tsk_p2_preauth_006c_01_work_item_03]
test -f evidence/phase2/tsk_p2_preauth_006c_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006c_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- enum_exists
- enum_values_present

## Rollback

Delete enum file:
```bash
rm src/Symphony/Core/DataAuthorityLevel.cs
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Enum values do not match DB | Low | Critical | Review DB ENUM values carefully |
| Naming convention incorrect | Low | Medium | Use PascalCase for C# enum values |

## Approval

This task adds C# code. Requires human review before merge.
