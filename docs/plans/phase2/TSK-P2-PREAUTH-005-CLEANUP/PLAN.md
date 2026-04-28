# TSK-P2-PREAUTH-005-CLEANUP PLAN — Wave 5 Baseline Reconciliation

Task: TSK-P2-PREAUTH-005-CLEANUP
Owner: DB_FOUNDATION
Depends on: []
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-005-CLEANUP.BASELINE_RECONCILIATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Perform baseline reconciliation before Wave 5 implementation by deleting the monolithic migration 0120 and updating all Wave 5 task plans and metadata to target new migration sequence (0137-0144). This enables proper atomic implementation of Wave 5 tasks, removing placeholder RAISE NOTICE stubs and respecting forward-only migration principles.

## Architectural Context

The existing migration 0120_create_state_transitions.sql is a monolith containing all Wave 5 work (state_transitions table, state_current table, and 6 trigger functions). This violates atomic task principles and contains placeholder RAISE NOTICE logic instead of actual enforcement. To implement Wave 5 correctly, we must delete this monolith and re-sequence the work into atomic migrations 0137-0144, then update all task plans and remediation tasks to reference the new sequence.

## Pre-conditions

- Migration 0120_create_state_transitions.sql exists
- All Wave 5 task PLAN.md and meta.yml files exist
- All remediation task PLAN.md files exist
- MIGRATION_HEAD is currently 0136

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0120_create_state_transitions.sql | DELETE | Remove monolith migration |
| scripts/db/verify_tsk_p2_preauth_005_01.sh | DELETE | Remove stale verification script |
| docs/plans/phase2/TSK-P2-PREAUTH-005-01/PLAN.md | MODIFY | Update migration 0120 → 0137 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-02/PLAN.md | MODIFY | Update migration 0120 → 0138 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-03/PLAN.md | MODIFY | Update migration 0120 → 0139 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-04/PLAN.md | MODIFY | Update migration 0120 → 0140 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-05/PLAN.md | MODIFY | Update migration 0120 → 0141 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-06/PLAN.md | MODIFY | Update migration 0120 → 0142 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-07/PLAN.md | MODIFY | Update migration 0120 → 0143 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-08/PLAN.md | MODIFY | Update migration 0120 → 0144 |
| tasks/TSK-P2-PREAUTH-005-01/meta.yml | MODIFY | Update touches to 0137 |
| tasks/TSK-P2-PREAUTH-005-02/meta.yml | MODIFY | Update touches to 0138 |
| tasks/TSK-P2-PREAUTH-005-03/meta.yml | MODIFY | Update touches to 0139 |
| tasks/TSK-P2-PREAUTH-005-04/meta.yml | MODIFY | Update touches to 0140 |
| tasks/TSK-P2-PREAUTH-005-05/meta.yml | MODIFY | Update touches to 0141 |
| tasks/TSK-P2-PREAUTH-005-06/meta.yml | MODIFY | Update touches to 0142 |
| tasks/TSK-P2-PREAUTH-005-07/meta.yml | MODIFY | Update touches to 0143 |
| tasks/TSK-P2-PREAUTH-005-08/meta.yml | MODIFY | Update touches to 0144 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-01/PLAN.md | MODIFY | Update target migration 0120 → 0137 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-02/PLAN.md | MODIFY | Update target migration 0120 → 0137 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-03/PLAN.md | MODIFY | Update target migration 0120 → 0137 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-04/PLAN.md | MODIFY | Update target migration 0120 → 0137 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-05/PLAN.md | MODIFY | Update target migration 0120 → 0137 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-06/PLAN.md | MODIFY | Update target migration 0120 → 0139 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-07/PLAN.md | MODIFY | Update target migration 0120 → 0140 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-08/PLAN.md | MODIFY | Update target migration 0120 → 0142 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-09/PLAN.md | MODIFY | Update target migration 0120 → 0137 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-10/PLAN.md | MODIFY | Update target migration 0120 → 0141 |
| docs/plans/phase2/TSK-P2-PREAUTH-005-REM-11/PLAN.md | MODIFY | Update target migration 0120 → 0137 |

## Stop Conditions

- **If migration 0120 does not exist** -> STOP (already cleaned up or wrong state)
- **If any Wave 5 task file is missing** -> STOP (incomplete task pack)
- **If dependency chain would be broken** -> STOP (verify before applying changes)

## Implementation Steps

