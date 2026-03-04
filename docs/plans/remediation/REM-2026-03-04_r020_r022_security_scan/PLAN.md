# REM-2026-03-04 R-020..R-022 Security Scan Coverage

failure_signature: REM.SECURITY_REMEDIATION.SCAN_SCOPE_PARITY
origin_task_id: R-020

## repro_command
- `bash scripts/audit/verify_semgrep_languages.sh --require py --require cs`
- `bash scripts/audit/verify_ci_security_scan_includes.sh --require scripts/security/lint_app_sql_injection.sh --require semgrep`
- `bash scripts/audit/verify_security_scan_fail_closed.sh`
- `bash scripts/security/audit_lint_suppressions.sh`
- `bash scripts/audit/validate_scan_scope_contract.sh`
- `bash scripts/audit/verify_scan_scope.sh`

## verification_commands_run
- Same as repro_command.
