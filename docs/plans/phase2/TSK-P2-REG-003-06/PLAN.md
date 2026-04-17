# TSK-P2-REG-003-06: Implement enforce_k13_taxonomy_alignment() trigger

**Task:** TSK-P2-REG-003-06
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-REG-003-05
**Blocks:** TSK-P2-REG-003-07
**Failure Signature**: Trigger missing or not SECURITY DEFINER => CRITICAL_FAIL

## Objective

Implement enforce_k13_taxonomy_alignment() trigger to ensure taxonomy_aligned flag requires spatial_check_execution_id, enforcing EU Taxonomy K13 compliance.

## Architectural Context

The enforce_k13_taxonomy_alignment() trigger enforces that when taxonomy_aligned=true, there must be a spatial_check_execution_id in project_boundaries for that project. Raises GF060 on violation.

## Pre-conditions

- TSK-P2-REG-003-05 (enforce_dns_harm trigger) is complete
- taxonomy_aligned column exists in projects table
- project_boundaries table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0125_k13_trigger.sql | CREATE | Migration creating enforce_k13_taxonomy_alignment() trigger |
| scripts/db/verify_tsk_p2_reg_003_06.sh | CREATE | Verification script for this task |

## Stop Conditions

- If enforce_k13_taxonomy_alignment() function does not exist in pg_proc
- If function is not SECURITY DEFINER with hardened search_path
- If trigger is not attached as BEFORE INSERT OR UPDATE on projects
- If trigger does not raise GF060

## Implementation Steps

### [ID tsk_p2_reg_003_06_work_item_01] Write enforce_k13_taxonomy_alignment() function
Write enforce_k13_taxonomy_alignment() as SECURITY DEFINER PL/pgSQL with hardened search_path: SET search_path = pg_catalog, public. Function logic: IF NEW.taxonomy_aligned = true AND (SELECT spatial_check_execution_id FROM public.project_boundaries WHERE project_id = NEW.project_id LIMIT 1) IS NULL THEN RAISE EXCEPTION 'K13: taxonomy_aligned requires spatial_check_execution_id' USING ERRCODE = 'GF060'; END IF; RETURN NEW.

### [ID tsk_p2_reg_003_06_work_item_02] Attach trigger to projects
Attach function as BEFORE INSERT OR UPDATE trigger on projects table.

### [ID tsk_p2_reg_003_06_work_item_03] Write verification script
Write verify_tsk_p2_reg_003_06.sh that runs psql to verify function exists with prosecdef=true and trigger is attached.

### [ID tsk_p2_reg_003_06_work_item_04] Run verification script
Run verify_tsk_p2_reg_003_06.sh to confirm trigger is successful.

### [ID tsk_p2_reg_003_06_work_item_05] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_003_06_work_item_01] [ID tsk_p2_reg_003_06_work_item_02]
# [ID tsk_p2_reg_003_06_work_item_03] [ID tsk_p2_reg_003_06_work_item_04]
test -x scripts/db/verify_tsk_p2_reg_003_06.sh && bash scripts/db/verify_tsk_p2_reg_003_06.sh > evidence/phase2/tsk_p2_reg_003_06.json || exit 1

# [ID tsk_p2_reg_003_06_work_item_01]
test -f schema/migrations/0125_k13_trigger.sql || exit 1

# [ID tsk_p2_reg_003_06_work_item_04]
test -f evidence/phase2/tsk_p2_reg_003_06.json || exit 1

# [ID tsk_p2_reg_003_06_work_item_05]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_003_06.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- function_exists
- security_definer
- trigger_attached
- observed_paths

## Rollback

Revert trigger:
```bash
psql -c "DROP TRIGGER IF EXISTS enforce_k13_taxonomy_alignment ON projects CASCADE"
psql -c "DROP FUNCTION IF EXISTS enforce_k13_taxonomy_alignment()"
git checkout schema/migrations/0125_k13_trigger.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Function not SECURITY DEFINER | Low | Critical | Hardening required per AGENTS.md |
| search_path not hardened | Low | Critical | Add SET search_path = pg_catalog, public to function |
| taxonomy_aligned column does not exist | Low | Critical | Ensure TSK-P2-REG-003-04 is complete |

## Approval

This task modifies schema. Requires human review before merge.
