# Remediation Plan

failure_signature: CI.SEC.DDL_LOCK_RISK.BROKEN_PIPE
origin_gate_id: SEC-G02

## repro_command
bash scripts/security/lint_ddl_lock_risk.sh

## scope_boundary
In scope:
- Fix CI-only `Broken pipe` failure in `scripts/security/lint_ddl_lock_risk.sh`.
- Preserve Phase-0 parity semantics (same script behavior local vs CI).

Out of scope:
- Changing DDL lock-risk policy rules or allowlist semantics.
- Marking unrelated tasks as complete.

## change_plan
- Remove `pipefail`-sensitive `printf | python3` pipeline used for evidence emission.
- Replace with temp-file handoff so the evidence generator cannot fail via `SIGPIPE`.

## verification_commands_run
- bash scripts/security/lint_ddl_lock_risk.sh
- bash scripts/audit/run_phase0_ordered_checks.sh
- bash scripts/dev/pre_ci.sh

## final_status
OPEN

