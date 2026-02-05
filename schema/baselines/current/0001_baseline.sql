--
-- PostgreSQL database dump
--

\restrict zZ4gOuitbEQME1k6FfQS52An54P8bfmTlFs5vNzUJ4oiweeS5UnjU7S88jwFzDR

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
    token_jti_hash text
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
    CONSTRAINT ck_pending_payload_is_object CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT payment_outbox_pending_attempt_count_check CHECK ((attempt_count >= 0))
)
WITH (fillfactor='80');


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
    CONSTRAINT tenants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text]))),
    CONSTRAINT tenants_tenant_type_check CHECK ((tenant_type = ANY (ARRAY['NGO'::text, 'COOPERATIVE'::text, 'GOVERNMENT'::text, 'COMMERCIAL'::text])))
);


--
-- Name: ingress_attestations ingress_attestations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingress_attestations
    ADD CONSTRAINT ingress_attestations_pkey PRIMARY KEY (attestation_id);


--
-- Name: participant_outbox_sequences participant_outbox_sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participant_outbox_sequences
    ADD CONSTRAINT participant_outbox_sequences_pkey PRIMARY KEY (participant_id);


--
-- Name: payment_outbox_attempts payment_outbox_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_attempts
    ADD CONSTRAINT payment_outbox_attempts_pkey PRIMARY KEY (attempt_id);


--
-- Name: payment_outbox_pending payment_outbox_pending_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_outbox_pending
    ADD CONSTRAINT payment_outbox_pending_pkey PRIMARY KEY (outbox_id);


--
-- Name: policy_versions policy_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policy_versions
    ADD CONSTRAINT policy_versions_pkey PRIMARY KEY (version);


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
-- Name: idx_attempts_instruction_idempotency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attempts_instruction_idempotency ON public.payment_outbox_attempts USING btree (instruction_id, idempotency_key);


--
-- Name: idx_attempts_outbox_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attempts_outbox_id ON public.payment_outbox_attempts USING btree (outbox_id);


--
-- Name: idx_ingress_attestations_cert_fpr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_cert_fpr ON public.ingress_attestations USING btree (cert_fingerprint_sha256) WHERE (cert_fingerprint_sha256 IS NOT NULL);


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
-- Name: idx_ingress_attestations_tenant_received; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ingress_attestations_tenant_received ON public.ingress_attestations USING btree (tenant_id, received_at) WHERE (tenant_id IS NOT NULL);


--
-- Name: idx_payment_outbox_pending_due_claim; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_outbox_pending_due_claim ON public.payment_outbox_pending USING btree (next_attempt_at, lease_expires_at, created_at);


--
-- Name: idx_payment_outbox_pending_tenant_due; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_outbox_pending_tenant_due ON public.payment_outbox_pending USING btree (tenant_id, next_attempt_at) WHERE (tenant_id IS NOT NULL);


--
-- Name: idx_policy_versions_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_policy_versions_is_active ON public.policy_versions USING btree (is_active) WHERE (is_active = true);


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
-- Name: idx_tenants_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tenants_status ON public.tenants USING btree (status);


--
-- Name: ux_ingress_attestations_tenant_instruction; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_ingress_attestations_tenant_instruction ON public.ingress_attestations USING btree (tenant_id, instruction_id);


--
-- Name: ux_outbox_attempts_one_terminal_per_outbox; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_outbox_attempts_one_terminal_per_outbox ON public.payment_outbox_attempts USING btree (outbox_id) WHERE (state = ANY (ARRAY['DISPATCHED'::public.outbox_attempt_state, 'FAILED'::public.outbox_attempt_state]));


--
-- Name: ux_policy_versions_single_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_policy_versions_single_active ON public.policy_versions USING btree ((1)) WHERE (status = 'ACTIVE'::public.policy_version_status);


--
-- Name: ingress_attestations trg_deny_ingress_attestations_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_ingress_attestations_mutation BEFORE DELETE OR UPDATE ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.deny_ingress_attestations_mutation();


--
-- Name: payment_outbox_attempts trg_deny_outbox_attempts_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_outbox_attempts_mutation BEFORE DELETE OR UPDATE ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.deny_outbox_attempts_mutation();


--
-- Name: revoked_client_certs trg_deny_revoked_client_certs_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_revoked_client_certs_mutation BEFORE DELETE OR UPDATE ON public.revoked_client_certs FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();


--
-- Name: revoked_tokens trg_deny_revoked_tokens_mutation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_deny_revoked_tokens_mutation BEFORE DELETE OR UPDATE ON public.revoked_tokens FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();


--
-- Name: ingress_attestations trg_ingress_member_tenant_match; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ingress_member_tenant_match BEFORE INSERT ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.enforce_member_tenant_match();


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
-- PostgreSQL database dump complete
--

\unrestrict zZ4gOuitbEQME1k6FfQS52An54P8bfmTlFs5vNzUJ4oiweeS5UnjU7S88jwFzDR

