# PERF-003 EXEC_LOG

failure_signature: PHASE1.PERF.003.REBASELINE_SHA_LOCK_REQUIRED
origin_task_id: PERF-003
Plan: docs/plans/phase1/PERF-003/PLAN.md

## repro_command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## execution
- Added `scripts/perf/rebaseline.sh` to generate candidate baseline files from smoke evidence.
- Added `scripts/perf/verify_rebaseline_approval.sh` to enforce SHA-locked approval checks.
- Added `scripts/audit/verify_perf_003_rebaseline_sha_lock.sh` with pass/mismatch fixtures and evidence emission.
- Wired PERF-003 verification into Phase-1 pre_ci sequence and registered contract/invariant entries.

## verification_commands_run
- `bash scripts/audit/verify_perf_003_rebaseline_sha_lock.sh`
- `python3 scripts/audit/validate_evidence.py --task PERF-003 --evidence evidence/phase1/perf_003_rebaseline_sha_lock.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## final_status
- completed
