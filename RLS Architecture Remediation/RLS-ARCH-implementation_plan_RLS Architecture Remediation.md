# RLS-ARCH — Deterministic Dual-Policy System (v10.1 — Hybrid Final)

**Phase Name:** RLS Architecture Remediation  
**Phase Key:** RLS-ARCH

---

## Core Philosophy

> **RLS is declared, generated, and enforced. Never discovered, classified, or interpreted.**

All previous versions attempted to understand existing policy state and make surgical corrections. This version replaces that approach entirely:

1. **Declare** table isolation requirements in YAML (source of truth)
2. **Drop** all existing policies (destructive reset)
3. **Generate** correct policies deterministically from declared config
4. **Enforce** invariants structurally, not heuristically

**What is eliminated:**
- ~~`_normalize_rls_expr()`~~ — no normalization in any code path
- ~~Policy classification logic~~ — no interpreting existing policies
- ~~Unknown policy handling~~ — no unknown policies possible
- ~~Fingerprint-based gating~~ — fingerprint retained for audit only
- ~~Canonical template matching~~ — no matching, only generation

---

## User Review Required

> [!CAUTION]
> **Destructive migration.** Phase 2 drops ALL existing policies on target tables, then regenerates from declared config. Non-isolation policies must be explicitly whitelisted to survive.

> [!IMPORTANT]
> **Mandatory setter wrapper.** `set_tenant_context()` is the ONLY way to set tenant GUC. Direct `SET` is prohibited and detectable.

> [!WARNING]
> **Behavioral change:** `current_tenant_id()` (strict getter) now raises EXCEPTION on NULL. Application code must always set tenant context before DB operations.

---

## Phase 0 — Structural Declaration

### 0.1 Target Table Registry (YAML — Single Source of Truth)

#### [NEW] [rls_tables.yml](file:///home/mwiza/workspace/Symphony/schema/rls_tables.yml)

```yaml
# AUTHORITATIVE — every tenant-scoped table MUST be listed here
# CI fails if DB contains public tables with tenant_id NOT in this file
tables:
  # DIRECT: table has its own tenant_id column
  - name: adapter_registrations
    type: DIRECT
    tenant_column: tenant_id

  - name: green_assets
    type: DIRECT
    tenant_column: tenant_id

  # JOIN: table lacks tenant_id, isolated via FK to parent with tenant_id
  - name: asset_measurements
    type: JOIN
    parent: green_assets
    fk_column: asset_id
    parent_pk: id

  # GLOBAL: no tenant isolation (config tables, reference data)
  # Explicitly declared — not inferred from absence
  - name: interpretation_packs
    type: GLOBAL
    reason: CONFIG_TABLE
    reviewer: "mwiza"
    reviewed_at: "2026-03-24T17:00:00Z"
```

**Rules:**
- Every table with `tenant_id` MUST be type `DIRECT`
- Every table with FK to a DIRECT table and no `tenant_id` MUST be type `JOIN`
- Tables with neither → `GLOBAL` (requires reason enum + reviewer)
- CI query: `SELECT relname FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relname NOT IN (<yaml_tables>)` → must return 0 rows for tables with `tenant_id`
- No auto-discovery fallback. Missing table = CI failure.

### 0.2 DB Metadata Table (Populated from YAML)

```sql
CREATE TABLE IF NOT EXISTS public._rls_table_config (
  table_name TEXT PRIMARY KEY,
  isolation_type TEXT NOT NULL CHECK (isolation_type IN ('DIRECT', 'JOIN', 'GLOBAL')),
  tenant_column TEXT,           -- for DIRECT tables
  parent_table TEXT,            -- for JOIN tables
  fk_column TEXT,               -- for JOIN tables
  parent_pk TEXT,               -- for JOIN tables
  loaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Phase 0 script: parse YAML → populate `_rls_table_config` → validate.

### 0.3 Hard Validation (FAIL FAST)

```sql
-- 1. FK must exist for JOIN tables
SELECT c.table_name FROM _rls_table_config c
WHERE c.isolation_type = 'JOIN'
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_name = c.table_name
      AND kcu.column_name = c.fk_column
      AND ccu.table_name = c.parent_table
  );
-- Must return 0 rows

-- 2. FK column must be NOT NULL (v10.1 — nullable FK = isolation bypass)
SELECT c.table_name, c.fk_column FROM _rls_table_config c
WHERE c.isolation_type = 'JOIN'
  AND EXISTS (
    SELECT 1 FROM information_schema.columns col
    WHERE col.table_schema = 'public'
      AND col.table_name = c.table_name
      AND col.column_name = c.fk_column
      AND col.is_nullable = 'YES'
  );
-- Must return 0 rows. Nullable FK → rows bypass JOIN isolation.

-- 3. FK must be NOT DEFERRABLE (v10.1 — deferred FK = consistency window)
SELECT c.table_name, tc.constraint_name FROM _rls_table_config c
JOIN information_schema.table_constraints tc ON tc.table_name = c.table_name
  AND tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
  AND kcu.column_name = c.fk_column
