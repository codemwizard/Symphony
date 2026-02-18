# Execution Log (TSK-P0-146)

task_id: TSK-P0-146
invariant_id: INV-031
gate_id: INT-G22

Plan: `docs/plans/phase0/TSK-P0-146_inv031_parity_ordering/PLAN.md`

## Work performed
- Wired `scripts/audit/run_phase0_ordered_checks.sh` to run `scripts/db/tests/test_outbox_pending_indexes.sh` when `DATABASE_URL` is present (DB-capable contexts only).
- Updated CI `db_verify_invariants` job to install the same pinned toolchain as the mechanical job and to run `scripts/audit/run_phase0_ordered_checks.sh` with `DATABASE_URL` set, ensuring `INT-G22` is exercised under the canonical ordering in CI.

## Verification
- Local (non-DB): `bash scripts/audit/verify_ci_order.sh`
- CI: `db_verify_invariants` job runs `scripts/audit/run_phase0_ordered_checks.sh` with `DATABASE_URL` set (DB parity).

## Final Summary
`INT-G22` (INV-031) is now executed via the canonical Phase-0 ordered runner in both local pre-CI (DB-up) and CI (DB job), while DB-less CI jobs do not attempt DB access.

## Status
COMPLETED
