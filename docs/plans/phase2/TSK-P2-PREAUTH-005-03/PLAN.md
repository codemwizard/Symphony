# TSK-P2-PREAUTH-005-03 PLAN — Implement enforce_transition_state_rules() trigger

Task: TSK-P2-PREAUTH-005-03
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-02
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-005-03.TRIGGER_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Implement the enforce_transition_state_rules() trigger function to check state_rules table before allowing state transitions. This task prevents invalid state transitions, creating risk of state machine violations.

## Architectural Context

The enforce_transition_state_rules() function checks the state_rules table for valid (from_state, to_state) pairs before allowing state transitions. It must be SECURITY DEFINER with hardened search_path. This is part of the HIGHEST RISK area.

## Pre-conditions

- TSK-P2-PREAUTH-005-02 is complete
- state_transitions and state_rules tables exist
- Migration 0120 exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | MODIFY | Add enforce_transition_state_rules() function |
| scripts/db/verify_tsk_p2_preauth_005_03.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

## Implementation Steps

### Step 1: Add enforce_transition_state_rules() function to migration 0120
**What:** `[ID tsk_p2_preauth_005_03_work_item_01]` Add enforce_transition_state_rules() function to migration 0120
**How:** Modify schema/migrations/0120_create_state_transitions.sql to add function as SECURITY DEFINER with SET search_path = pg_catalog, public. Function checks state_rules table for valid (from_state, to_state) pair and raises GF032 if rule not found or condition not met
**Done when:** Migration file contains enforce_transition_state_rules() function definition

### Step 2: Attach function as BEFORE INSERT OR UPDATE trigger on state_transitions
**What:** `[ID tsk_p2_preauth_005_03_work_item_02]` Attach function as trigger
**How:** Add CREATE TRIGGER statement to attach function as BEFORE INSERT OR UPDATE on state_transitions table
**Done when:** Migration file contains trigger attachment statement

### Step 3: Write verification script
**What:** `[ID tsk_p2_preauth_005_03_work_item_03]` Create verify_tsk_p2_preauth_005_03.sh
**How:** Write bash script that runs psql to verify function exists with exact name, is SECURITY DEFINER, and trigger is attached
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_03.sh

### Step 4: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID tsk_p2_preauth_005_03_work_item_04]` Implement the negative test for enforce_transition_state_rules() trigger
**How:** Define execution failure test (TSK-P2-PREAUTH-005-03-N1) that simulates missing function or incorrect SECURITY DEFINER setting. Feed bad schema state into the verification logic and ensure it is explicitly rejected.
**Done when:** The verification script exits non-zero against unfixed/dummy schema (missing function or wrong security), and exits 0 against the target implementation.

### Step 5: Run verification script
**What:** `[ID tsk_p2_preauth_005_03_work_item_05]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_03.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/tsk_p2_preauth_005_03.json

## Verification

```bash
# [ID tsk_p2_preauth_005_03_work_item_01] [ID tsk_p2_preauth_005_03_work_item_02]
# [ID tsk_p2_preauth_005_03_work_item_03] [ID tsk_p2_preauth_005_03_work_item_04] [ID tsk_p2_preauth_005_03_work_item_05]
test -x scripts/db/verify_tsk_p2_preauth_005_03.sh && bash scripts/db/verify_tsk_p2_preauth_005_03.sh > evidence/phase2/tsk_p2_preauth_005_03.json || exit 1

# [ID tsk_p2_preauth_005_03_work_item_01]
psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_transition_state_rules'" | grep -q '1 row' || exit 1

# [ID tsk_p2_preauth_005_03_work_item_05]
test -f evidence/phase2/tsk_p2_preauth_005_03.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_03.json with must_include fields:
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
- No verification that state_rules table is actually populated with valid rules (trigger checks table but doesn't validate data)
- No protection against trigger being disabled or dropped after deployment
- No verification that trigger actually fires on INSERT/UPDATE (presence check only)

These will be addressed in future waves with additional hardening and runtime guards.
