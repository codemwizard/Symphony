--
-- PostgreSQL database dump
--

\restrict ce1Vyv3T5wzkGqqcBkLUen5fbu94lAsZWJ0ZSjGdgenrzljUlvDUWNdaBsuyh8s

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg13+1)
-- Dumped by pg_dump version 18.3 (Debian 18.3-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: adjustment_state_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.adjustment_state_enum AS ENUM (
    'requested',
    'pending_approval',
    'cooling_off',
    'eligible_execute',
    'executed',
    'denied',
    'blocked_legal_hold'
);


--
-- Name: finality_resolution_state_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.finality_resolution_state_enum AS ENUM (
    'ACTIVE',
    'FINALITY_CONFLICT',
    'RESOLVED_MANUAL'
);


--
-- Name: finality_signal_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.finality_signal_status_enum AS ENUM (
    'SUCCESS',
    'FAILED',
    'PENDING'
);


--
-- Name: inquiry_state_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.inquiry_state_enum AS ENUM (
    'SCHEDULED',
    'SENT',
    'AWAITING_EXECUTION',
    'ESCALATED',
    'ACKNOWLEDGED',
    'EXHAUSTED'
);


--
-- Name: key_class_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.key_class_enum AS ENUM (
    'EASK',
    'PCSK',
    'AAK',
    'TRANSPORT_IDENTITY'
);


--
-- Name: orphan_classification_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.orphan_classification_enum AS ENUM (
    'LATE_CALLBACK',
    'DUPLICATE_DISPATCH',
    'UNKNOWN_REFERENCE',
    'REPLAY_ATTEMPT'
);


--
-- Name: outbox_attempt_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.outbox_attempt_state AS ENUM (
    'DISPATCHING',
    'DISPATCHED',
    'RETRYABLE',
    'FAILED',
    'ZOMBIE_REQUEUE'
);


--
-- Name: policy_bundle_state_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.policy_bundle_state_enum AS ENUM (
    'draft',
    'approved',
    'active'
);


--
-- Name: policy_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.policy_version_status AS ENUM (
    'ACTIVE',
    'GRACE',
    'RETIRED'
);


--
-- Name: quarantine_classification_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.quarantine_classification_enum AS ENUM (
    'TRANSPORT',
    'PROTOCOL',
    'SYNTAX',
    'SEMANTIC'
);


--
-- Name: reference_strategy_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.reference_strategy_type_enum AS ENUM (
    'SUFFIX',
    'DETERMINISTIC_ALIAS',
    'RE_ENCODED_HASH_TOKEN',
    'RAIL_NATIVE_ALT_FIELD'
);


--
-- Name: acknowledge_inquiry_response(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.acknowledge_inquiry_response(p_instruction_id text, p_policy_version_id text) RETURNS public.inquiry_state_enum
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_state public.inquiry_state_enum;
BEGIN
  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_state IS NULL THEN
    RAISE EXCEPTION 'inquiry_not_found' USING ERRCODE = 'P7300';
  END IF;

  IF v_state <> 'SENT' THEN
    RAISE EXCEPTION 'illegal_transition_to_acknowledged_from:%', v_state USING ERRCODE = 'P7300';
  END IF;

  UPDATE public.inquiry_state_machine
  SET inquiry_state = 'ACKNOWLEDGED',
      policy_version_id = p_policy_version_id
  WHERE instruction_id = p_instruction_id;

  RETURN 'ACKNOWLEDGED';
END;
$$;


--
-- Name: activate_policy_bundle(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.activate_policy_bundle(p_policy_bundle_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: activate_project(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.activate_project(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(project_id uuid, status text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_current_status TEXT;
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF006';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF007';
    END IF;

    -- Fetch current status
    SELECT p.status
      INTO v_current_status
      FROM public.projects p
     WHERE p.project_id = p_project_id
       AND p.tenant_id  = p_tenant_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'project not found for tenant' USING ERRCODE = 'GF008';
    END IF;

    IF v_current_status != 'DRAFT' THEN
        RAISE EXCEPTION 'project must be in DRAFT status to activate; current=%', v_current_status
            USING ERRCODE = 'GF009';
    END IF;

    -- Delegate lifecycle transition (defined in 0110)
    PERFORM public.transition_asset_status(p_tenant_id, p_project_id, 'ACTIVE');

    -- Update project to ACTIVE
    UPDATE public.projects
       SET status = 'ACTIVE'
     WHERE project_id = p_project_id
       AND tenant_id  = p_tenant_id;

    -- Record PROJECT_ACTIVATION monitoring event (defined in 0108)
    PERFORM public.record_monitoring_record(
        p_tenant_id,
        p_project_id,
        'PROJECT_ACTIVATION',
        '{}'::jsonb
    );

    RETURN QUERY SELECT p_project_id, 'ACTIVE'::TEXT;
END;
$$;


--
-- Name: adapter_registrations_append_only_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.adapter_registrations_append_only_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    -- Block UPDATE and DELETE operations
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'adapter_registrations is append-only - % operations not allowed', TG_OP;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: allocate_dispatch_reference(uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.allocate_dispatch_reference(p_instruction_id uuid, p_adjustment_id uuid, p_parent_reference text, p_rail_id text) RETURNS TABLE(registry_id uuid, allocated_reference text, canonicalized_reference text, strategy_used public.reference_strategy_type_enum, policy_version_id text, collision_retry_count integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_strategy record;
  v_attempt integer := 0;
  v_candidate text;
  v_canon text;
  v_collision boolean;
BEGIN
  SELECT * INTO v_strategy FROM public.resolve_reference_strategy(p_rail_id);

  LOOP
    IF v_strategy.strategy_type = 'SUFFIX' THEN
      v_candidate := p_parent_reference || '-' || lpad(v_attempt::text, 2, '0');
    ELSIF v_strategy.strategy_type = 'DETERMINISTIC_ALIAS' THEN
      v_candidate := substr(md5(p_parent_reference || ':' || coalesce(p_adjustment_id::text,'none') || ':' || v_attempt::text), 1, greatest(8, v_strategy.max_length));
    ELSIF v_strategy.strategy_type = 'RE_ENCODED_HASH_TOKEN' THEN
      v_candidate := substr(md5('reh:' || p_parent_reference || ':' || p_rail_id || ':' || v_attempt::text), 1, greatest(8, v_strategy.max_length));
    ELSE
      v_candidate := p_parent_reference;
    END IF;

    v_canon := public.canonicalize_reference_for_rail(v_candidate, p_rail_id);
    v_collision := false;

    BEGIN
      INSERT INTO public.dispatch_reference_registry(
        instruction_id, adjustment_id, rail_id, allocated_reference,
        canonicalized_reference, strategy_used, policy_version_id, collision_retry_count
      ) VALUES (
        p_instruction_id, p_adjustment_id, p_rail_id, v_candidate,
        v_canon, v_strategy.strategy_type, v_strategy.policy_version_id, v_attempt
      )
      RETURNING
        dispatch_reference_registry.registry_id,
        dispatch_reference_registry.allocated_reference,
        dispatch_reference_registry.canonicalized_reference,
        dispatch_reference_registry.strategy_used,
        dispatch_reference_registry.policy_version_id,
        dispatch_reference_registry.collision_retry_count
      INTO registry_id, allocated_reference, canonicalized_reference, strategy_used, policy_version_id, collision_retry_count;
    EXCEPTION
      WHEN unique_violation THEN
        v_collision := true;
    END;

    IF NOT v_collision THEN
      IF v_attempt > 0 THEN
        INSERT INTO public.dispatch_reference_collision_events(
          instruction_id, adjustment_id, rail_id, reference_attempted,
          strategy_used, collision_count, outcome, policy_version_id
        ) VALUES (
          p_instruction_id, p_adjustment_id, p_rail_id, v_candidate,
          v_strategy.strategy_type, v_attempt, 'RESOLVED', v_strategy.policy_version_id
        );
      END IF;

      RETURN NEXT;
      RETURN;
    END IF;

    v_attempt := v_attempt + 1;
    IF v_attempt > v_strategy.nonce_retry_limit THEN
      INSERT INTO public.dispatch_reference_collision_events(
        instruction_id, adjustment_id, rail_id, reference_attempted,
        strategy_used, collision_count, outcome, policy_version_id
      ) VALUES (
        p_instruction_id, p_adjustment_id, p_rail_id, p_parent_reference,
        v_strategy.strategy_type, v_attempt, 'EXHAUSTED', v_strategy.policy_version_id
      );
      RAISE EXCEPTION USING ERRCODE='P7801', MESSAGE='REFERENCE_ALLOCATION_RETRY_EXHAUSTED';
    END IF;
  END LOOP;
END;
$$;


--
-- Name: anchor_dispatched_outbox_attempt(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.anchor_dispatched_outbox_attempt() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_sequence_ref TEXT;
  v_profile TEXT;
BEGIN
  IF NEW.state <> 'DISPATCHED' THEN
    RETURN NEW;
  END IF;

  v_sequence_ref := NULLIF(BTRIM(NEW.rail_reference), '');
  IF v_sequence_ref IS NULL THEN
    RAISE EXCEPTION 'dispatch requires rail sequence reference'
      USING ERRCODE = 'P7005';
  END IF;

  v_profile := COALESCE(NULLIF(BTRIM(NEW.rail_type), ''), 'GENERIC');

  INSERT INTO public.rail_dispatch_truth_anchor(
    attempt_id,
    outbox_id,
    instruction_id,
    participant_id,
    rail_participant_id,
    rail_profile,
    rail_sequence_ref,
    state
  ) VALUES (
    NEW.attempt_id,
    NEW.outbox_id,
    NEW.instruction_id,
    NEW.participant_id,
    NEW.participant_id,
    v_profile,
    v_sequence_ref,
    NEW.state
  );

  RETURN NEW;
END;
$$;


--
-- Name: apply_finality_signals(text, text, public.finality_signal_status_enum, text, public.finality_signal_status_enum); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_finality_signals(p_instruction_id text, p_rail_a_id text, p_rail_a_status public.finality_signal_status_enum, p_rail_b_id text, p_rail_b_status public.finality_signal_status_enum) RETURNS public.finality_resolution_state_enum
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: apply_inquiry_attempt(text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.apply_inquiry_attempt(p_instruction_id text, p_policy_version_id text, p_max_attempts integer) RETURNS public.inquiry_state_enum
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_state public.inquiry_state_enum;
  v_attempts INTEGER;
  v_max INTEGER;
BEGIN
  IF p_max_attempts IS NULL OR p_max_attempts <= 0 THEN
    RAISE EXCEPTION 'invalid_max_attempts' USING ERRCODE = 'P7302';
  END IF;

  INSERT INTO public.inquiry_state_machine(instruction_id, inquiry_state, attempts, max_attempts, policy_version_id)
  VALUES (p_instruction_id, 'SCHEDULED', 0, p_max_attempts, p_policy_version_id)
  ON CONFLICT (instruction_id) DO NOTHING;

  SELECT inquiry_state, attempts, max_attempts INTO v_state, v_attempts, v_max
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_state IN ('ACKNOWLEDGED', 'EXHAUSTED') THEN
    RAISE EXCEPTION 'illegal_transition_from_terminal_inquiry_state:%', v_state USING ERRCODE = 'P7300';
  END IF;

  v_attempts := v_attempts + 1;

  IF v_attempts >= v_max THEN
    UPDATE public.inquiry_state_machine
    SET attempts = v_attempts,
        inquiry_state = 'EXHAUSTED',
        policy_version_id = p_policy_version_id,
        max_attempts = p_max_attempts
    WHERE instruction_id = p_instruction_id;
    RETURN 'EXHAUSTED';
  END IF;

  UPDATE public.inquiry_state_machine
  SET attempts = v_attempts,
      inquiry_state = 'SENT',
      policy_version_id = p_policy_version_id,
      max_attempts = p_max_attempts
  WHERE instruction_id = p_instruction_id;
  RETURN 'SENT';
END;
$$;


--
-- Name: assert_adjustment_execution_allowed(uuid, public.adjustment_state_enum, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_adjustment_execution_allowed(p_adjustment_id uuid, p_current_state public.adjustment_state_enum, p_freeze_flag_type text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF p_current_state = 'cooling_off' THEN
    RAISE EXCEPTION 'ADJUSTMENT_COOLING_OFF_ACTIVE' USING ERRCODE = 'P7701';
  END IF;
  IF p_freeze_flag_type IS NOT NULL THEN
    RAISE EXCEPTION 'ADJUSTMENT_FREEZE_BLOCK' USING ERRCODE = 'P7702';
  END IF;
END;
$$;


--
-- Name: assert_canonicalization_version_exists(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_canonicalization_version_exists(p_version text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.canonicalization_registry WHERE canonicalization_version = p_version) THEN
    RAISE EXCEPTION USING ERRCODE='P8301', MESSAGE='UNVERIFIABLE_MISSING_CANONICALIZER';
  END IF;
END;
$$;


--
-- Name: assert_hsm_fail_closed(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_hsm_fail_closed(p_should_block boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF p_should_block THEN
    RAISE EXCEPTION USING ERRCODE='P8401', MESSAGE='HSM_FAIL_CLOSED_ENFORCED';
  END IF;
END;
$$;


--
-- Name: assert_key_class_authorized(text, public.key_class_enum); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_key_class_authorized(p_caller_id text, p_key_class public.key_class_enum) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: assert_offline_safe_mode_dispatch_allowed(text, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_offline_safe_mode_dispatch_allowed(p_reason text, p_policy_version_id text, p_is_offline boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF p_is_offline THEN
    INSERT INTO public.offline_safe_mode_windows(reason, policy_version_id, gap_marker_id)
    VALUES (p_reason, p_policy_version_id, md5(p_reason || '|' || now()::text));
    RAISE EXCEPTION 'OFFLINE_SAFE_MODE_ACTIVE' USING ERRCODE = 'P7501';
  END IF;
END;
$$;


--
-- Name: assert_pii_absent_from_penalty_pack(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_pii_absent_from_penalty_pack(p_contains_raw_pii boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF p_contains_raw_pii THEN
    RAISE EXCEPTION USING ERRCODE='P8404', MESSAGE='PII_PRESENT_IN_PENALTY_DEFENSE_PACK';
  END IF;
END;
$$;


--
-- Name: assert_rate_limit_blocked(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_rate_limit_blocked(p_blocked boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF p_blocked THEN
    RAISE EXCEPTION USING ERRCODE='P8402', MESSAGE='RATE_LIMIT_BREACH_BLOCKED';
  END IF;
END;
$$;


--
-- Name: assert_reference_registered(text, text, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_reference_registered(p_rail_id text, p_reference text, p_instruction_id uuid, p_adjustment_id uuid DEFAULT NULL::uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.dispatch_reference_registry r
    WHERE r.rail_id = p_rail_id
      AND (r.allocated_reference = p_reference OR r.canonicalized_reference = p_reference)
      AND r.instruction_id = p_instruction_id
      AND (p_adjustment_id IS NULL OR r.adjustment_id = p_adjustment_id)
  ) INTO v_exists;

  IF NOT v_exists THEN
    INSERT INTO public.dispatch_reference_collision_events(
      instruction_id, adjustment_id, rail_id, reference_attempted,
      strategy_used, collision_count, outcome, policy_version_id
    ) VALUES (
      p_instruction_id, p_adjustment_id, p_rail_id, p_reference,
      'SUFFIX', 1, 'UNREGISTERED_BLOCKED', NULL
    );
    RAISE EXCEPTION USING ERRCODE='P8001', MESSAGE='REFERENCE_NOT_REGISTERED';
  END IF;
END;
$$;


--
-- Name: assert_secondary_retraction_approval(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_secondary_retraction_approval(p_ok boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF NOT p_ok THEN
    RAISE EXCEPTION USING ERRCODE='P8403', MESSAGE='RETRACTION_SECONDARY_APPROVAL_REQUIRED';
  END IF;
END;
$$;


--
-- Name: attach_evidence(uuid, uuid, text, text, text, uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attach_evidence(p_tenant_id uuid, p_project_id uuid, p_evidence_class text, p_document_type text, p_target_record_type text, p_target_record_id uuid, p_node_payload_json jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_evidence_node_id      UUID;
    v_monitoring_record_id  UUID := NULL;
    v_valid_classes         TEXT[] := ARRAY[
        'RAW_SOURCE', 'ATTESTED_SOURCE', 'NORMALIZED_RECORD',
        'ANALYST_FINDING', 'VERIFIER_FINDING', 'REGULATORY_EXPORT', 'ISSUANCE_ARTIFACT'
    ];
    v_valid_target_types    TEXT[] := ARRAY[
        'PROJECT', 'MONITORING_RECORD', 'ASSET_BATCH', 'EVIDENCE_NODE'
    ];
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_evidence_class IS NULL OR trim(p_evidence_class) = '' THEN
        RAISE EXCEPTION 'p_evidence_class is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_document_type IS NULL OR trim(p_document_type) = '' THEN
        RAISE EXCEPTION 'p_document_type is required' USING ERRCODE = 'GF004';
    END IF;
    IF p_target_record_type IS NULL OR trim(p_target_record_type) = '' THEN
        RAISE EXCEPTION 'p_target_record_type is required' USING ERRCODE = 'GF005';
    END IF;
    IF p_target_record_id IS NULL THEN
        RAISE EXCEPTION 'p_target_record_id is required' USING ERRCODE = 'GF006';
    END IF;

    -- ── Evidence class validation ───────────────────────────────────────────
    IF NOT (p_evidence_class = ANY(v_valid_classes)) THEN
        RAISE EXCEPTION 'Invalid evidence class: %; must be one of %',
                         p_evidence_class, v_valid_classes
            USING ERRCODE = 'GF007';
    END IF;

    -- ── Target record type validation ───────────────────────────────────────
    IF NOT (p_target_record_type = ANY(v_valid_target_types)) THEN
        RAISE EXCEPTION 'Invalid target record type: %', p_target_record_type
            USING ERRCODE = 'GF008';
    END IF;

    -- ── Validate target record exists and belongs to tenant ─────────────────
    IF p_target_record_type = 'PROJECT' THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.projects
             WHERE project_id = p_target_record_id AND tenant_id = p_tenant_id
        ) THEN
            RAISE EXCEPTION 'target PROJECT not found for tenant' USING ERRCODE = 'GF009';
        END IF;

    ELSIF p_target_record_type = 'MONITORING_RECORD' THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.monitoring_records mr
             WHERE mr.monitoring_record_id = p_target_record_id
               AND mr.tenant_id = p_tenant_id
               AND mr.project_id = p_project_id
        ) THEN
            RAISE EXCEPTION 'target MONITORING_RECORD not found for project/tenant'
                USING ERRCODE = 'GF010';
        END IF;
        v_monitoring_record_id := p_target_record_id;

    ELSIF p_target_record_type = 'ASSET_BATCH' THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.asset_batches ab
             WHERE ab.asset_batch_id = p_target_record_id
               AND ab.tenant_id = p_tenant_id
               AND ab.project_id = p_project_id
        ) THEN
            RAISE EXCEPTION 'target ASSET_BATCH not found for project/tenant'
                USING ERRCODE = 'GF011';
        END IF;

    ELSIF p_target_record_type = 'EVIDENCE_NODE' THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.evidence_nodes en
             WHERE en.evidence_node_id = p_target_record_id
               AND en.tenant_id = p_tenant_id
        ) THEN
            RAISE EXCEPTION 'target EVIDENCE_NODE not found for tenant'
                USING ERRCODE = 'GF012';
        END IF;
    END IF;

    -- ── Insert evidence node (append-only) ──────────────────────────────────
    INSERT INTO evidence_nodes (
        tenant_id,
        project_id,
        monitoring_record_id,
        node_type,
        node_payload_json
    ) VALUES (
        p_tenant_id,
        p_project_id,
        v_monitoring_record_id,
        p_evidence_class,
        p_node_payload_json
    )
    RETURNING evidence_node_id INTO v_evidence_node_id;

    RETURN v_evidence_node_id;
END;
$$;


--
-- Name: attempt_lifecycle_transition(uuid, text, uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attempt_lifecycle_transition(p_tenant_id uuid, p_subject_type text, p_subject_id uuid, p_from_status text, p_to_status text, p_jurisdiction_code text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_unsatisfied_checkpoints INT;
    v_conditional_count       INT;
    v_result_state            TEXT;
    v_valid_subject_types     TEXT[] := ARRAY['PROJECT', 'ASSET_BATCH', 'MONITORING_RECORD', 'EVIDENCE_NODE'];
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF016';
    END IF;
    IF p_subject_type IS NULL THEN
        RAISE EXCEPTION 'p_subject_type is required' USING ERRCODE = 'GF016';
    END IF;
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF016';
    END IF;
    IF p_from_status IS NULL THEN
        RAISE EXCEPTION 'p_from_status is required' USING ERRCODE = 'GF016';
    END IF;
    IF p_to_status IS NULL THEN
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF016';
    END IF;

    IF NOT (p_subject_type = ANY(v_valid_subject_types)) THEN
        RAISE EXCEPTION 'Invalid subject type: %', p_subject_type USING ERRCODE = 'GF016';
    END IF;

    -- ── Checkpoint evaluation ────────────────────────────────────────────────
    -- REQUIRED checkpoints: if any unsatisfied_checkpoints remain, block transition.
    -- CONDITIONALLY_REQUIRED: transition proceeds but outcome = PENDING_CLARIFICATION.
    IF p_jurisdiction_code IS NOT NULL THEN
        SELECT COUNT(*) INTO v_unsatisfied_checkpoints
          FROM public.lifecycle_checkpoint_rules lcr
         WHERE lcr.jurisdiction_code = p_jurisdiction_code
           AND lcr.rule_type = 'REQUIRED';

        SELECT COUNT(*) INTO v_conditional_count
          FROM public.lifecycle_checkpoint_rules lcr
         WHERE lcr.jurisdiction_code = p_jurisdiction_code
           AND lcr.rule_type = 'CONDITIONALLY_REQUIRED';
    ELSE
        v_unsatisfied_checkpoints := 0;
        v_conditional_count := 0;
    END IF;

    IF v_unsatisfied_checkpoints > 0 THEN
        RAISE EXCEPTION 'lifecycle transition blocked: % unsatisfied REQUIRED checkpoints',
                         v_unsatisfied_checkpoints
            USING ERRCODE = 'GF016';
    END IF;

    IF v_conditional_count > 0 THEN
        -- Provisional pass: state becomes PENDING_CLARIFICATION
        v_result_state := 'PENDING_CLARIFICATION';
    ELSE
        -- All requirements satisfied: state becomes CONDITIONALLY_SATISFIED
        v_result_state := 'CONDITIONALLY_SATISFIED';
    END IF;

    -- Execute the validated lifecycle transition
    PERFORM public.transition_asset_status(p_tenant_id, p_subject_id, p_to_status);

    RETURN v_result_state;
END;
$$;


--
-- Name: authority_decisions_append_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.authority_decisions_append_only() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'UPDATE not allowed on authority_decisions (append-only ledger)'
            USING ERRCODE = 'GF001';
    END IF;
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'DELETE not allowed on authority_decisions (append-only ledger)'
            USING ERRCODE = 'GF001';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: authorize_escrow_reservation(uuid, bigint, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.authorize_escrow_reservation(p_program_escrow_id uuid, p_amount_minor bigint, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_env public.escrow_envelopes%ROWTYPE;
  v_amount BIGINT := COALESCE(p_amount_minor, 0);
  v_actor TEXT := COALESCE(NULLIF(BTRIM(p_actor_id), ''), 'system');
  v_reservation_escrow_id UUID;
BEGIN
  IF v_amount <= 0 THEN
    RAISE EXCEPTION 'invalid reservation amount %', v_amount
      USING ERRCODE = 'P7304';
  END IF;

  -- Critical lock: deterministic prevention of oversubscription.
  SELECT *
  INTO v_env
  FROM public.escrow_envelopes
  WHERE escrow_envelopes.escrow_id = p_program_escrow_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'escrow envelope not found'
      USING ERRCODE = 'P7302';
  END IF;

  IF v_env.reserved_amount_minor + v_amount > v_env.ceiling_amount_minor THEN
    RAISE EXCEPTION 'escrow ceiling exceeded'
      USING ERRCODE = 'P7304';
  END IF;

  UPDATE public.escrow_envelopes
  SET reserved_amount_minor = reserved_amount_minor + v_amount,
      updated_at = NOW()
  WHERE escrow_envelopes.escrow_id = v_env.escrow_id;

  INSERT INTO public.escrow_accounts(
    tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at, release_due_at
  ) VALUES (
    v_env.tenant_id, NULL, NULL, 'CREATED', v_amount, v_env.currency_code, NOW() + interval '30 minutes', NOW() + interval '60 minutes'
  )
  RETURNING escrow_accounts.escrow_id INTO v_reservation_escrow_id;

  -- Record state as AUTHORIZED and write append-only event.
  PERFORM 1
  FROM public.transition_escrow_state(
    p_escrow_id => v_reservation_escrow_id,
    p_to_state => 'AUTHORIZED',
    p_actor_id => v_actor,
    p_reason => COALESCE(p_reason, 'reservation_authorized'),
    p_metadata => COALESCE(p_metadata, '{}'::jsonb),
    p_now => NOW()
  );

  INSERT INTO public.escrow_reservations(
    tenant_id, program_escrow_id, reservation_escrow_id, amount_minor, actor_id, reason, metadata, created_at
  ) VALUES (
    v_env.tenant_id, v_env.escrow_id, v_reservation_escrow_id, v_amount, v_actor, p_reason, COALESCE(p_metadata, '{}'::jsonb), NOW()
  );

  RETURN v_reservation_escrow_id;
END;
$$;


--
-- Name: block_active_reference_policy_updates(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.block_active_reference_policy_updates() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: bump_participant_outbox_seq(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.bump_participant_outbox_seq(p_participant_id text) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
  DECLARE
    allocated BIGINT;
  BEGIN
    INSERT INTO participant_outbox_sequences(participant_id, next_sequence_id)
    VALUES (p_participant_id, 2)
    ON CONFLICT (participant_id)
    DO UPDATE
      SET next_sequence_id = participant_outbox_sequences.next_sequence_id + 1
    RETURNING (participant_outbox_sequences.next_sequence_id - 1) INTO allocated;
  
    RETURN allocated;
  END;
$$;


--
-- Name: canonicalize_reference_for_rail(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.canonicalize_reference_for_rail(p_allocated_reference text, p_rail_id text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_strategy record;
  v_truncated text;
BEGIN
  SELECT * INTO v_strategy FROM public.resolve_reference_strategy(p_rail_id);

  IF length(p_allocated_reference) > v_strategy.max_length THEN
    RAISE EXCEPTION USING ERRCODE='P7901', MESSAGE='REFERENCE_LENGTH_EXCEEDED';
  END IF;

  v_truncated := left(p_allocated_reference, v_strategy.max_length);
  RETURN v_truncated;
END;
$$;


--
-- Name: check_reg26_separation(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_reg26_separation(p_verifier_id uuid, p_project_id uuid, p_requested_role text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF p_requested_role = 'VERIFIER' THEN
        IF EXISTS (
            SELECT 1 FROM public.verifier_project_assignments
            WHERE verifier_id = p_verifier_id
              AND project_id = p_project_id
              AND assigned_role = 'VALIDATOR'
        ) THEN
            RAISE EXCEPTION
                'Regulation 26 violation: validator cannot verify the same project (verifier_id=%, project_id=%)',
                p_verifier_id, p_project_id
                USING ERRCODE = 'GF001';
        END IF;
    END IF;
END;
$$;


--
-- Name: claim_anchor_sync_operation(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_anchor_sync_operation(p_worker_id text, p_lease_seconds integer DEFAULT 30) RETURNS TABLE(operation_id uuid, pack_id uuid, lease_token uuid, state text, attempt_count integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_worker TEXT := NULLIF(BTRIM(p_worker_id), '');
BEGIN
  IF v_worker IS NULL THEN
    RAISE EXCEPTION 'worker_id is required' USING ERRCODE = 'P7210';
  END IF;

  IF p_lease_seconds IS NULL OR p_lease_seconds <= 0 THEN
    RAISE EXCEPTION 'lease seconds must be > 0' USING ERRCODE = 'P7210';
  END IF;

  RETURN QUERY
  WITH candidate AS (
    SELECT o.operation_id
    FROM public.anchor_sync_operations o
    WHERE o.state IN ('PENDING', 'ANCHORED')
      AND (o.lease_expires_at IS NULL OR o.lease_expires_at <= clock_timestamp())
    ORDER BY o.updated_at, o.created_at
    LIMIT 1
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.anchor_sync_operations o
  SET state = CASE WHEN o.state = 'ANCHORED' THEN 'ANCHORED' ELSE 'ANCHORING' END,
      claimed_by = v_worker,
      lease_token = public.uuid_v7_or_random(),
      lease_expires_at = clock_timestamp() + make_interval(secs => p_lease_seconds),
      attempt_count = o.attempt_count + 1,
      last_error = NULL
  FROM candidate c
  WHERE o.operation_id = c.operation_id
  RETURNING o.operation_id, o.pack_id, o.lease_token, o.state, o.attempt_count;
END;
$$;


--
-- Name: claim_outbox_batch(integer, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_outbox_batch(p_batch_size integer, p_worker_id text, p_lease_seconds integer) RETURNS TABLE(outbox_id uuid, instruction_id text, participant_id text, sequence_id bigint, idempotency_key text, rail_type text, payload jsonb, attempt_count integer, lease_token uuid, lease_expires_at timestamp with time zone)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
WITH due AS (
  SELECT p.outbox_id
  FROM payment_outbox_pending p
  WHERE p.next_attempt_at <= NOW()
    AND (p.lease_expires_at IS NULL OR p.lease_expires_at <= NOW())
  ORDER BY p.next_attempt_at ASC, p.created_at ASC
  LIMIT p_batch_size
  FOR UPDATE SKIP LOCKED
 ),
 leased AS (
   UPDATE payment_outbox_pending p
   SET
     claimed_by = p_worker_id,
     lease_token = public.uuid_v7_or_random(),
     lease_expires_at = NOW() + make_interval(secs => p_lease_seconds)
   FROM due
   WHERE p.outbox_id = due.outbox_id
   RETURNING
     p.outbox_id,
     p.instruction_id,
     p.participant_id,
     p.sequence_id,
     p.idempotency_key,
     p.rail_type,
     p.payload,
     p.attempt_count,
     p.lease_token,
     p.lease_expires_at
 )
 SELECT * FROM leased;
 $$;


--
-- Name: classify_orphan_or_replay(text, text, boolean, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.classify_orphan_or_replay(p_instruction_id text, p_event_fingerprint text, p_is_late_callback boolean, p_is_duplicate_dispatch boolean, p_has_unknown_reference boolean, p_is_replay boolean) RETURNS public.orphan_classification_enum
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: cleanup_expired_verifier_tokens(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cleanup_expired_verifier_tokens() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_count INT;
BEGIN
    UPDATE public.gf_verifier_read_tokens
       SET revoked_at = now(),
           revocation_reason = 'expired_cleanup'
     WHERE expires_at <= now()
       AND revoked_at IS NULL;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;


--
-- Name: complete_anchor_sync_operation(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_anchor_sync_operation(p_operation_id uuid, p_lease_token uuid, p_worker_id text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_op public.anchor_sync_operations%ROWTYPE;
BEGIN
  SELECT * INTO v_op
  FROM public.anchor_sync_operations
  WHERE operation_id = p_operation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'anchor operation not found' USING ERRCODE = 'P7210';
  END IF;

  IF v_op.claimed_by IS DISTINCT FROM p_worker_id THEN
    RAISE EXCEPTION 'anchor operation worker mismatch' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.lease_token IS DISTINCT FROM p_lease_token OR v_op.lease_expires_at IS NULL OR v_op.lease_expires_at <= clock_timestamp() THEN
    RAISE EXCEPTION 'anchor operation lease invalid' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.state <> 'ANCHORED' OR NULLIF(BTRIM(v_op.anchor_ref), '') IS NULL THEN
    RAISE EXCEPTION 'anchor completion requires anchored state' USING ERRCODE = 'P7211';
  END IF;

  UPDATE public.anchor_sync_operations
  SET state = 'COMPLETED',
      lease_token = NULL,
      lease_expires_at = NULL
  WHERE operation_id = v_op.operation_id;
END;
$$;


--
-- Name: complete_outbox_attempt(uuid, uuid, text, public.outbox_attempt_state, text, text, text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_outbox_attempt(p_outbox_id uuid, p_lease_token uuid, p_worker_id text, p_state public.outbox_attempt_state, p_rail_reference text DEFAULT NULL::text, p_rail_code text DEFAULT NULL::text, p_error_code text DEFAULT NULL::text, p_error_message text DEFAULT NULL::text, p_latency_ms integer DEFAULT NULL::integer, p_retry_delay_seconds integer DEFAULT 1) RETURNS TABLE(attempt_no integer, state public.outbox_attempt_state)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
  DECLARE
    v_instruction_id TEXT; v_participant_id TEXT; v_sequence_id BIGINT;
    v_idempotency_key TEXT; v_rail_type TEXT; v_payload JSONB;
    v_next_attempt_no INT; v_effective_state outbox_attempt_state;
  BEGIN
    SELECT p.instruction_id, p.participant_id, p.sequence_id, p.idempotency_key, p.rail_type, p.payload
    INTO v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload
    FROM payment_outbox_pending p
    WHERE p.outbox_id = p_outbox_id AND p.claimed_by = p_worker_id
      AND p.lease_token = p_lease_token AND p.lease_expires_at > NOW()
    FOR UPDATE;
  
    IF NOT FOUND THEN
      RAISE EXCEPTION 'LEASE_LOST' USING ERRCODE = 'P7002',
        DETAIL = 'Lease missing/expired or token mismatch; refusing to complete';
    END IF;
  
    IF p_state NOT IN ('DISPATCHED', 'FAILED', 'RETRYABLE') THEN
      RAISE EXCEPTION 'Invalid completion state %', p_state USING ERRCODE = 'P7003';
    END IF;
  
    SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
    FROM payment_outbox_attempts a WHERE a.outbox_id = p_outbox_id;
  
    v_effective_state := p_state;
    -- Retry ceiling is a safety fuse to prevent infinite retry loops.
    -- Configurable via GUC; default 20.
    IF p_state = 'RETRYABLE' AND v_next_attempt_no >= public.outbox_retry_ceiling() THEN
      v_effective_state := 'FAILED';
    END IF;
  
    INSERT INTO payment_outbox_attempts (
      outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
      attempt_no, state, claimed_at, completed_at, rail_reference, rail_code,
      error_code, error_message, latency_ms, worker_id
    ) VALUES (
      p_outbox_id, v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload,
      v_next_attempt_no, v_effective_state, NOW(),
      CASE WHEN v_effective_state IN ('DISPATCHED', 'FAILED') THEN NOW() ELSE NULL END,
      p_rail_reference, p_rail_code, p_error_code, p_error_message, p_latency_ms, p_worker_id
    );
  
    IF v_effective_state IN ('DISPATCHED', 'FAILED') THEN
      DELETE FROM payment_outbox_pending WHERE outbox_id = p_outbox_id;
    ELSE
      UPDATE payment_outbox_pending SET
        attempt_count = GREATEST(attempt_count, v_next_attempt_no),
        next_attempt_at = NOW() + make_interval(secs => GREATEST(1, COALESCE(p_retry_delay_seconds, 1))),
        claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
      WHERE outbox_id = p_outbox_id;
    END IF;
  
    RETURN QUERY SELECT v_next_attempt_no, v_effective_state;
  END;
$$;


--
-- Name: compute_effect_seal_hash(text, jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_effect_seal_hash(p_instruction_id text, p_payload jsonb, p_canonicalization_version text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_input text;
BEGIN
  v_input := coalesce(p_instruction_id, '') || '|' || coalesce(p_canonicalization_version, '') || '|' || coalesce(p_payload::text, '{}');
  RETURN md5(v_input);
END;
$$;


--
-- Name: create_internal_ledger_journal(uuid, text, text, text, jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_internal_ledger_journal(p_tenant_id uuid, p_idempotency_key text, p_journal_type text, p_currency_code text, p_postings jsonb, p_reference_id text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_existing UUID;
  v_journal_id UUID;
  v_item JSONB;
BEGIN
  IF p_postings IS NULL OR jsonb_typeof(p_postings) <> 'array' OR jsonb_array_length(p_postings) < 2 THEN
    RAISE EXCEPTION 'p_postings must contain at least two postings'
      USING ERRCODE = '23514';
  END IF;

  SELECT journal_id
    INTO v_existing
  FROM public.internal_ledger_journals
  WHERE tenant_id = p_tenant_id
    AND idempotency_key = p_idempotency_key;

  IF v_existing IS NOT NULL THEN
    RETURN v_existing;
  END IF;

  INSERT INTO public.internal_ledger_journals(
    tenant_id, idempotency_key, journal_type, reference_id, currency_code
  ) VALUES (
    p_tenant_id, p_idempotency_key, p_journal_type, p_reference_id, p_currency_code
  )
  RETURNING journal_id INTO v_journal_id;

  FOR v_item IN
    SELECT value
    FROM jsonb_array_elements(p_postings)
  LOOP
    INSERT INTO public.internal_ledger_postings(
      journal_id, tenant_id, account_code, direction, amount_minor, currency_code
    ) VALUES (
      v_journal_id,
      p_tenant_id,
      v_item->>'account_code',
      upper(v_item->>'direction'),
      (v_item->>'amount_minor')::BIGINT,
      COALESCE(v_item->>'currency_code', p_currency_code)
    );
  END LOOP;

  IF NOT public.verify_internal_ledger_journal_balance(v_journal_id) THEN
    RAISE EXCEPTION 'journal is not balanced'
      USING ERRCODE = '23514';
  END IF;

  RETURN v_journal_id;
END;
$$;


--
-- Name: current_jurisdiction_code_or_null(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_jurisdiction_code_or_null() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
  SELECT current_setting('app.jurisdiction_code', true);
$$;


--
-- Name: current_tenant_id_or_null(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_tenant_id_or_null() RETURNS uuid
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
  v text;
BEGIN
  v := current_setting('app.current_tenant_id', true);
  IF v IS NULL OR btrim(v) = '' THEN
    RETURN NULL;
  END IF;

  BEGIN
    RETURN v::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN NULL;
  END;
END;
$$;


--
-- Name: decide_supervisor_approval(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.decide_supervisor_approval(p_instruction_id text, p_decision text, p_actor text, p_reason text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_decision TEXT := UPPER(BTRIM(COALESCE(p_decision, '')));
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
BEGIN
  IF v_decision NOT IN ('APPROVED', 'REJECTED') THEN
    RAISE EXCEPTION 'invalid decision %', p_decision;
  END IF;

  UPDATE public.supervisor_approval_queue
  SET status = v_decision,
      approved_at = CASE WHEN v_decision = 'APPROVED' THEN NOW() ELSE approved_at END,
      approved_by = CASE WHEN v_decision = 'APPROVED' THEN v_actor ELSE approved_by END,
      decided_at = NOW(),
      decided_by = v_actor,
      decision_reason = p_reason
  WHERE instruction_id = p_instruction_id
    AND status = 'PENDING_SUPERVISOR_APPROVAL'
    AND COALESCE(submitted_by, '') <> v_actor;

  IF NOT FOUND THEN
    IF EXISTS (
      SELECT 1
      FROM public.supervisor_approval_queue
      WHERE instruction_id = p_instruction_id
        AND status = 'PENDING_SUPERVISOR_APPROVAL'
        AND COALESCE(submitted_by, '') = v_actor
    ) THEN
      RAISE EXCEPTION 'self approval is not permitted for instruction %', p_instruction_id
        USING ERRCODE = '42501';
    END IF;

    RAISE EXCEPTION 'instruction % is not pending supervisor approval', p_instruction_id;
  END IF;
END;
$$;


--
-- Name: deny_append_only_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_append_only_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RAISE EXCEPTION '% is append-only', TG_TABLE_NAME
      USING ERRCODE = 'P0001';
  END;
$$;


--
-- Name: deny_final_instruction_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_final_instruction_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.is_final IS TRUE THEN
    RAISE EXCEPTION 'final instruction cannot be mutated'
      USING ERRCODE = 'P7003';
  END IF;
  RETURN OLD;
END;
$$;


--
-- Name: deny_ingress_attestations_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_ingress_attestations_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RAISE EXCEPTION 'ingress_attestations is append-only'
      USING ERRCODE = 'P0001';
  END;
$$;


--
-- Name: deny_member_device_events_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_member_device_events_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'member_device_events is append-only'
    USING ERRCODE = 'P0001';
END;
$$;


--
-- Name: deny_outbox_attempts_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_outbox_attempts_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RAISE EXCEPTION 'payment_outbox_attempts is append-only'
      USING ERRCODE = 'P0001';
  END;
$$;


--
-- Name: deny_pii_vault_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_pii_vault_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF current_setting('symphony.allow_pii_purge', true) = 'on' THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'pii_vault_records updates require purge executor'
      USING ERRCODE = 'P7004';
  END IF;

  RAISE EXCEPTION 'pii_vault_records is non-deletable'
    USING ERRCODE = 'P7004';
END;
$$;


--
-- Name: deny_revocation_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_revocation_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RAISE EXCEPTION 'revocation tables are append-only'
      USING ERRCODE = 'P0001';
  END;
$$;


--
-- Name: deny_sim_swap_alerts_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_sim_swap_alerts_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'sim_swap_alerts is append-only'
    USING ERRCODE = 'P0001';
END;
$$;


--
-- Name: derive_sim_swap_alert(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.derive_sim_swap_alert(p_event_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_event public.member_device_events%ROWTYPE;
  v_prior_iccid_hash TEXT;
  v_formula_version_id UUID;
  v_alert_id UUID;
BEGIN
  SELECT e.*
  INTO v_event
  FROM public.member_device_events e
  WHERE e.event_id = p_event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'member_device_event % not found', p_event_id
      USING ERRCODE = 'P7400';
  END IF;

  IF v_event.event_type <> 'SIM_SWAP_DETECTED' OR v_event.iccid_hash IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT md.iccid_hash
  INTO v_prior_iccid_hash
  FROM public.member_devices md
  WHERE md.tenant_id = v_event.tenant_id
    AND md.member_id = v_event.member_id
    AND md.status = 'ACTIVE'
    AND md.iccid_hash IS NOT NULL
    AND md.iccid_hash <> v_event.iccid_hash
  ORDER BY md.created_at DESC, md.device_id_hash DESC
  LIMIT 1;

  IF v_prior_iccid_hash IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT rf.formula_version_id
  INTO v_formula_version_id
  FROM public.risk_formula_versions rf
  WHERE rf.formula_key = 'TIER1_DETERMINISTIC_DEFAULT'
    AND rf.is_active = TRUE
  ORDER BY rf.created_at DESC
  LIMIT 1;

  IF v_formula_version_id IS NULL THEN
    RAISE EXCEPTION 'active formula key % not found', 'TIER1_DETERMINISTIC_DEFAULT'
      USING ERRCODE = 'P7401';
  END IF;

  INSERT INTO public.sim_swap_alerts(
    tenant_id,
    member_id,
    source_event_id,
    prior_iccid_hash,
    new_iccid_hash,
    formula_version_id,
    alert_type,
    derived_at
  )
  VALUES (
    v_event.tenant_id,
    v_event.member_id,
    v_event.event_id,
    v_prior_iccid_hash,
    v_event.iccid_hash,
    v_formula_version_id,
    'SIM_SWAP_DETECTED',
    COALESCE(v_event.observed_at, NOW())
  )
  ON CONFLICT (source_event_id) DO NOTHING
  RETURNING alert_id INTO v_alert_id;

  IF v_alert_id IS NULL THEN
    SELECT s.alert_id
    INTO v_alert_id
    FROM public.sim_swap_alerts s
    WHERE s.source_event_id = v_event.event_id;
  END IF;

  RETURN v_alert_id;
END;
$$;


--
-- Name: enforce_adjustment_terminal_immutability(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_adjustment_terminal_immutability() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF TG_OP='UPDATE' AND OLD.adjustment_state IN ('executed','denied','blocked_legal_hold') THEN
    RAISE EXCEPTION 'ADJUSTMENT_TERMINAL_IMMUTABLE' USING ERRCODE = 'P7101';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: enforce_confidence_before_issuance(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_confidence_before_issuance() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_confidence_score  NUMERIC;
    v_required_threshold NUMERIC := 0.95;
    v_to_status         TEXT;
    v_from_status       TEXT;
    v_decision_count    INT;
    v_approved_count    INT;
BEGIN
    -- Only enforce on transitions TO 'ISSUED'
    v_to_status := NEW.event_payload_json->>'to_status';
    v_from_status := NEW.event_payload_json->>'from_status';

    IF v_to_status IS NULL OR v_to_status != 'ISSUED' THEN
        RETURN NEW;
    END IF;

    -- ── Count authority decisions for this batch ────────────────────────────
    -- A batch must have at least one APPROVED authority decision to be issued.
    SELECT COUNT(*),
           COUNT(*) FILTER (
               WHERE (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
           )
      INTO v_decision_count, v_approved_count
      FROM public.authority_decisions ad
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
       AND (ad.decision_payload_json->>'subject_id')::UUID = NEW.asset_batch_id;

    -- ── Fail-closed: no decisions = no issuance ────────────────────────────
    IF v_decision_count = 0 THEN
        RAISE EXCEPTION 'CONF001: No authority decisions found for batch %. Issuance blocked (fail-closed).',
            NEW.asset_batch_id
            USING ERRCODE = 'GF020';
    END IF;

    IF v_approved_count = 0 THEN
        RAISE EXCEPTION 'CONF002: No APPROVED authority decisions for batch %. Issuance blocked.',
            NEW.asset_batch_id
            USING ERRCODE = 'GF021';
    END IF;

    -- ── Mathematical confidence validation ─────────────────────────────────
    -- Aggregate confidence from approved decisions. Each decision's
    -- confidence_score is stored in decision_payload_json.
    -- The confidence_score must be a value between 0 and 1.
    SELECT COALESCE(
               AVG(
                   (ad.decision_payload_json->>'confidence_score')::NUMERIC
               ),
               0
           )
      INTO v_confidence_score
      FROM public.authority_decisions ad
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
       AND (ad.decision_payload_json->>'subject_id')::UUID = NEW.asset_batch_id
       AND (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
       AND ad.decision_payload_json->>'confidence_score' IS NOT NULL;

    -- ── Threshold enforcement ──────────────────────────────────────────────
    -- Mathematical gate: confidence_score < required_threshold => block
    IF v_confidence_score < v_required_threshold THEN
        RAISE EXCEPTION 'CONF003: Insufficient confidence for issuance. Required: %, Actual: %. Batch: %',
            v_required_threshold, v_confidence_score, NEW.asset_batch_id
            USING ERRCODE = 'GF022';
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: enforce_instruction_reversal_source(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_instruction_reversal_source() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_source_state TEXT;
  v_source_final BOOLEAN;
BEGIN
  IF NEW.is_final IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'instruction settlement rows must be final'
      USING ERRCODE = 'P7003';
  END IF;

  IF NEW.reversal_of_instruction_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT final_state, is_final
  INTO v_source_state, v_source_final
  FROM public.instruction_settlement_finality
  WHERE instruction_id = NEW.reversal_of_instruction_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'reversal requires existing instruction %', NEW.reversal_of_instruction_id
      USING ERRCODE = 'P7003';
  END IF;

  IF v_source_state <> 'SETTLED' OR v_source_final IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'reversal source instruction must be final and SETTLED: %', NEW.reversal_of_instruction_id
      USING ERRCODE = 'P7003';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: enforce_internal_ledger_posting_context(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_internal_ledger_posting_context() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_journal_tenant UUID;
  v_journal_currency TEXT;
BEGIN
  SELECT tenant_id, currency_code
    INTO v_journal_tenant, v_journal_currency
  FROM public.internal_ledger_journals
  WHERE journal_id = NEW.journal_id;

  IF v_journal_tenant IS NULL THEN
    RAISE EXCEPTION 'journal not found for posting'
      USING ERRCODE = '23503';
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_journal_tenant THEN
    RAISE EXCEPTION 'cross-tenant posting rejected'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.currency_code IS DISTINCT FROM v_journal_currency THEN
    RAISE EXCEPTION 'posting currency must match journal currency'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: enforce_member_tenant_match(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_member_tenant_match() RETURNS trigger
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


--
-- Name: enforce_settlement_acknowledgement(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_settlement_acknowledgement() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  IF NEW.final_state = 'SETTLED' THEN
    PERFORM public.guard_settlement_requires_acknowledgement(NEW.instruction_id);
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: enqueue_payment_outbox(text, text, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_payment_outbox(p_instruction_id text, p_participant_id text, p_idempotency_key text, p_rail_type text, p_payload jsonb) RETURNS TABLE(outbox_id uuid, sequence_id bigint, created_at timestamp with time zone, state text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
  DECLARE
    existing_pending RECORD;
    existing_attempt RECORD;
    allocated_sequence BIGINT;
  BEGIN
    -- One 64-bit lock key derived from both fields to avoid int4 truncation.
    PERFORM pg_advisory_xact_lock(
      hashtextextended(p_instruction_id || chr(31) || p_idempotency_key, 1)
    );

    SELECT p.outbox_id, p.sequence_id, p.created_at
    INTO existing_pending
    FROM payment_outbox_pending p
    WHERE p.instruction_id = p_instruction_id
      AND p.idempotency_key = p_idempotency_key
    LIMIT 1;

    IF FOUND THEN
      RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
      RETURN;
    END IF;

    SELECT a.outbox_id, a.sequence_id, a.created_at, a.state
    INTO existing_attempt
    FROM payment_outbox_attempts a
    WHERE a.instruction_id = p_instruction_id
      AND a.idempotency_key = p_idempotency_key
    ORDER BY a.claimed_at DESC
    LIMIT 1;

    IF FOUND THEN
      RETURN QUERY SELECT existing_attempt.outbox_id, existing_attempt.sequence_id, existing_attempt.created_at, existing_attempt.state::TEXT;
      RETURN;
    END IF;

    allocated_sequence := bump_participant_outbox_seq(p_participant_id);

    BEGIN
      INSERT INTO payment_outbox_pending (
        instruction_id,
        participant_id,
        sequence_id,
        idempotency_key,
        rail_type,
        payload
      )
      VALUES (
        p_instruction_id,
        p_participant_id,
        allocated_sequence,
        p_idempotency_key,
        p_rail_type,
        p_payload
      )
      RETURNING payment_outbox_pending.outbox_id, payment_outbox_pending.sequence_id, payment_outbox_pending.created_at
      INTO existing_pending;
    EXCEPTION
      WHEN unique_violation THEN
        SELECT p.outbox_id, p.sequence_id, p.created_at
        INTO existing_pending
        FROM payment_outbox_pending p
        WHERE p.instruction_id = p_instruction_id
          AND p.idempotency_key = p_idempotency_key
        LIMIT 1;
        IF NOT FOUND THEN
          RAISE;
        END IF;
    END;

    -- Wakeup-only notify (best-effort). Empty payload.
    PERFORM pg_notify('symphony_outbox', '');

    RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
  END;
$$;


--
-- Name: ensure_anchor_sync_operation(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_anchor_sync_operation(p_pack_id uuid, p_anchor_provider text DEFAULT 'GENERIC'::text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_operation_id UUID;
BEGIN
  IF p_pack_id IS NULL THEN
    RAISE EXCEPTION 'pack_id is required' USING ERRCODE = 'P7210';
  END IF;

  INSERT INTO public.anchor_sync_operations(pack_id, anchor_provider)
  VALUES (p_pack_id, COALESCE(NULLIF(BTRIM(p_anchor_provider), ''), 'GENERIC'))
  ON CONFLICT (pack_id) DO NOTHING
  RETURNING operation_id INTO v_operation_id;

  IF v_operation_id IS NULL THEN
    SELECT operation_id INTO v_operation_id
    FROM public.anchor_sync_operations
    WHERE pack_id = p_pack_id;
  END IF;

  RETURN v_operation_id;
END;
$$;


--
-- Name: escalate_missing_acknowledgement(text, uuid, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.escalate_missing_acknowledgement(p_instruction_id text, p_program_id uuid, p_policy_version_id text, p_actor text DEFAULT 'system'::text, p_reason text DEFAULT 'missing_acknowledgement'::text, p_timeout_minutes integer DEFAULT 30) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_state public.inquiry_state_enum;
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
BEGIN
  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_state IS NULL THEN
    RAISE EXCEPTION 'acknowledgement_state_not_found' USING ERRCODE = 'P7300';
  END IF;

  IF v_state <> 'AWAITING_EXECUTION' THEN
    RAISE EXCEPTION 'illegal_escalation_from_state:%', v_state USING ERRCODE = 'P7300';
  END IF;

  PERFORM public.submit_for_supervisor_approval(
    p_instruction_id,
    p_program_id,
    p_timeout_minutes,
    p_reason,
    v_actor
  );

  UPDATE public.supervisor_approval_queue
  SET status = 'ESCALATED',
      held_reason = COALESCE(p_reason, held_reason, 'missing_acknowledgement'),
      escalated_at = NOW(),
      decided_at = NULL,
      decided_by = NULL,
      decision_reason = NULL
  WHERE instruction_id = p_instruction_id;

  UPDATE public.inquiry_state_machine
  SET inquiry_state = 'ESCALATED',
      policy_version_id = p_policy_version_id
  WHERE instruction_id = p_instruction_id;

  INSERT INTO public.supervisor_interrupt_audit_events(
    instruction_id, program_id, action, queue_status, actor, reason
  ) VALUES (
    p_instruction_id, p_program_id, 'ESCALATED', 'ESCALATED', v_actor, p_reason
  );
END;
$$;


--
-- Name: evaluate_adjustment_ceiling(uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.evaluate_adjustment_ceiling(p_adjustment_id uuid, p_parent_instruction_value numeric) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_parent text;
  v_total numeric;
BEGIN
  SELECT parent_instruction_id INTO v_parent FROM public.adjustment_instructions WHERE adjustment_id = p_adjustment_id;
  SELECT coalesce(sum(a.adjustment_value),0)
  INTO v_total
  FROM public.adjustment_execution_attempts e
  JOIN public.adjustment_instructions a ON a.adjustment_id=e.adjustment_id
  WHERE a.parent_instruction_id=v_parent AND e.outcome='executed';

  IF v_total > p_parent_instruction_value THEN
    RAISE EXCEPTION 'ADJUSTMENT_CEILING_BREACH' USING ERRCODE = 'P7201';
  END IF;
END;
$$;


--
-- Name: evaluate_circuit_breaker(text, text, numeric, numeric, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.evaluate_circuit_breaker(p_adapter_id text, p_rail_id text, p_trigger_threshold numeric, p_observed_rate numeric, p_window_seconds integer, p_policy_version_id text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: execute_pii_purge(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.execute_pii_purge(p_purge_request_id uuid, p_executor text) RETURNS TABLE(purge_request_id uuid, rows_affected integer, already_purged boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_subject_token TEXT;
  v_rows INTEGER := 0;
  v_prior INTEGER := 0;
BEGIN
  SELECT r.subject_token
  INTO v_subject_token
  FROM public.pii_purge_requests r
  WHERE r.purge_request_id = p_purge_request_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'purge request not found: %', p_purge_request_id
      USING ERRCODE = 'P7004';
  END IF;

  SELECT e.rows_affected
  INTO v_prior
  FROM public.pii_purge_events e
  WHERE e.purge_request_id = p_purge_request_id
    AND e.event_type = 'PURGED'
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT p_purge_request_id, v_prior, TRUE;
    RETURN;
  END IF;

  PERFORM set_config('symphony.allow_pii_purge', 'on', true);

  UPDATE public.pii_vault_records
     SET protected_payload = NULL,
         purged_at = NOW(),
         purge_request_id = p_purge_request_id
   WHERE subject_token = v_subject_token
     AND purged_at IS NULL;

  GET DIAGNOSTICS v_rows = ROW_COUNT;

  INSERT INTO public.pii_purge_events(
    purge_request_id,
    event_type,
    rows_affected,
    metadata
  ) VALUES (
    p_purge_request_id,
    'PURGED',
    v_rows,
    jsonb_build_object('executor', p_executor)
  )
  ON CONFLICT ON CONSTRAINT ux_pii_purge_events_request_event
  DO NOTHING;

  RETURN QUERY SELECT p_purge_request_id, v_rows, FALSE;
END;
$$;


--
-- Name: expire_escrows(timestamp with time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.expire_escrows(p_now timestamp with time zone DEFAULT now(), p_actor_id text DEFAULT 'escrow_expiry_worker'::text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_escrow_id UUID;
  v_count INTEGER := 0;
BEGIN
  FOR v_escrow_id IN
    SELECT e.escrow_id
    FROM public.escrow_accounts e
    WHERE
      (e.state = 'CREATED' AND e.authorization_expires_at IS NOT NULL AND e.authorization_expires_at <= p_now)
      OR (e.state = 'AUTHORIZED' AND e.authorization_expires_at IS NOT NULL AND e.authorization_expires_at <= p_now)
      OR (e.state = 'RELEASE_REQUESTED' AND e.release_due_at IS NOT NULL AND e.release_due_at <= p_now)
  LOOP
    PERFORM public.transition_escrow_state(
      p_escrow_id => v_escrow_id,
      p_to_state => 'EXPIRED',
      p_actor_id => p_actor_id,
      p_reason => 'window_elapsed',
      p_metadata => jsonb_build_object('expired_at', p_now),
      p_now => p_now
    );
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;


--
-- Name: expire_supervisor_approvals(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.expire_supervisor_approvals(p_now timestamp with time zone DEFAULT now()) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  UPDATE public.supervisor_approval_queue
  SET status = 'TIMED_OUT',
      decided_at = p_now,
      decided_by = 'system_timeout',
      decision_reason = COALESCE(decision_reason, 'timeout')
  WHERE status = 'PENDING_SUPERVISOR_APPROVAL'
    AND timeout_at <= p_now;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;


--
-- Name: get_checkpoint_requirements(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_checkpoint_requirements(p_jurisdiction_code text) RETURNS TABLE(lifecycle_checkpoint_rule_id uuid, regulatory_checkpoint_id uuid, rule_type text, rule_payload_json jsonb)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT lcr.lifecycle_checkpoint_rule_id,
           lcr.regulatory_checkpoint_id,
           lcr.rule_type,
           lcr.rule_payload_json
      FROM public.lifecycle_checkpoint_rules lcr
     WHERE lcr.jurisdiction_code = p_jurisdiction_code
     ORDER BY lcr.created_at ASC;
END;
$$;


--
-- Name: get_evidence_node(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_evidence_node(p_tenant_id uuid, p_evidence_node_id uuid) RETURNS TABLE(evidence_node_id uuid, project_id uuid, monitoring_record_id uuid, node_type text, node_payload_json jsonb, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT en.evidence_node_id,
           en.project_id,
           en.monitoring_record_id,
           en.node_type,
           en.node_payload_json,
           en.created_at
      FROM public.evidence_nodes en
     WHERE en.evidence_node_id = p_evidence_node_id
       AND en.tenant_id        = p_tenant_id;
END;
$$;


--
-- Name: get_monitoring_record_payload(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_monitoring_record_payload(p_tenant_id uuid, p_monitoring_record_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_payload JSONB;
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF007';
    END IF;
    IF p_monitoring_record_id IS NULL THEN
        RAISE EXCEPTION 'p_monitoring_record_id is required' USING ERRCODE = 'GF014';
    END IF;

    SELECT mr.record_payload_json
      INTO v_payload
      FROM public.monitoring_records mr
     WHERE mr.monitoring_record_id = p_monitoring_record_id
       AND mr.tenant_id            = p_tenant_id;

    RETURN v_payload;
END;
$$;


--
-- Name: gf_verifier_read_tokens_append_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gf_verifier_read_tokens_append_only() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'DELETE not allowed on gf_verifier_read_tokens (append-only ledger)'
            USING ERRCODE = 'GF001';
    END IF;
    IF TG_OP = 'UPDATE' THEN
        -- Only allow setting revoked_at (soft revocation)
        IF OLD.token_hash != NEW.token_hash
           OR OLD.verifier_id != NEW.verifier_id
           OR OLD.project_id != NEW.project_id
           OR OLD.tenant_id != NEW.tenant_id
           OR OLD.expires_at != NEW.expires_at
        THEN
            RAISE EXCEPTION 'UPDATE not allowed on immutable columns of gf_verifier_read_tokens'
                USING ERRCODE = 'GF001';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: gf_verifier_tables_append_only(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gf_verifier_tables_append_only() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION 'Table % is append-only', TG_TABLE_NAME
            USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: guard_auto_finalize_when_inquiry_exhausted(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_auto_finalize_when_inquiry_exhausted(p_instruction_id text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_state public.inquiry_state_enum;
BEGIN
  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id;

  IF v_state = 'EXHAUSTED' THEN
    RAISE EXCEPTION 'INQUIRY_EXHAUSTED_AUTO_FINALIZE_BLOCKED' USING ERRCODE = 'P7301';
  END IF;
END;
$$;


--
-- Name: guard_settlement_requires_acknowledgement(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_settlement_requires_acknowledgement(p_instruction_id text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_state public.inquiry_state_enum;
BEGIN
  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id;

  IF v_state IS DISTINCT FROM 'ACKNOWLEDGED' THEN
    RAISE EXCEPTION 'ACKNOWLEDGEMENT_REQUIRED_BEFORE_SETTLEMENT' USING ERRCODE = 'P7301';
  END IF;
END;
$$;


--
-- Name: issue_adjustment(text, text, numeric, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.issue_adjustment(p_parent_instruction_id text, p_adjustment_type text, p_adjustment_value numeric, p_policy_version_id text, p_justification text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_id uuid;
  v_recipient text;
BEGIN
  SELECT 'parent:' || p_parent_instruction_id INTO v_recipient;
  INSERT INTO public.adjustment_instructions(
    parent_instruction_id, adjustment_type, adjustment_value,
    recipient_ref, policy_version_id, justification
  ) VALUES (
    p_parent_instruction_id, p_adjustment_type, p_adjustment_value,
    v_recipient, p_policy_version_id, p_justification
  ) RETURNING adjustment_id INTO v_id;
  RETURN v_id;
END;
$$;


--
-- Name: issue_adjustment_with_recipient(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.issue_adjustment_with_recipient(p_parent_instruction_id text, p_recipient text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  RAISE EXCEPTION 'ADJUSTMENT_RECIPIENT_NOT_PERMITTED' USING ERRCODE = 'P7601';
END;
$$;


--
-- Name: issue_asset_batch(uuid, uuid, uuid, uuid, uuid, text, numeric, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.issue_asset_batch(p_tenant_id uuid, p_project_id uuid, p_methodology_version_id uuid, p_adapter_registration_id uuid, p_interpretation_pack_id uuid, p_asset_type text, p_quantity numeric, p_unit text, p_metadata_json jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_asset_batch_id          UUID;
    v_project_status          TEXT;
    v_adapter_active          BOOLEAN;
    v_unsatisfied_checkpoints INT;
    v_conditional_count       INT;
    v_jurisdiction_code       TEXT;
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_methodology_version_id IS NULL THEN
        RAISE EXCEPTION 'p_methodology_version_id is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_adapter_registration_id IS NULL THEN
        RAISE EXCEPTION 'p_adapter_registration_id is required' USING ERRCODE = 'GF004';
    END IF;
    IF p_asset_type IS NULL THEN
        RAISE EXCEPTION 'p_asset_type is required' USING ERRCODE = 'GF005';
    END IF;
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'p_quantity must be positive' USING ERRCODE = 'GF006';
    END IF;
    IF p_unit IS NULL THEN
        RAISE EXCEPTION 'p_unit is required' USING ERRCODE = 'GF007';
    END IF;

    -- ── INV-165: interpretation_pack_id enforcement ─────────────────────────
    IF p_interpretation_pack_id IS NULL THEN
        RAISE EXCEPTION 'interpretation_pack_id is required (INV-165)'
            USING ERRCODE = 'P0001';
    END IF;

    -- ── Project ACTIVE status validation ────────────────────────────────────
    SELECT p.status INTO v_project_status
      FROM public.projects p
     WHERE p.project_id = p_project_id
       AND p.tenant_id = p_tenant_id;

    IF v_project_status IS NULL THEN
        RAISE EXCEPTION 'Project not found' USING ERRCODE = 'GF008';
    END IF;
    IF v_project_status != 'ACTIVE' THEN
        RAISE EXCEPTION 'Project must be ACTIVE for issuance, current status: %', v_project_status
            USING ERRCODE = 'GF009';
    END IF;

    -- Check is_active = true for adapter registration
    SELECT ar.is_active INTO v_adapter_active
      FROM public.adapter_registrations ar
     WHERE ar.adapter_registration_id = p_adapter_registration_id;

    IF v_adapter_active IS NULL THEN
        RAISE EXCEPTION 'Adapter registration not found' USING ERRCODE = 'GF010';
    END IF;
    IF v_adapter_active != true THEN
        RAISE EXCEPTION 'Adapter registration is not active' USING ERRCODE = 'GF011';
    END IF;

    -- ── Lifecycle checkpoint rules validation (ACTIVE->ISSUED) ──────────────
    -- Fail-closed: count unsatisfied REQUIRED checkpoints. If any exist, block.
    -- CONDITIONALLY_REQUIRED transitions to PENDING_CLARIFICATION.
    SELECT p.jurisdiction_code INTO v_jurisdiction_code
      FROM public.projects p
     WHERE p.project_id = p_project_id;

    IF v_jurisdiction_code IS NOT NULL THEN
        SELECT COUNT(*) INTO v_unsatisfied_checkpoints
          FROM public.lifecycle_checkpoint_rules lcr
         WHERE lcr.jurisdiction_code = v_jurisdiction_code
           AND lcr.rule_type = 'REQUIRED';

        SELECT COUNT(*) INTO v_conditional_count
          FROM public.lifecycle_checkpoint_rules lcr
         WHERE lcr.jurisdiction_code = v_jurisdiction_code
           AND lcr.rule_type = 'CONDITIONALLY_REQUIRED';

        IF v_unsatisfied_checkpoints > 0 THEN
            RAISE EXCEPTION 'Issuance blocked: % unsatisfied REQUIRED checkpoints for ACTIVE->ISSUED transition',
                v_unsatisfied_checkpoints
                USING ERRCODE = 'GF012';
        END IF;

        IF v_conditional_count > 0 THEN
            -- PENDING_CLARIFICATION: conditional checkpoints exist but do not block
            NULL; -- Provisional pass; confidence enforcement trigger handles final gate
        END IF;
    END IF;

    -- ── Insert asset batch ──────────────────────────────────────────────────
    INSERT INTO asset_batches (
        tenant_id, project_id, batch_type, quantity, status
    ) VALUES (
        p_tenant_id, p_project_id, p_asset_type, p_quantity, 'ISSUED'
    )
    RETURNING asset_batch_id INTO v_asset_batch_id;

    -- ── Record lifecycle event (triggers confidence enforcement) ─────────────
    INSERT INTO asset_lifecycle_events (
        tenant_id, asset_batch_id, event_type,
        event_payload_json
    ) VALUES (
        p_tenant_id, v_asset_batch_id, 'STATUS_CHANGE',
        jsonb_build_object(
            'from_status', 'ACTIVE',
            'to_status', 'ISSUED',
            'asset_type', p_asset_type,
            'quantity', p_quantity,
            'unit', p_unit,
            'methodology_version_id', p_methodology_version_id,
            'adapter_registration_id', p_adapter_registration_id,
            'interpretation_pack_id', p_interpretation_pack_id,
            'metadata', p_metadata_json
        )
    );

    RETURN v_asset_batch_id;
END;
$$;


--
-- Name: issue_verifier_read_token(uuid, uuid, uuid, integer, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.issue_verifier_read_token(p_tenant_id uuid, p_verifier_id uuid, p_project_id uuid, p_ttl_hours integer DEFAULT 720, p_scoped_tables jsonb DEFAULT '["evidence_nodes", "monitoring_records", "asset_batches", "verification_cases"]'::jsonb) RETURNS TABLE(token_id uuid, token_secret text, expires_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_token_id       UUID;
    v_token_secret   TEXT;
    v_token_hash     TEXT;
    v_expires_at     TIMESTAMPTZ;
    v_verifier_active BOOLEAN;
    v_methodology_scope JSONB;
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_verifier_id IS NULL THEN
        RAISE EXCEPTION 'p_verifier_id is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF004';
    END IF;
    IF p_ttl_hours IS NULL OR p_ttl_hours <= 0 OR p_ttl_hours > 8760 THEN
        RAISE EXCEPTION 'p_ttl_hours must be between 1 and 8760' USING ERRCODE = 'GF005';
    END IF;

    -- ── Verifier validation ─────────────────────────────────────────────────
    SELECT vr.is_active, vr.methodology_scope
      INTO v_verifier_active, v_methodology_scope
      FROM public.verifier_registry vr
     WHERE vr.verifier_id = p_verifier_id
       AND vr.tenant_id = p_tenant_id;

    IF v_verifier_active IS NULL THEN
        RAISE EXCEPTION 'Verifier not found' USING ERRCODE = 'GF006';
    END IF;
    IF v_verifier_active != true THEN
        RAISE EXCEPTION 'Verifier is not active' USING ERRCODE = 'GF007';
    END IF;

    -- ── Regulation 26 separation check ──────────────────────────────────────
    PERFORM public.check_reg26_separation(p_verifier_id, p_project_id, 'VERIFIER');

    -- ── Generate cryptographic token ────────────────────────────────────────
    v_token_secret := encode(public.gen_random_bytes(32), 'hex');
    v_token_hash := public.crypt(v_token_secret, public.gen_salt('bf', 8));
    v_expires_at := now() + (p_ttl_hours || ' hours')::INTERVAL;

    -- ── Insert token record ─────────────────────────────────────────────────
    INSERT INTO public.gf_verifier_read_tokens (
        tenant_id, verifier_id, project_id, token_hash,
        scoped_tables, expires_at
    ) VALUES (
        p_tenant_id, p_verifier_id, p_project_id, v_token_hash,
        p_scoped_tables, v_expires_at
    )
    RETURNING gf_verifier_read_tokens.token_id INTO v_token_id;

    -- ── Return token secret (shown once) ────────────────────────────────────
    -- RETURN v_token_secret via output parameters; plaintext is never stored.
    RETURN QUERY SELECT v_token_id, v_token_secret, v_expires_at;
END;
$$;


--
-- Name: link_evidence_to_record(uuid, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.link_evidence_to_record(p_tenant_id uuid, p_evidence_node_id uuid, p_target_evidence_node_id uuid, p_edge_type text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_edge_id          UUID;
    v_source_tenant    UUID;
    v_target_tenant    UUID;
    v_valid_edge_types TEXT[] := ARRAY[
        'SUPPORTS', 'REFUTES', 'DOCUMENTS', 'VALIDATES',
        'ATTESTS_TO', 'DERIVED_FROM', 'CORROBORATES'
    ];
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF013';
    END IF;
    IF p_evidence_node_id IS NULL THEN
        RAISE EXCEPTION 'p_evidence_node_id is required' USING ERRCODE = 'GF014';
    END IF;
    IF p_target_evidence_node_id IS NULL THEN
        RAISE EXCEPTION 'p_target_evidence_node_id is required' USING ERRCODE = 'GF015';
    END IF;
    IF p_edge_type IS NULL OR trim(p_edge_type) = '' THEN
        RAISE EXCEPTION 'p_edge_type is required' USING ERRCODE = 'GF016';
    END IF;

    -- ── Edge type validation ────────────────────────────────────────────────
    IF NOT (p_edge_type = ANY(v_valid_edge_types)) THEN
        RAISE EXCEPTION 'Invalid edge type: %', p_edge_type USING ERRCODE = 'GF017';
    END IF;

    -- ── Self-loop prevention ────────────────────────────────────────────────
    IF p_evidence_node_id = p_target_evidence_node_id THEN
        RAISE EXCEPTION 'Self-loop not allowed: source and target evidence_node_id are identical'
            USING ERRCODE = 'GF018';
    END IF;

    -- ── Cross-tenant linkage prevention ────────────────────────────────────
    SELECT en.tenant_id INTO v_source_tenant
      FROM public.evidence_nodes en
     WHERE en.evidence_node_id = p_evidence_node_id;

    IF v_source_tenant IS NULL THEN
        RAISE EXCEPTION 'source evidence node not found' USING ERRCODE = 'GF019';
    END IF;

    IF v_source_tenant != p_tenant_id THEN
        RAISE EXCEPTION 'cross-tenant linkage prevented: source tenant_id != p_tenant_id'
            USING ERRCODE = 'GF019';
    END IF;

    SELECT en.tenant_id INTO v_target_tenant
      FROM public.evidence_nodes en
     WHERE en.evidence_node_id = p_target_evidence_node_id;

    IF v_target_tenant IS NULL OR v_target_tenant != p_tenant_id THEN
        RAISE EXCEPTION 'cross-tenant linkage prevented: target tenant_id != p_tenant_id'
            USING ERRCODE = 'GF019';
    END IF;

    -- ── Insert evidence edge (append-only) ──────────────────────────────────
    INSERT INTO evidence_edges (
        tenant_id,
        source_node_id,
        target_node_id,
        edge_type
    ) VALUES (
        p_tenant_id,
        p_evidence_node_id,
        p_target_evidence_node_id,
        p_edge_type
    )
    RETURNING evidence_edge_id INTO v_edge_id;

    RETURN v_edge_id;
END;
$$;


--
-- Name: list_project_asset_batches(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_project_asset_batches(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(asset_batch_id uuid, batch_type text, quantity numeric, status text, total_retired numeric, remaining_quantity numeric, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
    END IF;

    RETURN QUERY
    SELECT ab.asset_batch_id, ab.batch_type, ab.quantity, ab.status,
           COALESCE(SUM(re.retired_quantity), 0) AS total_retired,
           ab.quantity - COALESCE(SUM(re.retired_quantity), 0) AS remaining_quantity,
           ab.created_at
      FROM public.asset_batches ab
      LEFT JOIN public.retirement_events re ON re.asset_batch_id = ab.asset_batch_id
     WHERE ab.project_id = p_project_id
       AND ab.tenant_id = p_tenant_id
     GROUP BY ab.asset_batch_id, ab.batch_type, ab.quantity, ab.status, ab.created_at
     ORDER BY ab.created_at DESC;
END;
$$;


--
-- Name: list_project_evidence(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_project_evidence(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(evidence_node_id uuid, node_type text, monitoring_record_id uuid, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT en.evidence_node_id,
           en.node_type,
           en.monitoring_record_id,
           en.created_at
      FROM public.evidence_nodes en
     WHERE en.tenant_id  = p_tenant_id
       AND en.project_id = p_project_id
     ORDER BY en.created_at ASC;
END;
$$;


--
-- Name: list_tenant_projects(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_tenant_projects(p_tenant_id uuid) RETURNS TABLE(project_id uuid, name text, status text, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT p.project_id, p.name, p.status, p.created_at
      FROM public.projects p
     WHERE p.tenant_id = p_tenant_id
     ORDER BY p.created_at DESC;
END;
$$;


--
-- Name: list_verifier_tokens(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.list_verifier_tokens(p_tenant_id uuid, p_verifier_id uuid) RETURNS TABLE(token_id uuid, project_id uuid, scoped_tables jsonb, issued_at timestamp with time zone, expires_at timestamp with time zone, revoked_at timestamp with time zone, is_valid boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_verifier_id IS NULL THEN
        RAISE EXCEPTION 'p_verifier_id is required' USING ERRCODE = 'GF003';
    END IF;

    RETURN QUERY
    SELECT t.token_id, t.project_id, t.scoped_tables,
           t.issued_at, t.expires_at, t.revoked_at,
           (t.revoked_at IS NULL AND t.expires_at > now()) AS is_valid
      FROM public.gf_verifier_read_tokens t
     WHERE t.tenant_id = p_tenant_id
       AND t.verifier_id = p_verifier_id
     ORDER BY t.created_at DESC;
END;
$$;


--
-- Name: mark_anchor_sync_anchored(uuid, uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mark_anchor_sync_anchored(p_operation_id uuid, p_lease_token uuid, p_worker_id text, p_anchor_ref text, p_anchor_type text DEFAULT 'HYBRID_SYNC'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_op public.anchor_sync_operations%ROWTYPE;
BEGIN
  SELECT * INTO v_op
  FROM public.anchor_sync_operations
  WHERE operation_id = p_operation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'anchor operation not found' USING ERRCODE = 'P7210';
  END IF;

  IF v_op.claimed_by IS DISTINCT FROM p_worker_id THEN
    RAISE EXCEPTION 'anchor operation worker mismatch' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.lease_token IS DISTINCT FROM p_lease_token OR v_op.lease_expires_at IS NULL OR v_op.lease_expires_at <= clock_timestamp() THEN
    RAISE EXCEPTION 'anchor operation lease invalid' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.state NOT IN ('ANCHORING', 'ANCHORED') THEN
    RAISE EXCEPTION 'anchor operation cannot be anchored from state %', v_op.state USING ERRCODE = 'P7211';
  END IF;

  IF NULLIF(BTRIM(p_anchor_ref), '') IS NULL THEN
    RAISE EXCEPTION 'anchor reference is required' USING ERRCODE = 'P7211';
  END IF;

  UPDATE public.anchor_sync_operations
  SET state = 'ANCHORED',
      anchor_ref = p_anchor_ref,
      anchor_type = COALESCE(NULLIF(BTRIM(p_anchor_type), ''), 'HYBRID_SYNC')
  WHERE operation_id = v_op.operation_id;
END;
$$;


--
-- Name: mark_instruction_awaiting_execution(text, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mark_instruction_awaiting_execution(p_instruction_id text, p_program_id uuid, p_policy_version_id text, p_actor text DEFAULT 'system'::text) RETURNS public.inquiry_state_enum
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
  INSERT INTO public.inquiry_state_machine(
    instruction_id, inquiry_state, attempts, max_attempts, policy_version_id
  ) VALUES (
    p_instruction_id, 'AWAITING_EXECUTION', 0, 1, p_policy_version_id
  )
  ON CONFLICT (instruction_id) DO UPDATE
    SET inquiry_state = 'AWAITING_EXECUTION',
        policy_version_id = EXCLUDED.policy_version_id;

  RETURN 'AWAITING_EXECUTION';
END;
$$;


--
-- Name: migrate_person_to_program(uuid, uuid, uuid, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.migrate_person_to_program(p_tenant_id uuid, p_person_id uuid, p_from_program_id uuid, p_to_program_id uuid, p_new_entity_id uuid, p_reason text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: migrate_person_to_program(uuid, uuid, uuid, uuid, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.migrate_person_to_program(p_tenant_id uuid, p_person_id uuid, p_from_program_id uuid, p_to_program_id uuid, p_migrated_by text DEFAULT CURRENT_USER, p_reason text DEFAULT 'program_migration'::text, p_formula_key text DEFAULT 'TIER1_DETERMINISTIC_DEFAULT'::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: outbox_retry_ceiling(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.outbox_retry_ceiling() RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COALESCE(
    NULLIF(current_setting('symphony.outbox_retry_ceiling', true), '')::int,
    20
  );
$$;


--
-- Name: quarantine_malformed_response(text, text, public.quarantine_classification_enum, text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.quarantine_malformed_response(p_adapter_id text, p_rail_id text, p_classification public.quarantine_classification_enum, p_payload text, p_truncate_kb integer, p_policy_version_id text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: query_asset_batch(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_asset_batch(p_tenant_id uuid, p_asset_batch_id uuid) RETURNS TABLE(asset_batch_id uuid, project_id uuid, batch_type text, quantity numeric, status text, total_retired numeric, remaining_quantity numeric, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_asset_batch_id IS NULL THEN
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF013';
    END IF;

    RETURN QUERY
    SELECT ab.asset_batch_id, ab.project_id, ab.batch_type,
           ab.quantity, ab.status,
           COALESCE(SUM(re.retired_quantity), 0) AS total_retired,
           ab.quantity - COALESCE(SUM(re.retired_quantity), 0) AS remaining_quantity,
           ab.created_at
      FROM public.asset_batches ab
      LEFT JOIN public.retirement_events re ON re.asset_batch_id = ab.asset_batch_id
     WHERE ab.asset_batch_id = p_asset_batch_id
       AND ab.tenant_id = p_tenant_id
     GROUP BY ab.asset_batch_id, ab.project_id, ab.batch_type,
              ab.quantity, ab.status, ab.created_at;
END;
$$;


--
-- Name: query_authority_decisions(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_authority_decisions(p_jurisdiction_code text, p_subject_id uuid DEFAULT NULL::uuid) RETURNS TABLE(authority_decision_id uuid, regulatory_authority_id uuid, decision_type text, decision_outcome text, subject_type text, subject_id text, from_status text, to_status text, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT ad.authority_decision_id,
           ad.regulatory_authority_id,
           ad.decision_type,
           (ad.decision_payload_json->>'decision_outcome')::TEXT,
           (ad.decision_payload_json->>'subject_type')::TEXT,
           (ad.decision_payload_json->>'subject_id')::TEXT,
           (ad.decision_payload_json->>'from_status')::TEXT,
           (ad.decision_payload_json->>'to_status')::TEXT,
           ad.created_at
      FROM public.authority_decisions ad
     WHERE ad.jurisdiction_code = p_jurisdiction_code
       AND (p_subject_id IS NULL
            OR (ad.decision_payload_json->>'subject_id')::UUID = p_subject_id)
     ORDER BY ad.created_at ASC;
END;
$$;


--
-- Name: query_evidence_lineage(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_evidence_lineage(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(evidence_node_id uuid, node_type text, monitoring_record_id uuid, evidence_edge_id uuid, source_node_id uuid, target_node_id uuid, edge_type text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT en.evidence_node_id,
           en.node_type,
           en.monitoring_record_id,
           ee.evidence_edge_id,
           ee.source_node_id,
           ee.target_node_id,
           ee.edge_type
      FROM public.evidence_nodes en
      LEFT JOIN public.evidence_edges ee
             ON ee.source_node_id = en.evidence_node_id
            AND ee.tenant_id      = en.tenant_id
     WHERE en.tenant_id  = p_tenant_id
       AND en.project_id = p_project_id
     ORDER BY en.created_at ASC;
END;
$$;


--
-- Name: query_monitoring_records(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_monitoring_records(p_tenant_id uuid, p_project_id uuid, p_record_type text DEFAULT NULL::text) RETURNS TABLE(monitoring_record_id uuid, project_id uuid, record_type text, record_payload_json jsonb, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF005';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF013';
    END IF;

    RETURN QUERY
    SELECT mr.monitoring_record_id,
           mr.project_id,
           mr.record_type,
           mr.record_payload_json,
           mr.created_at
      FROM public.monitoring_records mr
     WHERE mr.tenant_id  = p_tenant_id
       AND mr.project_id = p_project_id
       AND (p_record_type IS NULL OR mr.record_type = p_record_type)
     ORDER BY mr.created_at ASC;
END;
$$;


--
-- Name: query_project_details(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.query_project_details(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(project_id uuid, name text, status text, created_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    RETURN QUERY
    SELECT p.project_id, p.name, p.status, p.created_at
      FROM public.projects p
     WHERE p.project_id = p_project_id
       AND p.tenant_id  = p_tenant_id;
END;
$$;


--
-- Name: record_asset_lifecycle_event(uuid, uuid, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_asset_lifecycle_event(p_tenant_id uuid, p_asset_batch_id uuid, p_event_type text, p_event_payload jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_lifecycle_event_id UUID;
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_asset_batch_id IS NULL THEN
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF013';
    END IF;
    IF p_event_type IS NULL THEN
        RAISE EXCEPTION 'p_event_type is required' USING ERRCODE = 'GF018';
    END IF;

    INSERT INTO asset_lifecycle_events (
        tenant_id, asset_batch_id, event_type, event_payload_json
    ) VALUES (
        p_tenant_id, p_asset_batch_id, p_event_type, p_event_payload
    )
    RETURNING lifecycle_event_id INTO v_lifecycle_event_id;

    RETURN v_lifecycle_event_id;
END;
$$;


--
-- Name: record_authority_decision(uuid, text, text, text, text, uuid, text, text, uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_authority_decision(p_regulatory_authority_id uuid, p_jurisdiction_code text, p_decision_type text, p_decision_outcome text, p_subject_type text, p_subject_id uuid, p_from_status text, p_to_status text, p_interpretation_pack_id uuid DEFAULT NULL::uuid, p_decision_payload_json jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_decision_id         UUID;
    v_authority_jcode     TEXT;
    v_pack_jcode          TEXT;
    v_unsatisfied_checkpoints INT;
    v_valid_subject_types TEXT[] := ARRAY['PROJECT', 'ASSET_BATCH', 'MONITORING_RECORD', 'EVIDENCE_NODE'];
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_regulatory_authority_id IS NULL THEN
        RAISE EXCEPTION 'p_regulatory_authority_id is required' USING ERRCODE = 'GF005';
    END IF;
    IF p_jurisdiction_code IS NULL OR trim(p_jurisdiction_code) = '' THEN
        RAISE EXCEPTION 'p_jurisdiction_code is required' USING ERRCODE = 'GF006';
    END IF;
    IF p_decision_type IS NULL OR trim(p_decision_type) = '' THEN
        RAISE EXCEPTION 'p_decision_type is required' USING ERRCODE = 'GF007';
    END IF;
    IF p_decision_outcome IS NULL OR trim(p_decision_outcome) = '' THEN
        RAISE EXCEPTION 'p_decision_outcome is required' USING ERRCODE = 'GF008';
    END IF;
    IF p_subject_type IS NULL OR trim(p_subject_type) = '' THEN
        RAISE EXCEPTION 'p_subject_type is required' USING ERRCODE = 'GF009';
    END IF;
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF010';
    END IF;
    IF p_from_status IS NULL THEN
        RAISE EXCEPTION 'p_from_status is required' USING ERRCODE = 'GF011';
    END IF;
    IF p_to_status IS NULL THEN
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF012';
    END IF;

    -- ── Subject type validation ─────────────────────────────────────────────
    IF NOT (p_subject_type = ANY(v_valid_subject_types)) THEN
        RAISE EXCEPTION 'Invalid subject type: %', p_subject_type USING ERRCODE = 'GF013';
    END IF;

    -- ── Regulatory authority validation ─────────────────────────────────────
    -- Confirms the regulatory_authorities entry matches the jurisdiction_code
    SELECT ra.jurisdiction_code INTO v_authority_jcode
      FROM public.regulatory_authorities ra
     WHERE ra.regulatory_authority_id = p_regulatory_authority_id;

    IF v_authority_jcode IS NULL THEN
        RAISE EXCEPTION 'regulatory authority not found' USING ERRCODE = 'GF014';
    END IF;

    IF v_authority_jcode != p_jurisdiction_code THEN
        RAISE EXCEPTION 'jurisdiction_code does not match regulatory_authorities entry'
            USING ERRCODE = 'GF014';
    END IF;

    -- ── Interpretation pack validation (INV-165: mandatory for governed decisions) ──
    -- interpretation_pack_id IS NULL is rejected; every authority decision must
    -- be anchored to a jurisdiction interpretation pack (P0001 = raise_exception).
    IF p_interpretation_pack_id IS NULL THEN
        RAISE EXCEPTION 'interpretation_pack_id is required for governed regulatory decisions (INV-165)'
            USING ERRCODE = 'P0001';
    ELSE
        SELECT ip.jurisdiction_code INTO v_pack_jcode
          FROM public.interpretation_packs ip
         WHERE ip.interpretation_pack_id = p_interpretation_pack_id;

        IF v_pack_jcode IS NULL OR v_pack_jcode != p_jurisdiction_code THEN
            RAISE EXCEPTION 'interpretation_pack_id not found or jurisdiction mismatch'
                USING ERRCODE = 'GF015';
        END IF;
    END IF;

    -- ── Lifecycle checkpoint rules validation ───────────────────────────────
    -- Count REQUIRED checkpoints in lifecycle_checkpoint_rules that are unsatisfied.
    -- REQUIRED checkpoints block the transition; CONDITIONALLY_REQUIRED become
    -- PENDING_CLARIFICATION (provisional pass) and resolve to CONDITIONALLY_SATISFIED.
    SELECT COUNT(*)
      INTO v_unsatisfied_checkpoints
      FROM public.lifecycle_checkpoint_rules lcr
     WHERE lcr.jurisdiction_code = p_jurisdiction_code
       AND lcr.rule_type = 'REQUIRED';

    -- Record authority decision; extra lifecycle fields stored in decision_payload_json
    INSERT INTO authority_decisions (
        jurisdiction_code,
        regulatory_authority_id,
        decision_type,
        decision_payload_json
    ) VALUES (
        p_jurisdiction_code,
        p_regulatory_authority_id,
        p_decision_type,
        jsonb_build_object(
            'decision_outcome', p_decision_outcome,
            'subject_type',     p_subject_type,
            'subject_id',       p_subject_id,
            'from_status',      p_from_status,
            'to_status',        p_to_status
        ) || p_decision_payload_json
    )
    RETURNING authority_decision_id INTO v_decision_id;

    RETURN v_decision_id;
END;
$$;


--
-- Name: record_late_callback(text, jsonb, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_late_callback(p_instruction_id text, p_payload jsonb, p_state_at_arrival text, p_fingerprint text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: record_mmo_reality_control(text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_mmo_reality_control(p_instruction_id text, p_scenario_type text, p_fallback_posture text, p_policy_version_id text, p_behavior_profile text, p_evidence_artifact_type text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: record_monitoring_record(uuid, uuid, text, jsonb, uuid, timestamp with time zone, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_monitoring_record(p_tenant_id uuid, p_project_id uuid, p_record_type text, p_record_payload_json jsonb, p_methodology_version_id uuid DEFAULT NULL::uuid, p_event_timestamp timestamp with time zone DEFAULT NULL::timestamp with time zone, p_payload_schema_reference_id uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_monitoring_record_id UUID;
    v_project_status       TEXT;
    v_payload_valid        BOOLEAN;
    v_mv_adapter_id        UUID;
BEGIN
    -- ── Required input validation ───────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_record_type IS NULL OR trim(p_record_type) = '' THEN
        RAISE EXCEPTION 'p_record_type is required' USING ERRCODE = 'GF004';
    END IF;
    IF p_record_payload_json IS NULL THEN
        RAISE EXCEPTION 'p_record_payload_json is required' USING ERRCODE = 'GF006';
    END IF;

    -- ── Optional parameter validation ──────────────────────────────────────
    -- event_timestamp: default to now() if not supplied
    IF p_event_timestamp IS NULL THEN
        p_event_timestamp := now();
    END IF;

    -- payload_schema_reference_id: optional, validated if supplied
    IF p_payload_schema_reference_id IS NULL THEN
        NULL; -- no schema reference check required
    END IF;

    -- methodology_version_id: if supplied, confirm it matches the project context
    IF p_methodology_version_id IS NULL THEN
        NULL; -- methodology version check skipped for internal registration calls
    ELSE
        -- Validate that the methodology_version_id matches an active adapter context
        SELECT mv.adapter_registration_id
          INTO v_mv_adapter_id
          FROM public.methodology_versions mv
         WHERE mv.methodology_version_id = p_methodology_version_id
           AND mv.tenant_id = p_tenant_id
           AND mv.status = 'ACTIVE'
         LIMIT 1;

        IF v_mv_adapter_id IS NULL THEN
            RAISE EXCEPTION 'methodology_version_id does not match an active version'
                USING ERRCODE = 'GF003';
        END IF;
    END IF;

    -- ── Project validation ───────────────────────────────────────────────────
    -- Confirm project exists for this tenant and is in ACTIVE status
    SELECT p.status
      INTO v_project_status
      FROM public.projects p
     WHERE p.project_id = p_project_id
       AND p.tenant_id  = p_tenant_id;

    IF v_project_status IS NULL THEN
        RAISE EXCEPTION 'project not found for tenant' USING ERRCODE = 'GF008';
    END IF;

    IF v_project_status != 'ACTIVE' THEN
        RAISE EXCEPTION 'project must have status ACTIVE to accept monitoring records; current=%',
                         v_project_status
            USING ERRCODE = 'GF009';
    END IF;

    -- Confirm project has at least one asset_batches entry (asset tracking context)
    IF NOT EXISTS (
        SELECT 1
          FROM public.asset_batches ab
         WHERE ab.project_id = p_project_id
           AND ab.tenant_id  = p_tenant_id
    ) THEN
        RAISE EXCEPTION 'no asset_batches context found for project; asset tracking must be initialised first'
            USING ERRCODE = 'GF010';
    END IF;

    -- ── Payload validation ───────────────────────────────────────────────────
    -- Validate payload is a JSON object; validate schema reference if supplied
    v_payload_valid := public.validate_payload_against_schema(
        p_record_payload_json,
        p_payload_schema_reference_id
    );

    IF NOT v_payload_valid THEN
        IF jsonb_typeof(p_record_payload_json) != 'object' THEN
            RAISE EXCEPTION 'record_payload_json must be a JSON object'
                USING ERRCODE = 'GF011';
        ELSE
            RAISE EXCEPTION 'payload_schema_reference_id not found in schema_registry'
                USING ERRCODE = 'GF012';
        END IF;
    END IF;

    -- ── Insert monitoring record ─────────────────────────────────────────────
    INSERT INTO monitoring_records (
        tenant_id,
        project_id,
        record_type,
        record_payload_json
    ) VALUES (
        p_tenant_id,
        p_project_id,
        p_record_type,
        p_record_payload_json
    )
    RETURNING monitoring_record_id INTO v_monitoring_record_id;

    RETURN v_monitoring_record_id;
END;
$$;


--
-- Name: register_project(uuid, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.register_project(p_tenant_id uuid, p_project_name text, p_jurisdiction_code text, p_methodology_version_id uuid) RETURNS TABLE(project_id uuid, status text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_project_id            UUID;
    v_adapter_registration_id UUID;
BEGIN
    -- Input validation
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_project_name IS NULL OR trim(p_project_name) = '' THEN
        RAISE EXCEPTION 'p_project_name is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_jurisdiction_code IS NULL OR trim(p_jurisdiction_code) = '' THEN
        RAISE EXCEPTION 'p_jurisdiction_code is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_methodology_version_id IS NULL THEN
        RAISE EXCEPTION 'p_methodology_version_id is required' USING ERRCODE = 'GF004';
    END IF;

    -- Validate methodology_version is active and its adapter is active
    SELECT mv.adapter_registration_id
      INTO v_adapter_registration_id
      FROM public.methodology_versions mv
      JOIN public.adapter_registrations ar
        ON ar.adapter_registration_id = mv.adapter_registration_id
     WHERE mv.methodology_version_id = p_methodology_version_id
       AND mv.tenant_id = p_tenant_id
       AND mv.status = 'ACTIVE'
       AND ar.is_active = true
     LIMIT 1;

    IF v_adapter_registration_id IS NULL THEN
        RAISE EXCEPTION 'methodology_version not found, not active, or adapter not active'
            USING ERRCODE = 'GF005';
    END IF;

    -- Insert project in DRAFT status
    INSERT INTO public.projects (tenant_id, name, status)
    VALUES (p_tenant_id, trim(p_project_name), 'DRAFT')
    RETURNING public.projects.project_id INTO v_project_id;

    -- Record PROJECT_REGISTRATION monitoring event (defined in 0108)
    PERFORM public.record_monitoring_record(
        p_tenant_id,
        v_project_id,
        'PROJECT_REGISTRATION',
        jsonb_build_object(
            'methodology_version_id', p_methodology_version_id,
            'adapter_registration_id', v_adapter_registration_id,
            'jurisdiction_code', p_jurisdiction_code
        )
    );

    RETURN QUERY SELECT v_project_id, 'DRAFT'::TEXT;
END;
$$;


--
-- Name: release_escrow(uuid, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.release_escrow(p_escrow_id uuid, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_event_id UUID;
BEGIN
  SELECT t.event_id
  INTO v_event_id
  FROM public.transition_escrow_state(
    p_escrow_id => p_escrow_id,
    p_to_state => 'RELEASED',
    p_actor_id => p_actor_id,
    p_reason => p_reason,
    p_metadata => COALESCE(p_metadata, '{}'::jsonb),
    p_now => NOW()
  ) AS t;

  RETURN v_event_id;
END;
$$;


--
-- Name: repair_expired_anchor_sync_leases(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.repair_expired_anchor_sync_leases(p_worker_id text DEFAULT 'anchor_repair'::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  UPDATE public.anchor_sync_operations
  SET state = CASE WHEN state = 'ANCHORED' THEN 'ANCHORED' ELSE 'PENDING' END,
      claimed_by = NULL,
      lease_token = NULL,
      lease_expires_at = NULL,
      last_error = COALESCE(last_error, 'LEASE_EXPIRED_REPAIRED')
  WHERE state IN ('ANCHORING', 'ANCHORED')
    AND lease_expires_at IS NOT NULL
    AND lease_expires_at <= clock_timestamp();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;


--
-- Name: repair_expired_leases(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.repair_expired_leases(p_batch_size integer, p_worker_id text) RETURNS TABLE(outbox_id uuid, attempt_no integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
  DECLARE
    v_record RECORD;
    v_next_attempt_no INT;
    v_retry_ceiling INT;
  BEGIN
    v_retry_ceiling := public.outbox_retry_ceiling();

    FOR v_record IN
      SELECT p.outbox_id, p.instruction_id, p.participant_id, p.sequence_id,
             p.idempotency_key, p.rail_type, p.payload
      FROM payment_outbox_pending p
      WHERE p.claimed_by IS NOT NULL AND p.lease_token IS NOT NULL AND p.lease_expires_at <= NOW()
      ORDER BY p.lease_expires_at ASC, p.created_at ASC LIMIT p_batch_size FOR UPDATE SKIP LOCKED
    LOOP
      SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
      FROM payment_outbox_attempts a WHERE a.outbox_id = v_record.outbox_id;

      IF v_next_attempt_no >= v_retry_ceiling THEN
        INSERT INTO payment_outbox_attempts (
          outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
          attempt_no, state, claimed_at, completed_at, error_code, error_message, worker_id
        ) VALUES (
          v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
          v_record.idempotency_key, v_record.rail_type, v_record.payload,
          v_next_attempt_no, 'FAILED', NOW(), NOW(),
          'RETRY_CEILING_EXCEEDED', 'expired lease repair hit retry ceiling', p_worker_id
        );

        DELETE FROM payment_outbox_pending WHERE outbox_id = v_record.outbox_id;
      ELSE
        INSERT INTO payment_outbox_attempts (
          outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
          attempt_no, state, claimed_at, completed_at, worker_id
        ) VALUES (
          v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
          v_record.idempotency_key, v_record.rail_type, v_record.payload,
          v_next_attempt_no, 'ZOMBIE_REQUEUE', NOW(), NOW(), p_worker_id
        );

        UPDATE payment_outbox_pending SET
          attempt_count = GREATEST(attempt_count, v_next_attempt_no),
          next_attempt_at = NOW() + INTERVAL '1 second',
          claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
        WHERE payment_outbox_pending.outbox_id = v_record.outbox_id;
      END IF;

      outbox_id := v_record.outbox_id;
      attempt_no := v_next_attempt_no;
      RETURN NEXT;
    END LOOP;
    RETURN;
  END;
$$;


--
-- Name: request_pii_purge(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.request_pii_purge(p_subject_token text, p_requested_by text, p_request_reason text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_request_id UUID;
BEGIN
  INSERT INTO public.pii_purge_requests(
    subject_token,
    requested_by,
    request_reason
  ) VALUES (
    p_subject_token,
    p_requested_by,
    p_request_reason
  )
  RETURNING purge_request_id INTO v_request_id;

  INSERT INTO public.pii_purge_events(
    purge_request_id,
    event_type,
    rows_affected,
    metadata
  ) VALUES (
    v_request_id,
    'REQUESTED',
    0,
    jsonb_build_object('subject_token', p_subject_token)
  );

  RETURN v_request_id;
END;
$$;


--
-- Name: resolve_missing_acknowledgement_interrupt(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resolve_missing_acknowledgement_interrupt(p_instruction_id text, p_action text, p_actor text, p_reason text DEFAULT NULL::text) RETURNS public.inquiry_state_enum
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_action TEXT := UPPER(BTRIM(COALESCE(p_action, '')));
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
  v_program_id UUID;
  v_state public.inquiry_state_enum;
  v_queue_status TEXT;
BEGIN
  IF v_action NOT IN ('ACKNOWLEDGE', 'RESUME', 'RESET') THEN
    RAISE EXCEPTION 'invalid_interrupt_action:%', p_action USING ERRCODE = 'P7300';
  END IF;

  SELECT program_id INTO v_program_id
  FROM public.supervisor_approval_queue
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_program_id IS NULL THEN
    RAISE EXCEPTION 'supervisor_interrupt_not_found' USING ERRCODE = 'P7300';
  END IF;

  SELECT inquiry_state INTO v_state
  FROM public.inquiry_state_machine
  WHERE instruction_id = p_instruction_id
  FOR UPDATE;

  IF v_state IS NULL OR v_state NOT IN ('ESCALATED', 'AWAITING_EXECUTION') THEN
    RAISE EXCEPTION 'illegal_interrupt_resolution_state:%', v_state USING ERRCODE = 'P7300';
  END IF;

  IF v_action = 'ACKNOWLEDGE' THEN
    UPDATE public.inquiry_state_machine
    SET inquiry_state = 'ACKNOWLEDGED'
    WHERE instruction_id = p_instruction_id;

    UPDATE public.supervisor_approval_queue
    SET status = 'APPROVED',
        approved_at = NOW(),
        approved_by = v_actor,
        decided_at = NOW(),
        decided_by = v_actor,
        decision_reason = COALESCE(p_reason, 'acknowledged')
    WHERE instruction_id = p_instruction_id;

    v_queue_status := 'APPROVED';
    v_state := 'ACKNOWLEDGED';
  ELSIF v_action = 'RESUME' THEN
    UPDATE public.inquiry_state_machine
    SET inquiry_state = 'AWAITING_EXECUTION'
    WHERE instruction_id = p_instruction_id;

    UPDATE public.supervisor_approval_queue
    SET status = 'APPROVED',
        resumed_at = NOW(),
        approved_at = NOW(),
        approved_by = v_actor,
        decided_at = NOW(),
        decided_by = v_actor,
        decision_reason = COALESCE(p_reason, 'resume_ack_wait')
    WHERE instruction_id = p_instruction_id;

    v_queue_status := 'APPROVED';
    v_state := 'AWAITING_EXECUTION';
  ELSE
    UPDATE public.inquiry_state_machine
    SET inquiry_state = 'AWAITING_EXECUTION'
    WHERE instruction_id = p_instruction_id;

    UPDATE public.supervisor_approval_queue
    SET status = 'RESET',
        reset_at = NOW(),
        decided_at = NOW(),
        decided_by = v_actor,
        decision_reason = COALESCE(p_reason, 'reset_to_ack_wait')
    WHERE instruction_id = p_instruction_id;

    v_queue_status := 'RESET';
    v_state := 'AWAITING_EXECUTION';
  END IF;

  INSERT INTO public.supervisor_interrupt_audit_events(
    instruction_id, program_id, action, queue_status, actor, reason
  ) VALUES (
    p_instruction_id, v_program_id,
    CASE v_action
      WHEN 'ACKNOWLEDGE' THEN 'ACKNOWLEDGED'
      WHEN 'RESUME' THEN 'RESUMED'
      ELSE 'RESET'
    END,
    v_queue_status,
    v_actor,
    p_reason
  );

  RETURN v_state;
END;
$$;


--
-- Name: resolve_reference_strategy(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resolve_reference_strategy(p_rail_id text) RETURNS TABLE(strategy_type public.reference_strategy_type_enum, rail_id text, max_length integer, nonce_retry_limit integer, collision_action text, policy_version_id text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_policy record;
BEGIN
  SELECT policy_version_id, policy_json INTO v_policy
  FROM public.reference_strategy_policy_versions
  WHERE version_status = 'ACTIVE'
  ORDER BY activated_at DESC
  LIMIT 1;

  IF v_policy.policy_version_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P7802', MESSAGE='REFERENCE_STRATEGY_POLICY_NOT_FOUND';
  END IF;

  RETURN QUERY
  SELECT
    (s->>'strategy_type')::public.reference_strategy_type_enum,
    s->>'rail_id',
    (s->>'max_length')::integer,
    (s->>'nonce_retry_limit')::integer,
    s->>'collision_action',
    v_policy.policy_version_id
  FROM jsonb_array_elements(v_policy.policy_json->'strategies') AS s
  WHERE s->>'rail_id' IN (p_rail_id, '*')
  ORDER BY CASE WHEN s->>'rail_id' = p_rail_id THEN 0 ELSE 1 END
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P7802', MESSAGE='REFERENCE_STRATEGY_POLICY_NOT_FOUND';
  END IF;
END;
$$;


--
-- Name: retire_asset_batch(uuid, uuid, text, uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.retire_asset_batch(p_tenant_id uuid, p_asset_batch_id uuid, p_retirement_reason text, p_interpretation_pack_id uuid, p_quantity numeric DEFAULT NULL::numeric) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_retirement_event_id UUID;
    v_batch_status        TEXT;
    v_batch_quantity      NUMERIC;
    v_total_retired       NUMERIC;
    v_remaining_quantity  NUMERIC;
    v_retire_qty          NUMERIC;
BEGIN
    -- ── Input validation ────────────────────────────────────────────────────
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
    END IF;
    IF p_asset_batch_id IS NULL THEN
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF013';
    END IF;
    IF p_retirement_reason IS NULL THEN
        RAISE EXCEPTION 'p_retirement_reason is required' USING ERRCODE = 'GF014';
    END IF;

    -- ── INV-165: interpretation_pack_id enforcement ─────────────────────────
    IF p_interpretation_pack_id IS NULL THEN
        RAISE EXCEPTION 'interpretation_pack_id is required (INV-165)'
            USING ERRCODE = 'P0001';
    END IF;

    -- ── Asset ISSUED status validation ──────────────────────────────────────
    SELECT ab.status, ab.quantity
      INTO v_batch_status, v_batch_quantity
      FROM public.asset_batches ab
     WHERE ab.asset_batch_id = p_asset_batch_id
       AND ab.tenant_id = p_tenant_id;

    IF v_batch_status IS NULL THEN
        RAISE EXCEPTION 'Asset batch not found' USING ERRCODE = 'GF015';
    END IF;
    IF v_batch_status != 'ISSUED' THEN
        RAISE EXCEPTION 'Asset batch must be ISSUED for retirement, current status: %', v_batch_status
            USING ERRCODE = 'GF016';
    END IF;

    -- ── Quantity guard: retirement must not exceed remaining ─────────────────
    SELECT COALESCE(SUM(re.retired_quantity), 0)
      INTO v_total_retired
      FROM public.retirement_events re
     WHERE re.asset_batch_id = p_asset_batch_id;

    v_remaining_quantity := v_batch_quantity - v_total_retired;

    v_retire_qty := COALESCE(p_quantity, v_remaining_quantity);

    IF v_retire_qty <= 0 THEN
        RAISE EXCEPTION 'p_quantity must be positive' USING ERRCODE = 'GF006';
    END IF;

    IF v_retire_qty > v_remaining_quantity THEN
        RAISE EXCEPTION 'retired_quantity exceeds remaining: requested=%, remaining=%',
            v_retire_qty, v_remaining_quantity
            USING ERRCODE = 'GF017';
    END IF;

    -- ── Append-only retirement event (irrevocable) ──────────────────────────
    INSERT INTO retirement_events (
        tenant_id, asset_batch_id, retired_quantity, retirement_reason
    ) VALUES (
        p_tenant_id, p_asset_batch_id, v_retire_qty, p_retirement_reason
    )
    RETURNING retirement_event_id INTO v_retirement_event_id;

    -- ── If fully retired, update batch status ───────────────────────────────
    IF (v_total_retired + v_retire_qty) >= v_batch_quantity THEN
        UPDATE public.asset_batches
           SET status = 'RETIRED'
         WHERE asset_batch_id = p_asset_batch_id
           AND tenant_id = p_tenant_id;
    END IF;

    -- ── Record lifecycle event ──────────────────────────────────────────────
    INSERT INTO asset_lifecycle_events (
        tenant_id, asset_batch_id, event_type,
        event_payload_json
    ) VALUES (
        p_tenant_id, p_asset_batch_id, 'RETIREMENT',
        jsonb_build_object(
            'from_status', 'ISSUED',
            'to_status', CASE WHEN (v_total_retired + v_retire_qty) >= v_batch_quantity
                              THEN 'RETIRED' ELSE 'ISSUED' END,
            'retired_quantity', v_retire_qty,
            'remaining_quantity', v_remaining_quantity - v_retire_qty,
            'retirement_reason', p_retirement_reason,
            'interpretation_pack_id', p_interpretation_pack_id
        )
    );

    RETURN v_retirement_event_id;
END;
$$;


--
-- Name: revoke_verifier_read_token(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.revoke_verifier_read_token(p_tenant_id uuid, p_token_id uuid, p_reason text DEFAULT 'manual_revocation'::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_token_id IS NULL THEN
        RAISE EXCEPTION 'p_token_id is required' USING ERRCODE = 'GF003';
    END IF;

    UPDATE public.gf_verifier_read_tokens
       SET revoked_at = now(),
           revocation_reason = p_reason
     WHERE token_id = p_token_id
       AND tenant_id = p_tenant_id
       AND revoked_at IS NULL;
END;
$$;


--
-- Name: set_correlation_id_if_null(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_correlation_id_if_null() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.correlation_id IS NULL THEN
    NEW.correlation_id := public.uuid_v7_or_random();
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: set_external_proofs_attribution(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_external_proofs_attribution() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  derived_tenant_id UUID;
  derived_billable_client_id UUID;
BEGIN
  SELECT ia.tenant_id
    INTO derived_tenant_id
    FROM public.ingress_attestations ia
   WHERE ia.attestation_id = NEW.attestation_id;

  IF derived_tenant_id IS NULL THEN
    RAISE EXCEPTION 'external_proofs requires tenant attribution via ingress_attestations'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT t.billable_client_id
    INTO derived_billable_client_id
    FROM public.tenants t
   WHERE t.tenant_id = derived_tenant_id;

  IF derived_billable_client_id IS NULL THEN
    RAISE EXCEPTION 'external_proofs requires billable_client_id attribution via tenant'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id := derived_tenant_id;
  ELSIF NEW.tenant_id <> derived_tenant_id THEN
    RAISE EXCEPTION 'external_proofs tenant_id does not match derived tenant_id'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.billable_client_id IS NULL THEN
    NEW.billable_client_id := derived_billable_client_id;
  ELSIF NEW.billable_client_id <> derived_billable_client_id THEN
    RAISE EXCEPTION 'external_proofs billable_client_id does not match derived billable_client_id'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: sign_digest_hsm_enforced(text, text, public.key_class_enum, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sign_digest_hsm_enforced(p_caller_id text, p_key_id text, p_key_class public.key_class_enum, p_artifact_type text, p_digest_hash text, p_signing_path text DEFAULT 'HSM'::text, p_assurance_tier text DEFAULT 'HSM_BACKED'::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: store_effect_seal(text, jsonb, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.store_effect_seal(p_instruction_id text, p_payload jsonb, p_canonicalization_version text, p_policy_version_id text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: submit_for_supervisor_approval(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submit_for_supervisor_approval(p_instruction_id text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_program_id UUID;
BEGIN
  SELECT program_id
  INTO v_program_id
  FROM public.programs
  ORDER BY created_at ASC
  LIMIT 1;

  IF v_program_id IS NULL THEN
    RAISE EXCEPTION 'no program available for supervisor approval submission';
  END IF;

  PERFORM public.submit_for_supervisor_approval(p_instruction_id, v_program_id, 30, NULL, 'system');
END;
$$;


--
-- Name: submit_for_supervisor_approval(text, uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submit_for_supervisor_approval(p_instruction_id text, p_program_id uuid, p_timeout_minutes integer DEFAULT 30) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_timeout INTEGER := COALESCE(p_timeout_minutes, 30);
BEGIN
  IF v_timeout <= 0 THEN
    RAISE EXCEPTION 'approval timeout must be positive';
  END IF;

  INSERT INTO public.supervisor_approval_queue(
    instruction_id, program_id, status, held_at, timeout_at, decided_at, decided_by, decision_reason
  ) VALUES (
    p_instruction_id, p_program_id, 'PENDING_SUPERVISOR_APPROVAL', NOW(), NOW() + make_interval(mins => v_timeout), NULL, NULL, NULL
  )
  ON CONFLICT (instruction_id) DO UPDATE
    SET program_id = EXCLUDED.program_id,
        status = 'PENDING_SUPERVISOR_APPROVAL',
        held_at = NOW(),
        timeout_at = NOW() + make_interval(mins => v_timeout),
        decided_at = NULL,
        decided_by = NULL,
        decision_reason = NULL;
END;
$$;


--
-- Name: submit_for_supervisor_approval(text, uuid, integer, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submit_for_supervisor_approval(p_instruction_id text, p_program_id uuid, p_timeout_minutes integer DEFAULT 30, p_held_reason text DEFAULT NULL::text, p_submitted_by text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_timeout INTEGER := COALESCE(p_timeout_minutes, 30);
  v_submitted_by TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_submitted_by, '')), ''), 'system');
BEGIN
  IF v_timeout <= 0 THEN
    RAISE EXCEPTION 'approval timeout must be positive';
  END IF;

  INSERT INTO public.supervisor_approval_queue(
    instruction_id, program_id, status, held_at, held_reason, timeout_at, submitted_by,
    decided_at, decided_by, decision_reason, approved_by, approved_at
  ) VALUES (
    p_instruction_id,
    p_program_id,
    'PENDING_SUPERVISOR_APPROVAL',
    NOW(),
    p_held_reason,
    NOW() + make_interval(mins => v_timeout),
    v_submitted_by,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  )
  ON CONFLICT (instruction_id) DO UPDATE
    SET program_id = EXCLUDED.program_id,
        status = 'PENDING_SUPERVISOR_APPROVAL',
        held_at = NOW(),
        held_reason = EXCLUDED.held_reason,
        timeout_at = EXCLUDED.timeout_at,
        submitted_by = EXCLUDED.submitted_by,
        decided_at = NULL,
        decided_by = NULL,
        decision_reason = NULL,
        approved_by = NULL,
        approved_at = NULL;
END;
$$;


--
-- Name: touch_anchor_sync_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_anchor_sync_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;


--
-- Name: touch_escrow_envelopes_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_escrow_envelopes_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;


--
-- Name: touch_escrow_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_escrow_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;


--
-- Name: touch_inquiry_state_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_inquiry_state_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;


--
-- Name: touch_members_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_members_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.metadata := COALESCE(NEW.metadata, '{}'::jsonb);
  RETURN NEW;
END;
$$;


--
-- Name: touch_persons_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_persons_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;


--
-- Name: touch_programs_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_programs_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;


--
-- Name: transition_asset_status(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.transition_asset_status(p_tenant_id uuid, p_subject_id uuid, p_to_status text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_current_status TEXT;
BEGIN
    IF p_tenant_id IS NULL THEN
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF003';
    END IF;
    IF p_to_status IS NULL THEN
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF004';
    END IF;

    -- Resolve current status from projects (primary subject type for activation)
    SELECT p.status INTO v_current_status
      FROM public.projects p
     WHERE p.project_id = p_subject_id AND p.tenant_id = p_tenant_id;

    -- Asset_batches may also be subject; continue without error if not a project
    IF v_current_status IS NULL THEN
        SELECT ab.status INTO v_current_status
          FROM public.asset_batches ab
         WHERE ab.asset_batch_id = p_subject_id AND ab.tenant_id = p_tenant_id;
    END IF;
END;
$$;


--
-- Name: transition_escrow_state(uuid, text, text, text, jsonb, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.transition_escrow_state(p_escrow_id uuid, p_to_state text, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb, p_now timestamp with time zone DEFAULT now()) RETURNS TABLE(escrow_id uuid, previous_state text, new_state text, event_id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
  v_row public.escrow_accounts%ROWTYPE;
  v_to_state TEXT := UPPER(BTRIM(COALESCE(p_to_state, '')));
  v_actor TEXT := COALESCE(NULLIF(BTRIM(p_actor_id), ''), 'system');
  v_event_id UUID;
  v_legal BOOLEAN := FALSE;
BEGIN
  SELECT *
  INTO v_row
  FROM public.escrow_accounts
  WHERE escrow_accounts.escrow_id = p_escrow_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'escrow not found'
      USING ERRCODE = 'P7302';
  END IF;

  IF v_to_state NOT IN ('CREATED', 'AUTHORIZED', 'RELEASE_REQUESTED', 'RELEASED', 'CANCELED', 'EXPIRED') THEN
    RAISE EXCEPTION 'invalid target escrow state %', v_to_state
      USING ERRCODE = 'P7303';
  END IF;

  IF v_row.state IN ('RELEASED', 'CANCELED', 'EXPIRED') THEN
    RAISE EXCEPTION 'escrow terminal state transition forbidden: % -> %', v_row.state, v_to_state
      USING ERRCODE = 'P7303';
  END IF;

  v_legal := (
    (v_row.state = 'CREATED' AND v_to_state IN ('AUTHORIZED', 'CANCELED', 'EXPIRED'))
    OR (v_row.state = 'AUTHORIZED' AND v_to_state IN ('RELEASE_REQUESTED', 'CANCELED', 'EXPIRED'))
    OR (v_row.state = 'RELEASE_REQUESTED' AND v_to_state IN ('RELEASED', 'CANCELED', 'EXPIRED'))
  );

  IF NOT v_legal THEN
    RAISE EXCEPTION 'illegal escrow transition: % -> %', v_row.state, v_to_state
      USING ERRCODE = 'P7303';
  END IF;

  UPDATE public.escrow_accounts
  SET state = v_to_state,
      updated_at = p_now,
      released_at = CASE WHEN v_to_state = 'RELEASED' THEN COALESCE(released_at, p_now) ELSE released_at END,
      canceled_at = CASE WHEN v_to_state = 'CANCELED' THEN COALESCE(canceled_at, p_now) ELSE canceled_at END,
      expired_at = CASE WHEN v_to_state = 'EXPIRED' THEN COALESCE(expired_at, p_now) ELSE expired_at END
  WHERE escrow_accounts.escrow_id = p_escrow_id;

  INSERT INTO public.escrow_events(escrow_id, tenant_id, event_type, actor_id, reason, metadata, created_at)
  VALUES (
    v_row.escrow_id,
    v_row.tenant_id,
    v_to_state,
    v_actor,
    p_reason,
    COALESCE(p_metadata, '{}'::jsonb),
    p_now
  )
  RETURNING escrow_events.event_id INTO v_event_id;

  RETURN QUERY
  SELECT v_row.escrow_id, v_row.state, v_to_state, v_event_id;
END;
$$;


--
-- Name: uuid_strategy(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.uuid_strategy() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  SELECT CASE
    WHEN to_regprocedure('public.uuidv7()') IS NOT NULL THEN 'uuidv7'
    ELSE 'gen_random_uuid'
  END;
$$;


--
-- Name: uuid_v7_or_random(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.uuid_v7_or_random() RETURNS uuid
    LANGUAGE sql
    AS $$
          SELECT gen_random_uuid();
        $$;


--
-- Name: validate_confidence_score(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_confidence_score(p_asset_batch_id uuid) RETURNS TABLE(confidence_score numeric, required_threshold numeric, decision_count integer, approved_count integer, is_sufficient boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_confidence   NUMERIC;
    v_threshold    NUMERIC := 0.95;
    v_total        INT;
    v_approved     INT;
BEGIN
    IF p_asset_batch_id IS NULL THEN
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF023';
    END IF;

    SELECT COUNT(*),
           COUNT(*) FILTER (
               WHERE (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
           )
      INTO v_total, v_approved
      FROM public.authority_decisions ad
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
       AND (ad.decision_payload_json->>'subject_id')::UUID = p_asset_batch_id;

    SELECT COALESCE(
               AVG((ad.decision_payload_json->>'confidence_score')::NUMERIC),
               0
           )
      INTO v_confidence
      FROM public.authority_decisions ad
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
       AND (ad.decision_payload_json->>'subject_id')::UUID = p_asset_batch_id
       AND (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
       AND ad.decision_payload_json->>'confidence_score' IS NOT NULL;

    RETURN QUERY SELECT v_confidence, v_threshold, v_total, v_approved,
                        (v_confidence >= v_threshold AND v_approved > 0);
END;
$$;


--
-- Name: validate_payload_against_schema(jsonb, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_payload_against_schema(p_payload jsonb, p_payload_schema_reference_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
DECLARE
    v_schema_exists BOOLEAN := false;
BEGIN
    -- Payload must be a JSON object (Rule 10: opaque validation only)
    IF jsonb_typeof(p_payload) != 'object' THEN
        RETURN false;
    END IF;

    -- If a schema reference was supplied, validate it exists in schema_registry
    IF p_payload_schema_reference_id IS NULL THEN
        RETURN true;
    END IF;

    SELECT EXISTS(
        SELECT 1
          FROM public.schema_registry sr
         WHERE sr.schema_reference_id = p_payload_schema_reference_id
    ) INTO v_schema_exists;

    RETURN v_schema_exists;
END;
$$;


--
-- Name: verify_dispatch_effect_seal(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_dispatch_effect_seal(p_instruction_id text, p_outbound_payload jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: verify_instruction_hierarchy(text, uuid, text, uuid, uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_instruction_hierarchy(p_instruction_id text, p_tenant_id uuid, p_participant_id text, p_program_id uuid, p_entity_id uuid, p_member_id uuid, p_device_id text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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
      USING ERRCODE = 'P7302';
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
      USING ERRCODE = 'P7303';
  END IF;

  RETURN TRUE;
END;
$$;


--
-- Name: verify_internal_ledger_journal_balance(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_internal_ledger_journal_balance(p_journal_id uuid) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH sums AS (
    SELECT
      COALESCE(SUM(CASE WHEN direction = 'DEBIT' THEN amount_minor ELSE 0 END), 0) AS debit_total,
      COALESCE(SUM(CASE WHEN direction = 'CREDIT' THEN amount_minor ELSE 0 END), 0) AS credit_total,
      COUNT(*) AS posting_count,
      COUNT(DISTINCT account_code) AS distinct_accounts,
      COUNT(*) FILTER (WHERE direction = 'DEBIT') AS debit_count,
      COUNT(*) FILTER (WHERE direction = 'CREDIT') AS credit_count
    FROM public.internal_ledger_postings
    WHERE journal_id = p_journal_id
  )
  SELECT posting_count >= 2
     AND debit_count >= 1
     AND credit_count >= 1
     AND distinct_accounts >= 2
     AND debit_total = credit_total
  FROM sums;
$$;


--
-- Name: verify_merkle_leaf(uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_merkle_leaf(p_batch_id uuid, p_leaf_index integer, p_expected_leaf_hash text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: verify_policy_bundle_runtime(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_policy_bundle_runtime(p_policy_bundle_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
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


--
-- Name: verify_verifier_read_token(text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_verifier_read_token(p_token_hash text, p_project_id uuid) RETURNS TABLE(token_id uuid, verifier_id uuid, scoped_tables jsonb, expires_at timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'public'
    AS $$
BEGIN
    IF p_token_hash IS NULL THEN
        RAISE EXCEPTION 'p_token_hash is required' USING ERRCODE = 'GF002';
    END IF;
    IF p_project_id IS NULL THEN
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF003';
    END IF;

    RETURN QUERY
    SELECT t.token_id, t.verifier_id, t.scoped_tables, t.expires_at
      FROM public.gf_verifier_read_tokens t
     WHERE t.project_id = p_project_id
       AND t.revoked_at IS NULL
       AND t.expires_at > now()
       AND t.token_hash = public.crypt(p_token_hash, t.token_hash)
     LIMIT 1;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: adapter_circuit_breakers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adapter_circuit_breakers (
    adapter_id text NOT NULL,
    rail_id text NOT NULL,
    state text DEFAULT 'ACTIVE'::text NOT NULL,
    trigger_threshold numeric(8,6) NOT NULL,
    observed_rate numeric(8,6) DEFAULT 0 NOT NULL,
    rolling_window_seconds integer NOT NULL,
    policy_version_id text NOT NULL,
    suspended_at timestamp with time zone,
    resumed_at timestamp with time zone,
    operator_id text,
    justification_text text
);


--
-- Name: adapter_registrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adapter_registrations (
    adapter_registration_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    adapter_code text NOT NULL,
    methodology_code text NOT NULL,
    methodology_authority text NOT NULL,
    version_code text NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    payload_schema_refs jsonb DEFAULT '[]'::jsonb NOT NULL,
    checklist_refs jsonb DEFAULT '[]'::jsonb NOT NULL,
    entrypoint_refs jsonb DEFAULT '[]'::jsonb NOT NULL,
    issuance_semantic_mode text NOT NULL,
    retirement_semantic_mode text NOT NULL,
    jurisdiction_compatibility jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT adapter_registrations_checklist_refs_check CHECK ((jsonb_typeof(checklist_refs) = 'array'::text)),
    CONSTRAINT adapter_registrations_entrypoint_refs_check CHECK ((jsonb_typeof(entrypoint_refs) = 'array'::text)),
    CONSTRAINT adapter_registrations_issuance_semantic_mode_check CHECK ((issuance_semantic_mode = ANY (ARRAY['STRICT'::text, 'LENIENT'::text, 'HYBRID'::text]))),
    CONSTRAINT adapter_registrations_jurisdiction_compatibility_check CHECK ((jsonb_typeof(jurisdiction_compatibility) = 'object'::text)),
    CONSTRAINT adapter_registrations_payload_schema_refs_check CHECK ((jsonb_typeof(payload_schema_refs) = 'array'::text)),
    CONSTRAINT adapter_registrations_retirement_semantic_mode_check CHECK ((retirement_semantic_mode = ANY (ARRAY['STRICT'::text, 'LENIENT'::text, 'HYBRID'::text])))
);

ALTER TABLE ONLY public.adapter_registrations FORCE ROW LEVEL SECURITY;


--
-- Name: adjustment_approval_stages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adjustment_approval_stages (
    stage_id uuid DEFAULT gen_random_uuid() NOT NULL,
    adjustment_id uuid NOT NULL,
    required_approver_count integer NOT NULL,
    quorum_threshold integer NOT NULL,
    stage_status text NOT NULL,
    quorum_policy_version_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: adjustment_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adjustment_approvals (
    approval_id uuid DEFAULT gen_random_uuid() NOT NULL,
    stage_id uuid NOT NULL,
    approver_id text NOT NULL,
    role_at_time_of_signing text NOT NULL,
    department_at_time_of_signing text NOT NULL,
    attestation_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    signature_ref text NOT NULL,
    unsigned_reason text
);


--
-- Name: adjustment_execution_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adjustment_execution_attempts (
    attempt_id uuid DEFAULT gen_random_uuid() NOT NULL,
    adjustment_id uuid NOT NULL,
    idempotency_key text NOT NULL,
    adjustment_value numeric(18,2) NOT NULL,
    attempt_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    dispatch_reference text,
    outcome text NOT NULL
);


--
-- Name: adjustment_freeze_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adjustment_freeze_flags (
    flag_id uuid DEFAULT gen_random_uuid() NOT NULL,
    adjustment_id uuid NOT NULL,
    flag_type text NOT NULL,
    authority_reference text NOT NULL,
    operator_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: adjustment_instructions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adjustment_instructions (
    adjustment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    parent_instruction_id text NOT NULL,
    adjustment_state public.adjustment_state_enum DEFAULT 'requested'::public.adjustment_state_enum NOT NULL,
    adjustment_type text NOT NULL,
    adjustment_value numeric(18,2) NOT NULL,
    recipient_ref text NOT NULL,
    justification text,
    policy_version_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: anchor_backfill_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anchor_backfill_jobs (
    job_id uuid DEFAULT gen_random_uuid() NOT NULL,
    replay_day date NOT NULL,
    status text NOT NULL,
    source_stream text NOT NULL,
    target_stream text NOT NULL,
    records_replayed integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT anchor_backfill_jobs_status_check CHECK ((status = ANY (ARRAY['STARTED'::text, 'COMPLETED'::text, 'FAILED'::text])))
);


--
-- Name: anchor_sync_operations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anchor_sync_operations (
    operation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    pack_id uuid NOT NULL,
    state text DEFAULT 'PENDING'::text NOT NULL,
    anchor_provider text DEFAULT 'GENERIC'::text NOT NULL,
    anchor_type text,
    anchor_ref text,
    claimed_by text,
    lease_token uuid,
    lease_expires_at timestamp with time zone,
    attempt_count integer DEFAULT 0 NOT NULL,
    last_error text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT anchor_sync_operations_attempt_count_check CHECK ((attempt_count >= 0)),
    CONSTRAINT anchor_sync_operations_state_check CHECK ((state = ANY (ARRAY['PENDING'::text, 'ANCHORING'::text, 'ANCHORED'::text, 'COMPLETED'::text, 'FAILED'::text]))),
    CONSTRAINT ck_anchor_sync_completed_requires_anchor_ref CHECK (((state <> 'COMPLETED'::text) OR (anchor_ref IS NOT NULL)))
);


--
-- Name: archive_verification_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archive_verification_runs (
    run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_scope text NOT NULL,
    years_covered integer NOT NULL,
    archive_only boolean DEFAULT true NOT NULL,
    key_versions_covered text[] NOT NULL,
    canonicalization_versions_covered text[] CONSTRAINT archive_verification_runs_canonicalization_versions_co_not_null NOT NULL,
    outcome text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT archive_verification_runs_outcome_check CHECK ((outcome = ANY (ARRAY['PASS'::text, 'FAIL'::text]))),
    CONSTRAINT archive_verification_runs_years_covered_check CHECK ((years_covered >= 1))
);


--
-- Name: artifact_signing_batch_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.artifact_signing_batch_items (
    item_id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    artifact_id text NOT NULL,
    leaf_index integer NOT NULL,
    leaf_hash text NOT NULL,
    CONSTRAINT artifact_signing_batch_items_leaf_index_check CHECK ((leaf_index >= 0))
);


--
-- Name: artifact_signing_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.artifact_signing_batches (
    batch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    artifact_class text NOT NULL,
    merkle_root text NOT NULL,
    total_artifacts integer NOT NULL,
    hsm_key_ref text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT artifact_signing_batches_total_artifacts_check CHECK ((total_artifacts > 0))
);


--
-- Name: asset_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_batches (
    asset_batch_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    project_id uuid NOT NULL,
    batch_type text NOT NULL,
    quantity numeric NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT asset_batches_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT asset_batches_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'ACTIVE'::text, 'RETIRED'::text, 'CANCELLED'::text])))
);

ALTER TABLE ONLY public.asset_batches FORCE ROW LEVEL SECURITY;


--
-- Name: asset_lifecycle_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_lifecycle_events (
    lifecycle_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    asset_batch_id uuid NOT NULL,
    event_type text NOT NULL,
    event_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.asset_lifecycle_events FORCE ROW LEVEL SECURITY;


--
-- Name: audit_tamper_evident_chains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_tamper_evident_chains (
    chain_id uuid DEFAULT gen_random_uuid() NOT NULL,
    domain text NOT NULL,
    current_hash text NOT NULL,
    previous_hash text,
    generated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: authority_decisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authority_decisions (
    authority_decision_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    jurisdiction_code text NOT NULL,
    regulatory_authority_id uuid NOT NULL,
    decision_type text NOT NULL,
    decision_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.authority_decisions FORCE ROW LEVEL SECURITY;


--
-- Name: billable_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billable_clients (
    billable_client_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    legal_name text NOT NULL,
    client_type text NOT NULL,
    regulator_ref text,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    client_key text,
    CONSTRAINT billable_clients_client_type_check CHECK ((client_type = ANY (ARRAY['BANK'::text, 'MMO'::text, 'NGO'::text, 'GOV_PROGRAM'::text, 'COOP_FEDERATION'::text, 'ENTERPRISE'::text]))),
    CONSTRAINT billable_clients_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
);


--
-- Name: billing_usage_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_usage_events (
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    billable_client_id uuid NOT NULL,
    tenant_id uuid,
    client_id uuid,
    subject_member_id uuid,
    subject_client_id uuid,
    correlation_id uuid,
    event_type text NOT NULL,
    units text NOT NULL,
    quantity bigint NOT NULL,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now(),
    idempotency_key text,
    CONSTRAINT billing_usage_events_event_type_check CHECK ((event_type = ANY (ARRAY['EVIDENCE_BUNDLE'::text, 'CASE_PACK'::text, 'EXCEPTION_TRIAGE'::text, 'RETENTION_ANCHOR'::text, 'ESCROW_RELEASE'::text, 'DISPUTE_PACK'::text]))),
    CONSTRAINT billing_usage_events_member_requires_tenant_chk CHECK (((subject_member_id IS NULL) OR (tenant_id IS NOT NULL))),
    CONSTRAINT billing_usage_events_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT billing_usage_events_subject_zero_or_one_chk CHECK (((((subject_member_id IS NOT NULL))::integer + ((subject_client_id IS NOT NULL))::integer) <= 1)),
    CONSTRAINT billing_usage_events_units_check CHECK ((units = ANY (ARRAY['count'::text, 'bytes'::text, 'seconds'::text, 'events'::text])))
);

ALTER TABLE ONLY public.billing_usage_events FORCE ROW LEVEL SECURITY;


--
-- Name: boz_operational_scenario_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.boz_operational_scenario_runs (
    run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    scenario_name text NOT NULL,
    outcome text NOT NULL,
    evidence_ref text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT boz_operational_scenario_runs_outcome_check CHECK ((outcome = ANY (ARRAY['PASS'::text, 'FAIL'::text])))
);


--
-- Name: canonicalization_archive_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.canonicalization_archive_snapshots (
    snapshot_id uuid DEFAULT gen_random_uuid() NOT NULL,
    canonicalization_version text CONSTRAINT canonicalization_archive_snap_canonicalization_version_not_null NOT NULL,
    snapshot_path text NOT NULL,
    snapshot_sha256 text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: canonicalization_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.canonicalization_registry (
    canonicalization_version text NOT NULL,
    spec_json jsonb NOT NULL,
    test_vectors jsonb NOT NULL,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    deprecated_at timestamp with time zone,
    immutable boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: dispatch_reference_collision_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispatch_reference_collision_events (
    collision_event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    instruction_id uuid NOT NULL,
    adjustment_id uuid,
    rail_id text NOT NULL,
    reference_attempted text CONSTRAINT dispatch_reference_collision_event_reference_attempted_not_null NOT NULL,
    strategy_used public.reference_strategy_type_enum NOT NULL,
    collision_count integer NOT NULL,
    outcome text NOT NULL,
    policy_version_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT dispatch_reference_collision_events_collision_count_check CHECK ((collision_count >= 1)),
    CONSTRAINT dispatch_reference_collision_events_outcome_check CHECK ((outcome = ANY (ARRAY['RESOLVED'::text, 'EXHAUSTED'::text, 'TRUNCATION_COLLISION_BLOCKED'::text, 'UNREGISTERED_BLOCKED'::text, 'REJECTED'::text])))
);


--
-- Name: dispatch_reference_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dispatch_reference_registry (
    registry_id uuid DEFAULT gen_random_uuid() NOT NULL,
    instruction_id uuid NOT NULL,
    adjustment_id uuid,
    rail_id text NOT NULL,
    allocated_reference text NOT NULL,
    canonicalized_reference text NOT NULL,
    strategy_used public.reference_strategy_type_enum NOT NULL,
    policy_version_id text NOT NULL,
    collision_retry_count integer DEFAULT 0 NOT NULL,
    allocation_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    dispatch_attempted_at timestamp with time zone,
    CONSTRAINT dispatch_reference_registry_collision_retry_count_check CHECK ((collision_retry_count >= 0))
);


--
-- Name: effect_seal_mismatch_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.effect_seal_mismatch_events (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    instruction_id text NOT NULL,
    stored_seal_hash text NOT NULL,
    computed_dispatch_hash text NOT NULL,
    mismatch_detected boolean DEFAULT true NOT NULL,
    dispatch_blocked boolean DEFAULT true NOT NULL,
    event_timestamp timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: escrow_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escrow_accounts (
    escrow_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    program_id uuid,
    entity_id text,
    state text DEFAULT 'CREATED'::text NOT NULL,
    authorized_amount_minor bigint NOT NULL,
    currency_code character(3) NOT NULL,
    authorization_expires_at timestamp with time zone,
    release_due_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    released_at timestamp with time zone,
    canceled_at timestamp with time zone,
    expired_at timestamp with time zone,
    CONSTRAINT escrow_accounts_authorized_amount_minor_check CHECK ((authorized_amount_minor >= 0)),
    CONSTRAINT escrow_accounts_state_check CHECK ((state = ANY (ARRAY['CREATED'::text, 'AUTHORIZED'::text, 'RELEASE_REQUESTED'::text, 'RELEASED'::text, 'CANCELED'::text, 'EXPIRED'::text])))
);

ALTER TABLE ONLY public.escrow_accounts FORCE ROW LEVEL SECURITY;


--
-- Name: escrow_envelopes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escrow_envelopes (
    escrow_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    currency_code character(3) NOT NULL,
    ceiling_amount_minor bigint NOT NULL,
    reserved_amount_minor bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT escrow_envelopes_ceiling_amount_minor_check CHECK ((ceiling_amount_minor >= 0)),
    CONSTRAINT escrow_envelopes_reserved_amount_minor_check CHECK ((reserved_amount_minor >= 0))
);

ALTER TABLE ONLY public.escrow_envelopes FORCE ROW LEVEL SECURITY;


--
-- Name: escrow_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escrow_events (
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    escrow_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    event_type text NOT NULL,
    actor_id text DEFAULT CURRENT_USER NOT NULL,
    reason text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT escrow_events_event_type_check CHECK ((event_type = ANY (ARRAY['CREATED'::text, 'AUTHORIZED'::text, 'RELEASE_REQUESTED'::text, 'RELEASED'::text, 'CANCELED'::text, 'EXPIRED'::text])))
);

ALTER TABLE ONLY public.escrow_events FORCE ROW LEVEL SECURITY;


--
-- Name: escrow_reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escrow_reservations (
    reservation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    program_escrow_id uuid NOT NULL,
    reservation_escrow_id uuid NOT NULL,
    amount_minor bigint NOT NULL,
    actor_id text DEFAULT CURRENT_USER NOT NULL,
    reason text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT escrow_reservations_amount_minor_check CHECK ((amount_minor > 0))
);

ALTER TABLE ONLY public.escrow_reservations FORCE ROW LEVEL SECURITY;


--
-- Name: escrow_summary_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escrow_summary_projection (
    escrow_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    program_id uuid,
    state text NOT NULL,
    authorized_amount_minor bigint DEFAULT 0 NOT NULL,
    currency_code character(3) DEFAULT 'USD'::bpchar NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
);


--
-- Name: evidence_bundle_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence_bundle_projection (
    instruction_id text NOT NULL,
    tenant_id uuid NOT NULL,
    projection_payload jsonb NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
);


--
-- Name: evidence_edges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence_edges (
    evidence_edge_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    source_node_id uuid NOT NULL,
    target_node_id uuid NOT NULL,
    edge_type text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT no_self_loop CHECK ((source_node_id <> target_node_id))
);

ALTER TABLE ONLY public.evidence_edges FORCE ROW LEVEL SECURITY;


--
-- Name: evidence_nodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence_nodes (
    evidence_node_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    project_id uuid NOT NULL,
    monitoring_record_id uuid,
    node_type text NOT NULL,
    node_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.evidence_nodes FORCE ROW LEVEL SECURITY;


--
-- Name: evidence_pack_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence_pack_items (
    item_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    pack_id uuid NOT NULL,
    artifact_path text,
    artifact_hash text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT evidence_pack_items_path_or_hash_chk CHECK (((artifact_path IS NOT NULL) OR (artifact_hash IS NOT NULL)))
);


--
-- Name: evidence_packs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evidence_packs (
    pack_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    pack_type text NOT NULL,
    correlation_id uuid,
    root_hash text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    signer_participant_id text,
    signature_alg text,
    signature text,
    signed_at timestamp with time zone,
    anchor_type text,
    anchor_ref text,
    anchored_at timestamp with time zone,
    CONSTRAINT evidence_packs_pack_type_check CHECK ((pack_type = ANY (ARRAY['INSTRUCTION_BUNDLE'::text, 'INCIDENT_PACK'::text, 'DISPUTE_PACK'::text])))
);


--
-- Name: execution_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.execution_records (
    execution_id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    execution_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    interpretation_version_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: external_proofs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_proofs (
    proof_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    attestation_id uuid NOT NULL,
    provider text NOT NULL,
    request_hash text NOT NULL,
    response_hash text NOT NULL,
    provider_ref text,
    verified_at timestamp with time zone,
    expires_at timestamp with time zone,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id uuid,
    billable_client_id uuid,
    subject_member_id uuid
);

ALTER TABLE ONLY public.external_proofs FORCE ROW LEVEL SECURITY;


--
-- Name: gf_verifier_read_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gf_verifier_read_tokens (
    token_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    verifier_id uuid NOT NULL,
    project_id uuid NOT NULL,
    token_hash text NOT NULL,
    scoped_tables jsonb DEFAULT '[]'::jsonb NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    revocation_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.gf_verifier_read_tokens FORCE ROW LEVEL SECURITY;


--
-- Name: global_rate_limit_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.global_rate_limit_policies (
    policy_id uuid DEFAULT gen_random_uuid() NOT NULL,
    partition_strategy text NOT NULL,
    max_requests integer NOT NULL,
    interval_seconds integer NOT NULL,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT global_rate_limit_policies_interval_seconds_check CHECK ((interval_seconds > 0)),
    CONSTRAINT global_rate_limit_policies_max_requests_check CHECK ((max_requests > 0))
);


--
-- Name: historical_verification_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historical_verification_runs (
    verification_run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    key_version text NOT NULL,
    verified_artifact_id text NOT NULL,
    key_used text NOT NULL,
    operational_store_excluded boolean DEFAULT true CONSTRAINT historical_verification_run_operational_store_excluded_not_null NOT NULL,
    outcome text NOT NULL,
    error_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: hsm_fail_closed_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hsm_fail_closed_events (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    outage_source text NOT NULL,
    blocked_action text NOT NULL,
    error_code text NOT NULL,
    observed_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: incident_case_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_case_projection (
    incident_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    status text NOT NULL,
    projection_payload jsonb NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
);


--
-- Name: incident_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_events (
    incident_event_id uuid NOT NULL,
    incident_id uuid NOT NULL,
    event_type text NOT NULL,
    event_payload jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: ingress_attestations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingress_attestations (
    attestation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    instruction_id text NOT NULL,
    tenant_id uuid NOT NULL,
    payload_hash text NOT NULL,
    signature_hash text,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    client_id uuid,
    client_id_hash text,
    member_id uuid,
    participant_id text,
    cert_fingerprint_sha256 text,
    token_jti_hash text,
    correlation_id uuid,
    signatures jsonb DEFAULT '[]'::jsonb NOT NULL,
    upstream_ref text,
    downstream_ref text,
    nfs_sequence_ref text,
    levy_applicable boolean
);

ALTER TABLE ONLY public.ingress_attestations FORCE ROW LEVEL SECURITY;


--
-- Name: inquiry_state_machine; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inquiry_state_machine (
    instruction_id text NOT NULL,
    inquiry_state public.inquiry_state_enum DEFAULT 'SCHEDULED'::public.inquiry_state_enum NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    max_attempts integer NOT NULL,
    policy_version_id text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT inquiry_state_machine_max_attempts_check CHECK ((max_attempts > 0))
);


--
-- Name: instruction_effect_seals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instruction_effect_seals (
    instruction_id text NOT NULL,
    effect_seal_hash text NOT NULL,
    canonicalization_version text NOT NULL,
    policy_version_id text NOT NULL,
    sealed_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: instruction_finality_conflicts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instruction_finality_conflicts (
    instruction_id text NOT NULL,
    finality_state public.finality_resolution_state_enum DEFAULT 'ACTIVE'::public.finality_resolution_state_enum NOT NULL,
    rail_a_id text,
    rail_a_response public.finality_signal_status_enum,
    rail_b_id text,
    rail_b_response public.finality_signal_status_enum,
    contradiction_timestamp timestamp with time zone,
    containment_action text,
    operator_resolution_id text,
    resolved_at timestamp with time zone
);


--
-- Name: instruction_settlement_finality; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instruction_settlement_finality (
    finality_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    instruction_id text NOT NULL,
    participant_id text NOT NULL,
    is_final boolean DEFAULT true NOT NULL,
    final_state text NOT NULL,
    rail_message_type text NOT NULL,
    reversal_of_instruction_id text,
    finalized_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb,
    CONSTRAINT instruction_settlement_finality_final_state_check CHECK ((final_state = ANY (ARRAY['SETTLED'::text, 'REVERSED'::text]))),
    CONSTRAINT instruction_settlement_finality_is_final_true_chk CHECK ((is_final = true)),
    CONSTRAINT instruction_settlement_finality_rail_message_type_check CHECK ((rail_message_type = ANY (ARRAY['pacs.008'::text, 'camt.056'::text]))),
    CONSTRAINT instruction_settlement_finality_self_reversal_chk CHECK (((reversal_of_instruction_id IS NULL) OR (reversal_of_instruction_id <> instruction_id))),
    CONSTRAINT instruction_settlement_finality_shape_chk CHECK ((((final_state = 'SETTLED'::text) AND (reversal_of_instruction_id IS NULL) AND (rail_message_type = 'pacs.008'::text)) OR ((final_state = 'REVERSED'::text) AND (reversal_of_instruction_id IS NOT NULL) AND (rail_message_type = 'camt.056'::text))))
);


--
-- Name: instruction_status_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instruction_status_projection (
    instruction_id text NOT NULL,
    tenant_id uuid NOT NULL,
    participant_id text NOT NULL,
    rail_type text NOT NULL,
    status text NOT NULL,
    attestation_id uuid NOT NULL,
    outbox_id uuid NOT NULL,
    payload_hash text NOT NULL,
    amount_minor bigint DEFAULT 0 NOT NULL,
    currency_code character(3) DEFAULT 'ZMW'::bpchar NOT NULL,
    correlation_id uuid,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
);


--
-- Name: internal_ledger_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.internal_ledger_journals (
    journal_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    idempotency_key text NOT NULL,
    journal_type text NOT NULL,
    reference_id text,
    currency_code text NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT internal_ledger_journals_currency_code_check CHECK ((currency_code ~ '^[A-Z]{3}$'::text))
);


--
-- Name: internal_ledger_postings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.internal_ledger_postings (
    posting_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    journal_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    account_code text NOT NULL,
    direction text NOT NULL,
    amount_minor bigint NOT NULL,
    currency_code text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT internal_ledger_postings_amount_minor_check CHECK ((amount_minor > 0)),
    CONSTRAINT internal_ledger_postings_currency_code_check CHECK ((currency_code ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT internal_ledger_postings_direction_check CHECK ((direction = ANY (ARRAY['DEBIT'::text, 'CREDIT'::text])))
);


--
-- Name: interpretation_packs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interpretation_packs (
    interpretation_pack_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    jurisdiction_code text NOT NULL,
    pack_type text NOT NULL,
    pack_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.interpretation_packs FORCE ROW LEVEL SECURITY;


--
-- Name: jurisdiction_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jurisdiction_profiles (
    jurisdiction_profile_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    jurisdiction_code text NOT NULL,
    profile_type text NOT NULL,
    profile_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.jurisdiction_profiles FORCE ROW LEVEL SECURITY;


--
-- Name: key_rotation_drills; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.key_rotation_drills (
    drill_id uuid DEFAULT gen_random_uuid() NOT NULL,
    rotation_type text NOT NULL,
    old_key_id text NOT NULL,
    new_key_id text NOT NULL,
    trigger_reason text,
    old_key_deactivation_timestamp timestamp with time zone,
    new_key_activation_timestamp timestamp with time zone,
    archival_confirmed boolean DEFAULT false NOT NULL,
    drill_outcome text NOT NULL,
    meta_signing_key_class public.key_class_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT key_rotation_drills_drill_outcome_check CHECK ((drill_outcome = ANY (ARRAY['PASS'::text, 'FAIL'::text]))),
    CONSTRAINT key_rotation_drills_rotation_type_check CHECK ((rotation_type = ANY (ARRAY['SCHEDULED'::text, 'EMERGENCY'::text])))
);


--
-- Name: kyc_provider_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kyc_provider_registry (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_code text NOT NULL,
    provider_name text NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    public_key_pem text,
    signing_algorithm text,
    boz_licence_reference text,
    is_active boolean,
    active_from date,
    active_to date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT kyc_provider_registry_check CHECK (((active_to IS NULL) OR (active_from IS NULL) OR (active_to >= active_from)))
);


--
-- Name: kyc_retention_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kyc_retention_policy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    retention_class text NOT NULL,
    statutory_reference text NOT NULL,
    retention_years integer NOT NULL,
    description text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    CONSTRAINT kyc_retention_policy_retention_years_check CHECK ((retention_years > 0))
);


--
-- Name: kyc_verification_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kyc_verification_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid NOT NULL,
    provider_id uuid,
    provider_code text,
    outcome text,
    verification_method text,
    verification_hash text,
    hash_algorithm text,
    provider_signature text,
    provider_key_version text,
    provider_reference text,
    jurisdiction_code character(2),
    document_type text,
    verified_at_provider timestamp with time zone,
    anchored_at timestamp with time zone DEFAULT now() NOT NULL,
    retention_class text DEFAULT 'FIC_AML_CUSTOMER_ID'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    CONSTRAINT kyc_verification_records_retention_class_check CHECK ((retention_class = 'FIC_AML_CUSTOMER_ID'::text))
);


--
-- Name: levy_calculation_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.levy_calculation_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    instruction_id uuid NOT NULL,
    levy_rate_id uuid,
    jurisdiction_code character(2),
    taxable_amount_minor bigint,
    levy_amount_pre_cap bigint,
    cap_applied_minor bigint,
    levy_amount_final bigint,
    currency_code character(3),
    reporting_period character(7),
    levy_status text,
    calculated_at timestamp with time zone,
    calculated_by_version text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT levy_calculation_records_cap_applied_minor_check CHECK (((cap_applied_minor IS NULL) OR (cap_applied_minor >= 0))),
    CONSTRAINT levy_calculation_records_levy_amount_final_check CHECK (((levy_amount_final IS NULL) OR (levy_amount_final >= 0))),
    CONSTRAINT levy_calculation_records_levy_amount_pre_cap_check CHECK (((levy_amount_pre_cap IS NULL) OR (levy_amount_pre_cap >= 0))),
    CONSTRAINT levy_calculation_records_reporting_period_check CHECK (((reporting_period IS NULL) OR (reporting_period ~ '^[0-9]{4}-[0-9]{2}$'::text))),
    CONSTRAINT levy_calculation_records_taxable_amount_minor_check CHECK (((taxable_amount_minor IS NULL) OR (taxable_amount_minor >= 0)))
);


--
-- Name: levy_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.levy_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    statutory_reference text,
    rate_bps integer NOT NULL,
    cap_amount_minor bigint,
    cap_currency_code character(3),
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    CONSTRAINT levy_rates_cap_amount_minor_check CHECK (((cap_amount_minor IS NULL) OR (cap_amount_minor > 0))),
    CONSTRAINT levy_rates_cap_currency_required CHECK (((cap_amount_minor IS NULL) OR (cap_currency_code IS NOT NULL))),
    CONSTRAINT levy_rates_check CHECK (((effective_to IS NULL) OR (effective_to >= effective_from))),
    CONSTRAINT levy_rates_rate_bps_check CHECK (((rate_bps >= 0) AND (rate_bps <= 10000)))
);


--
-- Name: levy_remittance_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.levy_remittance_periods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    period_code character(7) NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    filing_deadline date,
    period_status text,
    filed_at timestamp with time zone,
    zra_reference text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT levy_remittance_periods_check CHECK ((period_end >= period_start)),
    CONSTRAINT levy_remittance_periods_check1 CHECK (((filing_deadline IS NULL) OR (filing_deadline >= period_end))),
    CONSTRAINT levy_remittance_periods_period_code_check CHECK ((period_code ~ '^[0-9]{4}-[0-9]{2}$'::text))
);


--
-- Name: lifecycle_checkpoint_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lifecycle_checkpoint_rules (
    lifecycle_checkpoint_rule_id uuid DEFAULT public.uuid_v7_or_random() CONSTRAINT lifecycle_checkpoint_rules_lifecycle_checkpoint_rule_i_not_null NOT NULL,
    jurisdiction_code text NOT NULL,
    regulatory_checkpoint_id uuid NOT NULL,
    rule_type text NOT NULL,
    rule_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.lifecycle_checkpoint_rules FORCE ROW LEVEL SECURITY;


--
-- Name: malformed_quarantine_store; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.malformed_quarantine_store (
    quarantine_id uuid DEFAULT gen_random_uuid() NOT NULL,
    adapter_id text NOT NULL,
    rail_id text NOT NULL,
    classification public.quarantine_classification_enum NOT NULL,
    truncation_applied boolean NOT NULL,
    payload_hash text NOT NULL,
    payload_capture text NOT NULL,
    retention_policy_version_id text NOT NULL,
    capture_timestamp timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: member_device_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_device_events (
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    member_id uuid NOT NULL,
    instruction_id text NOT NULL,
    device_id text,
    device_id_hash text,
    iccid_hash text,
    event_type text NOT NULL,
    observed_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT member_device_events_device_id_event_type_chk CHECK (((device_id IS NULL) = (event_type = ANY (ARRAY['UNREGISTERED_DEVICE'::text, 'REVOKED_DEVICE_ATTEMPT'::text])))),
    CONSTRAINT member_device_events_event_type_check CHECK ((event_type = ANY (ARRAY['ENROLLED_DEVICE'::text, 'UNREGISTERED_DEVICE'::text, 'REVOKED_DEVICE_ATTEMPT'::text, 'SIM_SWAP_DETECTED'::text])))
);

ALTER TABLE ONLY public.member_device_events FORCE ROW LEVEL SECURITY;


--
-- Name: member_devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_devices (
    tenant_id uuid NOT NULL,
    member_id uuid NOT NULL,
    device_id_hash text NOT NULL,
    iccid_hash text,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT member_devices_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text, 'REVOKED'::text])))
);

ALTER TABLE ONLY public.member_devices FORCE ROW LEVEL SECURITY;


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.members (
    tenant_id uuid NOT NULL,
    member_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_member_id uuid NOT NULL,
    person_id uuid NOT NULL,
    entity_id uuid NOT NULL,
    member_ref_hash text NOT NULL,
    kyc_status text DEFAULT 'PENDING'::text NOT NULL,
    enrolled_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    ceiling_amount_minor bigint DEFAULT 0 NOT NULL,
    ceiling_currency character(3) DEFAULT 'USD'::bpchar NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT members_ceiling_amount_minor_check CHECK ((ceiling_amount_minor >= 0)),
    CONSTRAINT members_kyc_status_check CHECK ((kyc_status = ANY (ARRAY['PENDING'::text, 'VERIFIED'::text, 'REJECTED'::text]))),
    CONSTRAINT members_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'ARCHIVED'::text])))
);

ALTER TABLE ONLY public.members FORCE ROW LEVEL SECURITY;


--
-- Name: methodology_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.methodology_versions (
    methodology_version_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    adapter_registration_id uuid NOT NULL,
    version text NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT methodology_versions_status_check CHECK ((status = ANY (ARRAY['DRAFT'::text, 'ACTIVE'::text, 'DEPRECATED'::text])))
);

ALTER TABLE ONLY public.methodology_versions FORCE ROW LEVEL SECURITY;


--
-- Name: mmo_reality_control_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mmo_reality_control_events (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    instruction_id text NOT NULL,
    scenario_type text NOT NULL,
    fallback_posture text NOT NULL,
    policy_version_id text NOT NULL,
    behavior_profile text NOT NULL,
    evidence_artifact_type text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: monitoring_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.monitoring_records (
    monitoring_record_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    project_id uuid NOT NULL,
    record_type text NOT NULL,
    record_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.monitoring_records FORCE ROW LEVEL SECURITY;


--
-- Name: offline_safe_mode_windows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offline_safe_mode_windows (
    window_id uuid DEFAULT gen_random_uuid() NOT NULL,
    block_start timestamp with time zone DEFAULT now() NOT NULL,
    block_end timestamp with time zone,
    reason text NOT NULL,
    policy_version_id text NOT NULL,
    gap_marker_id text NOT NULL,
    re_sign_linked boolean DEFAULT false NOT NULL
);


--
-- Name: orphaned_attestation_landing_zone; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orphaned_attestation_landing_zone (
    orphan_id uuid DEFAULT gen_random_uuid() NOT NULL,
    instruction_id text NOT NULL,
    callback_payload_hash text CONSTRAINT orphaned_attestation_landing_zon_callback_payload_hash_not_null NOT NULL,
    callback_payload_truncated text CONSTRAINT orphaned_attestation_landin_callback_payload_truncated_not_null NOT NULL,
    arrival_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    instruction_state_at_arrival text CONSTRAINT orphaned_attestation_landin_instruction_state_at_arriv_not_null NOT NULL,
    classification public.orphan_classification_enum NOT NULL,
    event_fingerprint text NOT NULL
);


--
-- Name: participant_outbox_sequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.participant_outbox_sequences (
    participant_id text NOT NULL,
    next_sequence_id bigint NOT NULL,
    CONSTRAINT participant_outbox_sequences_next_sequence_id_check CHECK ((next_sequence_id >= 1))
);


--
-- Name: participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.participants (
    participant_id text NOT NULL,
    legal_name text NOT NULL,
    participant_kind text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT participants_participant_kind_check CHECK ((participant_kind = ANY (ARRAY['BANK'::text, 'MMO'::text, 'NGO'::text, 'GOV_PROGRAM'::text, 'COOP_FEDERATION'::text, 'ENTERPRISE'::text, 'INTERNAL'::text]))),
    CONSTRAINT participants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
);


--
-- Name: payment_outbox_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_outbox_attempts (
    attempt_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    outbox_id uuid NOT NULL,
    instruction_id text NOT NULL,
    participant_id text NOT NULL,
    sequence_id bigint NOT NULL,
    idempotency_key text NOT NULL,
    rail_type text NOT NULL,
    payload jsonb NOT NULL,
    attempt_no integer NOT NULL,
    state public.outbox_attempt_state NOT NULL,
    claimed_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    rail_reference text,
    rail_code text,
    error_code text,
    error_message text,
    latency_ms integer,
    worker_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id uuid,
    member_id uuid,
    correlation_id uuid,
    upstream_ref text,
    downstream_ref text,
    nfs_sequence_ref text,
    CONSTRAINT ck_attempts_payload_is_object CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT payment_outbox_attempts_attempt_no_check CHECK ((attempt_no >= 1)),
    CONSTRAINT payment_outbox_attempts_latency_ms_check CHECK (((latency_ms IS NULL) OR (latency_ms >= 0)))
);

ALTER TABLE ONLY public.payment_outbox_attempts FORCE ROW LEVEL SECURITY;


--
-- Name: payment_outbox_pending; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_outbox_pending (
    outbox_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    instruction_id text NOT NULL,
    participant_id text NOT NULL,
    sequence_id bigint NOT NULL,
    idempotency_key text NOT NULL,
    rail_type text NOT NULL,
    payload jsonb NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    claimed_by text,
    lease_token uuid,
    lease_expires_at timestamp with time zone,
    tenant_id uuid,
    correlation_id uuid,
    upstream_ref text,
    downstream_ref text,
    nfs_sequence_ref text,
    kyc_hold boolean,
    CONSTRAINT ck_pending_payload_is_object CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT payment_outbox_pending_attempt_count_check CHECK ((attempt_count >= 0))
)
WITH (fillfactor='80');

ALTER TABLE ONLY public.payment_outbox_pending FORCE ROW LEVEL SECURITY;


--
-- Name: penalty_defense_packs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.penalty_defense_packs (
    pack_id uuid DEFAULT gen_random_uuid() NOT NULL,
    report_id text NOT NULL,
    contains_raw_pii boolean DEFAULT false NOT NULL,
    submission_attempt_ref uuid,
    generated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: persons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.persons (
    tenant_id uuid NOT NULL,
    person_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    person_ref_hash text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT persons_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text, 'SUSPENDED'::text])))
);

ALTER TABLE ONLY public.persons FORCE ROW LEVEL SECURITY;


--
-- Name: pii_erased_subject_placeholders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pii_erased_subject_placeholders (
    placeholder_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_ref text NOT NULL,
    placeholder_ref text NOT NULL,
    purge_effective_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pii_erasure_journal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pii_erasure_journal (
    erasure_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_ref text NOT NULL,
    request_source text NOT NULL,
    approved_at timestamp with time zone,
    completed_at timestamp with time zone,
    status text NOT NULL,
    CONSTRAINT pii_erasure_journal_status_check CHECK ((status = ANY (ARRAY['REQUESTED'::text, 'APPROVED'::text, 'COMPLETED'::text, 'FAILED'::text])))
);


--
-- Name: pii_purge_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pii_purge_events (
    purge_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    purge_request_id uuid NOT NULL,
    event_type text NOT NULL,
    rows_affected integer DEFAULT 0 NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb,
    CONSTRAINT pii_purge_events_event_type_check CHECK ((event_type = ANY (ARRAY['REQUESTED'::text, 'PURGED'::text]))),
    CONSTRAINT pii_purge_events_rows_affected_check CHECK ((rows_affected >= 0))
);


--
-- Name: pii_purge_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pii_purge_requests (
    purge_request_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    subject_token text NOT NULL,
    requested_by text NOT NULL,
    request_reason text NOT NULL,
    requested_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pii_tokenization_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pii_tokenization_registry (
    token_id uuid DEFAULT gen_random_uuid() NOT NULL,
    subject_ref text NOT NULL,
    token_value text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    retired_at timestamp with time zone
);


--
-- Name: pii_vault_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pii_vault_records (
    vault_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    subject_token text NOT NULL,
    identity_hash text NOT NULL,
    protected_payload jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    purged_at timestamp with time zone,
    purge_request_id uuid,
    CONSTRAINT pii_vault_records_purge_shape_chk CHECK ((((purged_at IS NULL) AND (protected_payload IS NOT NULL) AND (purge_request_id IS NULL)) OR ((purged_at IS NOT NULL) AND (protected_payload IS NULL) AND (purge_request_id IS NOT NULL))))
);


--
-- Name: policy_bundles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.policy_bundles (
    policy_bundle_id uuid DEFAULT gen_random_uuid() NOT NULL,
    policy_id text NOT NULL,
    policy_version text NOT NULL,
    state public.policy_bundle_state_enum DEFAULT 'draft'::public.policy_bundle_state_enum NOT NULL,
    high_risk boolean DEFAULT false NOT NULL,
    signer_key_id text,
    signature_valid boolean DEFAULT false NOT NULL,
    activation_timestamp timestamp with time zone,
    verification_outcome text,
    assurance_tier text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: policy_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.policy_versions (
    version text NOT NULL,
    status public.policy_version_status DEFAULT 'ACTIVE'::public.policy_version_status NOT NULL,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    grace_expires_at timestamp with time zone,
    checksum text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean GENERATED ALWAYS AS ((status = 'ACTIVE'::public.policy_version_status)) STORED,
    CONSTRAINT ck_policy_active_has_no_grace_expiry CHECK (((status <> 'ACTIVE'::public.policy_version_status) OR (grace_expires_at IS NULL))),
    CONSTRAINT ck_policy_checksum_nonempty CHECK ((length(checksum) > 0)),
    CONSTRAINT ck_policy_grace_requires_expiry CHECK (((status <> 'GRACE'::public.policy_version_status) OR (grace_expires_at IS NOT NULL)))
);


--
-- Name: program_member_summary_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.program_member_summary_projection (
    tenant_id uuid NOT NULL,
    program_id uuid NOT NULL,
    active_member_count bigint DEFAULT 0 NOT NULL,
    verified_member_count bigint DEFAULT 0 CONSTRAINT program_member_summary_projectio_verified_member_count_not_null NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
);


--
-- Name: program_migration_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.program_migration_events (
    migration_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    person_id uuid NOT NULL,
    from_program_id uuid NOT NULL,
    to_program_id uuid NOT NULL,
    migrated_member_id uuid NOT NULL,
    migrated_at timestamp with time zone DEFAULT now() NOT NULL,
    migrated_by text NOT NULL,
    reason text,
    formula_version_id uuid NOT NULL,
    new_member_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT program_migration_events_from_to_chk CHECK ((from_program_id <> to_program_id))
);

ALTER TABLE ONLY public.program_migration_events FORCE ROW LEVEL SECURITY;


--
-- Name: program_supplier_allowlist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.program_supplier_allowlist (
    tenant_id uuid NOT NULL,
    program_id uuid NOT NULL,
    supplier_id text NOT NULL,
    allowed boolean DEFAULT true NOT NULL,
    updated_at_utc text NOT NULL
);

ALTER TABLE ONLY public.program_supplier_allowlist FORCE ROW LEVEL SECURITY;


--
-- Name: programme_policy_binding; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme_policy_binding (
    id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    programme_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    policy_code text NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    bound_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.programme_policy_binding FORCE ROW LEVEL SECURITY;


--
-- Name: programme_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme_registry (
    id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    programme_key text NOT NULL,
    display_name text NOT NULL,
    status text DEFAULT 'CREATED'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT programme_registry_status_check CHECK ((status = ANY (ARRAY['CREATED'::text, 'ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
);

ALTER TABLE ONLY public.programme_registry FORCE ROW LEVEL SECURITY;


--
-- Name: programs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programs (
    program_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    program_key text NOT NULL,
    program_name text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    program_escrow_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT programs_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
);

ALTER TABLE ONLY public.programs FORCE ROW LEVEL SECURITY;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    project_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    name text NOT NULL,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT projects_status_check CHECK ((status = ANY (ARRAY['DRAFT'::text, 'ACTIVE'::text, 'SUSPENDED'::text, 'RETIRED'::text])))
);

ALTER TABLE ONLY public.projects FORCE ROW LEVEL SECURITY;


--
-- Name: proof_pack_batch_leaves; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proof_pack_batch_leaves (
    leaf_id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    artifact_id text NOT NULL,
    leaf_index integer NOT NULL,
    leaf_hash text NOT NULL,
    merkle_proof jsonb NOT NULL,
    CONSTRAINT proof_pack_batch_leaves_leaf_index_check CHECK ((leaf_index >= 0))
);


--
-- Name: proof_pack_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.proof_pack_batches (
    batch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    merkle_root text NOT NULL,
    leaf_count integer NOT NULL,
    canonicalization_version text NOT NULL,
    published_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT proof_pack_batches_leaf_count_check CHECK ((leaf_count > 0))
);


--
-- Name: rail_dispatch_truth_anchor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rail_dispatch_truth_anchor (
    anchor_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    attempt_id uuid NOT NULL,
    outbox_id uuid NOT NULL,
    instruction_id text NOT NULL,
    participant_id text NOT NULL,
    rail_participant_id text NOT NULL,
    rail_profile text NOT NULL,
    rail_sequence_ref text NOT NULL,
    state public.outbox_attempt_state NOT NULL,
    anchored_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT rail_truth_anchor_state_chk CHECK ((state = 'DISPATCHED'::public.outbox_attempt_state))
);


--
-- Name: redaction_audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.redaction_audit_events (
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    report_id text NOT NULL,
    actor_id text NOT NULL,
    action text NOT NULL,
    redaction_scope text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: reference_strategy_policy_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reference_strategy_policy_versions (
    policy_version_id text NOT NULL,
    version_status text DEFAULT 'ACTIVE'::text NOT NULL,
    policy_json jsonb NOT NULL,
    signed_at timestamp with time zone,
    signed_key_id text,
    unsigned_reason text,
    evidence_path text,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reference_strategy_policy_versions_version_status_check CHECK ((version_status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text])))
);


--
-- Name: regulatory_authorities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regulatory_authorities (
    regulatory_authority_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    jurisdiction_code text NOT NULL,
    authority_name text NOT NULL,
    authority_type text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.regulatory_authorities FORCE ROW LEVEL SECURITY;


--
-- Name: regulatory_checkpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regulatory_checkpoints (
    regulatory_checkpoint_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    jurisdiction_code text NOT NULL,
    regulatory_authority_id uuid NOT NULL,
    checkpoint_type text NOT NULL,
    checkpoint_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY public.regulatory_checkpoints FORCE ROW LEVEL SECURITY;


--
-- Name: regulatory_incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regulatory_incidents (
    incident_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    incident_type text NOT NULL,
    detected_at timestamp with time zone NOT NULL,
    description text NOT NULL,
    severity text NOT NULL,
    status text NOT NULL,
    reported_to_boz_at timestamp with time zone,
    boz_reference text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT regulatory_incidents_severity_check CHECK ((severity = ANY (ARRAY['LOW'::text, 'MEDIUM'::text, 'HIGH'::text, 'CRITICAL'::text]))),
    CONSTRAINT regulatory_incidents_status_check CHECK ((status = ANY (ARRAY['OPEN'::text, 'UNDER_INVESTIGATION'::text, 'REPORTED'::text, 'CLOSED'::text])))
);


--
-- Name: regulatory_report_submission_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regulatory_report_submission_attempts (
    attempt_id uuid DEFAULT gen_random_uuid() NOT NULL,
    report_id text NOT NULL,
    endpoint text NOT NULL,
    status text NOT NULL,
    response_code integer,
    attempted_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: regulatory_retraction_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regulatory_retraction_approvals (
    approval_id uuid DEFAULT gen_random_uuid() NOT NULL,
    report_id text NOT NULL,
    approver_role text NOT NULL,
    approval_stage text NOT NULL,
    approved_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: resign_sweeps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resign_sweeps (
    sweep_id uuid DEFAULT gen_random_uuid() NOT NULL,
    sweep_completed_timestamp timestamp with time zone NOT NULL,
    artifacts_resigned_count integer NOT NULL,
    artifacts_with_pending_tier_assignment_cleared boolean DEFAULT false CONSTRAINT resign_sweeps_artifacts_with_pending_tier_assignment_c_not_null NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT resign_sweeps_artifacts_resigned_count_check CHECK ((artifacts_resigned_count >= 0))
);


--
-- Name: retirement_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.retirement_events (
    retirement_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    asset_batch_id uuid NOT NULL,
    retired_quantity numeric NOT NULL,
    retirement_reason text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT retirement_events_retired_quantity_check CHECK ((retired_quantity > (0)::numeric))
);

ALTER TABLE ONLY public.retirement_events FORCE ROW LEVEL SECURITY;


--
-- Name: revoked_client_certs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revoked_client_certs (
    cert_fingerprint_sha256 text NOT NULL,
    revoked_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    reason_code text,
    revoked_by text
);


--
-- Name: revoked_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.revoked_tokens (
    token_jti text NOT NULL,
    revoked_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    reason_code text,
    revoked_by text
);


--
-- Name: risk_formula_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_formula_versions (
    formula_version_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    formula_key text NOT NULL,
    formula_name text NOT NULL,
    tier text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    formula_spec jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT risk_formula_versions_tier_check CHECK ((tier = ANY (ARRAY['TIER1'::text, 'TIER2'::text, 'TIER3'::text])))
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version text NOT NULL,
    checksum text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: signing_audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signing_audit_log (
    sign_event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    caller_id text NOT NULL,
    key_id text NOT NULL,
    key_class public.key_class_enum NOT NULL,
    artifact_type text NOT NULL,
    digest_hash text NOT NULL,
    canonicalization_version text,
    signing_service_id text NOT NULL,
    trust_chain_ref text,
    assurance_tier text NOT NULL,
    signing_path text NOT NULL,
    outcome text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT signing_audit_log_outcome_check CHECK ((outcome = ANY (ARRAY['PASS'::text, 'REJECTED'::text, 'BLOCKED'::text]))),
    CONSTRAINT signing_audit_log_signing_path_check CHECK ((signing_path = ANY (ARRAY['HSM'::text, 'KMS'::text, 'SOFTWARE_BYPASS'::text])))
);


--
-- Name: signing_authorization_matrix; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signing_authorization_matrix (
    matrix_id uuid DEFAULT gen_random_uuid() NOT NULL,
    caller_id text NOT NULL,
    key_class public.key_class_enum NOT NULL,
    permitted_artifact_types text[] DEFAULT '{}'::text[] NOT NULL,
    key_backend text NOT NULL,
    exportable boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT signing_authorization_matrix_key_backend_check CHECK ((key_backend = ANY (ARRAY['HSM'::text, 'KMS'::text, 'SOFTWARE'::text])))
);


--
-- Name: signing_throughput_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signing_throughput_runs (
    run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    target_tps integer NOT NULL,
    achieved_tps integer NOT NULL,
    p95_latency_ms integer NOT NULL,
    pass boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT signing_throughput_runs_achieved_tps_check CHECK ((achieved_tps >= 0)),
    CONSTRAINT signing_throughput_runs_p95_latency_ms_check CHECK ((p95_latency_ms >= 0)),
    CONSTRAINT signing_throughput_runs_target_tps_check CHECK ((target_tps > 0))
);


--
-- Name: sim_swap_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sim_swap_alerts (
    alert_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    member_id uuid NOT NULL,
    source_event_id uuid NOT NULL,
    prior_iccid_hash text NOT NULL,
    new_iccid_hash text NOT NULL,
    formula_version_id uuid NOT NULL,
    alert_type text DEFAULT 'SIM_SWAP_DETECTED'::text NOT NULL,
    derived_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT sim_swap_alerts_alert_type_check CHECK ((alert_type = 'SIM_SWAP_DETECTED'::text)),
    CONSTRAINT sim_swap_alerts_iccid_diff_chk CHECK ((prior_iccid_hash <> new_iccid_hash))
);

ALTER TABLE ONLY public.sim_swap_alerts FORCE ROW LEVEL SECURITY;


--
-- Name: supervisor_access_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supervisor_access_policies (
    scope text NOT NULL,
    description text NOT NULL,
    api_access boolean NOT NULL,
    db_access boolean NOT NULL,
    report_delivery boolean NOT NULL,
    read_window_minutes integer,
    hold_timeout_minutes integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT supervisor_access_policies_hold_timeout_minutes_check CHECK (((hold_timeout_minutes IS NULL) OR (hold_timeout_minutes > 0))),
    CONSTRAINT supervisor_access_policies_read_window_minutes_check CHECK (((read_window_minutes IS NULL) OR (read_window_minutes > 0))),
    CONSTRAINT supervisor_access_policies_scope_check CHECK ((scope = ANY (ARRAY['READ_ONLY'::text, 'AUDIT'::text, 'APPROVAL_REQUIRED'::text])))
);


--
-- Name: supervisor_approval_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supervisor_approval_queue (
    instruction_id text NOT NULL,
    program_id uuid NOT NULL,
    status text NOT NULL,
    held_at timestamp with time zone DEFAULT now() NOT NULL,
    timeout_at timestamp with time zone NOT NULL,
    decided_at timestamp with time zone,
    decided_by text,
    decision_reason text,
    held_reason text,
    submitted_by text,
    approved_by text,
    approved_at timestamp with time zone,
    escalated_at timestamp with time zone,
    reset_at timestamp with time zone,
    resumed_at timestamp with time zone,
    CONSTRAINT supervisor_approval_queue_status_check CHECK ((status = ANY (ARRAY['PENDING_SUPERVISOR_APPROVAL'::text, 'APPROVED'::text, 'REJECTED'::text, 'TIMED_OUT'::text, 'ESCALATED'::text, 'RESET'::text])))
);


--
-- Name: supervisor_audit_member_device_events; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.supervisor_audit_member_device_events AS
 SELECT m.entity_id AS program_id,
    e.tenant_id,
    e.member_id,
    e.instruction_id,
    e.event_type,
    e.observed_at
   FROM (public.member_device_events e
     JOIN public.members m ON ((m.member_id = e.member_id)));


--
-- Name: supervisor_audit_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supervisor_audit_tokens (
    token_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    program_id uuid NOT NULL,
    scope text DEFAULT 'AUDIT'::text NOT NULL,
    token_hash text NOT NULL,
    issued_by text NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT supervisor_audit_tokens_scope_check CHECK ((scope = 'AUDIT'::text))
);


--
-- Name: supervisor_interrupt_audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supervisor_interrupt_audit_events (
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    instruction_id text NOT NULL,
    program_id uuid NOT NULL,
    action text NOT NULL,
    queue_status text NOT NULL,
    actor text NOT NULL,
    reason text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT supervisor_interrupt_audit_events_action_check CHECK ((action = ANY (ARRAY['ESCALATED'::text, 'ACKNOWLEDGED'::text, 'RESUMED'::text, 'RESET'::text]))),
    CONSTRAINT supervisor_interrupt_audit_events_queue_status_check CHECK ((queue_status = ANY (ARRAY['PENDING_SUPERVISOR_APPROVAL'::text, 'APPROVED'::text, 'REJECTED'::text, 'TIMED_OUT'::text, 'ESCALATED'::text, 'RESET'::text])))
);


--
-- Name: supplier_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supplier_registry (
    tenant_id uuid NOT NULL,
    supplier_id text NOT NULL,
    supplier_name text NOT NULL,
    payout_target text NOT NULL,
    registered_latitude numeric,
    registered_longitude numeric,
    active boolean DEFAULT true NOT NULL,
    updated_at_utc text NOT NULL,
    supplier_type text
);

ALTER TABLE ONLY public.supplier_registry FORCE ROW LEVEL SECURITY;


--
-- Name: tenant_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_clients (
    client_id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    client_key text NOT NULL,
    display_name text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tenant_clients_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'REVOKED'::text])))
);

ALTER TABLE ONLY public.tenant_clients FORCE ROW LEVEL SECURITY;


--
-- Name: tenant_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_members (
    member_id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    member_ref text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    tpin_hash bytea,
    msisdn_hash bytea,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tenant_members_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'EXITED'::text])))
);

ALTER TABLE ONLY public.tenant_members FORCE ROW LEVEL SECURITY;


--
-- Name: tenant_program_year_unique_beneficiaries; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.tenant_program_year_unique_beneficiaries AS
 SELECT tenant_id,
    (EXTRACT(year FROM enrolled_at))::integer AS program_year,
    count(DISTINCT person_id) AS unique_beneficiaries
   FROM public.members m
  GROUP BY tenant_id, (EXTRACT(year FROM enrolled_at));


--
-- Name: tenant_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenant_registry (
    id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_key text NOT NULL,
    display_name text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tenant_registry_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
);

ALTER TABLE ONLY public.tenant_registry FORCE ROW LEVEL SECURITY;


--
-- Name: tenants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tenants (
    tenant_id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_key text NOT NULL,
    tenant_name text NOT NULL,
    tenant_type text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    billable_client_id uuid,
    parent_tenant_id uuid,
    CONSTRAINT tenants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text]))),
    CONSTRAINT tenants_tenant_type_check CHECK ((tenant_type = ANY (ARRAY['NGO'::text, 'COOPERATIVE'::text, 'GOVERNMENT'::text, 'COMMERCIAL'::text])))
);

ALTER TABLE ONLY public.tenants FORCE ROW LEVEL SECURITY;


--
-- Name: verifier_project_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verifier_project_assignments (
    assignment_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    verifier_id uuid NOT NULL,
    project_id uuid NOT NULL,
    assigned_role text NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT verifier_project_assignments_assigned_role_check CHECK ((assigned_role = ANY (ARRAY['VALIDATOR'::text, 'VERIFIER'::text])))
);

ALTER TABLE ONLY public.verifier_project_assignments FORCE ROW LEVEL SECURITY;


--
-- Name: verifier_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verifier_registry (
    verifier_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    tenant_id uuid NOT NULL,
    jurisdiction_code text NOT NULL,
    verifier_name text NOT NULL,
    role_type text NOT NULL,
    accreditation_reference text NOT NULL,
    accreditation_authority text NOT NULL,
    accreditation_expiry date NOT NULL,
    methodology_scope jsonb DEFAULT '[]'::jsonb NOT NULL,
    jurisdiction_scope jsonb DEFAULT '[]'::jsonb NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    deactivated_at timestamp with time zone,
    deactivation_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT verifier_deactivation_consistency CHECK ((((is_active = true) AND (deactivated_at IS NULL) AND (deactivation_reason IS NULL)) OR ((is_active = false) AND (deactivated_at IS NOT NULL) AND (deactivation_reason IS NOT NULL)))),
    CONSTRAINT verifier_registry_role_type_check CHECK ((role_type = ANY (ARRAY['VALIDATOR'::text, 'VERIFIER'::text, 'VALIDATOR_VERIFIER'::text])))
);

ALTER TABLE ONLY public.verifier_registry FORCE ROW LEVEL SECURITY;


--
-- Name: adapter_circuit_breakers adapter_circuit_breakers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adapter_circuit_breakers
    ADD CONSTRAINT adapter_circuit_breakers_pkey PRIMARY KEY (adapter_id, rail_id);


--
-- Name: adapter_registrations adapter_registration_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adapter_registrations
    ADD CONSTRAINT adapter_registration_unique UNIQUE (tenant_id, adapter_code, methodology_code, version_code);


--
-- Name: adapter_registrations adapter_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adapter_registrations
    ADD CONSTRAINT adapter_registrations_pkey PRIMARY KEY (adapter_registration_id);


--
-- Name: adjustment_approval_stages adjustment_approval_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_approval_stages
    ADD CONSTRAINT adjustment_approval_stages_pkey PRIMARY KEY (stage_id);


--
-- Name: adjustment_approvals adjustment_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_approvals
    ADD CONSTRAINT adjustment_approvals_pkey PRIMARY KEY (approval_id);


--
-- Name: adjustment_approvals adjustment_approvals_stage_id_approver_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_approvals
    ADD CONSTRAINT adjustment_approvals_stage_id_approver_id_key UNIQUE (stage_id, approver_id);


--
-- Name: adjustment_execution_attempts adjustment_execution_attempts_adjustment_id_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_execution_attempts
    ADD CONSTRAINT adjustment_execution_attempts_adjustment_id_idempotency_key_key UNIQUE (adjustment_id, idempotency_key);


--
-- Name: adjustment_execution_attempts adjustment_execution_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_execution_attempts
    ADD CONSTRAINT adjustment_execution_attempts_pkey PRIMARY KEY (attempt_id);


--
-- Name: adjustment_freeze_flags adjustment_freeze_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_freeze_flags
    ADD CONSTRAINT adjustment_freeze_flags_pkey PRIMARY KEY (flag_id);


--
-- Name: adjustment_instructions adjustment_instructions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_instructions
    ADD CONSTRAINT adjustment_instructions_pkey PRIMARY KEY (adjustment_id);


--
-- Name: anchor_backfill_jobs anchor_backfill_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anchor_backfill_jobs
    ADD CONSTRAINT anchor_backfill_jobs_pkey PRIMARY KEY (job_id);


--
-- Name: anchor_sync_operations anchor_sync_operations_pack_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anchor_sync_operations
    ADD CONSTRAINT anchor_sync_operations_pack_id_key UNIQUE (pack_id);


--
-- Name: anchor_sync_operations anchor_sync_operations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anchor_sync_operations
    ADD CONSTRAINT anchor_sync_operations_pkey PRIMARY KEY (operation_id);


--
-- Name: archive_verification_runs archive_verification_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archive_verification_runs
    ADD CONSTRAINT archive_verification_runs_pkey PRIMARY KEY (run_id);


--
-- Name: artifact_signing_batch_items artifact_signing_batch_items_batch_id_leaf_index_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artifact_signing_batch_items
    ADD CONSTRAINT artifact_signing_batch_items_batch_id_leaf_index_key UNIQUE (batch_id, leaf_index);


--
-- Name: artifact_signing_batch_items artifact_signing_batch_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artifact_signing_batch_items
    ADD CONSTRAINT artifact_signing_batch_items_pkey PRIMARY KEY (item_id);


--
-- Name: artifact_signing_batches artifact_signing_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artifact_signing_batches
    ADD CONSTRAINT artifact_signing_batches_pkey PRIMARY KEY (batch_id);


--
-- Name: asset_batches asset_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_batches
    ADD CONSTRAINT asset_batches_pkey PRIMARY KEY (asset_batch_id);


--
-- Name: asset_lifecycle_events asset_lifecycle_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_lifecycle_events
    ADD CONSTRAINT asset_lifecycle_events_pkey PRIMARY KEY (lifecycle_event_id);


--
-- Name: audit_tamper_evident_chains audit_tamper_evident_chains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_tamper_evident_chains
    ADD CONSTRAINT audit_tamper_evident_chains_pkey PRIMARY KEY (chain_id);


--
-- Name: authority_decisions authority_decisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authority_decisions
    ADD CONSTRAINT authority_decisions_pkey PRIMARY KEY (authority_decision_id);


--
-- Name: billable_clients billable_clients_client_key_required_new_rows_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.billable_clients
    ADD CONSTRAINT billable_clients_client_key_required_new_rows_chk CHECK (((client_key IS NOT NULL) AND (length(btrim(client_key)) > 0))) NOT VALID;


--
-- Name: billable_clients billable_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billable_clients
    ADD CONSTRAINT billable_clients_pkey PRIMARY KEY (billable_client_id);


--
-- Name: billing_usage_events billing_usage_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_usage_events
    ADD CONSTRAINT billing_usage_events_pkey PRIMARY KEY (event_id);


--
-- Name: boz_operational_scenario_runs boz_operational_scenario_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boz_operational_scenario_runs
    ADD CONSTRAINT boz_operational_scenario_runs_pkey PRIMARY KEY (run_id);


--
-- Name: canonicalization_archive_snapshots canonicalization_archive_snap_canonicalization_version_snap_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canonicalization_archive_snapshots
    ADD CONSTRAINT canonicalization_archive_snap_canonicalization_version_snap_key UNIQUE (canonicalization_version, snapshot_sha256);


--
-- Name: canonicalization_archive_snapshots canonicalization_archive_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canonicalization_archive_snapshots
    ADD CONSTRAINT canonicalization_archive_snapshots_pkey PRIMARY KEY (snapshot_id);


--
-- Name: canonicalization_registry canonicalization_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canonicalization_registry
    ADD CONSTRAINT canonicalization_registry_pkey PRIMARY KEY (canonicalization_version);


--
-- Name: dispatch_reference_collision_events dispatch_reference_collision_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_reference_collision_events
    ADD CONSTRAINT dispatch_reference_collision_events_pkey PRIMARY KEY (collision_event_id);


--
-- Name: dispatch_reference_registry dispatch_reference_registry_canon_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_reference_registry
    ADD CONSTRAINT dispatch_reference_registry_canon_unique UNIQUE (rail_id, canonicalized_reference);


--
-- Name: dispatch_reference_registry dispatch_reference_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_reference_registry
    ADD CONSTRAINT dispatch_reference_registry_pkey PRIMARY KEY (registry_id);


--
-- Name: dispatch_reference_registry dispatch_reference_registry_ref_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_reference_registry
    ADD CONSTRAINT dispatch_reference_registry_ref_unique UNIQUE (rail_id, allocated_reference);


--
-- Name: effect_seal_mismatch_events effect_seal_mismatch_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.effect_seal_mismatch_events
    ADD CONSTRAINT effect_seal_mismatch_events_pkey PRIMARY KEY (event_id);


--
-- Name: escrow_accounts escrow_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_accounts
    ADD CONSTRAINT escrow_accounts_pkey PRIMARY KEY (escrow_id);


--
-- Name: escrow_envelopes escrow_envelopes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_envelopes
    ADD CONSTRAINT escrow_envelopes_pkey PRIMARY KEY (escrow_id);


--
-- Name: escrow_events escrow_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_events
    ADD CONSTRAINT escrow_events_pkey PRIMARY KEY (event_id);


--
-- Name: escrow_reservations escrow_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_reservations
    ADD CONSTRAINT escrow_reservations_pkey PRIMARY KEY (reservation_id);


--
-- Name: escrow_reservations escrow_reservations_program_escrow_id_reservation_escrow_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_reservations
    ADD CONSTRAINT escrow_reservations_program_escrow_id_reservation_escrow_id_key UNIQUE (program_escrow_id, reservation_escrow_id);


--
-- Name: escrow_summary_projection escrow_summary_projection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_summary_projection
    ADD CONSTRAINT escrow_summary_projection_pkey PRIMARY KEY (escrow_id);


--
-- Name: evidence_bundle_projection evidence_bundle_projection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_bundle_projection
    ADD CONSTRAINT evidence_bundle_projection_pkey PRIMARY KEY (instruction_id);


--
-- Name: evidence_edges evidence_edges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_edges
    ADD CONSTRAINT evidence_edges_pkey PRIMARY KEY (evidence_edge_id);


--
-- Name: evidence_nodes evidence_nodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_nodes
    ADD CONSTRAINT evidence_nodes_pkey PRIMARY KEY (evidence_node_id);


--
-- Name: evidence_pack_items evidence_pack_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_pack_items
    ADD CONSTRAINT evidence_pack_items_pkey PRIMARY KEY (item_id);


--
-- Name: evidence_packs evidence_packs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_packs
    ADD CONSTRAINT evidence_packs_pkey PRIMARY KEY (pack_id);


--
-- Name: execution_records execution_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.execution_records
    ADD CONSTRAINT execution_records_pkey PRIMARY KEY (execution_id);


--
-- Name: external_proofs external_proofs_billable_client_required_new_rows_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.external_proofs
    ADD CONSTRAINT external_proofs_billable_client_required_new_rows_chk CHECK ((billable_client_id IS NOT NULL)) NOT VALID;


--
-- Name: external_proofs external_proofs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_proofs
    ADD CONSTRAINT external_proofs_pkey PRIMARY KEY (proof_id);


--
-- Name: external_proofs external_proofs_tenant_required_new_rows_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.external_proofs
    ADD CONSTRAINT external_proofs_tenant_required_new_rows_chk CHECK ((tenant_id IS NOT NULL)) NOT VALID;


--
-- Name: gf_verifier_read_tokens gf_verifier_read_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gf_verifier_read_tokens
    ADD CONSTRAINT gf_verifier_read_tokens_pkey PRIMARY KEY (token_id);


--
-- Name: global_rate_limit_policies global_rate_limit_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.global_rate_limit_policies
    ADD CONSTRAINT global_rate_limit_policies_pkey PRIMARY KEY (policy_id);


--
-- Name: historical_verification_runs historical_verification_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historical_verification_runs
    ADD CONSTRAINT historical_verification_runs_pkey PRIMARY KEY (verification_run_id);


--
-- Name: hsm_fail_closed_events hsm_fail_closed_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hsm_fail_closed_events
    ADD CONSTRAINT hsm_fail_closed_events_pkey PRIMARY KEY (event_id);


--
-- Name: incident_case_projection incident_case_projection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_case_projection
    ADD CONSTRAINT incident_case_projection_pkey PRIMARY KEY (incident_id);


--
-- Name: incident_events incident_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_events
    ADD CONSTRAINT incident_events_pkey PRIMARY KEY (incident_event_id);


--
-- Name: ingress_attestations ingress_attestations_correlation_required_new_rows_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.ingress_attestations
    ADD CONSTRAINT ingress_attestations_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;


--
-- Name: ingress_attestations ingress_attestations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingress_attestations
    ADD CONSTRAINT ingress_attestations_pkey PRIMARY KEY (attestation_id);


--
-- Name: inquiry_state_machine inquiry_state_machine_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inquiry_state_machine
    ADD CONSTRAINT inquiry_state_machine_pkey PRIMARY KEY (instruction_id);


--
-- Name: instruction_effect_seals instruction_effect_seals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_effect_seals
    ADD CONSTRAINT instruction_effect_seals_pkey PRIMARY KEY (instruction_id);


--
-- Name: instruction_finality_conflicts instruction_finality_conflicts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_finality_conflicts
    ADD CONSTRAINT instruction_finality_conflicts_pkey PRIMARY KEY (instruction_id);


--
-- Name: instruction_settlement_finality instruction_settlement_finality_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_settlement_finality
    ADD CONSTRAINT instruction_settlement_finality_pkey PRIMARY KEY (finality_id);


--
-- Name: instruction_status_projection instruction_status_projection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_status_projection
    ADD CONSTRAINT instruction_status_projection_pkey PRIMARY KEY (instruction_id);


--
-- Name: internal_ledger_journals internal_ledger_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_ledger_journals
    ADD CONSTRAINT internal_ledger_journals_pkey PRIMARY KEY (journal_id);


--
-- Name: internal_ledger_journals internal_ledger_journals_tenant_id_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_ledger_journals
    ADD CONSTRAINT internal_ledger_journals_tenant_id_idempotency_key_key UNIQUE (tenant_id, idempotency_key);


--
-- Name: internal_ledger_postings internal_ledger_postings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_ledger_postings
    ADD CONSTRAINT internal_ledger_postings_pkey PRIMARY KEY (posting_id);


--
-- Name: interpretation_packs interpretation_packs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interpretation_packs
    ADD CONSTRAINT interpretation_packs_pkey PRIMARY KEY (interpretation_pack_id);


--
-- Name: jurisdiction_profiles jurisdiction_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jurisdiction_profiles
    ADD CONSTRAINT jurisdiction_profiles_pkey PRIMARY KEY (jurisdiction_profile_id);


--
-- Name: key_rotation_drills key_rotation_drills_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.key_rotation_drills
    ADD CONSTRAINT key_rotation_drills_pkey PRIMARY KEY (drill_id);


--
-- Name: kyc_provider_registry kyc_provider_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_provider_registry
    ADD CONSTRAINT kyc_provider_registry_pkey PRIMARY KEY (id);


--
-- Name: kyc_provider_registry kyc_provider_unique_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_provider_registry
    ADD CONSTRAINT kyc_provider_unique_code UNIQUE (provider_code);


--
-- Name: kyc_retention_policy kyc_retention_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_retention_policy
    ADD CONSTRAINT kyc_retention_policy_pkey PRIMARY KEY (id);


--
-- Name: kyc_retention_policy kyc_retention_unique_active_class; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_retention_policy
    ADD CONSTRAINT kyc_retention_unique_active_class UNIQUE (jurisdiction_code, retention_class);


--
-- Name: kyc_verification_records kyc_verification_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_verification_records
    ADD CONSTRAINT kyc_verification_records_pkey PRIMARY KEY (id);


--
-- Name: levy_calculation_records levy_calculation_one_per_instruction; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levy_calculation_records
    ADD CONSTRAINT levy_calculation_one_per_instruction UNIQUE (instruction_id);


--
-- Name: levy_calculation_records levy_calculation_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levy_calculation_records
    ADD CONSTRAINT levy_calculation_records_pkey PRIMARY KEY (id);


--
-- Name: levy_remittance_periods levy_periods_unique_period_jurisdiction; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levy_remittance_periods
    ADD CONSTRAINT levy_periods_unique_period_jurisdiction UNIQUE (period_code, jurisdiction_code);


--
-- Name: levy_rates levy_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levy_rates
    ADD CONSTRAINT levy_rates_pkey PRIMARY KEY (id);


--
-- Name: levy_remittance_periods levy_remittance_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levy_remittance_periods
    ADD CONSTRAINT levy_remittance_periods_pkey PRIMARY KEY (id);


--
-- Name: lifecycle_checkpoint_rules lifecycle_checkpoint_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lifecycle_checkpoint_rules
    ADD CONSTRAINT lifecycle_checkpoint_rules_pkey PRIMARY KEY (lifecycle_checkpoint_rule_id);


--
-- Name: malformed_quarantine_store malformed_quarantine_store_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.malformed_quarantine_store
    ADD CONSTRAINT malformed_quarantine_store_pkey PRIMARY KEY (quarantine_id);


--
-- Name: member_device_events member_device_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_device_events
    ADD CONSTRAINT member_device_events_pkey PRIMARY KEY (event_id);


--
-- Name: member_devices member_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_devices
    ADD CONSTRAINT member_devices_pkey PRIMARY KEY (member_id, device_id_hash);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (member_id);


--
-- Name: members members_tenant_id_member_ref_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_tenant_id_member_ref_hash_key UNIQUE (tenant_id, member_ref_hash);


--
-- Name: members members_tenant_id_person_id_entity_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_tenant_id_person_id_entity_id_key UNIQUE (tenant_id, person_id, entity_id);


--
-- Name: methodology_versions methodology_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.methodology_versions
    ADD CONSTRAINT methodology_versions_pkey PRIMARY KEY (methodology_version_id);


--
-- Name: mmo_reality_control_events mmo_reality_control_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mmo_reality_control_events
    ADD CONSTRAINT mmo_reality_control_events_pkey PRIMARY KEY (event_id);


--
-- Name: monitoring_records monitoring_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_records
    ADD CONSTRAINT monitoring_records_pkey PRIMARY KEY (monitoring_record_id);


--
-- Name: offline_safe_mode_windows offline_safe_mode_windows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_safe_mode_windows
    ADD CONSTRAINT offline_safe_mode_windows_pkey PRIMARY KEY (window_id);


--
-- Name: orphaned_attestation_landing_zone orphaned_attestation_landing_zone_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orphaned_attestation_landing_zone
    ADD CONSTRAINT orphaned_attestation_landing_zone_pkey PRIMARY KEY (orphan_id);


--
-- Name: participant_outbox_sequences participant_outbox_sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participant_outbox_sequences
    ADD CONSTRAINT participant_outbox_sequences_pkey PRIMARY KEY (participant_id);


--
-- Name: participants participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participants
    ADD CONSTRAINT participants_pkey PRIMARY KEY (participant_id);


--
-- Name: payment_outbox_attempts payment_outbox_attempts_correlation_required_new_rows_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.payment_outbox_attempts
    ADD CONSTRAINT payment_outbox_attempts_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;


--
-- Name: payment_outbox_attempts payment_outbox_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_attempts
    ADD CONSTRAINT payment_outbox_attempts_pkey PRIMARY KEY (attempt_id);


--
-- Name: payment_outbox_pending payment_outbox_pending_correlation_required_new_rows_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.payment_outbox_pending
    ADD CONSTRAINT payment_outbox_pending_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;


--
-- Name: payment_outbox_pending payment_outbox_pending_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_pending
    ADD CONSTRAINT payment_outbox_pending_pkey PRIMARY KEY (outbox_id);


--
-- Name: penalty_defense_packs penalty_defense_packs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.penalty_defense_packs
    ADD CONSTRAINT penalty_defense_packs_pkey PRIMARY KEY (pack_id);


--
-- Name: persons persons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_pkey PRIMARY KEY (person_id);


--
-- Name: pii_erased_subject_placeholders pii_erased_subject_placeholders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_erased_subject_placeholders
    ADD CONSTRAINT pii_erased_subject_placeholders_pkey PRIMARY KEY (placeholder_id);


--
-- Name: pii_erased_subject_placeholders pii_erased_subject_placeholders_placeholder_ref_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_erased_subject_placeholders
    ADD CONSTRAINT pii_erased_subject_placeholders_placeholder_ref_key UNIQUE (placeholder_ref);


--
-- Name: pii_erasure_journal pii_erasure_journal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_erasure_journal
    ADD CONSTRAINT pii_erasure_journal_pkey PRIMARY KEY (erasure_id);


--
-- Name: pii_purge_events pii_purge_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_purge_events
    ADD CONSTRAINT pii_purge_events_pkey PRIMARY KEY (purge_event_id);


--
-- Name: pii_purge_requests pii_purge_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_purge_requests
    ADD CONSTRAINT pii_purge_requests_pkey PRIMARY KEY (purge_request_id);


--
-- Name: pii_tokenization_registry pii_tokenization_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_tokenization_registry
    ADD CONSTRAINT pii_tokenization_registry_pkey PRIMARY KEY (token_id);


--
-- Name: pii_tokenization_registry pii_tokenization_registry_token_value_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_tokenization_registry
    ADD CONSTRAINT pii_tokenization_registry_token_value_key UNIQUE (token_value);


--
-- Name: pii_vault_records pii_vault_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_vault_records
    ADD CONSTRAINT pii_vault_records_pkey PRIMARY KEY (vault_id);


--
-- Name: policy_bundles policy_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_bundles
    ADD CONSTRAINT policy_bundles_pkey PRIMARY KEY (policy_bundle_id);


--
-- Name: policy_bundles policy_bundles_policy_id_policy_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_bundles
    ADD CONSTRAINT policy_bundles_policy_id_policy_version_key UNIQUE (policy_id, policy_version);


--
-- Name: policy_versions policy_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_versions
    ADD CONSTRAINT policy_versions_pkey PRIMARY KEY (version);


--
-- Name: program_member_summary_projection program_member_summary_projection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_member_summary_projection
    ADD CONSTRAINT program_member_summary_projection_pkey PRIMARY KEY (tenant_id, program_id);


--
-- Name: program_migration_events program_migration_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_migration_events
    ADD CONSTRAINT program_migration_events_pkey PRIMARY KEY (migration_event_id);


--
-- Name: program_supplier_allowlist program_supplier_allowlist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_supplier_allowlist
    ADD CONSTRAINT program_supplier_allowlist_pkey PRIMARY KEY (tenant_id, program_id, supplier_id);


--
-- Name: programme_policy_binding programme_policy_binding_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_policy_binding
    ADD CONSTRAINT programme_policy_binding_pkey PRIMARY KEY (id);


--
-- Name: programme_policy_binding programme_policy_binding_programme_id_is_active_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_policy_binding
    ADD CONSTRAINT programme_policy_binding_programme_id_is_active_key UNIQUE (programme_id, is_active);


--
-- Name: programme_registry programme_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_registry
    ADD CONSTRAINT programme_registry_pkey PRIMARY KEY (id);


--
-- Name: programme_registry programme_registry_tenant_id_programme_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_registry
    ADD CONSTRAINT programme_registry_tenant_id_programme_key_key UNIQUE (tenant_id, programme_key);


--
-- Name: programs programs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_pkey PRIMARY KEY (program_id);


--
-- Name: programs programs_tenant_id_program_escrow_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_tenant_id_program_escrow_id_key UNIQUE (tenant_id, program_escrow_id);


--
-- Name: programs programs_tenant_id_program_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_tenant_id_program_key_key UNIQUE (tenant_id, program_key);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);


--
-- Name: proof_pack_batch_leaves proof_pack_batch_leaves_batch_id_leaf_index_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proof_pack_batch_leaves
    ADD CONSTRAINT proof_pack_batch_leaves_batch_id_leaf_index_key UNIQUE (batch_id, leaf_index);


--
-- Name: proof_pack_batch_leaves proof_pack_batch_leaves_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proof_pack_batch_leaves
    ADD CONSTRAINT proof_pack_batch_leaves_pkey PRIMARY KEY (leaf_id);


--
-- Name: proof_pack_batches proof_pack_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proof_pack_batches
    ADD CONSTRAINT proof_pack_batches_pkey PRIMARY KEY (batch_id);


--
-- Name: rail_dispatch_truth_anchor rail_dispatch_truth_anchor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rail_dispatch_truth_anchor
    ADD CONSTRAINT rail_dispatch_truth_anchor_pkey PRIMARY KEY (anchor_id);


--
-- Name: redaction_audit_events redaction_audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.redaction_audit_events
    ADD CONSTRAINT redaction_audit_events_pkey PRIMARY KEY (event_id);


--
-- Name: reference_strategy_policy_versions reference_strategy_policy_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference_strategy_policy_versions
    ADD CONSTRAINT reference_strategy_policy_versions_pkey PRIMARY KEY (policy_version_id);


--
-- Name: regulatory_authorities regulatory_authorities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_authorities
    ADD CONSTRAINT regulatory_authorities_pkey PRIMARY KEY (regulatory_authority_id);


--
-- Name: regulatory_checkpoints regulatory_checkpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_checkpoints
    ADD CONSTRAINT regulatory_checkpoints_pkey PRIMARY KEY (regulatory_checkpoint_id);


--
-- Name: regulatory_incidents regulatory_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_incidents
    ADD CONSTRAINT regulatory_incidents_pkey PRIMARY KEY (incident_id);


--
-- Name: regulatory_report_submission_attempts regulatory_report_submission_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_report_submission_attempts
    ADD CONSTRAINT regulatory_report_submission_attempts_pkey PRIMARY KEY (attempt_id);


--
-- Name: regulatory_retraction_approvals regulatory_retraction_approva_report_id_approver_role_appro_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_retraction_approvals
    ADD CONSTRAINT regulatory_retraction_approva_report_id_approver_role_appro_key UNIQUE (report_id, approver_role, approval_stage);


--
-- Name: regulatory_retraction_approvals regulatory_retraction_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_retraction_approvals
    ADD CONSTRAINT regulatory_retraction_approvals_pkey PRIMARY KEY (approval_id);


--
-- Name: resign_sweeps resign_sweeps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resign_sweeps
    ADD CONSTRAINT resign_sweeps_pkey PRIMARY KEY (sweep_id);


--
-- Name: retirement_events retirement_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retirement_events
    ADD CONSTRAINT retirement_events_pkey PRIMARY KEY (retirement_event_id);


--
-- Name: revoked_client_certs revoked_client_certs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revoked_client_certs
    ADD CONSTRAINT revoked_client_certs_pkey PRIMARY KEY (cert_fingerprint_sha256);


--
-- Name: revoked_tokens revoked_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.revoked_tokens
    ADD CONSTRAINT revoked_tokens_pkey PRIMARY KEY (token_jti);


--
-- Name: risk_formula_versions risk_formula_versions_formula_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_formula_versions
    ADD CONSTRAINT risk_formula_versions_formula_key_key UNIQUE (formula_key);


--
-- Name: risk_formula_versions risk_formula_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_formula_versions
    ADD CONSTRAINT risk_formula_versions_pkey PRIMARY KEY (formula_version_id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: signing_audit_log signing_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signing_audit_log
    ADD CONSTRAINT signing_audit_log_pkey PRIMARY KEY (sign_event_id);


--
-- Name: signing_authorization_matrix signing_authorization_matrix_caller_id_key_class_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signing_authorization_matrix
    ADD CONSTRAINT signing_authorization_matrix_caller_id_key_class_key UNIQUE (caller_id, key_class);


--
-- Name: signing_authorization_matrix signing_authorization_matrix_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signing_authorization_matrix
    ADD CONSTRAINT signing_authorization_matrix_pkey PRIMARY KEY (matrix_id);


--
-- Name: signing_throughput_runs signing_throughput_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signing_throughput_runs
    ADD CONSTRAINT signing_throughput_runs_pkey PRIMARY KEY (run_id);


--
-- Name: sim_swap_alerts sim_swap_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sim_swap_alerts
    ADD CONSTRAINT sim_swap_alerts_pkey PRIMARY KEY (alert_id);


--
-- Name: sim_swap_alerts sim_swap_alerts_source_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sim_swap_alerts
    ADD CONSTRAINT sim_swap_alerts_source_event_id_key UNIQUE (source_event_id);


--
-- Name: supervisor_access_policies supervisor_access_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisor_access_policies
    ADD CONSTRAINT supervisor_access_policies_pkey PRIMARY KEY (scope);


--
-- Name: supervisor_approval_queue supervisor_approval_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisor_approval_queue
    ADD CONSTRAINT supervisor_approval_queue_pkey PRIMARY KEY (instruction_id);


--
-- Name: supervisor_audit_tokens supervisor_audit_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisor_audit_tokens
    ADD CONSTRAINT supervisor_audit_tokens_pkey PRIMARY KEY (token_id);


--
-- Name: supervisor_audit_tokens supervisor_audit_tokens_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisor_audit_tokens
    ADD CONSTRAINT supervisor_audit_tokens_token_hash_key UNIQUE (token_hash);


--
-- Name: supervisor_interrupt_audit_events supervisor_interrupt_audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisor_interrupt_audit_events
    ADD CONSTRAINT supervisor_interrupt_audit_events_pkey PRIMARY KEY (event_id);


--
-- Name: supplier_registry supplier_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_registry
    ADD CONSTRAINT supplier_registry_pkey PRIMARY KEY (tenant_id, supplier_id);


--
-- Name: tenant_clients tenant_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_clients
    ADD CONSTRAINT tenant_clients_pkey PRIMARY KEY (client_id);


--
-- Name: tenant_clients tenant_clients_tenant_id_client_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_clients
    ADD CONSTRAINT tenant_clients_tenant_id_client_key_key UNIQUE (tenant_id, client_key);


--
-- Name: tenant_members tenant_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_members
    ADD CONSTRAINT tenant_members_pkey PRIMARY KEY (member_id);


--
-- Name: tenant_members tenant_members_tenant_id_member_ref_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_members
    ADD CONSTRAINT tenant_members_tenant_id_member_ref_key UNIQUE (tenant_id, member_ref);


--
-- Name: tenant_registry tenant_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_registry
    ADD CONSTRAINT tenant_registry_pkey PRIMARY KEY (id);


--
-- Name: tenant_registry tenant_registry_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_registry
    ADD CONSTRAINT tenant_registry_tenant_id_key UNIQUE (tenant_id);


--
-- Name: tenant_registry tenant_registry_tenant_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_registry
    ADD CONSTRAINT tenant_registry_tenant_key_key UNIQUE (tenant_key);


--
-- Name: tenants tenants_billable_client_required_new_rows_chk; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.tenants
    ADD CONSTRAINT tenants_billable_client_required_new_rows_chk CHECK ((billable_client_id IS NOT NULL)) NOT VALID;


--
-- Name: tenants tenants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (tenant_id);


--
-- Name: tenants tenants_tenant_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_tenant_key_key UNIQUE (tenant_key);


--
-- Name: payment_outbox_attempts ux_attempts_outbox_attempt_no; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_attempts
    ADD CONSTRAINT ux_attempts_outbox_attempt_no UNIQUE (outbox_id, attempt_no);


--
-- Name: billable_clients ux_billable_clients_client_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billable_clients
    ADD CONSTRAINT ux_billable_clients_client_key UNIQUE (client_key);


--
-- Name: evidence_pack_items ux_evidence_pack_items_pack_hash; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_pack_items
    ADD CONSTRAINT ux_evidence_pack_items_pack_hash UNIQUE (pack_id, artifact_hash);


--
-- Name: instruction_settlement_finality ux_instruction_settlement_finality_instruction; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_settlement_finality
    ADD CONSTRAINT ux_instruction_settlement_finality_instruction UNIQUE (instruction_id);


--
-- Name: payment_outbox_pending ux_pending_idempotency; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_pending
    ADD CONSTRAINT ux_pending_idempotency UNIQUE (instruction_id, idempotency_key);


--
-- Name: payment_outbox_pending ux_pending_participant_sequence; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_pending
    ADD CONSTRAINT ux_pending_participant_sequence UNIQUE (participant_id, sequence_id);


--
-- Name: pii_purge_events ux_pii_purge_events_request_event; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_purge_events
    ADD CONSTRAINT ux_pii_purge_events_request_event UNIQUE (purge_request_id, event_type);


--
-- Name: pii_vault_records ux_pii_vault_records_subject_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_vault_records
    ADD CONSTRAINT ux_pii_vault_records_subject_token UNIQUE (subject_token);


--
-- Name: rail_dispatch_truth_anchor ux_rail_truth_anchor_attempt_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rail_dispatch_truth_anchor
    ADD CONSTRAINT ux_rail_truth_anchor_attempt_id UNIQUE (attempt_id);


--
-- Name: rail_dispatch_truth_anchor ux_rail_truth_anchor_sequence_scope; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rail_dispatch_truth_anchor
    ADD CONSTRAINT ux_rail_truth_anchor_sequence_scope UNIQUE (rail_sequence_ref, rail_participant_id, rail_profile);


--
-- Name: verifier_project_assignments verifier_project_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifier_project_assignments
    ADD CONSTRAINT verifier_project_assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: verifier_project_assignments verifier_project_role_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifier_project_assignments
    ADD CONSTRAINT verifier_project_role_unique UNIQUE (verifier_id, project_id, assigned_role);


--
-- Name: verifier_registry verifier_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifier_registry
    ADD CONSTRAINT verifier_registry_pkey PRIMARY KEY (verifier_id);


--
-- Name: idx_adapter_registrations_adapter_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_adapter_registrations_adapter_code ON public.adapter_registrations USING btree (adapter_code);


--
-- Name: idx_adapter_registrations_methodology; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_adapter_registrations_methodology ON public.adapter_registrations USING btree (methodology_code, methodology_authority);


--
-- Name: idx_adapter_registrations_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_adapter_registrations_tenant_id ON public.adapter_registrations USING btree (tenant_id);


--
-- Name: idx_anchor_sync_operations_state_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_anchor_sync_operations_state_due ON public.anchor_sync_operations USING btree (state, lease_expires_at, updated_at);


--
-- Name: idx_asset_batches_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asset_batches_project_id ON public.asset_batches USING btree (project_id);


--
-- Name: idx_asset_batches_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asset_batches_tenant_id ON public.asset_batches USING btree (tenant_id);


--
-- Name: idx_asset_lifecycle_events_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asset_lifecycle_events_batch_id ON public.asset_lifecycle_events USING btree (asset_batch_id);


--
-- Name: idx_asset_lifecycle_events_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_asset_lifecycle_events_tenant_id ON public.asset_lifecycle_events USING btree (tenant_id);


--
-- Name: idx_attempts_instruction_idempotency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attempts_instruction_idempotency ON public.payment_outbox_attempts USING btree (instruction_id, idempotency_key);


--
-- Name: idx_attempts_outbox_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attempts_outbox_id ON public.payment_outbox_attempts USING btree (outbox_id);


--
-- Name: idx_authority_decisions_jurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_authority_decisions_jurisdiction ON public.authority_decisions USING btree (jurisdiction_code);


--
-- Name: idx_billing_usage_events_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_billing_usage_events_correlation_id ON public.billing_usage_events USING btree (correlation_id);


--
-- Name: idx_dispatch_reference_collision_events_instruction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dispatch_reference_collision_events_instruction ON public.dispatch_reference_collision_events USING btree (instruction_id, created_at DESC);


--
-- Name: idx_dispatch_reference_registry_adjustment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dispatch_reference_registry_adjustment ON public.dispatch_reference_registry USING btree (adjustment_id, allocation_timestamp DESC);


--
-- Name: idx_dispatch_reference_registry_instruction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dispatch_reference_registry_instruction ON public.dispatch_reference_registry USING btree (instruction_id, allocation_timestamp DESC);


--
-- Name: idx_escrow_accounts_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_escrow_accounts_program ON public.escrow_accounts USING btree (program_id) WHERE (program_id IS NOT NULL);


--
-- Name: idx_escrow_accounts_tenant_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_escrow_accounts_tenant_state ON public.escrow_accounts USING btree (tenant_id, state, authorization_expires_at, release_due_at);


--
-- Name: idx_escrow_envelopes_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_escrow_envelopes_tenant ON public.escrow_envelopes USING btree (tenant_id);


--
-- Name: idx_escrow_events_escrow_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_escrow_events_escrow_created ON public.escrow_events USING btree (escrow_id, created_at);


--
-- Name: idx_escrow_reservations_tenant_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_escrow_reservations_tenant_program ON public.escrow_reservations USING btree (tenant_id, program_escrow_id, created_at);


--
-- Name: idx_evidence_edges_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_edges_source ON public.evidence_edges USING btree (source_node_id);


--
-- Name: idx_evidence_edges_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_edges_target ON public.evidence_edges USING btree (target_node_id);


--
-- Name: idx_evidence_edges_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_edges_tenant_id ON public.evidence_edges USING btree (tenant_id);


--
-- Name: idx_evidence_nodes_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_nodes_project_id ON public.evidence_nodes USING btree (project_id);


--
-- Name: idx_evidence_nodes_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_nodes_tenant_id ON public.evidence_nodes USING btree (tenant_id);


--
-- Name: idx_evidence_packs_anchor_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_packs_anchor_ref ON public.evidence_packs USING btree (anchor_ref) WHERE (anchor_ref IS NOT NULL);


--
-- Name: idx_evidence_packs_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_packs_correlation_id ON public.evidence_packs USING btree (correlation_id);


--
-- Name: idx_execution_records_interpretation_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_execution_records_interpretation_version_id ON public.execution_records USING btree (interpretation_version_id);


--
-- Name: idx_execution_records_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_execution_records_project_id ON public.execution_records USING btree (project_id);


--
-- Name: idx_execution_records_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_execution_records_timestamp ON public.execution_records USING btree (execution_timestamp);


--
-- Name: idx_external_proofs_attestation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_proofs_attestation_id ON public.external_proofs USING btree (attestation_id);


--
-- Name: idx_gf_verifier_read_tokens_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gf_verifier_read_tokens_expires ON public.gf_verifier_read_tokens USING btree (expires_at);


--
-- Name: idx_gf_verifier_read_tokens_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gf_verifier_read_tokens_hash ON public.gf_verifier_read_tokens USING btree (token_hash);


--
-- Name: idx_gf_verifier_read_tokens_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gf_verifier_read_tokens_project ON public.gf_verifier_read_tokens USING btree (project_id);


--
-- Name: idx_gf_verifier_read_tokens_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gf_verifier_read_tokens_tenant ON public.gf_verifier_read_tokens USING btree (tenant_id);


--
-- Name: idx_gf_verifier_read_tokens_verifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_gf_verifier_read_tokens_verifier ON public.gf_verifier_read_tokens USING btree (verifier_id);


--
-- Name: idx_ingress_attestations_cert_fpr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_cert_fpr ON public.ingress_attestations USING btree (cert_fingerprint_sha256) WHERE (cert_fingerprint_sha256 IS NOT NULL);


--
-- Name: idx_ingress_attestations_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_correlation_id ON public.ingress_attestations USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);


--
-- Name: idx_ingress_attestations_instruction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_instruction ON public.ingress_attestations USING btree (instruction_id);


--
-- Name: idx_ingress_attestations_member_received; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_member_received ON public.ingress_attestations USING btree (member_id, received_at) WHERE (member_id IS NOT NULL);


--
-- Name: idx_ingress_attestations_received_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_received_at ON public.ingress_attestations USING btree (received_at);


--
-- Name: idx_ingress_attestations_tenant_correlation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_tenant_correlation ON public.ingress_attestations USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);


--
-- Name: idx_ingress_attestations_tenant_received; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_tenant_received ON public.ingress_attestations USING btree (tenant_id, received_at) WHERE (tenant_id IS NOT NULL);


--
-- Name: idx_instruction_settlement_finality_participant_finalized; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_instruction_settlement_finality_participant_finalized ON public.instruction_settlement_finality USING btree (participant_id, finalized_at DESC);


--
-- Name: idx_internal_ledger_postings_journal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_internal_ledger_postings_journal ON public.internal_ledger_postings USING btree (journal_id, direction);


--
-- Name: idx_interpretation_packs_jurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_interpretation_packs_jurisdiction ON public.interpretation_packs USING btree (jurisdiction_code);


--
-- Name: idx_jurisdiction_profiles_jurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_jurisdiction_profiles_jurisdiction ON public.jurisdiction_profiles USING btree (jurisdiction_code);


--
-- Name: idx_lifecycle_checkpoint_rules_jurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lifecycle_checkpoint_rules_jurisdiction ON public.lifecycle_checkpoint_rules USING btree (jurisdiction_code);


--
-- Name: idx_malformed_quarantine_adapter_rail_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_malformed_quarantine_adapter_rail_time ON public.malformed_quarantine_store USING btree (adapter_id, rail_id, capture_timestamp DESC);


--
-- Name: idx_member_device_events_instruction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_device_events_instruction ON public.member_device_events USING btree (instruction_id);


--
-- Name: idx_member_device_events_tenant_member_observed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_device_events_tenant_member_observed ON public.member_device_events USING btree (tenant_id, member_id, observed_at DESC);


--
-- Name: idx_member_devices_active_device; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_devices_active_device ON public.member_devices USING btree (tenant_id, device_id_hash) WHERE (status = 'ACTIVE'::text);


--
-- Name: idx_member_devices_active_iccid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_devices_active_iccid ON public.member_devices USING btree (tenant_id, iccid_hash) WHERE ((iccid_hash IS NOT NULL) AND (status = 'ACTIVE'::text));


--
-- Name: idx_member_devices_tenant_member; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_devices_tenant_member ON public.member_devices USING btree (tenant_id, member_id);


--
-- Name: idx_members_entity_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_members_entity_active ON public.members USING btree (tenant_id, entity_id, status) WHERE (status = 'ACTIVE'::text);


--
-- Name: idx_members_entity_member_ref_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_members_entity_member_ref_active ON public.members USING btree (tenant_id, entity_id, member_ref_hash) WHERE (status = 'ACTIVE'::text);


--
-- Name: idx_members_tenant_member; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_members_tenant_member ON public.members USING btree (tenant_id, member_id);


--
-- Name: idx_members_tenant_member_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_members_tenant_member_ref ON public.members USING btree (tenant_id, member_ref_hash);


--
-- Name: idx_methodology_versions_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_methodology_versions_tenant_id ON public.methodology_versions USING btree (tenant_id);


--
-- Name: idx_monitoring_records_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_monitoring_records_project_id ON public.monitoring_records USING btree (project_id);


--
-- Name: idx_monitoring_records_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_monitoring_records_tenant_id ON public.monitoring_records USING btree (tenant_id);


--
-- Name: idx_orphan_lz_instruction_arrival; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_orphan_lz_instruction_arrival ON public.orphaned_attestation_landing_zone USING btree (instruction_id, arrival_timestamp DESC);


--
-- Name: idx_payment_outbox_attempts_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_outbox_attempts_correlation_id ON public.payment_outbox_attempts USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);


--
-- Name: idx_payment_outbox_attempts_tenant_correlation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_outbox_attempts_tenant_correlation ON public.payment_outbox_attempts USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);


--
-- Name: idx_payment_outbox_pending_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_outbox_pending_correlation_id ON public.payment_outbox_pending USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);


--
-- Name: idx_payment_outbox_pending_due_claim; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_outbox_pending_due_claim ON public.payment_outbox_pending USING btree (next_attempt_at, lease_expires_at, created_at);


--
-- Name: idx_payment_outbox_pending_tenant_correlation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_outbox_pending_tenant_correlation ON public.payment_outbox_pending USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);


--
-- Name: idx_payment_outbox_pending_tenant_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_outbox_pending_tenant_due ON public.payment_outbox_pending USING btree (tenant_id, next_attempt_at) WHERE (tenant_id IS NOT NULL);


--
-- Name: idx_persons_tenant_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_persons_tenant_ref ON public.persons USING btree (tenant_id, person_ref_hash);


--
-- Name: idx_pii_purge_requests_subject_requested; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pii_purge_requests_subject_requested ON public.pii_purge_requests USING btree (subject_token, requested_at DESC);


--
-- Name: idx_policy_versions_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_policy_versions_is_active ON public.policy_versions USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_program_migration_events_tenant_person; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_program_migration_events_tenant_person ON public.program_migration_events USING btree (tenant_id, person_id, migrated_at DESC);


--
-- Name: idx_program_migration_events_tenant_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_program_migration_events_tenant_time ON public.program_migration_events USING btree (tenant_id, migrated_at DESC);


--
-- Name: idx_programs_tenant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_programs_tenant_status ON public.programs USING btree (tenant_id, status);


--
-- Name: idx_projects_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_tenant_id ON public.projects USING btree (tenant_id);


--
-- Name: idx_rail_truth_anchor_participant_anchored; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rail_truth_anchor_participant_anchored ON public.rail_dispatch_truth_anchor USING btree (rail_participant_id, anchored_at DESC);


--
-- Name: idx_reference_strategy_policy_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_reference_strategy_policy_active ON public.reference_strategy_policy_versions USING btree (version_status) WHERE (version_status = 'ACTIVE'::text);


--
-- Name: idx_regulatory_authorities_jurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_regulatory_authorities_jurisdiction ON public.regulatory_authorities USING btree (jurisdiction_code);


--
-- Name: idx_regulatory_checkpoints_jurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_regulatory_checkpoints_jurisdiction ON public.regulatory_checkpoints USING btree (jurisdiction_code);


--
-- Name: idx_retirement_events_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_retirement_events_batch_id ON public.retirement_events USING btree (asset_batch_id);


--
-- Name: idx_retirement_events_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_retirement_events_tenant_id ON public.retirement_events USING btree (tenant_id);


--
-- Name: idx_sim_swap_alerts_tenant_member_derived; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sim_swap_alerts_tenant_member_derived ON public.sim_swap_alerts USING btree (tenant_id, member_id, derived_at DESC);


--
-- Name: idx_supervisor_approval_queue_status_timeout; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_supervisor_approval_queue_status_timeout ON public.supervisor_approval_queue USING btree (status, timeout_at);


--
-- Name: idx_supervisor_audit_tokens_program_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_supervisor_audit_tokens_program_expires ON public.supervisor_audit_tokens USING btree (program_id, expires_at DESC);


--
-- Name: idx_supervisor_interrupt_audit_events_instruction_recorded; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_supervisor_interrupt_audit_events_instruction_recorded ON public.supervisor_interrupt_audit_events USING btree (instruction_id, recorded_at DESC);


--
-- Name: idx_tenant_clients_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_clients_tenant ON public.tenant_clients USING btree (tenant_id);


--
-- Name: idx_tenant_members_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_members_status ON public.tenant_members USING btree (status);


--
-- Name: idx_tenant_members_tenant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenant_members_tenant ON public.tenant_members USING btree (tenant_id);


--
-- Name: idx_tenants_billable_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenants_billable_client_id ON public.tenants USING btree (billable_client_id);


--
-- Name: idx_tenants_parent_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenants_parent_tenant_id ON public.tenants USING btree (parent_tenant_id);


--
-- Name: idx_tenants_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenants_status ON public.tenants USING btree (status);


--
-- Name: idx_verifier_project_assignments_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verifier_project_assignments_project ON public.verifier_project_assignments USING btree (project_id);


--
-- Name: idx_verifier_project_assignments_verifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verifier_project_assignments_verifier ON public.verifier_project_assignments USING btree (verifier_id);


--
-- Name: idx_verifier_registry_jurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verifier_registry_jurisdiction ON public.verifier_registry USING btree (jurisdiction_code);


--
-- Name: idx_verifier_registry_tenant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_verifier_registry_tenant_id ON public.verifier_registry USING btree (tenant_id);


--
-- Name: ix_incident_events_incident_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_incident_events_incident_created ON public.incident_events USING btree (incident_id, created_at);


--
-- Name: ix_regulatory_incidents_tenant_detected; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_regulatory_incidents_tenant_detected ON public.regulatory_incidents USING btree (tenant_id, detected_at DESC);


--
-- Name: kyc_provider_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX kyc_provider_active_idx ON public.kyc_provider_registry USING btree (jurisdiction_code, provider_code) WHERE ((active_to IS NULL) AND (is_active IS NOT FALSE));


--
-- Name: kyc_provider_jurisdiction_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kyc_provider_jurisdiction_idx ON public.kyc_provider_registry USING btree (jurisdiction_code, active_from DESC);


--
-- Name: kyc_verification_jurisdiction_outcome_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kyc_verification_jurisdiction_outcome_idx ON public.kyc_verification_records USING btree (jurisdiction_code, outcome) WHERE (outcome IS NOT NULL);


--
-- Name: kyc_verification_member_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kyc_verification_member_idx ON public.kyc_verification_records USING btree (member_id, anchored_at DESC);


--
-- Name: kyc_verification_provider_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kyc_verification_provider_idx ON public.kyc_verification_records USING btree (provider_id) WHERE (provider_id IS NOT NULL);


--
-- Name: levy_calc_reporting_period_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX levy_calc_reporting_period_idx ON public.levy_calculation_records USING btree (reporting_period, jurisdiction_code) WHERE (reporting_period IS NOT NULL);


--
-- Name: levy_calc_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX levy_calc_status_idx ON public.levy_calculation_records USING btree (levy_status) WHERE (levy_status IS NOT NULL);


--
-- Name: levy_periods_jurisdiction_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX levy_periods_jurisdiction_idx ON public.levy_remittance_periods USING btree (jurisdiction_code, period_start DESC);


--
-- Name: levy_periods_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX levy_periods_status_idx ON public.levy_remittance_periods USING btree (period_status) WHERE (period_status IS NOT NULL);


--
-- Name: levy_rates_jurisdiction_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX levy_rates_jurisdiction_date_idx ON public.levy_rates USING btree (jurisdiction_code, effective_from DESC);


--
-- Name: levy_rates_one_active_per_jurisdiction; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX levy_rates_one_active_per_jurisdiction ON public.levy_rates USING btree (jurisdiction_code) WHERE (effective_to IS NULL);


--
-- Name: ux_billing_usage_events_idempotency; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_billing_usage_events_idempotency ON public.billing_usage_events USING btree (billable_client_id, idempotency_key) WHERE (idempotency_key IS NOT NULL);


--
-- Name: ux_ingress_attestations_tenant_instruction; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_ingress_attestations_tenant_instruction ON public.ingress_attestations USING btree (tenant_id, instruction_id);


--
-- Name: ux_instruction_settlement_finality_one_reversal_per_original; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_instruction_settlement_finality_one_reversal_per_original ON public.instruction_settlement_finality USING btree (reversal_of_instruction_id) WHERE (reversal_of_instruction_id IS NOT NULL);


--
-- Name: ux_outbox_attempts_one_terminal_per_outbox; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_outbox_attempts_one_terminal_per_outbox ON public.payment_outbox_attempts USING btree (outbox_id) WHERE (state = ANY (ARRAY['DISPATCHED'::public.outbox_attempt_state, 'FAILED'::public.outbox_attempt_state]));


--
-- Name: ux_policy_versions_single_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_policy_versions_single_active ON public.policy_versions USING btree ((1)) WHERE (status = 'ACTIVE'::public.policy_version_status);


--
-- Name: ux_program_migration_events_deterministic; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_program_migration_events_deterministic ON public.program_migration_events USING btree (tenant_id, person_id, from_program_id, to_program_id);


--
-- Name: kyc_retention_policy kyc_retention_policy_no_delete; Type: RULE; Schema: public; Owner: -
--

CREATE RULE kyc_retention_policy_no_delete AS
    ON DELETE TO public.kyc_retention_policy DO INSTEAD NOTHING;


--
-- Name: kyc_retention_policy kyc_retention_policy_no_update; Type: RULE; Schema: public; Owner: -
--

CREATE RULE kyc_retention_policy_no_update AS
    ON UPDATE TO public.kyc_retention_policy DO INSTEAD NOTHING;


--
-- Name: adapter_registrations adapter_registrations_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER adapter_registrations_append_only BEFORE DELETE OR UPDATE ON public.adapter_registrations FOR EACH ROW EXECUTE FUNCTION public.adapter_registrations_append_only_trigger();


--
-- Name: asset_lifecycle_events asset_lifecycle_confidence_enforcement; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER asset_lifecycle_confidence_enforcement BEFORE INSERT ON public.asset_lifecycle_events FOR EACH ROW EXECUTE FUNCTION public.enforce_confidence_before_issuance();


--
-- Name: authority_decisions authority_decisions_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER authority_decisions_append_only BEFORE DELETE OR UPDATE ON public.authority_decisions FOR EACH ROW EXECUTE FUNCTION public.authority_decisions_append_only();


--
-- Name: gf_verifier_read_tokens gf_verifier_read_tokens_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER gf_verifier_read_tokens_append_only BEFORE DELETE OR UPDATE ON public.gf_verifier_read_tokens FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_read_tokens_append_only();


--
-- Name: adjustment_instructions trg_adjustment_terminal_immutability; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_adjustment_terminal_immutability BEFORE UPDATE ON public.adjustment_instructions FOR EACH ROW EXECUTE FUNCTION public.enforce_adjustment_terminal_immutability();


--
-- Name: payment_outbox_attempts trg_anchor_dispatched_outbox_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_anchor_dispatched_outbox_attempt AFTER INSERT ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.anchor_dispatched_outbox_attempt();


--
-- Name: reference_strategy_policy_versions trg_block_active_reference_policy_updates; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_block_active_reference_policy_updates BEFORE UPDATE ON public.reference_strategy_policy_versions FOR EACH ROW EXECUTE FUNCTION public.block_active_reference_policy_updates();


--
-- Name: billing_usage_events trg_deny_billing_usage_events_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_billing_usage_events_mutation BEFORE DELETE OR UPDATE ON public.billing_usage_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: escrow_events trg_deny_escrow_events_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_escrow_events_mutation BEFORE DELETE OR UPDATE ON public.escrow_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: evidence_pack_items trg_deny_evidence_pack_items_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_evidence_pack_items_mutation BEFORE DELETE OR UPDATE ON public.evidence_pack_items FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: evidence_packs trg_deny_evidence_packs_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_evidence_packs_mutation BEFORE DELETE OR UPDATE ON public.evidence_packs FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: external_proofs trg_deny_external_proofs_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_external_proofs_mutation BEFORE DELETE OR UPDATE ON public.external_proofs FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: instruction_settlement_finality trg_deny_final_instruction_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_final_instruction_mutation BEFORE DELETE OR UPDATE ON public.instruction_settlement_finality FOR EACH ROW EXECUTE FUNCTION public.deny_final_instruction_mutation();


--
-- Name: ingress_attestations trg_deny_ingress_attestations_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_ingress_attestations_mutation BEFORE DELETE OR UPDATE ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.deny_ingress_attestations_mutation();


--
-- Name: internal_ledger_journals trg_deny_internal_ledger_journals_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_internal_ledger_journals_mutation BEFORE DELETE OR UPDATE ON public.internal_ledger_journals FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: internal_ledger_postings trg_deny_internal_ledger_postings_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_internal_ledger_postings_mutation BEFORE DELETE OR UPDATE ON public.internal_ledger_postings FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: member_device_events trg_deny_member_device_events_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_member_device_events_mutation BEFORE DELETE OR UPDATE ON public.member_device_events FOR EACH ROW EXECUTE FUNCTION public.deny_member_device_events_mutation();


--
-- Name: payment_outbox_attempts trg_deny_outbox_attempts_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_outbox_attempts_mutation BEFORE DELETE OR UPDATE ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.deny_outbox_attempts_mutation();


--
-- Name: pii_purge_events trg_deny_pii_purge_events_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_pii_purge_events_mutation BEFORE DELETE OR UPDATE ON public.pii_purge_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: pii_purge_requests trg_deny_pii_purge_requests_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_pii_purge_requests_mutation BEFORE DELETE OR UPDATE ON public.pii_purge_requests FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: pii_vault_records trg_deny_pii_vault_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_pii_vault_mutation BEFORE DELETE OR UPDATE ON public.pii_vault_records FOR EACH ROW EXECUTE FUNCTION public.deny_pii_vault_mutation();


--
-- Name: rail_dispatch_truth_anchor trg_deny_rail_dispatch_truth_anchor_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_rail_dispatch_truth_anchor_mutation BEFORE DELETE OR UPDATE ON public.rail_dispatch_truth_anchor FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


--
-- Name: revoked_client_certs trg_deny_revoked_client_certs_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_revoked_client_certs_mutation BEFORE DELETE OR UPDATE ON public.revoked_client_certs FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();


--
-- Name: revoked_tokens trg_deny_revoked_tokens_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_revoked_tokens_mutation BEFORE DELETE OR UPDATE ON public.revoked_tokens FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();


--
-- Name: sim_swap_alerts trg_deny_sim_swap_alerts_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_sim_swap_alerts_mutation BEFORE DELETE OR UPDATE ON public.sim_swap_alerts FOR EACH ROW EXECUTE FUNCTION public.deny_sim_swap_alerts_mutation();


--
-- Name: instruction_settlement_finality trg_enforce_instruction_reversal_source; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_enforce_instruction_reversal_source BEFORE INSERT ON public.instruction_settlement_finality FOR EACH ROW EXECUTE FUNCTION public.enforce_instruction_reversal_source();


--
-- Name: internal_ledger_postings trg_enforce_internal_ledger_posting_context; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_enforce_internal_ledger_posting_context BEFORE INSERT OR UPDATE ON public.internal_ledger_postings FOR EACH ROW EXECUTE FUNCTION public.enforce_internal_ledger_posting_context();


--
-- Name: instruction_settlement_finality trg_enforce_settlement_acknowledgement; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_enforce_settlement_acknowledgement BEFORE INSERT ON public.instruction_settlement_finality FOR EACH ROW EXECUTE FUNCTION public.enforce_settlement_acknowledgement();


--
-- Name: ingress_attestations trg_ingress_member_tenant_match; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ingress_member_tenant_match BEFORE INSERT ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.enforce_member_tenant_match();


--
-- Name: ingress_attestations trg_set_corr_id_ingress_attestations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_corr_id_ingress_attestations BEFORE INSERT ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();


--
-- Name: payment_outbox_attempts trg_set_corr_id_payment_outbox_attempts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_corr_id_payment_outbox_attempts BEFORE INSERT ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();


--
-- Name: payment_outbox_pending trg_set_corr_id_payment_outbox_pending; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_corr_id_payment_outbox_pending BEFORE INSERT ON public.payment_outbox_pending FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();


--
-- Name: external_proofs trg_set_external_proofs_attribution; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_external_proofs_attribution BEFORE INSERT ON public.external_proofs FOR EACH ROW EXECUTE FUNCTION public.set_external_proofs_attribution();


--
-- Name: anchor_sync_operations trg_touch_anchor_sync_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_touch_anchor_sync_updated_at BEFORE UPDATE ON public.anchor_sync_operations FOR EACH ROW EXECUTE FUNCTION public.touch_anchor_sync_updated_at();


--
-- Name: escrow_envelopes trg_touch_escrow_envelopes_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_touch_escrow_envelopes_updated_at BEFORE UPDATE ON public.escrow_envelopes FOR EACH ROW EXECUTE FUNCTION public.touch_escrow_envelopes_updated_at();


--
-- Name: escrow_accounts trg_touch_escrow_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_touch_escrow_updated_at BEFORE UPDATE ON public.escrow_accounts FOR EACH ROW EXECUTE FUNCTION public.touch_escrow_updated_at();


--
-- Name: inquiry_state_machine trg_touch_inquiry_state_machine_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_touch_inquiry_state_machine_updated_at BEFORE UPDATE ON public.inquiry_state_machine FOR EACH ROW EXECUTE FUNCTION public.touch_inquiry_state_updated_at();


--
-- Name: members trg_touch_members_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_touch_members_updated_at BEFORE INSERT OR UPDATE ON public.members FOR EACH ROW EXECUTE FUNCTION public.touch_members_updated_at();


--
-- Name: persons trg_touch_persons_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_touch_persons_updated_at BEFORE UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.touch_persons_updated_at();


--
-- Name: programs trg_touch_programs_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_touch_programs_updated_at BEFORE UPDATE ON public.programs FOR EACH ROW EXECUTE FUNCTION public.touch_programs_updated_at();


--
-- Name: verifier_project_assignments verifier_project_assignments_no_mutate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER verifier_project_assignments_no_mutate BEFORE DELETE OR UPDATE ON public.verifier_project_assignments FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tables_append_only();


--
-- Name: verifier_registry verifier_registry_no_mutate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER verifier_registry_no_mutate BEFORE DELETE OR UPDATE ON public.verifier_registry FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tables_append_only();


--
-- Name: adapter_registrations adapter_registrations_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adapter_registrations
    ADD CONSTRAINT adapter_registrations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: adjustment_approval_stages adjustment_approval_stages_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_approval_stages
    ADD CONSTRAINT adjustment_approval_stages_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id);


--
-- Name: adjustment_approvals adjustment_approvals_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_approvals
    ADD CONSTRAINT adjustment_approvals_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.adjustment_approval_stages(stage_id);


--
-- Name: adjustment_execution_attempts adjustment_execution_attempts_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_execution_attempts
    ADD CONSTRAINT adjustment_execution_attempts_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id);


--
-- Name: adjustment_freeze_flags adjustment_freeze_flags_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_freeze_flags
    ADD CONSTRAINT adjustment_freeze_flags_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id);


--
-- Name: adjustment_instructions adjustment_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adjustment_instructions
    ADD CONSTRAINT adjustment_parent_fk FOREIGN KEY (parent_instruction_id) REFERENCES public.inquiry_state_machine(instruction_id);


--
-- Name: anchor_sync_operations anchor_sync_operations_pack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anchor_sync_operations
    ADD CONSTRAINT anchor_sync_operations_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.evidence_packs(pack_id);


--
-- Name: artifact_signing_batch_items artifact_signing_batch_items_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artifact_signing_batch_items
    ADD CONSTRAINT artifact_signing_batch_items_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.artifact_signing_batches(batch_id) ON DELETE CASCADE;


--
-- Name: asset_batches asset_batches_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_batches
    ADD CONSTRAINT asset_batches_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;


--
-- Name: asset_batches asset_batches_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_batches
    ADD CONSTRAINT asset_batches_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: asset_lifecycle_events asset_lifecycle_events_asset_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_lifecycle_events
    ADD CONSTRAINT asset_lifecycle_events_asset_batch_id_fkey FOREIGN KEY (asset_batch_id) REFERENCES public.asset_batches(asset_batch_id) ON DELETE RESTRICT;


--
-- Name: asset_lifecycle_events asset_lifecycle_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_lifecycle_events
    ADD CONSTRAINT asset_lifecycle_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: authority_decisions authority_decisions_regulatory_authority_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authority_decisions
    ADD CONSTRAINT authority_decisions_regulatory_authority_id_fkey FOREIGN KEY (regulatory_authority_id) REFERENCES public.regulatory_authorities(regulatory_authority_id) ON DELETE RESTRICT;


--
-- Name: billing_usage_events billing_usage_events_billable_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_usage_events
    ADD CONSTRAINT billing_usage_events_billable_client_id_fkey FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id);


--
-- Name: billing_usage_events billing_usage_events_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_usage_events
    ADD CONSTRAINT billing_usage_events_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.tenant_clients(client_id);


--
-- Name: billing_usage_events billing_usage_events_subject_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_usage_events
    ADD CONSTRAINT billing_usage_events_subject_client_id_fkey FOREIGN KEY (subject_client_id) REFERENCES public.tenant_clients(client_id);


--
-- Name: billing_usage_events billing_usage_events_subject_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_usage_events
    ADD CONSTRAINT billing_usage_events_subject_member_id_fkey FOREIGN KEY (subject_member_id) REFERENCES public.tenant_members(member_id);


--
-- Name: billing_usage_events billing_usage_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_usage_events
    ADD CONSTRAINT billing_usage_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);


--
-- Name: canonicalization_archive_snapshots canonicalization_archive_snapshot_canonicalization_version_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canonicalization_archive_snapshots
    ADD CONSTRAINT canonicalization_archive_snapshot_canonicalization_version_fkey FOREIGN KEY (canonicalization_version) REFERENCES public.canonicalization_registry(canonicalization_version) ON DELETE RESTRICT;


--
-- Name: dispatch_reference_collision_events dispatch_reference_collision_events_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_reference_collision_events
    ADD CONSTRAINT dispatch_reference_collision_events_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id) ON DELETE RESTRICT;


--
-- Name: dispatch_reference_registry dispatch_reference_registry_adjustment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_reference_registry
    ADD CONSTRAINT dispatch_reference_registry_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id) ON DELETE RESTRICT;


--
-- Name: dispatch_reference_registry dispatch_reference_registry_policy_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dispatch_reference_registry
    ADD CONSTRAINT dispatch_reference_registry_policy_version_id_fkey FOREIGN KEY (policy_version_id) REFERENCES public.reference_strategy_policy_versions(policy_version_id) ON DELETE RESTRICT;


--
-- Name: escrow_accounts escrow_accounts_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_accounts
    ADD CONSTRAINT escrow_accounts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE CASCADE;


--
-- Name: escrow_envelopes escrow_envelopes_escrow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_envelopes
    ADD CONSTRAINT escrow_envelopes_escrow_id_fkey FOREIGN KEY (escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;


--
-- Name: escrow_envelopes escrow_envelopes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_envelopes
    ADD CONSTRAINT escrow_envelopes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: escrow_events escrow_events_escrow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_events
    ADD CONSTRAINT escrow_events_escrow_id_fkey FOREIGN KEY (escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;


--
-- Name: escrow_events escrow_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_events
    ADD CONSTRAINT escrow_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: escrow_reservations escrow_reservations_program_escrow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_reservations
    ADD CONSTRAINT escrow_reservations_program_escrow_id_fkey FOREIGN KEY (program_escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;


--
-- Name: escrow_reservations escrow_reservations_reservation_escrow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_reservations
    ADD CONSTRAINT escrow_reservations_reservation_escrow_id_fkey FOREIGN KEY (reservation_escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;


--
-- Name: escrow_reservations escrow_reservations_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_reservations
    ADD CONSTRAINT escrow_reservations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: escrow_summary_projection escrow_summary_projection_escrow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_summary_projection
    ADD CONSTRAINT escrow_summary_projection_escrow_id_fkey FOREIGN KEY (escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;


--
-- Name: escrow_summary_projection escrow_summary_projection_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_summary_projection
    ADD CONSTRAINT escrow_summary_projection_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: escrow_summary_projection escrow_summary_projection_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_summary_projection
    ADD CONSTRAINT escrow_summary_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: evidence_bundle_projection evidence_bundle_projection_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_bundle_projection
    ADD CONSTRAINT evidence_bundle_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: evidence_edges evidence_edges_source_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_edges
    ADD CONSTRAINT evidence_edges_source_node_id_fkey FOREIGN KEY (source_node_id) REFERENCES public.evidence_nodes(evidence_node_id) ON DELETE RESTRICT;


--
-- Name: evidence_edges evidence_edges_target_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_edges
    ADD CONSTRAINT evidence_edges_target_node_id_fkey FOREIGN KEY (target_node_id) REFERENCES public.evidence_nodes(evidence_node_id) ON DELETE RESTRICT;


--
-- Name: evidence_edges evidence_edges_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_edges
    ADD CONSTRAINT evidence_edges_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: evidence_nodes evidence_nodes_monitoring_record_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_nodes
    ADD CONSTRAINT evidence_nodes_monitoring_record_id_fkey FOREIGN KEY (monitoring_record_id) REFERENCES public.monitoring_records(monitoring_record_id) ON DELETE RESTRICT;


--
-- Name: evidence_nodes evidence_nodes_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_nodes
    ADD CONSTRAINT evidence_nodes_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;


--
-- Name: evidence_nodes evidence_nodes_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_nodes
    ADD CONSTRAINT evidence_nodes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: evidence_pack_items evidence_pack_items_pack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_pack_items
    ADD CONSTRAINT evidence_pack_items_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.evidence_packs(pack_id);


--
-- Name: execution_records execution_records_interpretation_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.execution_records
    ADD CONSTRAINT execution_records_interpretation_version_id_fkey FOREIGN KEY (interpretation_version_id) REFERENCES public.interpretation_packs(interpretation_pack_id) ON DELETE RESTRICT;


--
-- Name: external_proofs external_proofs_attestation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_proofs
    ADD CONSTRAINT external_proofs_attestation_id_fkey FOREIGN KEY (attestation_id) REFERENCES public.ingress_attestations(attestation_id);


--
-- Name: external_proofs external_proofs_billable_client_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_proofs
    ADD CONSTRAINT external_proofs_billable_client_fk FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id) NOT VALID;


--
-- Name: external_proofs external_proofs_subject_member_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_proofs
    ADD CONSTRAINT external_proofs_subject_member_fk FOREIGN KEY (subject_member_id) REFERENCES public.tenant_members(member_id) NOT VALID;


--
-- Name: external_proofs external_proofs_tenant_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_proofs
    ADD CONSTRAINT external_proofs_tenant_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) NOT VALID;


--
-- Name: gf_verifier_read_tokens gf_verifier_read_tokens_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gf_verifier_read_tokens
    ADD CONSTRAINT gf_verifier_read_tokens_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;


--
-- Name: gf_verifier_read_tokens gf_verifier_read_tokens_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gf_verifier_read_tokens
    ADD CONSTRAINT gf_verifier_read_tokens_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: gf_verifier_read_tokens gf_verifier_read_tokens_verifier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gf_verifier_read_tokens
    ADD CONSTRAINT gf_verifier_read_tokens_verifier_id_fkey FOREIGN KEY (verifier_id) REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT;


--
-- Name: incident_case_projection incident_case_projection_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_case_projection
    ADD CONSTRAINT incident_case_projection_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.regulatory_incidents(incident_id) ON DELETE RESTRICT;


--
-- Name: incident_case_projection incident_case_projection_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_case_projection
    ADD CONSTRAINT incident_case_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: incident_events incident_events_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_events
    ADD CONSTRAINT incident_events_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.regulatory_incidents(incident_id) ON DELETE CASCADE;


--
-- Name: ingress_attestations ingress_attestations_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingress_attestations
    ADD CONSTRAINT ingress_attestations_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.tenant_clients(client_id);


--
-- Name: ingress_attestations ingress_attestations_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingress_attestations
    ADD CONSTRAINT ingress_attestations_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.tenant_members(member_id);


--
-- Name: instruction_settlement_finality instruction_settlement_finality_reversal_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_settlement_finality
    ADD CONSTRAINT instruction_settlement_finality_reversal_fk FOREIGN KEY (reversal_of_instruction_id) REFERENCES public.instruction_settlement_finality(instruction_id) DEFERRABLE;


--
-- Name: instruction_status_projection instruction_status_projection_attestation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_status_projection
    ADD CONSTRAINT instruction_status_projection_attestation_id_fkey FOREIGN KEY (attestation_id) REFERENCES public.ingress_attestations(attestation_id) ON DELETE RESTRICT;


--
-- Name: instruction_status_projection instruction_status_projection_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_status_projection
    ADD CONSTRAINT instruction_status_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: internal_ledger_journals internal_ledger_journals_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_ledger_journals
    ADD CONSTRAINT internal_ledger_journals_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: internal_ledger_postings internal_ledger_postings_journal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_ledger_postings
    ADD CONSTRAINT internal_ledger_postings_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES public.internal_ledger_journals(journal_id) ON DELETE RESTRICT;


--
-- Name: internal_ledger_postings internal_ledger_postings_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.internal_ledger_postings
    ADD CONSTRAINT internal_ledger_postings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: kyc_verification_records kyc_verification_records_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_verification_records
    ADD CONSTRAINT kyc_verification_records_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.tenant_members(member_id) ON DELETE RESTRICT;


--
-- Name: kyc_verification_records kyc_verification_records_provider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kyc_verification_records
    ADD CONSTRAINT kyc_verification_records_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES public.kyc_provider_registry(id) ON DELETE RESTRICT;


--
-- Name: levy_calculation_records levy_calculation_records_instruction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levy_calculation_records
    ADD CONSTRAINT levy_calculation_records_instruction_id_fkey FOREIGN KEY (instruction_id) REFERENCES public.ingress_attestations(attestation_id) ON DELETE RESTRICT;


--
-- Name: levy_calculation_records levy_calculation_records_levy_rate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.levy_calculation_records
    ADD CONSTRAINT levy_calculation_records_levy_rate_id_fkey FOREIGN KEY (levy_rate_id) REFERENCES public.levy_rates(id) ON DELETE RESTRICT;


--
-- Name: lifecycle_checkpoint_rules lifecycle_checkpoint_rules_regulatory_checkpoint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lifecycle_checkpoint_rules
    ADD CONSTRAINT lifecycle_checkpoint_rules_regulatory_checkpoint_id_fkey FOREIGN KEY (regulatory_checkpoint_id) REFERENCES public.regulatory_checkpoints(regulatory_checkpoint_id) ON DELETE RESTRICT;


--
-- Name: member_device_events member_device_events_ingress_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_device_events
    ADD CONSTRAINT member_device_events_ingress_fk FOREIGN KEY (tenant_id, instruction_id) REFERENCES public.ingress_attestations(tenant_id, instruction_id) ON DELETE RESTRICT;


--
-- Name: member_device_events member_device_events_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_device_events
    ADD CONSTRAINT member_device_events_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;


--
-- Name: member_devices member_devices_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_devices
    ADD CONSTRAINT member_devices_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;


--
-- Name: member_devices member_devices_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_devices
    ADD CONSTRAINT member_devices_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: members members_entity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: members members_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(person_id) ON DELETE RESTRICT;


--
-- Name: members members_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: members members_tenant_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_tenant_member_id_fkey FOREIGN KEY (tenant_member_id) REFERENCES public.tenant_members(member_id) ON DELETE RESTRICT;


--
-- Name: methodology_versions methodology_versions_adapter_registration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.methodology_versions
    ADD CONSTRAINT methodology_versions_adapter_registration_id_fkey FOREIGN KEY (adapter_registration_id) REFERENCES public.adapter_registrations(adapter_registration_id) ON DELETE RESTRICT;


--
-- Name: methodology_versions methodology_versions_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.methodology_versions
    ADD CONSTRAINT methodology_versions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: monitoring_records monitoring_records_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_records
    ADD CONSTRAINT monitoring_records_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;


--
-- Name: monitoring_records monitoring_records_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monitoring_records
    ADD CONSTRAINT monitoring_records_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: payment_outbox_attempts payment_outbox_attempts_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_attempts
    ADD CONSTRAINT payment_outbox_attempts_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.tenant_members(member_id);


--
-- Name: payment_outbox_attempts payment_outbox_attempts_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_attempts
    ADD CONSTRAINT payment_outbox_attempts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);


--
-- Name: payment_outbox_pending payment_outbox_pending_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_pending
    ADD CONSTRAINT payment_outbox_pending_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);


--
-- Name: penalty_defense_packs penalty_defense_packs_submission_attempt_ref_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.penalty_defense_packs
    ADD CONSTRAINT penalty_defense_packs_submission_attempt_ref_fkey FOREIGN KEY (submission_attempt_ref) REFERENCES public.regulatory_report_submission_attempts(attempt_id);


--
-- Name: persons persons_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: pii_purge_events pii_purge_events_purge_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_purge_events
    ADD CONSTRAINT pii_purge_events_purge_request_id_fkey FOREIGN KEY (purge_request_id) REFERENCES public.pii_purge_requests(purge_request_id);


--
-- Name: pii_vault_records pii_vault_records_purge_request_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_vault_records
    ADD CONSTRAINT pii_vault_records_purge_request_fk FOREIGN KEY (purge_request_id) REFERENCES public.pii_purge_requests(purge_request_id) DEFERRABLE;


--
-- Name: program_member_summary_projection program_member_summary_projection_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_member_summary_projection
    ADD CONSTRAINT program_member_summary_projection_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: program_member_summary_projection program_member_summary_projection_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_member_summary_projection
    ADD CONSTRAINT program_member_summary_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: program_migration_events program_migration_events_formula_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_migration_events
    ADD CONSTRAINT program_migration_events_formula_version_id_fkey FOREIGN KEY (formula_version_id) REFERENCES public.risk_formula_versions(formula_version_id) ON DELETE RESTRICT;


--
-- Name: program_migration_events program_migration_events_from_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_migration_events
    ADD CONSTRAINT program_migration_events_from_program_id_fkey FOREIGN KEY (from_program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: program_migration_events program_migration_events_migrated_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_migration_events
    ADD CONSTRAINT program_migration_events_migrated_member_id_fkey FOREIGN KEY (migrated_member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;


--
-- Name: program_migration_events program_migration_events_new_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_migration_events
    ADD CONSTRAINT program_migration_events_new_member_id_fkey FOREIGN KEY (new_member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;


--
-- Name: program_migration_events program_migration_events_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_migration_events
    ADD CONSTRAINT program_migration_events_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(person_id) ON DELETE RESTRICT;


--
-- Name: program_migration_events program_migration_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_migration_events
    ADD CONSTRAINT program_migration_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: program_migration_events program_migration_events_to_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_migration_events
    ADD CONSTRAINT program_migration_events_to_program_id_fkey FOREIGN KEY (to_program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: program_supplier_allowlist program_supplier_allowlist_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_supplier_allowlist
    ADD CONSTRAINT program_supplier_allowlist_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: program_supplier_allowlist program_supplier_allowlist_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_supplier_allowlist
    ADD CONSTRAINT program_supplier_allowlist_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: program_supplier_allowlist program_supplier_allowlist_tenant_id_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_supplier_allowlist
    ADD CONSTRAINT program_supplier_allowlist_tenant_id_supplier_id_fkey FOREIGN KEY (tenant_id, supplier_id) REFERENCES public.supplier_registry(tenant_id, supplier_id) ON DELETE RESTRICT;


--
-- Name: programme_policy_binding programme_policy_binding_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_policy_binding
    ADD CONSTRAINT programme_policy_binding_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programme_registry(id);


--
-- Name: programme_policy_binding programme_policy_binding_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_policy_binding
    ADD CONSTRAINT programme_policy_binding_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant_registry(tenant_id);


--
-- Name: programme_registry programme_registry_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_registry
    ADD CONSTRAINT programme_registry_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant_registry(tenant_id);


--
-- Name: programs programs_program_escrow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_program_escrow_id_fkey FOREIGN KEY (program_escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE CASCADE;


--
-- Name: programs programs_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE CASCADE;


--
-- Name: projects projects_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: proof_pack_batch_leaves proof_pack_batch_leaves_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proof_pack_batch_leaves
    ADD CONSTRAINT proof_pack_batch_leaves_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.proof_pack_batches(batch_id) ON DELETE CASCADE;


--
-- Name: proof_pack_batches proof_pack_batches_canonicalization_version_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proof_pack_batches
    ADD CONSTRAINT proof_pack_batches_canonicalization_version_fkey FOREIGN KEY (canonicalization_version) REFERENCES public.canonicalization_registry(canonicalization_version) ON DELETE RESTRICT;


--
-- Name: rail_dispatch_truth_anchor rail_truth_anchor_attempt_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rail_dispatch_truth_anchor
    ADD CONSTRAINT rail_truth_anchor_attempt_fk FOREIGN KEY (attempt_id) REFERENCES public.payment_outbox_attempts(attempt_id) DEFERRABLE;


--
-- Name: regulatory_checkpoints regulatory_checkpoints_regulatory_authority_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_checkpoints
    ADD CONSTRAINT regulatory_checkpoints_regulatory_authority_id_fkey FOREIGN KEY (regulatory_authority_id) REFERENCES public.regulatory_authorities(regulatory_authority_id) ON DELETE RESTRICT;


--
-- Name: regulatory_incidents regulatory_incidents_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regulatory_incidents
    ADD CONSTRAINT regulatory_incidents_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: retirement_events retirement_events_asset_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retirement_events
    ADD CONSTRAINT retirement_events_asset_batch_id_fkey FOREIGN KEY (asset_batch_id) REFERENCES public.asset_batches(asset_batch_id) ON DELETE RESTRICT;


--
-- Name: retirement_events retirement_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retirement_events
    ADD CONSTRAINT retirement_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: sim_swap_alerts sim_swap_alerts_formula_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sim_swap_alerts
    ADD CONSTRAINT sim_swap_alerts_formula_version_id_fkey FOREIGN KEY (formula_version_id) REFERENCES public.risk_formula_versions(formula_version_id) ON DELETE RESTRICT;


--
-- Name: sim_swap_alerts sim_swap_alerts_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sim_swap_alerts
    ADD CONSTRAINT sim_swap_alerts_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;


--
-- Name: sim_swap_alerts sim_swap_alerts_source_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sim_swap_alerts
    ADD CONSTRAINT sim_swap_alerts_source_event_id_fkey FOREIGN KEY (source_event_id) REFERENCES public.member_device_events(event_id) ON DELETE RESTRICT;


--
-- Name: sim_swap_alerts sim_swap_alerts_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sim_swap_alerts
    ADD CONSTRAINT sim_swap_alerts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: supervisor_approval_queue supervisor_approval_queue_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisor_approval_queue
    ADD CONSTRAINT supervisor_approval_queue_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: supervisor_audit_tokens supervisor_audit_tokens_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisor_audit_tokens
    ADD CONSTRAINT supervisor_audit_tokens_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: supervisor_interrupt_audit_events supervisor_interrupt_audit_events_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supervisor_interrupt_audit_events
    ADD CONSTRAINT supervisor_interrupt_audit_events_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;


--
-- Name: supplier_registry supplier_registry_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supplier_registry
    ADD CONSTRAINT supplier_registry_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: tenant_clients tenant_clients_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_clients
    ADD CONSTRAINT tenant_clients_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);


--
-- Name: tenant_members tenant_members_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenant_members
    ADD CONSTRAINT tenant_members_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);


--
-- Name: tenants tenants_billable_client_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_billable_client_fk FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id) NOT VALID;


--
-- Name: tenants tenants_parent_tenant_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tenants
    ADD CONSTRAINT tenants_parent_tenant_fk FOREIGN KEY (parent_tenant_id) REFERENCES public.tenants(tenant_id) NOT VALID;


--
-- Name: verifier_project_assignments verifier_project_assignments_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifier_project_assignments
    ADD CONSTRAINT verifier_project_assignments_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;


--
-- Name: verifier_project_assignments verifier_project_assignments_verifier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifier_project_assignments
    ADD CONSTRAINT verifier_project_assignments_verifier_id_fkey FOREIGN KEY (verifier_id) REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT;


--
-- Name: verifier_registry verifier_registry_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifier_registry
    ADD CONSTRAINT verifier_registry_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: adapter_registrations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;

--
-- Name: asset_batches; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_batches ENABLE ROW LEVEL SECURITY;

--
-- Name: asset_lifecycle_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.asset_lifecycle_events ENABLE ROW LEVEL SECURITY;

--
-- Name: authority_decisions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.authority_decisions ENABLE ROW LEVEL SECURITY;

--
-- Name: authority_decisions authority_decisions_jurisdiction_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY authority_decisions_jurisdiction_access ON public.authority_decisions USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));


--
-- Name: billing_usage_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.billing_usage_events ENABLE ROW LEVEL SECURITY;

--
-- Name: escrow_accounts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.escrow_accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: escrow_envelopes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.escrow_envelopes ENABLE ROW LEVEL SECURITY;

--
-- Name: escrow_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.escrow_events ENABLE ROW LEVEL SECURITY;

--
-- Name: escrow_reservations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.escrow_reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: evidence_edges; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.evidence_edges ENABLE ROW LEVEL SECURITY;

--
-- Name: evidence_nodes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.evidence_nodes ENABLE ROW LEVEL SECURITY;

--
-- Name: external_proofs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.external_proofs ENABLE ROW LEVEL SECURITY;

--
-- Name: gf_verifier_read_tokens; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.gf_verifier_read_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: gf_verifier_read_tokens gf_verifier_read_tokens_tenant_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY gf_verifier_read_tokens_tenant_isolation ON public.gf_verifier_read_tokens USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: ingress_attestations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ingress_attestations ENABLE ROW LEVEL SECURITY;

--
-- Name: interpretation_packs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.interpretation_packs ENABLE ROW LEVEL SECURITY;

--
-- Name: jurisdiction_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.jurisdiction_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: lifecycle_checkpoint_rules; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lifecycle_checkpoint_rules ENABLE ROW LEVEL SECURITY;

--
-- Name: member_device_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.member_device_events ENABLE ROW LEVEL SECURITY;

--
-- Name: member_devices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.member_devices ENABLE ROW LEVEL SECURITY;

--
-- Name: members; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;

--
-- Name: methodology_versions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.methodology_versions ENABLE ROW LEVEL SECURITY;

--
-- Name: monitoring_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.monitoring_records ENABLE ROW LEVEL SECURITY;

--
-- Name: payment_outbox_attempts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payment_outbox_attempts ENABLE ROW LEVEL SECURITY;

--
-- Name: payment_outbox_pending; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payment_outbox_pending ENABLE ROW LEVEL SECURITY;

--
-- Name: persons; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;

--
-- Name: program_migration_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.program_migration_events ENABLE ROW LEVEL SECURITY;

--
-- Name: program_supplier_allowlist; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.program_supplier_allowlist ENABLE ROW LEVEL SECURITY;

--
-- Name: programme_policy_binding; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.programme_policy_binding ENABLE ROW LEVEL SECURITY;

--
-- Name: programme_registry; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.programme_registry ENABLE ROW LEVEL SECURITY;

--
-- Name: programs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;

--
-- Name: projects; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

--
-- Name: regulatory_authorities; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.regulatory_authorities ENABLE ROW LEVEL SECURITY;

--
-- Name: regulatory_checkpoints; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.regulatory_checkpoints ENABLE ROW LEVEL SECURITY;

--
-- Name: retirement_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.retirement_events ENABLE ROW LEVEL SECURITY;

--
-- Name: interpretation_packs rls_jurisdiction_isolation_interpretation_packs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_jurisdiction_isolation_interpretation_packs ON public.interpretation_packs USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));


--
-- Name: jurisdiction_profiles rls_jurisdiction_isolation_jurisdiction_profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_jurisdiction_isolation_jurisdiction_profiles ON public.jurisdiction_profiles USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));


--
-- Name: lifecycle_checkpoint_rules rls_jurisdiction_isolation_lifecycle_checkpoint_rules; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_jurisdiction_isolation_lifecycle_checkpoint_rules ON public.lifecycle_checkpoint_rules USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));


--
-- Name: regulatory_authorities rls_jurisdiction_isolation_regulatory_authorities; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_jurisdiction_isolation_regulatory_authorities ON public.regulatory_authorities USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));


--
-- Name: regulatory_checkpoints rls_jurisdiction_isolation_regulatory_checkpoints; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_jurisdiction_isolation_regulatory_checkpoints ON public.regulatory_checkpoints USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));


--
-- Name: adapter_registrations rls_tenant_isolation_adapter_registrations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_adapter_registrations ON public.adapter_registrations USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: asset_batches rls_tenant_isolation_asset_batches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_asset_batches ON public.asset_batches USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: asset_lifecycle_events rls_tenant_isolation_asset_lifecycle_events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_asset_lifecycle_events ON public.asset_lifecycle_events USING ((EXISTS ( SELECT 1
   FROM public.asset_batches
  WHERE ((asset_batches.asset_batch_id = asset_lifecycle_events.asset_batch_id) AND (asset_batches.tenant_id = public.current_tenant_id_or_null()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.asset_batches
  WHERE ((asset_batches.asset_batch_id = asset_lifecycle_events.asset_batch_id) AND (asset_batches.tenant_id = public.current_tenant_id_or_null())))));


--
-- Name: billing_usage_events rls_tenant_isolation_billing_usage_events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_billing_usage_events ON public.billing_usage_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: escrow_accounts rls_tenant_isolation_escrow_accounts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_escrow_accounts ON public.escrow_accounts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: escrow_envelopes rls_tenant_isolation_escrow_envelopes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_escrow_envelopes ON public.escrow_envelopes AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: escrow_events rls_tenant_isolation_escrow_events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_escrow_events ON public.escrow_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: escrow_reservations rls_tenant_isolation_escrow_reservations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_escrow_reservations ON public.escrow_reservations AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: evidence_edges rls_tenant_isolation_evidence_edges; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_evidence_edges ON public.evidence_edges USING ((EXISTS ( SELECT 1
   FROM public.evidence_nodes
  WHERE ((evidence_nodes.evidence_node_id = evidence_edges.source_node_id) AND (evidence_nodes.tenant_id = public.current_tenant_id_or_null()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.evidence_nodes
  WHERE ((evidence_nodes.evidence_node_id = evidence_edges.source_node_id) AND (evidence_nodes.tenant_id = public.current_tenant_id_or_null())))));


--
-- Name: evidence_nodes rls_tenant_isolation_evidence_nodes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_evidence_nodes ON public.evidence_nodes USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: external_proofs rls_tenant_isolation_external_proofs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_external_proofs ON public.external_proofs AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: ingress_attestations rls_tenant_isolation_ingress_attestations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_ingress_attestations ON public.ingress_attestations AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: member_device_events rls_tenant_isolation_member_device_events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_member_device_events ON public.member_device_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: member_devices rls_tenant_isolation_member_devices; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_member_devices ON public.member_devices AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: members rls_tenant_isolation_members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_members ON public.members AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: methodology_versions rls_tenant_isolation_methodology_versions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_methodology_versions ON public.methodology_versions USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: monitoring_records rls_tenant_isolation_monitoring_records; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_monitoring_records ON public.monitoring_records USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: payment_outbox_attempts rls_tenant_isolation_payment_outbox_attempts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_payment_outbox_attempts ON public.payment_outbox_attempts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: payment_outbox_pending rls_tenant_isolation_payment_outbox_pending; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_payment_outbox_pending ON public.payment_outbox_pending AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: persons rls_tenant_isolation_persons; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_persons ON public.persons AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: program_migration_events rls_tenant_isolation_program_migration_events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_program_migration_events ON public.program_migration_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: program_supplier_allowlist rls_tenant_isolation_program_supplier_allowlist; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_program_supplier_allowlist ON public.program_supplier_allowlist AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: programme_policy_binding rls_tenant_isolation_programme_policy_binding; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_programme_policy_binding ON public.programme_policy_binding USING (((tenant_id = (NULLIF(current_setting('app.current_tenant_id'::text, true), ''::text))::uuid) OR (current_setting('app.bypass_rls'::text, true) = 'on'::text)));


--
-- Name: programme_registry rls_tenant_isolation_programme_registry; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_programme_registry ON public.programme_registry USING (((tenant_id = (NULLIF(current_setting('app.current_tenant_id'::text, true), ''::text))::uuid) OR (current_setting('app.bypass_rls'::text, true) = 'on'::text)));


--
-- Name: programs rls_tenant_isolation_programs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_programs ON public.programs AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: projects rls_tenant_isolation_projects; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_projects ON public.projects USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: retirement_events rls_tenant_isolation_retirement_events; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_retirement_events ON public.retirement_events USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: sim_swap_alerts rls_tenant_isolation_sim_swap_alerts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_sim_swap_alerts ON public.sim_swap_alerts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: supplier_registry rls_tenant_isolation_supplier_registry; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_supplier_registry ON public.supplier_registry AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: tenant_clients rls_tenant_isolation_tenant_clients; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_tenant_clients ON public.tenant_clients AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: tenant_members rls_tenant_isolation_tenant_members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_tenant_members ON public.tenant_members AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: tenant_registry rls_tenant_isolation_tenant_registry; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_tenant_registry ON public.tenant_registry USING (((tenant_id = (NULLIF(current_setting('app.current_tenant_id'::text, true), ''::text))::uuid) OR (current_setting('app.bypass_rls'::text, true) = 'on'::text)));


--
-- Name: tenants rls_tenant_isolation_tenants; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_tenants ON public.tenants AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: verifier_project_assignments rls_tenant_isolation_verifier_project_assignments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_verifier_project_assignments ON public.verifier_project_assignments USING ((EXISTS ( SELECT 1
   FROM public.verifier_registry
  WHERE ((verifier_registry.verifier_id = verifier_project_assignments.verifier_id) AND (verifier_registry.tenant_id = public.current_tenant_id_or_null()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.verifier_registry
  WHERE ((verifier_registry.verifier_id = verifier_project_assignments.verifier_id) AND (verifier_registry.tenant_id = public.current_tenant_id_or_null())))));


--
-- Name: verifier_registry rls_tenant_isolation_verifier_registry; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_tenant_isolation_verifier_registry ON public.verifier_registry USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));


--
-- Name: sim_swap_alerts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sim_swap_alerts ENABLE ROW LEVEL SECURITY;

--
-- Name: supplier_registry; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supplier_registry ENABLE ROW LEVEL SECURITY;

--
-- Name: tenant_clients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tenant_clients ENABLE ROW LEVEL SECURITY;

--
-- Name: tenant_members; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tenant_members ENABLE ROW LEVEL SECURITY;

--
-- Name: tenant_registry; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tenant_registry ENABLE ROW LEVEL SECURITY;

--
-- Name: tenants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

--
-- Name: verifier_project_assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.verifier_project_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: verifier_registry; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.verifier_registry ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict ce1Vyv3T5wzkGqqcBkLUen5fbu94lAsZWJ0ZSjGdgenrzljUlvDUWNdaBsuyh8s

