-- Migration 0094: Green Finance Jurisdiction Isolation Function
-- Canonical jurisdiction isolation primitive matching current_tenant_id_or_null() pattern from 0059.
-- Required by GF jurisdiction-isolated tables: interpretation_packs, regulatory_authorities,
-- regulatory_checkpoints, jurisdiction_profiles, lifecycle_checkpoint_rules, authority_decisions.

CREATE OR REPLACE FUNCTION public.current_jurisdiction_code_or_null()
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v text;
BEGIN
  v := current_setting('app.current_jurisdiction_code', true);
  IF v IS NULL OR btrim(v) = '' THEN
    RETURN NULL;
  END IF;

  -- Jurisdiction codes are text (ISO 3166-1 alpha-2 or similar); no cast needed.
  -- Validate reasonable length to prevent abuse.
  IF length(v) > 16 THEN
    RETURN NULL;
  END IF;

  RETURN v;
END;
$$;

COMMENT ON FUNCTION public.current_jurisdiction_code_or_null() IS
  'Returns app.current_jurisdiction_code when set and non-empty; NULL otherwise (fail-closed for jurisdiction RLS).';
