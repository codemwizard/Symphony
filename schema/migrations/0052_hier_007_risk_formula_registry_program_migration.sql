-- 0052_hier_007_risk_formula_registry_program_migration.sql
-- TSK-P1-HIER-007: Risk formula registry (Tier-1 deterministic default)
-- + program migration events + deterministic migration function.

CREATE TABLE IF NOT EXISTS public.risk_formula_versions (
  formula_version_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  formula_key TEXT NOT NULL UNIQUE,
  formula_name TEXT NOT NULL,
  tier TEXT NOT NULL CHECK (tier IN ('TIER1','TIER2','TIER3')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  formula_spec JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.risk_formula_versions(formula_key, formula_name, tier, is_active, formula_spec)
VALUES (
  'TIER1_DETERMINISTIC_DEFAULT',
  'Tier-1 deterministic migration default',
  'TIER1',
  TRUE,
  '{"mode":"deterministic","description":"default deterministic formula baseline"}'::jsonb
)
ON CONFLICT (formula_key) DO UPDATE
SET formula_name = EXCLUDED.formula_name,
    tier = EXCLUDED.tier,
    is_active = EXCLUDED.is_active,
    formula_spec = EXCLUDED.formula_spec;

CREATE TABLE IF NOT EXISTS public.program_migration_events (
  migration_event_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  person_id UUID NOT NULL REFERENCES public.persons(person_id) ON DELETE RESTRICT,
  from_program_id UUID NOT NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
  to_program_id UUID NOT NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
  migrated_member_id UUID NOT NULL REFERENCES public.members(member_id) ON DELETE RESTRICT,
  migrated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  migrated_by TEXT NOT NULL,
  reason TEXT NOT NULL,
  formula_version_id UUID NOT NULL REFERENCES public.risk_formula_versions(formula_version_id) ON DELETE RESTRICT,
  CONSTRAINT program_migration_events_from_to_chk CHECK (from_program_id <> to_program_id)
);

CREATE INDEX IF NOT EXISTS idx_program_migration_events_tenant_time
  ON public.program_migration_events(tenant_id, migrated_at DESC);

CREATE INDEX IF NOT EXISTS idx_program_migration_events_tenant_person
  ON public.program_migration_events(tenant_id, person_id, migrated_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS ux_program_migration_events_deterministic
  ON public.program_migration_events(tenant_id, person_id, from_program_id, to_program_id);

CREATE OR REPLACE FUNCTION public.migrate_person_to_program(
  p_tenant_id UUID,
  p_person_id UUID,
  p_from_program_id UUID,
  p_to_program_id UUID,
  p_migrated_by TEXT DEFAULT current_user,
  p_reason TEXT DEFAULT 'program_migration',
  p_formula_key TEXT DEFAULT 'TIER1_DETERMINISTIC_DEFAULT'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_source_member public.members%ROWTYPE;
  v_target_member_id UUID;
  v_formula_version_id UUID;
  v_actor TEXT := COALESCE(NULLIF(BTRIM(p_migrated_by), ''), current_user);
  v_reason TEXT := COALESCE(NULLIF(BTRIM(p_reason), ''), 'program_migration');
BEGIN
  IF p_from_program_id = p_to_program_id THEN
    RAISE EXCEPTION 'from_program_id and to_program_id must differ'
      USING ERRCODE = 'P7304';
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

  IF NOT EXISTS (
    SELECT 1
    FROM public.persons pe
    WHERE pe.person_id = p_person_id
      AND pe.tenant_id = p_tenant_id
  ) THEN
    RAISE EXCEPTION 'person_id % is not in tenant %', p_person_id, p_tenant_id
      USING ERRCODE = 'P7305';
  END IF;

  SELECT rf.formula_version_id
  INTO v_formula_version_id
  FROM public.risk_formula_versions rf
  WHERE rf.formula_key = COALESCE(NULLIF(BTRIM(p_formula_key), ''), 'TIER1_DETERMINISTIC_DEFAULT')
    AND rf.is_active = TRUE
  ORDER BY rf.created_at DESC
  LIMIT 1;

  IF v_formula_version_id IS NULL THEN
    RAISE EXCEPTION 'active formula key % not found', p_formula_key
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

  SELECT m.member_id
  INTO v_target_member_id
  FROM public.members m
  WHERE m.tenant_id = p_tenant_id
    AND m.person_id = p_person_id
    AND m.entity_id = p_to_program_id
  LIMIT 1;

  IF v_target_member_id IS NULL THEN
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
      p_to_program_id,
      md5(v_source_member.member_ref_hash || ':migrated:' || p_to_program_id::text),
      v_source_member.kyc_status,
      NOW(),
      v_source_member.status,
      v_source_member.ceiling_amount_minor,
      v_source_member.ceiling_currency,
      COALESCE(v_source_member.metadata, '{}'::jsonb) || jsonb_build_object(
        'migrated_from_program_id', p_from_program_id,
        'migrated_at', NOW(),
        'migrated_by', v_actor,
        'migration_reason', v_reason
      )
    )
    RETURNING member_id INTO v_target_member_id;

    INSERT INTO public.program_migration_events(
      tenant_id,
      person_id,
      from_program_id,
      to_program_id,
      migrated_member_id,
      migrated_at,
      migrated_by,
      reason,
      formula_version_id
    ) VALUES (
      p_tenant_id,
      p_person_id,
      p_from_program_id,
      p_to_program_id,
      v_target_member_id,
      NOW(),
      v_actor,
      v_reason,
      v_formula_version_id
    )
    ON CONFLICT (tenant_id, person_id, from_program_id, to_program_id) DO NOTHING;
  END IF;

  RETURN v_target_member_id;
END;
$$;

CREATE OR REPLACE VIEW public.tenant_program_year_unique_beneficiaries AS
SELECT
  m.tenant_id,
  EXTRACT(YEAR FROM m.enrolled_at)::INTEGER AS program_year,
  COUNT(DISTINCT m.person_id)::BIGINT AS unique_beneficiaries
FROM public.members m
GROUP BY m.tenant_id, EXTRACT(YEAR FROM m.enrolled_at);

REVOKE ALL ON TABLE public.risk_formula_versions FROM PUBLIC;
REVOKE ALL ON TABLE public.program_migration_events FROM PUBLIC;
REVOKE ALL ON TABLE public.tenant_program_year_unique_beneficiaries FROM PUBLIC;
