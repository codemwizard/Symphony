# PERF-005 EXEC_LOG

failure_signature: PHASE1.PERF.005.REGULATORY_TIMING_COMPLIANCE_REQUIRED
origin_task_id: PERF-005
Plan: docs/plans/phase1/PERF-005/PLAN.md

## repro_command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## execution
- Added `scripts/perf/verify_perf_005.sh` to compute rail timing compliance from perf smoke profile.
- Added contract + invariant wiring so PERF-005 evidence is required in Phase-1 gate chain.
- Added task metadata and remediation trace plan/log artifacts.

## verification_commands_run
- `bash scripts/perf/verify_perf_005.sh --evidence evidence/phase1/perf_005__regulatory_timing_compliance_gate.json`
- `python3 scripts/audit/validate_evidence.py --task PERF-005 --evidence evidence/phase1/perf_005__regulatory_timing_compliance_gate.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## final_status
- completed
