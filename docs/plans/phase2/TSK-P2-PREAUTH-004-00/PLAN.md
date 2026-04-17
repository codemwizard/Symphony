# TSK-P2-PREAUTH-004-00: Create PLAN.md and verify alignment for policy_decisions

**Task:** TSK-P2-PREAUTH-004-00
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-003-02
**Blocks:** TSK-P2-PREAUTH-004-01
**Failure Signature**: PLAN.md missing or verification fails => CRITICAL_FAIL

## Objective

Create the PLAN.md for the policy_decisions and state_rules tables. This task ensures the schema changes have architectural documentation and verification trace before implementation begins.

## Architectural Context

The policy_decisions table tracks policy decisions with timestamps. The state_rules table defines state transition rules with conditions. Without these tables, the system cannot enforce state machine rules or track policy decisions.

## Pre-conditions

- TSK-P2-PREAUTH-003-02 is complete
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- If verify_plan_semantic_alignment.py fails with orphaned nodes
- If the plan lacks explicit verifier specifications
- If the plan lacks negative test definitions

## Implementation Steps

### [ID tsk_p2_preauth_004_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_preauth_004_00_work_item_02] Document policy_decisions table requirements
Document the policy_decisions table requirements including columns: policy_decision_id UUID PRIMARY KEY, project_id UUID NOT NULL, decision_type VARCHAR NOT NULL, decision_timestamp TIMESTAMPTZ NOT NULL, and indexes on project_id.

### [ID tsk_p2_preauth_004_00_work_item_03] Document state_rules table requirements
Document the state_rules table requirements including columns: state_rule_id UUID PRIMARY KEY, from_state VARCHAR NOT NULL, to_state VARCHAR NOT NULL, rule_condition TEXT NOT NULL, and UNIQUE constraint on (from_state, to_state).

### [ID tsk_p2_preauth_004_00_work_item_04] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-004-00/meta.yml

## Verification

```bash
# DOCS_ONLY task - human review required
# No automated verification for plan creation
```


## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_004_00.json with must_include fields:
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
rm docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| Table requirements incomplete | Low | High | Document all columns and constraints explicitly |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.
