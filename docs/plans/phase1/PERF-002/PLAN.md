# PERF-002 PLAN

Task: PERF-002  
Failure Signature: PHASE1.PERF.002.REGRESSION_DETECTION_WARMUP_REQUIRED

## Repro Command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Scope
- Add mandatory warmup to perf smoke execution and fail closed if warmup fails.
- Add baseline-driven smart regression classification (PASS/SOFT_REGRESSION/HARD_REGRESSION).
- Emit deterministic PERF-002 evidence at `evidence/phase1/perf_002_regression_detection_warmup.json`.

## Verification Commands
- `bash scripts/audit/verify_perf_002_regression_detection_warmup.sh`
- `python3 scripts/audit/validate_evidence.py --task PERF-002 --evidence evidence/phase1/perf_002_regression_detection_warmup.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
