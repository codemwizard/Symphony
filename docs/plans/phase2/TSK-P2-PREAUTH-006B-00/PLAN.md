# TSK-P2-PREAUTH-006B-00: Create PLAN.md and verify alignment for data authority triggers

**Task:** TSK-P2-PREAUTH-006B-00
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-006A-04
**Blocks:** TSK-P2-PREAUTH-006B-01
**Failure Signature**: PLAN.md missing or verification fails => CRITICAL_FAIL

## Objective

Create the PLAN.md for 5 data authority trigger functions. This task ensures the trigger changes have architectural documentation and verification trace before implementation begins.

## Architectural Context

The 5 data authority trigger functions enforce data authority constraints across the system: enforce_monitoring_authority, enforce_asset_batch_authority, enforce_state_transition_authority, upgrade_authority_on_execution_binding, downgrade_authority_on_supersession.

## Pre-conditions

- TSK-P2-PREAUTH-006A-04 is complete
- Data authority ENUM and columns are in place
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- If verify_plan_semantic_alignment.py fails with orphaned nodes
- If the plan lacks explicit verifier specifications
- If the plan lacks negative test definitions

## Implementation Steps

### [ID tsk_p2_preauth_006b_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_preauth_006b_00_work_item_02] Document 5 trigger functions
Document the 5 trigger functions: enforce_monitoring_authority(), enforce_asset_batch_authority(), enforce_state_transition_authority(), upgrade_authority_on_execution_binding(), downgrade_authority_on_supersession().

### [ID tsk_p2_preauth_006b_00_work_item_03] Document trigger attachment points
Document trigger attachment points: BEFORE INSERT OR UPDATE on monitoring_records, asset_batches, state_transitions, AFTER INSERT on state_transitions.

### [ID tsk_p2_preauth_006b_00_work_item_04] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-006B-00/meta.yml

## Verification

```bash
# DOCS_ONLY task - human review required
# No automated verification for plan creation
```


## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006b_00.json with must_include fields:
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
rm docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| Trigger functions not documented | Low | Critical | Document all 5 trigger functions explicitly |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.
