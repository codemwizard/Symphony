# Implementation Plan: TSK-P2-W6-REM-14

## Mission
Enforce the `NOT NULL` constraint on `state_current.last_transition_id` to prevent corrupted application state from persisting at the database boundary.

## Constraints
- **Forward-only migration**: Must be a new migration file (`0154_enforce_last_transition_id_not_null.sql`), do not edit `0151`.
- **Precondition Check**: Must check for existing `NULL` rows and abort if they exist.
- **Write Isolation**: Verifier and execution must be performed under strict write isolation to prevent concurrent insertion of invalid rows during the ALTER phase.
- **Full Path Verification**: The negative test must execute an `INSERT INTO state_transitions` using the actual database write surface to prove the trigger (`ai_01_update_current_state`) enforces the constraint downstream.

## Verification Commands
- `bash scripts/db/verify_tsk_p2_w6_rem_14.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P2-W6-REM-14 --evidence evidence/phase2/tsk_p2_w6_rem_14.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Approval References
- Phase: 2
- Architect Decision: `W6-REM-implementation_plan.md` (v8)

## Evidence Paths
- `evidence/phase2/tsk_p2_w6_rem_14.json`
