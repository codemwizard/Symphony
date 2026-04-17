# TSK-P2-REG-002-00: Create PLAN.md and verify alignment for exchange_rate_audit_log

**Task:** TSK-P2-REG-002-00
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-007-05
**Blocks:** TSK-P2-REG-002-01
**Failure Signature**: PLAN.md missing or verification fails => CRITICAL_FAIL

## Objective

Create the PLAN.md for the exchange_rate_audit_log table implementation. This task ensures the schema changes have architectural documentation and verification trace before implementation begins.

## Architectural Context

The exchange_rate_audit_log table tracks exchange rates with high precision (NUMERIC(18,8)) for financial audit compliance.

## Pre-conditions

- TSK-P2-PREAUTH-007-05 is complete
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-REG-002-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- If verify_plan_semantic_alignment.py fails with orphaned nodes
- If the plan lacks explicit verifier specifications
- If the plan lacks negative test definitions

## Implementation Steps

### [ID tsk_p2_reg_002_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-REG-002-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_reg_002_00_work_item_02] Document exchange_rate_audit_log table requirements
Document table requirements including rate_value as NUMERIC(18,8) for precision.

### [ID tsk_p2_reg_002_00_work_item_03] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-REG-002-00/PLAN.md --meta tasks/TSK-P2-REG-002-00/meta.yml

## Verification

```bash
# [ID tsk_p2_reg_002_00_work_item_01] [ID tsk_p2_reg_002_00_work_item_02] [ID tsk_p2_reg_002_00_work_item_03] [ID tsk_p2_reg_002_00_ac_01] [ID tsk_p2_reg_002_00_ac_02]
python3 scripts/audit/verify_plan_semantic_alignment.py --meta tasks/TSK-P2-REG-002-00/meta.yml
# [ID tsk_p2_reg_002_00_work_item_01] [ID tsk_p2_reg_002_00_work_item_02] [ID tsk_p2_reg_002_00_work_item_03] [ID tsk_p2_reg_002_00_ac_01] [ID tsk_p2_reg_002_00_ac_02]
python3 scripts/audit/validate_evidence.py --task TSK-P2-REG-002-00 --evidence evidence/phase2/tsk_p2_reg_002_00.json
# [ID tsk_p2_reg_002_00_work_item_01] [ID tsk_p2_reg_002_00_work_item_02] [ID tsk_p2_reg_002_00_work_item_03] [ID tsk_p2_reg_002_00_ac_01] [ID tsk_p2_reg_002_00_ac_02]
bash scripts/dev/pre_ci.sh
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_002_00.json with must_include fields:
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
rm docs/plans/phase2/TSK-P2-REG-002-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| Precision requirements incomplete | Low | High | Document NUMERIC(18,8) explicitly |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.
