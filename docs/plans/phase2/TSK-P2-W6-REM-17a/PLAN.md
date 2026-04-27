# Implementation Plan: TSK-P2-W6-REM-17a

## Mission
Add `interpretation_version_id` (nullable) to `state_transitions` and `project_id` (nullable) to `policy_decisions`.

## Targets
1. `schema/migrations/0156_add_interpretation_version_id.sql`
2. `schema/migrations/0157_add_project_id_to_policy_decisions.sql`
3. `scripts/db/verify_tsk_p2_w6_rem_17a.sh`

## Acceptance Criteria
- Both columns are visible and nullable.
- `scripts/db/verify_tsk_p2_w6_rem_17a.sh` successfully validates nullability.
- Existing Wave 5 verifiers (`verify_tsk_p2_preauth_005_*.sh` and `verify_wave5_state_machine_integration.sh`) continue to pass.

## Evidence Paths
- `evidence/phase2/tsk_p2_w6_rem_17a.json`
