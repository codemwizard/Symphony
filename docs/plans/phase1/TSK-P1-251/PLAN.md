# TSK-P1-251 PLAN — Stabilize remediation trace evidence

Task: TSK-P1-251
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-249
failure_signature: PRECI.EVIDENCE.TSK-P1-251.REMEDIATION_TRACE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Remove branch-diff-sensitive churn from `evidence/phase0/remediation_trace.json`.
The remediation trace must remain byte-stable for the same committed tree so it
stops masking the real remaining drift in the pre-push convergence path.

## Constraints

- Preserve enough remediation diagnostics to keep the trace useful.
- Prefer deterministic summaries, counts, or canonicalized projections over raw mutable inventories.
- Do not introduce a new dependency on uncommitted branch state.

## Approval References

- Apex authority: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- Remediation casefile: `docs/plans/phase1/REM-2026-04-06_evidence-push-nonconvergence/PLAN.md`
- Predecessor task: `docs/plans/phase1/TSK-P1-249/PLAN.md`

## Implementation Steps

- [ID tsk_p1_251_work_item_01] Audit the remediation trace payload fields that drift with branch-local changed-file state.
- [ID tsk_p1_251_work_item_02] Replace those fields with deterministic summaries or canonicalized projections.
- [ID tsk_p1_251_work_item_03] Add a repeated-run stability test for the remediation trace verifier.
- [ID tsk_p1_251_work_item_04] Emit evidence capturing the compared outputs and equality proof.

## Verification Commands

```bash
# [ID tsk_p1_251_work_item_01] [ID tsk_p1_251_work_item_02] [ID tsk_p1_251_work_item_03] [ID tsk_p1_251_work_item_04]
bash scripts/audit/tests/test_verify_remediation_trace.sh
# [ID tsk_p1_251_work_item_04]
python3 scripts/audit/validate_evidence.py --task TSK-P1-251 --evidence evidence/phase1/tsk_p1_251_remediation_trace_stability.json
# [ID tsk_p1_251_work_item_01] [ID tsk_p1_251_work_item_02] [ID tsk_p1_251_work_item_03]
PRE_CI_CONTEXT=1 bash scripts/audit/verify_remediation_trace.sh
```

## Evidence Paths

- `evidence/phase1/tsk_p1_251_remediation_trace_stability.json`
