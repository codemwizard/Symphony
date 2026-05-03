

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

-- RLS Table Configuration (deterministic for CI)
CREATE TABLE IF NOT EXISTS public._rls_table_config (
  table_name TEXT PRIMARY KEY,
  isolation_type TEXT NOT NULL CHECK (isolation_type IN ('DIRECT', 'JOIN', 'GLOBAL', 'JURISDICTION')),
  tenant_column TEXT,
  parent_table TEXT,
  fk_column TEXT,
  parent_pk TEXT,
  loaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Population from canonical registry (rls_tables.yml)
INSERT INTO public._rls_table_config
  (table_name, isolation_type, tenant_column, parent_table, fk_column, parent_pk)
VALUES
  ('tenants', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('tenant_clients', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('tenant_members', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('billing_usage_events', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('escrow_accounts', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('escrow_events', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('escrow_envelopes', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('escrow_reservations', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('programs', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('persons', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('members', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('member_devices', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('member_device_events', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('program_migration_events', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('sim_swap_alerts', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('regulatory_incidents', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('instruction_status_projection', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('evidence_bundle_projection', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('escrow_summary_projection', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('incident_case_projection', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('program_member_summary_projection', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('internal_ledger_journals', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('internal_ledger_postings', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('supplier_registry', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('program_supplier_allowlist', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('tenant_registry', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('programme_registry', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('programme_policy_binding', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('payment_outbox_attempts', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('payment_outbox_pending', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('external_proofs', 'DIRECT', 'tenant_id', NULL, NULL, NULL),
  ('ingress_attestations', 'GLOBAL', NULL, NULL, NULL, NULL),
  ('risk_formula_versions', 'GLOBAL', NULL, NULL, NULL, NULL),
  ('adapter_registrations', 'DIRECT', 'tenant_id', NULL, NULL, NULL)
ON CONFLICT (table_name) DO UPDATE SET
  isolation_type = EXCLUDED.isolation_type,
  tenant_column = EXCLUDED.tenant_column,
  parent_table = EXCLUDED.parent_table,
  fk_column = EXCLUDED.fk_column,
  parent_pk = EXCLUDED.parent_pk,
  loaded_at = now();


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

DO $$ DECLARE acquired boolean; BEGIN
  acquired := pg_try_advisory_xact_lock(
    hashtext(current_database()),
    hashtext('0095_rls_dual_policy'));
  IF NOT acquired THEN
    RAISE EXCEPTION 'Migration 0095 running in another session — aborting';
  END IF;
END $$;

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

-- Level 0: root parent tables
LOCK TABLE public.tenants IN ACCESS EXCLUSIVE MODE NOWAIT;
-- Level 1: child tables
LOCK TABLE public.tenant_members IN ACCESS EXCLUSIVE MODE NOWAIT;
-- Level 2: independent tables by traffic tier
LOCK TABLE public.adapter_registrations IN ACCESS EXCLUSIVE MODE NOWAIT;

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

ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants FORCE ROW LEVEL SECURITY;
-- Drop any policies using bypass_rls or NULLIF patterns

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


