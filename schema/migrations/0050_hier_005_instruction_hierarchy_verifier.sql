-- 0050_hier_005_instruction_hierarchy_verifier.sql
-- TSK-P1-HIER-005: member devices with tenant-safe reverse lookup indexes.

CREATE OR REPLACE FUNCTION public.verify_instruction_hierarchy(
  p_instruction_id TEXT,
  p_tenant_id UUID,
  p_participant_id TEXT,
  p_program_id UUID,
  p_entity_id UUID,
  p_member_id UUID,
  p_device_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  -- 1) tenant -> participant linkage (instruction-scoped)
  IF NOT EXISTS (
    SELECT 1
    FROM public.ingress_attestations ia
    WHERE ia.instruction_id = p_instruction_id
      AND ia.tenant_id = p_tenant_id
      AND ia.participant_id = p_participant_id
  ) THEN
    RAISE EXCEPTION 'tenant-to-participant linkage invalid for instruction'
      USING ERRCODE = 'P7299';
  END IF;

  -- 2) participant -> program linkage (tenant-safe program ownership check)
  IF NOT EXISTS (
    SELECT 1
    FROM public.programs pr
    WHERE pr.program_id = p_program_id
      AND pr.tenant_id = p_tenant_id
  ) THEN
    RAISE EXCEPTION 'participant-to-program linkage invalid'
      USING ERRCODE = 'P7300';
  END IF;

  -- 3) entity -> program linkage
  IF p_entity_id IS DISTINCT FROM p_program_id THEN
    RAISE EXCEPTION 'program-to-entity linkage invalid'
      USING ERRCODE = 'P7301';
  END IF;

  -- 4) member -> entity linkage
  IF NOT EXISTS (
    SELECT 1
    FROM public.members m
    WHERE m.member_id = p_member_id
      AND m.tenant_id = p_tenant_id
      AND m.entity_id = p_entity_id
  ) THEN
    RAISE EXCEPTION 'entity-to-member linkage invalid'
      USING ERRCODE = 'P7305';
  END IF;

  -- 5) device -> member linkage (active-path device check)
  IF NOT EXISTS (
    SELECT 1
    FROM public.member_devices md
    WHERE md.tenant_id = p_tenant_id
      AND md.member_id = p_member_id
      AND md.device_id_hash = p_device_id
      AND md.status = 'ACTIVE'
  ) THEN
    RAISE EXCEPTION 'member-to-device linkage invalid'
      USING ERRCODE = 'P7306';
  END IF;

  RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION public.verify_instruction_hierarchy(TEXT, UUID, TEXT, UUID, UUID, UUID, TEXT) IS
  'Phase-1 hierarchy guard: instruction/tenant/participant/program/entity/member/device linkage with deterministic SQLSTATE failures.';

