# TSK-P2-PREAUTH-006C-00 PLAN — Create PLAN.md and verify alignment for C# read model marking

Task: TSK-P2-PREAUTH-006C-00
Owner: ARCHITECT
Depends on: TSK-P2-PREAUTH-006B-04
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-006C-00.PLAN_CREATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

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

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

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
# [ID tsk_p2_preauth_006c_00_work_item_01]
test -f docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006c_00_work_item_02]
grep -q "DataAuthorityLevel" docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md &&
grep -q "Phase1IndicativeOnly" docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006c_00_work_item_03]
grep -q "MonitoringRecord" docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md &&
grep -q "AssetBatch" docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md &&
grep -q "StateTransition" docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_006c_00_work_item_04]
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-006C-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-006C-00/meta.yml || exit 1
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
