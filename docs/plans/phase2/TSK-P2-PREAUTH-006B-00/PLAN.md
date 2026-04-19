# TSK-P2-PREAUTH-006B-00 PLAN — Create PLAN.md and verify alignment for data authority triggers

Task: TSK-P2-PREAUTH-006B-00
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-006A-04
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-006B-00.PLAN_CREATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

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

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

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
# [ID tsk_p2_preauth_006b_00_work_item_01]
test -f docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006b_00_work_item_02]
grep -q "enforce_monitoring_authority" docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md &&
grep -q "enforce_asset_batch_authority" docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md &&
grep -q "enforce_state_transition_authority" docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006b_00_work_item_03]
grep -q "trigger attachment points" docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md &&
grep -q "BEFORE INSERT OR UPDATE" docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006b_00_work_item_04]
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-006B-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-006B-00/meta.yml || exit 1
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
