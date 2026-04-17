# TSK-P2-REG-004-00: Create PLAN.md and verify alignment for INV-169 promotion

**Task:** TSK-P2-REG-004-00
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-007-05
**Blocks:** TSK-P2-REG-004-01
**Failure Signature**: PLAN.md missing or verification fails => CRITICAL_FAIL

## Objective

Create the PLAN.md for verifying check_reg26_separation() function and promoting INV-169. This task ensures the invariant promotion has architectural documentation and verification trace before implementation begins.

## Architectural Context

INV-169 enforces REG26 separation via check_reg26_separation() function. This task promotes the invariant to implemented status after verification.

## Pre-conditions

- TSK-P2-PREAUTH-007-05 is complete
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-REG-004-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- If verify_plan_semantic_alignment.py fails with orphaned nodes
- If the plan lacks explicit verifier specifications
- If the plan lacks negative test definitions

## Implementation Steps

### [ID tsk_p2_reg_004_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-REG-004-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_reg_004_00_work_item_02] Document check_reg26_separation() function verification
Document exact psql query for verifying check_reg26_separation() function exists: psql -c "SELECT 1 FROM pg_proc WHERE proname='check_reg26_separation'" | grep -q '1 row'.

### [ID tsk_p2_reg_004_00_work_item_03] Document INV-169 promotion requirements
Document updating INV-169 in INVARIANTS_MANIFEST.yml to status: implemented.

### [ID tsk_p2_reg_004_00_work_item_04] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-REG-004-00/PLAN.md --meta tasks/TSK-P2-REG-004-00/meta.yml

## Verification

```bash
# [ID tsk_p2_reg_004_00_work_item_01] [ID tsk_p2_reg_004_00_work_item_02] [ID tsk_p2_reg_004_00_work_item_03] [ID tsk_p2_reg_004_00_work_item_04] [ID tsk_p2_reg_004_00_ac_01] [ID tsk_p2_reg_004_00_ac_02]
python3 scripts/audit/verify_plan_semantic_alignment.py --meta tasks/TSK-P2-REG-004-00/meta.yml
# [ID tsk_p2_reg_004_00_work_item_01] [ID tsk_p2_reg_004_00_work_item_02] [ID tsk_p2_reg_004_00_work_item_03] [ID tsk_p2_reg_004_00_work_item_04] [ID tsk_p2_reg_004_00_ac_01] [ID tsk_p2_reg_004_00_ac_02]
python3 scripts/audit/validate_evidence.py --task TSK-P2-REG-004-00 --evidence evidence/phase2/tsk_p2_reg_004_00.json
# [ID tsk_p2_reg_004_00_work_item_01] [ID tsk_p2_reg_004_00_work_item_02] [ID tsk_p2_reg_004_00_work_item_03] [ID tsk_p2_reg_004_00_work_item_04] [ID tsk_p2_reg_004_00_ac_01] [ID tsk_p2_reg_004_00_ac_02]
bash scripts/dev/pre_ci.sh
```

## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_reg_004_00.json with must_include fields:
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
rm docs/plans/phase2/TSK-P2-REG-004-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| INV-169 promotion requirements incomplete | Low | High | Document exact verifier specifications |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.
