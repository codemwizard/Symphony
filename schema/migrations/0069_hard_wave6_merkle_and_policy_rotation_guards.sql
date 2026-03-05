CREATE OR REPLACE FUNCTION public.block_active_reference_policy_updates()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF OLD.version_status = 'ACTIVE' THEN
    IF NEW.version_status = 'ACTIVE' THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P7803',
        MESSAGE = 'ACTIVE_REFERENCE_POLICY_IMMUTABLE';
    END IF;

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
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_merkle_leaf(
  p_batch_id uuid,
  p_leaf_index integer,
  p_expected_leaf_hash text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_hash text;
BEGIN
  IF p_expected_leaf_hash IS NULL OR btrim(p_expected_leaf_hash) = '' THEN
    RAISE EXCEPTION USING ERRCODE='P8303', MESSAGE='MERKLE_LEAF_HASH_MISMATCH';
  END IF;

  SELECT leaf_hash INTO v_hash
  FROM public.proof_pack_batch_leaves
  WHERE batch_id = p_batch_id AND leaf_index = p_leaf_index;

  IF v_hash IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P8302', MESSAGE='MERKLE_LEAF_NOT_FOUND';
  END IF;

  IF v_hash <> p_expected_leaf_hash THEN
    RAISE EXCEPTION USING ERRCODE='P8303', MESSAGE='MERKLE_LEAF_HASH_MISMATCH';
  END IF;

  RETURN true;
END;
$$;
