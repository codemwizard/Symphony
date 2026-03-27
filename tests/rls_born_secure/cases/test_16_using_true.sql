-- TEST 16: USING (true) policy
-- Purpose: Catches unconditional access bypass
-- Expected: FAIL — USING_TRUE_POLICY

CREATE TABLE public.test_table (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL
);

ALTER TABLE public.test_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_table FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_test_table ON public.test_table
  FOR ALL TO PUBLIC
  USING (true);
