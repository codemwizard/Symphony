# Implementation Plan: TSK-P2-W6-REM-17b-beta

## Mission
Backfill the `policy_decisions.project_id` column using `execution_records.project_id` as the source of truth, enforcing execution-bound lineage.

## Constraints
1. **Idempotency:** Must do zero updates if run twice.
2. **Safety:** Must disable the `policy_decisions_append_only_trigger` temporarily to allow the mutation.
3. **Contract:** Use the three-phase Assert → Mutate → Reconcile structure.

## Deliverables
- `schema/migrations/0160_backfill_policy_decisions_project_id.sql`
- `scripts/db/verify_tsk_p2_w6_rem_17b_beta.sh`
