-- ══════════════════════════════════════════════════════════════════════════════
-- 0095: RLS Dual-Policy Architecture — Deterministic Migration
-- TSK-RLS-ARCH-001 v10.1
--
-- PREREQUISITES:
--   1. Phase 0 must have been run (phase0_rls_enumerate.py)
--   2. _rls_table_config must be populated
--   3. _preserved_policies must be populated
--   4. Use run_migration_0095.sh — DO NOT run directly
--
-- TRANSACTION BOUNDARY: entire migration runs in a single transaction.
-- Any failure → full ROLLBACK. No partial policy state possible.
-- ══════════════════════════════════════════════════════════════════════════════

BEGIN;

-- ── 1.1 Infrastructure tables (idempotent) ──────────────────────────────────

CREATE TABLE IF NOT EXISTS public._migration_guards (
    key TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    skip_guard BOOLEAN NOT NULL DEFAULT false,
    force_override BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS public._migration_fingerprints (
    migration_key TEXT NOT NULL,
    fingerprint_type TEXT NOT NULL,
    fingerprint_hash TEXT NOT NULL,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (migration_key, fingerprint_type)
);

CREATE TABLE IF NOT EXISTS public._migration_fn_hashes (
    migration_key TEXT NOT NULL,
    function_name TEXT NOT NULL,
    definition_hash TEXT NOT NULL,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (migration_key, function_name)
);

-- ── 1.2 Migration guard ─────────────────────────────────────────────────────

DO $guard$ BEGIN
    -- Already applied and NOT flagged for re-run
    IF EXISTS (
        SELECT 1 FROM _migration_guards
        WHERE key = '0095_rls_dual_policy' AND skip_guard = false
    )
    AND EXISTS (
        SELECT 1 FROM _migration_fingerprints
        WHERE migration_key = '0095_rls_dual_policy'
          AND fingerprint_type = 'post_migration'
    )
    THEN
        RAISE EXCEPTION 'Migration 0095 already applied. To re-run: UPDATE _migration_guards SET skip_guard = true WHERE key = ''0095_rls_dual_policy'';';
    END IF;
END $guard$;

-- ── 1.3 Advisory lock (two-key) ─────────────────────────────────────────────

DO $lock$ DECLARE acquired boolean; BEGIN
    acquired := pg_try_advisory_xact_lock(
        hashtext(current_database()),
        hashtext('0095_rls_dual_policy'));
    IF NOT acquired THEN
        RAISE EXCEPTION 'Migration 0095 running in another session — aborting';
    END IF;
END $lock$;

-- ── 1.4 Preflight blocker report ────────────────────────────────────────────

SET LOCAL lock_timeout = '5s';

DO $blocker$ DECLARE r RECORD; found BOOLEAN := false; BEGIN
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
          AND c.relname IN (
              SELECT table_name FROM _rls_table_config
              WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
          )
    LOOP
        RAISE WARNING 'BLOCKER: pid=% user=% dur=% q=%',
            r.pid, r.usename, r.dur, r.qry;
        found := true;
    END LOOP;
    IF found THEN
        RAISE EXCEPTION 'Sessions holding locks on target tables — abort. Retry in maintenance window.';
    END IF;
END $blocker$;

-- ── 1.6 Destructive reset ───────────────────────────────────────────────────

DO $reset$ DECLARE pol RECORD; BEGIN
    FOR pol IN
        SELECT p.polname, c.relname
        FROM pg_policy p
        JOIN pg_class c ON c.oid = p.polrelid
        WHERE c.relnamespace = 'public'::regnamespace
          AND c.relname IN (
              SELECT table_name FROM _rls_table_config
              WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
          )
    LOOP
        EXECUTE format('DROP POLICY %I ON public.%I', pol.polname, pol.relname);
    END LOOP;
END $reset$;

-- Reapply preserved policies from structural snapshot
DO $restore$ DECLARE pol RECORD; BEGIN
    FOR pol IN SELECT * FROM _preserved_policies
    LOOP
        EXECUTE pol.create_sql;
        RAISE NOTICE 'RESTORED: %.%', pol.table_name, pol.policy_name;
    END LOOP;
END $restore$;


-- ── 2.1 Tenant functions (dual getter + mandatory setter) ───────────────────

-- Strict getter (for application code — EXCEPTION on NULL)
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

-- Permissive getter (for RLS expressions only — returns NULL → fail-closed)
CREATE OR REPLACE FUNCTION public.current_tenant_id_or_null()
RETURNS uuid LANGUAGE plpgsql STABLE
SET search_path = pg_catalog, public
AS $$
DECLARE v text;
BEGIN
    v := current_setting('app.current_tenant_id', true);
    IF v IS NULL OR btrim(v) = '' THEN
        RETURN NULL;
    END IF;
    BEGIN
        RETURN v::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
        RETURN NULL;
    END;
END;
$$;

-- Mandatory setter wrapper (SECURITY DEFINER)
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
END;
$$;

REVOKE ALL ON FUNCTION public.set_tenant_context(uuid) FROM PUBLIC;
-- Grant to app role (adjust role name as needed)
-- GRANT EXECUTE ON FUNCTION public.set_tenant_context(uuid) TO app_role;


-- ── 1.7 Idempotent deterministic generation (DIRECT tables) ─────────────────

DO $gen_direct$ DECLARE tbl RECORD; col_exists BOOLEAN; BEGIN
    FOR tbl IN SELECT * FROM _rls_table_config WHERE isolation_type = 'DIRECT'
    LOOP
        -- Safety: verify tenant column actually exists in DB
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = tbl.table_name
              AND column_name = tbl.tenant_column
        ) INTO col_exists;

        IF NOT col_exists THEN
            RAISE WARNING 'SKIPPING %: tenant_column "%" does not exist in table', tbl.table_name, tbl.tenant_column;
            CONTINUE;
        END IF;

        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl.table_name);
        EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', tbl.table_name);

        -- Idempotent: drop before create
        EXECUTE format('DROP POLICY IF EXISTS rls_base_%I ON public.%I',
            tbl.table_name, tbl.table_name);
        EXECUTE format('DROP POLICY IF EXISTS rls_iso_%I ON public.%I',
            tbl.table_name, tbl.table_name);

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
END $gen_direct$;

