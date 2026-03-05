CREATE TYPE public.key_class_enum AS ENUM ('EASK','PCSK','AAK','TRANSPORT_IDENTITY');
CREATE TYPE public.policy_bundle_state_enum AS ENUM ('draft','approved','active');

CREATE TABLE public.signing_authorization_matrix (
  matrix_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  caller_id text NOT NULL,
  key_class public.key_class_enum NOT NULL,
  permitted_artifact_types text[] NOT NULL DEFAULT '{}',
  key_backend text NOT NULL CHECK (key_backend IN ('HSM','KMS','SOFTWARE')),
  exportable boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (caller_id, key_class)
);

CREATE TABLE public.signing_audit_log (
  sign_event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  caller_id text NOT NULL,
  key_id text NOT NULL,
  key_class public.key_class_enum NOT NULL,
  artifact_type text NOT NULL,
  digest_hash text NOT NULL,
  canonicalization_version text,
  signing_service_id text NOT NULL,
  trust_chain_ref text,
  assurance_tier text NOT NULL,
  signing_path text NOT NULL CHECK (signing_path IN ('HSM','KMS','SOFTWARE_BYPASS')),
  outcome text NOT NULL CHECK (outcome IN ('PASS','REJECTED','BLOCKED')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.policy_bundles (
  policy_bundle_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id text NOT NULL,
  policy_version text NOT NULL,
  state public.policy_bundle_state_enum NOT NULL DEFAULT 'draft',
  high_risk boolean NOT NULL DEFAULT false,
  signer_key_id text,
  signature_valid boolean NOT NULL DEFAULT false,
  activation_timestamp timestamptz,
  verification_outcome text,
  assurance_tier text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (policy_id, policy_version)
);

CREATE TABLE public.key_rotation_drills (
  drill_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rotation_type text NOT NULL CHECK (rotation_type IN ('SCHEDULED','EMERGENCY')),
  old_key_id text NOT NULL,
  new_key_id text NOT NULL,
  trigger_reason text,
  old_key_deactivation_timestamp timestamptz,
  new_key_activation_timestamp timestamptz,
  archival_confirmed boolean NOT NULL DEFAULT false,
  drill_outcome text NOT NULL CHECK (drill_outcome IN ('PASS','FAIL')),
  meta_signing_key_class public.key_class_enum NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.historical_verification_runs (
  verification_run_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key_version text NOT NULL,
  verified_artifact_id text NOT NULL,
  key_used text NOT NULL,
  operational_store_excluded boolean NOT NULL DEFAULT true,
  outcome text NOT NULL,
  error_code text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.resign_sweeps (
  sweep_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sweep_completed_timestamp timestamptz NOT NULL,
  artifacts_resigned_count integer NOT NULL CHECK (artifacts_resigned_count >= 0),
  artifacts_with_pending_tier_assignment_cleared boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.assert_key_class_authorized(
  p_caller_id text,
  p_key_class public.key_class_enum
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_allowed boolean;
BEGIN
  SELECT true INTO v_allowed
  FROM public.signing_authorization_matrix
  WHERE caller_id = p_caller_id
    AND key_class = p_key_class
  LIMIT 1;

  IF COALESCE(v_allowed, false) IS NOT true THEN
    RAISE EXCEPTION USING ERRCODE='P8101', MESSAGE='KEY_CLASS_UNAUTHORIZED';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.sign_digest_hsm_enforced(
  p_caller_id text,
  p_key_id text,
  p_key_class public.key_class_enum,
  p_artifact_type text,
  p_digest_hash text,
  p_signing_path text DEFAULT 'HSM',
  p_assurance_tier text DEFAULT 'HSM_BACKED'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  PERFORM public.assert_key_class_authorized(p_caller_id, p_key_class);

  IF p_signing_path = 'SOFTWARE_BYPASS' THEN
    RAISE EXCEPTION USING ERRCODE='P8102', MESSAGE='HSM_BYPASS_BLOCKED';
  END IF;

  INSERT INTO public.signing_audit_log(
    caller_id, key_id, key_class, artifact_type, digest_hash,
    canonicalization_version, signing_service_id, trust_chain_ref,
    assurance_tier, signing_path, outcome
  ) VALUES (
    p_caller_id, p_key_id, p_key_class, p_artifact_type, p_digest_hash,
    'v1', 'signing-service-v1', 'trust-chain-main',
    p_assurance_tier, p_signing_path, 'PASS'
  ) RETURNING sign_event_id INTO v_event_id;

  RETURN v_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.activate_policy_bundle(
  p_policy_bundle_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  UPDATE public.policy_bundles
  SET state='active', activation_timestamp=now(), verification_outcome='PASS', assurance_tier=COALESCE(assurance_tier,'HSM_BACKED')
  WHERE policy_bundle_id = p_policy_bundle_id
    AND state = 'approved'
    AND signature_valid = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P8201', MESSAGE='POLICY_BUNDLE_UNSIGNED';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_policy_bundle_runtime(
  p_policy_bundle_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_ok boolean;
BEGIN
  SELECT signature_valid INTO v_ok FROM public.policy_bundles WHERE policy_bundle_id = p_policy_bundle_id;
  IF COALESCE(v_ok,false) IS NOT true THEN
    RAISE EXCEPTION USING ERRCODE='P8202', MESSAGE='POLICY_BUNDLE_VERIFICATION_FAILED';
  END IF;
END;
$$;

REVOKE ALL ON TABLE public.signing_authorization_matrix FROM PUBLIC;
REVOKE ALL ON TABLE public.signing_audit_log FROM PUBLIC;
REVOKE ALL ON TABLE public.policy_bundles FROM PUBLIC;
REVOKE ALL ON TABLE public.key_rotation_drills FROM PUBLIC;
REVOKE ALL ON TABLE public.historical_verification_runs FROM PUBLIC;
REVOKE ALL ON TABLE public.resign_sweeps FROM PUBLIC;