WHERE c.isolation_type = 'JOIN'
  AND tc.is_deferrable = 'YES';
-- Must return 0 rows. Deferrable FK → window of inconsistency.

-- 4. Parent must be DIRECT
SELECT c.table_name FROM _rls_table_config c
WHERE c.isolation_type = 'JOIN'
  AND c.parent_table NOT IN (
    SELECT table_name FROM _rls_table_config WHERE isolation_type = 'DIRECT'
  );
-- Must return 0 rows

-- 5. Parent must have tenant_column
SELECT c.table_name FROM _rls_table_config c
WHERE c.isolation_type = 'JOIN'
  AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns col
    WHERE col.table_name = c.parent_table
      AND col.column_name = (SELECT p.tenant_column FROM _rls_table_config p WHERE p.table_name = c.parent_table)
  );
-- Must return 0 rows

-- 6. No cycles in JOIN graph (topological sort in Phase 0 script — cycle → abort)
```

Any validation failure → **abort with diagnostic. No fallback.**

> [!NOTE]
> v10.1: Added FK column NOT NULL and NOT DEFERRABLE checks. Without these, JOIN isolation is weaker than DIRECT: nullable FK allows rows to bypass the EXISTS check, and deferrable FK creates a window where orphan rows can exist transiently.

### 0.4 Partition + Inheritance Check

```sql
SELECT relname FROM pg_class
WHERE relkind = 'p'
  AND relnamespace = 'public'::regnamespace
  AND relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL');
-- Must return 0 rows (partitioned tables need special handling)

SELECT c.relname FROM pg_inherits i
JOIN pg_class c ON c.oid = i.inhrelid
WHERE c.relnamespace = 'public'::regnamespace
  AND c.relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL');
