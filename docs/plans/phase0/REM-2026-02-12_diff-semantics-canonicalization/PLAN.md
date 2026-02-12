# Remediation Plan

failure_signature: P0.PARITY.DIFF_SEMANTICS.DRIFT
origin_task_id: TSK-P0-152
first_observed_utc: 2026-02-12T00:00:00Z

## repro_command
- bash scripts/dev/pre_ci.sh
- bash scripts/audit/run_phase0_ordered_checks.sh

## scope_boundary
In scope:
- Centralize git diff semantics for parity-critical gates.
- Enforce range-only diff semantics in enforcement (no staged/worktree fallbacks).
- Add a regression verifier to prevent drift.

Out of scope:
- Changing invariant meaning or evidence contract semantics.

## proposed_fix
- Add `scripts/lib/git_diff.sh` as the shared helper (range-only).
- Refactor parity-critical diff-based gates to use the helper.
- Add `scripts/audit/verify_diff_semantics_parity.sh` and wire it into ordered checks.

## verification_commands_run
- bash scripts/audit/verify_phase0_contract.sh
- bash scripts/audit/verify_diff_semantics_parity.sh
- bash scripts/audit/run_phase0_ordered_checks.sh

## final_status
OPEN

