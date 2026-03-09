# SEC-001 PLAN

Task: SEC-001
Owner role: SUPERVISOR
Depends on: FP-001
failure_signature: PHASE1.SEC.001.REQUIRED

## objective
Runtime dangerous-sink eradication

## scope
- Eliminate runtime shell-to-DB query execution from control-plane/app paths.
- Add sink-aware blocking rules for psql_scalar(...), psql_json_array(...), and subprocess psql -c usage.
- Add regression fixtures for multi-fragment SQL assembly and direct subprocess sink forms.

## acceptance_criteria
- No runtime shell-to-DB query path remains in production/control-plane path.
- Dangerous sink patterns fail CI.
- Fixture corpus proves detection of direct and composed sink forms.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/security/lint_app_sql_injection.sh`
- `python3 scripts/audit/validate_evidence.py --task SEC-001 --evidence evidence/security/sec_001_dangerous_sink_policy.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## no_touch_warnings
- Do not change ledger DB functions under this task.
- Do not keep a half-fixed shell-based fallback in production path.

## evidence_output
- `evidence/security/sec_001_dangerous_sink_policy.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/security/lint_app_sql_injection.sh`
- `python3 scripts/audit/validate_evidence.py --task SEC-001 --evidence evidence/security/sec_001_dangerous_sink_policy.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
