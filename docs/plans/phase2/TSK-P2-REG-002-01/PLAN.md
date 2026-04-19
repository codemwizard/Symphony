# TSK-P2-REG-002-01: Create exchange_rate_audit_log table

Task: TSK-P2-REG-002-01
Owner: DB_FOUNDATION
Depends on: TSK-P2-REG-002-00
failure_signature: PRE-PHASE2.REG.TSK-P2-REG-002-01.TABLE_OR_PRECISION_INCORRECT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the exchange_rate_audit_log table with high-precision rate tracking for financial audit compliance.

## Architectural Context

The exchange_rate_audit_log table stores exchange rates with NUMERIC(18,8) precision to ensure accurate financial calculations and audit trail.

## Pre-conditions

- TSK-P2-REG-002-00 PLAN.md exists and passes verification
- MIGRATION_HEAD is at previous migration

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0124_create_exchange_rate_audit_log.sql | CREATE | Migration creating exchange_rate_audit_log table |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0124 |
| scripts/db/verify_tsk_p2_reg_002_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- If exchange_rate_audit_log table does not exist
- If rate_value column is not NUMERIC(18,8)
- If MIGRATION_HEAD is not updated to 0124

## Implementation Steps

### [ID tsk_p2_reg_002_01_work_item_01] Write migration 0124
Write migration 0124 at schema/migrations/0124_create_exchange_rate_audit_log.sql creating exchange_rate_audit_log table with columns: audit_id UUID PRIMARY KEY, from_currency VARCHAR NOT NULL, to_currency VARCHAR NOT NULL, rate_value NUMERIC(18,8) NOT NULL, effective_from TIMESTAMPTZ NOT NULL, and UNIQUE constraint on (from_currency, to_currency, effective_from).

### [ID tsk_p2_reg_002_01_work_item_02] Update MIGRATION_HEAD
Update MIGRATION_HEAD to 0124: echo 0124 > schema/migrations/MIGRATION_HEAD.

### [ID tsk_p2_reg_002_01_work_item_03] Write verification script
Write verify_tsk_p2_reg_002_01.sh that runs psql to verify table exists and rate_value is NUMERIC(18,8).

### [ID tsk_p2_reg_002_01_work_item_04] Run verification script
Run verify_tsk_p2_reg_002_01.sh to confirm migration is successful.

### [ID tsk_p2_reg_002_01_work_item_05] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_002_01_work_item_01] [ID tsk_p2_reg_002_01_work_item_02]
# [ID tsk_p2_reg_002_01_work_item_03] [ID tsk_p2_reg_002_01_work_item_04]
test -x scripts/db/verify_tsk_p2_reg_002_01.sh && bash scripts/db/verify_tsk_p2_reg_002_01.sh > evidence/phase2/tsk_p2_reg_002_01.json || exit 1

# [ID tsk_p2_reg_002_01_work_item_01]
test -f schema/migrations/0124_create_exchange_rate_audit_log.sql || exit 1

# [ID tsk_p2_reg_002_01_work_item_02]
test "$(cat schema/migrations/MIGRATION_HEAD)" = "0124" || exit 1

# [ID tsk_p2_reg_002_01_work_item_04]
test -f evidence/phase2/tsk_p2_reg_002_01.json || exit 1

# [ID tsk_p2_reg_002_01_work_item_05]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_002_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- precision_correct
- migration_head
- observed_paths

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0124_create_exchange_rate_audit_log.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration syntax error | Low | Critical | Test migration on dev database first |
| Precision incorrect | Low | High | Review NUMERIC(18,8) definition carefully |

## Approval

This task modifies schema. Requires human review before merge.
