-- 0057_hier_010_program_migration_contract_alignment.sql
-- TSK-P1-HIER-010: align program migration contract + deterministic duplicate SQLSTATE.

ALTER TABLE public.program_migration_events
  ADD COLUMN IF NOT EXISTS new_member_id UUID;

UPDATE public.program_migration_events
SET new_member_id = migrated_member_id
WHERE new_member_id IS NULL;

ALTER TABLE public.program_migration_events
  ALTER COLUMN new_member_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'program_migration_events_new_member_id_fkey'
      AND conrelid = 'public.program_migration_events'::regclass
  ) THEN
    ALTER TABLE public.program_migration_events
      ADD CONSTRAINT program_migration_events_new_member_id_fkey
      FOREIGN KEY (new_member_id)
      REFERENCES public.members(member_id)
      ON DELETE RESTRICT;
  END IF;
END;
$$;

ALTER TABLE public.program_migration_events
  ALTER COLUMN reason DROP NOT NULL;

ALTER TABLE public.program_migration_events
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ;

UPDATE public.program_migration_events
SET created_at = COALESCE(created_at, migrated_at, NOW())
WHERE created_at IS NULL;

ALTER TABLE public.program_migration_events
  ALTER COLUMN created_at SET NOT NULL;

CREATE OR REPLACE FUNCTION public.migrate_person_to_program(
  p_tenant_id UUID,
  p_person_id UUID,
  p_from_program_id UUID,
  p_to_program_id UUID,
  p_new_entity_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_source_member public.members%ROWTYPE;
  v_new_member_id UUID;
  v_formula_version_id UUID;
  v_reason TEXT := NULLIF(BTRIM(COALESCE(p_reason, '')), '');
BEGIN
  IF p_from_program_id = p_to_program_id THEN
    RAISE EXCEPTION 'from_program_id and to_program_id must differ'
      USING ERRCODE = 'P7304';
  END IF;

  IF p_new_entity_id IS DISTINCT FROM p_to_program_id THEN
    RAISE EXCEPTION 'new_entity_id must equal to_program_id'
      USING ERRCODE = 'P7301';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.programs p
    WHERE p.program_id = p_from_program_id
      AND p.tenant_id = p_tenant_id
  ) THEN
    RAISE EXCEPTION 'from_program_id % is not in tenant %', p_from_program_id, p_tenant_id
      USING ERRCODE = 'P7300';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.programs p
    WHERE p.program_id = p_to_program_id
      AND p.tenant_id = p_tenant_id
  ) THEN
    RAISE EXCEPTION 'to_program_id % is not in tenant %', p_to_program_id, p_tenant_id
      USING ERRCODE = 'P7301';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.program_migration_events e
    WHERE e.tenant_id = p_tenant_id
      AND e.person_id = p_person_id
      AND e.from_program_id = p_from_program_id
      AND e.to_program_id = p_to_program_id
  ) THEN
    RAISE EXCEPTION 'duplicate migration call for tenant %, person %, from %, to %',
      p_tenant_id, p_person_id, p_from_program_id, p_to_program_id
      USING ERRCODE = '23505';
  END IF;

  SELECT rf.formula_version_id
  INTO v_formula_version_id
  FROM public.risk_formula_versions rf
  WHERE rf.formula_key = 'TIER1_DETERMINISTIC_DEFAULT'
    AND rf.is_active = TRUE
  ORDER BY rf.created_at DESC
  LIMIT 1;

  IF v_formula_version_id IS NULL THEN
    RAISE EXCEPTION 'active formula key TIER1_DETERMINISTIC_DEFAULT not found'
      USING ERRCODE = 'P7307';
  END IF;

  SELECT m.*
  INTO v_source_member
  FROM public.members m
  WHERE m.tenant_id = p_tenant_id
    AND m.person_id = p_person_id
    AND m.entity_id = p_from_program_id
  ORDER BY m.enrolled_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'source member not found for tenant %, person %, program %', p_tenant_id, p_person_id, p_from_program_id
      USING ERRCODE = 'P7306';
  END IF;

  INSERT INTO public.members(
    tenant_id,
    member_id,
    tenant_member_id,
    person_id,
    entity_id,
    member_ref_hash,
    kyc_status,
    enrolled_at,
    status,
    ceiling_amount_minor,
    ceiling_currency,
    metadata
  ) VALUES (
    v_source_member.tenant_id,
    public.uuid_v7_or_random(),
    v_source_member.tenant_member_id,
    v_source_member.person_id,
    p_new_entity_id,
    md5(v_source_member.member_ref_hash || ':migrated:' || p_new_entity_id::text || ':' || now()::text),
    v_source_member.kyc_status,
    NOW(),
    v_source_member.status,
    v_source_member.ceiling_amount_minor,
    v_source_member.ceiling_currency,
    COALESCE(v_source_member.metadata, '{}'::jsonb) || jsonb_build_object(
      'migrated_from_program_id', p_from_program_id,
      'migrated_to_program_id', p_to_program_id,
      'migrated_at', NOW(),
      'migration_reason', v_reason
    )
  )
  RETURNING member_id INTO v_new_member_id;

  INSERT INTO public.program_migration_events(
    tenant_id,
    person_id,
    from_program_id,
    to_program_id,
    migrated_member_id,
    new_member_id,
    migrated_at,
    migrated_by,
    reason,
    formula_version_id,
    created_at
  ) VALUES (
    p_tenant_id,
    p_person_id,
    p_from_program_id,
    p_to_program_id,
    v_new_member_id,
    v_new_member_id,
    NOW(),
    current_user,
    v_reason,
    v_formula_version_id,
    NOW()
  );

  RETURN v_new_member_id;
END;
$$;

COMMENT ON FUNCTION public.migrate_person_to_program(UUID, UUID, UUID, UUID, UUID, TEXT) IS
  'Phase-1 migration function: additive member migration with duplicate-call SQLSTATE 23505.';
