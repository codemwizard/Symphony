CREATE OR REPLACE FUNCTION public.block_active_reference_policy_updates()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  -- Protected policy/signature/evidence fields are immutable across all states.
  -- This prevents two-step tampering after ACTIVE -> INACTIVE rotation.
  IF NEW.policy_json IS DISTINCT FROM OLD.policy_json
     OR NEW.signed_at IS DISTINCT FROM OLD.signed_at
     OR NEW.signed_key_id IS DISTINCT FROM OLD.signed_key_id
     OR NEW.unsigned_reason IS DISTINCT FROM OLD.unsigned_reason
     OR NEW.evidence_path IS DISTINCT FROM OLD.evidence_path
     OR NEW.policy_version_id IS DISTINCT FROM OLD.policy_version_id
     OR NEW.activated_at IS DISTINCT FROM OLD.activated_at
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P7803',
      MESSAGE = 'ACTIVE_REFERENCE_POLICY_IMMUTABLE';
  END IF;

  -- Mutations that keep a row ACTIVE are blocked; only legal status rotations pass.
  IF OLD.version_status = 'ACTIVE' AND NEW.version_status = 'ACTIVE' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P7803',
      MESSAGE = 'ACTIVE_REFERENCE_POLICY_IMMUTABLE';
  END IF;

  RETURN NEW;
END;
$$;
