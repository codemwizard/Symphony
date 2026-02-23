# PERF-001 PLAN

Task: PERF-001  
Failure Signature: PHASE1.PERF.001.ENGINE_METRICS_CAPTURE_REQUIRED

## Repro Command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Scope
- Capture engine-level metrics non-invasively from perf-smoke execution.
- Emit deterministic evidence at `evidence/phase1/perf_001_engine_metrics_capture.json`.
- Require PERF-001 evidence through Phase-1 contract.

## Verification Commands
- `bash scripts/audit/verify_perf_001_engine_metrics_capture.sh`
- `python3 scripts/audit/validate_evidence.py --task PERF-001 --evidence evidence/phase1/perf_001_engine_metrics_capture.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
