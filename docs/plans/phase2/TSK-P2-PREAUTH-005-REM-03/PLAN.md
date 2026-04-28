# TSK-P2-PREAUTH-005-REM-03 PLAN — Add UNIQUE(entity_type, entity_id, execution_id) constraint

Task: TSK-P2-PREAUTH-005-REM-03
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-REM-02
failure_signature: PRE-PHASE2.WAVE5.REM-03.UNIQUE_CONSTRAINT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Add UNIQUE(entity_type, entity_id, execution_id) constraint to the state_transitions table. This ensures no duplicate transitions for the same entity within the same execution, preventing audit trail corruption.

## Architectural Context

The Wave-5-for-Devin.md specification requires a UNIQUE constraint on (entity_type, entity_id, execution_id) to prevent duplicate state transitions. The original migration 0120 lacked this constraint, allowing multiple transitions for the same entity in the same execution. This is a critical structural gap that breaks the idempotency invariant.

## Pre-conditions

- TSK-P2-PREAUTH-005-01 is complete (state_transitions table created)
- TSK-P2-PREAUTH-005-CLEANUP has completed
- Migration 0137 is applied
- No existing duplicate (entity_type, entity_id, transition_hash) combinations (remediation assumes clean state)

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0137_create_state_transitions.sql | MODIFY | Add UNIQUE(entity_type, entity_id, execution_id) constraint |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0137 |
| scripts/db/verify_tsk_p2_preauth_005_rem_03.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If UNIQUE constraint is not added** -> STOP
- **If MIGRATION_HEAD is not updated to 0123** -> STOP
- **If approval metadata is not created before editing migration** -> STOP

## Implementation Steps

### Step 1: Create Stage A approval artifact
**What:** `[ID rem_03_work_01]` Create approval artifact before editing migration
**How:** Create approvals/YYYY-MM-DD/BRANCH-<branch-name>.md and .approval.json with required fields per approval_metadata.schema.json
**Done when:** Approval artifact passes schema validation

### Step 2: Add UNIQUE constraint
**What:** `[ID rem_03_work_02]` Add UNIQUE(entity_type, entity_id, execution_id) constraint
**How:** Modify migration 0137 to add UNIQUE constraint
**Done when:** UNIQUE constraint exists in migration

### Step 3: Update MIGRATION_HEAD
**What:** `[ID rem_03_work_03]` Update MIGRATION_HEAD to 0137
**How:** Run: echo 0137 > schema/migrations/MIGRATION_HEAD
**Done when:** MIGRATION_HEAD contains "0137"

### Step 4: Write verification script
**What:** `[ID rem_03_work_04]` Create verify_tsk_p2_preauth_005_rem_03.sh
**How:** Write bash script that verifies UNIQUE constraint exists using DATABASE_URL
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_rem_03.sh

### Step 5: Write negative test for duplicates
**What:** `[ID rem_03_work_05]` Implement negative test for duplicate rejection
**How:** Add test that attempts INSERT duplicate (entity_type, entity_id, execution_id), verifies it fails with constraint violation
**Done when:** Negative test confirms duplicates are rejected

### Step 6: Run verification
**What:** `[ID rem_03_work_06]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_rem_03.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/TSK-P2-PREAUTH-005-REM-03.json

### Step 7: Update EXEC_LOG.md with remediation markers
**What:** `[ID rem_03_work_07]` Document remediation in EXEC_LOG.md
**How:** Add entry with failure_signature, origin_task_id, repro_command, verification_commands_run, final_status
**Done when:** EXEC_LOG.md contains all required remediation trace markers

## Verification

```bash
# [ID rem_03_work_02] Check UNIQUE constraint
psql "$DATABASE_URL" -c "\d state_transitions" | grep -q 'unique.*entity_type.*entity_id.*execution_id' || exit 1

# [ID rem_03_work_03] Check MIGRATION_HEAD
test $(cat schema/migrations/MIGRATION_HEAD) = '0137' || exit 1

# [ID rem_03_work_04] [ID rem_03_work_06] Run verification script
test -x scripts/db/verify_tsk_p2_preauth_005_rem_03.sh && bash scripts/db/verify_tsk_p2_preauth_005_rem_03.sh > evidence/phase2/TSK-P2-PREAUTH-005-REM-03.json || exit 1

# [ID rem_03_work_06] Check evidence file
test -f evidence/phase2/TSK-P2-PREAUTH-005-REM-03.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/TSK-P2-PREAUTH-005-REM-03.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- unique_constraint_verified
- migration_head
- negative_test_results

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0137_create_state_transitions.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Existing duplicate (entity_type, entity_id, execution_id) combinations | Low | Critical | Remediation assumes clean state, data migration required if duplicates exist |

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

## Anti-Drift Cheating Limits

After implementing this task, the following attack surfaces remain open:
- No enforcement that triggers actually use this constraint (addressed in REM-06 through REM-08)
- No cryptographic verification of transition_hash (addressed in REM-10)
- No generic entity model (addressed in REM-11)

These will be addressed in subsequent remediation tasks.
