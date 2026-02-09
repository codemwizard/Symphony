             p.idempotency_key, p.rail_type, p.payload
          'RETRY_CEILING_EXCEEDED', 'expired lease repair hit retry ceiling', p_worker_id
          AND p.idempotency_key = p_idempotency_key
          RAISE;
          SELECT gen_random_uuid();
          attempt_count = GREATEST(attempt_count, v_next_attempt_no),
          attempt_no, state, claimed_at, completed_at, error_code, error_message, worker_id
          attempt_no, state, claimed_at, completed_at, worker_id
          claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
          next_attempt_at = NOW() + INTERVAL '1 second',
          outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
          outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
          v_next_attempt_no, 'FAILED', NOW(), NOW(),
          v_next_attempt_no, 'ZOMBIE_REQUEUE', NOW(), NOW(), p_worker_id
          v_record.idempotency_key, v_record.rail_type, v_record.payload,
          v_record.idempotency_key, v_record.rail_type, v_record.payload,
          v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
          v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
        $$;
        ) VALUES (
        ) VALUES (
        );
        );
        DELETE FROM payment_outbox_pending WHERE outbox_id = v_record.outbox_id;
        DETAIL = 'Lease missing/expired or token mismatch; refusing to complete';
        END IF;
        FROM payment_outbox_pending p
        IF NOT FOUND THEN
        INSERT INTO payment_outbox_attempts (
        INSERT INTO payment_outbox_attempts (
        INTO existing_pending
        LIMIT 1;
        SELECT p.outbox_id, p.sequence_id, p.created_at
        UPDATE payment_outbox_pending SET
        WHERE p.instruction_id = p_instruction_id
        WHERE payment_outbox_pending.outbox_id = v_record.outbox_id;
        allocated_sequence,
        attempt_count = GREATEST(attempt_count, v_next_attempt_no),
        claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
        idempotency_key,
        instruction_id,
        next_attempt_at = NOW() + make_interval(secs => GREATEST(1, COALESCE(p_retry_delay_seconds, 1))),
        p_idempotency_key,
        p_instruction_id,
        p_participant_id,
        p_payload
        p_rail_type,
        participant_id,
        payload
        rail_type,
        sequence_id,
      )
      )
      AND a.idempotency_key = p_idempotency_key
      AND p.idempotency_key = p_idempotency_key
      AND p.lease_token = p_lease_token AND p.lease_expires_at > NOW()
      CASE WHEN v_effective_state IN ('DISPATCHED', 'FAILED') THEN NOW() ELSE NULL END,
      DELETE FROM payment_outbox_pending WHERE outbox_id = p_outbox_id;
      ELSE
      END IF;
      FROM payment_outbox_attempts a WHERE a.outbox_id = v_record.outbox_id;
      FROM payment_outbox_pending p
      IF v_next_attempt_no >= v_retry_ceiling THEN
      INSERT INTO payment_outbox_pending (
      INTO existing_pending;
      ORDER BY p.lease_expires_at ASC, p.created_at ASC LIMIT p_batch_size FOR UPDATE SKIP LOCKED
      RAISE EXCEPTION 'Invalid completion state %', p_state USING ERRCODE = 'P7003';
      RAISE EXCEPTION 'LEASE_LOST' USING ERRCODE = 'P7002',
      RETURN NEXT;
      RETURN QUERY SELECT existing_attempt.outbox_id, existing_attempt.sequence_id, existing_attempt.created_at, existing_attempt.state::TEXT;
      RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
      RETURN;
      RETURN;
      RETURNING payment_outbox_pending.outbox_id, payment_outbox_pending.sequence_id, payment_outbox_pending.created_at
      SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
      SELECT p.outbox_id, p.instruction_id, p.participant_id, p.sequence_id,
      SET next_sequence_id = participant_outbox_sequences.next_sequence_id + 1
      UPDATE payment_outbox_pending SET
      USING ERRCODE = '23503';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P7201';
      USING ERRCODE = 'P7202';
      VALUES (
      WHEN unique_violation THEN
      WHERE outbox_id = p_outbox_id;
      WHERE p.claimed_by IS NOT NULL AND p.lease_token IS NOT NULL AND p.lease_expires_at <= NOW()
      attempt_no := v_next_attempt_no;
      attempt_no, state, claimed_at, completed_at, rail_reference, rail_code,
      error_code, error_message, latency_ms, worker_id
      hashtextextended(p_instruction_id || chr(31) || p_idempotency_key, 1)
      outbox_id := v_record.outbox_id;
      outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
      p_outbox_id, v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload,
      p_rail_reference, p_rail_code, p_error_code, p_error_message, p_latency_ms, p_worker_id
      v_effective_state := 'FAILED';
      v_next_attempt_no, v_effective_state, NOW(),
     claimed_by = p_worker_id,
     lease_expires_at = NOW() + make_interval(secs => p_lease_seconds)
     lease_token = public.uuid_v7_or_random(),
     p.attempt_count,
     p.idempotency_key,
     p.instruction_id,
     p.lease_expires_at
     p.lease_token,
     p.outbox_id,
     p.participant_id,
     p.payload,
     p.rail_type,
     p.sequence_id,
    'ACTIVE',
    'DISPATCHED',
    'DISPATCHING',
    'FAILED',
    'GRACE',
    'RETIRED'
    'RETRYABLE',
    'ZOMBIE_REQUEUE'
    ) VALUES (
    );
    );
    20
    ADD CONSTRAINT billable_clients_client_key_required_new_rows_chk CHECK (((client_key IS NOT NULL) AND (length(btrim(client_key)) > 0))) NOT VALID;
    ADD CONSTRAINT billable_clients_pkey PRIMARY KEY (billable_client_id);
    ADD CONSTRAINT billing_usage_events_billable_client_id_fkey FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id);
    ADD CONSTRAINT billing_usage_events_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.tenant_clients(client_id);
    ADD CONSTRAINT billing_usage_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT billing_usage_events_subject_client_id_fkey FOREIGN KEY (subject_client_id) REFERENCES public.tenant_clients(client_id);
    ADD CONSTRAINT billing_usage_events_subject_member_id_fkey FOREIGN KEY (subject_member_id) REFERENCES public.tenant_members(member_id);
    ADD CONSTRAINT billing_usage_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT evidence_pack_items_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.evidence_packs(pack_id);
    ADD CONSTRAINT evidence_pack_items_pkey PRIMARY KEY (item_id);
    ADD CONSTRAINT evidence_packs_pkey PRIMARY KEY (pack_id);
    ADD CONSTRAINT external_proofs_attestation_id_fkey FOREIGN KEY (attestation_id) REFERENCES public.ingress_attestations(attestation_id);
    ADD CONSTRAINT external_proofs_billable_client_fk FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id) NOT VALID;
    ADD CONSTRAINT external_proofs_billable_client_required_new_rows_chk CHECK ((billable_client_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT external_proofs_pkey PRIMARY KEY (proof_id);
    ADD CONSTRAINT external_proofs_subject_member_fk FOREIGN KEY (subject_member_id) REFERENCES public.tenant_members(member_id) NOT VALID;
    ADD CONSTRAINT external_proofs_tenant_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) NOT VALID;
    ADD CONSTRAINT external_proofs_tenant_required_new_rows_chk CHECK ((tenant_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT ingress_attestations_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.tenant_clients(client_id);
    ADD CONSTRAINT ingress_attestations_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT ingress_attestations_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.tenant_members(member_id);
    ADD CONSTRAINT ingress_attestations_pkey PRIMARY KEY (attestation_id);
    ADD CONSTRAINT participant_outbox_sequences_pkey PRIMARY KEY (participant_id);
    ADD CONSTRAINT participants_pkey PRIMARY KEY (participant_id);
    ADD CONSTRAINT payment_outbox_attempts_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT payment_outbox_attempts_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.tenant_members(member_id);
    ADD CONSTRAINT payment_outbox_attempts_pkey PRIMARY KEY (attempt_id);
    ADD CONSTRAINT payment_outbox_attempts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT payment_outbox_pending_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT payment_outbox_pending_pkey PRIMARY KEY (outbox_id);
    ADD CONSTRAINT payment_outbox_pending_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT policy_versions_pkey PRIMARY KEY (version);
    ADD CONSTRAINT revoked_client_certs_pkey PRIMARY KEY (cert_fingerprint_sha256);
    ADD CONSTRAINT revoked_tokens_pkey PRIMARY KEY (token_jti);
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);
    ADD CONSTRAINT tenant_clients_pkey PRIMARY KEY (client_id);
    ADD CONSTRAINT tenant_clients_tenant_id_client_key_key UNIQUE (tenant_id, client_key);
    ADD CONSTRAINT tenant_clients_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT tenant_members_pkey PRIMARY KEY (member_id);
    ADD CONSTRAINT tenant_members_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT tenant_members_tenant_id_member_ref_key UNIQUE (tenant_id, member_ref);
    ADD CONSTRAINT tenants_billable_client_fk FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id) NOT VALID;
    ADD CONSTRAINT tenants_billable_client_required_new_rows_chk CHECK ((billable_client_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT tenants_parent_tenant_fk FOREIGN KEY (parent_tenant_id) REFERENCES public.tenants(tenant_id) NOT VALID;
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (tenant_id);
    ADD CONSTRAINT tenants_tenant_key_key UNIQUE (tenant_key);
    ADD CONSTRAINT ux_attempts_outbox_attempt_no UNIQUE (outbox_id, attempt_no);
    ADD CONSTRAINT ux_evidence_pack_items_pack_hash UNIQUE (pack_id, artifact_hash);
    ADD CONSTRAINT ux_pending_idempotency UNIQUE (instruction_id, idempotency_key);
    ADD CONSTRAINT ux_pending_participant_sequence UNIQUE (participant_id, sequence_id);
    AND (p.lease_expires_at IS NULL OR p.lease_expires_at <= NOW())
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    AS $$
    BEGIN
    CONSTRAINT billable_clients_client_type_check CHECK ((client_type = ANY (ARRAY['BANK'::text, 'MMO'::text, 'NGO'::text, 'GOV_PROGRAM'::text, 'COOP_FEDERATION'::text, 'ENTERPRISE'::text]))),
    CONSTRAINT billable_clients_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT billing_usage_events_event_type_check CHECK ((event_type = ANY (ARRAY['EVIDENCE_BUNDLE'::text, 'CASE_PACK'::text, 'EXCEPTION_TRIAGE'::text, 'RETENTION_ANCHOR'::text, 'ESCROW_RELEASE'::text, 'DISPUTE_PACK'::text]))),
    CONSTRAINT billing_usage_events_member_requires_tenant_chk CHECK (((subject_member_id IS NULL) OR (tenant_id IS NOT NULL))),
    CONSTRAINT billing_usage_events_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT billing_usage_events_subject_zero_or_one_chk CHECK (((((subject_member_id IS NOT NULL))::integer + ((subject_client_id IS NOT NULL))::integer) <= 1)),
    CONSTRAINT billing_usage_events_units_check CHECK ((units = ANY (ARRAY['count'::text, 'bytes'::text, 'seconds'::text, 'events'::text])))
    CONSTRAINT ck_attempts_payload_is_object CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT ck_pending_payload_is_object CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT ck_policy_active_has_no_grace_expiry CHECK (((status <> 'ACTIVE'::public.policy_version_status) OR (grace_expires_at IS NULL))),
    CONSTRAINT ck_policy_checksum_nonempty CHECK ((length(checksum) > 0)),
    CONSTRAINT ck_policy_grace_requires_expiry CHECK (((status <> 'GRACE'::public.policy_version_status) OR (grace_expires_at IS NOT NULL)))
    CONSTRAINT evidence_pack_items_path_or_hash_chk CHECK (((artifact_path IS NOT NULL) OR (artifact_hash IS NOT NULL)))
    CONSTRAINT evidence_packs_pack_type_check CHECK ((pack_type = ANY (ARRAY['INSTRUCTION_BUNDLE'::text, 'INCIDENT_PACK'::text, 'DISPUTE_PACK'::text])))
    CONSTRAINT participant_outbox_sequences_next_sequence_id_check CHECK ((next_sequence_id >= 1))
    CONSTRAINT participants_participant_kind_check CHECK ((participant_kind = ANY (ARRAY['BANK'::text, 'MMO'::text, 'NGO'::text, 'GOV_PROGRAM'::text, 'COOP_FEDERATION'::text, 'ENTERPRISE'::text, 'INTERNAL'::text]))),
    CONSTRAINT participants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT payment_outbox_attempts_attempt_no_check CHECK ((attempt_no >= 1)),
    CONSTRAINT payment_outbox_attempts_latency_ms_check CHECK (((latency_ms IS NULL) OR (latency_ms >= 0)))
    CONSTRAINT payment_outbox_pending_attempt_count_check CHECK ((attempt_count >= 0))
    CONSTRAINT tenant_clients_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'REVOKED'::text])))
    CONSTRAINT tenant_members_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'EXITED'::text])))
    CONSTRAINT tenants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text]))),
    CONSTRAINT tenants_tenant_type_check CHECK ((tenant_type = ANY (ARRAY['NGO'::text, 'COOPERATIVE'::text, 'GOVERNMENT'::text, 'COMMERCIAL'::text])))
    DO UPDATE
    ELSE
    ELSE 'gen_random_uuid'
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END LOOP;
    END;
    EXCEPTION
    FOR UPDATE;
    FOR v_record IN
    FROM payment_outbox_attempts a
    FROM payment_outbox_attempts a WHERE a.outbox_id = p_outbox_id;
    FROM payment_outbox_pending p
    FROM payment_outbox_pending p
    FROM public.ingress_attestations ia
    FROM public.tenants t
    IF FOUND THEN
    IF FOUND THEN
    IF NOT FOUND THEN
    IF p_state = 'RETRYABLE' AND v_next_attempt_no >= public.outbox_retry_ceiling() THEN
    IF p_state NOT IN ('DISPATCHED', 'FAILED', 'RETRYABLE') THEN
    IF v_effective_state IN ('DISPATCHED', 'FAILED') THEN
    INSERT INTO participant_outbox_sequences(participant_id, next_sequence_id)
    INSERT INTO payment_outbox_attempts (
    INTO derived_billable_client_id
    INTO derived_tenant_id
    INTO existing_attempt
    INTO existing_pending
    INTO v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE sql
    LANGUAGE sql SECURITY DEFINER
    LANGUAGE sql STABLE
    LANGUAGE sql STABLE
    LIMIT 1;
    LIMIT 1;
    LOOP
    NEW.billable_client_id := derived_billable_client_id;
    NEW.correlation_id := public.uuid_v7_or_random();
    NEW.tenant_id := derived_tenant_id;
    NULLIF(current_setting('symphony.outbox_retry_ceiling', true), '')::int,
    ON CONFLICT (participant_id)
    ORDER BY a.claimed_at DESC
    PERFORM pg_advisory_xact_lock(
    PERFORM pg_notify('symphony_outbox', '');
    RAISE EXCEPTION '% is append-only', TG_TABLE_NAME
    RAISE EXCEPTION 'external_proofs billable_client_id does not match derived billable_client_id'
    RAISE EXCEPTION 'external_proofs requires billable_client_id attribution via tenant'
    RAISE EXCEPTION 'external_proofs requires tenant attribution via ingress_attestations'
    RAISE EXCEPTION 'external_proofs tenant_id does not match derived tenant_id'
    RAISE EXCEPTION 'ingress_attestations is append-only'
    RAISE EXCEPTION 'member/tenant mismatch'
    RAISE EXCEPTION 'member_id not found'
    RAISE EXCEPTION 'payment_outbox_attempts is append-only'
    RAISE EXCEPTION 'revocation tables are append-only'
    RAISE EXCEPTION 'tenant_id required when member_id is set'
    RETURN NEW;
    RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
    RETURN QUERY SELECT v_next_attempt_no, v_effective_state;
    RETURN allocated;
    RETURN;
    RETURNING (participant_outbox_sequences.next_sequence_id - 1) INTO allocated;
    SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
    SELECT a.outbox_id, a.sequence_id, a.created_at, a.state
    SELECT p.instruction_id, p.participant_id, p.sequence_id, p.idempotency_key, p.rail_type, p.payload
    SELECT p.outbox_id, p.sequence_id, p.created_at
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    VALUES (p_participant_id, 2)
    WHEN to_regprocedure('public.uuidv7()') IS NOT NULL THEN 'uuidv7'
    WHERE a.instruction_id = p_instruction_id
    WHERE p.instruction_id = p_instruction_id
    WHERE p.outbox_id = p_outbox_id AND p.claimed_by = p_worker_id
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    allocated BIGINT;
    allocated_sequence := bump_participant_outbox_seq(p_participant_id);
    allocated_sequence BIGINT;
    anchor_ref text,
    anchor_type text,
    anchored_at timestamp with time zone,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
    artifact_hash text NOT NULL,
    artifact_path text,
    attempt_count integer DEFAULT 0 NOT NULL,
    attempt_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    attempt_no integer NOT NULL,
    attestation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    attestation_id uuid NOT NULL,
    billable_client_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    billable_client_id uuid NOT NULL,
    billable_client_id uuid,
    billable_client_id uuid,
    cert_fingerprint_sha256 text NOT NULL,
    cert_fingerprint_sha256 text,
    checksum text NOT NULL,
    checksum text NOT NULL,
    claimed_at timestamp with time zone DEFAULT now() NOT NULL,
    claimed_by text,
    client_id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid,
    client_id uuid,
    client_id_hash text,
    client_key text NOT NULL,
    client_key text,
    client_type text NOT NULL,
    completed_at timestamp with time zone,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    display_name text NOT NULL,
    downstream_ref text,
    downstream_ref text,
    downstream_ref text,
    error_code text,
    error_message text,
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    event_type text NOT NULL,
    existing_attempt RECORD;
    existing_pending RECORD;
    expires_at timestamp with time zone,
    expires_at timestamp with time zone,
    expires_at timestamp with time zone,
    grace_expires_at timestamp with time zone,
    idempotency_key text NOT NULL,
    idempotency_key text NOT NULL,
    idempotency_key text,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    is_active boolean GENERATED ALWAYS AS ((status = 'ACTIVE'::public.policy_version_status)) STORED,
    item_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    latency_ms integer,
    lease_expires_at timestamp with time zone,
    lease_token uuid,
    legal_name text NOT NULL,
    legal_name text NOT NULL,
    member_id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid,
    member_id uuid,
    member_ref text NOT NULL,
    metadata jsonb,
    metadata jsonb,
    msisdn_hash bytea,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    next_sequence_id bigint NOT NULL,
    nfs_sequence_ref text
    nfs_sequence_ref text,
    nfs_sequence_ref text,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    outbox_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    outbox_id uuid NOT NULL,
    pack_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    pack_id uuid NOT NULL,
    pack_type text NOT NULL,
    parent_tenant_id uuid,
    participant_id text NOT NULL,
    participant_id text NOT NULL,
    participant_id text NOT NULL,
    participant_id text NOT NULL,
    participant_id text,
    participant_kind text NOT NULL,
    payload jsonb NOT NULL,
    payload jsonb NOT NULL,
    payload_hash text NOT NULL,
    proof_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    provider text NOT NULL,
    provider_ref text,
    quantity bigint NOT NULL,
    rail_code text,
    rail_reference text,
    rail_type text NOT NULL,
    rail_type text NOT NULL,
    reason_code text,
    reason_code text,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    regulator_ref text,
    request_hash text NOT NULL,
    response_hash text NOT NULL,
    revoked_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_by text
    revoked_by text
    root_hash text,
    sequence_id bigint NOT NULL,
    sequence_id bigint NOT NULL,
    signature text,
    signature_alg text,
    signature_hash text,
    signatures jsonb DEFAULT '[]'::jsonb NOT NULL,
    signed_at timestamp with time zone,
    signer_participant_id text,
    state public.outbox_attempt_state NOT NULL,
    status public.policy_version_status DEFAULT 'ACTIVE'::public.policy_version_status NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    subject_client_id uuid,
    subject_member_id uuid
    subject_member_id uuid,
    tenant_id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid,
    tenant_id uuid,
    tenant_id uuid,
    tenant_id uuid,
    tenant_key text NOT NULL,
    tenant_name text NOT NULL,
    tenant_type text NOT NULL,
    token_jti text NOT NULL,
    token_jti_hash text,
    tpin_hash bytea,
    units text NOT NULL,
    upstream_ref text,
    upstream_ref text,
    upstream_ref text,
    v_effective_state := p_state;
    v_idempotency_key TEXT; v_rail_type TEXT; v_payload JSONB;
    v_instruction_id TEXT; v_participant_id TEXT; v_sequence_id BIGINT;
    v_next_attempt_no INT;
    v_next_attempt_no INT; v_effective_state outbox_attempt_state;
    v_record RECORD;
    v_retry_ceiling := public.outbox_retry_ceiling();
    v_retry_ceiling INT;
    verified_at timestamp with time zone,
    version text NOT NULL,
    version text NOT NULL,
    worker_id text,
   FROM due
   RETURNING
   SET
   UPDATE payment_outbox_pending p
   WHERE ia.attestation_id = NEW.attestation_id;
   WHERE p.outbox_id = due.outbox_id
   WHERE t.tenant_id = derived_tenant_id;
  );
  BEGIN
  BEGIN
  BEGIN
  BEGIN
  BEGIN
  BEGIN
  BEGIN
  BEGIN
  DECLARE
  DECLARE
  DECLARE
  DECLARE
  ELSIF NEW.billable_client_id <> derived_billable_client_id THEN
  ELSIF NEW.tenant_id <> derived_tenant_id THEN
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END;
  END;
  END;
  END;
  END;
  END;
  END;
  END;
  END;
  FOR UPDATE SKIP LOCKED
  FROM payment_outbox_pending p
  FROM public.tenant_members
  IF NEW.billable_client_id IS NULL THEN
  IF NEW.correlation_id IS NULL THEN
  IF NEW.member_id IS NULL THEN
  IF NEW.tenant_id IS NULL THEN
  IF NEW.tenant_id IS NULL THEN
  IF derived_billable_client_id IS NULL THEN
  IF derived_tenant_id IS NULL THEN
  IF m_tenant <> NEW.tenant_id THEN
  IF m_tenant IS NULL THEN
  LIMIT p_batch_size
  ORDER BY p.next_attempt_at ASC, p.created_at ASC
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  SELECT CASE
  SELECT COALESCE(
  SELECT ia.tenant_id
  SELECT p.outbox_id
  SELECT t.billable_client_id
  SELECT tenant_id INTO m_tenant
  WHERE member_id = NEW.member_id;
  WHERE p.next_attempt_at <= NOW()
  derived_billable_client_id UUID;
  derived_tenant_id UUID;
  m_tenant uuid;
 $$;
 )
 ),
 SELECT * FROM leased;
 leased AS (
$$;
$$;
$$;
$$;
$$;
$$;
$$;
$$;
$$;
$$;
$$;
$$;
$$;
)
);
);
);
);
);
);
);
);
);
);
);
);
);
);
);
);
);
);
ALTER TABLE ONLY public.billable_clients
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_packs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.ingress_attestations
ALTER TABLE ONLY public.ingress_attestations
ALTER TABLE ONLY public.ingress_attestations
ALTER TABLE ONLY public.participant_outbox_sequences
ALTER TABLE ONLY public.participants
ALTER TABLE ONLY public.payment_outbox_attempts
ALTER TABLE ONLY public.payment_outbox_attempts
ALTER TABLE ONLY public.payment_outbox_attempts
ALTER TABLE ONLY public.payment_outbox_attempts
ALTER TABLE ONLY public.payment_outbox_pending
ALTER TABLE ONLY public.payment_outbox_pending
ALTER TABLE ONLY public.payment_outbox_pending
ALTER TABLE ONLY public.payment_outbox_pending
ALTER TABLE ONLY public.policy_versions
ALTER TABLE ONLY public.revoked_client_certs
ALTER TABLE ONLY public.revoked_tokens
ALTER TABLE ONLY public.schema_migrations
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE public.billable_clients
ALTER TABLE public.external_proofs
ALTER TABLE public.external_proofs
ALTER TABLE public.ingress_attestations
ALTER TABLE public.payment_outbox_attempts
ALTER TABLE public.payment_outbox_pending
ALTER TABLE public.tenants
BEGIN
BEGIN
BEGIN
CREATE FUNCTION public.bump_participant_outbox_seq(p_participant_id text) RETURNS bigint
CREATE FUNCTION public.claim_outbox_batch(p_batch_size integer, p_worker_id text, p_lease_seconds integer) RETURNS TABLE(outbox_id uuid, instruction_id text, participant_id text, sequence_id bigint, idempotency_key text, rail_type text, payload jsonb, attempt_count integer, lease_token uuid, lease_expires_at timestamp with time zone)
CREATE FUNCTION public.complete_outbox_attempt(p_outbox_id uuid, p_lease_token uuid, p_worker_id text, p_state public.outbox_attempt_state, p_rail_reference text DEFAULT NULL::text, p_rail_code text DEFAULT NULL::text, p_error_code text DEFAULT NULL::text, p_error_message text DEFAULT NULL::text, p_latency_ms integer DEFAULT NULL::integer, p_retry_delay_seconds integer DEFAULT 1) RETURNS TABLE(attempt_no integer, state public.outbox_attempt_state)
CREATE FUNCTION public.deny_append_only_mutation() RETURNS trigger
CREATE FUNCTION public.deny_ingress_attestations_mutation() RETURNS trigger
CREATE FUNCTION public.deny_outbox_attempts_mutation() RETURNS trigger
CREATE FUNCTION public.deny_revocation_mutation() RETURNS trigger
CREATE FUNCTION public.enforce_member_tenant_match() RETURNS trigger
CREATE FUNCTION public.enqueue_payment_outbox(p_instruction_id text, p_participant_id text, p_idempotency_key text, p_rail_type text, p_payload jsonb) RETURNS TABLE(outbox_id uuid, sequence_id bigint, created_at timestamp with time zone, state text)
CREATE FUNCTION public.outbox_retry_ceiling() RETURNS integer
CREATE FUNCTION public.repair_expired_leases(p_batch_size integer, p_worker_id text) RETURNS TABLE(outbox_id uuid, attempt_no integer)
CREATE FUNCTION public.set_correlation_id_if_null() RETURNS trigger
CREATE FUNCTION public.set_external_proofs_attribution() RETURNS trigger
CREATE FUNCTION public.uuid_strategy() RETURNS text
CREATE FUNCTION public.uuid_v7_or_random() RETURNS uuid
CREATE INDEX idx_attempts_instruction_idempotency ON public.payment_outbox_attempts USING btree (instruction_id, idempotency_key);
CREATE INDEX idx_attempts_outbox_id ON public.payment_outbox_attempts USING btree (outbox_id);
CREATE INDEX idx_billing_usage_events_correlation_id ON public.billing_usage_events USING btree (correlation_id);
CREATE INDEX idx_evidence_packs_anchor_ref ON public.evidence_packs USING btree (anchor_ref) WHERE (anchor_ref IS NOT NULL);
CREATE INDEX idx_evidence_packs_correlation_id ON public.evidence_packs USING btree (correlation_id);
CREATE INDEX idx_external_proofs_attestation_id ON public.external_proofs USING btree (attestation_id);
CREATE INDEX idx_ingress_attestations_cert_fpr ON public.ingress_attestations USING btree (cert_fingerprint_sha256) WHERE (cert_fingerprint_sha256 IS NOT NULL);
CREATE INDEX idx_ingress_attestations_correlation_id ON public.ingress_attestations USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_ingress_attestations_instruction ON public.ingress_attestations USING btree (instruction_id);
CREATE INDEX idx_ingress_attestations_member_received ON public.ingress_attestations USING btree (member_id, received_at) WHERE (member_id IS NOT NULL);
CREATE INDEX idx_ingress_attestations_received_at ON public.ingress_attestations USING btree (received_at);
CREATE INDEX idx_ingress_attestations_tenant_correlation ON public.ingress_attestations USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_ingress_attestations_tenant_received ON public.ingress_attestations USING btree (tenant_id, received_at) WHERE (tenant_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_attempts_correlation_id ON public.payment_outbox_attempts USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_attempts_tenant_correlation ON public.payment_outbox_attempts USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_pending_correlation_id ON public.payment_outbox_pending USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_pending_due_claim ON public.payment_outbox_pending USING btree (next_attempt_at, lease_expires_at, created_at);
CREATE INDEX idx_payment_outbox_pending_tenant_correlation ON public.payment_outbox_pending USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_pending_tenant_due ON public.payment_outbox_pending USING btree (tenant_id, next_attempt_at) WHERE (tenant_id IS NOT NULL);
CREATE INDEX idx_policy_versions_is_active ON public.policy_versions USING btree (is_active) WHERE (is_active = true);
CREATE INDEX idx_tenant_clients_tenant ON public.tenant_clients USING btree (tenant_id);
CREATE INDEX idx_tenant_members_status ON public.tenant_members USING btree (status);
CREATE INDEX idx_tenant_members_tenant ON public.tenant_members USING btree (tenant_id);
CREATE INDEX idx_tenants_billable_client_id ON public.tenants USING btree (billable_client_id);
CREATE INDEX idx_tenants_parent_tenant_id ON public.tenants USING btree (parent_tenant_id);
CREATE INDEX idx_tenants_status ON public.tenants USING btree (status);
CREATE SCHEMA public;
CREATE TABLE public.billable_clients (
CREATE TABLE public.billing_usage_events (
CREATE TABLE public.evidence_pack_items (
CREATE TABLE public.evidence_packs (
CREATE TABLE public.external_proofs (
CREATE TABLE public.ingress_attestations (
CREATE TABLE public.participant_outbox_sequences (
CREATE TABLE public.participants (
CREATE TABLE public.payment_outbox_attempts (
CREATE TABLE public.payment_outbox_pending (
CREATE TABLE public.policy_versions (
CREATE TABLE public.revoked_client_certs (
CREATE TABLE public.revoked_tokens (
CREATE TABLE public.schema_migrations (
CREATE TABLE public.tenant_clients (
CREATE TABLE public.tenant_members (
CREATE TABLE public.tenants (
CREATE TRIGGER trg_deny_billing_usage_events_mutation BEFORE DELETE OR UPDATE ON public.billing_usage_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_evidence_pack_items_mutation BEFORE DELETE OR UPDATE ON public.evidence_pack_items FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_evidence_packs_mutation BEFORE DELETE OR UPDATE ON public.evidence_packs FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_external_proofs_mutation BEFORE DELETE OR UPDATE ON public.external_proofs FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_ingress_attestations_mutation BEFORE DELETE OR UPDATE ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.deny_ingress_attestations_mutation();
CREATE TRIGGER trg_deny_outbox_attempts_mutation BEFORE DELETE OR UPDATE ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.deny_outbox_attempts_mutation();
CREATE TRIGGER trg_deny_revoked_client_certs_mutation BEFORE DELETE OR UPDATE ON public.revoked_client_certs FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();
CREATE TRIGGER trg_deny_revoked_tokens_mutation BEFORE DELETE OR UPDATE ON public.revoked_tokens FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();
CREATE TRIGGER trg_ingress_member_tenant_match BEFORE INSERT ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.enforce_member_tenant_match();
CREATE TRIGGER trg_set_corr_id_ingress_attestations BEFORE INSERT ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();
CREATE TRIGGER trg_set_corr_id_payment_outbox_attempts BEFORE INSERT ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();
CREATE TRIGGER trg_set_corr_id_payment_outbox_pending BEFORE INSERT ON public.payment_outbox_pending FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();
CREATE TRIGGER trg_set_external_proofs_attribution BEFORE INSERT ON public.external_proofs FOR EACH ROW EXECUTE FUNCTION public.set_external_proofs_attribution();
CREATE TYPE public.outbox_attempt_state AS ENUM (
CREATE TYPE public.policy_version_status AS ENUM (
CREATE UNIQUE INDEX ux_billable_clients_client_key ON public.billable_clients USING btree (client_key) WHERE (client_key IS NOT NULL);
CREATE UNIQUE INDEX ux_billing_usage_events_idempotency ON public.billing_usage_events USING btree (billable_client_id, idempotency_key) WHERE (idempotency_key IS NOT NULL);
CREATE UNIQUE INDEX ux_ingress_attestations_tenant_instruction ON public.ingress_attestations USING btree (tenant_id, instruction_id);
CREATE UNIQUE INDEX ux_outbox_attempts_one_terminal_per_outbox ON public.payment_outbox_attempts USING btree (outbox_id) WHERE (state = ANY (ARRAY['DISPATCHED'::public.outbox_attempt_state, 'FAILED'::public.outbox_attempt_state]));
CREATE UNIQUE INDEX ux_policy_versions_single_active ON public.policy_versions USING btree ((1)) WHERE (status = 'ACTIVE'::public.policy_version_status);
DECLARE
DECLARE
END;
END;
END;
WITH (fillfactor='80');
WITH due AS (
