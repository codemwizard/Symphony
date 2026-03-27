-- TEST 13: Role-scoped policy (TO authenticated_role instead of TO PUBLIC)
-- Purpose: Catches role-scoped grant that breaks canonical pattern
-- Expected: FAIL — ROLE_SCOPED_POLICY

CREATE TABLE public.test_table (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL
);

ALTER TABLE public.test_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_table FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_test_table ON public.test_table
  AS RESTRICTIVE FOR ALL TO authenticated_role
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
