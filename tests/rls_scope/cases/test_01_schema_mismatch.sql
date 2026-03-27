-- TEST 1: Schema-qualified mismatch
-- Purpose: Proves parser normalization handles public.X == X
-- Expected: PASS (normalization works correctly)

CREATE TABLE public.adapter_registrations (
  tenant_id uuid
);

ALTER TABLE adapter_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE adapter_registrations FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_adapter_registrations
  ON adapter_registrations
  AS RESTRICTIVE FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
