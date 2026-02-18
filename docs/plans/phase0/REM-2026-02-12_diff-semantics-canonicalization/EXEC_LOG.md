# Remediation Execution Log

failure_signature: P0.PARITY.DIFF_SEMANTICS.DRIFT
origin_task_id: TSK-P0-152

## repro_command
- bash scripts/dev/pre_ci.sh
- bash scripts/audit/run_phase0_ordered_checks.sh

## change_applied
- Added `scripts/lib/git_diff.sh` (range-only commit semantics via merge-base).
- Refactored `scripts/audit/enforce_change_rule.sh` and `scripts/audit/verify_baseline_change_governance.sh` to use the helper and remove staged/worktree unions.
- Added `scripts/audit/verify_diff_semantics_parity.sh` and wired into `scripts/audit/run_phase0_ordered_checks.sh`.
- Added TSK-P0-152..155 to `docs/PHASE0/phase0_contract.yml` and marked completed.

## verification_commands_run
- bash scripts/audit/verify_phase0_contract.sh
- bash scripts/audit/verify_diff_semantics_parity.sh
- bash scripts/audit/run_phase0_ordered_checks.sh

## final_status
PASS

