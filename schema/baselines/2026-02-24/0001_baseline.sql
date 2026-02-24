--
-- PostgreSQL database dump
--

\restrict lxPpmBm0KudOnUX8navbWWRO866S82nSg1oGj6NX7b4kX6wz6ElBnZWDSiQL7PH

-- Dumped from database version 18.2 (Debian 18.2-1.pgdg13+1)
-- Dumped by pg_dump version 18.2 (Debian 18.2-1.pgdg13+1)

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
-- Name: policy_version_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.policy_version_status AS ENUM (
    'ACTIVE',
    'GRACE',
    'RETIRED'
);


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


SET default_tablespace = '';

SET default_table_access_method = heap;

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
    CONSTRAINT member_device_events_event_type_check CHECK ((event_type = ANY (ARRAY['ENROLLED_DEVICE'::text, 'UNREGISTERED_DEVICE'::text, 'REVOKED_DEVICE_ATTEMPT'::text])))
);


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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version text NOT NULL,
    checksum text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


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
-- Name: instruction_settlement_finality instruction_settlement_finality_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instruction_settlement_finality
    ADD CONSTRAINT instruction_settlement_finality_pkey PRIMARY KEY (finality_id);


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
-- Name: persons persons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persons
    ADD CONSTRAINT persons_pkey PRIMARY KEY (person_id);


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
-- Name: pii_vault_records pii_vault_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pii_vault_records
    ADD CONSTRAINT pii_vault_records_pkey PRIMARY KEY (vault_id);


--
-- Name: policy_versions policy_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_versions
    ADD CONSTRAINT policy_versions_pkey PRIMARY KEY (version);


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
-- Name: rail_dispatch_truth_anchor rail_dispatch_truth_anchor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rail_dispatch_truth_anchor
    ADD CONSTRAINT rail_dispatch_truth_anchor_pkey PRIMARY KEY (anchor_id);


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
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


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
-- Name: idx_anchor_sync_operations_state_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_anchor_sync_operations_state_due ON public.anchor_sync_operations USING btree (state, lease_expires_at, updated_at);


--
-- Name: idx_attempts_instruction_idempotency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attempts_instruction_idempotency ON public.payment_outbox_attempts USING btree (instruction_id, idempotency_key);


--
-- Name: idx_attempts_outbox_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attempts_outbox_id ON public.payment_outbox_attempts USING btree (outbox_id);


--
-- Name: idx_billing_usage_events_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_billing_usage_events_correlation_id ON public.billing_usage_events USING btree (correlation_id);


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
-- Name: idx_evidence_packs_anchor_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_packs_anchor_ref ON public.evidence_packs USING btree (anchor_ref) WHERE (anchor_ref IS NOT NULL);


--
-- Name: idx_evidence_packs_correlation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evidence_packs_correlation_id ON public.evidence_packs USING btree (correlation_id);


--
-- Name: idx_external_proofs_attestation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_external_proofs_attestation_id ON public.external_proofs USING btree (attestation_id);


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
-- Name: idx_programs_tenant_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_programs_tenant_status ON public.programs USING btree (tenant_id, status);


--
-- Name: idx_rail_truth_anchor_participant_anchored; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rail_truth_anchor_participant_anchored ON public.rail_dispatch_truth_anchor USING btree (rail_participant_id, anchored_at DESC);


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
-- Name: ux_billable_clients_client_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_billable_clients_client_key ON public.billable_clients USING btree (client_key) WHERE (client_key IS NOT NULL);


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
-- Name: payment_outbox_attempts trg_anchor_dispatched_outbox_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_anchor_dispatched_outbox_attempt AFTER INSERT ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.anchor_dispatched_outbox_attempt();


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
-- Name: instruction_settlement_finality trg_enforce_instruction_reversal_source; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_enforce_instruction_reversal_source BEFORE INSERT ON public.instruction_settlement_finality FOR EACH ROW EXECUTE FUNCTION public.enforce_instruction_reversal_source();


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
-- Name: anchor_sync_operations anchor_sync_operations_pack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anchor_sync_operations
    ADD CONSTRAINT anchor_sync_operations_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.evidence_packs(pack_id);


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
-- Name: escrow_accounts escrow_accounts_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escrow_accounts
    ADD CONSTRAINT escrow_accounts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


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
-- Name: evidence_pack_items evidence_pack_items_pack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evidence_pack_items
    ADD CONSTRAINT evidence_pack_items_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.evidence_packs(pack_id);


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
-- Name: programs programs_program_escrow_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_program_escrow_id_fkey FOREIGN KEY (program_escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;


--
-- Name: programs programs_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;


--
-- Name: rail_dispatch_truth_anchor rail_truth_anchor_attempt_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rail_dispatch_truth_anchor
    ADD CONSTRAINT rail_truth_anchor_attempt_fk FOREIGN KEY (attempt_id) REFERENCES public.payment_outbox_attempts(attempt_id) DEFERRABLE;


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
-- PostgreSQL database dump complete
--

\unrestrict lxPpmBm0KudOnUX8navbWWRO866S82nSg1oGj6NX7b4kX6wz6ElBnZWDSiQL7PH

