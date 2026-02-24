-- 0047_hier_002_programs_person_member_bridge.sql
-- TSK-P1-HIER-002: Programs + program_escrow_id bridge.

CREATE TABLE IF NOT EXISTS public.persons (
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  person_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  person_ref_hash TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','SUSPENDED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_persons_tenant_ref
  ON public.persons(tenant_id, person_ref_hash);

COMMENT ON TABLE public.persons IS
  'Phase-1 person envelope: tenant-scoped pseudonymous identity with hashed reference and status gating.';

CREATE OR REPLACE FUNCTION public.touch_persons_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_persons_updated_at ON public.persons;
CREATE TRIGGER trg_touch_persons_updated_at
BEFORE UPDATE ON public.persons
FOR EACH ROW
EXECUTE FUNCTION public.touch_persons_updated_at();

CREATE TABLE IF NOT EXISTS public.members (
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  member_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  tenant_member_id UUID NOT NULL REFERENCES public.tenant_members(member_id) ON DELETE RESTRICT,
  person_id UUID NOT NULL REFERENCES public.persons(person_id) ON DELETE RESTRICT,
  entity_id UUID NOT NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
  member_ref_hash TEXT NOT NULL,
  kyc_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING','VERIFIED','REJECTED')),
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','ARCHIVED')),
  ceiling_amount_minor BIGINT NOT NULL DEFAULT 0 CHECK (ceiling_amount_minor >= 0),
  ceiling_currency CHAR(3) NOT NULL DEFAULT 'USD',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (tenant_id, person_id, entity_id),
  UNIQUE (tenant_id, member_ref_hash)
);

CREATE INDEX IF NOT EXISTS idx_members_tenant_member
  ON public.members(tenant_id, member_id);

CREATE INDEX IF NOT EXISTS idx_members_tenant_member_ref
  ON public.members(tenant_id, member_ref_hash);

CREATE INDEX IF NOT EXISTS idx_members_entity_active
  ON public.members(tenant_id, entity_id, status)
  WHERE status = 'ACTIVE';

CREATE INDEX IF NOT EXISTS idx_members_entity_member_ref_active
  ON public.members(tenant_id, entity_id, member_ref_hash)
  WHERE status = 'ACTIVE';

COMMENT ON TABLE public.members IS
  'Phase-1 membership enrollment: program-scoped rows that link tenant_members/persons to programs with ceilings and KYC posture.';

CREATE OR REPLACE FUNCTION public.touch_members_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.metadata := COALESCE(NEW.metadata, '{}'::jsonb);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_members_updated_at ON public.members;
CREATE TRIGGER trg_touch_members_updated_at
BEFORE INSERT OR UPDATE ON public.members
FOR EACH ROW
EXECUTE FUNCTION public.touch_members_updated_at();

REVOKE ALL ON TABLE public.persons FROM PUBLIC;
REVOKE ALL ON TABLE public.members FROM PUBLIC;

