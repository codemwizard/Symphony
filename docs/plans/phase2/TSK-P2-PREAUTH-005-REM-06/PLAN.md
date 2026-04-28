# TSK-P2-PREAUTH-005-REM-06 PLAN — Change enforce_transition_state_rules to RAISE EXCEPTION

Task: TSK-P2-PREAUTH-005-REM-06
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-REM-03
failure_signature: PRE-PHASE2.WAVE5.REM-06.RAISE_EXCEPTION_STATE_RULES
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Change the enforce_transition_state_rules() trigger function from RAISE NOTICE to RAISE EXCEPTION. This ensures invalid state transitions are actually rejected, not just logged.

## Architectural Context

The Wave-5-for-Devin.md specification requires all enforcement triggers to use RAISE EXCEPTION to block invalid operations. The original migration 0120 implemented enforce_transition_state_rules() with RAISE NOTICE, which only logs violations without blocking them. This is a critical behavioral gap that breaks the state rule enforcement invariant.

## Pre-conditions

- TSK-P2-PREAUTH-005-REM-03 is complete (strong UNIQUE constraint added)
- TSK-P2-PREAUTH-005-03 is complete (enforce_transition_state_rules trigger exists)
- TSK-P2-PREAUTH-005-CLEANUP has completed
- Migration 0139 is applied
- state_rules table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0139_create_enforce_transition_state_rules.sql | MODIFY | Change RAISE NOTICE to RAISE EXCEPTION in enforce_transition_state_rules() |
| scripts/db/verify_tsk_p2_preauth_005_rem_06.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If RAISE NOTICE is not changed to RAISE EXCEPTION** -> STOP
- **If approval metadata is not created before editing migration** -> STOP
- **If behavioral negative test is not implemented** -> STOP

## Implementation Steps

### Step 1: Create Stage A approval artifact
**What:** `[ID rem_06_work_01]` Create approval artifact before editing migration
**How:** Create approvals/YYYY-MM-DD/BRANCH-<branch-name>.md and .approval.json with required fields per approval_metadata.schema.json
**Done when:** Approval artifact passes schema validation

### Step 2: Change RAISE NOTICE to RAISE EXCEPTION
**What:** `[ID rem_06_work_02]` Change enforce_transition_state_rules() from RAISE NOTICE to RAISE EXCEPTION
**How:** Modify migration 0139 to replace RAISE NOTICE with RAISE EXCEPTION in the trigger function
**Done when:** Trigger function uses RAISE EXCEPTION

### Step 3: Write verification script
**What:** `[ID rem_06_work_03]` Create verify_tsk_p2_preauth_005_rem_06.sh
**How:** Write bash script that verifies trigger uses RAISE EXCEPTION using DATABASE_URL
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_rem_06.sh

### Step 4: Write behavioral negative test
**What:** `[ID rem_06_work_04]` Implement behavioral negative test for invalid state transition
**How:** Add test that attempts INSERT with invalid state transition, verifies it fails with RAISE EXCEPTION
**Done when:** Negative test confirms invalid transitions are rejected with exception

### Step 5: Run verification
**What:** `[ID rem_06_work_05]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_rem_06.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/TSK-P2-PREAUTH-005-REM-06.json

### Step 6: Update EXEC_LOG.md with remediation markers
**What:** `[ID rem_06_work_06]` Document remediation in EXEC_LOG.md
**How:** Add entry with failure_signature, origin_task_id, repro_command, verification_commands_run, final_status
**Done when:** EXEC_LOG.md contains all required remediation trace markers

## Verification

```bash
# [ID rem_06_work_02] Check RAISE EXCEPTION in trigger
psql "$DATABASE_URL" -c "SELECT prosrc FROM pg_proc WHERE proname = 'enforce_transition_state_rules'" | grep -q 'RAISE EXCEPTION' || exit 1

# [ID rem_06_work_03] [ID rem_06_work_05] Run verification script
test -x scripts/db/verify_tsk_p2_preauth_005_rem_06.sh && bash scripts/db/verify_tsk_p2_preauth_005_rem_06.sh > evidence/phase2/TSK-P2-PREAUTH-005-REM-06.json || exit 1

# [ID rem_06_work_05] Check evidence file
test -f evidence/phase2/TSK-P2-PREAUTH-005-REM-06.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/TSK-P2-PREAUTH-005-REM-06.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- raise_exception_verified
- behavioral_negative_test_results

## Rollback

Revert migration:
```bash
git checkout schema/migrations/0139_create_enforce_transition_state_rules.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Trigger name change | Low | Medium | Trigger name is explicitly specified in spec |

## Approval

This task modifies database schema (HIGHEST RISK area). Requires human review before merge. Regulated surface compliance per REGULATED_SURFACE_PATHS.yml and REMEDIATION_TRACE_WORKFLOW.md is mandatory.

**Regulated Surface Compliance (CRITICAL):**
- schema/migrations/** is a regulated surface per REGULATED_SURFACE_PATHS.yml
- MUST NOT edit migration files without prior approval metadata
- Approval artifacts MUST be created BEFORE editing regulated surfaces
- Stage A approval artifact: approvals/YYYY-MM-DD/BRANCH-<branch-name>.md and .approval.json
- Must include: regulated_surfaces_touched: true, paths_changed with specific migration files

**Remediation Trace Compliance (CRITICAL):**
- schema/** is a production-affecting surface requiring remediation trace per REMEDIATION_TRACE_WORKFLOW.md
- Task PLAN.md/EXEC_LOG.md pair satisfies remediation trace requirement
- EXEC_LOG.md MUST include all required markers: failure_signature, origin_task_id, repro_command, verification_commands_run, final_status
- EXEC_LOG.md is append-only - never delete or modify existing entries
- Markers must be present when migration file is modified - not deferred to pre_ci

**Execution Safety (CRITICAL):**
- Use CREATE OR REPLACE FUNCTION for idempotency when modifying functions
- Use DROP TRIGGER IF EXISTS / CREATE TRIGGER for idempotency when modifying triggers
- This ensures migrations can be executed repeatedly without errors

## Anti-Drift Cheating Limits

After implementing this task, the following attack surfaces remain open:
- Other triggers still lack JOIN logic (addressed in REM-07 through REM-08)
- No cryptographic verification of transition_hash (addressed in REM-10)
- No generic entity model (addressed in REM-11)

These will be addressed in subsequent remediation tasks.
