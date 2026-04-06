# TSK-P1-252 PLAN — Stabilize human governance review signoff evidence

Task: TSK-P1-252
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-249
failure_signature: PRECI.EVIDENCE.TSK-P1-252.GOVERNANCE_SIGNOFF_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Remove reviewed-file drift from `evidence/phase1/human_governance_review_signoff.json`.
The signoff evidence must be stable for the same committed review scope so
adjacent branch churn does not re-dirty the tree during pre-push.

## Constraints

- Preserve the semantic meaning of signoff evidence for downstream consumers.
- If an inventory must remain, make its inclusion rules explicit and deterministic.
- Do not blur human review scope with unrelated branch-local file churn.

## Approval References

- Apex authority: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- Remediation casefile: `docs/plans/phase1/REM-2026-04-06_evidence-push-nonconvergence/PLAN.md`
- Predecessor task: `docs/plans/phase1/TSK-P1-249/PLAN.md`

## Implementation Steps

- [ID tsk_p1_252_work_item_01] Audit the signoff payload fields driven by reviewed-file drift.
- [ID tsk_p1_252_work_item_02] Replace or canonicalize the unstable reviewed-file projection.
- [ID tsk_p1_252_work_item_03] Add a focused repeated-run stability test for the signoff verifier.
- [ID tsk_p1_252_work_item_04] Emit evidence capturing the stable projection and repeated-run proof.

## Verification Commands

```bash
# [ID tsk_p1_252_work_item_01] [ID tsk_p1_252_work_item_02] [ID tsk_p1_252_work_item_03] [ID tsk_p1_252_work_item_04]
bash scripts/audit/tests/test_verify_human_governance_review_signoff.sh
# [ID tsk_p1_252_work_item_04]
python3 scripts/audit/validate_evidence.py --task TSK-P1-252 --evidence evidence/phase1/tsk_p1_252_governance_signoff_stability.json
# [ID tsk_p1_252_work_item_01] [ID tsk_p1_252_work_item_02] [ID tsk_p1_252_work_item_03]
PRE_CI_CONTEXT=1 bash scripts/audit/verify_human_governance_review_signoff.sh
```

## Evidence Paths

- `evidence/phase1/tsk_p1_252_governance_signoff_stability.json`
