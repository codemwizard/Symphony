             p.idempotency_key, p.rail_type, p.payload
          'RETRY_CEILING_EXCEEDED', 'expired lease repair hit retry ceiling', p_worker_id
          AND p.idempotency_key = p_idempotency_key
          RAISE;
          SELECT gen_random_uuid();
          attempt_count = GREATEST(attempt_count, v_next_attempt_no),
          attempt_no, state, claimed_at, completed_at, error_code, error_message, worker_id
          attempt_no, state, claimed_at, completed_at, worker_id
          claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
          instruction_id, adjustment_id, rail_id, reference_attempted,
          next_attempt_at = NOW() + INTERVAL '1 second',
          outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
          outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
          p_instruction_id, p_adjustment_id, p_rail_id, v_candidate,
          strategy_used, collision_count, outcome, policy_version_id
          v_next_attempt_no, 'FAILED', NOW(), NOW(),
          v_next_attempt_no, 'ZOMBIE_REQUEUE', NOW(), NOW(), p_worker_id
          v_record.idempotency_key, v_record.rail_type, v_record.payload,
          v_record.idempotency_key, v_record.rail_type, v_record.payload,
          v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
          v_record.outbox_id, v_record.instruction_id, v_record.participant_id, v_record.sequence_id,
          v_strategy.strategy_type, v_attempt, 'RESOLVED', v_strategy.policy_version_id
         purge_request_id = p_purge_request_id
         purged_at = NOW(),
        $$;
        'migrated_at', NOW(),
        'migrated_by', v_actor,
        'migrated_from_program_id', p_from_program_id,
        'migration_reason', v_reason
        ) VALUES (
        ) VALUES (
        ) VALUES (
        );
        );
        );
        AND (r.allocated_reference = v_candidate OR r.canonicalized_reference = v_canon)
        AND COALESCE(submitted_by, '') = v_actor
        AND status = 'PENDING_SUPERVISOR_APPROVAL'
        DELETE FROM payment_outbox_pending WHERE outbox_id = v_record.outbox_id;
        DETAIL = 'Lease missing/expired or token mismatch; refusing to complete';
        END IF;
        FROM payment_outbox_pending p
        IF NOT FOUND THEN
        INSERT INTO payment_outbox_attempts (
        INSERT INTO payment_outbox_attempts (
        INSERT INTO public.dispatch_reference_collision_events(
        INTO existing_pending
        LIMIT 1;
        SELECT p.outbox_id, p.sequence_id, p.created_at
        UPDATE payment_outbox_pending SET
        USING ERRCODE = '42501';
        WHERE p.instruction_id = p_instruction_id
        WHERE payment_outbox_pending.outbox_id = v_record.outbox_id;
        allocated_sequence,
        approved_at = NULL;
        approved_by = NULL,
        attempt_count = GREATEST(attempt_count, v_next_attempt_no),
        canonicalization_version = EXCLUDED.canonicalization_version,
        canonicalized_reference, strategy_used, policy_version_id, collision_retry_count
        claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
        containment_action = EXCLUDED.containment_action;
        contradiction_timestamp = EXCLUDED.contradiction_timestamp,
        decided_at = NULL,
        decided_at = NULL,
        decided_by = NULL,
        decided_by = NULL,
        decision_reason = NULL,
        decision_reason = NULL;
        dispatch_reference_registry.allocated_reference,
        dispatch_reference_registry.canonicalized_reference,
        dispatch_reference_registry.collision_retry_count
        dispatch_reference_registry.policy_version_id,
        dispatch_reference_registry.registry_id,
        dispatch_reference_registry.strategy_used,
        held_at = NOW(),
        held_at = NOW(),
        held_reason = EXCLUDED.held_reason,
        idempotency_key,
        inquiry_state = 'EXHAUSTED',
        instruction_id,
        instruction_id, adjustment_id, rail_id, allocated_reference,
        instruction_id, adjustment_id, rail_id, reference_attempted,
        max_attempts = p_max_attempts
        next_attempt_at = NOW() + make_interval(secs => GREATEST(1, COALESCE(p_retry_delay_seconds, 1))),
        observed_rate = EXCLUDED.observed_rate,
        p_idempotency_key,
        p_instruction_id,
        p_instruction_id, p_adjustment_id, p_rail_id, p_parent_reference,
        p_instruction_id, p_adjustment_id, p_rail_id, v_candidate,
        p_participant_id,
        p_payload
        p_rail_type,
        participant_id,
        payload
        policy_version_id = EXCLUDED.policy_version_id,
        policy_version_id = EXCLUDED.policy_version_id,
        policy_version_id = p_policy_version_id,
        rail_a_id = EXCLUDED.rail_a_id,
        rail_a_response = EXCLUDED.rail_a_response,
        rail_b_id = EXCLUDED.rail_b_id,
        rail_b_response = EXCLUDED.rail_b_response,
        rail_type,
        rolling_window_seconds = EXCLUDED.rolling_window_seconds,
        sealed_at = now();
        sequence_id,
        status = 'PENDING_SUPERVISOR_APPROVAL',
        status = 'PENDING_SUPERVISOR_APPROVAL',
        strategy_used, collision_count, outcome, policy_version_id
        submitted_by = EXCLUDED.submitted_by,
        suspended_at = CASE WHEN EXCLUDED.state='SUSPENDED' THEN now() ELSE public.adapter_circuit_breakers.suspended_at END;
        timeout_at = EXCLUDED.timeout_at,
        timeout_at = NOW() + make_interval(mins => v_timeout),
        trigger_threshold = EXCLUDED.trigger_threshold,
        v_canon, v_strategy.strategy_type, v_strategy.policy_version_id, v_attempt
        v_strategy.strategy_type, v_attempt, 'EXHAUSTED', v_strategy.policy_version_id
      'SUFFIX', 1, 'UNREGISTERED_BLOCKED', NULL
      'migrated_at', NOW(),
      'migrated_from_program_id', p_from_program_id,
      'migrated_to_program_id', p_to_program_id,
      'migration_reason', v_reason
      (e.state = 'CREATED' AND e.authorization_expires_at IS NOT NULL AND e.authorization_expires_at <= p_now)
      )
      )
      )
      )
      ) VALUES (
      ) VALUES (
      );
      AND (o.lease_expires_at IS NULL OR o.lease_expires_at <= clock_timestamp())
      AND (p_adjustment_id IS NULL OR r.adjustment_id = p_adjustment_id)
      AND (r.allocated_reference = p_reference OR r.canonicalized_reference = p_reference)
      AND a.idempotency_key = p_idempotency_key
      AND e.from_program_id = p_from_program_id
      AND e.person_id = p_person_id
      AND e.to_program_id = p_to_program_id
      AND ia.participant_id = p_participant_id
      AND ia.tenant_id = p_tenant_id
      AND m.entity_id = p_entity_id
      AND m.tenant_id = p_tenant_id
      AND md.device_id_hash = p_device_id
      AND md.member_id = p_member_id
      AND md.status = 'ACTIVE'
      AND p.idempotency_key = p_idempotency_key
      AND p.lease_token = p_lease_token AND p.lease_expires_at > NOW()
      AND p.tenant_id = p_tenant_id
      AND p.tenant_id = p_tenant_id
      AND p.tenant_id = p_tenant_id
      AND p.tenant_id = p_tenant_id
      AND pe.tenant_id = p_tenant_id
      AND pr.tenant_id = p_tenant_id
      AND r.instruction_id = p_instruction_id
      CASE WHEN v_effective_state IN ('DISPATCHED', 'FAILED') THEN NOW() ELSE NULL END,
      COALESCE(v_source_member.metadata, '{}'::jsonb) || jsonb_build_object(
      DELETE FROM payment_outbox_pending WHERE outbox_id = p_outbox_id;
      ELSE
      END IF;
      END IF;
      ERRCODE = 'P7803',
      FROM payment_outbox_attempts a WHERE a.outbox_id = v_record.outbox_id;
      FROM payment_outbox_pending p
      FROM public.supervisor_approval_queue
      IF v_attempt > 0 THEN
      IF v_next_attempt_no >= v_retry_ceiling THEN
      INSERT INTO payment_outbox_pending (
      INSERT INTO public.dispatch_reference_collision_events(
      INSERT INTO public.dispatch_reference_registry(
      INTO existing_pending;
      INTO registry_id, allocated_reference, canonicalized_reference, strategy_used, policy_version_id, collision_retry_count;
      MESSAGE = 'ACTIVE_REFERENCE_POLICY_IMMUTABLE';
      NOW(),
      NOW(),
      OR (e.state = 'AUTHORIZED' AND e.authorization_expires_at IS NOT NULL AND e.authorization_expires_at <= p_now)
      OR (e.state = 'RELEASE_REQUESTED' AND e.release_due_at IS NOT NULL AND e.release_due_at <= p_now)
      ORDER BY p.lease_expires_at ASC, p.created_at ASC LIMIT p_batch_size FOR UPDATE SKIP LOCKED
      RAISE EXCEPTION 'Invalid completion state %', p_state USING ERRCODE = 'P7003';
      RAISE EXCEPTION 'LEASE_LOST' USING ERRCODE = 'P7002',
      RAISE EXCEPTION 'self approval is not permitted for instruction %', p_instruction_id
      RAISE EXCEPTION USING ERRCODE='P7801', MESSAGE='REFERENCE_ALLOCATION_RETRY_EXHAUSTED';
      RETURN NEW;
      RETURN NEXT;
      RETURN NEXT;
      RETURN QUERY SELECT existing_attempt.outbox_id, existing_attempt.sequence_id, existing_attempt.created_at, existing_attempt.state::TEXT;
      RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
      RETURN;
      RETURN;
      RETURN;
      RETURNING
      RETURNING payment_outbox_pending.outbox_id, payment_outbox_pending.sequence_id, payment_outbox_pending.created_at
      SELECT 1
      SELECT 1 FROM public.dispatch_reference_registry r
      SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
      SELECT p.outbox_id, p.instruction_id, p.participant_id, p.sequence_id,
      SET next_sequence_id = participant_outbox_sequences.next_sequence_id + 1
      UPDATE payment_outbox_pending SET
      USING ERRCODE = '23503';
      USING ERRCODE = '23505';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P0001';
      USING ERRCODE = 'P7003';
      USING ERRCODE = 'P7003';
      USING ERRCODE = 'P7003';
      USING ERRCODE = 'P7003';
      USING ERRCODE = 'P7004';
      USING ERRCODE = 'P7004';
      USING ERRCODE = 'P7005';
      USING ERRCODE = 'P7201';
      USING ERRCODE = 'P7202';
      USING ERRCODE = 'P7299';
      USING ERRCODE = 'P7300';
      USING ERRCODE = 'P7300';
      USING ERRCODE = 'P7300';
      USING ERRCODE = 'P7301';
      USING ERRCODE = 'P7301';
      USING ERRCODE = 'P7301';
      USING ERRCODE = 'P7301';
      USING ERRCODE = 'P7302';
      USING ERRCODE = 'P7302';
      USING ERRCODE = 'P7302';
      USING ERRCODE = 'P7303';
      USING ERRCODE = 'P7303';
      USING ERRCODE = 'P7303';
      USING ERRCODE = 'P7303';
      USING ERRCODE = 'P7304';
      USING ERRCODE = 'P7304';
      USING ERRCODE = 'P7304';
      USING ERRCODE = 'P7304';
      USING ERRCODE = 'P7305';
      USING ERRCODE = 'P7306';
      USING ERRCODE = 'P7306';
      USING ERRCODE = 'P7307';
      USING ERRCODE = 'P7307';
      USING ERRCODE = 'P7400';
      USING ERRCODE = 'P7401';
      VALUES (
      WHEN unique_violation THEN
      WHERE instruction_id = p_instruction_id
      WHERE outbox_id = p_outbox_id;
      WHERE p.claimed_by IS NOT NULL AND p.lease_token IS NOT NULL AND p.lease_expires_at <= NOW()
      WHERE r.rail_id = p_rail_id
      anchor_ref = p_anchor_ref,
      anchor_type = COALESCE(NULLIF(BTRIM(p_anchor_type), ''), 'HYBRID_SYNC')
      approved_at = CASE WHEN v_decision = 'APPROVED' THEN NOW() ELSE approved_at END,
      approved_by = CASE WHEN v_decision = 'APPROVED' THEN v_actor ELSE approved_by END,
      attempt_count = o.attempt_count + 1,
      attempt_no := v_next_attempt_no;
      attempt_no, state, claimed_at, completed_at, rail_reference, rail_code,
      canceled_at = CASE WHEN v_to_state = 'CANCELED' THEN COALESCE(canceled_at, p_now) ELSE canceled_at END,
      ceiling_amount_minor,
      ceiling_currency,
      claimed_by = NULL,
      claimed_by = v_worker,
      decided_at = NOW(),
      decided_at = p_now,
      decided_by = 'system_timeout',
      decided_by = v_actor,
      decision_reason = COALESCE(decision_reason, 'timeout')
      decision_reason = p_reason
      enrolled_at,
      entity_id,
      error_code, error_message, latency_ms, worker_id
      expired_at = CASE WHEN v_to_state = 'EXPIRED' THEN COALESCE(expired_at, p_now) ELSE expired_at END
      formula_version_id
      from_program_id,
      hashtextextended(p_instruction_id || chr(31) || p_idempotency_key, 1)
      inquiry_state = 'SENT',
      instruction_id, adjustment_id, rail_id, reference_attempted,
      kyc_status,
      last_error = COALESCE(last_error, 'LEASE_EXPIRED_REPAIRED')
      last_error = NULL
      lease_expires_at = NULL
      lease_expires_at = NULL,
      lease_expires_at = clock_timestamp() + make_interval(secs => p_lease_seconds),
      lease_token = NULL,
      lease_token = NULL,
      lease_token = public.uuid_v7_or_random(),
      max_attempts = p_max_attempts
      md5(v_source_member.member_ref_hash || ':migrated:' || p_to_program_id::text),
      member_id,
      member_ref_hash,
      metadata
      migrated_at,
      migrated_by,
      migrated_member_id,
      outbox_id := v_record.outbox_id;
      outbox_id, instruction_id, participant_id, sequence_id, idempotency_key, rail_type, payload,
      p_actor_id => p_actor_id,
      p_escrow_id => v_escrow_id,
      p_from_program_id,
      p_instruction_id, p_adjustment_id, p_rail_id, p_reference,
      p_metadata => jsonb_build_object('expired_at', p_now),
      p_now => p_now
      p_outbox_id, v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload,
      p_person_id,
      p_rail_reference, p_rail_code, p_error_code, p_error_message, p_latency_ms, p_worker_id
      p_reason => 'window_elapsed',
      p_tenant_id,
      p_tenant_id, p_person_id, p_from_program_id, p_to_program_id
      p_to_program_id,
      p_to_program_id,
      p_to_state => 'EXPIRED',
      person_id,
      person_id,
      policy_version_id = p_policy_version_id
      policy_version_id = p_policy_version_id,
      public.uuid_v7_or_random(),
      reason,
      released_at = CASE WHEN v_to_state = 'RELEASED' THEN COALESCE(released_at, p_now) ELSE released_at END,
      status,
      strategy_used, collision_count, outcome, policy_version_id
      tenant_id,
      tenant_id,
      tenant_member_id,
      to_program_id,
      updated_at = NOW()
      updated_at = p_now,
      v_actor,
      v_candidate := p_parent_reference || '-' || lpad(v_attempt::text, 2, '0');
      v_candidate := p_parent_reference;
      v_candidate := substr(md5('reh:' || p_parent_reference || ':' || p_rail_id || ':' || v_attempt::text), 1, greatest(8, v_strategy.max_length));
      v_candidate := substr(md5(p_parent_reference || ':' || coalesce(p_adjustment_id::text,'none') || ':' || v_attempt::text), 1, greatest(8, v_strategy.max_length));
      v_effective_state := 'FAILED';
      v_formula_version_id
      v_next_attempt_no, v_effective_state, NOW(),
      v_reason,
      v_source_member.ceiling_amount_minor,
      v_source_member.ceiling_currency,
      v_source_member.kyc_status,
      v_source_member.person_id,
      v_source_member.status,
      v_source_member.tenant_id,
      v_source_member.tenant_member_id,
      v_target_member_id,
     AND p_rail_a_status <> p_rail_b_status THEN
     AND p_rail_b_status IN ('SUCCESS','FAILED')
     AND purged_at IS NULL;
     JOIN public.members m ON ((m.member_id = e.member_id)));
     SET protected_payload = NULL,
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
    'AAK',
    'ACKNOWLEDGED',
    'ACTIVE',
    'ACTIVE',
    'DETERMINISTIC_ALIAS',
    'DISPATCHED',
    'DISPATCHING',
    'DUPLICATE_DISPATCH',
    'EASK',
    'EXHAUSTED'
    'FAILED',
    'FAILED',
    'FINALITY_CONFLICT',
    'GRACE',
    'LATE_CALLBACK',
    'LATE_CALLBACK',
    'ORPHAN_ROUTING',
    'PCSK',
    'PENDING'
    'PENDING_SUPERVISOR_APPROVAL',
    'PROTOCOL',
    'PURGED',
    'RAIL_NATIVE_ALT_FIELD'
    'REPLAY_ATTEMPT'
    'REQUESTED',
    'RESOLVED_MANUAL'
    'RETIRED'
    'RETRYABLE',
    'RE_ENCODED_HASH_TOKEN',
    'SCHEDULED',
    'SEMANTIC'
    'SENT',
    'SIM_SWAP_DETECTED',
    'SUCCESS',
    'SUFFIX',
    'SYNTAX',
    'TRANSPORT',
    'TRANSPORT_IDENTITY'
    'UNKNOWN_REFERENCE',
    'ZOMBIE_REQUEUE'
    'active'
    'approved',
    'blocked_legal_hold'
    'cooling_off',
    'denied',
    'draft',
    'eligible_execute',
    'executed',
    'pending_approval',
    'requested',
    'v1', 'signing-service-v1', 'trust-chain-main',
    (EXTRACT(year FROM enrolled_at))::integer AS program_year,
    (s->>'max_length')::integer,
    (s->>'nonce_retry_limit')::integer,
    (s->>'strategy_type')::public.reference_strategy_type_enum,
    (v_row.state = 'CREATED' AND v_to_state IN ('AUTHORIZED', 'CANCELED', 'EXPIRED'))
    )
    )
    )
    ) INTO v_collision;
    ) THEN
    ) VALUES (
    ) VALUES (
    ) VALUES (
    ) VALUES (
    );
    );
    );
    );
    0,
    20
    ADD CONSTRAINT adapter_circuit_breakers_pkey PRIMARY KEY (adapter_id, rail_id);
    ADD CONSTRAINT adjustment_approval_stages_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id);
    ADD CONSTRAINT adjustment_approval_stages_pkey PRIMARY KEY (stage_id);
    ADD CONSTRAINT adjustment_approvals_pkey PRIMARY KEY (approval_id);
    ADD CONSTRAINT adjustment_approvals_stage_id_approver_id_key UNIQUE (stage_id, approver_id);
    ADD CONSTRAINT adjustment_approvals_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.adjustment_approval_stages(stage_id);
    ADD CONSTRAINT adjustment_execution_attempts_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id);
    ADD CONSTRAINT adjustment_execution_attempts_adjustment_id_idempotency_key_key UNIQUE (adjustment_id, idempotency_key);
    ADD CONSTRAINT adjustment_execution_attempts_pkey PRIMARY KEY (attempt_id);
    ADD CONSTRAINT adjustment_freeze_flags_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id);
    ADD CONSTRAINT adjustment_freeze_flags_pkey PRIMARY KEY (flag_id);
    ADD CONSTRAINT adjustment_instructions_pkey PRIMARY KEY (adjustment_id);
    ADD CONSTRAINT adjustment_parent_fk FOREIGN KEY (parent_instruction_id) REFERENCES public.inquiry_state_machine(instruction_id);
    ADD CONSTRAINT anchor_sync_operations_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.evidence_packs(pack_id);
    ADD CONSTRAINT anchor_sync_operations_pack_id_key UNIQUE (pack_id);
    ADD CONSTRAINT anchor_sync_operations_pkey PRIMARY KEY (operation_id);
    ADD CONSTRAINT billable_clients_client_key_required_new_rows_chk CHECK (((client_key IS NOT NULL) AND (length(btrim(client_key)) > 0))) NOT VALID;
    ADD CONSTRAINT billable_clients_pkey PRIMARY KEY (billable_client_id);
    ADD CONSTRAINT billing_usage_events_billable_client_id_fkey FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id);
    ADD CONSTRAINT billing_usage_events_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.tenant_clients(client_id);
    ADD CONSTRAINT billing_usage_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT billing_usage_events_subject_client_id_fkey FOREIGN KEY (subject_client_id) REFERENCES public.tenant_clients(client_id);
    ADD CONSTRAINT billing_usage_events_subject_member_id_fkey FOREIGN KEY (subject_member_id) REFERENCES public.tenant_members(member_id);
    ADD CONSTRAINT billing_usage_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT dispatch_reference_collision_events_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id) ON DELETE RESTRICT;
    ADD CONSTRAINT dispatch_reference_collision_events_pkey PRIMARY KEY (collision_event_id);
    ADD CONSTRAINT dispatch_reference_registry_adjustment_id_fkey FOREIGN KEY (adjustment_id) REFERENCES public.adjustment_instructions(adjustment_id) ON DELETE RESTRICT;
    ADD CONSTRAINT dispatch_reference_registry_canon_unique UNIQUE (rail_id, canonicalized_reference);
    ADD CONSTRAINT dispatch_reference_registry_pkey PRIMARY KEY (registry_id);
    ADD CONSTRAINT dispatch_reference_registry_policy_version_id_fkey FOREIGN KEY (policy_version_id) REFERENCES public.reference_strategy_policy_versions(policy_version_id) ON DELETE RESTRICT;
    ADD CONSTRAINT dispatch_reference_registry_ref_unique UNIQUE (rail_id, allocated_reference);
    ADD CONSTRAINT effect_seal_mismatch_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT escrow_accounts_pkey PRIMARY KEY (escrow_id);
    ADD CONSTRAINT escrow_accounts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_envelopes_escrow_id_fkey FOREIGN KEY (escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_envelopes_pkey PRIMARY KEY (escrow_id);
    ADD CONSTRAINT escrow_envelopes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_events_escrow_id_fkey FOREIGN KEY (escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT escrow_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_reservations_pkey PRIMARY KEY (reservation_id);
    ADD CONSTRAINT escrow_reservations_program_escrow_id_fkey FOREIGN KEY (program_escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_reservations_program_escrow_id_reservation_escrow_id_key UNIQUE (program_escrow_id, reservation_escrow_id);
    ADD CONSTRAINT escrow_reservations_reservation_escrow_id_fkey FOREIGN KEY (reservation_escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_reservations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
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
    ADD CONSTRAINT historical_verification_runs_pkey PRIMARY KEY (verification_run_id);
    ADD CONSTRAINT incident_events_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.regulatory_incidents(incident_id) ON DELETE CASCADE;
    ADD CONSTRAINT incident_events_pkey PRIMARY KEY (incident_event_id);
    ADD CONSTRAINT ingress_attestations_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.tenant_clients(client_id);
    ADD CONSTRAINT ingress_attestations_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT ingress_attestations_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.tenant_members(member_id);
    ADD CONSTRAINT ingress_attestations_pkey PRIMARY KEY (attestation_id);
    ADD CONSTRAINT inquiry_state_machine_pkey PRIMARY KEY (instruction_id);
    ADD CONSTRAINT instruction_effect_seals_pkey PRIMARY KEY (instruction_id);
    ADD CONSTRAINT instruction_finality_conflicts_pkey PRIMARY KEY (instruction_id);
    ADD CONSTRAINT instruction_settlement_finality_pkey PRIMARY KEY (finality_id);
    ADD CONSTRAINT instruction_settlement_finality_reversal_fk FOREIGN KEY (reversal_of_instruction_id) REFERENCES public.instruction_settlement_finality(instruction_id) DEFERRABLE;
    ADD CONSTRAINT key_rotation_drills_pkey PRIMARY KEY (drill_id);
    ADD CONSTRAINT kyc_provider_registry_pkey PRIMARY KEY (id);
    ADD CONSTRAINT kyc_provider_unique_code UNIQUE (provider_code);
    ADD CONSTRAINT kyc_retention_policy_pkey PRIMARY KEY (id);
    ADD CONSTRAINT kyc_retention_unique_active_class UNIQUE (jurisdiction_code, retention_class);
    ADD CONSTRAINT kyc_verification_records_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.tenant_members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT kyc_verification_records_pkey PRIMARY KEY (id);
    ADD CONSTRAINT kyc_verification_records_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES public.kyc_provider_registry(id) ON DELETE RESTRICT;
    ADD CONSTRAINT levy_calculation_one_per_instruction UNIQUE (instruction_id);
    ADD CONSTRAINT levy_calculation_records_instruction_id_fkey FOREIGN KEY (instruction_id) REFERENCES public.ingress_attestations(attestation_id) ON DELETE RESTRICT;
    ADD CONSTRAINT levy_calculation_records_levy_rate_id_fkey FOREIGN KEY (levy_rate_id) REFERENCES public.levy_rates(id) ON DELETE RESTRICT;
    ADD CONSTRAINT levy_calculation_records_pkey PRIMARY KEY (id);
    ADD CONSTRAINT levy_periods_unique_period_jurisdiction UNIQUE (period_code, jurisdiction_code);
    ADD CONSTRAINT levy_rates_pkey PRIMARY KEY (id);
    ADD CONSTRAINT levy_remittance_periods_pkey PRIMARY KEY (id);
    ADD CONSTRAINT malformed_quarantine_store_pkey PRIMARY KEY (quarantine_id);
    ADD CONSTRAINT member_device_events_ingress_fk FOREIGN KEY (tenant_id, instruction_id) REFERENCES public.ingress_attestations(tenant_id, instruction_id) ON DELETE RESTRICT;
    ADD CONSTRAINT member_device_events_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT member_device_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT member_devices_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT member_devices_pkey PRIMARY KEY (member_id, device_id_hash);
    ADD CONSTRAINT member_devices_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT members_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT members_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(person_id) ON DELETE RESTRICT;
    ADD CONSTRAINT members_pkey PRIMARY KEY (member_id);
    ADD CONSTRAINT members_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT members_tenant_id_member_ref_hash_key UNIQUE (tenant_id, member_ref_hash);
    ADD CONSTRAINT members_tenant_id_person_id_entity_id_key UNIQUE (tenant_id, person_id, entity_id);
    ADD CONSTRAINT members_tenant_member_id_fkey FOREIGN KEY (tenant_member_id) REFERENCES public.tenant_members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT mmo_reality_control_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT offline_safe_mode_windows_pkey PRIMARY KEY (window_id);
    ADD CONSTRAINT orphaned_attestation_landing_zone_pkey PRIMARY KEY (orphan_id);
    ADD CONSTRAINT participant_outbox_sequences_pkey PRIMARY KEY (participant_id);
    ADD CONSTRAINT participants_pkey PRIMARY KEY (participant_id);
    ADD CONSTRAINT payment_outbox_attempts_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT payment_outbox_attempts_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.tenant_members(member_id);
    ADD CONSTRAINT payment_outbox_attempts_pkey PRIMARY KEY (attempt_id);
    ADD CONSTRAINT payment_outbox_attempts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT payment_outbox_pending_correlation_required_new_rows_chk CHECK ((correlation_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT payment_outbox_pending_pkey PRIMARY KEY (outbox_id);
    ADD CONSTRAINT payment_outbox_pending_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT persons_pkey PRIMARY KEY (person_id);
    ADD CONSTRAINT persons_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT pii_purge_events_pkey PRIMARY KEY (purge_event_id);
    ADD CONSTRAINT pii_purge_events_purge_request_id_fkey FOREIGN KEY (purge_request_id) REFERENCES public.pii_purge_requests(purge_request_id);
    ADD CONSTRAINT pii_purge_requests_pkey PRIMARY KEY (purge_request_id);
    ADD CONSTRAINT pii_vault_records_pkey PRIMARY KEY (vault_id);
    ADD CONSTRAINT pii_vault_records_purge_request_fk FOREIGN KEY (purge_request_id) REFERENCES public.pii_purge_requests(purge_request_id) DEFERRABLE;
    ADD CONSTRAINT policy_bundles_pkey PRIMARY KEY (policy_bundle_id);
    ADD CONSTRAINT policy_bundles_policy_id_policy_version_key UNIQUE (policy_id, policy_version);
    ADD CONSTRAINT policy_versions_pkey PRIMARY KEY (version);
    ADD CONSTRAINT program_migration_events_formula_version_id_fkey FOREIGN KEY (formula_version_id) REFERENCES public.risk_formula_versions(formula_version_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_from_program_id_fkey FOREIGN KEY (from_program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_migrated_member_id_fkey FOREIGN KEY (migrated_member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_new_member_id_fkey FOREIGN KEY (new_member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(person_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_pkey PRIMARY KEY (migration_event_id);
    ADD CONSTRAINT program_migration_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_to_program_id_fkey FOREIGN KEY (to_program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT programs_pkey PRIMARY KEY (program_id);
    ADD CONSTRAINT programs_program_escrow_id_fkey FOREIGN KEY (program_escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;
    ADD CONSTRAINT programs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT programs_tenant_id_program_escrow_id_key UNIQUE (tenant_id, program_escrow_id);
    ADD CONSTRAINT programs_tenant_id_program_key_key UNIQUE (tenant_id, program_key);
    ADD CONSTRAINT rail_dispatch_truth_anchor_pkey PRIMARY KEY (anchor_id);
    ADD CONSTRAINT rail_truth_anchor_attempt_fk FOREIGN KEY (attempt_id) REFERENCES public.payment_outbox_attempts(attempt_id) DEFERRABLE;
    ADD CONSTRAINT reference_strategy_policy_versions_pkey PRIMARY KEY (policy_version_id);
    ADD CONSTRAINT regulatory_incidents_pkey PRIMARY KEY (incident_id);
    ADD CONSTRAINT regulatory_incidents_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT resign_sweeps_pkey PRIMARY KEY (sweep_id);
    ADD CONSTRAINT revoked_client_certs_pkey PRIMARY KEY (cert_fingerprint_sha256);
    ADD CONSTRAINT revoked_tokens_pkey PRIMARY KEY (token_jti);
    ADD CONSTRAINT risk_formula_versions_formula_key_key UNIQUE (formula_key);
    ADD CONSTRAINT risk_formula_versions_pkey PRIMARY KEY (formula_version_id);
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);
    ADD CONSTRAINT signing_audit_log_pkey PRIMARY KEY (sign_event_id);
    ADD CONSTRAINT signing_authorization_matrix_caller_id_key_class_key UNIQUE (caller_id, key_class);
    ADD CONSTRAINT signing_authorization_matrix_pkey PRIMARY KEY (matrix_id);
    ADD CONSTRAINT sim_swap_alerts_formula_version_id_fkey FOREIGN KEY (formula_version_id) REFERENCES public.risk_formula_versions(formula_version_id) ON DELETE RESTRICT;
    ADD CONSTRAINT sim_swap_alerts_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT sim_swap_alerts_pkey PRIMARY KEY (alert_id);
    ADD CONSTRAINT sim_swap_alerts_source_event_id_fkey FOREIGN KEY (source_event_id) REFERENCES public.member_device_events(event_id) ON DELETE RESTRICT;
    ADD CONSTRAINT sim_swap_alerts_source_event_id_key UNIQUE (source_event_id);
    ADD CONSTRAINT sim_swap_alerts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT supervisor_access_policies_pkey PRIMARY KEY (scope);
    ADD CONSTRAINT supervisor_approval_queue_pkey PRIMARY KEY (instruction_id);
    ADD CONSTRAINT supervisor_approval_queue_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT supervisor_audit_tokens_pkey PRIMARY KEY (token_id);
    ADD CONSTRAINT supervisor_audit_tokens_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT supervisor_audit_tokens_token_hash_key UNIQUE (token_hash);
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
    ADD CONSTRAINT ux_instruction_settlement_finality_instruction UNIQUE (instruction_id);
    ADD CONSTRAINT ux_pending_idempotency UNIQUE (instruction_id, idempotency_key);
    ADD CONSTRAINT ux_pending_participant_sequence UNIQUE (participant_id, sequence_id);
    ADD CONSTRAINT ux_pii_purge_events_request_event UNIQUE (purge_request_id, event_type);
    ADD CONSTRAINT ux_pii_vault_records_subject_token UNIQUE (subject_token);
    ADD CONSTRAINT ux_rail_truth_anchor_attempt_id UNIQUE (attempt_id);
    ADD CONSTRAINT ux_rail_truth_anchor_sequence_scope UNIQUE (rail_sequence_ref, rail_participant_id, rail_profile);
    AND (p.lease_expires_at IS NULL OR p.lease_expires_at <= NOW())
    AND COALESCE(submitted_by, '') <> v_actor;
    AND e.event_type = 'PURGED'
    AND key_class = p_key_class
    AND lease_expires_at <= clock_timestamp();
    AND lease_expires_at IS NOT NULL
    AND m.entity_id = p_from_program_id
    AND m.entity_id = p_from_program_id
    AND m.entity_id = p_to_program_id
    AND m.person_id = p_person_id
    AND m.person_id = p_person_id
    AND m.person_id = p_person_id
    AND md.iccid_hash <> v_event.iccid_hash
    AND md.iccid_hash IS NOT NULL
    AND md.member_id = v_event.member_id
    AND md.status = 'ACTIVE'
    AND rf.is_active = TRUE
    AND rf.is_active = TRUE
    AND rf.is_active = TRUE
    AND signature_valid = true;
    AND state = 'approved'
    AND status = 'PENDING_SUPERVISOR_APPROVAL'
    AND timeout_at <= p_now;
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
    AS $$
    BEGIN
    CASE WHEN v_state='FINALITY_CONFLICT' THEN 'HOLD_RELEASE' ELSE NULL END
    CASE WHEN v_state='FINALITY_CONFLICT' THEN now() ELSE NULL END,
    CASE WHEN v_state='SUSPENDED' THEN now() ELSE NULL END
    COALESCE(p_metadata, '{}'::jsonb),
    COALESCE(v_event.observed_at, NOW())
    COALESCE(v_source_member.metadata, '{}'::jsonb) || jsonb_build_object(
    CONSTRAINT anchor_sync_operations_attempt_count_check CHECK ((attempt_count >= 0)),
    CONSTRAINT anchor_sync_operations_state_check CHECK ((state = ANY (ARRAY['PENDING'::text, 'ANCHORING'::text, 'ANCHORED'::text, 'COMPLETED'::text, 'FAILED'::text]))),
    CONSTRAINT billable_clients_client_type_check CHECK ((client_type = ANY (ARRAY['BANK'::text, 'MMO'::text, 'NGO'::text, 'GOV_PROGRAM'::text, 'COOP_FEDERATION'::text, 'ENTERPRISE'::text]))),
    CONSTRAINT billable_clients_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT billing_usage_events_event_type_check CHECK ((event_type = ANY (ARRAY['EVIDENCE_BUNDLE'::text, 'CASE_PACK'::text, 'EXCEPTION_TRIAGE'::text, 'RETENTION_ANCHOR'::text, 'ESCROW_RELEASE'::text, 'DISPUTE_PACK'::text]))),
    CONSTRAINT billing_usage_events_member_requires_tenant_chk CHECK (((subject_member_id IS NULL) OR (tenant_id IS NOT NULL))),
    CONSTRAINT billing_usage_events_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT billing_usage_events_subject_zero_or_one_chk CHECK (((((subject_member_id IS NOT NULL))::integer + ((subject_client_id IS NOT NULL))::integer) <= 1)),
    CONSTRAINT billing_usage_events_units_check CHECK ((units = ANY (ARRAY['count'::text, 'bytes'::text, 'seconds'::text, 'events'::text])))
    CONSTRAINT ck_anchor_sync_completed_requires_anchor_ref CHECK (((state <> 'COMPLETED'::text) OR (anchor_ref IS NOT NULL)))
    CONSTRAINT ck_attempts_payload_is_object CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT ck_pending_payload_is_object CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT ck_policy_active_has_no_grace_expiry CHECK (((status <> 'ACTIVE'::public.policy_version_status) OR (grace_expires_at IS NULL))),
    CONSTRAINT ck_policy_checksum_nonempty CHECK ((length(checksum) > 0)),
    CONSTRAINT ck_policy_grace_requires_expiry CHECK (((status <> 'GRACE'::public.policy_version_status) OR (grace_expires_at IS NOT NULL)))
    CONSTRAINT dispatch_reference_collision_events_collision_count_check CHECK ((collision_count >= 1)),
    CONSTRAINT dispatch_reference_collision_events_outcome_check CHECK ((outcome = ANY (ARRAY['RESOLVED'::text, 'EXHAUSTED'::text, 'TRUNCATION_COLLISION_BLOCKED'::text, 'UNREGISTERED_BLOCKED'::text, 'REJECTED'::text])))
    CONSTRAINT dispatch_reference_registry_collision_retry_count_check CHECK ((collision_retry_count >= 0))
    CONSTRAINT escrow_accounts_authorized_amount_minor_check CHECK ((authorized_amount_minor >= 0)),
    CONSTRAINT escrow_accounts_state_check CHECK ((state = ANY (ARRAY['CREATED'::text, 'AUTHORIZED'::text, 'RELEASE_REQUESTED'::text, 'RELEASED'::text, 'CANCELED'::text, 'EXPIRED'::text])))
    CONSTRAINT escrow_envelopes_ceiling_amount_minor_check CHECK ((ceiling_amount_minor >= 0)),
    CONSTRAINT escrow_envelopes_reserved_amount_minor_check CHECK ((reserved_amount_minor >= 0))
    CONSTRAINT escrow_events_event_type_check CHECK ((event_type = ANY (ARRAY['CREATED'::text, 'AUTHORIZED'::text, 'RELEASE_REQUESTED'::text, 'RELEASED'::text, 'CANCELED'::text, 'EXPIRED'::text])))
    CONSTRAINT escrow_reservations_amount_minor_check CHECK ((amount_minor > 0))
    CONSTRAINT evidence_pack_items_path_or_hash_chk CHECK (((artifact_path IS NOT NULL) OR (artifact_hash IS NOT NULL)))
    CONSTRAINT evidence_packs_pack_type_check CHECK ((pack_type = ANY (ARRAY['INSTRUCTION_BUNDLE'::text, 'INCIDENT_PACK'::text, 'DISPUTE_PACK'::text])))
    CONSTRAINT inquiry_state_machine_max_attempts_check CHECK ((max_attempts > 0))
    CONSTRAINT instruction_settlement_finality_final_state_check CHECK ((final_state = ANY (ARRAY['SETTLED'::text, 'REVERSED'::text]))),
    CONSTRAINT instruction_settlement_finality_is_final_true_chk CHECK ((is_final = true)),
    CONSTRAINT instruction_settlement_finality_rail_message_type_check CHECK ((rail_message_type = ANY (ARRAY['pacs.008'::text, 'camt.056'::text]))),
    CONSTRAINT instruction_settlement_finality_self_reversal_chk CHECK (((reversal_of_instruction_id IS NULL) OR (reversal_of_instruction_id <> instruction_id))),
    CONSTRAINT instruction_settlement_finality_shape_chk CHECK ((((final_state = 'SETTLED'::text) AND (reversal_of_instruction_id IS NULL) AND (rail_message_type = 'pacs.008'::text)) OR ((final_state = 'REVERSED'::text) AND (reversal_of_instruction_id IS NOT NULL) AND (rail_message_type = 'camt.056'::text))))
    CONSTRAINT key_rotation_drills_drill_outcome_check CHECK ((drill_outcome = ANY (ARRAY['PASS'::text, 'FAIL'::text]))),
    CONSTRAINT key_rotation_drills_rotation_type_check CHECK ((rotation_type = ANY (ARRAY['SCHEDULED'::text, 'EMERGENCY'::text])))
    CONSTRAINT kyc_provider_registry_check CHECK (((active_to IS NULL) OR (active_from IS NULL) OR (active_to >= active_from)))
    CONSTRAINT kyc_retention_policy_retention_years_check CHECK ((retention_years > 0))
    CONSTRAINT kyc_verification_records_retention_class_check CHECK ((retention_class = 'FIC_AML_CUSTOMER_ID'::text))
    CONSTRAINT levy_calculation_records_cap_applied_minor_check CHECK (((cap_applied_minor IS NULL) OR (cap_applied_minor >= 0))),
    CONSTRAINT levy_calculation_records_levy_amount_final_check CHECK (((levy_amount_final IS NULL) OR (levy_amount_final >= 0))),
    CONSTRAINT levy_calculation_records_levy_amount_pre_cap_check CHECK (((levy_amount_pre_cap IS NULL) OR (levy_amount_pre_cap >= 0))),
    CONSTRAINT levy_calculation_records_reporting_period_check CHECK (((reporting_period IS NULL) OR (reporting_period ~ '^[0-9]{4}-[0-9]{2}$'::text))),
    CONSTRAINT levy_calculation_records_taxable_amount_minor_check CHECK (((taxable_amount_minor IS NULL) OR (taxable_amount_minor >= 0)))
    CONSTRAINT levy_rates_cap_amount_minor_check CHECK (((cap_amount_minor IS NULL) OR (cap_amount_minor > 0))),
    CONSTRAINT levy_rates_cap_currency_required CHECK (((cap_amount_minor IS NULL) OR (cap_currency_code IS NOT NULL))),
    CONSTRAINT levy_rates_check CHECK (((effective_to IS NULL) OR (effective_to >= effective_from))),
    CONSTRAINT levy_rates_rate_bps_check CHECK (((rate_bps >= 0) AND (rate_bps <= 10000)))
    CONSTRAINT levy_remittance_periods_check CHECK ((period_end >= period_start)),
    CONSTRAINT levy_remittance_periods_check1 CHECK (((filing_deadline IS NULL) OR (filing_deadline >= period_end))),
    CONSTRAINT levy_remittance_periods_period_code_check CHECK ((period_code ~ '^[0-9]{4}-[0-9]{2}$'::text))
    CONSTRAINT member_device_events_device_id_event_type_chk CHECK (((device_id IS NULL) = (event_type = ANY (ARRAY['UNREGISTERED_DEVICE'::text, 'REVOKED_DEVICE_ATTEMPT'::text])))),
    CONSTRAINT member_device_events_event_type_check CHECK ((event_type = ANY (ARRAY['ENROLLED_DEVICE'::text, 'UNREGISTERED_DEVICE'::text, 'REVOKED_DEVICE_ATTEMPT'::text, 'SIM_SWAP_DETECTED'::text])))
    CONSTRAINT member_devices_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text, 'REVOKED'::text])))
    CONSTRAINT members_ceiling_amount_minor_check CHECK ((ceiling_amount_minor >= 0)),
    CONSTRAINT members_kyc_status_check CHECK ((kyc_status = ANY (ARRAY['PENDING'::text, 'VERIFIED'::text, 'REJECTED'::text]))),
    CONSTRAINT members_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'ARCHIVED'::text])))
    CONSTRAINT participant_outbox_sequences_next_sequence_id_check CHECK ((next_sequence_id >= 1))
    CONSTRAINT participants_participant_kind_check CHECK ((participant_kind = ANY (ARRAY['BANK'::text, 'MMO'::text, 'NGO'::text, 'GOV_PROGRAM'::text, 'COOP_FEDERATION'::text, 'ENTERPRISE'::text, 'INTERNAL'::text]))),
    CONSTRAINT participants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT payment_outbox_attempts_attempt_no_check CHECK ((attempt_no >= 1)),
    CONSTRAINT payment_outbox_attempts_latency_ms_check CHECK (((latency_ms IS NULL) OR (latency_ms >= 0)))
    CONSTRAINT payment_outbox_pending_attempt_count_check CHECK ((attempt_count >= 0))
    CONSTRAINT persons_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text, 'SUSPENDED'::text])))
    CONSTRAINT pii_purge_events_event_type_check CHECK ((event_type = ANY (ARRAY['REQUESTED'::text, 'PURGED'::text]))),
    CONSTRAINT pii_purge_events_rows_affected_check CHECK ((rows_affected >= 0))
    CONSTRAINT pii_vault_records_purge_shape_chk CHECK ((((purged_at IS NULL) AND (protected_payload IS NOT NULL) AND (purge_request_id IS NULL)) OR ((purged_at IS NOT NULL) AND (protected_payload IS NULL) AND (purge_request_id IS NOT NULL))))
    CONSTRAINT program_migration_events_from_to_chk CHECK ((from_program_id <> to_program_id))
    CONSTRAINT programs_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT rail_truth_anchor_state_chk CHECK ((state = 'DISPATCHED'::public.outbox_attempt_state))
    CONSTRAINT reference_strategy_policy_versions_version_status_check CHECK ((version_status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text])))
    CONSTRAINT regulatory_incidents_severity_check CHECK ((severity = ANY (ARRAY['LOW'::text, 'MEDIUM'::text, 'HIGH'::text, 'CRITICAL'::text]))),
    CONSTRAINT regulatory_incidents_status_check CHECK ((status = ANY (ARRAY['OPEN'::text, 'UNDER_INVESTIGATION'::text, 'REPORTED'::text, 'CLOSED'::text])))
    CONSTRAINT resign_sweeps_artifacts_resigned_count_check CHECK ((artifacts_resigned_count >= 0))
    CONSTRAINT risk_formula_versions_tier_check CHECK ((tier = ANY (ARRAY['TIER1'::text, 'TIER2'::text, 'TIER3'::text])))
    CONSTRAINT signing_audit_log_outcome_check CHECK ((outcome = ANY (ARRAY['PASS'::text, 'REJECTED'::text, 'BLOCKED'::text]))),
    CONSTRAINT signing_audit_log_signing_path_check CHECK ((signing_path = ANY (ARRAY['HSM'::text, 'KMS'::text, 'SOFTWARE_BYPASS'::text])))
    CONSTRAINT signing_authorization_matrix_key_backend_check CHECK ((key_backend = ANY (ARRAY['HSM'::text, 'KMS'::text, 'SOFTWARE'::text])))
    CONSTRAINT sim_swap_alerts_alert_type_check CHECK ((alert_type = 'SIM_SWAP_DETECTED'::text)),
    CONSTRAINT sim_swap_alerts_iccid_diff_chk CHECK ((prior_iccid_hash <> new_iccid_hash))
    CONSTRAINT supervisor_access_policies_hold_timeout_minutes_check CHECK (((hold_timeout_minutes IS NULL) OR (hold_timeout_minutes > 0))),
    CONSTRAINT supervisor_access_policies_read_window_minutes_check CHECK (((read_window_minutes IS NULL) OR (read_window_minutes > 0))),
    CONSTRAINT supervisor_access_policies_scope_check CHECK ((scope = ANY (ARRAY['READ_ONLY'::text, 'AUDIT'::text, 'APPROVAL_REQUIRED'::text])))
    CONSTRAINT supervisor_approval_queue_status_check CHECK ((status = ANY (ARRAY['PENDING_SUPERVISOR_APPROVAL'::text, 'APPROVED'::text, 'REJECTED'::text, 'TIMED_OUT'::text])))
    CONSTRAINT supervisor_audit_tokens_scope_check CHECK ((scope = 'AUDIT'::text))
    CONSTRAINT tenant_clients_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'REVOKED'::text])))
    CONSTRAINT tenant_members_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'EXITED'::text])))
    CONSTRAINT tenants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text]))),
    CONSTRAINT tenants_tenant_type_check CHECK ((tenant_type = ANY (ARRAY['NGO'::text, 'COOPERATIVE'::text, 'GOVERNMENT'::text, 'COMMERCIAL'::text])))
    DO UPDATE
    ELSE
    ELSE
    ELSE 'gen_random_uuid'
    ELSIF v_strategy.strategy_type = 'DETERMINISTIC_ALIAS' THEN
    ELSIF v_strategy.strategy_type = 'RE_ENCODED_HASH_TOKEN' THEN
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END IF;
    END LOOP;
    END;
    EXCEPTION
    FOR UPDATE SKIP LOCKED
    FOR UPDATE;
    FOR v_record IN
    FROM payment_outbox_attempts a
    FROM payment_outbox_attempts a WHERE a.outbox_id = p_outbox_id;
    FROM payment_outbox_pending p
    FROM payment_outbox_pending p
    FROM public.anchor_sync_operations
    FROM public.anchor_sync_operations o
    FROM public.dispatch_reference_registry r
    FROM public.escrow_accounts e
    FROM public.ingress_attestations ia
    FROM public.ingress_attestations ia
    FROM public.member_devices md
    FROM public.members m
    FROM public.persons pe
    FROM public.program_migration_events e
    FROM public.programs p
    FROM public.programs p
    FROM public.programs p
    FROM public.programs p
    FROM public.programs pr
    FROM public.sim_swap_alerts s
    FROM public.tenants t
    IF EXISTS (
    IF FOUND THEN
    IF FOUND THEN
    IF NOT FOUND THEN
    IF NOT v_collision THEN
    IF current_setting('symphony.allow_pii_purge', true) = 'on' THEN
    IF p_state = 'RETRYABLE' AND v_next_attempt_no >= public.outbox_retry_ceiling() THEN
    IF p_state NOT IN ('DISPATCHED', 'FAILED', 'RETRYABLE') THEN
    IF v_attempt > v_strategy.nonce_retry_limit THEN
    IF v_effective_state IN ('DISPATCHED', 'FAILED') THEN
    IF v_strategy.strategy_type = 'SUFFIX' THEN
    INSERT INTO participant_outbox_sequences(participant_id, next_sequence_id)
    INSERT INTO payment_outbox_attempts (
    INSERT INTO public.dispatch_reference_collision_events(
    INSERT INTO public.effect_seal_mismatch_events(instruction_id, stored_seal_hash, computed_dispatch_hash)
    INSERT INTO public.members(
    INSERT INTO public.offline_safe_mode_windows(reason, policy_version_id, gap_marker_id)
    INSERT INTO public.program_migration_events(
    INTO derived_billable_client_id
    INTO derived_tenant_id
    INTO existing_attempt
    INTO existing_pending
    INTO v_alert_id
    INTO v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
    LANGUAGE plpgsql
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
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql SECURITY DEFINER
    LANGUAGE plpgsql STABLE
    LANGUAGE sql
    LANGUAGE sql SECURITY DEFINER
    LANGUAGE sql STABLE
    LANGUAGE sql STABLE
    LIMIT 1
    LIMIT 1;
    LIMIT 1;
    LOOP
    NEW.attempt_id,
    NEW.billable_client_id := derived_billable_client_id;
    NEW.correlation_id := public.uuid_v7_or_random();
    NEW.instruction_id,
    NEW.outbox_id,
    NEW.participant_id,
    NEW.participant_id,
    NEW.state
    NEW.tenant_id := derived_tenant_id;
    NOW()
    NOW() + make_interval(mins => v_timeout),
    NOW(),
    NOW(),
    NOW(),
    NULL
    NULL,
    NULL,
    NULL,
    NULL,
    NULLIF(current_setting('symphony.outbox_retry_ceiling', true), '')::int,
    ON CONFLICT (participant_id)
    ON CONFLICT (tenant_id, person_id, from_program_id, to_program_id) DO NOTHING;
    ON DELETE TO public.kyc_retention_policy DO INSTEAD NOTHING;
    ON UPDATE TO public.kyc_retention_policy DO INSTEAD NOTHING;
    OR (v_row.state = 'AUTHORIZED' AND v_to_state IN ('RELEASE_REQUESTED', 'CANCELED', 'EXPIRED'))
    OR (v_row.state = 'RELEASE_REQUESTED' AND v_to_state IN ('RELEASED', 'CANCELED', 'EXPIRED'))
    ORDER BY a.claimed_at DESC
    ORDER BY o.updated_at, o.created_at
    PERFORM pg_advisory_xact_lock(
    PERFORM pg_notify('symphony_outbox', '');
    PERFORM public.transition_escrow_state(
    RAISE EXCEPTION '% is append-only', TG_TABLE_NAME
    RAISE EXCEPTION 'ADAPTER_SUSPENDED_CIRCUIT_BREAKER' USING ERRCODE = 'P7401';
    RAISE EXCEPTION 'ADJUSTMENT_CEILING_BREACH' USING ERRCODE = 'P7201';
    RAISE EXCEPTION 'ADJUSTMENT_COOLING_OFF_ACTIVE' USING ERRCODE = 'P7701';
    RAISE EXCEPTION 'ADJUSTMENT_FREEZE_BLOCK' USING ERRCODE = 'P7702';
    RAISE EXCEPTION 'ADJUSTMENT_TERMINAL_IMMUTABLE' USING ERRCODE = 'P7101';
    RAISE EXCEPTION 'INQUIRY_EXHAUSTED_AUTO_FINALIZE_BLOCKED' USING ERRCODE = 'P7301';
    RAISE EXCEPTION 'OFFLINE_SAFE_MODE_ACTIVE' USING ERRCODE = 'P7501';
    RAISE EXCEPTION 'active formula key % not found', 'TIER1_DETERMINISTIC_DEFAULT'
    RAISE EXCEPTION 'active formula key % not found', p_formula_key
    RAISE EXCEPTION 'active formula key TIER1_DETERMINISTIC_DEFAULT not found'
    RAISE EXCEPTION 'anchor completion requires anchored state' USING ERRCODE = 'P7211';
    RAISE EXCEPTION 'anchor operation cannot be anchored from state %', v_op.state USING ERRCODE = 'P7211';
    RAISE EXCEPTION 'anchor operation lease invalid' USING ERRCODE = 'P7212';
    RAISE EXCEPTION 'anchor operation lease invalid' USING ERRCODE = 'P7212';
    RAISE EXCEPTION 'anchor operation not found' USING ERRCODE = 'P7210';
    RAISE EXCEPTION 'anchor operation not found' USING ERRCODE = 'P7210';
    RAISE EXCEPTION 'anchor operation worker mismatch' USING ERRCODE = 'P7212';
    RAISE EXCEPTION 'anchor operation worker mismatch' USING ERRCODE = 'P7212';
    RAISE EXCEPTION 'anchor reference is required' USING ERRCODE = 'P7211';
    RAISE EXCEPTION 'approval timeout must be positive';
    RAISE EXCEPTION 'approval timeout must be positive';
    RAISE EXCEPTION 'dispatch requires rail sequence reference'
    RAISE EXCEPTION 'duplicate migration call for tenant %, person %, from %, to %',
    RAISE EXCEPTION 'effect_seal_mismatch' USING ERRCODE = 'P7102';
    RAISE EXCEPTION 'entity-to-member linkage invalid'
    RAISE EXCEPTION 'escrow ceiling exceeded'
    RAISE EXCEPTION 'escrow envelope not found'
    RAISE EXCEPTION 'escrow not found'
    RAISE EXCEPTION 'escrow terminal state transition forbidden: % -> %', v_row.state, v_to_state
    RAISE EXCEPTION 'external_proofs billable_client_id does not match derived billable_client_id'
    RAISE EXCEPTION 'external_proofs requires billable_client_id attribution via tenant'
    RAISE EXCEPTION 'external_proofs requires tenant attribution via ingress_attestations'
    RAISE EXCEPTION 'external_proofs tenant_id does not match derived tenant_id'
    RAISE EXCEPTION 'final instruction cannot be mutated'
    RAISE EXCEPTION 'finality_conflict_hold_release' USING ERRCODE = 'P7402';
    RAISE EXCEPTION 'from_program_id % is not in tenant %', p_from_program_id, p_tenant_id
    RAISE EXCEPTION 'from_program_id % is not in tenant %', p_from_program_id, p_tenant_id
    RAISE EXCEPTION 'from_program_id and to_program_id must differ'
    RAISE EXCEPTION 'from_program_id and to_program_id must differ'
    RAISE EXCEPTION 'illegal escrow transition: % -> %', v_row.state, v_to_state
    RAISE EXCEPTION 'illegal_transition_from_terminal_inquiry_state:%', v_state USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'illegal_transition_to_acknowledged_from:%', v_state USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'ingress_attestations is append-only'
    RAISE EXCEPTION 'inquiry_not_found' USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'instruction % is not pending supervisor approval', p_instruction_id;
    RAISE EXCEPTION 'instruction settlement rows must be final'
    RAISE EXCEPTION 'invalid decision %', p_decision;
    RAISE EXCEPTION 'invalid reservation amount %', v_amount
    RAISE EXCEPTION 'invalid target escrow state %', v_to_state
    RAISE EXCEPTION 'invalid_max_attempts' USING ERRCODE = 'P7302';
    RAISE EXCEPTION 'lease seconds must be > 0' USING ERRCODE = 'P7210';
    RAISE EXCEPTION 'member-to-device linkage invalid'
    RAISE EXCEPTION 'member/tenant mismatch'
    RAISE EXCEPTION 'member_device_event % not found', p_event_id
    RAISE EXCEPTION 'member_id not found'
    RAISE EXCEPTION 'missing_effect_seal' USING ERRCODE = 'P7102';
    RAISE EXCEPTION 'new_entity_id must equal to_program_id'
    RAISE EXCEPTION 'no program available for supervisor approval submission';
    RAISE EXCEPTION 'orphan_replay_containment_reject' USING ERRCODE = 'P7503';
    RAISE EXCEPTION 'pack_id is required' USING ERRCODE = 'P7210';
    RAISE EXCEPTION 'participant-to-program linkage invalid'
    RAISE EXCEPTION 'payment_outbox_attempts is append-only'
    RAISE EXCEPTION 'person_id % is not in tenant %', p_person_id, p_tenant_id
    RAISE EXCEPTION 'pii_vault_records updates require purge executor'
    RAISE EXCEPTION 'program-to-entity linkage invalid'
    RAISE EXCEPTION 'purge request not found: %', p_purge_request_id
    RAISE EXCEPTION 'reversal requires existing instruction %', NEW.reversal_of_instruction_id
    RAISE EXCEPTION 'reversal source instruction must be final and SETTLED: %', NEW.reversal_of_instruction_id
    RAISE EXCEPTION 'revocation tables are append-only'
    RAISE EXCEPTION 'source member not found for tenant %, person %, program %', p_tenant_id, p_person_id, p_from_program_id
    RAISE EXCEPTION 'source member not found for tenant %, person %, program %', p_tenant_id, p_person_id, p_from_program_id
    RAISE EXCEPTION 'tenant-to-participant linkage invalid for instruction'
    RAISE EXCEPTION 'tenant_id required when member_id is set'
    RAISE EXCEPTION 'to_program_id % is not in tenant %', p_to_program_id, p_tenant_id
    RAISE EXCEPTION 'to_program_id % is not in tenant %', p_to_program_id, p_tenant_id
    RAISE EXCEPTION 'unsupported_mmo_scenario' USING ERRCODE = 'P7502';
    RAISE EXCEPTION 'worker_id is required' USING ERRCODE = 'P7210';
    RAISE EXCEPTION USING
    RAISE EXCEPTION USING ERRCODE='P7802', MESSAGE='REFERENCE_STRATEGY_POLICY_NOT_FOUND';
    RAISE EXCEPTION USING ERRCODE='P7802', MESSAGE='REFERENCE_STRATEGY_POLICY_NOT_FOUND';
    RAISE EXCEPTION USING ERRCODE='P7901', MESSAGE='REFERENCE_LENGTH_EXCEEDED';
    RAISE EXCEPTION USING ERRCODE='P8001', MESSAGE='REFERENCE_NOT_REGISTERED';
    RAISE EXCEPTION USING ERRCODE='P8101', MESSAGE='KEY_CLASS_UNAUTHORIZED';
    RAISE EXCEPTION USING ERRCODE='P8102', MESSAGE='HSM_BYPASS_BLOCKED';
    RAISE EXCEPTION USING ERRCODE='P8201', MESSAGE='POLICY_BUNDLE_UNSIGNED';
    RAISE EXCEPTION USING ERRCODE='P8202', MESSAGE='POLICY_BUNDLE_VERIFICATION_FAILED';
    RETURN 'EXHAUSTED';
    RETURN NEW;
    RETURN NEW;
    RETURN NEW;
    RETURN NULL;
    RETURN NULL;
    RETURN NULL;
    RETURN NULL;
    RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
    RETURN QUERY SELECT p_purge_request_id, v_prior, TRUE;
    RETURN QUERY SELECT v_next_attempt_no, v_effective_state;
    RETURN allocated;
    RETURN v::uuid;
    RETURN;
    RETURN;
    RETURNING (participant_outbox_sequences.next_sequence_id - 1) INTO allocated;
    RETURNING member_id INTO v_target_member_id;
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT 1
    SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
    SELECT EXISTS(
    SELECT a.outbox_id, a.sequence_id, a.created_at, a.state
    SELECT e.escrow_id
    SELECT o.operation_id
    SELECT operation_id INTO v_operation_id
    SELECT p.instruction_id, p.participant_id, p.sequence_id, p.idempotency_key, p.rail_type, p.payload
    SELECT p.outbox_id, p.sequence_id, p.created_at
    SELECT s.alert_id
    SET attempts = v_attempts,
    SET effect_seal_hash = EXCLUDED.effect_seal_hash,
    SET finality_state = EXCLUDED.finality_state,
    SET program_id = EXCLUDED.program_id,
    SET program_id = EXCLUDED.program_id,
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET search_path TO 'pg_catalog', 'public'
    SET state = EXCLUDED.state,
    UPDATE public.inquiry_state_machine
    USING ERRCODE = 'P0001';
    USING ERRCODE = 'P0001';
    USING ERRCODE = 'P7004';
    VALUES (p_instruction_id, v_stored_hash, v_computed_hash);
    VALUES (p_participant_id, 2)
    VALUES (p_reason, p_policy_version_id, md5(p_reason || '|' || now()::text));
    WHEN to_regprocedure('public.uuidv7()') IS NOT NULL THEN 'uuidv7'
    WHERE
    WHERE a.instruction_id = p_instruction_id
    WHERE e.tenant_id = p_tenant_id
    WHERE ia.instruction_id = p_instruction_id
    WHERE instruction_id = p_instruction_id;
    WHERE m.member_id = p_member_id
    WHERE md.tenant_id = p_tenant_id
    WHERE o.state IN ('PENDING', 'ANCHORED')
    WHERE p.instruction_id = p_instruction_id
    WHERE p.outbox_id = p_outbox_id AND p.claimed_by = p_worker_id
    WHERE p.program_id = p_from_program_id
    WHERE p.program_id = p_from_program_id
    WHERE p.program_id = p_to_program_id
    WHERE p.program_id = p_to_program_id
    WHERE pack_id = p_pack_id;
    WHERE pe.person_id = p_person_id
    WHERE pr.program_id = p_program_id
    WHERE r.rail_id = p_rail_id
    WHERE s.source_event_id = v_event.event_id;
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    activation_timestamp timestamp with time zone,
    active boolean DEFAULT true NOT NULL
    active_from date,
    active_to date,
    actor_id text DEFAULT CURRENT_USER NOT NULL,
    actor_id text DEFAULT CURRENT_USER NOT NULL,
    adapter_id text NOT NULL,
    adapter_id text NOT NULL,
    adapter_id, rail_id, classification, truncation_applied, payload_hash,
    adapter_id, rail_id, state, trigger_threshold, observed_rate,
    adjustment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    adjustment_id uuid NOT NULL,
    adjustment_id uuid NOT NULL,
    adjustment_id uuid NOT NULL,
    adjustment_id uuid,
    adjustment_id uuid,
    adjustment_state public.adjustment_state_enum DEFAULT 'requested'::public.adjustment_state_enum NOT NULL,
    adjustment_type text NOT NULL,
    adjustment_value numeric(18,2) NOT NULL,
    adjustment_value numeric(18,2) NOT NULL,
    alert_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    alert_type text DEFAULT 'SIM_SWAP_DETECTED'::text NOT NULL,
    alert_type,
    allocated BIGINT;
    allocated_reference text NOT NULL,
    allocated_sequence := bump_participant_outbox_seq(p_participant_id);
    allocated_sequence BIGINT;
    allocation_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    amount_minor bigint NOT NULL,
    anchor_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    anchor_provider text DEFAULT 'GENERIC'::text NOT NULL,
    anchor_ref text,
    anchor_ref text,
    anchor_type text,
    anchor_type text,
    anchored_at timestamp with time zone DEFAULT now() NOT NULL,
    anchored_at timestamp with time zone DEFAULT now() NOT NULL,
    anchored_at timestamp with time zone,
    api_access boolean NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
    approval_id uuid DEFAULT gen_random_uuid() NOT NULL,
    approved_at timestamp with time zone,
    approved_by text,
    approver_id text NOT NULL,
    archival_confirmed boolean DEFAULT false NOT NULL,
    arrival_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    artifact_hash text NOT NULL,
    artifact_path text,
    artifact_type text NOT NULL,
    artifacts_resigned_count integer NOT NULL,
    artifacts_with_pending_tier_assignment_cleared boolean DEFAULT false CONSTRAINT resign_sweeps_artifacts_with_pending_tier_assignment_c_not_null NOT NULL,
    assurance_tier text NOT NULL,
    assurance_tier text,
    assurance_tier, signing_path, outcome
    attempt_count integer DEFAULT 0 NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    attempt_id uuid DEFAULT gen_random_uuid() NOT NULL,
    attempt_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    attempt_id uuid NOT NULL,
    attempt_id,
    attempt_no integer NOT NULL,
    attempt_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    attestation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    attestation_id uuid NOT NULL,
    attestation_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    authority_reference text NOT NULL,
    authorization_expires_at timestamp with time zone,
    authorized_amount_minor bigint NOT NULL,
    behavior_profile text NOT NULL,
    behavior_profile, evidence_artifact_type
    billable_client_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    billable_client_id uuid NOT NULL,
    billable_client_id uuid,
    billable_client_id uuid,
    block_end timestamp with time zone,
    block_start timestamp with time zone DEFAULT now() NOT NULL,
    boz_licence_reference text,
    boz_reference text,
    calculated_at timestamp with time zone,
    calculated_by_version text,
    callback_payload_hash text CONSTRAINT orphaned_attestation_landing_zon_callback_payload_hash_not_null NOT NULL,
    callback_payload_hash,
    callback_payload_hash,
    callback_payload_truncated text CONSTRAINT orphaned_attestation_landin_callback_payload_truncated_not_null NOT NULL,
    callback_payload_truncated,
    callback_payload_truncated,
    caller_id text NOT NULL,
    caller_id text NOT NULL,
    caller_id, key_id, key_class, artifact_type, digest_hash,
    canceled_at timestamp with time zone,
    canonicalization_version text NOT NULL,
    canonicalization_version text,
    canonicalization_version, signing_service_id, trust_chain_ref,
    canonicalized_reference text NOT NULL,
    cap_amount_minor bigint,
    cap_applied_minor bigint,
    cap_currency_code character(3),
    capture_timestamp timestamp with time zone DEFAULT now() NOT NULL
    ceiling_amount_minor bigint DEFAULT 0 NOT NULL,
    ceiling_amount_minor bigint NOT NULL,
    ceiling_amount_minor,
    ceiling_currency character(3) DEFAULT 'USD'::bpchar NOT NULL,
    ceiling_currency,
    cert_fingerprint_sha256 text NOT NULL,
    cert_fingerprint_sha256 text,
    checksum text NOT NULL,
    checksum text NOT NULL,
    claimed_at timestamp with time zone DEFAULT now() NOT NULL,
    claimed_by text,
    claimed_by text,
    classification public.orphan_classification_enum NOT NULL,
    classification public.quarantine_classification_enum NOT NULL,
    classification,
    classification,
    client_id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_id uuid,
    client_id uuid,
    client_id_hash text,
    client_key text NOT NULL,
    client_key text,
    client_type text NOT NULL,
    collision_count integer NOT NULL,
    collision_event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    collision_retry_count integer DEFAULT 0 NOT NULL,
    completed_at timestamp with time zone,
    computed_dispatch_hash text NOT NULL,
    containment_action text,
    contradiction_timestamp timestamp with time zone,
    contradiction_timestamp, containment_action
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    count(DISTINCT person_id) AS unique_beneficiaries
    created_at
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
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
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    created_by text DEFAULT CURRENT_USER NOT NULL,
    currency_code character(3) NOT NULL,
    currency_code character(3) NOT NULL,
    currency_code character(3),
    current_user,
    db_access boolean NOT NULL,
    decided_at timestamp with time zone,
    decided_at, decided_by, decision_reason, approved_by, approved_at
    decided_by text,
    decision_reason text,
    department_at_time_of_signing text NOT NULL,
    derived_at
    derived_at timestamp with time zone DEFAULT now() NOT NULL,
    description text NOT NULL,
    description text NOT NULL,
    description text NOT NULL,
    detected_at timestamp with time zone NOT NULL,
    device_id text,
    device_id_hash text NOT NULL,
    device_id_hash text,
    digest_hash text NOT NULL,
    dispatch_attempted_at timestamp with time zone,
    dispatch_blocked boolean DEFAULT true NOT NULL,
    dispatch_reference text,
    display_name text NOT NULL,
    document_type text,
    downstream_ref text,
    downstream_ref text,
    downstream_ref text,
    drill_id uuid DEFAULT gen_random_uuid() NOT NULL,
    drill_outcome text NOT NULL,
    e.event_type,
    e.instruction_id,
    e.member_id,
    e.observed_at
    e.tenant_id,
    effect_seal_hash text NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    enrolled_at timestamp with time zone DEFAULT now() NOT NULL,
    enrolled_at,
    entity_id text,
    entity_id uuid NOT NULL,
    entity_id,
    error_code text,
    error_code text,
    error_message text,
    escrow_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    escrow_id uuid NOT NULL,
    escrow_id uuid NOT NULL,
    event_fingerprint
    event_fingerprint
    event_fingerprint text NOT NULL
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    event_payload jsonb NOT NULL,
    event_timestamp timestamp with time zone DEFAULT now() NOT NULL
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type,
    event_type,
    evidence_artifact_type text NOT NULL,
    evidence_path text,
    existing_attempt RECORD;
    existing_pending RECORD;
    expired_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone,
    expires_at timestamp with time zone,
    expires_at timestamp with time zone,
    exportable boolean DEFAULT false NOT NULL,
    fallback_posture text NOT NULL,
    filed_at timestamp with time zone,
    filing_deadline date,
    final_state text NOT NULL,
    finality_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    finality_state public.finality_resolution_state_enum DEFAULT 'ACTIVE'::public.finality_resolution_state_enum NOT NULL,
    finalized_at timestamp with time zone DEFAULT now() NOT NULL,
    flag_id uuid DEFAULT gen_random_uuid() NOT NULL,
    flag_type text NOT NULL,
    formula_key text NOT NULL,
    formula_name text NOT NULL,
    formula_spec jsonb DEFAULT '{}'::jsonb NOT NULL,
    formula_version_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    formula_version_id uuid NOT NULL,
    formula_version_id uuid NOT NULL,
    formula_version_id,
    formula_version_id,
    from_program_id uuid NOT NULL,
    from_program_id,
    gap_marker_id text NOT NULL,
    grace_expires_at timestamp with time zone,
    hash_algorithm text,
    held_at timestamp with time zone DEFAULT now() NOT NULL,
    held_reason text,
    high_risk boolean DEFAULT false NOT NULL,
    hold_timeout_minutes integer,
    iccid_hash text,
    iccid_hash text,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    idempotency_key text NOT NULL,
    idempotency_key text NOT NULL,
    idempotency_key text NOT NULL,
    idempotency_key text,
    identity_hash text NOT NULL,
    incident_event_id uuid NOT NULL,
    incident_id uuid NOT NULL,
    incident_id uuid NOT NULL,
    incident_type text NOT NULL,
    inquiry_state public.inquiry_state_enum DEFAULT 'SCHEDULED'::public.inquiry_state_enum NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id text NOT NULL,
    instruction_id uuid NOT NULL,
    instruction_id uuid NOT NULL,
    instruction_id uuid NOT NULL,
    instruction_id,
    instruction_id,
    instruction_id,
    instruction_id, finality_state, rail_a_id, rail_a_response, rail_b_id, rail_b_response,
    instruction_id, program_id, status, held_at, held_reason, timeout_at, submitted_by,
    instruction_id, program_id, status, held_at, timeout_at, decided_at, decided_by, decision_reason
    instruction_id, scenario_type, fallback_posture, policy_version_id,
    instruction_state_at_arrival text CONSTRAINT orphaned_attestation_landin_instruction_state_at_arriv_not_null NOT NULL,
    instruction_state_at_arrival,
    instruction_state_at_arrival,
    is_active boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_active boolean GENERATED ALWAYS AS ((status = 'ACTIVE'::public.policy_version_status)) STORED,
    is_active boolean,
    is_final boolean DEFAULT true NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    issued_by text NOT NULL,
    item_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    jsonb_build_object('executor', p_executor)
    jsonb_build_object('subject_token', p_subject_token)
    jurisdiction_code character(2) NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    jurisdiction_code character(2),
    jurisdiction_code character(2),
    justification text,
    justification_text text
    key_backend text NOT NULL,
    key_class public.key_class_enum NOT NULL,
    key_class public.key_class_enum NOT NULL,
    key_id text NOT NULL,
    key_used text NOT NULL,
    key_version text NOT NULL,
    kyc_hold boolean,
    kyc_status text DEFAULT 'PENDING'::text NOT NULL,
    kyc_status,
    last_error text,
    latency_ms integer,
    lease_expires_at timestamp with time zone,
    lease_expires_at timestamp with time zone,
    lease_token uuid,
    lease_token uuid,
    left(coalesce(p_event_fingerprint,''), 1024),
    left(coalesce(p_payload::text, '{}'), 4096),
    legal_name text NOT NULL,
    legal_name text NOT NULL,
    length(coalesce(p_payload,'')) > v_limit,
    levy_amount_final bigint,
    levy_amount_pre_cap bigint,
    levy_applicable boolean
    levy_rate_id uuid,
    levy_status text,
    matrix_id uuid DEFAULT gen_random_uuid() NOT NULL,
    max_attempts integer NOT NULL,
    md5(coalesce(p_event_fingerprint,'')),
    md5(coalesce(p_payload,'')),
    md5(coalesce(p_payload::text, '{}')),
    md5(v_source_member.member_ref_hash || ':migrated:' || p_new_entity_id::text || ':' || now()::text),
    member_id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    member_id uuid NOT NULL,
    member_id uuid NOT NULL,
    member_id uuid NOT NULL,
    member_id uuid NOT NULL,
    member_id uuid,
    member_id uuid,
    member_id,
    member_id,
    member_ref text NOT NULL,
    member_ref_hash text NOT NULL,
    member_ref_hash,
    meta_signing_key_class public.key_class_enum NOT NULL,
    metadata
    metadata
    metadata
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    metadata jsonb,
    metadata jsonb,
    metadata jsonb,
    metadata jsonb,
    migrated_at timestamp with time zone DEFAULT now() NOT NULL,
    migrated_at,
    migrated_by text NOT NULL,
    migrated_by,
    migrated_member_id uuid NOT NULL,
    migrated_member_id,
    migration_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    mismatch_detected boolean DEFAULT true NOT NULL,
    msisdn_hash bytea,
    new_iccid_hash text NOT NULL,
    new_iccid_hash,
    new_key_activation_timestamp timestamp with time zone,
    new_key_id text NOT NULL,
    new_member_id uuid NOT NULL,
    new_member_id,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    next_sequence_id bigint NOT NULL,
    nfs_sequence_ref text,
    nfs_sequence_ref text,
    nfs_sequence_ref text,
    observed_at timestamp with time zone NOT NULL,
    observed_rate numeric(8,6) DEFAULT 0 NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    old_key_deactivation_timestamp timestamp with time zone,
    old_key_id text NOT NULL,
    operation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    operational_store_excluded boolean DEFAULT true CONSTRAINT historical_verification_run_operational_store_excluded_not_null NOT NULL,
    operator_id text NOT NULL,
    operator_id text,
    operator_resolution_id text,
    orphan_id uuid DEFAULT gen_random_uuid() NOT NULL,
    outbox_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    outbox_id uuid NOT NULL,
    outbox_id uuid NOT NULL,
    outbox_id,
    outcome text NOT NULL
    outcome text NOT NULL,
    outcome text NOT NULL,
    outcome text NOT NULL,
    outcome text,
    p_actor_id => p_actor_id,
    p_actor_id => v_actor,
    p_adapter_id,
    p_adapter_id, p_rail_id, v_state, p_trigger_threshold, p_observed_rate,
    p_assurance_tier, p_signing_path, 'PASS'
    p_behavior_profile, p_evidence_artifact_type
    p_caller_id, p_key_id, p_key_class, p_artifact_type, p_digest_hash,
    p_classification,
    p_escrow_id => p_escrow_id,
    p_escrow_id => v_reservation_escrow_id,
    p_event_fingerprint
    p_fingerprint
    p_from_program_id,
    p_held_reason,
    p_instruction_id,
    p_instruction_id,
    p_instruction_id,
    p_instruction_id, p_program_id, 'PENDING_SUPERVISOR_APPROVAL', NOW(), NOW() + make_interval(mins => v_timeout), NULL, NULL, NULL
    p_instruction_id, p_scenario_type, p_fallback_posture, p_policy_version_id,
    p_instruction_id, v_state, p_rail_a_id, p_rail_a_status, p_rail_b_id, p_rail_b_status,
    p_metadata => COALESCE(p_metadata, '{}'::jsonb),
    p_metadata => COALESCE(p_metadata, '{}'::jsonb),
    p_new_entity_id,
    p_now
    p_now => NOW()
    p_now => NOW()
    p_parent_instruction_id, p_adjustment_type, p_adjustment_value,
    p_person_id,
    p_policy_version_id
    p_program_id,
    p_purge_request_id,
    p_rail_id,
    p_reason => COALESCE(p_reason, 'reservation_authorized'),
    p_reason => p_reason,
    p_reason,
    p_request_reason
    p_requested_by,
    p_state_at_arrival,
    p_subject_token,
    p_tenant_id,
    p_to_program_id,
    p_to_state => 'AUTHORIZED',
    p_to_state => 'RELEASED',
    p_window_seconds, p_policy_version_id,
    pack_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    pack_id uuid NOT NULL,
    pack_id uuid NOT NULL,
    pack_type text NOT NULL,
    parent_instruction_id text NOT NULL,
    parent_instruction_id, adjustment_type, adjustment_value,
    parent_tenant_id uuid,
    participant_id text NOT NULL,
    participant_id text NOT NULL,
    participant_id text NOT NULL,
    participant_id text NOT NULL,
    participant_id text NOT NULL,
    participant_id text NOT NULL,
    participant_id text,
    participant_id,
    participant_kind text NOT NULL,
    payload jsonb NOT NULL,
    payload jsonb NOT NULL,
    payload_capture text NOT NULL,
    payload_capture, retention_policy_version_id
    payload_hash text NOT NULL,
    payload_hash text NOT NULL,
    period_code character(7) NOT NULL,
    period_end date NOT NULL,
    period_start date NOT NULL,
    period_status text,
    permitted_artifact_types text[] DEFAULT '{}'::text[] NOT NULL,
    person_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    person_id uuid NOT NULL,
    person_id uuid NOT NULL,
    person_id,
    person_id,
    person_ref_hash text NOT NULL,
    policy_bundle_id uuid DEFAULT gen_random_uuid() NOT NULL,
    policy_id text NOT NULL,
    policy_json jsonb NOT NULL,
    policy_version text NOT NULL,
    policy_version_id text NOT NULL,
    policy_version_id text NOT NULL,
    policy_version_id text NOT NULL,
    policy_version_id text NOT NULL,
    policy_version_id text NOT NULL,
    policy_version_id text NOT NULL,
    policy_version_id text NOT NULL,
    policy_version_id text NOT NULL,
    policy_version_id text,
    prior_iccid_hash text NOT NULL,
    prior_iccid_hash,
    program_escrow_id uuid NOT NULL,
    program_escrow_id uuid NOT NULL,
    program_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    program_id uuid NOT NULL,
    program_id uuid NOT NULL,
    program_id uuid,
    program_key text NOT NULL,
    program_name text NOT NULL,
    proof_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    protected_payload jsonb,
    provider text NOT NULL,
    provider_code text NOT NULL,
    provider_code text,
    provider_id uuid,
    provider_key_version text,
    provider_name text NOT NULL,
    provider_ref text,
    provider_reference text,
    provider_signature text,
    public.uuid_v7_or_random(),
    public_key_pem text,
    purge_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    purge_request_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    purge_request_id uuid NOT NULL,
    purge_request_id uuid,
    purge_request_id,
    purge_request_id,
    purged_at timestamp with time zone,
    quantity bigint NOT NULL,
    quarantine_id uuid DEFAULT gen_random_uuid() NOT NULL,
    quorum_policy_version_id text NOT NULL,
    quorum_threshold integer NOT NULL,
    rail_a_id text,
    rail_a_response public.finality_signal_status_enum,
    rail_b_id text,
    rail_b_response public.finality_signal_status_enum,
    rail_code text,
    rail_id text NOT NULL,
    rail_id text NOT NULL,
    rail_id text NOT NULL,
    rail_id text NOT NULL,
    rail_message_type text NOT NULL,
    rail_participant_id text NOT NULL,
    rail_participant_id,
    rail_profile text NOT NULL,
    rail_profile,
    rail_reference text,
    rail_sequence_ref text NOT NULL,
    rail_sequence_ref,
    rail_type text NOT NULL,
    rail_type text NOT NULL,
    rate_bps integer NOT NULL,
    re_sign_linked boolean DEFAULT false NOT NULL
    read_window_minutes integer,
    reason text NOT NULL,
    reason text,
    reason text,
    reason text,
    reason,
    reason_code text,
    reason_code text,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    recipient_ref text NOT NULL,
    recipient_ref, policy_version_id, justification
    reference_attempted text CONSTRAINT dispatch_reference_collision_event_reference_attempted_not_null NOT NULL,
    registry_id uuid DEFAULT gen_random_uuid() NOT NULL,
    regulator_ref text,
    release_due_at timestamp with time zone,
    released_at timestamp with time zone,
    report_delivery boolean NOT NULL,
    reported_to_boz_at timestamp with time zone,
    reporting_period character(7),
    request_hash text NOT NULL,
    request_reason
    request_reason text NOT NULL,
    requested_at timestamp with time zone DEFAULT now() NOT NULL
    requested_by text NOT NULL,
    requested_by,
    required_approver_count integer NOT NULL,
    reservation_escrow_id uuid NOT NULL,
    reservation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    reserved_amount_minor bigint DEFAULT 0 NOT NULL,
    resolved_at timestamp with time zone
    response_hash text NOT NULL,
    resumed_at timestamp with time zone,
    retention_class text DEFAULT 'FIC_AML_CUSTOMER_ID'::text NOT NULL,
    retention_class text NOT NULL,
    retention_policy_version_id text NOT NULL,
    retention_years integer NOT NULL,
    reversal_of_instruction_id text,
    revoked_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    revoked_by text
    revoked_by text
    role_at_time_of_signing text NOT NULL,
    rolling_window_seconds integer NOT NULL,
    rolling_window_seconds, policy_version_id, suspended_at
    root_hash text,
    rotation_type text NOT NULL,
    rows_affected integer DEFAULT 0 NOT NULL,
    rows_affected,
    rows_affected,
    s->>'collision_action',
    s->>'rail_id',
    scenario_type text NOT NULL,
    scope text DEFAULT 'AUDIT'::text NOT NULL,
    scope text NOT NULL,
    sealed_at timestamp with time zone DEFAULT now() NOT NULL
    sequence_id bigint NOT NULL,
    sequence_id bigint NOT NULL,
    severity text NOT NULL,
    sign_event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text,
    signature_alg text,
    signature_hash text,
    signature_ref text NOT NULL,
    signature_valid boolean DEFAULT false NOT NULL,
    signatures jsonb DEFAULT '[]'::jsonb NOT NULL,
    signed_at timestamp with time zone,
    signed_at timestamp with time zone,
    signed_key_id text,
    signer_key_id text,
    signer_participant_id text,
    signing_algorithm text,
    signing_path text NOT NULL,
    signing_service_id text NOT NULL,
    source_event_id uuid NOT NULL,
    source_event_id,
    stage_id uuid DEFAULT gen_random_uuid() NOT NULL,
    stage_id uuid NOT NULL,
    stage_status text NOT NULL,
    state
    state public.outbox_attempt_state NOT NULL,
    state public.outbox_attempt_state NOT NULL,
    state public.policy_bundle_state_enum DEFAULT 'draft'::public.policy_bundle_state_enum NOT NULL,
    state text DEFAULT 'ACTIVE'::text NOT NULL,
    state text DEFAULT 'CREATED'::text NOT NULL,
    state text DEFAULT 'PENDING'::text NOT NULL,
    status public.policy_version_status DEFAULT 'ACTIVE'::public.policy_version_status NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text NOT NULL,
    status text NOT NULL,
    status,
    statutory_reference text NOT NULL,
    statutory_reference text,
    stored_seal_hash text NOT NULL,
    strategy_used public.reference_strategy_type_enum NOT NULL,
    strategy_used public.reference_strategy_type_enum NOT NULL,
    subject_client_id uuid,
    subject_member_id uuid
    subject_member_id uuid,
    subject_token text NOT NULL,
    subject_token text NOT NULL,
    subject_token,
    submitted_by text,
    suspended_at timestamp with time zone,
    sweep_completed_timestamp timestamp with time zone NOT NULL,
    sweep_id uuid DEFAULT gen_random_uuid() NOT NULL,
    taxable_amount_minor bigint,
    tenant_id uuid DEFAULT gen_random_uuid() NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    tenant_id uuid,
    tenant_id uuid,
    tenant_id uuid,
    tenant_id uuid,
    tenant_id,
    tenant_id,
    tenant_id,
    tenant_id, program_escrow_id, reservation_escrow_id, amount_minor, actor_id, reason, metadata, created_at
    tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at, release_due_at
    tenant_key text NOT NULL,
    tenant_member_id uuid NOT NULL,
    tenant_member_id,
    tenant_name text NOT NULL,
    tenant_type text NOT NULL,
    tier text NOT NULL,
    timeout_at timestamp with time zone NOT NULL,
    to_program_id uuid NOT NULL,
    to_program_id,
    token_hash text NOT NULL,
    token_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    token_jti text NOT NULL,
    token_jti_hash text,
    tpin_hash bytea,
    trigger_reason text,
    trigger_threshold numeric(8,6) NOT NULL,
    truncation_applied boolean NOT NULL,
    trust_chain_ref text,
    units text NOT NULL,
    unsigned_reason text
    unsigned_reason text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    upstream_ref text,
    upstream_ref text,
    upstream_ref text,
    v_actor,
    v_attempt := v_attempt + 1;
    v_canon := public.canonicalize_reference_for_rail(v_candidate, p_rail_id);
    v_capture,
    v_class := 'DUPLICATE_DISPATCH';
    v_class := 'LATE_CALLBACK';
    v_class := 'REPLAY_ATTEMPT';
    v_class := 'UNKNOWN_REFERENCE';
    v_class := 'UNKNOWN_REFERENCE';
    v_class,
    v_count := v_count + 1;
    v_effective_state := p_state;
    v_env.tenant_id, NULL, NULL, 'CREATED', v_amount, v_env.currency_code, NOW() + interval '30 minutes', NOW() + interval '60 minutes'
    v_env.tenant_id, v_env.escrow_id, v_reservation_escrow_id, v_amount, v_actor, p_reason, COALESCE(p_metadata, '{}'::jsonb), NOW()
    v_event.event_id,
    v_event.iccid_hash,
    v_event.member_id,
    v_event.tenant_id,
    v_formula_version_id,
    v_formula_version_id,
    v_idempotency_key TEXT; v_rail_type TEXT; v_payload JSONB;
    v_instruction_id TEXT; v_participant_id TEXT; v_sequence_id BIGINT;
    v_new_member_id,
    v_new_member_id,
    v_next_attempt_no INT;
    v_next_attempt_no INT; v_effective_state outbox_attempt_state;
    v_policy.policy_version_id
    v_prior_iccid_hash,
    v_profile,
    v_reason,
    v_recipient, p_policy_version_id, p_justification
    v_record RECORD;
    v_request_id,
    v_retry_ceiling := public.outbox_retry_ceiling();
    v_retry_ceiling INT;
    v_row.escrow_id,
    v_row.tenant_id,
    v_rows,
    v_sequence_ref,
    v_source_member.ceiling_amount_minor,
    v_source_member.ceiling_currency,
    v_source_member.kyc_status,
    v_source_member.person_id,
    v_source_member.status,
    v_source_member.tenant_id,
    v_source_member.tenant_member_id,
    v_state := 'FINALITY_CONFLICT';
    v_state := 'SUSPENDED';
    v_submitted_by,
    v_to_state,
    vault_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    verification_hash text,
    verification_method text,
    verification_outcome text,
    verification_run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    verified_artifact_id text NOT NULL,
    verified_at timestamp with time zone,
    verified_at_provider timestamp with time zone,
    version text NOT NULL,
    version text NOT NULL,
    version_status text DEFAULT 'ACTIVE'::text NOT NULL,
    window_id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_id text,
    zra_reference text,
   FROM (public.member_device_events e
   FROM due
   FROM public.members m
   RETURNING
   SET
   UPDATE payment_outbox_pending p
   WHERE ia.attestation_id = NEW.attestation_id;
   WHERE p.outbox_id = due.outbox_id
   WHERE subject_token = v_subject_token
   WHERE t.tenant_id = derived_tenant_id;
  )
  )
  )
  )
  )
  )
  )
  )
  )
  )
  )
  )
  ) AS t;
  ) INTO v_exists;
  ) RETURNING adjustment_id INTO v_id;
  ) RETURNING event_id INTO v_id;
  ) RETURNING orphan_id INTO v_id;
  ) RETURNING quarantine_id INTO v_id;
  ) RETURNING sign_event_id INTO v_event_id;
  ) THEN
  ) THEN
  ) THEN
  ) THEN
  ) THEN
  ) THEN
  ) THEN
  ) THEN
  ) THEN
  ) THEN
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  ) VALUES (
  );
  );
  );
  );
  );
  );
  );
  );
  BEGIN
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
  DO NOTHING;
  ELSE
  ELSIF NEW.billable_client_id <> derived_billable_client_id THEN
  ELSIF NEW.tenant_id <> derived_tenant_id THEN
  ELSIF p_has_unknown_reference THEN
  ELSIF p_is_duplicate_dispatch THEN
  ELSIF p_is_replay THEN
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END IF;
  END LOOP;
  END LOOP;
  END;
  END;
  END;
  END;
  END;
  END;
  END;
  END;
  END;
  END;
  EXCEPTION WHEN invalid_text_representation THEN
  FOR UPDATE SKIP LOCKED
  FOR UPDATE;
  FOR UPDATE;
  FOR UPDATE;
  FOR UPDATE;
  FOR UPDATE;
  FOR UPDATE;
  FOR v_escrow_id IN
  FROM candidate c
  FROM jsonb_array_elements(v_policy.policy_json->'strategies') AS s
  FROM payment_outbox_pending p
  FROM public.adjustment_execution_attempts e
  FROM public.anchor_sync_operations
  FROM public.anchor_sync_operations
  FROM public.escrow_accounts
  FROM public.escrow_envelopes
  FROM public.inquiry_state_machine
  FROM public.inquiry_state_machine
  FROM public.inquiry_state_machine
  FROM public.instruction_effect_seals
  FROM public.instruction_settlement_finality
  FROM public.member_device_events e
  FROM public.member_devices md
  FROM public.members m
  FROM public.members m
  FROM public.members m
  FROM public.pii_purge_events e
  FROM public.pii_purge_requests r
  FROM public.programs
  FROM public.reference_strategy_policy_versions
  FROM public.risk_formula_versions rf
  FROM public.risk_formula_versions rf
  FROM public.risk_formula_versions rf
  FROM public.signing_authorization_matrix
  FROM public.tenant_members
  FROM public.transition_escrow_state(
  FROM public.transition_escrow_state(
  GET DIAGNOSTICS v_count = ROW_COUNT;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  GROUP BY tenant_id, (EXTRACT(year FROM enrolled_at));
  IF COALESCE(v_allowed, false) IS NOT true THEN
  IF COALESCE(v_ok,false) IS NOT true THEN
  IF EXISTS (
  IF FOUND THEN
  IF NEW.billable_client_id IS NULL THEN
  IF NEW.correlation_id IS NULL THEN
  IF NEW.is_final IS DISTINCT FROM TRUE THEN
  IF NEW.member_id IS NULL THEN
  IF NEW.reversal_of_instruction_id IS NULL THEN
  IF NEW.state <> 'DISPATCHED' THEN
  IF NEW.tenant_id IS NULL THEN
  IF NEW.tenant_id IS NULL THEN
  IF NOT EXISTS (
  IF NOT EXISTS (
  IF NOT EXISTS (
  IF NOT EXISTS (
  IF NOT EXISTS (
  IF NOT EXISTS (
  IF NOT EXISTS (
  IF NOT EXISTS (
  IF NOT EXISTS (
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT FOUND THEN
  IF NOT v_exists THEN
  IF NOT v_legal THEN
  IF NULLIF(BTRIM(p_anchor_ref), '') IS NULL THEN
  IF OLD.is_final IS TRUE THEN
  IF OLD.version_status = 'ACTIVE' THEN
  IF TG_OP = 'UPDATE' THEN
  IF TG_OP='UPDATE' AND OLD.adjustment_state IN ('executed','denied','blocked_legal_hold') THEN
  IF derived_billable_client_id IS NULL THEN
  IF derived_tenant_id IS NULL THEN
  IF length(v_truncated) > v_strategy.max_length THEN
  IF m_tenant <> NEW.tenant_id THEN
  IF m_tenant IS NULL THEN
  IF p_current_state = 'cooling_off' THEN
  IF p_entity_id IS DISTINCT FROM p_program_id THEN
  IF p_freeze_flag_type IS NOT NULL THEN
  IF p_from_program_id = p_to_program_id THEN
  IF p_from_program_id = p_to_program_id THEN
  IF p_is_late_callback THEN
  IF p_is_offline THEN
  IF p_lease_seconds IS NULL OR p_lease_seconds <= 0 THEN
  IF p_max_attempts IS NULL OR p_max_attempts <= 0 THEN
  IF p_new_entity_id IS DISTINCT FROM p_to_program_id THEN
  IF p_observed_rate >= p_trigger_threshold THEN
  IF p_pack_id IS NULL THEN
  IF p_rail_a_status IN ('SUCCESS','FAILED')
  IF p_scenario_type NOT IN ('ASYNC_CONTRADICTION', 'DELAYED_SETTLEMENT', 'DUAL_DEBIT_RISK', 'SILENT_REJECTION') THEN
  IF p_signing_path = 'SOFTWARE_BYPASS' THEN
  IF v IS NULL OR btrim(v) = '' THEN
  IF v_alert_id IS NULL THEN
  IF v_amount <= 0 THEN
  IF v_attempts >= v_max THEN
  IF v_class IN ('DUPLICATE_DISPATCH', 'UNKNOWN_REFERENCE', 'REPLAY_ATTEMPT') THEN
  IF v_computed_hash <> v_stored_hash THEN
  IF v_decision NOT IN ('APPROVED', 'REJECTED') THEN
  IF v_env.reserved_amount_minor + v_amount > v_env.ceiling_amount_minor THEN
  IF v_event.event_type <> 'SIM_SWAP_DETECTED' OR v_event.iccid_hash IS NULL THEN
  IF v_formula_version_id IS NULL THEN
  IF v_formula_version_id IS NULL THEN
  IF v_formula_version_id IS NULL THEN
  IF v_op.claimed_by IS DISTINCT FROM p_worker_id THEN
  IF v_op.claimed_by IS DISTINCT FROM p_worker_id THEN
  IF v_op.lease_token IS DISTINCT FROM p_lease_token OR v_op.lease_expires_at IS NULL OR v_op.lease_expires_at <= clock_timestamp() THEN
  IF v_op.lease_token IS DISTINCT FROM p_lease_token OR v_op.lease_expires_at IS NULL OR v_op.lease_expires_at <= clock_timestamp() THEN
  IF v_op.state <> 'ANCHORED' OR NULLIF(BTRIM(v_op.anchor_ref), '') IS NULL THEN
  IF v_op.state NOT IN ('ANCHORING', 'ANCHORED') THEN
  IF v_operation_id IS NULL THEN
  IF v_policy.policy_version_id IS NULL THEN
  IF v_prior_iccid_hash IS NULL THEN
  IF v_program_id IS NULL THEN
  IF v_row.state IN ('RELEASED', 'CANCELED', 'EXPIRED') THEN
  IF v_sequence_ref IS NULL THEN
  IF v_source_state <> 'SETTLED' OR v_source_final IS DISTINCT FROM TRUE THEN
  IF v_state <> 'SENT' THEN
  IF v_state = 'EXHAUSTED' THEN
  IF v_state = 'FINALITY_CONFLICT' THEN
  IF v_state = 'SUSPENDED' THEN
  IF v_state IN ('ACKNOWLEDGED', 'EXHAUSTED') THEN
  IF v_state IS NULL THEN
  IF v_stored_hash IS NULL THEN
  IF v_target_member_id IS NULL THEN
  IF v_timeout <= 0 THEN
  IF v_timeout <= 0 THEN
  IF v_to_state NOT IN ('CREATED', 'AUTHORIZED', 'RELEASE_REQUESTED', 'RELEASED', 'CANCELED', 'EXPIRED') THEN
  IF v_total > p_parent_instruction_value THEN
  IF v_worker IS NULL THEN
  INSERT INTO public.adapter_circuit_breakers(
  INSERT INTO public.adjustment_instructions(
  INSERT INTO public.anchor_sync_operations(pack_id, anchor_provider)
  INSERT INTO public.escrow_accounts(
  INSERT INTO public.escrow_events(escrow_id, tenant_id, event_type, actor_id, reason, metadata, created_at)
  INSERT INTO public.escrow_reservations(
  INSERT INTO public.inquiry_state_machine(instruction_id, inquiry_state, attempts, max_attempts, policy_version_id)
  INSERT INTO public.instruction_effect_seals(instruction_id, effect_seal_hash, canonicalization_version, policy_version_id)
  INSERT INTO public.instruction_finality_conflicts(
  INSERT INTO public.malformed_quarantine_store(
  INSERT INTO public.members(
  INSERT INTO public.mmo_reality_control_events(
  INSERT INTO public.orphaned_attestation_landing_zone(
  INSERT INTO public.orphaned_attestation_landing_zone(
  INSERT INTO public.pii_purge_events(
  INSERT INTO public.pii_purge_events(
  INSERT INTO public.pii_purge_requests(
  INSERT INTO public.program_migration_events(
  INSERT INTO public.rail_dispatch_truth_anchor(
  INSERT INTO public.signing_audit_log(
  INSERT INTO public.sim_swap_alerts(
  INSERT INTO public.supervisor_approval_queue(
  INSERT INTO public.supervisor_approval_queue(
  INTO v_env
  INTO v_event
  INTO v_event_id
  INTO v_formula_version_id
  INTO v_formula_version_id
  INTO v_formula_version_id
  INTO v_prior
  INTO v_prior_iccid_hash
  INTO v_program_id
  INTO v_row
  INTO v_source_member
  INTO v_source_member
  INTO v_source_state, v_source_final
  INTO v_stored_hash, v_canonical_version
  INTO v_subject_token
  INTO v_target_member_id
  INTO v_total
  JOIN public.adjustment_instructions a ON a.adjustment_id=e.adjustment_id
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT 1;
  LIMIT p_batch_size
  LOOP
  LOOP
  NEW.metadata := COALESCE(NEW.metadata, '{}'::jsonb);
  NEW.updated_at := NOW();
  NEW.updated_at := NOW();
  NEW.updated_at := NOW();
  NEW.updated_at := NOW();
  NEW.updated_at := NOW();
  NEW.updated_at := now();
  ON CONFLICT (adapter_id, rail_id) DO UPDATE
  ON CONFLICT (instruction_id) DO NOTHING;
  ON CONFLICT (instruction_id) DO UPDATE
  ON CONFLICT (instruction_id) DO UPDATE
  ON CONFLICT (instruction_id) DO UPDATE
  ON CONFLICT (instruction_id) DO UPDATE
  ON CONFLICT (pack_id) DO NOTHING
  ON CONFLICT (source_event_id) DO NOTHING
  ON CONFLICT ON CONSTRAINT ux_pii_purge_events_request_event
  ORDER BY CASE WHEN s->>'rail_id' = p_rail_id THEN 0 ELSE 1 END
  ORDER BY activated_at DESC
  ORDER BY created_at ASC
  ORDER BY m.enrolled_at DESC
  ORDER BY m.enrolled_at DESC
  ORDER BY md.created_at DESC, md.device_id_hash DESC
  ORDER BY p.next_attempt_at ASC, p.created_at ASC
  ORDER BY rf.created_at DESC
  ORDER BY rf.created_at DESC
  ORDER BY rf.created_at DESC
  PERFORM 1
  PERFORM public.assert_key_class_authorized(p_caller_id, p_key_class);
  PERFORM public.submit_for_supervisor_approval(p_instruction_id, v_program_id, 30, NULL, 'system');
  PERFORM set_config('symphony.allow_pii_purge', 'on', true);
  RAISE EXCEPTION 'ADJUSTMENT_RECIPIENT_NOT_PERMITTED' USING ERRCODE = 'P7601';
  RAISE EXCEPTION 'member_device_events is append-only'
  RAISE EXCEPTION 'pii_vault_records is non-deletable'
  RAISE EXCEPTION 'sim_swap_alerts is append-only'
  RETURN 'ACKNOWLEDGED';
  RETURN 'SENT';
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN NEW;
  RETURN OLD;
  RETURN QUERY
  RETURN QUERY
  RETURN QUERY
  RETURN QUERY SELECT p_purge_request_id, v_rows, FALSE;
  RETURN TRUE;
  RETURN md5(v_input);
  RETURN v_alert_id;
  RETURN v_class;
  RETURN v_count;
  RETURN v_count;
  RETURN v_count;
  RETURN v_event_id;
  RETURN v_event_id;
  RETURN v_hash;
  RETURN v_id;
  RETURN v_id;
  RETURN v_id;
  RETURN v_id;
  RETURN v_new_member_id;
  RETURN v_operation_id;
  RETURN v_request_id;
  RETURN v_reservation_escrow_id;
  RETURN v_state;
  RETURN v_state;
  RETURN v_target_member_id;
  RETURN v_truncated;
  RETURNING alert_id INTO v_alert_id;
  RETURNING escrow_accounts.escrow_id INTO v_reservation_escrow_id;
  RETURNING escrow_events.event_id INTO v_event_id;
  RETURNING member_id INTO v_new_member_id;
  RETURNING o.operation_id, o.pack_id, o.lease_token, o.state, o.attempt_count;
  RETURNING operation_id INTO v_operation_id;
  RETURNING purge_request_id INTO v_request_id;
  SELECT
  SELECT 'parent:' || p_parent_instruction_id INTO v_recipient;
  SELECT *
  SELECT *
  SELECT * INTO v_op
  SELECT * INTO v_op
  SELECT * INTO v_strategy FROM public.resolve_reference_strategy(p_rail_id);
  SELECT * INTO v_strategy FROM public.resolve_reference_strategy(p_rail_id);
  SELECT CASE
  SELECT COALESCE(
  SELECT EXISTS (
  SELECT coalesce(sum(a.adjustment_value),0)
  SELECT e.*
  SELECT e.rows_affected
  SELECT effect_seal_hash, canonicalization_version
  SELECT final_state, is_final
  SELECT ia.tenant_id
  SELECT inquiry_state INTO v_state
  SELECT inquiry_state INTO v_state
  SELECT inquiry_state, attempts, max_attempts INTO v_state, v_attempts, v_max
  SELECT m.*
  SELECT m.*
  SELECT m.member_id
  SELECT md.iccid_hash
  SELECT p.outbox_id
  SELECT parent_instruction_id INTO v_parent FROM public.adjustment_instructions WHERE adjustment_id = p_adjustment_id;
  SELECT policy_version_id, policy_json INTO v_policy
  SELECT program_id
  SELECT r.subject_token
  SELECT rf.formula_version_id
  SELECT rf.formula_version_id
  SELECT rf.formula_version_id
  SELECT signature_valid INTO v_ok FROM public.policy_bundles WHERE policy_bundle_id = p_policy_bundle_id;
  SELECT t.billable_client_id
  SELECT t.event_id
  SELECT tenant_id INTO m_tenant
  SELECT true INTO v_allowed
  SELECT v_row.escrow_id, v_row.state, v_to_state, v_event_id;
  SET attempts = v_attempts,
  SET inquiry_state = 'ACKNOWLEDGED',
  SET reserved_amount_minor = reserved_amount_minor + v_amount,
  SET state = 'ANCHORED',
  SET state = 'COMPLETED',
  SET state = CASE WHEN o.state = 'ANCHORED' THEN 'ANCHORED' ELSE 'ANCHORING' END,
  SET state = CASE WHEN state = 'ANCHORED' THEN 'ANCHORED' ELSE 'PENDING' END,
  SET state = v_to_state,
  SET state='active', activation_timestamp=now(), verification_outcome='PASS', assurance_tier=COALESCE(assurance_tier,'HSM_BACKED')
  SET status = 'TIMED_OUT',
  SET status = v_decision,
  UPDATE public.anchor_sync_operations
  UPDATE public.anchor_sync_operations
  UPDATE public.anchor_sync_operations
  UPDATE public.anchor_sync_operations o
  UPDATE public.escrow_accounts
  UPDATE public.escrow_envelopes
  UPDATE public.inquiry_state_machine
  UPDATE public.inquiry_state_machine
  UPDATE public.pii_vault_records
  UPDATE public.policy_bundles
  UPDATE public.supervisor_approval_queue
  UPDATE public.supervisor_approval_queue
  VALUES (
  VALUES (
  VALUES (p_instruction_id, 'SCHEDULED', 0, p_max_attempts, p_policy_version_id)
  VALUES (p_instruction_id, v_hash, p_canonicalization_version, p_policy_version_id)
  VALUES (p_pack_id, COALESCE(NULLIF(BTRIM(p_anchor_provider), ''), 'GENERIC'))
  WHERE a.parent_instruction_id=v_parent AND e.outcome='executed';
  WHERE caller_id = p_caller_id
  WHERE e.event_id = p_event_id;
  WHERE e.purge_request_id = p_purge_request_id
  WHERE escrow_accounts.escrow_id = p_escrow_id
  WHERE escrow_accounts.escrow_id = p_escrow_id;
  WHERE escrow_envelopes.escrow_id = p_program_escrow_id
  WHERE escrow_envelopes.escrow_id = v_env.escrow_id;
  WHERE instruction_id = NEW.reversal_of_instruction_id;
  WHERE instruction_id = p_instruction_id
  WHERE instruction_id = p_instruction_id
  WHERE instruction_id = p_instruction_id
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE m.tenant_id = p_tenant_id
  WHERE m.tenant_id = p_tenant_id
  WHERE m.tenant_id = p_tenant_id
  WHERE md.tenant_id = v_event.tenant_id
  WHERE member_id = NEW.member_id;
  WHERE o.operation_id = c.operation_id
  WHERE operation_id = p_operation_id
  WHERE operation_id = p_operation_id
  WHERE operation_id = v_op.operation_id;
  WHERE operation_id = v_op.operation_id;
  WHERE p.next_attempt_at <= NOW()
  WHERE policy_bundle_id = p_policy_bundle_id
  WHERE r.purge_request_id = p_purge_request_id;
  WHERE rf.formula_key = 'TIER1_DETERMINISTIC_DEFAULT'
  WHERE rf.formula_key = 'TIER1_DETERMINISTIC_DEFAULT'
  WHERE rf.formula_key = COALESCE(NULLIF(BTRIM(p_formula_key), ''), 'TIER1_DETERMINISTIC_DEFAULT')
  WHERE s->>'rail_id' IN (p_rail_id, '*')
  WHERE state IN ('ANCHORING', 'ANCHORED')
  WHERE status = 'PENDING_SUPERVISOR_APPROVAL'
  WHERE version_status = 'ACTIVE'
  WITH candidate AS (
  derived_billable_client_id UUID;
  derived_tenant_id UUID;
  m_tenant uuid;
  v := current_setting('app.current_tenant_id', true);
  v text;
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
  v_actor TEXT := COALESCE(NULLIF(BTRIM(p_actor_id), ''), 'system');
  v_actor TEXT := COALESCE(NULLIF(BTRIM(p_actor_id), ''), 'system');
  v_actor TEXT := COALESCE(NULLIF(BTRIM(p_migrated_by), ''), current_user);
  v_alert_id UUID;
  v_allowed boolean;
  v_amount BIGINT := COALESCE(p_amount_minor, 0);
  v_attempt integer := 0;
  v_attempts := v_attempts + 1;
  v_attempts INTEGER;
  v_candidate text;
  v_canon text;
  v_canonical_version text;
  v_capture := left(coalesce(p_payload, ''), v_limit);
  v_capture text;
  v_class public.orphan_classification_enum;
  v_collision boolean;
  v_computed_hash := public.compute_effect_seal_hash(p_instruction_id, p_outbound_payload, v_canonical_version);
  v_computed_hash text;
  v_count INTEGER := 0;
  v_count INTEGER := 0;
  v_count INTEGER := 0;
  v_decision TEXT := UPPER(BTRIM(COALESCE(p_decision, '')));
  v_env public.escrow_envelopes%ROWTYPE;
  v_escrow_id UUID;
  v_event public.member_device_events%ROWTYPE;
  v_event_id UUID;
  v_event_id UUID;
  v_event_id uuid;
  v_exists boolean;
  v_formula_version_id UUID;
  v_formula_version_id UUID;
  v_formula_version_id UUID;
  v_hash := public.compute_effect_seal_hash(p_instruction_id, p_payload, p_canonicalization_version);
  v_hash text;
  v_id uuid;
  v_id uuid;
  v_id uuid;
  v_id uuid;
  v_input := coalesce(p_instruction_id, '') || '|' || coalesce(p_canonicalization_version, '') || '|' || coalesce(p_payload::text, '{}');
  v_input text;
  v_legal := (
  v_legal BOOLEAN := FALSE;
  v_limit := greatest(1, p_truncate_kb) * 1024;
  v_limit integer;
  v_max INTEGER;
  v_new_member_id UUID;
  v_ok boolean;
  v_op public.anchor_sync_operations%ROWTYPE;
  v_op public.anchor_sync_operations%ROWTYPE;
  v_operation_id UUID;
  v_parent text;
  v_policy record;
  v_prior INTEGER := 0;
  v_prior_iccid_hash TEXT;
  v_profile := COALESCE(NULLIF(BTRIM(NEW.rail_type), ''), 'GENERIC');
  v_profile TEXT;
  v_program_id UUID;
  v_reason TEXT := COALESCE(NULLIF(BTRIM(p_reason), ''), 'program_migration');
  v_reason TEXT := NULLIF(BTRIM(COALESCE(p_reason, '')), '');
  v_recipient text;
  v_request_id UUID;
  v_reservation_escrow_id UUID;
  v_row public.escrow_accounts%ROWTYPE;
  v_rows INTEGER := 0;
  v_sequence_ref := NULLIF(BTRIM(NEW.rail_reference), '');
  v_sequence_ref TEXT;
  v_source_final BOOLEAN;
  v_source_member public.members%ROWTYPE;
  v_source_member public.members%ROWTYPE;
  v_source_state TEXT;
  v_state public.finality_resolution_state_enum := 'ACTIVE';
  v_state public.inquiry_state_enum;
  v_state public.inquiry_state_enum;
  v_state public.inquiry_state_enum;
  v_state text := 'ACTIVE';
  v_stored_hash text;
  v_strategy record;
  v_strategy record;
  v_subject_token TEXT;
  v_submitted_by TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_submitted_by, '')), ''), 'system');
  v_target_member_id UUID;
  v_timeout INTEGER := COALESCE(p_timeout_minutes, 30);
  v_timeout INTEGER := COALESCE(p_timeout_minutes, 30);
  v_to_state TEXT := UPPER(BTRIM(COALESCE(p_to_state, '')));
  v_total numeric;
  v_truncated := left(p_allocated_reference, v_strategy.max_length);
  v_truncated text;
  v_worker TEXT := NULLIF(BTRIM(p_worker_id), '');
 $$;
 )
 ),
 SELECT * FROM leased;
 SELECT m.entity_id AS program_id,
 SELECT tenant_id,
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
);
);
);
);
);
);
);
ALTER TABLE ONLY public.adapter_circuit_breakers
ALTER TABLE ONLY public.adjustment_approval_stages
ALTER TABLE ONLY public.adjustment_approval_stages
ALTER TABLE ONLY public.adjustment_approvals
ALTER TABLE ONLY public.adjustment_approvals
ALTER TABLE ONLY public.adjustment_approvals
ALTER TABLE ONLY public.adjustment_execution_attempts
ALTER TABLE ONLY public.adjustment_execution_attempts
ALTER TABLE ONLY public.adjustment_execution_attempts
ALTER TABLE ONLY public.adjustment_freeze_flags
ALTER TABLE ONLY public.adjustment_freeze_flags
ALTER TABLE ONLY public.adjustment_instructions
ALTER TABLE ONLY public.adjustment_instructions
ALTER TABLE ONLY public.anchor_sync_operations
ALTER TABLE ONLY public.anchor_sync_operations
ALTER TABLE ONLY public.anchor_sync_operations
ALTER TABLE ONLY public.billable_clients
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.dispatch_reference_collision_events
ALTER TABLE ONLY public.dispatch_reference_collision_events
ALTER TABLE ONLY public.dispatch_reference_registry
ALTER TABLE ONLY public.dispatch_reference_registry
ALTER TABLE ONLY public.dispatch_reference_registry
ALTER TABLE ONLY public.dispatch_reference_registry
ALTER TABLE ONLY public.dispatch_reference_registry
ALTER TABLE ONLY public.effect_seal_mismatch_events
ALTER TABLE ONLY public.escrow_accounts
ALTER TABLE ONLY public.escrow_accounts
ALTER TABLE ONLY public.escrow_accounts FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.escrow_envelopes
ALTER TABLE ONLY public.escrow_envelopes
ALTER TABLE ONLY public.escrow_envelopes
ALTER TABLE ONLY public.escrow_envelopes FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.escrow_events
ALTER TABLE ONLY public.escrow_events
ALTER TABLE ONLY public.escrow_events
ALTER TABLE ONLY public.escrow_events FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.escrow_reservations
ALTER TABLE ONLY public.escrow_reservations
ALTER TABLE ONLY public.escrow_reservations
ALTER TABLE ONLY public.escrow_reservations
ALTER TABLE ONLY public.escrow_reservations
ALTER TABLE ONLY public.escrow_reservations FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_packs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.historical_verification_runs
ALTER TABLE ONLY public.incident_events
ALTER TABLE ONLY public.incident_events
ALTER TABLE ONLY public.ingress_attestations
ALTER TABLE ONLY public.ingress_attestations
ALTER TABLE ONLY public.ingress_attestations
ALTER TABLE ONLY public.ingress_attestations FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.inquiry_state_machine
ALTER TABLE ONLY public.instruction_effect_seals
ALTER TABLE ONLY public.instruction_finality_conflicts
ALTER TABLE ONLY public.instruction_settlement_finality
ALTER TABLE ONLY public.instruction_settlement_finality
ALTER TABLE ONLY public.instruction_settlement_finality
ALTER TABLE ONLY public.key_rotation_drills
ALTER TABLE ONLY public.kyc_provider_registry
ALTER TABLE ONLY public.kyc_provider_registry
ALTER TABLE ONLY public.kyc_retention_policy
ALTER TABLE ONLY public.kyc_retention_policy
ALTER TABLE ONLY public.kyc_verification_records
ALTER TABLE ONLY public.kyc_verification_records
ALTER TABLE ONLY public.kyc_verification_records
ALTER TABLE ONLY public.levy_calculation_records
ALTER TABLE ONLY public.levy_calculation_records
ALTER TABLE ONLY public.levy_calculation_records
ALTER TABLE ONLY public.levy_calculation_records
ALTER TABLE ONLY public.levy_rates
ALTER TABLE ONLY public.levy_remittance_periods
ALTER TABLE ONLY public.levy_remittance_periods
ALTER TABLE ONLY public.malformed_quarantine_store
ALTER TABLE ONLY public.member_device_events
ALTER TABLE ONLY public.member_device_events
ALTER TABLE ONLY public.member_device_events
ALTER TABLE ONLY public.member_device_events FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.member_devices
ALTER TABLE ONLY public.member_devices
ALTER TABLE ONLY public.member_devices
ALTER TABLE ONLY public.member_devices FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.members
ALTER TABLE ONLY public.members
ALTER TABLE ONLY public.members
ALTER TABLE ONLY public.members
ALTER TABLE ONLY public.members
ALTER TABLE ONLY public.members
ALTER TABLE ONLY public.members
ALTER TABLE ONLY public.members FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.mmo_reality_control_events
ALTER TABLE ONLY public.offline_safe_mode_windows
ALTER TABLE ONLY public.orphaned_attestation_landing_zone
ALTER TABLE ONLY public.participant_outbox_sequences
ALTER TABLE ONLY public.participants
ALTER TABLE ONLY public.payment_outbox_attempts
ALTER TABLE ONLY public.payment_outbox_attempts
ALTER TABLE ONLY public.payment_outbox_attempts
ALTER TABLE ONLY public.payment_outbox_attempts
ALTER TABLE ONLY public.payment_outbox_attempts FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.payment_outbox_pending
ALTER TABLE ONLY public.payment_outbox_pending
ALTER TABLE ONLY public.payment_outbox_pending
ALTER TABLE ONLY public.payment_outbox_pending
ALTER TABLE ONLY public.payment_outbox_pending FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.persons
ALTER TABLE ONLY public.persons
ALTER TABLE ONLY public.persons FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.pii_purge_events
ALTER TABLE ONLY public.pii_purge_events
ALTER TABLE ONLY public.pii_purge_events
ALTER TABLE ONLY public.pii_purge_requests
ALTER TABLE ONLY public.pii_vault_records
ALTER TABLE ONLY public.pii_vault_records
ALTER TABLE ONLY public.pii_vault_records
ALTER TABLE ONLY public.policy_bundles
ALTER TABLE ONLY public.policy_bundles
ALTER TABLE ONLY public.policy_versions
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.rail_dispatch_truth_anchor
ALTER TABLE ONLY public.rail_dispatch_truth_anchor
ALTER TABLE ONLY public.rail_dispatch_truth_anchor
ALTER TABLE ONLY public.rail_dispatch_truth_anchor
ALTER TABLE ONLY public.reference_strategy_policy_versions
ALTER TABLE ONLY public.regulatory_incidents
ALTER TABLE ONLY public.regulatory_incidents
ALTER TABLE ONLY public.resign_sweeps
ALTER TABLE ONLY public.revoked_client_certs
ALTER TABLE ONLY public.revoked_tokens
ALTER TABLE ONLY public.risk_formula_versions
ALTER TABLE ONLY public.risk_formula_versions
ALTER TABLE ONLY public.schema_migrations
ALTER TABLE ONLY public.signing_audit_log
ALTER TABLE ONLY public.signing_authorization_matrix
ALTER TABLE ONLY public.signing_authorization_matrix
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.supervisor_access_policies
ALTER TABLE ONLY public.supervisor_approval_queue
ALTER TABLE ONLY public.supervisor_approval_queue
ALTER TABLE ONLY public.supervisor_audit_tokens
ALTER TABLE ONLY public.supervisor_audit_tokens
ALTER TABLE ONLY public.supervisor_audit_tokens
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_clients FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenant_members FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants FORCE ROW LEVEL SECURITY;
ALTER TABLE public.billable_clients
ALTER TABLE public.billing_usage_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_envelopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.external_proofs
ALTER TABLE public.external_proofs
ALTER TABLE public.external_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingress_attestations
ALTER TABLE public.ingress_attestations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.member_device_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.member_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_outbox_attempts
ALTER TABLE public.payment_outbox_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_outbox_pending
ALTER TABLE public.payment_outbox_pending ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_migration_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sim_swap_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
BEGIN
CREATE FUNCTION public.acknowledge_inquiry_response(p_instruction_id text, p_policy_version_id text) RETURNS public.inquiry_state_enum
CREATE FUNCTION public.activate_policy_bundle(p_policy_bundle_id uuid) RETURNS void
CREATE FUNCTION public.allocate_dispatch_reference(p_instruction_id uuid, p_adjustment_id uuid, p_parent_reference text, p_rail_id text) RETURNS TABLE(registry_id uuid, allocated_reference text, canonicalized_reference text, strategy_used public.reference_strategy_type_enum, policy_version_id text, collision_retry_count integer)
CREATE FUNCTION public.anchor_dispatched_outbox_attempt() RETURNS trigger
CREATE FUNCTION public.apply_finality_signals(p_instruction_id text, p_rail_a_id text, p_rail_a_status public.finality_signal_status_enum, p_rail_b_id text, p_rail_b_status public.finality_signal_status_enum) RETURNS public.finality_resolution_state_enum
CREATE FUNCTION public.apply_inquiry_attempt(p_instruction_id text, p_policy_version_id text, p_max_attempts integer) RETURNS public.inquiry_state_enum
CREATE FUNCTION public.assert_adjustment_execution_allowed(p_adjustment_id uuid, p_current_state public.adjustment_state_enum, p_freeze_flag_type text DEFAULT NULL::text) RETURNS void
CREATE FUNCTION public.assert_key_class_authorized(p_caller_id text, p_key_class public.key_class_enum) RETURNS void
CREATE FUNCTION public.assert_offline_safe_mode_dispatch_allowed(p_reason text, p_policy_version_id text, p_is_offline boolean) RETURNS void
CREATE FUNCTION public.assert_reference_registered(p_rail_id text, p_reference text, p_instruction_id uuid, p_adjustment_id uuid DEFAULT NULL::uuid) RETURNS void
CREATE FUNCTION public.authorize_escrow_reservation(p_program_escrow_id uuid, p_amount_minor bigint, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS uuid
CREATE FUNCTION public.block_active_reference_policy_updates() RETURNS trigger
CREATE FUNCTION public.bump_participant_outbox_seq(p_participant_id text) RETURNS bigint
CREATE FUNCTION public.canonicalize_reference_for_rail(p_allocated_reference text, p_rail_id text) RETURNS text
CREATE FUNCTION public.claim_anchor_sync_operation(p_worker_id text, p_lease_seconds integer DEFAULT 30) RETURNS TABLE(operation_id uuid, pack_id uuid, lease_token uuid, state text, attempt_count integer)
CREATE FUNCTION public.claim_outbox_batch(p_batch_size integer, p_worker_id text, p_lease_seconds integer) RETURNS TABLE(outbox_id uuid, instruction_id text, participant_id text, sequence_id bigint, idempotency_key text, rail_type text, payload jsonb, attempt_count integer, lease_token uuid, lease_expires_at timestamp with time zone)
CREATE FUNCTION public.classify_orphan_or_replay(p_instruction_id text, p_event_fingerprint text, p_is_late_callback boolean, p_is_duplicate_dispatch boolean, p_has_unknown_reference boolean, p_is_replay boolean) RETURNS public.orphan_classification_enum
CREATE FUNCTION public.complete_anchor_sync_operation(p_operation_id uuid, p_lease_token uuid, p_worker_id text) RETURNS void
CREATE FUNCTION public.complete_outbox_attempt(p_outbox_id uuid, p_lease_token uuid, p_worker_id text, p_state public.outbox_attempt_state, p_rail_reference text DEFAULT NULL::text, p_rail_code text DEFAULT NULL::text, p_error_code text DEFAULT NULL::text, p_error_message text DEFAULT NULL::text, p_latency_ms integer DEFAULT NULL::integer, p_retry_delay_seconds integer DEFAULT 1) RETURNS TABLE(attempt_no integer, state public.outbox_attempt_state)
CREATE FUNCTION public.compute_effect_seal_hash(p_instruction_id text, p_payload jsonb, p_canonicalization_version text) RETURNS text
CREATE FUNCTION public.current_tenant_id_or_null() RETURNS uuid
CREATE FUNCTION public.decide_supervisor_approval(p_instruction_id text, p_decision text, p_actor text, p_reason text DEFAULT NULL::text) RETURNS void
CREATE FUNCTION public.deny_append_only_mutation() RETURNS trigger
CREATE FUNCTION public.deny_final_instruction_mutation() RETURNS trigger
CREATE FUNCTION public.deny_ingress_attestations_mutation() RETURNS trigger
CREATE FUNCTION public.deny_member_device_events_mutation() RETURNS trigger
CREATE FUNCTION public.deny_outbox_attempts_mutation() RETURNS trigger
CREATE FUNCTION public.deny_pii_vault_mutation() RETURNS trigger
CREATE FUNCTION public.deny_revocation_mutation() RETURNS trigger
CREATE FUNCTION public.deny_sim_swap_alerts_mutation() RETURNS trigger
CREATE FUNCTION public.derive_sim_swap_alert(p_event_id uuid) RETURNS uuid
CREATE FUNCTION public.enforce_adjustment_terminal_immutability() RETURNS trigger
CREATE FUNCTION public.enforce_instruction_reversal_source() RETURNS trigger
CREATE FUNCTION public.enforce_member_tenant_match() RETURNS trigger
CREATE FUNCTION public.enqueue_payment_outbox(p_instruction_id text, p_participant_id text, p_idempotency_key text, p_rail_type text, p_payload jsonb) RETURNS TABLE(outbox_id uuid, sequence_id bigint, created_at timestamp with time zone, state text)
CREATE FUNCTION public.ensure_anchor_sync_operation(p_pack_id uuid, p_anchor_provider text DEFAULT 'GENERIC'::text) RETURNS uuid
CREATE FUNCTION public.evaluate_adjustment_ceiling(p_adjustment_id uuid, p_parent_instruction_value numeric) RETURNS void
CREATE FUNCTION public.evaluate_circuit_breaker(p_adapter_id text, p_rail_id text, p_trigger_threshold numeric, p_observed_rate numeric, p_window_seconds integer, p_policy_version_id text) RETURNS text
CREATE FUNCTION public.execute_pii_purge(p_purge_request_id uuid, p_executor text) RETURNS TABLE(purge_request_id uuid, rows_affected integer, already_purged boolean)
CREATE FUNCTION public.expire_escrows(p_now timestamp with time zone DEFAULT now(), p_actor_id text DEFAULT 'escrow_expiry_worker'::text) RETURNS integer
CREATE FUNCTION public.expire_supervisor_approvals(p_now timestamp with time zone DEFAULT now()) RETURNS integer
CREATE FUNCTION public.guard_auto_finalize_when_inquiry_exhausted(p_instruction_id text) RETURNS void
CREATE FUNCTION public.issue_adjustment(p_parent_instruction_id text, p_adjustment_type text, p_adjustment_value numeric, p_policy_version_id text, p_justification text DEFAULT NULL::text) RETURNS uuid
CREATE FUNCTION public.issue_adjustment_with_recipient(p_parent_instruction_id text, p_recipient text) RETURNS uuid
CREATE FUNCTION public.mark_anchor_sync_anchored(p_operation_id uuid, p_lease_token uuid, p_worker_id text, p_anchor_ref text, p_anchor_type text DEFAULT 'HYBRID_SYNC'::text) RETURNS void
CREATE FUNCTION public.migrate_person_to_program(p_tenant_id uuid, p_person_id uuid, p_from_program_id uuid, p_to_program_id uuid, p_migrated_by text DEFAULT CURRENT_USER, p_reason text DEFAULT 'program_migration'::text, p_formula_key text DEFAULT 'TIER1_DETERMINISTIC_DEFAULT'::text) RETURNS uuid
CREATE FUNCTION public.migrate_person_to_program(p_tenant_id uuid, p_person_id uuid, p_from_program_id uuid, p_to_program_id uuid, p_new_entity_id uuid, p_reason text DEFAULT NULL::text) RETURNS uuid
CREATE FUNCTION public.outbox_retry_ceiling() RETURNS integer
CREATE FUNCTION public.quarantine_malformed_response(p_adapter_id text, p_rail_id text, p_classification public.quarantine_classification_enum, p_payload text, p_truncate_kb integer, p_policy_version_id text) RETURNS uuid
CREATE FUNCTION public.record_late_callback(p_instruction_id text, p_payload jsonb, p_state_at_arrival text, p_fingerprint text) RETURNS uuid
CREATE FUNCTION public.record_mmo_reality_control(p_instruction_id text, p_scenario_type text, p_fallback_posture text, p_policy_version_id text, p_behavior_profile text, p_evidence_artifact_type text) RETURNS uuid
CREATE FUNCTION public.release_escrow(p_escrow_id uuid, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS uuid
CREATE FUNCTION public.repair_expired_anchor_sync_leases(p_worker_id text DEFAULT 'anchor_repair'::text) RETURNS integer
CREATE FUNCTION public.repair_expired_leases(p_batch_size integer, p_worker_id text) RETURNS TABLE(outbox_id uuid, attempt_no integer)
CREATE FUNCTION public.request_pii_purge(p_subject_token text, p_requested_by text, p_request_reason text) RETURNS uuid
CREATE FUNCTION public.resolve_reference_strategy(p_rail_id text) RETURNS TABLE(strategy_type public.reference_strategy_type_enum, rail_id text, max_length integer, nonce_retry_limit integer, collision_action text, policy_version_id text)
CREATE FUNCTION public.set_correlation_id_if_null() RETURNS trigger
CREATE FUNCTION public.set_external_proofs_attribution() RETURNS trigger
CREATE FUNCTION public.sign_digest_hsm_enforced(p_caller_id text, p_key_id text, p_key_class public.key_class_enum, p_artifact_type text, p_digest_hash text, p_signing_path text DEFAULT 'HSM'::text, p_assurance_tier text DEFAULT 'HSM_BACKED'::text) RETURNS uuid
CREATE FUNCTION public.store_effect_seal(p_instruction_id text, p_payload jsonb, p_canonicalization_version text, p_policy_version_id text) RETURNS text
CREATE FUNCTION public.submit_for_supervisor_approval(p_instruction_id text) RETURNS void
CREATE FUNCTION public.submit_for_supervisor_approval(p_instruction_id text, p_program_id uuid, p_timeout_minutes integer DEFAULT 30) RETURNS void
CREATE FUNCTION public.submit_for_supervisor_approval(p_instruction_id text, p_program_id uuid, p_timeout_minutes integer DEFAULT 30, p_held_reason text DEFAULT NULL::text, p_submitted_by text DEFAULT NULL::text) RETURNS void
CREATE FUNCTION public.touch_anchor_sync_updated_at() RETURNS trigger
CREATE FUNCTION public.touch_escrow_envelopes_updated_at() RETURNS trigger
CREATE FUNCTION public.touch_escrow_updated_at() RETURNS trigger
CREATE FUNCTION public.touch_inquiry_state_updated_at() RETURNS trigger
CREATE FUNCTION public.touch_members_updated_at() RETURNS trigger
CREATE FUNCTION public.touch_persons_updated_at() RETURNS trigger
CREATE FUNCTION public.touch_programs_updated_at() RETURNS trigger
CREATE FUNCTION public.transition_escrow_state(p_escrow_id uuid, p_to_state text, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb, p_now timestamp with time zone DEFAULT now()) RETURNS TABLE(escrow_id uuid, previous_state text, new_state text, event_id uuid)
CREATE FUNCTION public.uuid_strategy() RETURNS text
CREATE FUNCTION public.uuid_v7_or_random() RETURNS uuid
CREATE FUNCTION public.verify_dispatch_effect_seal(p_instruction_id text, p_outbound_payload jsonb) RETURNS void
CREATE FUNCTION public.verify_instruction_hierarchy(p_instruction_id text, p_tenant_id uuid, p_participant_id text, p_program_id uuid, p_entity_id uuid, p_member_id uuid, p_device_id text) RETURNS boolean
CREATE FUNCTION public.verify_policy_bundle_runtime(p_policy_bundle_id uuid) RETURNS void
CREATE INDEX idx_anchor_sync_operations_state_due ON public.anchor_sync_operations USING btree (state, lease_expires_at, updated_at);
CREATE INDEX idx_attempts_instruction_idempotency ON public.payment_outbox_attempts USING btree (instruction_id, idempotency_key);
CREATE INDEX idx_attempts_outbox_id ON public.payment_outbox_attempts USING btree (outbox_id);
CREATE INDEX idx_billing_usage_events_correlation_id ON public.billing_usage_events USING btree (correlation_id);
CREATE INDEX idx_dispatch_reference_collision_events_instruction ON public.dispatch_reference_collision_events USING btree (instruction_id, created_at DESC);
CREATE INDEX idx_dispatch_reference_registry_adjustment ON public.dispatch_reference_registry USING btree (adjustment_id, allocation_timestamp DESC);
CREATE INDEX idx_dispatch_reference_registry_instruction ON public.dispatch_reference_registry USING btree (instruction_id, allocation_timestamp DESC);
CREATE INDEX idx_escrow_accounts_program ON public.escrow_accounts USING btree (program_id) WHERE (program_id IS NOT NULL);
CREATE INDEX idx_escrow_accounts_tenant_state ON public.escrow_accounts USING btree (tenant_id, state, authorization_expires_at, release_due_at);
CREATE INDEX idx_escrow_envelopes_tenant ON public.escrow_envelopes USING btree (tenant_id);
CREATE INDEX idx_escrow_events_escrow_created ON public.escrow_events USING btree (escrow_id, created_at);
CREATE INDEX idx_escrow_reservations_tenant_program ON public.escrow_reservations USING btree (tenant_id, program_escrow_id, created_at);
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
CREATE INDEX idx_instruction_settlement_finality_participant_finalized ON public.instruction_settlement_finality USING btree (participant_id, finalized_at DESC);
CREATE INDEX idx_malformed_quarantine_adapter_rail_time ON public.malformed_quarantine_store USING btree (adapter_id, rail_id, capture_timestamp DESC);
CREATE INDEX idx_member_device_events_instruction ON public.member_device_events USING btree (instruction_id);
CREATE INDEX idx_member_device_events_tenant_member_observed ON public.member_device_events USING btree (tenant_id, member_id, observed_at DESC);
CREATE INDEX idx_member_devices_active_device ON public.member_devices USING btree (tenant_id, device_id_hash) WHERE (status = 'ACTIVE'::text);
CREATE INDEX idx_member_devices_active_iccid ON public.member_devices USING btree (tenant_id, iccid_hash) WHERE ((iccid_hash IS NOT NULL) AND (status = 'ACTIVE'::text));
CREATE INDEX idx_member_devices_tenant_member ON public.member_devices USING btree (tenant_id, member_id);
CREATE INDEX idx_members_entity_active ON public.members USING btree (tenant_id, entity_id, status) WHERE (status = 'ACTIVE'::text);
CREATE INDEX idx_members_entity_member_ref_active ON public.members USING btree (tenant_id, entity_id, member_ref_hash) WHERE (status = 'ACTIVE'::text);
CREATE INDEX idx_members_tenant_member ON public.members USING btree (tenant_id, member_id);
CREATE INDEX idx_members_tenant_member_ref ON public.members USING btree (tenant_id, member_ref_hash);
CREATE INDEX idx_orphan_lz_instruction_arrival ON public.orphaned_attestation_landing_zone USING btree (instruction_id, arrival_timestamp DESC);
CREATE INDEX idx_payment_outbox_attempts_correlation_id ON public.payment_outbox_attempts USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_attempts_tenant_correlation ON public.payment_outbox_attempts USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_pending_correlation_id ON public.payment_outbox_pending USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_pending_due_claim ON public.payment_outbox_pending USING btree (next_attempt_at, lease_expires_at, created_at);
CREATE INDEX idx_payment_outbox_pending_tenant_correlation ON public.payment_outbox_pending USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_payment_outbox_pending_tenant_due ON public.payment_outbox_pending USING btree (tenant_id, next_attempt_at) WHERE (tenant_id IS NOT NULL);
CREATE INDEX idx_pii_purge_requests_subject_requested ON public.pii_purge_requests USING btree (subject_token, requested_at DESC);
CREATE INDEX idx_policy_versions_is_active ON public.policy_versions USING btree (is_active) WHERE (is_active = true);
CREATE INDEX idx_program_migration_events_tenant_person ON public.program_migration_events USING btree (tenant_id, person_id, migrated_at DESC);
CREATE INDEX idx_program_migration_events_tenant_time ON public.program_migration_events USING btree (tenant_id, migrated_at DESC);
CREATE INDEX idx_programs_tenant_status ON public.programs USING btree (tenant_id, status);
CREATE INDEX idx_rail_truth_anchor_participant_anchored ON public.rail_dispatch_truth_anchor USING btree (rail_participant_id, anchored_at DESC);
CREATE INDEX idx_sim_swap_alerts_tenant_member_derived ON public.sim_swap_alerts USING btree (tenant_id, member_id, derived_at DESC);
CREATE INDEX idx_supervisor_approval_queue_status_timeout ON public.supervisor_approval_queue USING btree (status, timeout_at);
CREATE INDEX idx_supervisor_audit_tokens_program_expires ON public.supervisor_audit_tokens USING btree (program_id, expires_at DESC);
CREATE INDEX idx_tenant_clients_tenant ON public.tenant_clients USING btree (tenant_id);
CREATE INDEX idx_tenant_members_status ON public.tenant_members USING btree (status);
CREATE INDEX idx_tenant_members_tenant ON public.tenant_members USING btree (tenant_id);
CREATE INDEX idx_tenants_billable_client_id ON public.tenants USING btree (billable_client_id);
CREATE INDEX idx_tenants_parent_tenant_id ON public.tenants USING btree (parent_tenant_id);
CREATE INDEX idx_tenants_status ON public.tenants USING btree (status);
CREATE INDEX ix_incident_events_incident_created ON public.incident_events USING btree (incident_id, created_at);
CREATE INDEX ix_regulatory_incidents_tenant_detected ON public.regulatory_incidents USING btree (tenant_id, detected_at DESC);
CREATE INDEX kyc_provider_jurisdiction_idx ON public.kyc_provider_registry USING btree (jurisdiction_code, active_from DESC);
CREATE INDEX kyc_verification_jurisdiction_outcome_idx ON public.kyc_verification_records USING btree (jurisdiction_code, outcome) WHERE (outcome IS NOT NULL);
CREATE INDEX kyc_verification_member_idx ON public.kyc_verification_records USING btree (member_id, anchored_at DESC);
CREATE INDEX kyc_verification_provider_idx ON public.kyc_verification_records USING btree (provider_id) WHERE (provider_id IS NOT NULL);
CREATE INDEX levy_calc_reporting_period_idx ON public.levy_calculation_records USING btree (reporting_period, jurisdiction_code) WHERE (reporting_period IS NOT NULL);
CREATE INDEX levy_calc_status_idx ON public.levy_calculation_records USING btree (levy_status) WHERE (levy_status IS NOT NULL);
CREATE INDEX levy_periods_jurisdiction_idx ON public.levy_remittance_periods USING btree (jurisdiction_code, period_start DESC);
CREATE INDEX levy_periods_status_idx ON public.levy_remittance_periods USING btree (period_status) WHERE (period_status IS NOT NULL);
CREATE INDEX levy_rates_jurisdiction_date_idx ON public.levy_rates USING btree (jurisdiction_code, effective_from DESC);
CREATE POLICY rls_tenant_isolation_billing_usage_events ON public.billing_usage_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_escrow_accounts ON public.escrow_accounts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_escrow_envelopes ON public.escrow_envelopes AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_escrow_events ON public.escrow_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_escrow_reservations ON public.escrow_reservations AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_external_proofs ON public.external_proofs AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_ingress_attestations ON public.ingress_attestations AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_member_device_events ON public.member_device_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_member_devices ON public.member_devices AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_members ON public.members AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_payment_outbox_attempts ON public.payment_outbox_attempts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_payment_outbox_pending ON public.payment_outbox_pending AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_persons ON public.persons AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_program_migration_events ON public.program_migration_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_programs ON public.programs AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_sim_swap_alerts ON public.sim_swap_alerts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_tenant_clients ON public.tenant_clients AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_tenant_members ON public.tenant_members AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_tenants ON public.tenants AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE RULE kyc_retention_policy_no_delete AS
CREATE RULE kyc_retention_policy_no_update AS
CREATE SCHEMA public;
CREATE TABLE public.adapter_circuit_breakers (
CREATE TABLE public.adjustment_approval_stages (
CREATE TABLE public.adjustment_approvals (
CREATE TABLE public.adjustment_execution_attempts (
CREATE TABLE public.adjustment_freeze_flags (
CREATE TABLE public.adjustment_instructions (
CREATE TABLE public.anchor_sync_operations (
CREATE TABLE public.billable_clients (
CREATE TABLE public.billing_usage_events (
CREATE TABLE public.dispatch_reference_collision_events (
CREATE TABLE public.dispatch_reference_registry (
CREATE TABLE public.effect_seal_mismatch_events (
CREATE TABLE public.escrow_accounts (
CREATE TABLE public.escrow_envelopes (
CREATE TABLE public.escrow_events (
CREATE TABLE public.escrow_reservations (
CREATE TABLE public.evidence_pack_items (
CREATE TABLE public.evidence_packs (
CREATE TABLE public.external_proofs (
CREATE TABLE public.historical_verification_runs (
CREATE TABLE public.incident_events (
CREATE TABLE public.ingress_attestations (
CREATE TABLE public.inquiry_state_machine (
CREATE TABLE public.instruction_effect_seals (
CREATE TABLE public.instruction_finality_conflicts (
CREATE TABLE public.instruction_settlement_finality (
CREATE TABLE public.key_rotation_drills (
CREATE TABLE public.kyc_provider_registry (
CREATE TABLE public.kyc_retention_policy (
CREATE TABLE public.kyc_verification_records (
CREATE TABLE public.levy_calculation_records (
CREATE TABLE public.levy_rates (
CREATE TABLE public.levy_remittance_periods (
CREATE TABLE public.malformed_quarantine_store (
CREATE TABLE public.member_device_events (
CREATE TABLE public.member_devices (
CREATE TABLE public.members (
CREATE TABLE public.mmo_reality_control_events (
CREATE TABLE public.offline_safe_mode_windows (
CREATE TABLE public.orphaned_attestation_landing_zone (
CREATE TABLE public.participant_outbox_sequences (
CREATE TABLE public.participants (
CREATE TABLE public.payment_outbox_attempts (
CREATE TABLE public.payment_outbox_pending (
CREATE TABLE public.persons (
CREATE TABLE public.pii_purge_events (
CREATE TABLE public.pii_purge_requests (
CREATE TABLE public.pii_vault_records (
CREATE TABLE public.policy_bundles (
CREATE TABLE public.policy_versions (
CREATE TABLE public.program_migration_events (
CREATE TABLE public.programs (
CREATE TABLE public.rail_dispatch_truth_anchor (
CREATE TABLE public.reference_strategy_policy_versions (
CREATE TABLE public.regulatory_incidents (
CREATE TABLE public.resign_sweeps (
CREATE TABLE public.revoked_client_certs (
CREATE TABLE public.revoked_tokens (
CREATE TABLE public.risk_formula_versions (
CREATE TABLE public.schema_migrations (
CREATE TABLE public.signing_audit_log (
CREATE TABLE public.signing_authorization_matrix (
CREATE TABLE public.sim_swap_alerts (
CREATE TABLE public.supervisor_access_policies (
CREATE TABLE public.supervisor_approval_queue (
CREATE TABLE public.supervisor_audit_tokens (
CREATE TABLE public.tenant_clients (
CREATE TABLE public.tenant_members (
CREATE TABLE public.tenants (
CREATE TRIGGER trg_adjustment_terminal_immutability BEFORE UPDATE ON public.adjustment_instructions FOR EACH ROW EXECUTE FUNCTION public.enforce_adjustment_terminal_immutability();
CREATE TRIGGER trg_anchor_dispatched_outbox_attempt AFTER INSERT ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.anchor_dispatched_outbox_attempt();
CREATE TRIGGER trg_block_active_reference_policy_updates BEFORE UPDATE ON public.reference_strategy_policy_versions FOR EACH ROW EXECUTE FUNCTION public.block_active_reference_policy_updates();
CREATE TRIGGER trg_deny_billing_usage_events_mutation BEFORE DELETE OR UPDATE ON public.billing_usage_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_escrow_events_mutation BEFORE DELETE OR UPDATE ON public.escrow_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_evidence_pack_items_mutation BEFORE DELETE OR UPDATE ON public.evidence_pack_items FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_evidence_packs_mutation BEFORE DELETE OR UPDATE ON public.evidence_packs FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_external_proofs_mutation BEFORE DELETE OR UPDATE ON public.external_proofs FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_final_instruction_mutation BEFORE DELETE OR UPDATE ON public.instruction_settlement_finality FOR EACH ROW EXECUTE FUNCTION public.deny_final_instruction_mutation();
CREATE TRIGGER trg_deny_ingress_attestations_mutation BEFORE DELETE OR UPDATE ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.deny_ingress_attestations_mutation();
CREATE TRIGGER trg_deny_member_device_events_mutation BEFORE DELETE OR UPDATE ON public.member_device_events FOR EACH ROW EXECUTE FUNCTION public.deny_member_device_events_mutation();
CREATE TRIGGER trg_deny_outbox_attempts_mutation BEFORE DELETE OR UPDATE ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.deny_outbox_attempts_mutation();
CREATE TRIGGER trg_deny_pii_purge_events_mutation BEFORE DELETE OR UPDATE ON public.pii_purge_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_pii_purge_requests_mutation BEFORE DELETE OR UPDATE ON public.pii_purge_requests FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_pii_vault_mutation BEFORE DELETE OR UPDATE ON public.pii_vault_records FOR EACH ROW EXECUTE FUNCTION public.deny_pii_vault_mutation();
CREATE TRIGGER trg_deny_rail_dispatch_truth_anchor_mutation BEFORE DELETE OR UPDATE ON public.rail_dispatch_truth_anchor FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_revoked_client_certs_mutation BEFORE DELETE OR UPDATE ON public.revoked_client_certs FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();
CREATE TRIGGER trg_deny_revoked_tokens_mutation BEFORE DELETE OR UPDATE ON public.revoked_tokens FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();
CREATE TRIGGER trg_deny_sim_swap_alerts_mutation BEFORE DELETE OR UPDATE ON public.sim_swap_alerts FOR EACH ROW EXECUTE FUNCTION public.deny_sim_swap_alerts_mutation();
CREATE TRIGGER trg_enforce_instruction_reversal_source BEFORE INSERT ON public.instruction_settlement_finality FOR EACH ROW EXECUTE FUNCTION public.enforce_instruction_reversal_source();
CREATE TRIGGER trg_ingress_member_tenant_match BEFORE INSERT ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.enforce_member_tenant_match();
CREATE TRIGGER trg_set_corr_id_ingress_attestations BEFORE INSERT ON public.ingress_attestations FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();
CREATE TRIGGER trg_set_corr_id_payment_outbox_attempts BEFORE INSERT ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();
CREATE TRIGGER trg_set_corr_id_payment_outbox_pending BEFORE INSERT ON public.payment_outbox_pending FOR EACH ROW EXECUTE FUNCTION public.set_correlation_id_if_null();
CREATE TRIGGER trg_set_external_proofs_attribution BEFORE INSERT ON public.external_proofs FOR EACH ROW EXECUTE FUNCTION public.set_external_proofs_attribution();
CREATE TRIGGER trg_touch_anchor_sync_updated_at BEFORE UPDATE ON public.anchor_sync_operations FOR EACH ROW EXECUTE FUNCTION public.touch_anchor_sync_updated_at();
CREATE TRIGGER trg_touch_escrow_envelopes_updated_at BEFORE UPDATE ON public.escrow_envelopes FOR EACH ROW EXECUTE FUNCTION public.touch_escrow_envelopes_updated_at();
CREATE TRIGGER trg_touch_escrow_updated_at BEFORE UPDATE ON public.escrow_accounts FOR EACH ROW EXECUTE FUNCTION public.touch_escrow_updated_at();
CREATE TRIGGER trg_touch_inquiry_state_machine_updated_at BEFORE UPDATE ON public.inquiry_state_machine FOR EACH ROW EXECUTE FUNCTION public.touch_inquiry_state_updated_at();
CREATE TRIGGER trg_touch_members_updated_at BEFORE INSERT OR UPDATE ON public.members FOR EACH ROW EXECUTE FUNCTION public.touch_members_updated_at();
CREATE TRIGGER trg_touch_persons_updated_at BEFORE UPDATE ON public.persons FOR EACH ROW EXECUTE FUNCTION public.touch_persons_updated_at();
CREATE TRIGGER trg_touch_programs_updated_at BEFORE UPDATE ON public.programs FOR EACH ROW EXECUTE FUNCTION public.touch_programs_updated_at();
CREATE TYPE public.adjustment_state_enum AS ENUM (
CREATE TYPE public.finality_resolution_state_enum AS ENUM (
CREATE TYPE public.finality_signal_status_enum AS ENUM (
CREATE TYPE public.inquiry_state_enum AS ENUM (
CREATE TYPE public.key_class_enum AS ENUM (
CREATE TYPE public.orphan_classification_enum AS ENUM (
CREATE TYPE public.outbox_attempt_state AS ENUM (
CREATE TYPE public.policy_bundle_state_enum AS ENUM (
CREATE TYPE public.policy_version_status AS ENUM (
CREATE TYPE public.quarantine_classification_enum AS ENUM (
CREATE TYPE public.reference_strategy_type_enum AS ENUM (
CREATE UNIQUE INDEX idx_persons_tenant_ref ON public.persons USING btree (tenant_id, person_ref_hash);
CREATE UNIQUE INDEX idx_reference_strategy_policy_active ON public.reference_strategy_policy_versions USING btree (version_status) WHERE (version_status = 'ACTIVE'::text);
CREATE UNIQUE INDEX kyc_provider_active_idx ON public.kyc_provider_registry USING btree (jurisdiction_code, provider_code) WHERE ((active_to IS NULL) AND (is_active IS NOT FALSE));
CREATE UNIQUE INDEX levy_rates_one_active_per_jurisdiction ON public.levy_rates USING btree (jurisdiction_code) WHERE (effective_to IS NULL);
CREATE UNIQUE INDEX ux_billable_clients_client_key ON public.billable_clients USING btree (client_key) WHERE (client_key IS NOT NULL);
CREATE UNIQUE INDEX ux_billing_usage_events_idempotency ON public.billing_usage_events USING btree (billable_client_id, idempotency_key) WHERE (idempotency_key IS NOT NULL);
CREATE UNIQUE INDEX ux_ingress_attestations_tenant_instruction ON public.ingress_attestations USING btree (tenant_id, instruction_id);
CREATE UNIQUE INDEX ux_instruction_settlement_finality_one_reversal_per_original ON public.instruction_settlement_finality USING btree (reversal_of_instruction_id) WHERE (reversal_of_instruction_id IS NOT NULL);
CREATE UNIQUE INDEX ux_outbox_attempts_one_terminal_per_outbox ON public.payment_outbox_attempts USING btree (outbox_id) WHERE (state = ANY (ARRAY['DISPATCHED'::public.outbox_attempt_state, 'FAILED'::public.outbox_attempt_state]));
CREATE UNIQUE INDEX ux_policy_versions_single_active ON public.policy_versions USING btree ((1)) WHERE (status = 'ACTIVE'::public.policy_version_status);
CREATE UNIQUE INDEX ux_program_migration_events_deterministic ON public.program_migration_events USING btree (tenant_id, person_id, from_program_id, to_program_id);
CREATE VIEW public.supervisor_audit_member_device_events AS
CREATE VIEW public.tenant_program_year_unique_beneficiaries AS
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
DECLARE
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
END;
WITH (fillfactor='80');
WITH due AS (
