# Remediation Execution Log

failure_signature: CI.SEC.DDL_LOCK_RISK.BROKEN_PIPE
origin_gate_id: SEC-G02

## repro_command
bash scripts/security/lint_ddl_lock_risk.sh

## error_observed
- CI failure: `scripts/security/lint_ddl_lock_risk.sh: line 155: printf: write error: Broken pipe`
- Exit code: 1

## change_applied
- Replaced pipeline-based evidence emission with a temp-file handoff in `scripts/security/lint_ddl_lock_risk.sh`.
  This removes `SIGPIPE` as a failure mode under `set -euo pipefail` and ensures CI/local parity.

## verification_commands_run
- bash scripts/security/lint_ddl_lock_risk.sh
- bash scripts/audit/run_phase0_ordered_checks.sh
- bash scripts/dev/pre_ci.sh

## final_status
PASS

