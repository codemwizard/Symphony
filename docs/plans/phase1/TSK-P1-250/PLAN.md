# TSK-P1-250 PLAN — Stabilize dotnet lint quality execution

Task: TSK-P1-250
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-249
failure_signature: PRECI.EVIDENCE.TSK-P1-250.DOTNET_RUNTIME_NONCONVERGENCE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Make the dotnet quality gate reach a reliable terminal state during local parity
execution and emit deterministic evidence summaries. This task closes the
pipeline-level risk that a long-running `dotnet format` stage leaves the branch
mid-regeneration and blocks fixed-point verification.

## Constraints

- Restrict changes to the dotnet quality gate and its focused regression test.
- Preserve diagnostically useful lint/build summaries after removing unstable raw output.
- Do not weaken the actual lint semantics just to make the gate appear stable.

## Approval References

- Apex authority: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- Remediation casefile: `docs/plans/phase1/REM-2026-04-06_evidence-push-nonconvergence/PLAN.md`
- Predecessor task: `docs/plans/phase1/TSK-P1-249/PLAN.md`

## Implementation Steps

- [ID tsk_p1_250_work_item_01] Audit the blocking `dotnet format` path and record the exact bounded behavior to install.
- [ID tsk_p1_250_work_item_02] Replace unstable raw-output evidence fields with deterministic summaries.
- [ID tsk_p1_250_work_item_03] Extend the focused regression test so it proves completion plus stable evidence emission.
- [ID tsk_p1_250_work_item_04] Emit task evidence capturing observed paths, hashes, command outputs, and execution trace.

## Verification Commands

```bash
# [ID tsk_p1_250_work_item_01] [ID tsk_p1_250_work_item_02] [ID tsk_p1_250_work_item_03] [ID tsk_p1_250_work_item_04]
bash scripts/security/tests/test_lint_dotnet_quality.sh
# [ID tsk_p1_250_work_item_04]
python3 scripts/audit/validate_evidence.py --task TSK-P1-250 --evidence evidence/phase1/tsk_p1_250_dotnet_lint_runtime_stability.json
# [ID tsk_p1_250_work_item_01] [ID tsk_p1_250_work_item_02] [ID tsk_p1_250_work_item_03]
PRE_CI_CONTEXT=1 bash scripts/security/lint_dotnet_quality.sh
```

## Evidence Paths

- `evidence/phase1/tsk_p1_250_dotnet_lint_runtime_stability.json`
