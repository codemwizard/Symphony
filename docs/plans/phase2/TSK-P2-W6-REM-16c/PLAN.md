# Implementation Plan: TSK-P2-W6-REM-16c

## Mission
Eliminate baseline drift between the governance registry and physical schema by renumbering the legacy `P7601` error to `P7504`.

## Constraints
1. **Mathematical Proof:** Must query `pg_proc` to prove `P7601` is gone and `P7504` is present in `issue_adjustment_with_recipient`.
2. **Fixture Convergence:** All test fixtures checking for this hardening rule must be patched to assert `P7504`.

## Deliverables
- `schema/migrations/0162_renumber_hardening_sqlstate.sql`
- Patched legacy audit tests.
- `scripts/db/verify_tsk_p2_w6_rem_16c.sh`
