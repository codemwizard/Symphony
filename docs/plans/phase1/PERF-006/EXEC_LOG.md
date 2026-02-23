# PERF-006 EXEC_LOG

failure_signature: PHASE1.PERF.006.CLOSEOUT_TRANSLATION_LAYER_REQUIRED
origin_task_id: PERF-006
Plan: docs/plans/phase1/PERF-006/PLAN.md

## repro_command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## execution
- Added `scripts/perf/verify_perf_006.sh` to regenerate KPI evidence in PERF-006 mode and assert translation layer guarantees.
- Extended `scripts/audit/verify_product_kpi_readiness.sh` to include settlement window compliance KPI + PERF-005 reference.
- Extended `scripts/audit/verify_phase1_closeout.sh` to enforce PERF-006 KPI fields at closeout.
- Wired PERF-006 verifier into Phase-1 pre_ci and contract/invariant registries.

## verification_commands_run
- `bash scripts/perf/verify_perf_006.sh --evidence evidence/phase1/perf_006__operational_risk_framework_translation_layer.json`
- `python3 scripts/audit/validate_evidence.py --task PERF-006 --evidence evidence/phase1/perf_006__operational_risk_framework_translation_layer.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## final_status
- completed
