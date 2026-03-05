# REM-2026-03-05 R-016 SQLi lint entrypoint restoration EXEC_LOG

failure_signature: REM.SECURITY.MISSING_SQLI_LINT_ENTRYPOINT
origin_task_id: R-016
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## repro_command
- `bash scripts/audit/run_security_fast_checks.sh`

## actions_taken
- Added `scripts/security/lint_app_sql_injection.sh` with deterministic C#/Python SQLi scanning and fixture mode.
- Kept `scripts/security/lint_sql_injection.sh` as compatibility wrapper to the restored entrypoint.

## verification_commands_run
- `bash -n scripts/security/lint_app_sql_injection.sh`
- `scripts/security/lint_app_sql_injection.sh --fixtures app_sql_injection`
- `scripts/security/lint_sql_injection.sh`

## final_status
- completed
