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
  v_existing_hash text;
  v_existing_version text;
BEGIN
  v_hash := public.compute_effect_seal_hash(p_instruction_id, p_payload, p_canonicalization_version);

  INSERT INTO public.instruction_effect_seals(instruction_id, effect_seal_hash, canonicalization_version, policy_version_id)
  VALUES (p_instruction_id, v_hash, p_canonicalization_version, p_policy_version_id)
  ON CONFLICT (instruction_id) DO NOTHING;

  IF FOUND THEN
    RETURN v_hash;
  END IF;

  SELECT effect_seal_hash, canonicalization_version
    INTO v_existing_hash, v_existing_version
  FROM public.instruction_effect_seals
  WHERE instruction_id = p_instruction_id;

  IF v_existing_hash IS NULL THEN
    RAISE EXCEPTION 'missing_effect_seal' USING ERRCODE = 'P7102';
  END IF;

  IF v_existing_hash <> v_hash OR v_existing_version <> p_canonicalization_version THEN
    INSERT INTO public.effect_seal_mismatch_events(instruction_id, stored_seal_hash, computed_dispatch_hash)
    VALUES (p_instruction_id, v_existing_hash, v_hash);
    RAISE EXCEPTION 'effect_seal_immutable_violation' USING ERRCODE = 'P7102';
  END IF;

  RETURN v_existing_hash;
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
    -- Keep transaction durable for conflict evidence; callers must branch on return state.
    RETURN v_state;
  END IF;

  RETURN v_state;
END;
$$;

REVOKE ALL ON FUNCTION public.compute_effect_seal_hash(text, jsonb, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.store_effect_seal(text, jsonb, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.verify_dispatch_effect_seal(text, jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_late_callback(text, jsonb, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.apply_finality_signals(text, text, public.finality_signal_status_enum, text, public.finality_signal_status_enum) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.quarantine_malformed_response(text, text, public.quarantine_classification_enum, text, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.evaluate_circuit_breaker(text, text, numeric, numeric, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.assert_offline_safe_mode_dispatch_allowed(text, text, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_mmo_reality_control(text, text, text, text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.classify_orphan_or_replay(text, text, boolean, boolean, boolean, boolean) FROM PUBLIC;