-- Must return 0 rows
```

### 0.5 Traffic Tier Classification

```sql
SELECT relname,
  n_tup_ins + n_tup_upd + n_tup_del AS write_volume
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL')
ORDER BY write_volume DESC;
```

Classify into Tier 1 (low), Tier 2 (medium), Tier 3 (high) for lock ordering.

### 0.6 Snapshot (Audit + Rollback Only)

#### [NEW] [0095_pre_snapshot.sql](file:///home/mwiza/workspace/Symphony/schema/migrations/0095_pre_snapshot.sql)

Executable SQL snapshot of all current policies on target tables. Generated by Phase 0 script.

**Role of snapshot (explicit):**
- ✅ Rollback mechanism
- ✅ Audit trail
- ❌ NOT correctness validator
- ❌ NOT classification input
- ❌ NOT migration blocker

**Fingerprint (retained, audit-only):**

```sql
-- Stored in _migration_fingerprints for audit. NEVER blocks migration.
INSERT INTO _migration_fingerprints (migration_key, fingerprint_type, fingerprint_hash)
VALUES ('0095_rls_dual_policy', 'pre_migration',
  (SELECT md5(string_agg(
    format('%s:%s:%s:%s',
      c.relname, p.polpermissive, p.polcmd,
      coalesce(pg_get_expr(p.polqual, p.polrelid), '')),
    '|' ORDER BY c.relname, p.polname
  )) FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
  WHERE c.relnamespace = 'public'::regnamespace
    AND c.relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL'))
)
ON CONFLICT DO NOTHING;
```

### 0.7 Function Definition Snapshot (Advisory)

```sql
-- Persist function hash for drift detection (advisory, not blocking)
INSERT INTO _migration_fn_hashes (migration_key, function_name, definition_hash)
VALUES ('0095_rls_dual_policy', 'current_tenant_id',
  md5(pg_get_functiondef(
    (SELECT p.oid FROM pg_proc p
     JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public' AND p.proname = 'current_tenant_id')
  ))
)
ON CONFLICT DO NOTHING;
```

> [!NOTE]
> Function hash is advisory — drift signal, not proof. Covers leaf definition only. Mismatch → WARNING + manual ack, not hard block.

---

## Phase 1 — Atomic Migration (Single Transaction)

> [!IMPORTANT]
> **Transaction boundary:** All Phase 1 steps execute inside a **single SQL transaction**. `BEGIN;` at start, `COMMIT;` at end. Any failure → full `ROLLBACK`. No partial policy state possible.

#### [NEW] [0095_rls_dual_policy_architecture.sql](file:///home/mwiza/workspace/Symphony/schema/migrations/0095_rls_dual_policy_architecture.sql)

### 1.1 Infrastructure Tables

```sql
-- Execution control (mutable)
CREATE TABLE IF NOT EXISTS public._migration_guards (
  key TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  skip_guard BOOLEAN NOT NULL DEFAULT false,
  force_override BOOLEAN NOT NULL DEFAULT false
);

-- Immutable fingerprint audit (INSERT-only)
CREATE TABLE IF NOT EXISTS public._migration_fingerprints (
  migration_key TEXT NOT NULL,
  fingerprint_type TEXT NOT NULL,
  fingerprint_hash TEXT NOT NULL,
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (migration_key, fingerprint_type)
);

-- Function integrity (INSERT-only, advisory)
CREATE TABLE IF NOT EXISTS public._migration_fn_hashes (
  migration_key TEXT NOT NULL,
  function_name TEXT NOT NULL,
  definition_hash TEXT NOT NULL,
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (migration_key, function_name)
);
```

### 1.2 Migration Guard

```sql
DO $$ BEGIN
  -- Already applied and NOT flagged for re-run
  IF EXISTS (SELECT 1 FROM _migration_guards
    WHERE key = '0095_rls_dual_policy' AND skip_guard = false)
  AND EXISTS (SELECT 1 FROM _migration_fingerprints
    WHERE migration_key = '0095_rls_dual_policy' AND fingerprint_type = 'post_migration')
  THEN
    RAISE EXCEPTION 'Migration 0095 already applied. To re-run: '
      'UPDATE _migration_guards SET skip_guard = true WHERE key = ...';
  END IF;

  -- Re-run: check force_override if fingerprint exists
  IF EXISTS (SELECT 1 FROM _migration_guards
    WHERE key = '0095_rls_dual_policy' AND skip_guard = true)
  THEN
    -- Function drift check (advisory)
    DECLARE current_fn_hash TEXT; stored_fn_hash TEXT;
    BEGIN
      current_fn_hash := md5(pg_get_functiondef(
        (SELECT p.oid FROM pg_proc p
         JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'public' AND p.proname = 'current_tenant_id')
      ));
      stored_fn_hash := (SELECT definition_hash FROM _migration_fn_hashes
        WHERE migration_key = '0095_rls_dual_policy'
          AND function_name = 'current_tenant_id');
      IF current_fn_hash IS DISTINCT FROM stored_fn_hash THEN
        RAISE WARNING 'Function drift detected: current_tenant_id() hash (%) ≠ snapshot (%).',
          current_fn_hash, stored_fn_hash;
        IF NOT EXISTS (SELECT 1 FROM _migration_guards
          WHERE key = '0095_fn_drift_acknowledged' AND skip_guard = true)
        THEN
          RAISE EXCEPTION 'Function drift not acknowledged. Review, then: '
            'INSERT INTO _migration_guards (key, skip_guard) '
            'VALUES (''0095_fn_drift_acknowledged'', true);';
        END IF;
      END IF;
    END;
  END IF;
END $$;
```

`force_override` rules: superuser-only, logged loudly, reset after migration. **Emergency escape hatch.**

### 1.3 Advisory Lock (Two-Key)

```sql
DO $$ DECLARE acquired boolean; BEGIN
  acquired := pg_try_advisory_xact_lock(
    hashtext(current_database()),
    hashtext('0095_rls_dual_policy'));
  IF NOT acquired THEN
    RAISE EXCEPTION 'Migration 0095 running in another session — aborting';
  END IF;
END $$;
```

### 1.4 Preflight Blocker Report

```sql
SET LOCAL lock_timeout = '5s';

DO $$ DECLARE r RECORD; found BOOLEAN := false; BEGIN
  FOR r IN
    SELECT DISTINCT a.pid, a.usename, a.state,
           left(a.query, 120) as qry,
           now() - a.query_start as dur
    FROM pg_stat_activity a
    JOIN pg_locks l ON l.pid = a.pid
    JOIN pg_class c ON c.oid = l.relation
    WHERE a.datname = current_database()
      AND a.pid != pg_backend_pid()
      AND c.relnamespace = 'public'::regnamespace
      AND c.relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL')
  LOOP
    RAISE WARNING 'BLOCKER: pid=% user=% dur=% q=%',
      r.pid, r.usename, r.dur, r.qry;
    found := true;
  END LOOP;
  IF found THEN
    RAISE EXCEPTION 'Sessions holding locks on target tables — abort. '
      'Retry in maintenance window.';
  END IF;
END $$;
```

### 1.5 Dependency-Ordered Locking (NOWAIT + Standardized Retry)

**Retry is a required migration runner interface, not tribal knowledge.**

#### [NEW] [run_migration_0095.sh](file:///home/mwiza/workspace/Symphony/scripts/db/run_migration_0095.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Required migration runner — DO NOT run 0095 directly via psql
MAX_RETRIES=3
MIGRATION="schema/migrations/0095_rls_dual_policy_architecture.sql"

for attempt in $(seq 1 $MAX_RETRIES); do
  echo "[$(date -u +%FT%TZ)] Attempt $attempt/$MAX_RETRIES"
  if psql "$DATABASE_URL" -f "$MIGRATION" 2>&1; then
    echo "Migration 0095 applied successfully."
    exit 0
  fi
  if [ "$attempt" -lt "$MAX_RETRIES" ]; then
    delay=$((2 ** attempt))
    echo "Lock acquisition failed. Backing off ${delay}s..."
    sleep $delay
  fi
done

echo "FATAL: Migration 0095 failed after $MAX_RETRIES attempts."
exit 1
```

**Inside migration (lock order):**

```sql
-- Level 0: root parent tables
LOCK TABLE public.<parent_1> IN ACCESS EXCLUSIVE MODE NOWAIT;
-- Level 1: child tables
LOCK TABLE public.<child_1> IN ACCESS EXCLUSIVE MODE NOWAIT;
-- Level 2: independent tables by traffic tier
LOCK TABLE public.<low_1> IN ACCESS EXCLUSIVE MODE NOWAIT;
```

> [!NOTE]
> v10.1: Retry is now a first-class script, not a bash comment. NOWAIT inside the transaction for fail-fast; retry with backoff in the runner for operational resilience.

### 1.6 Destructive Reset (Structural Preservation)

> [!CAUTION]
> **This drops ALL policies on target tables** except those structurally preserved from Phase 0.

**Phase 0 captures preserved policies structurally (not by name):**

```sql
-- Phase 0: snapshot non-isolation policies for structural preservation
CREATE TABLE IF NOT EXISTS public._preserved_policies (
  table_name TEXT NOT NULL,
  policy_name TEXT NOT NULL,
  permissive BOOLEAN NOT NULL,
  cmd TEXT NOT NULL,
  roles TEXT NOT NULL,
  qual_expr TEXT,
  wc_expr TEXT,
  create_sql TEXT NOT NULL,  -- executable CREATE POLICY statement
  PRIMARY KEY (table_name, policy_name)
);

-- Populated by Phase 0 script: for each non-isolation policy,
-- store the full CREATE POLICY statement for exact reapplication.
```

**Phase 1 reset:**

```sql
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT p.polname, c.relname
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relnamespace = 'public'::regnamespace
      AND c.relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL')
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', pol.polname, pol.relname);
  END LOOP;
END $$;

-- Reapply preserved policies from structural snapshot
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN SELECT * FROM _preserved_policies
  LOOP
    EXECUTE pol.create_sql;
    RAISE NOTICE 'RESTORED: %.%', pol.table_name, pol.policy_name;
  END LOOP;
END $$;
```

> [!IMPORTANT]
> **v10.1: Structural preservation replaces name-based whitelist.** Policy names are unstable identifiers — renaming a policy silently bypasses the whitelist. Now: Phase 0 captures the full `CREATE POLICY` statement. Phase 1 drops everything, then reapplies preserved policies from stored executable SQL. No name-based matching.

### 1.7 Deterministic Policy Generation

**All policies generated from `_rls_table_config`. No parsing, no matching.**

**DIRECT tables:**

```sql
DO $$
DECLARE tbl RECORD;
BEGIN
  FOR tbl IN SELECT * FROM _rls_table_config WHERE isolation_type = 'DIRECT'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl.table_name);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', tbl.table_name);

    -- Idempotent: drop before create (v10.1)
    EXECUTE format('DROP POLICY IF EXISTS rls_base_%I ON public.%I', tbl.table_name, tbl.table_name);
    EXECUTE format('DROP POLICY IF EXISTS rls_iso_%I ON public.%I', tbl.table_name, tbl.table_name);

    -- Baseline PERMISSIVE
    EXECUTE format(
      'CREATE POLICY rls_base_%I ON public.%I AS PERMISSIVE FOR ALL TO PUBLIC USING (true)',
      tbl.table_name, tbl.table_name);

    -- Isolation RESTRICTIVE
    EXECUTE format(
      'CREATE POLICY rls_iso_%I ON public.%I AS RESTRICTIVE FOR ALL TO PUBLIC '
      'USING (%I = public.current_tenant_id_or_null()) '
      'WITH CHECK (%I = public.current_tenant_id_or_null())',
      tbl.table_name, tbl.table_name, tbl.tenant_column, tbl.tenant_column);
  END LOOP;
END $$;
```

**JOIN tables:**

```sql
DO $$
DECLARE tbl RECORD;
BEGIN
  FOR tbl IN SELECT * FROM _rls_table_config WHERE isolation_type = 'JOIN'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl.table_name);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', tbl.table_name);

    -- Idempotent: drop before create (v10.1)
    EXECUTE format('DROP POLICY IF EXISTS rls_base_%I ON public.%I', tbl.table_name, tbl.table_name);
    EXECUTE format('DROP POLICY IF EXISTS rls_iso_%I ON public.%I', tbl.table_name, tbl.table_name);

    -- Baseline PERMISSIVE
    EXECUTE format(
      'CREATE POLICY rls_base_%I ON public.%I AS PERMISSIVE FOR ALL TO PUBLIC USING (true)',
      tbl.table_name, tbl.table_name);

    -- Isolation RESTRICTIVE (JOIN-based)
    EXECUTE format(
      'CREATE POLICY rls_iso_%I ON public.%I AS RESTRICTIVE FOR ALL TO PUBLIC '
      'USING (EXISTS (SELECT 1 FROM public.%I p WHERE p.%I = %I.%I '
        'AND p.tenant_id = public.current_tenant_id_or_null())) '
      'WITH CHECK (EXISTS (SELECT 1 FROM public.%I p WHERE p.%I = %I.%I '
        'AND p.tenant_id = public.current_tenant_id_or_null()))',
      tbl.table_name, tbl.table_name,
      tbl.parent_table, tbl.parent_pk, tbl.table_name, tbl.fk_column,
      tbl.parent_table, tbl.parent_pk, tbl.table_name, tbl.fk_column);
  END LOOP;
END $$;
```

### 1.8 GUC Hardening (Remove legacy bypass_rls)

```sql
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants FORCE ROW LEVEL SECURITY;
-- Drop any policies using bypass_rls or NULLIF patterns
```

### 1.9 Post-Migration Fingerprint + Guard Update

```sql
-- Store post-migration fingerprint (audit)
INSERT INTO _migration_fingerprints (migration_key, fingerprint_type, fingerprint_hash)
VALUES ('0095_rls_dual_policy', 'post_migration',
  (SELECT md5(string_agg(
    format('%s:%s:%s:%s',
      c.relname, p.polpermissive, p.polcmd,
      coalesce(pg_get_expr(p.polqual, p.polrelid), '')),
    '|' ORDER BY c.relname, p.polname
  )) FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
  WHERE c.relnamespace = 'public'::regnamespace
    AND c.relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL'))
);

-- Mark migration as applied
INSERT INTO _migration_guards (key, applied_at, skip_guard)
VALUES ('0095_rls_dual_policy', now(), false)
ON CONFLICT (key) DO UPDATE SET applied_at = now(), skip_guard = false, force_override = false;
```

### 1.10 Post-Generation Sanity Assertion (v10.1)

**Verify generated policies contain expected structure. Generation eliminated classification — this verifies the generator itself.**

```sql
DO $$
DECLARE tbl RECORD; pol_qual TEXT; fail BOOLEAN := false;
BEGIN
  -- Assert every DIRECT table's isolation policy references its tenant column
  FOR tbl IN SELECT * FROM _rls_table_config WHERE isolation_type = 'DIRECT'
  LOOP
    SELECT pg_get_expr(p.polqual, p.polrelid) INTO pol_qual
    FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relname = tbl.table_name AND p.polname = format('rls_iso_%s', tbl.table_name)
      AND c.relnamespace = 'public'::regnamespace;

    IF pol_qual IS NULL OR pol_qual NOT LIKE '%' || tbl.tenant_column || '%'
       OR pol_qual NOT LIKE '%current_tenant_id_or_null%' THEN
      RAISE WARNING 'SANITY FAIL on %: isolation policy missing tenant constraint', tbl.table_name;
      fail := true;
    END IF;
  END LOOP;

  -- Assert every JOIN table's isolation policy references parent + FK + tenant
  FOR tbl IN SELECT * FROM _rls_table_config WHERE isolation_type = 'JOIN'
  LOOP
    SELECT pg_get_expr(p.polqual, p.polrelid) INTO pol_qual
    FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relname = tbl.table_name AND p.polname = format('rls_iso_%s', tbl.table_name)
      AND c.relnamespace = 'public'::regnamespace;

    IF pol_qual IS NULL OR pol_qual NOT LIKE '%' || tbl.parent_table || '%'
       OR pol_qual NOT LIKE '%' || tbl.fk_column || '%'
       OR pol_qual NOT LIKE '%current_tenant_id_or_null%' THEN
      RAISE WARNING 'SANITY FAIL on %: JOIN policy missing structural elements', tbl.table_name;
      fail := true;
    END IF;
  END LOOP;

  IF fail THEN
    RAISE EXCEPTION 'Post-generation sanity check failed. Generated policies do not match expected structure.';
  END IF;
END $$;
```

### 1.11 Runtime Coverage Kill Switch (v10.1)

**Runs inside the transaction, before COMMIT. Removes CI dependency for coverage.**

```sql
-- Abort if any tenant table exists in DB but not in config
DO $$
DECLARE uncovered TEXT;
BEGIN
  SELECT string_agg(relname, ', ') INTO uncovered
  FROM pg_class
  WHERE relnamespace = 'public'::regnamespace
    AND relkind = 'r'
    AND EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = relname
        AND column_name = 'tenant_id'
    )
    AND relname NOT IN (SELECT table_name FROM _rls_table_config);

  IF uncovered IS NOT NULL THEN
    RAISE EXCEPTION 'COVERAGE KILL SWITCH: tables with tenant_id not in _rls_table_config: %. '
      'Update rls_tables.yml and re-run.', uncovered;
  END IF;

  -- Abort if any config table lacks RLS after generation
  SELECT string_agg(c.table_name, ', ') INTO uncovered
  FROM _rls_table_config c
  WHERE c.isolation_type != 'GLOBAL'
    AND NOT EXISTS (
      SELECT 1 FROM pg_class pc
      WHERE pc.relname = c.table_name
        AND pc.relnamespace = 'public'::regnamespace
        AND pc.relrowsecurity = true
        AND pc.relforcerowsecurity = true
    );

  IF uncovered IS NOT NULL THEN
    RAISE EXCEPTION 'COVERAGE KILL SWITCH: config tables without RLS enabled: %. '
      'Generation failed.', uncovered;
  END IF;
END $$;
```

> [!IMPORTANT]
> **v10.1: Runtime kill switch.** This runs inside the migration transaction, before COMMIT. It asserts two things: (1) no tenant table exists that isn't in the config, (2) no config table exists without RLS. Either failure → ROLLBACK. This eliminates silent coverage gaps regardless of whether CI runs.

---

## Phase 1R — Rollback Script

#### [NEW] [0095_rollback.sql](file:///home/mwiza/workspace/Symphony/schema/migrations/0095_rollback.sql)

Manual use only — NOT run by migration runner:

```sql
-- 1. Drop ALL current policies on target tables
DO $$ DECLARE pol RECORD; BEGIN
  FOR pol IN
    SELECT p.polname, c.relname FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relnamespace = 'public'::regnamespace
      AND c.relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL')
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', pol.polname, pol.relname);
  END LOOP;
END $$;

-- 2. Restore pre-migration policies
\i schema/migrations/0095_pre_snapshot.sql

-- 3. Mark guard for re-run
UPDATE _migration_guards SET skip_guard = true
WHERE key = '0095_rls_dual_policy';
```

---

## Phase 2 — Tenant Functions (Dual Getter + Mandatory Setter)

#### [MODIFY] Tenant context functions

**Strict getter (for application code):**

```sql
CREATE OR REPLACE FUNCTION public.current_tenant_id()
RETURNS uuid LANGUAGE plpgsql STABLE
SET search_path = pg_catalog, public
AS $$
DECLARE v text;
BEGIN
  v := current_setting('app.current_tenant_id', true);
  IF v IS NULL OR btrim(v) = '' THEN
    RAISE EXCEPTION 'Tenant context not set. Call set_tenant_context() before DB operations.';
  END IF;
  RETURN v::uuid;
END;
$$;
```

**Permissive getter (for RLS expressions only):**

```sql
CREATE OR REPLACE FUNCTION public.current_tenant_id_or_null()
RETURNS uuid LANGUAGE plpgsql STABLE
SET search_path = pg_catalog, public
AS $$
DECLARE v text;
BEGIN
  v := current_setting('app.current_tenant_id', true);
  IF v IS NULL OR btrim(v) = '' THEN
    RETURN NULL;  -- fail-closed: RESTRICTIVE policy evaluates false
  END IF;
  RETURN v::uuid;
END;
$$;
```

**Mandatory setter wrapper:**

```sql
CREATE OR REPLACE FUNCTION public.set_tenant_context(p_tenant_id uuid)
RETURNS void LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF p_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Cannot set NULL tenant context';
  END IF;
  PERFORM set_config('app.current_tenant_id', p_tenant_id::text, true);
  -- set_config with is_local=true = SET LOCAL
END;
$$;

REVOKE ALL ON FUNCTION public.set_tenant_context FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_tenant_context TO app_role;
```

> [!IMPORTANT]
> **Dual getter design:**
> - `current_tenant_id()` — used by application code. Hard-fails on missing context → forces developers to always set tenant.
> - `current_tenant_id_or_null()` — used ONLY in RLS policy expressions. Returns NULL → RESTRICTIVE policy evaluates to `false` → fail-closed, no exception. Required because admin functions (BYPASSRLS) operate without tenant context.

> [!WARNING]
> **Do NOT revoke `set_config()` from PUBLIC.** It's a system function used for all GUCs. Instead, lint + code review enforce that only `set_tenant_context()` is called in application code. The runtime verifier detects GUC leakage.

---

## Phase 3 — Lint (Simplified + Declarative)

#### [MODIFY] [lint_rls_born_secure.py](file:///home/mwiza/workspace/Symphony/scripts/db/lint_rls_born_secure.py)

Lint no longer classifies. It enforces:

1. **No manual policy creation** — only migration-generated `rls_base_*` and `rls_iso_*` patterns allowed
2. **YAML ↔ DB parity** — `_rls_table_config` must match `rls_tables.yml`
3. **No direct `SET app.current_tenant_id`** — only `set_tenant_context()` allowed
4. **No RLS functions calling other UDFs** — `current_tenant_id()`, `current_tenant_id_or_null()` must not call user-defined functions
5. **USING / WITH CHECK parity** — for all isolation policies, expressions must be identical
6. **Tenant constraint presence** — both USING and WITH CHECK must contain `current_tenant_id_or_null`
7. **DEFINER lint gate** — new `SECURITY DEFINER` functions must match `docs/invariants/approved_definer_functions.md`
8. **symphony_reader grant whitelist** — CI checks for unauthorized grants

Test cases: 13 (test_12–25 from v9.6, minus classification tests, plus YAML parity)

---

## Phase 4 — Runtime Verifier (Binary Drift Model)

#### [MODIFY] [verify_gf_rls_runtime.sh](file:///home/mwiza/workspace/Symphony/scripts/audit/verify_gf_rls_runtime.sh)

Drift is binary: system matches config, or it's broken.

**Policy structure (exactly 2 per non-GLOBAL table):**

```sql
SELECT c.relname,
  count(*) FILTER (WHERE p.polpermissive = true) AS permissive_count,
  count(*) FILTER (WHERE p.polpermissive = false) AS restrictive_count
FROM pg_policy p
JOIN pg_class c ON c.oid = p.polrelid
WHERE c.relnamespace = 'public'::regnamespace
  AND c.relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL')
GROUP BY c.relname;
-- Verify: permissive_count = 1, restrictive_count = 1 for ALL rows
```

**Target coverage (every declared table has RLS):**

```sql
SELECT c.table_name FROM _rls_table_config c
WHERE c.isolation_type != 'GLOBAL'
  AND NOT EXISTS (
    SELECT 1 FROM pg_class pc
    WHERE pc.relname = c.table_name
      AND pc.relnamespace = 'public'::regnamespace
      AND pc.relrowsecurity = true
      AND pc.relforcerowsecurity = true
  );
-- Must return 0 rows
```

**YAML ↔ DB parity:**

```sql
-- Tables in DB not in config
SELECT relname FROM pg_class
WHERE relnamespace = 'public'::regnamespace
  AND relname NOT IN (SELECT table_name FROM _rls_table_config)
  AND EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = relname AND column_name = 'tenant_id'
  );
-- Must return 0 rows
```

**Cross-tenant FK mismatch:**

```sql
SELECT COUNT(*) FROM child c
JOIN parent p ON p.pk = c.fk
WHERE c.tenant_id != p.tenant_id;
-- Must be 0 (per JOIN table pair from _rls_table_config)
```

**GUC leakage detection:**

```sql
-- Run outside any transaction block (autocommit, fresh connection)
SELECT current_setting('app.current_tenant_id', true) AS leaked_value;
-- Must be NULL or empty
```

**DEFINER role audit:**

```sql
SELECT r.rolname as member, g.rolname as granted_role
FROM pg_auth_members m
JOIN pg_roles r ON r.oid = m.member
JOIN pg_roles g ON g.oid = m.roleid
WHERE g.rolname IN ('symphony_ops_role', 'symphony_reader');
-- Only expected named users should appear
```

---

## Phase 5 — Adversarial Runtime Tests (21 cases)

#### [NEW] [test_rls_dual_policy_access.sh](file:///home/mwiza/workspace/Symphony/tests/rls_runtime/test_rls_dual_policy_access.sh)

| # | Category | Case | Expected |
|---|----------|------|----------|
| 1 | Read | Correct tenant | ≥1 row |
| 2 | Read | Wrong tenant | 0 rows |
| 3 | Read | No tenant (NULL GUC) | 0 rows |
| 4 | Read | Empty tenant | 0 rows |
| 5 | Write | INSERT wrong tenant_id | FAIL |
| 6 | Write | INSERT NULL tenant_id | FAIL |
| 7 | Write | UPDATE tenant_id to different | FAIL |
| 8 | Write | Cross-tenant UPDATE via subquery | FAIL |
| 9 | Write | INSERT correct tenant_id | SUCCESS |
| 10 | Abuse | Mixed-tenant transaction | FAIL / partial |
| 11 | Abuse | Bulk UPDATE across tenants | No cross-tenant effect |
| 12 | Abuse | SECURITY DEFINER bypass attempt | Audited, not bypassed |
| 13 | Abuse | COPY with wrong tenant | FAIL |
| 14 | Cross-table | JOIN across tenants | 0 rows |
| 15 | Cross-table | LATERAL subquery | Filtered |
| 16 | Cross-table | COUNT(*) cross-tenant | 0 / correct count |
| 17 | Cross-table | Correlated EXISTS | No leakage |
| 18 | Cross-table | Scalar subquery | Filtered |
| 19 | Plan cache | PREPARE → SET A → EXECUTE → SET B → EXECUTE | Correct per-tenant |
| 20 | Plan cache | Same as #19 + row count assertion | Counts match expected |
| 21 | Fn cache | DEFINER fn called twice, different tenants | Results differ correctly |

---

## Phase 6 — Bootstrap Gate

#### [NEW/MODIFY] [verify_migration_bootstrap.sh](file:///home/mwiza/workspace/Symphony/scripts/db/verify_migration_bootstrap.sh)

```bash
dropdb --if-exists symphony_bootstrap_test
createdb symphony_bootstrap_test
DATABASE_URL="..." scripts/db/migrate.sh
# Must complete with 0 errors
dropdb symphony_bootstrap_test
```

---

## Phase 7 — Admin Access (Governance Hardened)

Per-table read-only `SECURITY DEFINER` functions. **Audited privileged reads — NOT a security boundary.**

> [!WARNING]
> `SET ROLE` inside `SECURITY DEFINER` does not reliably reduce privileges. Correct model: **function OWNER IS the restricted role** (`OWNER TO symphony_reader`).

**Function pattern:**

```sql
CREATE OR REPLACE FUNCTION admin_read_<table>(p_limit int DEFAULT 100)
RETURNS TABLE (/* business columns ONLY */)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  RAISE LOG 'ADMIN_ELEVATION: user=% fn=% limit=% ip=%',
    current_user, 'admin_read_<table>', p_limit, inet_client_addr();
  RETURN QUERY SELECT /* columns */ FROM public.<table>
    ORDER BY created_at DESC LIMIT p_limit;
END;
$$;

ALTER FUNCTION admin_read_<table> OWNER TO symphony_reader;
REVOKE ALL ON FUNCTION admin_read_<table> FROM PUBLIC;
GRANT EXECUTE ON FUNCTION admin_read_<table> TO symphony_ops_role;
```

**`symphony_reader`:** `NOLOGIN`, `BYPASSRLS`, `SELECT` on specific tables only, NOT superuser.

**Four governance layers:**
1. **Lint gate** — new DEFINER checked against approved list
2. **CI audit** — `pg_auth_members` query for unexpected members
3. **Periodic review** — quarterly grant review
4. **Usage monitoring** — `pg_stat_user_functions` anomaly detection

---

## Trust Boundaries (What This System Does NOT Protect Against)

| Threat | Status | Mechanism | Limitations |
|---|---|---|---|
| Cross-tenant data access | ✅ Enforced | RESTRICTIVE RLS | Assumes setter called |
| Cross-tenant writes | ✅ Enforced | WITH CHECK = USING | Same |
| SQL injection bypassing RLS | ❌ No | Defense-in-depth, not boundary | Trusted clients only |
| Table owner bypassing RLS | ❌ No | Owner always bypasses | Use non-owner app roles |
| BYPASSRLS role misuse | ⚠️ Governed | CI whitelist + audit | `symphony_reader` bypasses FORCE RLS |
| FORCE RLS bypass | ⚠️ Known gap | Does NOT apply to BYPASSRLS roles | By design for admin reads |
| GUC misuse (direct SET) | ⚠️ Observable | Lint + runtime leakage check | **Possible and relies on application discipline.** Setter wrapper is mandatory but not structurally impossible to bypass without revoking system `set_config()`. |
| Function dependency drift | ⚠️ Advisory | Fn hash + manual ack | Leaf only |
| Schema evolution (new table) | ✅ Enforced | Runtime kill switch (in-txn) + YAML↔DB parity | Kill switch runs before COMMIT |
| Superuser access | ❌ Out of scope | — | Superusers bypass everything |

---

## Rollback Confidence

| Property | Status |
|---|---|
| Snapshot is executable SQL | ✅ |
| Snapshot validated via dry-run restore | ✅ |
| Fingerprint stored for audit (not blocking) | ✅ |
| Function hash stored (advisory drift signal) | ✅ |
| Rollback script is zero-manual-steps | ✅ |
| Guard prevents re-run on applied state | ✅ |
| Emergency override available (`force_override`) | ✅ |
| Post-generation sanity assertion | ✅ |
| Runtime coverage kill switch (before COMMIT) | ✅ |
| Trust boundaries explicitly documented | ✅ |

---

## Full Phase Summary

| Phase | Key Deliverables |
|---|---|
| 0 | YAML registry, `_rls_table_config`, hard validation (FK + NOT NULL + NOT DEFERRABLE), partition check, traffic tiers, snapshot (audit), fn hash (advisory), structural policy preservation |
| 1 | Single-txn: infrastructure tables + guard + two-key lock + blocker report + standardized retry runner + **destructive reset** (structural preservation) + **idempotent deterministic generation** + GUC hardening + **post-gen sanity assertion** + **runtime coverage kill switch** |
| 1R | Executable rollback |
| 2 | Dual tenant getters (strict + permissive) + mandatory setter wrapper |
| 3 | Lint: YAML parity, no manual policies, no direct SET, USING/WC parity, tenant presence, no nested UDF, DEFINER gate, grant whitelist |
| 4 | Verifier: binary drift (exactly 2 policies), target coverage, YAML↔DB parity, FK integrity, GUC leakage, role audit |
| 5 | 21 adversarial tests |
| 6 | Bootstrap gate (0 errors) |
| 7 | DEFINER w/ OWNER TO symphony_reader + 4-layer governance |
| TB | Trust boundaries: honest documentation of protections and limitations |

---

## Verification Plan

```bash
python3 tests/rls_born_secure/run_tests.py
python3 scripts/db/lint_rls_born_secure.py schema/migrations/0095_*.sql
DATABASE_URL="..." bash scripts/audit/verify_gf_rls_runtime.sh
DATABASE_URL="..." bash tests/rls_runtime/test_rls_dual_policy_access.sh
bash scripts/db/verify_migration_bootstrap.sh
```
