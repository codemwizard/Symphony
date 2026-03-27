-- TEST 18: Missing WITH CHECK clause
-- Purpose: Catches policy with USING but no WITH CHECK
-- Expected: FAIL — WRONG_WITH_CHECK

CREATE TABLE public.test_table (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL
);

ALTER TABLE public.test_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_table FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_test_table ON public.test_table
  FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null());
