# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: psql -f scripts/dev/seed_canonical_test_data.sql
final_status: RESOLVED

## Root Cause

`pre_ci.sh` was silently crashing during the DB/environment initialization phase. 
The script redirects the output of `migrate.sh` and `psql -f seed_canonical_test_data.sql` to `/dev/null`.
When executed independently, the seed script failed with:
`ERROR: null value in column "entity_type" of relation "execution_records" violates not-null constraint`

This constraint was introduced by migrations `0199` and `0201` as part of the `TSK-P2-W5-REM-01` remediation task, but the canonical test data was not updated to reflect this new schema requirement, causing the `psql` command to exit with a non-zero code.

## Fix

Update `scripts/dev/seed_canonical_test_data.sql` to include `entity_type` ('ASSET_BATCH') and `entity_id` ('00000000-0000-0000-0000-00000000000b') in the `execution_records` INSERT statement to satisfy the NOT NULL constraints.
