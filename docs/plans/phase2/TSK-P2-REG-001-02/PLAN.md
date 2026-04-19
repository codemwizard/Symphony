# TSK-P2-REG-001-02: Add append-only trigger and privileges to statutory_levy_registry

Task: TSK-P2-REG-001-02
Owner: DB_FOUNDATION
Depends on: TSK-P2-REG-001-01
failure_signature: PRE-PHASE2.REG.TSK-P2-REG-001-02.TRIGGER_OR_PRIVILEGES_INCORRECT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Add append-only trigger and revoke-first privileges to statutory_levy_registry table to ensure data immutability and proper access control.

## Architectural Context

Append-only trigger raises GF050 on any UPDATE or DELETE attempt on statutory_levy_registry table. Revoke-first privileges grant SELECT to symphony_command and ALL to symphony_control after REVOKE ALL FROM PUBLIC.

## Pre-conditions

- TSK-P2-REG-001-01 is complete
- statutory_levy_registry table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0123_create_statutory_levy_registry.sql | MODIFY | Add trigger and privileges |
| scripts/db/verify_tsk_p2_reg_001_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- If append-only trigger is not attached to statutory_levy_registry
- If trigger does not raise GF050 on UPDATE or DELETE
- If privileges are not revoke-first

## Implementation Steps

### [ID tsk_p2_reg_001_02_work_item_01] Add append-only trigger to migration 0123
Add trigger function to migration 0123 that raises GF050 on any UPDATE or DELETE attempt on statutory_levy_registry table.

### [ID tsk_p2_reg_001_02_work_item_02] Attach trigger as BEFORE UPDATE OR DELETE
Attach trigger as BEFORE UPDATE OR DELETE trigger on statutory_levy_registry table.

### [ID tsk_p2_reg_001_02_work_item_03] Add revoke-first privileges
Add GRANT SELECT ON statutory_levy_registry TO symphony_command and GRANT ALL ON statutory_levy_registry TO symphony_control after REVOKE ALL FROM PUBLIC.

### [ID tsk_p2_reg_001_02_work_item_04] Write verification script
Write verify_tsk_p2_reg_001_02.sh that runs psql to verify trigger exists and privileges are correct.

### [ID tsk_p2_reg_001_02_work_item_05] Run verification script
Run verify_tsk_p2_reg_001_02.sh to confirm changes are successful.

### [ID tsk_p2_reg_001_02_work_item_06] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_001_02_work_item_01] [ID tsk_p2_reg_001_02_work_item_02]
# [ID tsk_p2_reg_001_02_work_item_03] [ID tsk_p2_reg_001_02_work_item_04]
# [ID tsk_p2_reg_001_02_work_item_05]
test -x scripts/db/verify_tsk_p2_reg_001_02.sh && bash scripts/db/verify_tsk_p2_reg_001_02.sh > evidence/phase2/tsk_p2_reg_001_02.json || exit 1

# [ID tsk_p2_reg_001_02_work_item_05]
test -f evidence/phase2/tsk_p2_reg_001_02.json || exit 1

# [ID tsk_p2_reg_001_02_work_item_06]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_001_02.json with must_include fields:
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
git checkout schema/migrations/0123_create_statutory_levy_registry.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Trigger not SECURITY DEFINER | Low | Critical | Hardening required per AGENTS.md |
| Privileges not revoke-first | Low | High | Follow revoke-first privilege posture |

## Approval

This task modifies schema. Requires human review before merge.
