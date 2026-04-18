# TSK-P2-PREAUTH-005-06 PLAN — Implement enforce_execution_binding() trigger

Task: TSK-P2-PREAUTH-005-06
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-05
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-005-06.TRIGGER_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Implement the enforce_execution_binding() trigger function to verify execution_id is present for reproducible transitions. This task prevents non-reproducible state transitions, creating risk of untraceable state changes.

## Architectural Context

The enforce_execution_binding() function verifies execution_id is present for reproducible transitions. It must be SECURITY DEFINER with hardened search_path. This is part of the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-05 is complete
- Migration 0120 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | MODIFY | Add enforce_execution_binding() function |
| scripts/db/verify_tsk_p2_preauth_005_06.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

## Implementation Steps

### Step 1: Add enforce_execution_binding() function to migration 0120
**What:** `[ID tsk_p2_preauth_005_06_work_item_01]` Add enforce_execution_binding() function to migration 0120
**How:** Modify schema/migrations/0120_create_state_transitions.sql to add function as SECURITY DEFINER with SET search_path = pg_catalog, public. Function verifies execution_id is present for reproducible transitions and raises GF035 if missing
**Done when:** Migration file contains enforce_execution_binding() function definition

### Step 2: Attach function as BEFORE INSERT OR UPDATE trigger on state_transitions
**What:** `[ID tsk_p2_preauth_005_06_work_item_02]` Attach function as trigger
**How:** Add CREATE TRIGGER statement to attach function as BEFORE INSERT OR UPDATE on state_transitions table
**Done when:** Migration file contains trigger attachment statement

### Step 3: Write verification script
**What:** `[ID tsk_p2_preauth_005_06_work_item_03]` Create verify_tsk_p2_preauth_005_06.sh
**How:** Write bash script that runs psql to verify function exists with exact name, is SECURITY DEFINER, and trigger is attached
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_06.sh

### Step 4: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID tsk_p2_preauth_005_06_work_item_04]` Implement the negative test for enforce_execution_binding() trigger
**How:** Define execution failure test (TSK-P2-PREAUTH-005-06-N1) that simulates missing function or incorrect SECURITY DEFINER setting. Feed bad schema state into the verification logic and ensure it is explicitly rejected.
**Done when:** The verification script exits non-zero against unfixed/dummy schema (missing function or wrong security), and exits 0 against the target implementation.

### Step 5: Run verification script
**What:** `[ID tsk_p2_preauth_005_06_work_item_05]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_06.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/tsk_p2_preauth_005_06.json

## Verification

```bash
# [ID tsk_p2_preauth_005_06_work_item_01] [ID tsk_p2_preauth_005_06_work_item_02]
# [ID tsk_p2_preauth_005_06_work_item_03] [ID tsk_p2_preauth_005_06_work_item_04] [ID tsk_p2_preauth_005_06_work_item_05]
test -x scripts/db/verify_tsk_p2_preauth_005_06.sh && bash scripts/db/verify_tsk_p2_preauth_005_06.sh > evidence/phase2/tsk_p2_preauth_005_06.json || exit 1

# [ID tsk_p2_preauth_005_06_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_execution_binding'" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_005_06_work_item_05]
test -f evidence/phase2/tsk_p2_preauth_005_06.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_06.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- function_exists
- security_definer_present
- trigger_attached

## Rollback

Revert function addition from migration 0120:
```bash
git checkout schema/migrations/0120_create_state_transitions.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Function not SECURITY DEFINER | Low | Critical | Hardening required for security |
| Search path not hardened | Low | Critical | Use SET search_path = pg_catalog, public |

## Approval

This task modifies database schema with SECURITY DEFINER trigger (HIGHEST RISK area). Requires human review before merge.

## Anti-Drift Cheating Limits

After implementing this task, the following attack surfaces remain open:
- No verification that execution_id values actually reference valid execution records (presence check only)
- No protection against trigger being disabled or dropped after deployment
- No verification that trigger ordering is correct relative to other triggers

These will be addressed in future waves with execution record validation and runtime guards.
