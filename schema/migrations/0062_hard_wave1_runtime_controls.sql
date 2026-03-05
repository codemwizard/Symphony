-- 0062_hard_wave1_runtime_controls.sql
-- Wave-1 hardening controls for tasks: 013, 014, 015, 016, 017, 094, 101, 013B.

CREATE TYPE public.finality_signal_status_enum AS ENUM ('SUCCESS', 'FAILED', 'PENDING');

CREATE TYPE public.finality_resolution_state_enum AS ENUM (
  'ACTIVE',
  'FINALITY_CONFLICT',
  'RESOLVED_MANUAL'
);

CREATE TYPE public.quarantine_classification_enum AS ENUM (
  'TRANSPORT',
  'PROTOCOL',
  'SYNTAX',
  'SEMANTIC'
);

CREATE TYPE public.orphan_classification_enum AS ENUM (
  'LATE_CALLBACK',
  'DUPLICATE_DISPATCH',
  'UNKNOWN_REFERENCE',
  'REPLAY_ATTEMPT'
);

CREATE TABLE public.instruction_effect_seals (
  instruction_id text PRIMARY KEY,
  effect_seal_hash text NOT NULL,
  canonicalization_version text NOT NULL,
  policy_version_id text NOT NULL,
  sealed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.effect_seal_mismatch_events (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instruction_id text NOT NULL,
  stored_seal_hash text NOT NULL,
  computed_dispatch_hash text NOT NULL,
  mismatch_detected boolean NOT NULL DEFAULT true,
  dispatch_blocked boolean NOT NULL DEFAULT true,
  event_timestamp timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.orphaned_attestation_landing_zone (
  orphan_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instruction_id text NOT NULL,
  callback_payload_hash text NOT NULL,
  callback_payload_truncated text NOT NULL,
  arrival_timestamp timestamptz NOT NULL DEFAULT now(),
  instruction_state_at_arrival text NOT NULL,
  classification public.orphan_classification_enum NOT NULL,
  event_fingerprint text NOT NULL
);
CREATE INDEX idx_orphan_lz_instruction_arrival ON public.orphaned_attestation_landing_zone(instruction_id, arrival_timestamp DESC);

CREATE TABLE public.instruction_finality_conflicts (
  instruction_id text PRIMARY KEY,
  finality_state public.finality_resolution_state_enum NOT NULL DEFAULT 'ACTIVE',
  rail_a_id text,
  rail_a_response public.finality_signal_status_enum,
  rail_b_id text,
  rail_b_response public.finality_signal_status_enum,
  contradiction_timestamp timestamptz,
  containment_action text,
  operator_resolution_id text,
  resolved_at timestamptz
);

CREATE TABLE public.malformed_quarantine_store (
  quarantine_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adapter_id text NOT NULL,
  rail_id text NOT NULL,
  classification public.quarantine_classification_enum NOT NULL,
  truncation_applied boolean NOT NULL,
  payload_hash text NOT NULL,
  payload_capture text NOT NULL,
  retention_policy_version_id text NOT NULL,
  capture_timestamp timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_malformed_quarantine_adapter_rail_time ON public.malformed_quarantine_store(adapter_id, rail_id, capture_timestamp DESC);

CREATE TABLE public.adapter_circuit_breakers (
  adapter_id text NOT NULL,
  rail_id text NOT NULL,
  state text NOT NULL DEFAULT 'ACTIVE',
  trigger_threshold numeric(8,6) NOT NULL,
  observed_rate numeric(8,6) NOT NULL DEFAULT 0,
  rolling_window_seconds integer NOT NULL,
  policy_version_id text NOT NULL,
  suspended_at timestamptz,
  resumed_at timestamptz,
  operator_id text,
  justification_text text,
  PRIMARY KEY(adapter_id, rail_id)
);

CREATE TABLE public.offline_safe_mode_windows (
  window_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  block_start timestamptz NOT NULL DEFAULT now(),
  block_end timestamptz,
  reason text NOT NULL,
  policy_version_id text NOT NULL,
  gap_marker_id text NOT NULL,
  re_sign_linked boolean NOT NULL DEFAULT false
);

CREATE TABLE public.mmo_reality_control_events (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instruction_id text NOT NULL,
  scenario_type text NOT NULL,
  fallback_posture text NOT NULL,
  policy_version_id text NOT NULL,
  behavior_profile text NOT NULL,
  evidence_artifact_type text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.compute_effect_seal_hash(
  p_instruction_id text,
  p_payload jsonb,
  p_canonicalization_version text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_input text;
BEGIN
  v_input := coalesce(p_instruction_id, '') || '|' || coalesce(p_canonicalization_version, '') || '|' || coalesce(p_payload::text, '{}');
  RETURN md5(v_input);
END;
$$;

CREATE OR REPLACE FUNCTION public.store_effect_seal(
  p_instruction_id text,
  p_payload jsonb,
  p_canonicalization_version text,
  p_policy_version_id text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_hash text;
BEGIN
  v_hash := public.compute_effect_seal_hash(p_instruction_id, p_payload, p_canonicalization_version);
  INSERT INTO public.instruction_effect_seals(instruction_id, effect_seal_hash, canonicalization_version, policy_version_id)
  VALUES (p_instruction_id, v_hash, p_canonicalization_version, p_policy_version_id)
  ON CONFLICT (instruction_id) DO UPDATE
    SET effect_seal_hash = EXCLUDED.effect_seal_hash,
        canonicalization_version = EXCLUDED.canonicalization_version,
        policy_version_id = EXCLUDED.policy_version_id,
        sealed_at = now();
  RETURN v_hash;
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_dispatch_effect_seal(
  p_instruction_id text,
  p_outbound_payload jsonb
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_stored_hash text;
  v_canonical_version text;
  v_computed_hash text;
BEGIN
  SELECT effect_seal_hash, canonicalization_version
  INTO v_stored_hash, v_canonical_version
  FROM public.instruction_effect_seals
  WHERE instruction_id = p_instruction_id;

  IF v_stored_hash IS NULL THEN
    RAISE EXCEPTION 'missing_effect_seal' USING ERRCODE = 'P7102';
  END IF;

  v_computed_hash := public.compute_effect_seal_hash(p_instruction_id, p_outbound_payload, v_canonical_version);

  IF v_computed_hash <> v_stored_hash THEN
    INSERT INTO public.effect_seal_mismatch_events(instruction_id, stored_seal_hash, computed_dispatch_hash)
    VALUES (p_instruction_id, v_stored_hash, v_computed_hash);
    RAISE EXCEPTION 'effect_seal_mismatch' USING ERRCODE = 'P7102';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_late_callback(
  p_instruction_id text,
  p_payload jsonb,
  p_state_at_arrival text,
  p_fingerprint text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO public.orphaned_attestation_landing_zone(
    instruction_id,
    callback_payload_hash,
    callback_payload_truncated,
    instruction_state_at_arrival,
    classification,
    event_fingerprint
  ) VALUES (
    p_instruction_id,
    md5(coalesce(p_payload::text, '{}')),
    left(coalesce(p_payload::text, '{}'), 4096),
    p_state_at_arrival,
    'LATE_CALLBACK',
    p_fingerprint
  ) RETURNING orphan_id INTO v_id;
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.apply_finality_signals(
  p_instruction_id text,
  p_rail_a_id text,
  p_rail_a_status public.finality_signal_status_enum,
  p_rail_b_id text,
  p_rail_b_status public.finality_signal_status_enum
) RETURNS public.finality_resolution_state_enum
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_state public.finality_resolution_state_enum := 'ACTIVE';
BEGIN
  IF p_rail_a_status IN ('SUCCESS','FAILED')
     AND p_rail_b_status IN ('SUCCESS','FAILED')
     AND p_rail_a_status <> p_rail_b_status THEN
    v_state := 'FINALITY_CONFLICT';
  END IF;

  INSERT INTO public.instruction_finality_conflicts(
    instruction_id, finality_state, rail_a_id, rail_a_response, rail_b_id, rail_b_response,
    contradiction_timestamp, containment_action
  ) VALUES (
    p_instruction_id, v_state, p_rail_a_id, p_rail_a_status, p_rail_b_id, p_rail_b_status,
    CASE WHEN v_state='FINALITY_CONFLICT' THEN now() ELSE NULL END,
    CASE WHEN v_state='FINALITY_CONFLICT' THEN 'HOLD_RELEASE' ELSE NULL END
  )
  ON CONFLICT (instruction_id) DO UPDATE
    SET finality_state = EXCLUDED.finality_state,
        rail_a_id = EXCLUDED.rail_a_id,
        rail_a_response = EXCLUDED.rail_a_response,
        rail_b_id = EXCLUDED.rail_b_id,
        rail_b_response = EXCLUDED.rail_b_response,
        contradiction_timestamp = EXCLUDED.contradiction_timestamp,
        containment_action = EXCLUDED.containment_action;

  IF v_state = 'FINALITY_CONFLICT' THEN
    RAISE EXCEPTION 'finality_conflict_hold_release' USING ERRCODE = 'P7402';
  END IF;

  RETURN v_state;
END;
$$;

CREATE OR REPLACE FUNCTION public.quarantine_malformed_response(
  p_adapter_id text,
  p_rail_id text,
  p_classification public.quarantine_classification_enum,
  p_payload text,
  p_truncate_kb integer,
  p_policy_version_id text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_id uuid;
  v_limit integer;
  v_capture text;
BEGIN
  v_limit := greatest(1, p_truncate_kb) * 1024;
  v_capture := left(coalesce(p_payload, ''), v_limit);

  INSERT INTO public.malformed_quarantine_store(
    adapter_id, rail_id, classification, truncation_applied, payload_hash,
    payload_capture, retention_policy_version_id
  ) VALUES (
    p_adapter_id,
    p_rail_id,
    p_classification,
    length(coalesce(p_payload,'')) > v_limit,
    md5(coalesce(p_payload,'')),
    v_capture,
    p_policy_version_id
  ) RETURNING quarantine_id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.evaluate_circuit_breaker(
  p_adapter_id text,
  p_rail_id text,
  p_trigger_threshold numeric,
  p_observed_rate numeric,
  p_window_seconds integer,
  p_policy_version_id text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_state text := 'ACTIVE';
BEGIN
  IF p_observed_rate >= p_trigger_threshold THEN
    v_state := 'SUSPENDED';
  END IF;

  INSERT INTO public.adapter_circuit_breakers(
    adapter_id, rail_id, state, trigger_threshold, observed_rate,
    rolling_window_seconds, policy_version_id, suspended_at
  ) VALUES (
    p_adapter_id, p_rail_id, v_state, p_trigger_threshold, p_observed_rate,
    p_window_seconds, p_policy_version_id,
    CASE WHEN v_state='SUSPENDED' THEN now() ELSE NULL END
  )
  ON CONFLICT (adapter_id, rail_id) DO UPDATE
    SET state = EXCLUDED.state,
        trigger_threshold = EXCLUDED.trigger_threshold,
        observed_rate = EXCLUDED.observed_rate,
        rolling_window_seconds = EXCLUDED.rolling_window_seconds,
        policy_version_id = EXCLUDED.policy_version_id,
        suspended_at = CASE WHEN EXCLUDED.state='SUSPENDED' THEN now() ELSE public.adapter_circuit_breakers.suspended_at END;

  IF v_state = 'SUSPENDED' THEN
    RAISE EXCEPTION 'ADAPTER_SUSPENDED_CIRCUIT_BREAKER' USING ERRCODE = 'P7401';
  END IF;

  RETURN v_state;
END;
$$;

CREATE OR REPLACE FUNCTION public.assert_offline_safe_mode_dispatch_allowed(
  p_reason text,
  p_policy_version_id text,
  p_is_offline boolean
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF p_is_offline THEN
    INSERT INTO public.offline_safe_mode_windows(reason, policy_version_id, gap_marker_id)
    VALUES (p_reason, p_policy_version_id, md5(p_reason || '|' || now()::text));
    RAISE EXCEPTION 'OFFLINE_SAFE_MODE_ACTIVE' USING ERRCODE = 'P7501';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_mmo_reality_control(
  p_instruction_id text,
  p_scenario_type text,
  p_fallback_posture text,
  p_policy_version_id text,
  p_behavior_profile text,
  p_evidence_artifact_type text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF p_scenario_type NOT IN ('ASYNC_CONTRADICTION', 'DELAYED_SETTLEMENT', 'DUAL_DEBIT_RISK', 'SILENT_REJECTION') THEN
    RAISE EXCEPTION 'unsupported_mmo_scenario' USING ERRCODE = 'P7502';
  END IF;

  INSERT INTO public.mmo_reality_control_events(
    instruction_id, scenario_type, fallback_posture, policy_version_id,
    behavior_profile, evidence_artifact_type
  ) VALUES (
    p_instruction_id, p_scenario_type, p_fallback_posture, p_policy_version_id,
    p_behavior_profile, p_evidence_artifact_type
  ) RETURNING event_id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.classify_orphan_or_replay(
  p_instruction_id text,
  p_event_fingerprint text,
  p_is_late_callback boolean,
  p_is_duplicate_dispatch boolean,
  p_has_unknown_reference boolean,
  p_is_replay boolean
) RETURNS public.orphan_classification_enum
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_class public.orphan_classification_enum;
BEGIN
  IF p_is_late_callback THEN
    v_class := 'LATE_CALLBACK';
  ELSIF p_is_duplicate_dispatch THEN
    v_class := 'DUPLICATE_DISPATCH';
  ELSIF p_has_unknown_reference THEN
    v_class := 'UNKNOWN_REFERENCE';
  ELSIF p_is_replay THEN
    v_class := 'REPLAY_ATTEMPT';
  ELSE
    v_class := 'UNKNOWN_REFERENCE';
  END IF;

  INSERT INTO public.orphaned_attestation_landing_zone(
    instruction_id,
    callback_payload_hash,
    callback_payload_truncated,
    instruction_state_at_arrival,
    classification,
    event_fingerprint
  ) VALUES (
    p_instruction_id,
    md5(coalesce(p_event_fingerprint,'')),
    left(coalesce(p_event_fingerprint,''), 1024),
    'ORPHAN_ROUTING',
    v_class,
    p_event_fingerprint
  );

  IF v_class IN ('DUPLICATE_DISPATCH', 'UNKNOWN_REFERENCE', 'REPLAY_ATTEMPT') THEN
    RAISE EXCEPTION 'orphan_replay_containment_reject' USING ERRCODE = 'P7503';
  END IF;

  RETURN v_class;
END;
$$;

REVOKE ALL ON TABLE public.instruction_effect_seals FROM PUBLIC;
REVOKE ALL ON TABLE public.effect_seal_mismatch_events FROM PUBLIC;
REVOKE ALL ON TABLE public.orphaned_attestation_landing_zone FROM PUBLIC;
REVOKE ALL ON TABLE public.instruction_finality_conflicts FROM PUBLIC;
REVOKE ALL ON TABLE public.malformed_quarantine_store FROM PUBLIC;
REVOKE ALL ON TABLE public.adapter_circuit_breakers FROM PUBLIC;
REVOKE ALL ON TABLE public.offline_safe_mode_windows FROM PUBLIC;
REVOKE ALL ON TABLE public.mmo_reality_control_events FROM PUBLIC;
