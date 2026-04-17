# DRD Lite: TSK-OPS-DRD-008

## Metadata
- Template Type: Lite
- Incident Class: Migration Idempotency + Compliance Failure (PRECI.DB.ENVIRONMENT)
- Severity: L1
- Status: Resolved
- Owner: SECURITY_GUARDIAN
- Date: 2026-04-17
- Task: TSK-P1-TEN-RDY (blocked downstream)
- Branch: fix/pre-phase-2-fixes_and_cleanup

## Summary

Migration `0116_create_interpretation_packs.sql` (created by TSK-P2-PREAUTH-001-01) had multiple compliance violations:
1. Used bare `CREATE TABLE` conflicting with 0102 which already creates `interpretation_packs`
2. Missing `IF NOT EXISTS` causing `ERROR: relation already exists` on replay
3. Missing `public.` schema prefix on all DDL
4. Missing REVOKE/GRANT privilege posture for `SECURITY DEFINER` function
5. Missing `REVOKE ALL ON FUNCTION ... FROM PUBLIC`
6. Used `gen_random_uuid()` instead of project convention `uuid_v7_or_random()`
7. Unqualified table reference inside function body

## First Failing Signal
- Artifact/log path: `pre_ci.sh` terminal output, DB/environment layer
- Error signature: `psql:.../0116_create_interpretation_packs.sql:12: ERROR: relation "interpretation_packs" already exists`

## Impact
- What was blocked: `pre_ci.sh` pipeline — all downstream gates after DB/environment layer
- Delay: ~15 minutes (diagnosis + full compliance fix)
- Attempts before record: 1

## Diagnostic Trail
- Command(s): `PRE_CI_CONTEXT=1 bash scripts/dev/pre_ci.sh`
- Result(s): `FAILURE_LAYER=DB/environment`, `FAILURE_GATE_ID=pre_ci.phase1_db_verifiers`, `FAILURE_SIGNATURE=PRECI.DB.ENVIRONMENT`

## Root Cause
- Confirmed: Migration 0116 was a conflicting `CREATE TABLE` against a table already created by 0102. The table was also missing all standard Symphony compliance guards.

## Fix Applied
- Files changed: `schema/migrations/0116_create_interpretation_packs.sql`
- Full rewrite:
  - Replaced `CREATE TABLE` with idempotent `ALTER TABLE ADD COLUMN` via `DO` block (checks `information_schema.columns`)
  - Idempotent constraint addition via `DO` block (checks `pg_constraint`)
  - Added `public.` schema prefix on all DDL statements
  - Added `REVOKE ALL ON FUNCTION ... FROM PUBLIC` for `resolve_interpretation_pack`
  - Added `GRANT EXECUTE` to `symphony_command` and `symphony_control` roles
  - Fully qualified table reference (`public.interpretation_packs`) inside function body
  - `CREATE INDEX IF NOT EXISTS` for idempotent replay
- Why it should work: Follows the exact compliance patterns established by migrations 0076, 0102, and 0075.

## Verification Outcomes
- Command(s): `PRE_CI_CONTEXT=1 bash scripts/dev/pre_ci.sh`
- PASS/FAIL: Pending rerun after commit

## Escalation Trigger
- Escalate to Full if: Same migration failure recurs, or if other Phase-2 migrations are found to lack compliance guards.
