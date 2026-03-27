-- TEST 11: Missing FORCE RLS
-- Purpose: Table has ENABLE but not FORCE — superuser bypass possible
-- Expected: FAIL — MISSING_FORCE_RLS

CREATE TABLE public.test_table (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL
);

ALTER TABLE public.test_table ENABLE ROW LEVEL SECURITY;
-- NOTE: No FORCE ROW LEVEL SECURITY

CREATE POLICY rls_tenant_isolation_test_table ON public.test_table
  FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
