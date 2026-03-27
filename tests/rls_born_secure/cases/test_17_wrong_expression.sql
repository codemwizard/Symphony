-- TEST 17: Wrong expression (legacy current_setting pattern)
-- Purpose: Catches the exact regression pattern used in GF migrations
-- Expected: FAIL — WRONG_USING_EXPRESSION, WRONG_WITH_CHECK

CREATE TABLE public.test_table (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL
);

ALTER TABLE public.test_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_table FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_test_table ON public.test_table
  FOR ALL TO PUBLIC
  USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID)
  WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::UUID);
