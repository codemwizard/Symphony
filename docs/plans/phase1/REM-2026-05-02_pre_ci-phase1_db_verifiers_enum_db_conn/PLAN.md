# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: bash scripts/db/verify_tsk_p2_preauth_006a_01.sh
final_status: RESOLVED

## Root Cause

The `pre_ci.sh` CI pipeline runs its tests against an ephemeral database (using the `$DATABASE_URL` environment variable). However, the Phase 2 verification script `scripts/db/verify_tsk_p2_preauth_006a_01.sh` was incorrectly connecting to the default `symphony` database instead of the ephemeral CI database.

This happened for two reasons:
1. `scripts/db/verify_tsk_p2_preauth_006a_01.sh` calls `psql` without explicitly passing `$DATABASE_URL`.
2. `pre_ci.sh` invoked the script with hardcoded environment variables: `PGDATABASE=symphony`.

As a result, the script connected to the non-ephemeral `symphony` database, which lacks the `data_authority_level` ENUM created during the CI ephemeral database migration sequence, causing the "data_authority_level ENUM type does not exist" failure.

## Fix

1. **Updated `scripts/db/verify_tsk_p2_preauth_006a_01.sh`**: Modified `psql` commands to explicitly use `$DATABASE_URL` as the connection target.
2. **Updated `scripts/dev/pre_ci.sh`**: Removed the hardcoded `PGDATABASE=symphony` (and related `PGUSER`/`PGPASSWORD`) prefixes when calling `verify_tsk_p2_preauth_006a_01.sh` and `verify_tsk_p2_preauth_005_08.sh`, ensuring they rely on the exported `DATABASE_URL`.
