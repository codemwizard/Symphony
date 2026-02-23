# PERF Rebaseline Workflow (SHA-Locked)

This workflow is used when PERF-002 classifies a run as `SOFT_REGRESSION` or when a justified architecture change requires a new baseline.

## Inputs
- Current baseline: `docs/operations/perf_smoke_baseline.json`
- Current perf evidence: `evidence/phase1/perf_smoke_profile.json`

## Steps
1. Generate candidate baseline:
   - `scripts/perf/rebaseline.sh`
   - Output: `docs/operations/perf_smoke_baseline.candidate.json`
2. Compute candidate SHA256 (printed by script).
3. Fill approval file:
   - `docs/perf/perf_baseline_approval.yml`
   - Required fields:
     - `approved_by`
     - `approved_at_utc`
     - `candidate_baseline_sha256`
     - `reason`
4. Validate SHA lock:
   - `scripts/perf/verify_rebaseline_approval.sh`
5. If valid, promote candidate by replacing `docs/operations/perf_smoke_baseline.json` in a reviewed PR.

## Fail-closed rules
- Missing approval file with existing candidate baseline -> fail.
- SHA mismatch between candidate and approval -> fail.
- Missing required approval fields -> fail.
