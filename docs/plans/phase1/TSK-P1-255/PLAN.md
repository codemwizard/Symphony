# TSK-P1-255 PLAN — Prove end-to-end pre-push fixed-point convergence

Task: TSK-P1-255
Owner: QA_VERIFIER
Depends on: TSK-P1-254
failure_signature: PRECI.EVIDENCE.TSK-P1-255.PRE_PUSH_FIXED_POINT_PROOF
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Prove the actual push-blocking scenario is fixed end to end. The verifier must
change HEAD between runs, rerun `pre_ci`, and prove the evidence tree and full
worktree remain clean afterward.

## Constraints

- Use the repository-approved isolated temporary git-state strategy.
- Reject the invalid run-twice-without-commit shortcut.
- Preserve the user worktree and branch history while proving convergence.

## Approval References

- Apex authority: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- Remediation casefile: `docs/plans/phase1/REM-2026-04-06_evidence-push-nonconvergence/PLAN.md`
- Predecessor task: `docs/plans/phase1/TSK-P1-254/PLAN.md`

## Implementation Steps

- [ID tsk_p1_255_work_item_01] Build an isolated verifier harness for temporary HEAD changes.
- [ID tsk_p1_255_work_item_02] Execute the commit-between-runs fixed-point protocol and fail on any residual evidence or worktree drift.
- [ID tsk_p1_255_work_item_03] Add a guard test that rejects the invalid no-commit shortcut and enforces the required assertions.
- [ID tsk_p1_255_work_item_04] Emit evidence capturing before/after comparisons and the final zero-drift result.

## Verification Commands

```bash
# [ID tsk_p1_255_work_item_01] [ID tsk_p1_255_work_item_02] [ID tsk_p1_255_work_item_03] [ID tsk_p1_255_work_item_04]
bash scripts/audit/tests/test_zero_drift_pre_push.sh
# [ID tsk_p1_255_work_item_04]
python3 scripts/audit/validate_evidence.py --task TSK-P1-255 --evidence evidence/phase1/tsk_p1_255_pre_push_fixed_point.json
# [ID tsk_p1_255_work_item_01] [ID tsk_p1_255_work_item_02] [ID tsk_p1_255_work_item_03]
PRE_CI_CONTEXT=1 bash scripts/audit/verify_tsk_p1_255.sh
```

## Evidence Paths

- `evidence/phase1/tsk_p1_255_pre_push_fixed_point.json`
