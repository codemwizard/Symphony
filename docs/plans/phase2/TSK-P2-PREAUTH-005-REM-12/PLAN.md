# TSK-P2-PREAUTH-005-REM-12 PLAN — Fix append-only error string to match verifier requirement

Task: TSK-P2-PREAUTH-005-REM-12
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-REM-11
failure_signature: PRE-PHASE2.WAVE5.REM-12.APPEND_ONLY_ERROR_STRING_MISMATCH
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Fix the error string in the deny_state_transitions_mutation() trigger function to match the exact "state_transitions is append-only" string required by the verifier script. The current error messages are specific but do not match the exact string required by the verifier.

## Architectural Context

The Wave-5-for-Devin.md specification and verifier scripts require the error message for state_transitions append-only enforcement to be exactly "state_transitions is append-only". The current migration 0139 implements deny_state_transitions_mutation() with specific error messages like "Direct mutation of state_transitions is not allowed. Use state machine transitions." and "Deletion of state_transitions is not allowed. Audit trail must be preserved." These do not match the exact string required by the verifier. This is a critical error string gap that breaks the verifier test. The trigger already uses RAISE EXCEPTION, so this task focuses on fixing the error string.

## Pre-conditions

- TSK-P2-PREAUTH-005-REM-11 is complete (trigger naming fixed)
- TSK-P2-PREAUTH-005-CLEANUP has completed
- Migration 0139 is applied

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0139_create_deny_state_transitions_mutation.sql | MODIFY | Change error string to exact "state_transitions is append-only", use CREATE OR REPLACE FUNCTION |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0151 |
| scripts/db/verify_tsk_p2_preauth_005_rem_12.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If error string is not changed to exact "state_transitions is append-only"** -> STOP
- **If MIGRATION_HEAD is not updated to 0151** -> STOP
- **If approval metadata is not created before editing migration** -> STOP
- **If behavioral negative test is not implemented** -> STOP

## Implementation Steps

### Step 1: Create Stage A approval artifact
**What:** `[ID rem_12_work_01]` Create Stage A approval artifact BEFORE editing migration
**How:**
- Create approvals/YYYY-MM-DD/BRANCH-<branch-name>.md with change description
- Create approvals/YYYY-MM-DD/BRANCH-<branch-name>.approval.json with required fields per approval_metadata.schema.json
- Must include: regulated_surfaces_touched: true
- Must include: paths_changed: ["schema/migrations/0139_create_deny_state_transitions_mutation.sql", "schema/migrations/MIGRATION_HEAD"]
- Validate with: python3 -m json.tool < approvals/YYYY-MM-DD/BRANCH-<branch-name>.approval.json
**Done when:** Approval artifact passes schema validation and exists before migration edit

### Step 2: Fix error string to exact "state_transitions is append-only"
**What:** `[ID rem_12_work_02]` Change error string in deny_state_transitions_mutation()
**How:** Modify migration 0139 to change error messages to exact string "state_transitions is append-only" for both UPDATE and DELETE operations
**Done when:** Error string is exactly "state_transitions is append-only"

### Step 3: Use CREATE OR REPLACE FUNCTION for idempotency
**What:** `[ID rem_12_work_03]` Ensure idempotent function definition
**How:** Modify migration 0139 to use CREATE OR REPLACE FUNCTION for deny_state_transitions_mutation()
**Done when:** Migration uses idempotent DDL for function

### Step 4: Update MIGRATION_HEAD
**What:** `[ID rem_12_work_04]` Update MIGRATION_HEAD to 0151
**How:** Run: echo 0151 > schema/migrations/MIGRATION_HEAD
**Done when:** MIGRATION_HEAD contains "0151"

### Step 5: Write verification script
**What:** `[ID rem_12_work_05]` Create verify_tsk_p2_preauth_005_rem_12.sh
**How:** Write bash script that verifies error string matches exactly "state_transitions is append-only" using DATABASE_URL
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_rem_12.sh

### Step 6: Write behavioral negative test
**What:** `[ID rem_12_work_06]` Implement behavioral negative test for UPDATE/DELETE operations
**How:** Add test that attempts UPDATE on state_transitions, verifies it fails with RAISE EXCEPTION and exact error string "state_transitions is append-only"
**Done when:** Negative test confirms UPDATE/DELETE are rejected with exact error string

