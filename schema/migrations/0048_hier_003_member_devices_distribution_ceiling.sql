-- 0048_hier_003_member_devices_distribution_ceiling.sql
-- TSK-P1-HIER-003: Distribution entities + tenant denorm + ceilings.

CREATE TABLE IF NOT EXISTS public.member_devices (
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  member_id UUID NOT NULL REFERENCES public.members(member_id) ON DELETE RESTRICT,
  device_id_hash TEXT NOT NULL,
  iccid_hash TEXT,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','REVOKED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (member_id, device_id_hash),
  UNIQUE (member_id, device_id_hash)
);

CREATE INDEX IF NOT EXISTS idx_member_devices_tenant_member
  ON public.member_devices(tenant_id, member_id);

CREATE INDEX IF NOT EXISTS idx_member_devices_active_device
  ON public.member_devices(tenant_id, device_id_hash)
  WHERE status = 'ACTIVE';

CREATE INDEX IF NOT EXISTS idx_member_devices_active_iccid
  ON public.member_devices(tenant_id, iccid_hash)
  WHERE iccid_hash IS NOT NULL AND status = 'ACTIVE';

COMMENT ON TABLE public.member_devices IS
  'Phase-1 device distribution mapping: tenant-denormalized member device anchors with active lookups and optional ICCID hash.';

REVOKE ALL ON TABLE public.member_devices FROM PUBLIC;
