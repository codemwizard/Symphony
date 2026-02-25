-- TSK-P1-TEN-002: enforce tenant RLS isolation on all public tables that carry tenant_id.
CREATE OR REPLACE FUNCTION public.current_tenant_id_or_null()
RETURNS uuid
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v text;
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

COMMENT ON FUNCTION public.current_tenant_id_or_null() IS
  'Returns app.current_tenant_id::uuid when set and valid; NULL otherwise (fail-closed for tenant RLS).';

DO $$
DECLARE
  rec record;
  policy_name text;
  policy_expr text := 'tenant_id = public.current_tenant_id_or_null()';
BEGIN
  FOR rec IN
    SELECT c.oid, c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND a.attname = 'tenant_id'
      AND a.attisdropped = false
  LOOP
    policy_name := format('rls_tenant_isolation_%s', rec.relname);

    IF NOT EXISTS (
      SELECT 1
      FROM pg_policy p
      WHERE p.polrelid = rec.oid
        AND p.polname = policy_name
    ) THEN
      EXECUTE format(
        'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR ALL TO PUBLIC USING (%s) WITH CHECK (%s)',
        policy_name,
        rec.relname,
        policy_expr,
        policy_expr
      );
    END IF;

    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', rec.relname);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', rec.relname);
  END LOOP;
END;
$$;
