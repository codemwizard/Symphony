# TSK-P2-PREAUTH-007-00 PLAN — Create PLAN.md and verify alignment for invariant registration + CI wiring

Task: TSK-P2-PREAUTH-007-00
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-PREAUTH-001-02, TSK-P2-PREAUTH-005-08, TSK-P2-PREAUTH-006C-03
failure_signature: PRE-PHASE2.PREAUTH.TSK-P2-PREAUTH-007-00.PLAN_CREATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create the PLAN.md for registering INV-175 (data_authority_enforced), INV-176 (state_machine_enforced), INV-177 (phase1_boundary_marked), promoting INV-165/167 to implemented status, and wiring new verifier scripts into pre_ci.sh. This task ensures the invariant registration and CI wiring has architectural documentation and verification trace before implementation begins.

## Architectural Context

INV-175 enforces data_authority via ENUM and triggers in migration 0122. INV-176 enforces state machine enforcement via triggers in migration 0120. INV-177 enforces phase1_boundary_marked in C# read models verified by 006C tasks. INV-165/167 are promoted from draft to implemented status. The three new verifiers (verify_tsk_p2_preauth_006a.sh, verify_tsk_p2_preauth_005_08.sh, verify_tsk_p2_preauth_006c.sh) are wired into pre_ci.sh to enable continuous enforcement.

## Pre-conditions

- TSK-P2-PREAUTH-001-02 is complete
- TSK-P2-PREAUTH-005-08 is complete
- TSK-P2-PREAUTH-006C-03 is complete
- All schema changes are in place
- PLAN_TEMPLATE.md exists at docs/contracts/templates/PLAN_TEMPLATE.md

## Files to Change

| Path | Type | Change |
|------|------|--------|
| docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md | CREATE | Plan document with all required sections |

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

## Implementation Steps

### [ID tsk_p2_preauth_007_00_work_item_01] Create PLAN.md from template
Create PLAN.md at docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md from PLAN_TEMPLATE.md with objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, rollback, and risk sections.

### [ID tsk_p2_preauth_007_00_work_item_02] Document registering INV-175/176/177
Document registering INV-175 (data_authority_enforced), INV-176 (state_machine_enforced), INV-177 (phase1_boundary_marked) with their enforcement locations and verification commands.

### [ID tsk_p2_preauth_007_00_work_item_03] Document promoting INV-165/167
Document promoting INV-165 and INV-167 from draft to implemented status in INVARIANTS_MANIFEST.yml.

### [ID tsk_p2_preauth_007_00_work_item_04] Document wiring verifiers into pre_ci.sh
Document wiring verify_tsk_p2_preauth_006a.sh, verify_tsk_p2_preauth_005_08.sh, verify_tsk_p2_preauth_006c.sh into pre_ci.sh for continuous enforcement.

### [ID tsk_p2_preauth_007_00_work_item_05] Run verify_plan_semantic_alignment.py
Run verify_plan_semantic_alignment.py to validate proof graph integrity: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-007-00/meta.yml

## Verification

```bash
# [ID tsk_p2_preauth_007_00_work_item_01]
test -f docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_007_00_work_item_02]
grep -q "INV-175" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md &&
grep -q "INV-176" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md &&
grep -q "INV-177" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_007_00_work_item_03]
grep -q "INV-165" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md &&
grep -q "INV-167" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md &&
grep -q "implemented" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_007_00_work_item_04]
grep -q "pre_ci.sh" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md &&
grep -q "verify_tsk_p2_preauth_006a.sh" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md &&
grep -q "verify_tsk_p2_preauth_005_08.sh" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md &&
grep -q "verify_tsk_p2_preauth_006c.sh" docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_007_00_work_item_05]
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-007-00/meta.yml || exit 1
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
