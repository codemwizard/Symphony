# Baseline Drift — Real Root Cause Analysis

## Executive Summary

**PostGIS is a complete red herring.** The actual root cause is **migration path dependency** on the `policy_decisions` table and the `check_invariant_gate()` function. The migrations produce a *different schema* when applied incrementally to the long-lived main DB vs. applied all-at-once to a fresh ephemeral DB.

---

## The Evidence (from `/tmp/symphony_baseline_norm.sql` vs `/tmp/symphony_schema_dump.sql`)

The diff between the canonicalized baseline (main DB) and the canonicalized fresh-DB dump reveals **83 lines of diff**, and **every single difference** traces back to two object families:

### 1. `policy_decisions` — Constraint & Trigger Naming Divergence

| Aspect | Main DB (baseline) | Fresh DB (migrations) |
|--------|-------------------|----------------------|
| Primary key | `policy_decisions_pk` | `policy_decisions_pkey` |
| FK to execution_records | `policy_decisions_fk_execution` | `policy_decisions_execution_id_fkey` |
| Unique constraint | `policy_decisions_unique_exec_type` | `policy_decisions_execution_id_decision_type_key` |
| Hash check constraint | `policy_decisions_hash_hex_64` | `policy_decisions_decision_hash_check` |
| Signature check constraint | `policy_decisions_sig_hex_128` | `policy_decisions_signature_check` |
| Append-only trigger name | `policy_decisions_append_only_trigger` | `enforce_policy_decisions_append_only` |
| PK default value | `DEFAULT gen_random_uuid()` | *(no default)* |
| Append-only ERRCODE | `GF060` | `GF061` |
| FK ON DELETE clause | `ON DELETE RESTRICT` | *(no ON DELETE)* |

### 2. `check_invariant_gate()` — Function Exists in Main DB Only

The baseline contains a `check_invariant_gate()` trigger function with invariant-registry checking logic (variables `failing_count`, `registry_exists`, `SECURITY DEFINER`, `SET search_path`). This function and its associated logic lines are **absent** from the fresh DB dump.

---

## Why This Happens

The `policy_decisions` table was touched by **11 migrations** (0134, 0136, 0140, 0145, 0147, 0148, 0152, 0157, 0160, 0161, 0172). The evolution was:

1. **Migration 0134** — Created `policy_decisions` table. PostgreSQL auto-generated constraint names (e.g., `policy_decisions_pkey`, `policy_decisions_execution_id_fkey`).

2. **Later migrations on the main DB** (likely in the Wave 4/5 remediation) — Renamed constraints to explicit names (`policy_decisions_pk`, `policy_decisions_fk_execution`, etc.), added `DEFAULT gen_random_uuid()`, changed ERRCODE from `GF061` to `GF060`, renamed the trigger, added `ON DELETE RESTRICT`, and added the `check_invariant_gate()` function.

3. **On a fresh DB** — When all 172 migrations run sequentially, one of two things happens:
   - The early migrations create objects with auto-generated names
   - The later "fix" migrations use `IF NOT EXISTS` / `IF EXISTS` conditional logic that **doesn't fire** (because the object already exists with the auto-generated name, or doesn't exist yet in the expected form)
   - The result is a schema that preserves the auto-generated names, missing defaults, and missing function

> [!IMPORTANT]
> This is a classic **migration non-convergence** bug. The main DB's schema is the result of incremental ALTER operations on existing objects. The fresh DB's schema is the result of CREATE operations that produce different constraint/trigger names. The migrations that were supposed to rename/fix these objects contain conditional logic that behaves differently on a fresh DB vs. the main DB.

---

## Why PostGIS Was a Red Herring

- The baseline contains **zero** `CREATE EXTENSION` statements (pg_dump with `--schema=public` excludes them)
- PostGIS-dependent tables (`project_boundaries`, `protected_areas`) have identical definitions in both dumps
- The `postgis/postgis:18-3.6` Docker image provides PostGIS libraries, so `CREATE EXTENSION IF NOT EXISTS postgis` succeeds on both the main DB and fresh DBs
- Migration 0125 installs PostGIS successfully in all cases
- **None of the 83 diff lines mention PostGIS, geometry, spatial, or any extension**

