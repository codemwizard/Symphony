# TSK-P2-REG-002-02: Add append-only trigger and privileges to exchange_rate_audit_log

**Task:** TSK-P2-REG-002-02
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-REG-002-01
**Blocks: []
**Failure Signature**: Trigger missing or privileges incorrect => CRITICAL_FAIL

## Objective

Add append-only trigger and revoke-first privileges to exchange_rate_audit_log table to ensure data immutability and proper access control.

## Architectural Context

Append-only trigger raises GF051 on any UPDATE or DELETE attempt on exchange_rate_audit_log table. Revoke-first privileges grant SELECT to symphony_command and ALL to symphony_control after REVOKE ALL FROM PUBLIC.

## Pre-conditions

- TSK-P2-REG-002-01 is complete
- exchange_rate_audit_log table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0124_create_exchange_rate_audit_log.sql | MODIFY | Add trigger and privileges |
| scripts/db/verify_tsk_p2_reg_002_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If append-only trigger is not attached to exchange_rate_audit_log
- If trigger does not raise GF051 on UPDATE or DELETE
- If privileges are not revoke-first

## Implementation Steps

### [ID tsk_p2_reg_002_02_work_item_01] Add append-only trigger to migration 0124
Add trigger function to migration 0124 that raises GF051 on any UPDATE or DELETE attempt on exchange_rate_audit_log table.

### [ID tsk_p2_reg_002_02_work_item_02] Attach trigger as BEFORE UPDATE OR DELETE
Attach trigger as BEFORE UPDATE OR DELETE trigger on exchange_rate_audit_log table.

### [ID tsk_p2_reg_002_02_work_item_03] Add revoke-first privileges
Add GRANT SELECT ON exchange_rate_audit_log TO symphony_command and GRANT ALL ON exchange_rate_audit_log TO symphony_control after REVOKE ALL FROM PUBLIC.

### [ID tsk_p2_reg_002_02_work_item_04] Write verification script
Write verify_tsk_p2_reg_002_02.sh that runs psql to verify trigger exists and privileges are correct.

### [ID tsk_p2_reg_002_02_work_item_05] Run verification script
Run verify_tsk_p2_reg_002_02.sh to confirm changes are successful.

### [ID tsk_p2_reg_002_02_work_item_06] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_002_02_work_item_01] [ID tsk_p2_reg_002_02_work_item_02]
# [ID tsk_p2_reg_002_02_work_item_03] [ID tsk_p2_reg_002_02_work_item_04]
# [ID tsk_p2_reg_002_02_work_item_05]
test -x scripts/db/verify_tsk_p2_reg_002_02.sh && bash scripts/db/verify_tsk_p2_reg_002_02.sh > evidence/phase2/tsk_p2_reg_002_02.json || exit 1

# [ID tsk_p2_reg_002_02_work_item_05]
test -f evidence/phase2/tsk_p2_reg_002_02.json || exit 1

# [ID tsk_p2_reg_002_02_work_item_06]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_002_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- trigger_exists
- privileges_correct
- observed_paths

## Rollback

Revert trigger and privileges:
```bash
git checkout schema/migrations/0124_create_exchange_rate_audit_log.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Trigger not SECURITY DEFINER | Low | Critical | Hardening required per AGENTS.md |
| Privileges not revoke-first | Low | High | Follow revoke-first privilege posture |

## Approval

This task modifies schema. Requires human review before merge.
