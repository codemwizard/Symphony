# TSK-P2-REG-003-03: Create project_boundaries table

**Task:** TSK-P2-REG-003-03
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-REG-003-02
**Blocks:** TSK-P2-REG-003-04
**Failure Signature**: Table not created or FKs incorrect => CRITICAL_FAIL

## Objective

Create the project_boundaries table with PostGIS geometry to store project boundary polygons with execution binding for DNSH and K13 compliance.

## Architectural Context

The project_boundaries table stores project boundary polygons with execution binding via spatial_check_execution_id FK to execution_records. DNSH check version references protected_areas. Geometry is POLYGON with SRID 4326.

## Pre-conditions

- TSK-P2-REG-003-02 (protected_areas) is complete
- execution_records table exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| schema/migrations/0125_project_boundaries.sql | CREATE | Migration creating project_boundaries table |
| scripts/db/verify_tsk_p2_reg_003_03.sh | CREATE | Verification script for this task |

## Stop Conditions

- If project_boundaries table does not exist
- If geom column is not geometry(POLYGON, 4326) NOT NULL
- If dns_check_version_id FK to protected_areas is missing
- If spatial_check_execution_id FK to execution_records is missing
- If GIST index on geom is missing
- If append-only trigger is missing

## Implementation Steps

### [ID tsk_p2_reg_003_03_work_item_01] Write migration 0125 for project_boundaries table
Write migration 0125 at schema/migrations/0125_project_boundaries.sql creating project_boundaries table with columns: boundary_id UUID PRIMARY KEY, project_id UUID NOT NULL, geom geometry(POLYGON, 4326) NOT NULL, dns_check_version_id UUID NOT NULL REFERENCES protected_areas(area_id), spatial_check_execution_id UUID NOT NULL REFERENCES execution_records(execution_id), effective_from TIMESTAMPTZ NOT NULL, effective_to TIMESTAMPTZ.

### [ID tsk_p2_reg_003_03_work_item_02] Add GIST index on geom column
Add CREATE INDEX idx_project_boundaries_geom ON project_boundaries USING GIST (geom) to migration.

### [ID tsk_p2_reg_003_03_work_item_03] Add append-only trigger
Add trigger function to migration that raises GF056 on any UPDATE or DELETE attempt on project_boundaries table.

### [ID tsk_p2_reg_003_03_work_item_04] Add revoke-first privileges
Add GRANT SELECT ON project_boundaries TO symphony_command and GRANT ALL ON project_boundaries TO symphony_control after REVOKE ALL FROM PUBLIC.

### [ID tsk_p2_reg_003_03_work_item_05] Write verification script
Write verify_tsk_p2_reg_003_03.sh that runs psql to verify table exists, FKs are correct, and index exists.

### [ID tsk_p2_reg_003_03_work_item_06] Run verification script
Run verify_tsk_p2_reg_003_03.sh to confirm migration is successful.

### [ID tsk_p2_reg_003_03_work_item_07] Run pre_ci.sh
Run scripts/dev/pre_ci.sh to ensure conformance.

## Verification

```bash
# [ID tsk_p2_reg_003_03_work_item_01] [ID tsk_p2_reg_003_03_work_item_02]
# [ID tsk_p2_reg_003_03_work_item_03] [ID tsk_p2_reg_003_03_work_item_04]
# [ID tsk_p2_reg_003_03_work_item_05] [ID tsk_p2_reg_003_03_work_item_06]
test -x scripts/db/verify_tsk_p2_reg_003_03.sh && bash scripts/db/verify_tsk_p2_reg_003_03.sh > evidence/phase2/tsk_p2_reg_003_03.json || exit 1

# [ID tsk_p2_reg_003_03_work_item_01]
test -f schema/migrations/0125_project_boundaries.sql || exit 1

# [ID tsk_p2_reg_003_03_work_item_06]
test -f evidence/phase2/tsk_p2_reg_003_03.json || exit 1

# [ID tsk_p2_reg_003_03_work_item_07]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_003_03.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- table_exists
- geometry_type_correct
- foreign_keys_correct
- gist_index_exists
- append_only_trigger
- observed_paths

## Rollback

Revert migration:
```bash
git checkout schema/migrations/0125_project_boundaries.sql
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| FK to protected_areas fails | Low | Critical | Ensure TSK-P2-REG-003-02 is complete |
| FK to execution_records fails | Low | Critical | Ensure execution_records table exists |
| Geometry type incorrect | Low | Critical | Verify geometry(POLYGON, 4326) syntax |

## Approval

This task modifies schema. Requires human review before merge.
