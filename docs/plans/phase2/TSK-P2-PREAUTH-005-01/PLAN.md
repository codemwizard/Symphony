# TSK-P2-PREAUTH-005-01 PLAN — Create state_transitions table

Task: TSK-P2-PREAUTH-005-01
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-00
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-005-01.MIGRATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the state_transitions table to track all state transitions with execution binding. This task enables the system to record state transitions, preventing non-auditable state changes and lost execution context.

## Architectural Context

The state_transitions table stores all state transition events with execution binding. Indexes on project_id and transition_timestamp ensure efficient querying for project state history. This is part of the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-00 PLAN.md exists and passes verification
- Migration 0120 does not exist yet
- MIGRATION_HEAD exists and contains current migration number

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | CREATE | Migration creating state_transitions table |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0120 |
| scripts/db/verify_tsk_p2_preauth_005_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

## Implementation Steps

### Step 1: Write migration 0120
**What:** `[ID tsk_p2_preauth_005_01_work_item_01]` Create migration 0120 at schema/migrations/0120_create_state_transitions.sql
**How:** Write SQL creating state_transitions table with columns: transition_id UUID PRIMARY KEY, project_id UUID NOT NULL, from_state VARCHAR NOT NULL, to_state VARCHAR NOT NULL, transition_timestamp TIMESTAMPTZ NOT NULL, execution_id UUID, policy_decision_id UUID, signature TEXT, and indexes on project_id and transition_timestamp
**Done when:** Migration file exists at specified path with correct table definition

### Step 2: Update MIGRATION_HEAD
**What:** `[ID tsk_p2_preauth_005_01_work_item_02]` Update MIGRATION_HEAD to 0120
**How:** Run: echo 0120 > schema/migrations/MIGRATION_HEAD
**Done when:** MIGRATION_HEAD contains "0120"

### Step 3: Write verification script
**What:** `[ID tsk_p2_preauth_005_01_work_item_03]` Create verify_tsk_p2_preauth_005_01.sh
**How:** Write bash script that runs psql to verify table exists and indexes are present
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_01.sh

### Step 4: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID tsk_p2_preauth_005_01_work_item_04]` Implement the negative test for state_transitions table verification
**How:** Define execution failure test (TSK-P2-PREAUTH-005-01-N1) that simulates missing state_transitions table. Feed bad schema state into the verification logic and ensure it is explicitly rejected.
**Done when:** The verification script exits non-zero against unfixed/dummy schema (missing table), and exits 0 against the target implementation.

### Step 5: Run verification script
**What:** `[ID tsk_p2_preauth_005_01_work_item_05]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_01.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/tsk_p2_preauth_005_01.json

## Verification

```bash
# [ID tsk_p2_preauth_005_01_work_item_01] [ID tsk_p2_preauth_005_01_work_item_02]
# [ID tsk_p2_preauth_005_01_work_item_03] [ID tsk_p2_preauth_005_01_work_item_04] [ID tsk_p2_preauth_005_01_work_item_05]
test -x scripts/db/verify_tsk_p2_preauth_005_01.sh && bash scripts/db/verify_tsk_p2_preauth_005_01.sh > evidence/phase2/tsk_p2_preauth_005_01.json || exit 1

# [ID tsk_p2_preauth_005_01_work_item_02]
test $(cat schema/migrations/MIGRATION_HEAD) = "0120" || exit 1

# [ID tsk_p2_preauth_005_01_work_item_05]
test -f evidence/phase2/tsk_p2_preauth_005_01.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- indexes_present
- migration_head

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0120_create_state_transitions.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Migration syntax error | Low | Medium | Test migration on dev database first |
| Indexes missing | Low | Critical | Review index definitions carefully |

## Approval

This task modifies database schema (HIGHEST RISK area). Requires human review before merge.

## Anti-Drift Cheating Limits

After implementing this task, the following attack surfaces remain open:
- No enforcement that state_transitions table is only populated via triggers (direct INSERT/UPDATE possible until trigger layer is complete)
- No verification that indexes are actually used by query planner (presence check only)
- No protection against migration reapplication without idempotency guards (addressed in subsequent tasks)

These will be addressed in future waves with additional hardening and idempotency guards.
