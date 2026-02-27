# PERF-004 Plan

failure_signature: P1.PERF.004.CLOSEOUT_EXTENSION_REQUIRED
origin_task_id: PERF-004

## repro_command
- scripts/perf/verify_perf_004.sh --evidence evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json

## scope
- Extend closeout governance using contract-declared perf evidence paths.
- Add verifier-backed evidence that perf paths are enforced inputs to closeout.

## verification_commands_run
- scripts/perf/verify_perf_004.sh --evidence evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json
- python3 scripts/audit/validate_evidence.py --task PERF-004 --evidence evidence/phase1/perf_004__perf_contracts_closeout_checks_extends_verify.json
