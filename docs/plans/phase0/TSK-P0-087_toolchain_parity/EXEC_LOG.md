# EXEC_LOG — Local/CI toolchain parity (pinned)

Task ID: TSK-P0-087

Plan: docs/plans/phase0/TSK-P0-087_toolchain_parity/PLAN.md

Status: completed

Actions taken:
- Updated pinned `RIPGREP_VERSION` to match the repo’s installed rg version.
- Added repo-local bootstrap script to install pinned Python deps into `./.venv` and pinned `rg` into `./.toolchain/bin`.
- Updated fast checks and toolchain verifier to prefer repo-local `.venv` Python and `.toolchain/bin/rg`.
- Updated `scripts/dev/pre_ci.sh` to bootstrap the toolchain before running gates.

Verification:
- `scripts/audit/bootstrap_local_ci_toolchain.sh`
- `scripts/audit/verify_ci_toolchain.sh` (evidence: `evidence/phase0/ci_toolchain.json`)
- `scripts/audit/run_invariants_fast_checks.sh`

Final summary:
- Local and CI now converge on the same pinned toolchain, and local fast checks pass without manual PATH exports.
