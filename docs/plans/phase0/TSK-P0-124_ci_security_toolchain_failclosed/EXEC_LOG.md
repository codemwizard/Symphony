# Execution Log (TSK-P0-124)

failure_signature: CI.SECURITY.TOOLCHAIN.DRIFT_SEMGREP_NOT_ENFORCED
origin_gate_id: SEC-G06
repro_command: bash scripts/audit/verify_ci_toolchain.sh

Plan: docs/plans/phase0/TSK-P0-124_ci_security_toolchain_failclosed/PLAN.md

## Change Applied
- Extended `scripts/audit/verify_ci_toolchain.sh` to check Semgrep presence and pinned version.
- Updated `scripts/security/run_semgrep_sast.sh` to fail (not SKIPPED) when Semgrep is missing in CI (`GITHUB_ACTIONS=true`).
- Updated `.github/workflows/invariants.yml` security_scan job to run `scripts/audit/verify_ci_toolchain.sh` after installing the pinned toolchain.

## Verification Commands Run
verification_commands_run:
- bash scripts/audit/verify_ci_toolchain.sh
- bash scripts/security/run_semgrep_sast.sh

## Status
final_status: OPEN

## Final Summary
- Root cause: security job could degrade to SKIPPED Semgrep without CI failing.
- Fix: verify pinned Semgrep in CI toolchain gate and fail closed if missing/drifted.
- Verification: local checks pass; CI should now fail if Semgrep is absent and pass when installed.

