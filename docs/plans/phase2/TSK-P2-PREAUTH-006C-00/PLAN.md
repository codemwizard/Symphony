# TSK-P2-PREAUTH-006C-00: Create PLAN.md and verify alignment for C# read model marking

**Task:** TSK-P2-PREAUTH-006C-00
**Owner:** ARCHITECT
**Depends on:** TSK-P2-PREAUTH-006B-04
**Blocks:** TSK-P2-PREAUTH-006C-01
**Failure Signature**: PLAN.md missing or verification fails => CRITICAL_FAIL

## Objective

Create the PLAN.md for adding data_authority and audit_grade fields to C# read models. This task ensures the C# changes have architectural documentation and verification trace before implementation begins.

## Architectural Context

The DataAuthorityLevel enum and data_authority/audit_grade properties in C# read models provide cross-layer data authority contract between database and application layer.

## Pre-conditions

- TSK-P2-PREAUTH-006B-04 is complete
- Data authority triggers are in place
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- If verify_plan_semantic_alignment.py fails with orphaned nodes
- If the plan lacks explicit verifier specifications
- If the plan lacks negative test definitions

## Implementation Steps

### [ID tsk_p2_preauth_006c_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_preauth_006c_00_work_item_02] Document DataAuthorityLevel enum requirements
Document the DataAuthorityLevel enum requirements with values matching DB ENUM: Phase1IndicativeOnly, NonReproducible, DerivedUnverified, PolicyBoundUnsigned, AuthoritativeSigned, Superseded, Invalidated.

### [ID tsk_p2_preauth_006c_00_work_item_03] Document adding DataAuthority and AuditGrade to 3 read models
Document adding DataAuthority and AuditGrade properties to MonitoringRecord, AssetBatch, and StateTransition read models.

### [ID tsk_p2_preauth_006c_00_work_item_04] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-006C-00/meta.yml

## Verification

```bash
# DOCS_ONLY task - human review required
# No automated verification for plan creation
```


## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_006c_00.json with must_include fields:
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
rm docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| C# requirements incomplete | Low | High | Document all enum values and properties explicitly |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.
