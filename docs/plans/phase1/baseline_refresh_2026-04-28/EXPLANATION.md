# Baseline Refresh Explanation - 2026-04-28

## Date
2026-04-28

## Reason for Baseline Change

Baseline regenerated from fresh database running all migrations from scratch to match pre_ci.sh FRESH_DB=1 behavior. Previous baseline was from main database with progressive migration history, causing constraint naming and trigger function divergence.

## Root Cause

The baseline was originally generated from the main `symphony` database at migration 0172 state. This database had migrations applied progressively over time, with later migrations renaming or altering objects created by earlier migrations. When pre_ci.sh creates a fresh temporary database and runs all migrations from scratch, conditional logic (IF NOT EXISTS) behaves differently, resulting in divergent schema states.

Specific divergences observed:
- Constraint naming: explicit names vs auto-generated names
- Check constraint naming: policy_decisions_hash_hex_64 vs policy_decisions_decision_hash_check
- Error codes: GF060 vs GF061 in append-only trigger
- Default values: gen_random_uuid() missing in fresh DB
- Trigger functions: check_invariant_gate() missing in fresh DB
- Trigger names: policy_decisions_append_only_trigger vs enforce_policy_decisions_append_only

## Resolution

Regenerated baseline using the canonical generation script from a fresh database that ran all migrations from scratch, matching the exact migration path used by pre_ci.sh when FRESH_DB=1. This ensures migration path parity between baseline generation and CI verification.

## Migration Path

1. Created fresh database `baseline_fresh_db`
2. Verified all 172 migrations applied from scratch (checked schema_migrations table)
3. Ran canonical baseline generation script: `scripts/db/generate_baseline_snapshot.sh`
4. Verified baseline drift check passes against fresh temp database
5. Copied regenerated baseline to `schema/baselines/current/0001_baseline.sql`

## Verification

Baseline drift check passes against fresh temp database with hash `920921ad2d580491abd19bbe67c8c8d4fe1e6133acbb3fba6f83e6dc2f948009`.

## Compliance

Per PLANS-addendum_1.md baseline governance policy:
- Baseline generated via container pg_dump (canonical script)
- No manual baseline editing
- Explanation artifact created documenting rationale
