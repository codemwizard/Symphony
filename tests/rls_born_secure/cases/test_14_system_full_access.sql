-- TEST 14: system_full_access policy present
-- Purpose: Catches dormant privilege escalation pattern
-- Expected: FAIL — SYSTEM_FULL_ACCESS_PRESENT, WRONG_POLICY_COUNT

CREATE TABLE public.test_table (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL
);

ALTER TABLE public.test_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_table FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_test_table ON public.test_table
  FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());

CREATE POLICY test_table_system_full_access ON public.test_table
  FOR ALL TO system_role
  USING (true);
