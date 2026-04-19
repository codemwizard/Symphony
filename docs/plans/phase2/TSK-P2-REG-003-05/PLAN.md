# TSK-P2-REG-003-05: Implement enforce_dns_harm() trigger

Task: TSK-P2-REG-003-05
Owner: DB_FOUNDATION
Depends on: TSK-P2-REG-003-04
failure_signature: PRE-PHASE2.REG.TSK-P2-REG-003-05.TRIGGER_OR_SECURITY_DEFINER_INCORRECT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Implement enforce_dns_harm() trigger to prevent project boundaries from overlapping protected areas, enforcing DNSH (Do No Significant Harm) compliance.

## Architectural Context

The enforce_dns_harm() trigger uses PostGIS ST_Intersects() to detect overlaps between project_boundaries.geom and protected_areas.geom where effective_to IS NULL. Raises GF057 on violation.

## Pre-conditions

- TSK-P2-REG-003-04 (taxonomy_aligned column) is complete
- project_boundaries table exists
- protected_areas table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0125_dns_harm_trigger.sql | CREATE | Migration creating enforce_dns_harm() trigger |
| scripts/db/verify_tsk_p2_reg_003_05.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- If enforce_dns_harm() function does not exist in pg_proc
- If function is not SECURITY DEFINER with hardened search_path
- If trigger is not attached as BEFORE INSERT OR UPDATE on project_boundaries
- If trigger does not raise GF057

## Implementation Steps

### [ID tsk_p2_reg_003_05_work_item_01] Write enforce_dns_harm() function
Write enforce_dns_harm() as SECURITY DEFINER PL/pgSQL with hardened search_path: SET search_path = pg_catalog, public. Function logic: IF EXISTS (SELECT 1 FROM public.protected_areas pa WHERE ST_Intersects(NEW.geom, pa.geom) AND pa.effective_to IS NULL) THEN RAISE EXCEPTION 'DNSH violation: project boundary overlaps protected area' USING ERRCODE = 'GF057'; END IF; RETURN NEW.

### [ID tsk_p2_reg_003_05_work_item_02] Attach trigger to project_boundaries
Attach function as BEFORE INSERT OR UPDATE trigger on project_boundaries table.

### [ID tsk_p2_reg_003_05_work_item_03] Write verification script
Write verify_tsk_p2_reg_003_05.sh that runs psql to verify function exists with prosecdef=true and trigger is attached.

### [ID tsk_p2_reg_003_05_work_item_04] Run verification script
Run verify_tsk_p2_reg_003_05.sh to confirm trigger is successful.

### [ID tsk_p2_reg_003_05_work_item_05] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_003_05_work_item_01] [ID tsk_p2_reg_003_05_work_item_02]
# [ID tsk_p2_reg_003_05_work_item_03] [ID tsk_p2_reg_003_05_work_item_04]
test -x scripts/db/verify_tsk_p2_reg_003_05.sh && bash scripts/db/verify_tsk_p2_reg_003_05.sh > evidence/phase2/tsk_p2_reg_003_05.json || exit 1

# [ID tsk_p2_reg_003_05_work_item_01]
test -f schema/migrations/0125_dns_harm_trigger.sql || exit 1

# [ID tsk_p2_reg_003_05_work_item_04]
test -f evidence/phase2/tsk_p2_reg_003_05.json || exit 1

# [ID tsk_p2_reg_003_05_work_item_05]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_003_05.json with must_include fields:
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
psql -c "DROP TRIGGER IF EXISTS enforce_dns_harm ON project_boundaries CASCADE"
psql -c "DROP FUNCTION IF EXISTS enforce_dns_harm()"
git checkout schema/migrations/0125_dns_harm_trigger.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Function not SECURITY DEFINER | Low | Critical | Hardening required per AGENTS.md |
| search_path not hardened | Low | Critical | Add SET search_path = pg_catalog, public to function |
| ST_Intersects() performance | Low | Medium | GIST index on geom columns required |

## Approval

This task modifies schema. Requires human review before merge.