### Step 1: Delete monolith migration
**What:** `[ID tsk_p2_preauth_005_cleanup_work_item_01]` Remove schema/migrations/0120_create_state_transitions.sql
**How:** `rm schema/migrations/0120_create_state_transitions.sql`
**Done when:** File no longer exists

### Step 2: Delete stale verification script
**What:** `[ID tsk_p2_preauth_005_cleanup_work_item_02]` Remove scripts/db/verify_tsk_p2_preauth_005_01.sh
**How:** `rm scripts/db/verify_tsk_p2_preauth_005_01.sh`
**Done when:** File no longer exists

### Step 3-18: Update Phase 1 task files
**What:** `[ID tsk_p2_preauth_005_cleanup_work_item_03-18]` Update all 9 Wave 5 task PLAN.md and meta.yml files
**How:** Replace migration 0120 references with new sequence (0137-0144) in both PLAN.md and meta.yml files
**Done when:** All files reference correct new migration numbers

### Step 19: Update remediation task files
**What:** `[ID tsk_p2_preauth_005_cleanup_work_item_19]` Update all 11 remediation task PLAN.md files
**How:** Replace migration 0120 references with appropriate new migration numbers based on which migration each remediation task targets
**Done when:** All remediation tasks reference correct new migration numbers

### Step 20: Verify dependency chain
**What:** `[ID tsk_p2_preauth_005_cleanup_work_item_20]` Verify dependency chain integrity
**How:** Check that all tasks have correct depends_on and blocks references
**Done when:** Dependency chain is preserved and correct

## Verification

```bash
# [ID tsk_p2_preauth_005_cleanup_work_item_01]
test ! -f schema/migrations/0120_create_state_transitions.sql || exit 1

# [ID tsk_p2_preauth_005_cleanup_work_item_02]
test ! -f scripts/db/verify_tsk_p2_preauth_005_01.sh || exit 1

# [ID tsk_p2_preauth_005_cleanup_work_item_03] [ID tsk_p2_preauth_005_cleanup_work_item_05]
grep -q "0137" docs/plans/phase2/TSK-P2-PREAUTH-005-01/PLAN.md || exit 1
grep -q "0138" docs/plans/phase2/TSK-P2-PREAUTH-005-02/PLAN.md || exit 1

# [ID tsk_p2_preauth_005_cleanup_work_item_04] [ID tsk_p2_preauth_005_cleanup_work_item_06]
grep -q "0137_create_state_transitions.sql" tasks/TSK-P2-PREAUTH-005-01/meta.yml || exit 1
grep -q "0138_create_state_current.sql" tasks/TSK-P2-PREAUTH-005-02/meta.yml || exit 1

# [ID tsk_p2_preauth_005_cleanup_work_item_19]
! grep -r "0120_create_state_transitions.sql" docs/plans/phase2/TSK-P2-PREAUTH-005-REM-*/PLAN.md || exit 1

# [ID tsk_p2_preauth_005_cleanup_work_item_20]
grep -q "TSK-P2-PREAUTH-005-01" tasks/TSK-P2-PREAUTH-005-02/meta.yml || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_005_cleanup.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- monolith_deleted
- verification_script_deleted
- plans_updated
- meta_updated
- remediation_updated

## Rollback

Restore files from git (if cleanup was committed):
```bash
git checkout schema/migrations/0120_create_state_transitions.sql
git checkout scripts/db/verify_tsk_p2_preauth_005_01.sh
git checkout docs/plans/phase2/TSK-P2-PREAUTH-005-*/PLAN.md
git checkout tasks/TSK-P2-PREAUTH-005-*/meta.yml
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Accidental deletion of wrong file | Low | Critical | Verify file paths before deletion |
| Migration sequence conflict | Low | High | Verify MIGRATION_HEAD is 0136 before starting |
| Dependency chain breakage | Low | Critical | Verify depends_on/blocks before committing |

## Approval

This is a CRITICAL governance task that enables proper Wave 5 implementation. Requires human review before merge.

## Anti-Drift Cheating Limits

After this cleanup, the following attack surfaces remain open:
- Wave 5 tasks are not yet implemented (this cleanup only prepares the plans)
- Placeholder logic will be removed during actual implementation
- Migration sequence gap (0120-0136 exist, then 0137+) is intentional to preserve forward-only principle

These will be addressed during Wave 5 implementation tasks (005-01 through 005-08).
