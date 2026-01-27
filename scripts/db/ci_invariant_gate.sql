-- ============================================================
-- ci_invariant_gate.sql
-- Hard fail if core invariants are violated after migrations.
-- ============================================================

DO $$
DECLARE
  missing TEXT[];
  r RECORD;
  has_is_active BOOLEAN;
  checksum_nullable TEXT;
  public_has_schema_create BOOLEAN;
BEGIN
  -- ----------------------------------------------------------
  -- 1) Boot schema coverage: required relations exist
  -- ----------------------------------------------------------
  missing := ARRAY[]::TEXT[];

  IF to_regclass('public.schema_migrations') IS NULL THEN
    missing := array_append(missing, 'public.schema_migrations');
  END IF;

  IF to_regclass('public.payment_outbox_pending') IS NULL THEN
    missing := array_append(missing, 'public.payment_outbox_pending');
  END IF;

  IF to_regclass('public.payment_outbox_attempts') IS NULL THEN
    missing := array_append(missing, 'public.payment_outbox_attempts');
  END IF;

  IF to_regclass('public.participant_outbox_sequences') IS NULL THEN
    missing := array_append(missing, 'public.participant_outbox_sequences');
  END IF;

  IF to_regclass('public.policy_versions') IS NULL THEN
    missing := array_append(missing, 'public.policy_versions');
  END IF;

  IF array_length(missing, 1) IS NOT NULL THEN
    RAISE EXCEPTION 'CI gate failed: missing required relations: %', missing;
  END IF;

  -- ----------------------------------------------------------
  -- 1b) Boot query compatibility
  --     SELECT version FROM policy_versions WHERE is_active = true
  -- ----------------------------------------------------------
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'policy_versions'
      AND column_name = 'is_active'
  ) INTO has_is_active;

  IF NOT has_is_active THEN
    RAISE EXCEPTION 'CI gate failed: policy_versions.is_active missing (boot query incompatible)';
  END IF;

  -- checksum must exist and be NOT NULL (required integrity binding)
  SELECT is_nullable
    INTO checksum_nullable
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'policy_versions'
    AND column_name = 'checksum';

  IF checksum_nullable IS NULL THEN
    RAISE EXCEPTION 'CI gate failed: policy_versions.checksum column missing';
  END IF;

  IF checksum_nullable <> 'NO' THEN
    RAISE EXCEPTION 'CI gate failed: policy_versions.checksum must be NOT NULL (integrity required)';
  END IF;

  -- Sanity: checksum must not be empty string
  IF EXISTS (
    SELECT 1
    FROM public.policy_versions
    WHERE checksum = ''
  ) THEN
    RAISE EXCEPTION 'CI gate failed: policy_versions.checksum contains empty string';
  END IF;

  -- Ensure the boot query is executable (even if it returns 0 rows)
  PERFORM 1 FROM public.policy_versions WHERE is_active = true LIMIT 1;

  -- ----------------------------------------------------------
  -- 2) PUBLIC grants absent where forbidden (core tables)
  -- Use information_schema (PUBLIC is a pseudo-role; avoid has_*_privilege for PUBLIC)
  -- ----------------------------------------------------------
  IF EXISTS (
    SELECT 1
    FROM information_schema.role_table_grants g
    WHERE g.grantee = 'PUBLIC'
      AND g.table_schema = 'public'
      AND g.table_name IN (
        'schema_migrations',
        'payment_outbox_pending',
        'payment_outbox_attempts',
        'participant_outbox_sequences',
        'policy_versions'
      )
  ) THEN
    RAISE EXCEPTION 'CI gate failed: PUBLIC has forbidden privileges on core tables';
  END IF;

  -- Defense-in-depth: verify PUBLIC has zero table privileges via ACL inspection.
  IF EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    CROSS JOIN LATERAL aclexplode(COALESCE(c.relacl, acldefault('r', c.relowner))) a
    WHERE n.nspname = 'public'
      AND c.relname IN (
        'schema_migrations',
        'payment_outbox_pending',
        'payment_outbox_attempts',
        'participant_outbox_sequences',
        'policy_versions'
      )
      AND a.grantee = 0 -- PUBLIC
  ) THEN
    RAISE EXCEPTION 'CI gate failed: PUBLIC has forbidden ACL privileges on core tables (via relacl)';
  END IF;

  -- ----------------------------------------------------------
  -- 3) No runtime DDL: PUBLIC has no CREATE on schema public
  -- Correctly detect PUBLIC schema CREATE via ACL inspection.
  -- ----------------------------------------------------------
  SELECT EXISTS (
    SELECT 1
    FROM pg_namespace n
    CROSS JOIN LATERAL aclexplode(COALESCE(n.nspacl, acldefault('n', n.nspowner))) a
    WHERE n.nspname = 'public'
      AND a.grantee = 0               -- PUBLIC
      AND a.privilege_type = 'CREATE'
  ) INTO public_has_schema_create;

  IF public_has_schema_create THEN
    RAISE EXCEPTION 'CI gate failed: PUBLIC has CREATE on schema public (runtime DDL not enforceable)';
  END IF;

  -- Also ensure runtime roles don't have CREATE on schema public
  FOR r IN
    SELECT * FROM (VALUES
      ('symphony_ingest'::text),
      ('symphony_executor'::text),
      ('symphony_readonly'::text),
      ('symphony_auditor'::text),
      ('symphony_control'::text),
      ('test_user'::text)
    ) v(role_name)
  LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.role_name) THEN
      IF has_schema_privilege(r.role_name, 'public', 'CREATE') THEN
        RAISE EXCEPTION 'CI gate failed: role % has CREATE on schema public', r.role_name;
      END IF;
    END IF;
  END LOOP;

  -- ----------------------------------------------------------
  -- 4) Append-only attempts: trigger + function exist
  -- ----------------------------------------------------------
  IF to_regprocedure('public.deny_outbox_attempts_mutation()') IS NULL THEN
    RAISE EXCEPTION 'CI gate failed: deny_outbox_attempts_mutation() missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'payment_outbox_attempts'
      AND t.tgname = 'trg_deny_outbox_attempts_mutation'
      AND t.tgenabled IN ('O','A')
      AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'CI gate failed: append-only trigger missing/disabled on payment_outbox_attempts';
  END IF;

  -- ----------------------------------------------------------
  -- 5) Option A: no overrides, period (control cannot mutate attempts)
  -- ----------------------------------------------------------
  IF EXISTS (
    SELECT 1
    FROM information_schema.role_table_grants g
    WHERE g.table_schema = 'public'
      AND g.table_name = 'payment_outbox_attempts'
      AND g.grantee = 'symphony_control'
      AND g.privilege_type IN ('UPDATE','DELETE','TRUNCATE','TRIGGER')
  ) THEN
    RAISE EXCEPTION 'CI gate failed: symphony_control has forbidden UPDATE/DELETE/TRUNCATE/TRIGGER on payment_outbox_attempts';
  END IF;

  -- ----------------------------------------------------------
  -- 6) Policy grace scaffolding: status column + single ACTIVE index
  -- ----------------------------------------------------------
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'policy_versions'
      AND column_name = 'status'
  ) THEN
    RAISE EXCEPTION 'CI gate failed: policy_versions.status missing (grace scaffolding)';
  END IF;

  -- Require canonical unique predicate index name (stable, not string-matched)
  IF to_regclass('public.ux_policy_versions_single_active') IS NULL THEN
    RAISE EXCEPTION 'CI gate failed: ux_policy_versions_single_active index missing (single ACTIVE policy not enforced)';
  END IF;

END $$;

SELECT 'CI_INVARIANT_GATE_OK' AS status;
