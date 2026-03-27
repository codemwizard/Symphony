-- TEST 11: Real scope violation — ALTER on table not created in this migration
-- Purpose: Catches cross-table contamination (modifying a table you don't own)
-- Expected: FAIL — SCOPE_VIOLATION

CREATE TABLE public.adapter_registrations (
  tenant_id uuid
);

ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.tenants ADD COLUMN gf_test TEXT;