---

## Why Previous Attempts Failed

| Attempt | Why It Failed |
|---------|--------------|
| Add DATABASE_URL to .env | Irrelevant — DATABASE_URL was already correct |
| baseline_then_migrations strategy | Doesn't fix migration non-convergence |
| Manually edit baseline files | Policy violation AND wrong problem |
| Regenerate baseline | Regenerates from main DB which has the "correct" (divergent) schema — makes the gap wider |
| Add PostGIS to template1 | Wrong problem entirely; PostGIS was never the issue |

---

## The Real Solution

There are two valid approaches:

### Option A: Fix the Migrations (Correct, Forward-Only)

Write a new migration (e.g., `0173_converge_policy_decisions_naming.sql`) that:

1. **Renames auto-generated constraints** to the canonical names using `ALTER ... RENAME CONSTRAINT`:
   - `policy_decisions_pkey` → `policy_decisions_pk`
   - `policy_decisions_execution_id_fkey` → `policy_decisions_fk_execution`
   - `policy_decisions_execution_id_decision_type_key` → `policy_decisions_unique_exec_type`
   - `policy_decisions_decision_hash_check` → `policy_decisions_hash_hex_64`
   - `policy_decisions_signature_check` → `policy_decisions_sig_hex_128`

2. **Adds the missing DEFAULT** on `policy_decision_id` if absent

3. **Fixes the trigger name** from `enforce_policy_decisions_append_only` to `policy_decisions_append_only_trigger`

4. **Fixes the ERRCODE** from `GF061` to `GF060` in the append-only trigger function

5. **Adds `ON DELETE RESTRICT`** to the FK if missing

6. **Creates `check_invariant_gate()`** function if it doesn't exist

All operations must use `IF EXISTS` / `IF NOT EXISTS` guards to be idempotent — working correctly on BOTH the main DB (no-ops) and fresh DBs (applies fixes).

Then **regenerate the baseline** from the main DB.

### Option B: Regenerate Baseline from Fresh DB (Quick Fix)

1. Create a fresh DB, apply all migrations
2. Generate the baseline from THAT fresh DB
3. This makes the baseline match what fresh DBs produce

> [!WARNING]
> Option B is a band-aid. It would make the baseline match fresh DBs but would mean the main DB's schema diverges from the baseline. The main DB would fail the drift check if tested directly. Option A is the correct solution.

---

## Verification Plan

After applying the fix migration:
1. Run `scripts/db/migrate.sh` against the main DB (should be no-ops)
2. Run `pre_ci.sh` with `FRESH_DB=1` — the fresh DB should now produce identical schema
3. Regenerate baseline, verify hashes match
4. Clear DRD lockout

---

## Key Migrations to Audit

The non-convergence likely originates in these migrations (the ones that ALTER `policy_decisions`):

- [0134_policy_decisions.sql](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/schema/migrations/0134_policy_decisions.sql) — Original CREATE TABLE
- [0172_fix_trigger_authority_and_ordering.sql](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/schema/migrations/0172_fix_trigger_authority_and_ordering.sql) — Last migration, likely the "fix" that doesn't converge
- [0148_harden_trigger_functions_security_definer.sql](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/schema/migrations/0148_harden_trigger_functions_security_definer.sql) — SECURITY DEFINER hardening
- [0152_add_sqlstate_codes_to_triggers.sql](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/schema/migrations/0152_add_sqlstate_codes_to_triggers.sql) — ERRCODE changes
- [0163_create_invariant_registry.sql](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/schema/migrations/0163_create_invariant_registry.sql) — Creates check_invariant_gate()
- [0171_attestation_kill_switch_gate.sql](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/schema/migrations/0171_attestation_kill_switch_gate.sql) — Gate function logic
