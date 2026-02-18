-- 0019_member_tenant_consistency_guard.sql
-- Enforce member/tenant consistency on ingress attestations

CREATE OR REPLACE FUNCTION public.enforce_member_tenant_match()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  m_tenant uuid;
BEGIN
  IF NEW.member_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT tenant_id INTO m_tenant
  FROM public.tenant_members
  WHERE member_id = NEW.member_id;

  IF m_tenant IS NULL THEN
    RAISE EXCEPTION 'member_id not found'
      USING ERRCODE = '23503';
  END IF;

  IF NEW.tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant_id required when member_id is set'
      USING ERRCODE = 'P7201';
  END IF;

  IF m_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'member/tenant mismatch'
      USING ERRCODE = 'P7202';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ingress_member_tenant_match ON public.ingress_attestations;
CREATE TRIGGER trg_ingress_member_tenant_match
BEFORE INSERT ON public.ingress_attestations
FOR EACH ROW
EXECUTE FUNCTION public.enforce_member_tenant_match();
