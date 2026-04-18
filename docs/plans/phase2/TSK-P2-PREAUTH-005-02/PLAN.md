# TSK-P2-PREAUTH-005-02 PLAN — Create state_current table

Task: TSK-P2-PREAUTH-005-02
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-01
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-005-02.TABLE_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the state_current table to track current state for each project. This task enables the system to efficiently query current state, preventing performance degradation and incorrect state queries.

## Architectural Context

The state_current table stores the current state for each project. project_id is PRIMARY KEY ensuring one row per project. This is part of the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-01 is complete
- Migration 0120 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | MODIFY | Add state_current table |
| scripts/db/verify_tsk_p2_preauth_005_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

## Implementation Steps

### Step 1: Add state_current table to migration 0120
**What:** `[ID tsk_p2_preauth_005_02_work_item_01]` Add state_current table to migration 0120
**How:** Modify schema/migrations/0120_create_state_transitions.sql to add state_current table with columns: project_id UUID PRIMARY KEY, current_state VARCHAR NOT NULL, state_since TIMESTAMPTZ NOT NULL
**Done when:** Migration file contains state_current table definition

### Step 2: Write verification script
**What:** `[ID tsk_p2_preauth_005_02_work_item_02]` Create verify_tsk_p2_preauth_005_02.sh
**How:** Write bash script that runs psql to verify table exists and project_id is PRIMARY KEY
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_02.sh

### Step 3: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID tsk_p2_preauth_005_02_work_item_03]` Implement the negative test for state_current table verification
**How:** Define execution failure test (TSK-P2-PREAUTH-005-02-N1) that simulates missing state_current table or incorrect PRIMARY KEY. Feed bad schema state into the verification logic and ensure it is explicitly rejected.
**Done when:** The verification script exits non-zero against unfixed/dummy schema (missing table or wrong PK), and exits 0 against the target implementation.

### Step 4: Run verification script
**What:** `[ID tsk_p2_preauth_005_02_work_item_04]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_02.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/tsk_p2_preauth_005_02.json

## Verification

```bash
# [ID tsk_p2_preauth_005_02_work_item_01] [ID tsk_p2_preauth_005_02_work_item_02]
# [ID tsk_p2_preauth_005_02_work_item_03] [ID tsk_p2_preauth_005_02_work_item_04]
test -x scripts/db/verify_tsk_p2_preauth_005_02.sh && bash scripts/db/verify_tsk_p2_preauth_005_02.sh > evidence/phase2/tsk_p2_preauth_005_02.json || exit 1

# [ID tsk_p2_preauth_005_02_work_item_04]
test -f evidence/phase2/tsk_p2_preauth_005_02.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- primary_key_present

## Rollback

Revert state_current table addition from migration 0120:
```bash
git checkout schema/migrations/0120_create_state_transitions.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PRIMARY KEY incorrect | Low | Critical | Review PK definition carefully |
| state_since type incorrect | Low | Medium | Use TIMESTAMPTZ for timezone awareness |

## Approval

This task modifies database schema (HIGHEST RISK area). Requires human review before merge.

## Anti-Drift Cheating Limits

After implementing this task, the following attack surfaces remain open:
- No enforcement that state_current table is only updated via trigger (direct INSERT/UPDATE possible until trigger layer is complete)
- No verification that PRIMARY KEY constraint is actually enforced (presence check only)
- No protection against state_current table becoming inconsistent with state_transitions

These will be addressed by the trigger layer tasks (005-03 through 005-08).
