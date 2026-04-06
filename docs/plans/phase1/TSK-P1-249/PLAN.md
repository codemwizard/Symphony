# TSK-P1-249 PLAN — Patch remaining live timestamps and runtime-only evidence values

Task: TSK-P1-249
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-248
failure_signature: PRECI.EVIDENCE.TSK-P1-249.RUNTIME_VALUE_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Remove the remaining deterministic drift sources from the evidence pipeline
after the git identity clamp is in place. The targeted producers must emit only
stable timestamps, stable git metadata, and stable payload summaries under
deterministic mode.

## Constraints

- Restrict code changes to the evidence producers exercised by pre_ci.
- Preserve enough diagnostic value for failures after stripping unstable fields.
- Do not reintroduce live git or timestamp values through helper-independent code.

## Approval References

- Apex authority: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- Predecessor task: `docs/plans/phase1/TSK-P1-248/PLAN.md`

## Implementation Steps

- [ID tsk_p1_249_work_item_01] Clamp deterministic-only metadata in verify_agent_conformance.sh.
- [ID tsk_p1_249_work_item_02] Canonicalize reported PII lint roots so evidence does not leak /tmp paths.
- [ID tsk_p1_249_work_item_03] Replace raw dotnet stdout evidence with stable summary counters.
- [ID tsk_p1_249_work_item_04] Add a verifier that inspects the targeted producers and generated evidence for forbidden dynamic fields.

## Verification Commands

```bash
# [ID tsk_p1_249_work_item_01] [ID tsk_p1_249_work_item_02] [ID tsk_p1_249_work_item_03] [ID tsk_p1_249_work_item_04] [ID tsk_p1_249_work_item_05]
bash scripts/audit/verify_tsk_p1_249.sh
# [ID tsk_p1_249_work_item_05]
python3 scripts/audit/validate_evidence.py --task TSK-P1-249 --evidence evidence/phase1/tsk_p1_249_runtime_value_stabilization.json
# [ID tsk_p1_249_work_item_01] [ID tsk_p1_249_work_item_02] [ID tsk_p1_249_work_item_03] [ID tsk_p1_249_work_item_04]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```

## Evidence Paths

- `evidence/phase1/tsk_p1_249_runtime_value_stabilization.json`
