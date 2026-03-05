# REM-2026-03-05 Semgrep Exit-7 + Security Lint Entrypoint Fix

failure_signature: REM.SECURITY.SEMGREP.CONFIG_INVALID_AND_MISSING_SQLI_WRAPPER
origin_task_id: R-016

## repro_command
- `set -euo pipefail; semgrep --config=security/semgrep/rules.yml --quiet --error`
- `bash scripts/audit/run_security_fast_checks.sh`

## verification_commands_run
- Same as repro_command.
