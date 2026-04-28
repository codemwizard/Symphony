# Implementation Plan: TSK-P2-W6-REM-17c-beta

## Mission
Apply the `NOT NULL` constraint to `policy_decisions.project_id`, establishing structurally guaranteed lineage.

## Constraints
1. **Safety:** Must not break any existing test fixtures or verifiers.
2. **Schema:** Must not alter data, only schema metadata.

## Deliverables
- `schema/migrations/0161_enforce_policy_decisions_project_id_not_null.sql`
- `scripts/db/verify_tsk_p2_w6_rem_17c_beta.sh`
