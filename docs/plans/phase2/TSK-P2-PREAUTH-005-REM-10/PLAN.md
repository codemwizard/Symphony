# TSK-P2-PREAUTH-005-REM-10 PLAN — Add enforce_transition_signature trigger

Task: TSK-P2-PREAUTH-005-REM-10
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-REM-09
failure_signature: PRE-PHASE2.WAVE5.REM-10.TRANSITION_SIGNATURE_TRIGGER
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Add the enforce_transition_signature() trigger function to verify transition_hash. This ensures cryptographic integrity of state transitions.

## Architectural Context

The Wave-5-for-Devin.md specification requires a trigger to verify the transition_hash column for cryptographic integrity. The original migration 0120 did not include this trigger, allowing transitions without cryptographic verification. This is a critical behavioral gap that breaks the non-repudiation invariant.

## Pre-conditions

- TSK-P2-PREAUTH-005-REM-09 is complete (transition_hash column added)
- TSK-P2-PREAUTH-005-CLEANUP has completed
- Migration 0141 is applied

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0141_create_crypto_functions.sql | MODIFY | Add pgcrypto extension verification, add ed25519 verification functions, use CREATE OR REPLACE FUNCTION |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0149 |
| scripts/db/verify_tsk_p2_preauth_005_rem_10.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If enforce_transition_signature trigger is not added** -> STOP
- **If MIGRATION_HEAD is not updated to 0126** -> STOP
- **If approval metadata is not created before editing migration** -> STOP
- **If behavioral negative test is not implemented** -> STOP

## Implementation Steps

### Step 1: Create Stage A approval artifact
**What:** `[ID rem_10_work_01]` Create approval artifact before editing migration
**How:** Create approvals/YYYY-MM-DD/BRANCH-<branch-name>.md and .approval.json with required fields per approval_metadata.schema.json
**Done when:** Approval artifact passes schema validation

### Step 2: Add cryptographic verification to enforce_transition_signature trigger
**What:** `[ID rem_10_work_02]` Add cryptographic verification to enforce_transition_signature() trigger
**How:** Modify migration 0141 to add cryptographic verification logic that verifies transition_hash and uses RAISE EXCEPTION on failure
**Done when:** Trigger function includes cryptographic verification and uses RAISE EXCEPTION

### Step 3: Update MIGRATION_HEAD
**What:** `[ID rem_10_work_03]` Update MIGRATION_HEAD to 0141
**How:** Run: echo 0141 > schema/migrations/MIGRATION_HEAD
**Done when:** MIGRATION_HEAD contains "0141"

### Step 4: Write verification script
**What:** `[ID rem_10_work_04]` Create verify_tsk_p2_preauth_005_rem_10.sh
**How:** Write bash script that verifies trigger exists and uses RAISE EXCEPTION using DATABASE_URL
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_rem_10.sh

### Step 5: Write behavioral negative test
**What:** `[ID rem_10_work_05]` Implement behavioral negative test for invalid transition_hash
**How:** Add test that attempts INSERT with invalid transition_hash, verifies it fails with RAISE EXCEPTION
**Done when:** Negative test confirms invalid transition_hash is rejected with exception

### Step 6: Run verification
**What:** `[ID rem_10_work_06]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_rem_10.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/TSK-P2-PREAUTH-005-REM-10.json

### Step 7: Update EXEC_LOG.md with remediation markers
**What:** `[ID rem_10_work_07]` Document remediation in EXEC_LOG.md
**How:** Add entry with failure_signature, origin_task_id, repro_command, verification_commands_run, final_status
**Done when:** EXEC_LOG.md contains all required remediation trace markers

## Verification

```bash
# [ID rem_10_work_02] Check trigger exists and uses RAISE EXCEPTION
psql "$DATABASE_URL" -c "SELECT prosrc FROM pg_proc WHERE proname = 'enforce_transition_signature'" | grep -q 'RAISE EXCEPTION' || exit 1

# [ID rem_10_work_03] Check MIGRATION_HEAD
test $(cat schema/migrations/MIGRATION_HEAD) = '0141' || exit 1

# [ID rem_10_work_04] [ID rem_10_work_06] Run verification script
test -x scripts/db/verify_tsk_p2_preauth_005_rem_10.sh && bash scripts/db/verify_tsk_p2_preauth_005_rem_10.sh > evidence/phase2/TSK-P2-PREAUTH-005-REM-10.json || exit 1

# [ID rem_10_work_06] Check evidence file
test -f evidence/phase2/TSK-P2-PREAUTH-005-REM-10.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/TSK-P2-PREAUTH-005-REM-10.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- trigger_exists_verified
- migration_head
- behavioral_negative_test_results

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0141_create_enforce_transition_signature.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Trigger name conflict | Low | Medium | Trigger name is explicitly specified in spec |

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

**pgcrypto Extension (CRITICAL):**
- The pgcrypto extension must be verified or enabled before using ed25519 functions
- Include: CREATE EXTENSION IF NOT EXISTS pgcrypto; in migration 0141
- Verify pgcrypto is available in the target PostgreSQL environment

## Anti-Drift Cheating Limits

After implementing this task, the following attack surfaces remain open:
- No generic entity model (addressed in REM-11)

This will be addressed in the final remediation task.
