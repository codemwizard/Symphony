# PERF-002 EXEC_LOG

failure_signature: PHASE1.PERF.002.REGRESSION_DETECTION_WARMUP_REQUIRED
origin_task_id: PERF-002
Plan: docs/plans/phase1/PERF-002/PLAN.md

## repro_command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## execution
- Added mandatory warmup execution to `scripts/audit/run_perf_smoke.sh`.
- Added baseline-driven classification with PASS/SOFT_REGRESSION/HARD_REGRESSION using declared baseline thresholds.
- Added `scripts/audit/verify_perf_002_regression_detection_warmup.sh` and wired it into Phase-1 pre_ci.
- Registered PERF-002 evidence/verifier in Phase-1 contract and invariant registry.

## verification_commands_run
- `bash scripts/audit/verify_perf_002_regression_detection_warmup.sh`
- `python3 scripts/audit/validate_evidence.py --task PERF-002 --evidence evidence/phase1/perf_002_regression_detection_warmup.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## final_status
- completed

## Final summary
- PERF-002 now enforces mandatory warmup before perf measurements and emits baseline-driven regression classification evidence (PASS/SOFT/HARD) with fail-closed hard-regression behavior.
