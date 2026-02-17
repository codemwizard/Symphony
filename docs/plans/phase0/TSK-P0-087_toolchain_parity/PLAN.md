# PLAN — Local/CI toolchain parity (pinned)

## Task IDs
- TSK-P0-087

## Scope
- Ensure local and CI use the same pinned versions for the Phase-0 “mechanical gates” toolchain.
- Remove reliance on system Python packages for repo checks by preferring a repo-managed virtualenv.
- Ensure `verify_ci_toolchain.sh` and `run_invariants_fast_checks.sh` pass locally without manual PATH hacks.

## Non-Goals
- No changes to application runtime services.
- No changes to security posture beyond toolchain pinning and local bootstrap.
- No changes to CI job structure beyond consuming the shared pin file (already in place).

## Files / Paths Touched
- `scripts/audit/ci_toolchain_versions.env`
- `scripts/audit/bootstrap_local_ci_toolchain.sh` (new)
- `scripts/audit/verify_ci_toolchain.sh`
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/dev/pre_ci.sh`
- `docs/tasks/PHASE0_TASKS.md`
- `tasks/TSK-P0-087/meta.yml`
- `docs/PHASE0/phase0_contract.yml`
- `docs/plans/phase0/INDEX.md`

## Gates / Verifiers
- `scripts/audit/verify_ci_toolchain.sh` -> `evidence/phase0/ci_toolchain.json` (SEC-G06)
- `scripts/audit/run_invariants_fast_checks.sh` (must pass locally after bootstrap)

## Expected Failure Modes
- Local environment uses a different `jsonschema`/`rg` version than CI; mechanical gates diverge.
- Toolchain check passes in CI but fails locally (or vice versa).
- Toolchain check depends on global Python site-packages instead of repo-managed pins.
- Evidence file missing.

## Verification Commands
- `scripts/audit/bootstrap_local_ci_toolchain.sh`
- `scripts/audit/verify_ci_toolchain.sh`
- `scripts/audit/run_invariants_fast_checks.sh`

## Dependencies
- TSK-P0-073 (pre-CI wiring framework exists)
