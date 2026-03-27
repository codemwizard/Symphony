-- TEST 12: CREATE INDEX after CREATE POLICY (permitted)
-- Purpose: Proves CREATE INDEX after policy is NOT a violation
-- Expected: PASS

CREATE TABLE public.adapter_registrations (
  tenant_id uuid
);

ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adapter_registrations FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_adapter_registrations
  ON public.adapter_registrations
  AS RESTRICTIVE FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());

CREATE INDEX idx_adapter_tenant ON public.adapter_registrations (tenant_id);
