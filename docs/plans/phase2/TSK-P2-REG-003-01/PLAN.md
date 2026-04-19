# TSK-P2-REG-003-01: Install PostGIS extension

Task: TSK-P2-REG-003-01
Owner: DB_FOUNDATION
Depends on: TSK-P2-REG-003-00
failure_signature: PRE-PHASE2.REG.TSK-P2-REG-003-01.POSTGIS_NOT_INSTALLED
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Install PostGIS extension in the public schema to enable spatial data operations for DNSH and K13 compliance checks.

## Architectural Context

PostGIS extension provides geometry types and spatial functions required for DNSH overlap detection and K13 taxonomy alignment enforcement.

## Pre-conditions

- TSK-P2-REG-003-00 PLAN.md exists and passes verification
- Database server has PostGIS installed

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0125_postgis_extension.sql | CREATE | Migration installing PostGIS extension |
| scripts/db/verify_tsk_p2_reg_003_01.sh | CREATE | Verification script for this task |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- If PostGIS extension is not installed in public schema
- If PostGIS_version() returns null

## Implementation Steps

### [ID tsk_p2_reg_003_01_work_item_01] Write migration 0125 for PostGIS extension
Write migration 0125 at schema/migrations/0125_postgis_extension.sql with CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public.

### [ID tsk_p2_reg_003_01_work_item_02] Verify PostGIS installation
Add verification to migration: SELECT PostGIS_version() to confirm extension is loaded.

### [ID tsk_p2_reg_003_01_work_item_03] Write verification script
Write verify_tsk_p2_reg_003_01.sh that runs psql -c "SELECT PostGIS_version()" | grep -v '(0 rows)'.

### [ID tsk_p2_reg_003_01_work_item_04] Run verification script
Run verify_tsk_p2_reg_003_01.sh to confirm PostGIS is installed.

### [ID tsk_p2_reg_003_01_work_item_05] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_003_01_work_item_01] [ID tsk_p2_reg_003_01_work_item_02]
# [ID tsk_p2_reg_003_01_work_item_03] [ID tsk_p2_reg_003_01_work_item_04]
test -x scripts/db/verify_tsk_p2_reg_003_01.sh && bash scripts/db/verify_tsk_p2_reg_003_01.sh > evidence/phase2/tsk_p2_reg_003_01.json || exit 1

# [ID tsk_p2_reg_003_01_work_item_01]
test -f schema/migrations/0125_postgis_extension.sql || exit 1

# [ID tsk_p2_reg_003_01_work_item_04]
test -f evidence/phase2/tsk_p2_reg_003_01.json || exit 1

# [ID tsk_p2_reg_003_01_work_item_05]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_003_01.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- postgis_installed
- postgis_version
- observed_paths

## Rollback

Remove PostGIS extension:
```bash
psql -c "DROP EXTENSION IF EXISTS postgis CASCADE"
git checkout schema/migrations/0125_postgis_extension.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PostGIS not available in database | Low | Critical | Ensure PostGIS is installed on database server |
| Extension creation fails | Low | High | Check permissions on public schema |

## Approval

This task modifies schema. Requires human review before merge.
