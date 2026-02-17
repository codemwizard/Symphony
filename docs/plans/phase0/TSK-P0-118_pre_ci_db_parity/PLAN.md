# PLAN — Wire CI DB Checks Into Local pre_ci For Parity (Phase-0)

## Task IDs
- TSK-P0-118
- TSK-P0-119

## Context
Tier-1 posture requires that developer local parity runner (`scripts/dev/pre_ci.sh`) match CI failure modes as closely as possible.

CI currently runs DB checks that were not executed locally by `pre_ci.sh`:
- `scripts/db/n_minus_one_check.sh` (INV-021, N-1 compatibility gate)
- `scripts/db/tests/test_no_tx_migrations.sh` (INV-041, no-tx migrations path)

This creates a parity gap where an invariant can pass locally but fail in CI.

## Scope
- Update `scripts/dev/pre_ci.sh` to run:
  - `scripts/db/n_minus_one_check.sh`
  - `scripts/db/tests/test_no_tx_migrations.sh`
- Keep existing ordering:
  - after DB migrations + `scripts/db/verify_invariants.sh`
  - within the same local docker-postgres environment.
- Record the change as a Phase-0 plan + tasks in the canonical registries.

## Non-Goals
- Do not change CI.
- Do not change DB migrations or runtime services.
- Do not solve diff-range parity in this task cluster (tracked separately).

## Files / Paths Touched
- `scripts/dev/pre_ci.sh`
- `docs/plans/phase0/TSK-P0-118_pre_ci_db_parity/PLAN.md`
- `docs/plans/phase0/TSK-P0-118_pre_ci_db_parity/EXEC_LOG.md`
- `docs/plans/phase0/INDEX.md`
- `docs/tasks/PHASE0_TASKS.md`
- `tasks/TSK-P0-118/meta.yml`
- `tasks/TSK-P0-119/meta.yml`
- `docs/PHASE0/phase0_contract.yml`

## Verification Commands
- `scripts/dev/pre_ci.sh`

## Expected Failure Modes
- Local DB user lacks `CREATEDB`, causing N-1/no-tx tests to fail (should be fixed by using the local docker DB role).
- Parity drift: CI runs a DB check not executed locally.

## Remediation Markers (Required By Gate)
failure_signature: P0.PRE_CI_DB_PARITY
origin_task_id: TSK-P0-118
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: PASS
