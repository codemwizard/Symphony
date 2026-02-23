# PERF-006 PLAN

Task: PERF-006
Failure Signature: PHASE1.PERF.006.CLOSEOUT_TRANSLATION_LAYER_REQUIRED

## Repro Command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Scope
- Add PERF-006 verifier to enforce KPI settlement window compliance translation.
- Extend closeout verifier with KPI field checks required by PERF-006.
- Emit deterministic PERF-006 evidence artifact.

## Verification Commands
- `bash scripts/perf/verify_perf_006.sh --evidence evidence/phase1/perf_006__operational_risk_framework_translation_layer.json`
- `python3 scripts/audit/validate_evidence.py --task PERF-006 --evidence evidence/phase1/perf_006__operational_risk_framework_translation_layer.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
