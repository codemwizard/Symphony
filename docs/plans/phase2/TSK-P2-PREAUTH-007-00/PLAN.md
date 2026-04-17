# TSK-P2-PREAUTH-007-00: Create PLAN.md and verify alignment for invariant registration

**Task:** TSK-P2-PREAUTH-007-00
**Owner:** INVARIANTS_CURATOR
**Depends on:** TSK-P2-PREAUTH-006C-03
**Blocks:** TSK-P2-PREAUTH-007-01
**Failure Signature**: PLAN.md missing or verification fails => CRITICAL_FAIL

## Objective

Create the PLAN.md for registering 6 new invariants (INV-170 through INV-175) for the pre-phase2 implementation. This task ensures the invariant registration has architectural documentation and verification trace before implementation begins.

## Architectural Context

The 6 new invariants (INV-170 through INV-175) provide governance coverage for the pre-phase2 implementation: INV-170 (interpretation_pack temporal uniqueness), INV-171 (execution truth anchoring), INV-172 (state machine enforcement), INV-173 (data authority contract), INV-174 (append-only state transitions), INV-175 (execution binding requirement).

## Pre-conditions

- TSK-P2-PREAUTH-006C-03 is complete
- All schema changes are in place
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- If verify_plan_semantic_alignment.py fails with orphaned nodes
- If the plan lacks explicit verifier specifications
- If the plan lacks negative test definitions

## Implementation Steps

### [ID tsk_p2_preauth_007_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_preauth_007_00_work_item_02] Document registering 6 new invariants
Document registering INV-170 (interpretation_pack temporal uniqueness), INV-171 (execution truth anchoring), INV-172 (state machine enforcement), INV-173 (data authority contract), INV-174 (append-only state transitions), INV-175 (execution binding requirement).

### [ID tsk_p2_preauth_007_00_work_item_03] Document adding entries to INVARIANTS_MANIFEST.yml
Document adding entries to INVARIANTS_MANIFEST.yml with status: draft, enforcement_location, and verification_command for each invariant.

### [ID tsk_p2_preauth_007_00_work_item_04] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-007-00/meta.yml

## Verification

```bash
# DOCS_ONLY task - human review required
# No automated verification for plan creation
```


## Evidence Contract

Evidence will be emitted to evidence/phase2/tsk_p2_preauth_007_00.json with must_include fields:
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
rm docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md
```

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| PLAN.md fails semantic alignment | Low | Medium | Fix orphaned work items before proceeding |
| Invariant requirements incomplete | Low | High | Document all 6 invariants explicitly |

## Approval

This is a DOCS_ONLY task. No regulated surface changes. No approval required beyond verification passing.
