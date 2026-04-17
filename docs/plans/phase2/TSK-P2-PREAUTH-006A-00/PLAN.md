# TSK-P2-PREAUTH-006A-00: Create PLAN.md and verify alignment for data_authority ENUM

**Task:** TSK-P2-PREAUTH-006A-00
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-005-08
**Blocks:** TSK-P2-PREAUTH-006A-01
**Failure Signature**: PLAN.md missing or verification fails => CRITICAL_FAIL

## Objective

Create the PLAN.md for the data_authority_level ENUM type and adding data_authority columns to monitoring_records, asset_batches, and state_transitions. This task ensures the schema changes have architectural documentation and verification trace before implementation begins.

## Architectural Context

The data_authority_level ENUM type tracks data authority levels across the system. Adding data_authority columns to monitoring_records, asset_batches, and state_transitions enables cross-layer data authority contract enforcement.

## Pre-conditions

- TSK-P2-PREAUTH-005-08 is complete
- State machine + trigger layer is complete
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- If verify_plan_semantic_alignment.py fails with orphaned nodes
- If the plan lacks explicit verifier specifications
- If the plan lacks negative test definitions

## Implementation Steps

### [ID tsk_p2_preauth_006a_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_preauth_006a_00_work_item_02] Document data_authority_level ENUM requirements
Document the data_authority_level ENUM type requirements with values: 'phase1_indicative_only', 'non_reproducible', 'derived_unverified', 'policy_bound_unsigned', 'authoritative_signed', 'superseded', 'invalidated'.

### [ID tsk_p2_preauth_006a_00_work_item_03] Document adding data_authority columns to 3 tables
Document adding data_authority, audit_grade, and authority_explanation columns to monitoring_records, asset_batches, and state_transitions tables with appropriate defaults.

### [ID tsk_p2_preauth_006a_00_work_item_04] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-006A-00/meta.yml

## Verification

```bash
# DOCS_ONLY task - human review required
# No automated verification for plan creation
```


## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006a_00.json with must_include fields:
- observed_paths
- task_id
- git_sha
- timestamp_utc
- status
- checks
- plan_path
- graph_validation_enabled
- no_orphans
- graph_connected

## Rollback

Delete the PLAN.md file if it needs to be revised:
```bash
rm docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| ENUM values incomplete | Low | High | Document all 7 values explicitly |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.
