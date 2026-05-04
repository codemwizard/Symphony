# ADR-2026-05-04: Migration Convergence Fix

## Status
Accepted

## Context
Baseline drift was occurring due to migration non-convergence between the main database and fresh databases created by pre_ci.sh. The root cause was identified in the baseline drift root cause analysis:

1. **Constraint Naming Divergence**: Main DB had explicit constraint names while fresh DBs had auto-generated names
2. **Missing Function**: The `check_invariant_gate()` function existed in main DB but not in fresh DBs
3. **Trigger Differences**: Append-only trigger had different name and ERRCODE between main and fresh DBs

The `policy_decisions` table was touched by 11 migrations and evolved differently when applied incrementally vs all-at-once, causing schema divergence.

## Decision
Create a convergence migration (0203_converge_policy_decisions_schema.sql) to fix the schema differences and ensure both main and fresh databases produce identical schemas.

## Rationale
The convergence migration addresses the non-convergence issues by:

1. **Renaming Constraints**: Uses `ALTER TABLE ... RENAME CONSTRAINT` to convert auto-generated names to canonical names
2. **Adding Defaults**: Adds missing `DEFAULT gen_random_uuid()` on `policy_decision_id` 
3. **Fixing Triggers**: Drops and recreates the append-only trigger with correct name and ERRCODE (GF060)
4. **Adding Function**: Creates the missing `check_invariant_gate()` function
5. **Idempotent Operations**: All operations use `IF EXISTS`/`IF NOT EXISTS` guards to work correctly on both main and fresh databases

## Consequences
- Positive: Baseline drift check now passes with matching schema hashes
- Positive: Fresh databases created by pre_ci.sh now produce identical schema to main database
- Positive: Migration path dependency issues resolved
- Positive: CI pipeline can proceed without DRD lockouts
- Neutral: Main database schema remains unchanged (migration is mostly no-ops on existing schema)

## Migration Changes
- 0203_converge_policy_decisions_schema.sql - Convergence migration to fix schema non-convergence

## Schema Changes Applied
- Primary key: `policy_decisions_pkey` → `policy_decisions_pk`
- Foreign key: `policy_decisions_execution_id_fkey` → `policy_decisions_fk_execution`
- Unique constraint: `policy_decisions_execution_id_decision_type_key` → `policy_decisions_unique_exec_type`
- Check constraints: `policy_decisions_decision_hash_check` → `policy_decisions_hash_hex_64`
- Check constraints: `policy_decisions_signature_check` → `policy_decisions_sig_hex_128`
- Trigger: `enforce_policy_decisions_append_only` → `policy_decisions_append_only_trigger`
- ERRCODE: GF061 → GF060 in append-only trigger
- Added: `check_invariant_gate()` function
- Added: `DEFAULT gen_random_uuid()` on policy_decision_id
- Added: `ON DELETE RESTRICT` to foreign key

## Baseline Metadata
- Baseline date: 2026-05-04
- Baseline cutoff: 0203_converge_policy_decisions_schema.sql
- Normalized schema SHA256: 5426aeb4862a58934a2eb419a09b42def7e889689dd977cfd86aa084f1c39798
- Dump source: container:symphony-postgres
- pg_dump version: pg_dump (PostgreSQL) 18.3 (Debian 18.3-1.pgdg13+1)
- pg_server_version: 18.3 (Debian 18.3-1.pgdg13+1)

## Verification
- Baseline drift check passes with matching hashes
- Migration applies cleanly to main database (mostly no-ops)
- Fresh databases created by pre_ci.sh now match baseline schema
- CI pipeline completes without DRD lockouts

## References
- Baseline drift root cause analysis: baseline_drift_root_cause_analysis.md
- Baseline governance policy: docs/PLANS-addendum_1.md
- Previous baseline: ADR-2026-05-04-entity-coherence-baseline-update.md
