# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.AUDIT.GATES

origin_gate_id: pre_ci.phase0_ordered_checks
repro_command: scripts/dev/pre_ci.sh
root_cause: `pre_ci.sh` reaches `scripts/audit/verify_exception_template.sh` and fails because `docs/invariants/exceptions/exception_change-rule_ddl_2026-04-30.md` has `expiry: 2026-05-14` without `closed_at`, which violates the validator rule that expired exceptions must either remain in the future or be explicitly closed.
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Root Cause Analysis
- `SKIP_DOTNET_QUALITY_LINT=1 scripts/dev/pre_ci.sh` cleared the WSL-specific dotnet quality lint issue and allowed the gate stack to continue far enough to expose the actual first failing artifact.
- The concrete failure is emitted by `scripts/audit/verify_exception_template.sh`:
  - `docs/invariants/exceptions/exception_change-rule_ddl_2026-04-30.md: expiry must be in the future unless closed_at is set (got 2026-05-14)`
- The exception file is now stale because its `expiry` is in the past relative to 2026-05-15, but it was never marked closed in front matter.

## Remediation Path
- Add the missing `closed_at` metadata to the expired exception artifact so it satisfies the validator's closure rule.
- Re-run the targeted exception validator first.
- Clear the regenerated DRD lockout after the casefile reflects the captured failure.
- Re-run `pre_ci.sh` with `SKIP_DOTNET_QUALITY_LINT=1` so the known WSL2 dotnet format issue does not mask later gates.

## Initial Hypotheses
- resolved: the first failing artifact after applying the WSL2 dotnet lint workaround is the expired exception metadata in `docs/invariants/exceptions/exception_change-rule_ddl_2026-04-30.md`
