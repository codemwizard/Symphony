-- TEST 12: RESTRICTIVE policy (should be default PERMISSIVE)
-- Purpose: Catches AS RESTRICTIVE — blocks all access without companion PERMISSIVE
-- Expected: FAIL — IS_RESTRICTIVE

CREATE TABLE public.test_table (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL
);

ALTER TABLE public.test_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_table FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_test_table ON public.test_table
  AS RESTRICTIVE FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
