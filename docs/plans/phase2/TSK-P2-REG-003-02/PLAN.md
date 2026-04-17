# TSK-P2-REG-003-02: Create protected_areas table

**Task:** TSK-P2-REG-003-02
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-REG-003-01
**Blocks:** TSK-P2-REG-003-03
**Failure Signature**: Table not created or geometry incorrect => CRITICAL_FAIL

## Objective

Create the protected_areas table with PostGIS geometry to store versioned protected area polygons for DNSH compliance checking.

## Architectural Context

The protected_areas table stores protected area polygons with versioning via source_version_id FK to factor_registry. Geometry is POLYGON with SRID 4326 (WGS84). Append-only trigger ensures immutability.

## Pre-conditions

- TSK-P2-REG-003-01 (PostGIS extension) is complete
- factor_registry table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0125_protected_areas.sql | CREATE | Migration creating protected_areas table |
| scripts/db/verify_tsk_p2_reg_003_02.sh | CREATE | Verification script for this task |

## Stop Conditions

- If protected_areas table does not exist
- If geom column is not geometry(POLYGON, 4326) NOT NULL
- If source_version_id FK to factor_registry is missing
- If GIST index on geom is missing
- If append-only trigger is missing

## Implementation Steps

### [ID tsk_p2_reg_003_02_work_item_01] Write migration 0125 for protected_areas table
Write migration 0125 at schema/migrations/0125_protected_areas.sql creating protected_areas table with columns: area_id UUID PRIMARY KEY, area_name VARCHAR NOT NULL, geom geometry(POLYGON, 4326) NOT NULL, source_version_id UUID NOT NULL REFERENCES factor_registry(factor_id), effective_from TIMESTAMPTZ NOT NULL, effective_to TIMESTAMPTZ.

### [ID tsk_p2_reg_003_02_work_item_02] Add GIST index on geom column
Add CREATE INDEX idx_protected_areas_geom ON protected_areas USING GIST (geom) to migration.

### [ID tsk_p2_reg_003_02_work_item_03] Add append-only trigger
Add trigger function to migration that raises GF055 on any UPDATE or DELETE attempt on protected_areas table.

### [ID tsk_p2_reg_003_02_work_item_04] Add revoke-first privileges
Add GRANT SELECT ON protected_areas TO symphony_command and GRANT ALL ON protected_areas TO symphony_control after REVOKE ALL FROM PUBLIC.

### [ID tsk_p2_reg_003_02_work_item_05] Write verification script
Write verify_tsk_p2_reg_003_02.sh that runs psql to verify table exists, geom is geometry type, and index exists.

### [ID tsk_p2_reg_003_02_work_item_06] Run verification script
Run verify_tsk_p2_reg_003_02.sh to confirm migration is successful.

### [ID tsk_p2_reg_003_02_work_item_07] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_003_02_work_item_01] [ID tsk_p2_reg_003_02_work_item_02]
# [ID tsk_p2_reg_003_02_work_item_03] [ID tsk_p2_reg_003_02_work_item_04]
# [ID tsk_p2_reg_003_02_work_item_05] [ID tsk_p2_reg_003_02_work_item_06]
test -x scripts/db/verify_tsk_p2_reg_003_02.sh && bash scripts/db/verify_tsk_p2_reg_003_02.sh > evidence/phase2/tsk_p2_reg_003_02.json || exit 1

# [ID tsk_p2_reg_003_02_work_item_01]
test -f schema/migrations/0125_protected_areas.sql || exit 1

# [ID tsk_p2_reg_003_02_work_item_06]
test -f evidence/phase2/tsk_p2_reg_003_02.json || exit 1

# [ID tsk_p2_reg_003_02_work_item_07]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_003_02.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- geometry_type_correct
- gist_index_exists
- append_only_trigger
- observed_paths

## Rollback

Revert migration:
```bash
git checkout schema/migrations/0125_protected_areas.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PostGIS not installed | Low | Critical | Ensure TSK-P2-REG-003-01 is complete |
| FK to factor_registry fails | Low | High | Ensure factor_registry table exists |
| Geometry type incorrect | Low | Critical | Verify geometry(POLYGON, 4326) syntax |

## Approval

This task modifies schema. Requires human review before merge.
