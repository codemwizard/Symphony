-- 0049_hier_004_member_device_events_append_only.sql
-- TSK-P1-HIER-004: person model explicit + enrollment model (member device events).

CREATE TABLE IF NOT EXISTS public.member_device_events (
  event_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  tenant_id UUID NOT NULL,
  member_id UUID NOT NULL REFERENCES public.members(member_id) ON DELETE RESTRICT,
  instruction_id TEXT NOT NULL,
  device_id TEXT,
  device_id_hash TEXT,
  iccid_hash TEXT,
  event_type TEXT NOT NULL CHECK (event_type IN ('ENROLLED_DEVICE','UNREGISTERED_DEVICE','REVOKED_DEVICE_ATTEMPT')),
  observed_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT member_device_events_device_id_event_type_chk CHECK (
    (device_id IS NULL) = (event_type IN ('UNREGISTERED_DEVICE','REVOKED_DEVICE_ATTEMPT'))
  ),
  CONSTRAINT member_device_events_ingress_fk FOREIGN KEY (tenant_id, instruction_id)
    REFERENCES public.ingress_attestations(tenant_id, instruction_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_member_device_events_tenant_member_observed
  ON public.member_device_events(tenant_id, member_id, observed_at DESC);

CREATE INDEX IF NOT EXISTS idx_member_device_events_instruction
  ON public.member_device_events(instruction_id);

CREATE OR REPLACE FUNCTION public.deny_member_device_events_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'member_device_events is append-only'
    USING ERRCODE = 'P0001';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_member_device_events_mutation ON public.member_device_events;
CREATE TRIGGER trg_deny_member_device_events_mutation
BEFORE UPDATE OR DELETE ON public.member_device_events
FOR EACH ROW
EXECUTE FUNCTION public.deny_member_device_events_mutation();

COMMENT ON TABLE public.member_device_events IS
  'Phase-1 append-only member device event stream anchored to ingress attestations and tenant/member scope.';

REVOKE ALL ON TABLE public.member_device_events FROM PUBLIC;
