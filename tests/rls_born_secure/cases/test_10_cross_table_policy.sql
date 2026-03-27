-- TEST 10: Cross-table policy contamination
-- Purpose: Catches table b having no policy (both policies on table a)
-- Expected: FAIL — BORN_SECURE_VIOLATION:missing_policy on table b
-- (enforced by lint_rls_born_secure.sh)

CREATE TABLE public.a (tenant_id uuid);
CREATE TABLE public.b (tenant_id uuid);

ALTER TABLE public.a ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.a FORCE ROW LEVEL SECURITY;
ALTER TABLE public.b ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.b FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_a
  ON public.a
  FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());

CREATE POLICY rls_tenant_isolation_b
  ON public.a
  FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
