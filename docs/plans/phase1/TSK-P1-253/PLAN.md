# TSK-P1-253 PLAN — Stabilize validation-family evidence outputs

Task: TSK-P1-253
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-251, TSK-P1-252
failure_signature: PRECI.EVIDENCE.TSK-P1-253.VALIDATION_OUTPUT_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Remove unstable inventory and runtime-sensitive payloads from the
validation-family evidence outputs. These files must be byte-stable for the same
committed tree so they stop re-dirtying the worktree during fixed-point checks.

## Constraints

- Preserve downstream enforcement meaning while reducing drift.
- Use counts, fingerprints, or canonicalized summaries where full mutable inventories are unnecessary.
- Keep the validation family internally consistent across all three outputs.

## Approval References

- Apex authority: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- Remediation casefile: `docs/plans/phase1/REM-2026-04-06_evidence-push-nonconvergence/PLAN.md`
- Predecessor tasks: `docs/plans/phase1/TSK-P1-251/PLAN.md`, `docs/plans/phase1/TSK-P1-252/PLAN.md`

## Implementation Steps

- [ID tsk_p1_253_work_item_01] Audit unstable payload fields across the validation family.
- [ID tsk_p1_253_work_item_02] Replace mutable inventories with deterministic summaries or canonicalized projections.
- [ID tsk_p1_253_work_item_03] Add a focused repeated-run stability test covering the validation-family outputs.
- [ID tsk_p1_253_work_item_04] Emit evidence capturing the stabilized inventory design and repeated-run proof.

## Verification Commands

```bash
# [ID tsk_p1_253_work_item_01] [ID tsk_p1_253_work_item_02] [ID tsk_p1_253_work_item_03] [ID tsk_p1_253_work_item_04]
bash scripts/audit/tests/test_evidence_validation_stability.sh
# [ID tsk_p1_253_work_item_04]
python3 scripts/audit/validate_evidence.py --task TSK-P1-253 --evidence evidence/phase1/tsk_p1_253_validation_output_stability.json
# [ID tsk_p1_253_work_item_01] [ID tsk_p1_253_work_item_02] [ID tsk_p1_253_work_item_03]
PRE_CI_CONTEXT=1 python3 scripts/audit/validate_evidence.py
```

## Evidence Paths

- `evidence/phase1/tsk_p1_253_validation_output_stability.json`