-- ── 1.7 Idempotent deterministic generation (JOIN tables) ───────────────────

DO $gen_join$ DECLARE tbl RECORD; BEGIN
    FOR tbl IN SELECT * FROM _rls_table_config WHERE isolation_type = 'JOIN'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl.table_name);
        EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', tbl.table_name);

        -- Idempotent: drop before create
        EXECUTE format('DROP POLICY IF EXISTS rls_base_%I ON public.%I',
            tbl.table_name, tbl.table_name);
        EXECUTE format('DROP POLICY IF EXISTS rls_iso_%I ON public.%I',
            tbl.table_name, tbl.table_name);

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
END $gen_join$;


-- ── 1.10 Post-generation sanity assertion ───────────────────────────────────

DO $sanity$ DECLARE tbl RECORD; pol_qual TEXT; fail BOOLEAN := false; BEGIN
    -- Assert every DIRECT table's isolation policy references its tenant column
    FOR tbl IN SELECT * FROM _rls_table_config WHERE isolation_type = 'DIRECT'
    LOOP
        SELECT pg_get_expr(p.polqual, p.polrelid) INTO pol_qual
        FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
        WHERE c.relname = tbl.table_name
          AND p.polname = format('rls_iso_%s', tbl.table_name)
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
        WHERE c.relname = tbl.table_name
          AND p.polname = format('rls_iso_%s', tbl.table_name)
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

    RAISE NOTICE 'Post-generation sanity assertion: PASSED';
END $sanity$;


-- ── 1.11 Runtime coverage kill switch ───────────────────────────────────────

DO $kill_switch$ DECLARE uncovered TEXT; BEGIN
    -- Abort if any tenant table exists in DB but not in config
    SELECT string_agg(c.relname, ', ') INTO uncovered
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND c.relname NOT LIKE '\_%'
      AND EXISTS (
          SELECT 1 FROM pg_attribute a
          WHERE a.attrelid = c.oid
            AND a.attname = 'tenant_id'
            AND NOT a.attisdropped
      )
      AND c.relname NOT IN (SELECT table_name FROM _rls_table_config);

    IF uncovered IS NOT NULL THEN
        RAISE EXCEPTION 'COVERAGE KILL SWITCH: tables with tenant_id not in _rls_table_config: %. Update rls_tables.yml and re-run.', uncovered;
    END IF;

    -- Abort if any config table lacks RLS after generation
    SELECT string_agg(c.table_name, ', ') INTO uncovered
    FROM _rls_table_config c
    WHERE c.isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
      AND NOT EXISTS (
          SELECT 1 FROM pg_class pc
          WHERE pc.relname = c.table_name
            AND pc.relnamespace = 'public'::regnamespace
            AND pc.relrowsecurity = true
            AND pc.relforcerowsecurity = true
      );

    IF uncovered IS NOT NULL THEN
        RAISE EXCEPTION 'COVERAGE KILL SWITCH: config tables without RLS enabled: %. Generation failed.', uncovered;
    END IF;

    RAISE NOTICE 'Coverage kill switch: PASSED';
END $kill_switch$;


-- ── 1.9 Post-migration fingerprint + guard update ───────────────────────────

INSERT INTO _migration_fingerprints (migration_key, fingerprint_type, fingerprint_hash)
VALUES ('0095_rls_dual_policy', 'post_migration',
    (SELECT md5(string_agg(
        format('%s:%s:%s:%s',
            c.relname, p.polpermissive, p.polcmd,
            coalesce(pg_get_expr(p.polqual, p.polrelid), '')),
        '|' ORDER BY c.relname, p.polname
    )) FROM pg_policy p JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relnamespace = 'public'::regnamespace
      AND c.relname IN (
          SELECT table_name FROM _rls_table_config
          WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
      ))
)
ON CONFLICT (migration_key, fingerprint_type)
DO UPDATE SET fingerprint_hash = EXCLUDED.fingerprint_hash,
             captured_at = now();

INSERT INTO _migration_guards (key, applied_at, skip_guard)
VALUES ('0095_rls_dual_policy', now(), false)
ON CONFLICT (key)
DO UPDATE SET applied_at = now(), skip_guard = false, force_override = false;


COMMIT;
