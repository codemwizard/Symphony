# TSK-P2-PREAUTH-005-REM-11 PLAN — Add entity_type and entity_id columns to state_transitions

Task: TSK-P2-PREAUTH-005-REM-11
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-REM-10
failure_signature: PRE-PHASE2.WAVE5.REM-11.ENTITY_COLUMNS
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Add entity_type and entity_id columns to the state_transitions table. This enables generic entity model support for state transitions.

## Architectural Context

The Wave-5-for-Devin.md specification requires entity_type and entity_id columns to support a generic entity model for state transitions. The original migration 0120 did not include these columns, limiting state transitions to a specific entity type. This is a structural gap that breaks the generic entity model invariant.

## Pre-conditions

- TSK-P2-PREAUTH-005-REM-10 is complete (transition signature trigger added)
- TSK-P2-PREAUTH-005-CLEANUP has completed
- Migration 0137 is applied

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0137_create_state_transitions.sql | MODIFY | Add entity_type (NOT NULL text) and entity_id (NOT NULL uuid) columns |
| schema/migrations/MIGRATION_HEAD | MODIFY | Update to 0137 |
| scripts/db/verify_tsk_p2_preauth_005_rem_11.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If entity_type or entity_id columns are not added** -> STOP
- **If MIGRATION_HEAD is not updated to 0127** -> STOP
- **If approval metadata is not created before editing migration** -> STOP

## Implementation Steps

### Step 1: Create Stage A approval artifact
**What:** `[ID rem_11_work_01]` Create approval artifact before editing migration
**How:** Create approvals/YYYY-MM-DD/BRANCH-<branch-name>.md and .approval.json with required fields per approval_metadata.schema.json
**Done when:** Approval artifact passes schema validation

### Step 2: Add entity_type and entity_id columns
**What:** `[ID rem_11_work_02]` Add entity_type (NOT NULL text) and entity_id (NOT NULL uuid) columns to state_transitions table
**How:** Modify migration 0137 to add both columns with NOT NULL constraints
**Done when:** Both columns exist in state_transitions table

### Step 3: Update MIGRATION_HEAD
**What:** `[ID rem_11_work_03]` Update MIGRATION_HEAD to 0137
**How:** Run: echo 0137 > schema/migrations/MIGRATION_HEAD
**Done when:** MIGRATION_HEAD contains "0137"

### Step 4: Write verification script
**What:** `[ID rem_11_work_04]` Create verify_tsk_p2_preauth_005_rem_11.sh
**How:** Write bash script that verifies both columns exist using DATABASE_URL
**Done when:** Verification script exists at scripts/db/verify_tsk_p2_preauth_005_rem_11.sh

### Step 5: Run verification
**What:** `[ID rem_11_work_05]` Execute verification script
**How:** Run: bash scripts/db/verify_tsk_p2_preauth_005_rem_11.sh
**Done when:** Script exits 0 and emits evidence to evidence/phase2/TSK-P2-PREAUTH-005-REM-11.json

### Step 6: Update EXEC_LOG.md with remediation markers
**What:** `[ID rem_11_work_06]` Document remediation in EXEC_LOG.md
**How:** Add entry with failure_signature, origin_task_id, repro_command, verification_commands_run, final_status
**Done when:** EXEC_LOG.md contains all required remediation trace markers

## Verification

```bash
# [ID rem_11_work_02] Check columns exist
psql "$DATABASE_URL" -c "\d state_transitions" | grep -q 'entity_type.*not null' || exit 1
psql "$DATABASE_URL" -c "\d state_transitions" | grep -q 'entity_id.*not null' || exit 1

# [ID rem_11_work_03] Check MIGRATION_HEAD
test $(cat schema/migrations/MIGRATION_HEAD) = '0137' || exit 1

# [ID rem_11_work_04] [ID rem_11_work_05] Run verification script
test -x scripts/db/verify_tsk_p2_preauth_005_rem_11.sh && bash scripts/db/verify_tsk_p2_preauth_005_rem_11.sh > evidence/phase2/TSK-P2-PREAUTH-005-REM-11.json || exit 1

# [ID rem_11_work_05] Check evidence file
test -f evidence/phase2/TSK-P2-PREAUTH-005-REM-11.json || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/TSK-P2-PREAUTH-005-REM-11.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- columns_exist_verified
- migration_head

## Rollback

Revert migration and MIGRATION_HEAD:
```bash
git checkout schema/migrations/0137_create_state_transitions.sql
git checkout schema/migrations/MIGRATION_HEAD
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Column name conflict | Low | Medium | Column names are explicitly specified in spec |

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
- Use DROP TRIGGER IF EXISTS / CREATE TRIGGER for idempotency when modifying triggers
- This ensures migrations can be executed repeatedly without errors

## Anti-Drift Cheating Limits

This is the final remediation task for Wave 5. After implementing this task, all critical structural and behavioral gaps identified in Wave-5-for-Devin.md will be addressed:
- NOT NULL constraints on execution_id and policy_decision_id (REM-01, REM-02)
- UNIQUE constraint on (entity_type, entity_id, execution_id) (REM-03)
- last_transition_id column and FK constraint (REM-04, REM-05)
- RAISE EXCEPTION in all enforcement triggers (REM-06, REM-07, REM-08)
- transition_hash column and verification trigger (REM-09, REM-10)
- Generic entity model columns (REM-11)
