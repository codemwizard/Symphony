# TSK-P1-254 PLAN — Rebaseline stale deterministic evidence

Task: TSK-P1-254
Owner: QA_VERIFIER
Depends on: TSK-P1-250, TSK-P1-251, TSK-P1-252, TSK-P1-253
failure_signature: PRECI.EVIDENCE.TSK-P1-254.STALE_REBASELINE_GAP
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Rebaseline the stale deterministic evidence set only after the active evidence
producers are stable. This task closes the gap where already-correct producers
still rewrite old evidence artifacts that were committed in the wrong shape.

## Constraints

- Start only after the upstream producer-stability tasks complete.
- Inventory the stale evidence set before regenerating anything.
- Preserve a verifier-backed record of which files were rebaselined and why.

## Approval References

- Apex authority: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- Remediation casefile: `docs/plans/phase1/REM-2026-04-06_evidence-push-nonconvergence/PLAN.md`
- Predecessor tasks: `docs/plans/phase1/TSK-P1-250/PLAN.md`, `docs/plans/phase1/TSK-P1-251/PLAN.md`, `docs/plans/phase1/TSK-P1-252/PLAN.md`, `docs/plans/phase1/TSK-P1-253/PLAN.md`

## Implementation Steps

- [ID tsk_p1_254_work_item_01] Inventory the stale deterministic evidence files still rewritten by the stabilized generators.
- [ID tsk_p1_254_work_item_02] Rebaseline those files once and remove legacy runtime-only fields.
- [ID tsk_p1_254_work_item_03] Add a verifier that proves the stale deterministic evidence set is empty afterward.
- [ID tsk_p1_254_work_item_04] Emit evidence capturing the stale-file inventory and empty-drift result.

## Verification Commands

```bash
# [ID tsk_p1_254_work_item_01] [ID tsk_p1_254_work_item_02] [ID tsk_p1_254_work_item_03] [ID tsk_p1_254_work_item_04]
bash scripts/audit/verify_tsk_p1_254.sh
# [ID tsk_p1_254_work_item_04]
python3 scripts/audit/validate_evidence.py --task TSK-P1-254 --evidence evidence/phase1/tsk_p1_254_evidence_rebaseline.json
# [ID tsk_p1_254_work_item_01] [ID tsk_p1_254_work_item_02] [ID tsk_p1_254_work_item_03]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```

## Evidence Paths

- `evidence/phase1/tsk_p1_254_evidence_rebaseline.json`
