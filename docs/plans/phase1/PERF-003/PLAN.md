# PERF-003 PLAN

Task: PERF-003  
Failure Signature: PHASE1.PERF.003.REBASELINE_SHA_LOCK_REQUIRED

## Repro Command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Scope
- Implement candidate baseline generation from perf smoke evidence.
- Enforce SHA-locked approval verification for baseline promotion.
- Emit deterministic PERF-003 evidence at `evidence/phase1/perf_003_rebaseline_sha_lock.json`.

## Verification Commands
- `bash scripts/audit/verify_perf_003_rebaseline_sha_lock.sh`
- `python3 scripts/audit/validate_evidence.py --task PERF-003 --evidence evidence/phase1/perf_003_rebaseline_sha_lock.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
