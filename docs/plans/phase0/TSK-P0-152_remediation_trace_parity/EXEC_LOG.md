# Remediation Execution Log

failure_signature: CI.REMEDIATION_TRACE.PARITY_MISMATCH
origin_task_id: TSK-P0-152

## repro_command
bash scripts/audit/verify_remediation_trace.sh

## error_observed
CI was running the gate in `worktree` mode because the base ref differed (`origin/main` vs `rewrite/dotnet10-core`), so CI kept seeing tracked file changes that pre-push (forced to `range`) did not evaluate.

## change_applied
- Updated `scripts/audit/verify_remediation_trace.sh` to pick the right base ref (CI base/`@{upstream}`/ `origin/rewrite/dotnet10-core`), fetch it if necessary, and always diff `merge-base(BASE_REF, HEAD)...HEAD` so staged/worktree noise no longer affects parity.
- Set `scripts/dev/pre_ci.sh` to export the rewritten base ref before calling the gate and continue forcing `REMEDIATION_TRACE_DIFF_MODE=range`, thus mirroring CI’s commit-range diff.

## verification_commands_run
- REMEDIATION_TRACE_DIFF_MODE=range bash scripts/audit/verify_remediation_trace.sh
- scripts/dev/pre_ci.sh

## final_status
PASS
