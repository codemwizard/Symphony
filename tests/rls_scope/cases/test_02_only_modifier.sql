-- TEST 2: ALTER TABLE with ONLY modifier
-- Purpose: Proves parser handles ONLY keyword without false positive
-- Expected: PASS

CREATE TABLE public.adapter_registrations (
  tenant_id uuid
);

ALTER TABLE ONLY public.adapter_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.adapter_registrations FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_adapter_registrations
  ON public.adapter_registrations
  AS RESTRICTIVE FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