### Step 7: Run verification
**What:** `[ID rem_12_work_07]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_rem_12.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/TSK-P2-PREAUTH-005-REM-12.json

### Step 8: Update EXEC_LOG.md with remediation markers
**What:** `[ID rem_12_work_08]` Document remediation in EXEC_LOG.md
**How:** Add entry with:
- failure_signature: PRE-PHASE2.WAVE5.REM-12.APPEND_ONLY_ERROR_STRING_MISMATCH
- origin_task_id: TSK-P2-PREAUTH-005-05
- repro_command: verification command that exposed error string mismatch
- verification_commands_run: list of verifiers executed
- final_status: RESOLVED
**Done when:** EXEC_LOG.md contains all required remediation trace markers

## Verification

```bash
# [ID rem_12_work_01] Check Stage A approval artifact exists
test -f approvals/$(date +%Y-%m-%d)/BRANCH-*.approval.json && python3 -m json.tool < approvals/$(date +%Y-%m-%d)/BRANCH-*.approval.json > /dev/null || exit 1

# [ID rem_12_work_02] Check error string matches exactly
psql "$DATABASE_URL" -c "SELECT prosrc FROM pg_proc WHERE proname = 'deny_state_transitions_mutation'" | grep -q 'state_transitions is append-only' || exit 1

# [ID rem_12_work_03] Check CREATE OR REPLACE FUNCTION
psql "$DATABASE_URL" -c "SELECT prosrc FROM pg_proc WHERE proname = 'deny_state_transitions_mutation'" | grep -q 'CREATE OR REPLACE FUNCTION' || exit 1

# [ID rem_12_work_04] Check MIGRATION_HEAD
test $(cat schema/migrations/MIGRATION_HEAD) = '0151' || exit 1

# [ID rem_12_work_05] [ID rem_12_work_07] Run verification script
test -x scripts/db/verify_tsk_p2_preauth_005_rem_12.sh && bash scripts/db/verify_tsk_p2_preauth_005_rem_12.sh > evidence/phase2/TSK-P2-PREAUTH-005-REM-12.json || exit 1

# [ID rem_12_work_06] Check negative test results
grep -q 'behavioral_negative_test' evidence/phase2/TSK-P2-PREAUTH-005-REM-12.json || exit 1

# [ID rem_12_work_07] Check evidence file
test -f evidence/phase2/TSK-P2-PREAUTH-005-REM-12.json || exit 1

# [ID rem_12_work_08] Check remediation trace markers
grep -q 'failure_signature' docs/plans/phase2/TSK-P2-PREAUTH-005-REM-12/EXEC_LOG.md && grep -q 'origin_task_id' docs/plans/phase2/TSK-P2-PREAUTH-005-REM-12/EXEC_LOG.md && grep -q 'repro_command' docs/plans/phase2/TSK-P2-PREAUTH-005-REM-12/EXEC_LOG.md && grep -q 'verification_commands_run' docs/plans/phase2/TSK-P2-PREAUTH-005-REM-12/EXEC_LOG.md && grep -q 'final_status' docs/plans/phase2/TSK-P2-PREAUTH-005-REM-12/EXEC_LOG.md || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/TSK-P2-PREAUTH-005-REM-12.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- error_string_verified
- migration_head
- behavioral_negative_test_results

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0139_create_deny_state_transitions_mutation.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Error string change affects downstream consumers | Low | Medium | Error string is explicitly required by verifier script |

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
- This ensures migrations can be executed repeatedly without errors

## Anti-Drift Cheating Limits

This is the final remediation task for Wave 5. After implementing this task, all critical structural and behavioral gaps identified in Wave-5-for-Devin.md will be addressed:
- Hash-based idempotency constraint (REM-03)
- JOIN logic validation in triggers (REM-06, REM-07, REM-08)
- Cryptographic verification functions using ed25519 (REM-10)
- Explicit trigger naming for ordering (REM-11)
- Append-only error string matching verifier requirement (REM-12)
