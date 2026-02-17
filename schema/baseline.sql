--
-- PostgreSQL database dump
--

\restrict Thqu4QFTiSn4oo0CYjk84rFEi3NCOE5QMkCBcm5O6ddFOL2ofrWfyDhBjAo98H3

-- Dumped from database version 18.1 (Debian 18.1-1.pgdg13+2)
-- Dumped by pg_dump version 18.1 (Debian 18.1-1.pgdg13+2)

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


SET default_tablespace = '';

SET default_table_access_method = heap;

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
    nfs_sequence_ref text
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
    CONSTRAINT ck_pending_payload_is_object CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT payment_outbox_pending_attempt_count_check CHECK ((attempt_count >= 0))
)
WITH (fillfactor='80');


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
-- Name: idx_pii_purge_requests_subject_requested; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pii_purge_requests_subject_requested ON public.pii_purge_requests USING btree (subject_token, requested_at DESC);


--
-- Name: idx_policy_versions_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_policy_versions_is_active ON public.policy_versions USING btree (is_active) WHERE (is_active = true);


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
-- Name: payment_outbox_attempts trg_anchor_dispatched_outbox_attempt; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_anchor_dispatched_outbox_attempt AFTER INSERT ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.anchor_dispatched_outbox_attempt();


--
-- Name: billing_usage_events trg_deny_billing_usage_events_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_billing_usage_events_mutation BEFORE DELETE OR UPDATE ON public.billing_usage_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();


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

\unrestrict Thqu4QFTiSn4oo0CYjk84rFEi3NCOE5QMkCBcm5O6ddFOL2ofrWfyDhBjAo98H3

