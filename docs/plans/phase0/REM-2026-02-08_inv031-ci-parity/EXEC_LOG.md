# Remediation Execution Log

failure_signature: CI.INV-031.OUTBOX_PENDING_INDEXES.MISSING_ON_FRESH_DB
origin_task_id: TSK-P0-146

## repro_command
bash scripts/db/tests/test_outbox_pending_indexes.sh

## error_observed
- `evidence/phase0/outbox_pending_indexes.json` reported `missing_index` on a fresh CI DB prior to migrations.

## change_applied
- Removed DB-job execution of `scripts/audit/run_phase0_ordered_checks.sh` before `scripts/db/verify_invariants.sh` in `.github/workflows/invariants.yml`.
- Kept `INV-031` verification under `scripts/db/verify_invariants.sh` (migrations-first).
- Kept `scripts/audit/run_phase0_ordered_checks.sh` mechanical-only (no DB assertions).
- Fixed local pre-push ordering: `scripts/audit/verify_phase0_contract_evidence_status.sh` now runs after DB verification in `scripts/dev/pre_ci.sh` (so required DB evidence exists before the contract evidence gate is evaluated).
- Enforced fresh DB parity locally: `scripts/dev/pre_ci.sh` now defaults to `FRESH_DB=1` and creates a per-run ephemeral database, runs migrations/tests against it, then drops it on exit.

## verification_commands_run
- scripts/dev/pre_ci.sh
- bash scripts/audit/run_phase0_ordered_checks.sh
- bash scripts/audit/verify_remediation_trace.sh

## final_status
PASS
