# REM-2026-03-05 Semgrep Exit-7 + Security Lint Entrypoint Fix EXEC_LOG

origin_task_id: R-016

## repro_command
- `set -euo pipefail; semgrep --config=security/semgrep/rules.yml --quiet --error`

## verification_commands_run
- `set -euo pipefail; semgrep --config=security/semgrep/rules.yml --quiet --error`
- `scripts/security/lint_sql_injection.sh`

## final_status
- completed
