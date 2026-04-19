# TSK-P2-REG-003-00 PLAN — Create PLAN.md and verify alignment for PostGIS spatial tables

Task: TSK-P2-REG-003-00
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-000, TSK-P2-PREAUTH-007-05, TSK-P2-REG-001-02, TSK-P2-REG-002-02, TSK-P2-REG-004-01
failure_signature: PRE-PHASE2.REG.TSK-P2-REG-003-00.PLAN_CREATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the PLAN.md for the PostGIS spatial tables implementation (HIGHEST RISK - complex multi-operation). This task ensures the schema changes have architectural documentation and verification trace before implementation begins.

## Architectural Context

PostGIS spatial tables enable DNSH and K13 compliance checks via geometry operations. This includes PostGIS extension installation, protected_areas table, project_boundaries table, taxonomy_aligned column, and two trigger functions (enforce_dns_harm, enforce_k13_taxonomy_alignment).

## Pre-conditions

- TSK-P2-PREAUTH-000 (ADR for Spatial Capability Model) is complete
- TSK-P2-PREAUTH-007-05 (invariant registration) is complete
- TSK-P2-REG-001-02 (statutory_levy_registry) is complete
- TSK-P2-REG-002-02 (exchange_rate_audit_log) is complete
- TSK-P2-REG-004-01 (INV-169 promotion) is complete
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-REG-003-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

## Implementation Steps

### [ID tsk_p2_reg_003_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-REG-003-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_reg_003_00_work_item_02] Document PostGIS extension installation
Document CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public with PostGIS_version() verification.

### [ID tsk_p2_reg_003_00_work_item_03] Document protected_areas table
Document protected_areas table with geom geometry(POLYGON, 4326) NOT NULL, source_version_id UUID NOT NULL REFERENCES factor_registry(factor_id), append-only trigger, GIST index.

### [ID tsk_p2_reg_003_00_work_item_04] Document project_boundaries table
Document project_boundaries table with geom geometry(POLYGON, 4326) NOT NULL, dns_check_version_id UUID NOT NULL REFERENCES protected_areas(area_id), spatial_check_execution_id UUID NOT NULL REFERENCES execution_records(execution_id), GIST index, append-only trigger.

### [ID tsk_p2_reg_003_00_work_item_05] Document taxonomy_aligned column addition
Document ALTER TABLE projects ADD COLUMN taxonomy_aligned BOOLEAN NOT NULL DEFAULT false (must be BEFORE K13 trigger).

### [ID tsk_p2_reg_003_00_work_item_06] Document enforce_dns_harm() trigger
Document enforce_dns_harm() SECURITY DEFINER PL/pgSQL trigger with hardened search_path that raises GF057 on DNSH violation.

### [ID tsk_p2_reg_003_00_work_item_07] Document enforce_k13_taxonomy_alignment() trigger
Document enforce_k13_taxonomy_alignment() SECURITY DEFINER PL/pgSQL trigger that raises GF060 when taxonomy_aligned requires spatial_check_execution_id.

### [ID tsk_p2_reg_003_00_work_item_08] Document INV-178 registration
Document adding INV-178 to INVARIANTS_MANIFEST.yml with title: 'Project DNSH spatial check is DB-enforced via PostGIS with versioned dataset and execution binding'.

### [ID tsk_p2_reg_003_00_work_item_09] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-REG-003-00/PLAN.md --meta tasks/TSK-P2-REG-003-00/meta.yml

## Verification

```bash
# [ID tsk_p2_reg_003_00_work_item_01] [ID tsk_p2_reg_003_00_work_item_02] [ID tsk_p2_reg_003_00_work_item_03] [ID tsk_p2_reg_003_00_ac_01] [ID tsk_p2_reg_003_00_ac_02]
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-REG-003-00/PLAN.md --meta tasks/TSK-P2-REG-003-00/meta.yml || exit 1
# [ID tsk_p2_reg_003_00_work_item_01] [ID tsk_p2_reg_003_00_work_item_02] [ID tsk_p2_reg_003_00_work_item_03] [ID tsk_p2_reg_003_00_ac_01] [ID tsk_p2_reg_003_00_ac_02]
python3 scripts/audit/validate_evidence.py --task TSK-P2-REG-003-00 --evidence evidence/phase2/tsk_p2_reg_003_00.json || exit 1
# [ID tsk_p2_reg_003_00_work_item_01] [ID tsk_p2_reg_003_00_work_item_02] [ID tsk_p2_reg_003_00_work_item_03] [ID tsk_p2_reg_003_00_ac_01] [ID tsk_p2_reg_003_00_ac_02]
bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_003_00.json with must_include fields:
- task_id
- git_sha
- timestamp_utc
- status
- checks
- plan_path
- graph_validation_enabled
- no_orphans
- graph_connected
- observed_paths

## Rollback

Delete the PLAN.md file if it needs to be revised:
```bash
rm docs/plans/phase2/TSK-P2-REG-003-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| PostGIS requirements incomplete | Low | High | Document all geometry types and SRID explicitly |
| Trigger logic incorrect | Low | Critical | Review trigger functions carefully |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.
