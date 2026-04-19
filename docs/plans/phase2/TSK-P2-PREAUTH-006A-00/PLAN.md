# TSK-P2-PREAUTH-006A-00 PLAN — Create PLAN.md and verify alignment for data_authority ENUM

Task: TSK-P2-PREAUTH-006A-00
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-005-08
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-006A-00.PLAN_CREATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

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

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

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
# [ID tsk_p2_preauth_006a_00_work_item_01]
test -f docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006a_00_work_item_02]
grep -q "data_authority_level" docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md &&
grep -q "phase1_indicative_only" docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006a_00_work_item_03]
grep -q "monitoring_records" docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md &&
grep -q "asset_batches" docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md &&
grep -q "state_transitions" docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006a_00_work_item_04]
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-006A-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-006A-00/meta.yml || exit 1
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
