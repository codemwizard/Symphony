# PERF-005 PLAN

Task: PERF-005
Failure Signature: PHASE1.PERF.005.REGULATORY_TIMING_COMPLIANCE_REQUIRED

## Repro Command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Scope
- Add deterministic regulatory timing compliance verifier for Phase-1 rails.
- Emit `evidence/phase1/perf_005__regulatory_timing_compliance_gate.json`.
- Wire PERF-005 into pre_ci and Phase-1 contract/invariant registry.

## Verification Commands
- `bash scripts/perf/verify_perf_005.sh --evidence evidence/phase1/perf_005__regulatory_timing_compliance_gate.json`
- `python3 scripts/audit/validate_evidence.py --task PERF-005 --evidence evidence/phase1/perf_005__regulatory_timing_compliance_gate.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
