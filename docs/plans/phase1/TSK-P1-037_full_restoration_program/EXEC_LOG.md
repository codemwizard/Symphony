# TSK-P1-037 Execution Log

failure_signature: PHASE1.TSK.P1.037
origin_task_id: TSK-P1-037

## repro_command
`RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification_commands_run
- `bash scripts/dev/pre_ci.sh`
- `bash scripts/db/lint_migrations.sh`
- `bash scripts/security/lint_ddl_lock_risk.sh`
- `bash scripts/audit/check_sqlstate_map_drift.sh`
- `bash scripts/db/check_baseline_drift.sh`

## final_status
OPEN

Plan: `docs/plans/phase1/TSK-P1-037_full_restoration_program/PLAN.md`

## execution_notes
- PR-3 batch implemented forward-only anchor operational migration restoration via:
  - `schema/migrations/0033_anchor_sync_operational_enforcement.sql`
  - `schema/migrations/0034_anchor_sync_operational_fix_append_only_and_lease_time.sql`
- Baseline artifacts were refreshed after migration restore:
  - `schema/baseline.sql`
  - `schema/baselines/current/*`
  - `schema/baselines/2026-02-18/*`
- SQLSTATE map was updated with anchor-sync error codes:
  - `P7210`, `P7211`, `P7212`

- PR-4 batch restored anchor operational verifier/runtime wiring:
  - `scripts/db/verify_anchor_sync_operational_invariant.sh`
  - `scripts/db/tests/test_anchor_sync_operational.sh`
  - `docs/control_planes/CONTROL_PLANES.yml` (`INT-G29`)
  - `docs/PHASE1/phase1_contract.yml` (`INV-113` operational row)
  - `docs/invariants/INVARIANTS_MANIFEST.yml`
  - `docs/invariants/INVARIANTS_IMPLEMENTED.md`
  - `docs/invariants/INVARIANTS_QUICK.md`
  - `scripts/dev/pre_ci.sh`

- PR-4 verification rerun:
  - `bash scripts/dev/pre_ci.sh` -> PASS

- PR-5 batch restored pilot self-test harness orchestration:
  - `scripts/services/test_exception_case_pack_generator.sh`
  - `scripts/services/test_pilot_authz_tenant_boundary.sh`
  - `scripts/dev/run_phase1_pilot_harness.sh`
  - `scripts/dev/pre_ci.sh` (phase-1 self-test wiring)
  - `services/ledger-api/dotnet/src/LedgerApi/Program.cs` (`--self-test-case-pack`, `--self-test-authz`)

- PR-5 verification rerun:
  - `bash scripts/services/test_exception_case_pack_generator.sh` -> PASS
  - `bash scripts/services/test_pilot_authz_tenant_boundary.sh` -> PASS
  - `bash scripts/dev/run_phase1_pilot_harness.sh` -> PASS
  - `bash scripts/dev/pre_ci.sh` -> PASS
