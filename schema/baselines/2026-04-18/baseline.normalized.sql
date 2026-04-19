                              THEN 'RETIRED' ELSE 'ISSUED' END,
                         p_evidence_class, v_valid_classes
                         v_project_status
                         v_unsatisfied_checkpoints
                        (v_confidence >= v_threshold AND v_approved > 0);
                   (ad.decision_payload_json->>'confidence_score')::NUMERIC
                'Regulation 26 violation: validator cannot verify the same project (verifier_id=%, project_id=%)',
                NEW.audit_grade := true;
                NEW.authority_explanation := 'Execution binding with signature';
                NEW.authority_explanation := 'Execution binding without signature';
                NEW.data_authority := 'authoritative_signed';
                NEW.data_authority := 'policy_bound_unsigned';
                USING ERRCODE = 'GF001';
                USING ERRCODE = 'GF001';
                USING ERRCODE = 'GF003';
                USING ERRCODE = 'GF010';
                USING ERRCODE = 'GF011';
                USING ERRCODE = 'GF011';
                USING ERRCODE = 'GF012';
                USING ERRCODE = 'GF012';
                USING ERRCODE = 'GF012';
                USING ERRCODE = 'GF015';
                p_verifier_id, p_project_id
                v_unsatisfied_checkpoints
               ),
               0
               0
               AND ab.project_id = p_project_id
               AND ab.tenant_id = p_tenant_id
               AND en.tenant_id = p_tenant_id
               AND mr.project_id = p_project_id
               AND mr.tenant_id = p_tenant_id
               AVG(
               AVG((ad.decision_payload_json->>'confidence_score')::NUMERIC),
               WHERE (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
               WHERE (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
              AND assigned_role = 'VALIDATOR'
              AND project_id = p_project_id
              ab.quantity, ab.status, ab.created_at;
             ON ee.source_node_id = en.evidence_node_id
             WHERE ab.asset_batch_id = p_target_record_id
             WHERE en.evidence_node_id = p_target_record_id
             WHERE mr.monitoring_record_id = p_target_record_id
             WHERE project_id = p_target_record_id AND tenant_id = p_tenant_id
             p.idempotency_key, p.rail_type, p.payload
            'adapter_registration_id', p_adapter_registration_id,
            'adapter_registration_id', v_adapter_registration_id,
            'asset_type', p_asset_type,
            'decision_outcome', p_decision_outcome,
            'from_status',      p_from_status,
            'from_status', 'ACTIVE',
            'from_status', 'ISSUED',
            'interpretation_pack_id', p_interpretation_pack_id
            'interpretation_pack_id', p_interpretation_pack_id,
            'jurisdiction_code', p_jurisdiction_code
            'metadata', p_metadata_json
            'methodology_version_id', p_methodology_version_id,
            'methodology_version_id', p_methodology_version_id,
            'quantity', p_quantity,
            'remaining_quantity', v_remaining_quantity - v_retire_qty,
            'retired_quantity', v_retire_qty,
            'retirement_reason', p_retirement_reason,
            'subject_id',       p_subject_id,
            'subject_type',     p_subject_type,
            'to_status',        p_to_status
            'to_status', 'ISSUED',
            'to_status', CASE WHEN (v_total_retired + v_retire_qty) >= v_batch_quantity
            'unit', p_unit,
            (NEW.data_authority = 'invalidated')
            (NEW.data_authority = 'invalidated')
            (NEW.data_authority = 'invalidated')
            (OLD.data_authority = 'authoritative_signed' AND NEW.data_authority = 'superseded') OR
            (OLD.data_authority = 'authoritative_signed' AND NEW.data_authority = 'superseded') OR
            (OLD.data_authority = 'authoritative_signed' AND NEW.data_authority = 'superseded') OR
            (OLD.data_authority = 'derived_unverified' AND NEW.data_authority IN ('policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'derived_unverified' AND NEW.data_authority IN ('policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'derived_unverified' AND NEW.data_authority IN ('policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'non_reproducible' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'non_reproducible' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'non_reproducible' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'phase1_indicative_only' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'phase1_indicative_only' AND NEW.data_authority IN ('derived_unverified', 'policy_bound_unsigned', 'authoritative_signed')) OR
            (OLD.data_authority = 'policy_bound_unsigned' AND NEW.data_authority = 'authoritative_signed') OR
            (OLD.data_authority = 'policy_bound_unsigned' AND NEW.data_authority = 'authoritative_signed') OR
            (OLD.data_authority = 'policy_bound_unsigned' AND NEW.data_authority = 'authoritative_signed') OR
            AND ee.tenant_id      = en.tenant_id
            ELSE
            END IF;
            IF NEW.signature IS NOT NULL THEN
            NEW.asset_batch_id
            NEW.asset_batch_id
            NULL;
            OR (ad.decision_payload_json->>'subject_id')::UUID = p_subject_id)
            RAISE EXCEPTION
            RAISE EXCEPTION 'GF037: Invalid data_authority transition from % to %', OLD.data_authority, NEW.data_authority;
            RAISE EXCEPTION 'GF037: Invalid data_authority transition from % to %', OLD.data_authority, NEW.data_authority;
            RAISE EXCEPTION 'GF037: Invalid data_authority transition from % to %', OLD.data_authority, NEW.data_authority;
            RAISE EXCEPTION 'Issuance blocked: % unsatisfied REQUIRED checkpoints for ACTIVE->ISSUED transition',
            RAISE EXCEPTION 'UPDATE not allowed on immutable columns of gf_verifier_read_tokens'
            RAISE EXCEPTION 'interpretation_pack_id not found or jurisdiction mismatch'
            RAISE EXCEPTION 'methodology_version_id does not match an active version'
            RAISE EXCEPTION 'payload_schema_reference_id not found in schema_registry'
            RAISE EXCEPTION 'record_payload_json must be a JSON object'
            RAISE EXCEPTION 'target ASSET_BATCH not found for project/tenant'
            RAISE EXCEPTION 'target EVIDENCE_NODE not found for tenant'
            RAISE EXCEPTION 'target MONITORING_RECORD not found for project/tenant'
            RAISE EXCEPTION 'target PROJECT not found for tenant' USING ERRCODE = 'GF009';
            SELECT 1 FROM public.asset_batches ab
            SELECT 1 FROM public.evidence_nodes en
            SELECT 1 FROM public.monitoring_records mr
            SELECT 1 FROM public.projects
            SELECT 1 FROM public.verifier_project_assignments
            USING ERRCODE = 'GF001';
            USING ERRCODE = 'GF001';
            USING ERRCODE = 'GF001';
            USING ERRCODE = 'GF005';
            USING ERRCODE = 'GF007';
            USING ERRCODE = 'GF008';
            USING ERRCODE = 'GF009';
            USING ERRCODE = 'GF009';
            USING ERRCODE = 'GF009';
            USING ERRCODE = 'GF010';
            USING ERRCODE = 'GF014';
            USING ERRCODE = 'GF016';
            USING ERRCODE = 'GF016';
            USING ERRCODE = 'GF017';
            USING ERRCODE = 'GF018';
            USING ERRCODE = 'GF019';
            USING ERRCODE = 'GF019';
            USING ERRCODE = 'GF020';
            USING ERRCODE = 'GF021';
            USING ERRCODE = 'GF022';
            USING ERRCODE = 'P0001';
            USING ERRCODE = 'P0001';
            USING ERRCODE = 'P0001';
            USING ERRCODE = 'P0001';
            WHERE verifier_id = p_verifier_id
            v_required_threshold, v_confidence_score, NEW.asset_batch_id
            v_retire_qty, v_remaining_quantity
           (ad.decision_payload_json->>'decision_outcome')::TEXT,
           (ad.decision_payload_json->>'from_status')::TEXT,
           (ad.decision_payload_json->>'subject_id')::TEXT,
           (ad.decision_payload_json->>'subject_type')::TEXT,
           (ad.decision_payload_json->>'to_status')::TEXT,
           (t.revoked_at IS NULL AND t.expires_at > now()) AS is_valid
           )
           )
           )
           )
           AND ab.tenant_id  = p_tenant_id
           AND lcr.rule_type = 'CONDITIONALLY_REQUIRED';
           AND lcr.rule_type = 'CONDITIONALLY_REQUIRED';
           AND lcr.rule_type = 'REQUIRED';
           AND lcr.rule_type = 'REQUIRED';
           AND mv.status = 'ACTIVE'
           AND mv.tenant_id = p_tenant_id
           AND tenant_id = p_tenant_id;
           COALESCE(SUM(re.retired_quantity), 0) AS total_retired,
           COALESCE(SUM(re.retired_quantity), 0) AS total_retired,
           COUNT(*) FILTER (
           COUNT(*) FILTER (
           OR OLD.expires_at != NEW.expires_at
           OR OLD.project_id != NEW.project_id
           OR OLD.tenant_id != NEW.tenant_id
           OR OLD.verifier_id != NEW.verifier_id
           SET status = 'RETIRED'
           ab.created_at
           ab.created_at
           ab.quantity - COALESCE(SUM(re.retired_quantity), 0) AS remaining_quantity,
           ab.quantity - COALESCE(SUM(re.retired_quantity), 0) AS remaining_quantity,
           ab.quantity, ab.status,
           ad.created_at
           ad.decision_type,
           ad.regulatory_authority_id,
           ee.edge_type
           ee.evidence_edge_id,
           ee.source_node_id,
           ee.target_node_id,
           en.created_at
           en.created_at
           en.monitoring_record_id,
           en.monitoring_record_id,
           en.monitoring_record_id,
           en.node_payload_json,
           en.node_type,
           en.node_type,
           en.node_type,
           en.project_id,
           lcr.regulatory_checkpoint_id,
           lcr.rule_payload_json
           lcr.rule_type,
           mr.created_at
           mr.project_id,
           mr.record_payload_json,
           mr.record_type,
           revocation_reason = 'expired_cleanup'
           revocation_reason = p_reason
           t.issued_at, t.expires_at, t.revoked_at,
          'RETRY_CEILING_EXCEEDED', 'expired lease repair hit retry ceiling', p_worker_id
          AND p.idempotency_key = p_idempotency_key
          FROM public.asset_batches ab
          FROM public.asset_batches ab
          FROM public.interpretation_packs ip
          FROM public.lifecycle_checkpoint_rules lcr
          FROM public.lifecycle_checkpoint_rules lcr
          FROM public.lifecycle_checkpoint_rules lcr
          FROM public.lifecycle_checkpoint_rules lcr
          FROM public.methodology_versions mv
          FROM public.schema_registry sr
          INTO v_mv_adapter_id
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
         LIMIT 1;
         WHERE ab.asset_batch_id = p_subject_id AND ab.tenant_id = p_tenant_id;
         WHERE ab.project_id = p_project_id
         WHERE asset_batch_id = p_asset_batch_id
         WHERE ip.interpretation_pack_id = p_interpretation_pack_id;
         WHERE lcr.jurisdiction_code = p_jurisdiction_code
         WHERE lcr.jurisdiction_code = p_jurisdiction_code
         WHERE lcr.jurisdiction_code = v_jurisdiction_code
         WHERE lcr.jurisdiction_code = v_jurisdiction_code
         WHERE mv.methodology_version_id = p_methodology_version_id
         WHERE sr.schema_reference_id = p_payload_schema_reference_id
         purge_request_id = p_purge_request_id
         purged_at = NOW(),
        $$;
        'ANALYST_FINDING', 'VERIFIER_FINDING', 'REGULATORY_EXPORT', 'ISSUANCE_ARTIFACT'
        'ATTESTS_TO', 'DERIVED_FROM', 'CORROBORATES'
        'PROJECT', 'MONITORING_RECORD', 'ASSET_BATCH', 'EVIDENCE_NODE'
        'PROJECT_ACTIVATION',
        'PROJECT_REGISTRATION',
        'RAW_SOURCE', 'ATTESTED_SOURCE', 'NORMALIZED_RECORD',
        'SUPPORTS', 'REFUTES', 'DOCUMENTS', 'VALIDATES',
        'migrated_at', NOW(),
        'migrated_by', v_actor,
        'migrated_from_program_id', p_from_program_id,
        'migration_reason', v_reason
        '{}'::jsonb
        )
        )
        )
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
        ) || p_decision_payload_json
        );
        );
        );
        AND COALESCE(submitted_by, '') = v_actor
        AND status = 'PENDING_SUPERVISOR_APPROVAL'
        DELETE FROM payment_outbox_pending WHERE outbox_id = v_record.outbox_id;
        DETAIL = 'Lease missing/expired or token mismatch; refusing to complete';
        ELSE
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
        FROM payment_outbox_pending p
        IF EXISTS (
        IF NEW.execution_id IS NOT NULL THEN
        IF NOT (
        IF NOT (
        IF NOT (
        IF NOT EXISTS (
        IF NOT EXISTS (
        IF NOT EXISTS (
        IF NOT EXISTS (
        IF NOT FOUND THEN
        IF OLD.token_hash != NEW.token_hash
        IF jsonb_typeof(p_record_payload_json) != 'object' THEN
        IF v_conditional_count > 0 THEN
        IF v_mv_adapter_id IS NULL THEN
        IF v_pack_jcode IS NULL OR v_pack_jcode != p_jurisdiction_code THEN
        IF v_unsatisfied_checkpoints > 0 THEN
        INSERT INTO payment_outbox_attempts (
        INSERT INTO payment_outbox_attempts (
        INSERT INTO public.dispatch_reference_collision_events(
        INTO existing_pending
        LIMIT 1;
        NULL;
        NULL;
        ON ar.adapter_registration_id = mv.adapter_registration_id
        RAISE EXCEPTION 'Adapter registration is not active' USING ERRCODE = 'GF011';
        RAISE EXCEPTION 'Adapter registration not found' USING ERRCODE = 'GF010';
        RAISE EXCEPTION 'Asset batch must be ISSUED for retirement, current status: %', v_batch_status
        RAISE EXCEPTION 'Asset batch not found' USING ERRCODE = 'GF015';
        RAISE EXCEPTION 'CONF001: No authority decisions found for batch %. Issuance blocked (fail-closed).',
        RAISE EXCEPTION 'CONF002: No APPROVED authority decisions for batch %. Issuance blocked.',
        RAISE EXCEPTION 'CONF003: Insufficient confidence for issuance. Required: %, Actual: %. Batch: %',
        RAISE EXCEPTION 'DELETE not allowed on authority_decisions (append-only ledger)'
        RAISE EXCEPTION 'DELETE not allowed on gf_verifier_read_tokens (append-only ledger)'
        RAISE EXCEPTION 'GF036: state_transitions table is append-only, DELETE not allowed';
        RAISE EXCEPTION 'GF036: state_transitions table is append-only, UPDATE not allowed';
        RAISE EXCEPTION 'Invalid edge type: %', p_edge_type USING ERRCODE = 'GF017';
        RAISE EXCEPTION 'Invalid evidence class: %; must be one of %',
        RAISE EXCEPTION 'Invalid subject type: %', p_subject_type USING ERRCODE = 'GF013';
        RAISE EXCEPTION 'Invalid subject type: %', p_subject_type USING ERRCODE = 'GF016';
        RAISE EXCEPTION 'Invalid target record type: %', p_target_record_type
        RAISE EXCEPTION 'Project must be ACTIVE for issuance, current status: %', v_project_status
        RAISE EXCEPTION 'Project not found' USING ERRCODE = 'GF008';
        RAISE EXCEPTION 'Self-loop not allowed: source and target evidence_node_id are identical'
        RAISE EXCEPTION 'Table % is append-only', TG_TABLE_NAME
        RAISE EXCEPTION 'UPDATE not allowed on authority_decisions (append-only ledger)'
        RAISE EXCEPTION 'Verifier is not active' USING ERRCODE = 'GF007';
        RAISE EXCEPTION 'Verifier not found' USING ERRCODE = 'GF006';
        RAISE EXCEPTION 'adapter_registrations is append-only - % operations not allowed', TG_OP;
        RAISE EXCEPTION 'cross-tenant linkage prevented: source tenant_id != p_tenant_id'
        RAISE EXCEPTION 'cross-tenant linkage prevented: target tenant_id != p_tenant_id'
        RAISE EXCEPTION 'interpretation_pack_id is required (INV-165)'
        RAISE EXCEPTION 'interpretation_pack_id is required (INV-165)'
        RAISE EXCEPTION 'interpretation_pack_id is required for governed regulatory decisions (INV-165)'
        RAISE EXCEPTION 'jurisdiction_code does not match regulatory_authorities entry'
        RAISE EXCEPTION 'lifecycle transition blocked: % unsatisfied REQUIRED checkpoints',
        RAISE EXCEPTION 'methodology_version not found, not active, or adapter not active'
        RAISE EXCEPTION 'no asset_batches context found for project; asset tracking must be initialised first'
        RAISE EXCEPTION 'p_adapter_registration_id is required' USING ERRCODE = 'GF004';
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF013';
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF013';
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF013';
        RAISE EXCEPTION 'p_asset_batch_id is required' USING ERRCODE = 'GF023';
        RAISE EXCEPTION 'p_asset_type is required' USING ERRCODE = 'GF005';
        RAISE EXCEPTION 'p_decision_outcome is required' USING ERRCODE = 'GF008';
        RAISE EXCEPTION 'p_decision_type is required' USING ERRCODE = 'GF007';
        RAISE EXCEPTION 'p_document_type is required' USING ERRCODE = 'GF004';
        RAISE EXCEPTION 'p_edge_type is required' USING ERRCODE = 'GF016';
        RAISE EXCEPTION 'p_event_type is required' USING ERRCODE = 'GF018';
        RAISE EXCEPTION 'p_evidence_class is required' USING ERRCODE = 'GF003';
        RAISE EXCEPTION 'p_evidence_node_id is required' USING ERRCODE = 'GF014';
        RAISE EXCEPTION 'p_from_status is required' USING ERRCODE = 'GF011';
        RAISE EXCEPTION 'p_from_status is required' USING ERRCODE = 'GF016';
        RAISE EXCEPTION 'p_jurisdiction_code is required' USING ERRCODE = 'GF003';
        RAISE EXCEPTION 'p_jurisdiction_code is required' USING ERRCODE = 'GF006';
        RAISE EXCEPTION 'p_methodology_version_id is required' USING ERRCODE = 'GF003';
        RAISE EXCEPTION 'p_methodology_version_id is required' USING ERRCODE = 'GF004';
        RAISE EXCEPTION 'p_monitoring_record_id is required' USING ERRCODE = 'GF014';
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF003';
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF004';
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF007';
        RAISE EXCEPTION 'p_project_id is required' USING ERRCODE = 'GF013';
        RAISE EXCEPTION 'p_project_name is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_quantity must be positive' USING ERRCODE = 'GF006';
        RAISE EXCEPTION 'p_quantity must be positive' USING ERRCODE = 'GF006';
        RAISE EXCEPTION 'p_record_payload_json is required' USING ERRCODE = 'GF006';
        RAISE EXCEPTION 'p_record_type is required' USING ERRCODE = 'GF004';
        RAISE EXCEPTION 'p_regulatory_authority_id is required' USING ERRCODE = 'GF005';
        RAISE EXCEPTION 'p_retirement_reason is required' USING ERRCODE = 'GF014';
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF003';
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF010';
        RAISE EXCEPTION 'p_subject_id is required' USING ERRCODE = 'GF016';
        RAISE EXCEPTION 'p_subject_type is required' USING ERRCODE = 'GF009';
        RAISE EXCEPTION 'p_subject_type is required' USING ERRCODE = 'GF016';
        RAISE EXCEPTION 'p_target_evidence_node_id is required' USING ERRCODE = 'GF015';
        RAISE EXCEPTION 'p_target_record_id is required' USING ERRCODE = 'GF006';
        RAISE EXCEPTION 'p_target_record_type is required' USING ERRCODE = 'GF005';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF001';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF005';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF006';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF007';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF013';
        RAISE EXCEPTION 'p_tenant_id is required' USING ERRCODE = 'GF016';
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF004';
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF012';
        RAISE EXCEPTION 'p_to_status is required' USING ERRCODE = 'GF016';
        RAISE EXCEPTION 'p_token_hash is required' USING ERRCODE = 'GF002';
        RAISE EXCEPTION 'p_token_id is required' USING ERRCODE = 'GF003';
        RAISE EXCEPTION 'p_ttl_hours must be between 1 and 8760' USING ERRCODE = 'GF005';
        RAISE EXCEPTION 'p_unit is required' USING ERRCODE = 'GF007';
        RAISE EXCEPTION 'p_verifier_id is required' USING ERRCODE = 'GF003';
        RAISE EXCEPTION 'p_verifier_id is required' USING ERRCODE = 'GF003';
        RAISE EXCEPTION 'project must be in DRAFT status to activate; current=%', v_current_status
        RAISE EXCEPTION 'project must have status ACTIVE to accept monitoring records; current=%',
        RAISE EXCEPTION 'project not found for tenant' USING ERRCODE = 'GF008';
        RAISE EXCEPTION 'project not found for tenant' USING ERRCODE = 'GF008';
        RAISE EXCEPTION 'regulatory authority not found' USING ERRCODE = 'GF014';
        RAISE EXCEPTION 'retired_quantity exceeds remaining: requested=%, remaining=%',
        RAISE EXCEPTION 'source evidence node not found' USING ERRCODE = 'GF019';
        RAISE NOTICE 'Transition authority check: policy_decision_id is NULL';
        RAISE NOTICE 'Transition execution binding check: execution_id is NULL';
        RAISE NOTICE 'Transition signature check: signature is NULL';
        RETURN NEW;
        RETURN false;
        RETURN true;
        SELECT 1
        SELECT 1
        SELECT COUNT(*) INTO v_conditional_count
        SELECT COUNT(*) INTO v_conditional_count
        SELECT COUNT(*) INTO v_unsatisfied_checkpoints
        SELECT COUNT(*) INTO v_unsatisfied_checkpoints
        SELECT ab.status INTO v_current_status
        SELECT ip.jurisdiction_code INTO v_pack_jcode
        SELECT mv.adapter_registration_id
        SELECT p.outbox_id, p.sequence_id, p.created_at
        THEN
        UPDATE payment_outbox_pending SET
        UPDATE public.asset_batches
        USING ERRCODE = '42501';
        WHERE p.instruction_id = p_instruction_id
        WHERE payment_outbox_pending.outbox_id = v_record.outbox_id;
        allocated_sequence,
        approved_at = NOW(),
        approved_at = NOW(),
        approved_at = NULL;
        approved_by = NULL,
        approved_by = v_actor,
        approved_by = v_actor,
        attempt_count = GREATEST(attempt_count, v_next_attempt_no),
        canonicalized_reference, strategy_used, policy_version_id, collision_retry_count
        claimed_by = NULL, lease_token = NULL, lease_expires_at = NULL
        containment_action = EXCLUDED.containment_action;
        contradiction_timestamp = EXCLUDED.contradiction_timestamp,
        current_state = EXCLUDED.current_state,
        decided_at = NOW(),
        decided_at = NOW(),
        decided_at = NOW(),
        decided_at = NULL,
        decided_at = NULL,
        decided_by = NULL,
        decided_by = NULL,
        decided_by = v_actor,
        decided_by = v_actor,
        decided_by = v_actor,
        decision_payload_json
        decision_reason = COALESCE(p_reason, 'acknowledged')
        decision_reason = COALESCE(p_reason, 'reset_to_ack_wait')
        decision_reason = COALESCE(p_reason, 'resume_ack_wait')
        decision_reason = NULL,
        decision_reason = NULL;
        decision_type,
        dispatch_reference_registry.allocated_reference,
        dispatch_reference_registry.canonicalized_reference,
        dispatch_reference_registry.collision_retry_count
        dispatch_reference_registry.policy_version_id,
        dispatch_reference_registry.registry_id,
        dispatch_reference_registry.strategy_used,
        edge_type
        event_payload_json
        event_payload_json
        held_at = NOW(),
        held_at = NOW(),
        held_reason = EXCLUDED.held_reason,
        idempotency_key,
        inquiry_state = 'EXHAUSTED',
        instruction_id,
        instruction_id, adjustment_id, rail_id, allocated_reference,
        instruction_id, adjustment_id, rail_id, reference_attempted,
        jsonb_build_object(
        jsonb_build_object(
        jsonb_build_object(
        jsonb_build_object(
        jurisdiction_code,
        max_attempts = p_max_attempts
        monitoring_record_id,
        next_attempt_at = NOW() + make_interval(secs => GREATEST(1, COALESCE(p_retry_delay_seconds, 1))),
        node_payload_json
        node_type,
        observed_rate = EXCLUDED.observed_rate,
        p_decision_type,
        p_edge_type
        p_event_timestamp := now();
        p_evidence_class,
        p_evidence_node_id,
        p_idempotency_key,
        p_instruction_id,
        p_instruction_id, p_adjustment_id, p_rail_id, p_parent_reference,
        p_instruction_id, p_adjustment_id, p_rail_id, v_candidate,
        p_jurisdiction_code,
        p_node_payload_json
        p_participant_id,
        p_payload
        p_payload_schema_reference_id
        p_project_id,
        p_project_id,
        p_project_id,
        p_rail_type,
        p_record_payload_json
        p_record_payload_json,
        p_record_type,
        p_regulatory_authority_id,
        p_scoped_tables, v_expires_at
        p_target_evidence_node_id,
        p_tenant_id,
        p_tenant_id,
        p_tenant_id,
        p_tenant_id,
        p_tenant_id,
        p_tenant_id, p_asset_batch_id, 'RETIREMENT',
        p_tenant_id, p_asset_batch_id, p_event_type, p_event_payload
        p_tenant_id, p_asset_batch_id, v_retire_qty, p_retirement_reason
        p_tenant_id, p_project_id, p_asset_type, p_quantity, 'ISSUED'
        p_tenant_id, p_verifier_id, p_project_id, v_token_hash,
        p_tenant_id, v_asset_batch_id, 'STATUS_CHANGE',
        participant_id,
        payload
        policy_version_id = EXCLUDED.policy_version_id,
        policy_version_id = EXCLUDED.policy_version_id;
        policy_version_id = p_policy_version_id,
        project_id,
        project_id,
        rail_a_id = EXCLUDED.rail_a_id,
        rail_a_response = EXCLUDED.rail_a_response,
        rail_b_id = EXCLUDED.rail_b_id,
        rail_b_response = EXCLUDED.rail_b_response,
        rail_type,
        record_payload_json
        record_type,
        regulatory_authority_id,
        reset_at = NOW(),
        resumed_at = NOW(),
        rolling_window_seconds = EXCLUDED.rolling_window_seconds,
        scoped_tables, expires_at
        sequence_id,
        source_node_id,
        state_since = EXCLUDED.state_since;
        status = 'PENDING_SUPERVISOR_APPROVAL',
        status = 'PENDING_SUPERVISOR_APPROVAL',
        strategy_used, collision_count, outcome, policy_version_id
        submitted_by = EXCLUDED.submitted_by,
        suspended_at = CASE WHEN EXCLUDED.state='SUSPENDED' THEN now() ELSE public.adapter_circuit_breakers.suspended_at END;
        target_node_id,
        tenant_id,
        tenant_id,
        tenant_id,
        tenant_id, asset_batch_id, event_type,
        tenant_id, asset_batch_id, event_type,
        tenant_id, asset_batch_id, event_type, event_payload_json
        tenant_id, asset_batch_id, retired_quantity, retirement_reason
        tenant_id, project_id, batch_type, quantity, status
        tenant_id, verifier_id, project_id, token_hash,
        timeout_at = EXCLUDED.timeout_at,
        timeout_at = NOW() + make_interval(mins => v_timeout),
        trigger_threshold = EXCLUDED.trigger_threshold,
        v_canon, v_strategy.strategy_type, v_strategy.policy_version_id, v_attempt
        v_collision := true;
        v_conditional_count := 0;
        v_monitoring_record_id := p_target_record_id;
        v_monitoring_record_id,
        v_project_id,
        v_result_state := 'CONDITIONALLY_SATISFIED';
        v_result_state := 'PENDING_CLARIFICATION';
        v_strategy.strategy_type, v_attempt, 'EXHAUSTED', v_strategy.policy_version_id
        v_unsatisfied_checkpoints := 0;
       AND (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
       AND (ad.decision_payload_json->>'decision_outcome') = 'APPROVED'
       AND (ad.decision_payload_json->>'subject_id')::UUID = NEW.asset_batch_id
       AND (ad.decision_payload_json->>'subject_id')::UUID = NEW.asset_batch_id;
       AND (ad.decision_payload_json->>'subject_id')::UUID = p_asset_batch_id
       AND (ad.decision_payload_json->>'subject_id')::UUID = p_asset_batch_id;
       AND (p_record_type IS NULL OR mr.record_type = p_record_type)
       AND (p_subject_id IS NULL
       AND ab.tenant_id = p_tenant_id
       AND ab.tenant_id = p_tenant_id
       AND ab.tenant_id = p_tenant_id;
       AND ad.decision_payload_json->>'confidence_score' IS NOT NULL;
       AND ad.decision_payload_json->>'confidence_score' IS NOT NULL;
       AND ar.is_active = true
       AND en.project_id = p_project_id
       AND en.project_id = p_project_id
       AND en.tenant_id        = p_tenant_id;
       AND lcr.rule_type = 'REQUIRED';
       AND mr.project_id = p_project_id
       AND mr.tenant_id            = p_tenant_id;
       AND mv.status = 'ACTIVE'
       AND mv.tenant_id = p_tenant_id
       AND p.tenant_id  = p_tenant_id;
       AND p.tenant_id  = p_tenant_id;
       AND p.tenant_id  = p_tenant_id;
       AND p.tenant_id = p_tenant_id;
       AND revoked_at IS NULL;
       AND revoked_at IS NULL;
       AND t.expires_at > now()
       AND t.revoked_at IS NULL
       AND t.token_hash = public.crypt(p_token_hash, t.token_hash)
       AND t.verifier_id = p_verifier_id
       AND tenant_id  = p_tenant_id;
       AND tenant_id = p_tenant_id
       AND vr.tenant_id = p_tenant_id;
       SET revoked_at = now(),
       SET revoked_at = now(),
       SET status = 'ACTIVE'
      'SUFFIX', 1, 'UNREGISTERED_BLOCKED', NULL
      'migrated_at', NOW(),
      'migrated_from_program_id', p_from_program_id,
      'migrated_to_program_id', p_to_program_id,
      'migration_reason', v_reason
      (e.state = 'CREATED' AND e.authorization_expires_at IS NOT NULL AND e.authorization_expires_at <= p_now)
      (v_item->>'amount_minor')::BIGINT,
      )
      )
      )
      )
      ) VALUES (
      ) VALUES (
      );
      AND (effective_to IS NULL OR effective_to > p_effective_at)
      AND (o.lease_expires_at IS NULL OR o.lease_expires_at <= clock_timestamp())
      AND (p_adjustment_id IS NULL OR r.adjustment_id = p_adjustment_id)
      AND (r.allocated_reference = p_reference OR r.canonicalized_reference = p_reference)
      AND a.idempotency_key = p_idempotency_key
      AND e.from_program_id = p_from_program_id
      AND e.person_id = p_person_id
      AND e.to_program_id = p_to_program_id
      AND effective_from <= p_effective_at
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
      COALESCE(SUM(CASE WHEN direction = 'CREDIT' THEN amount_minor ELSE 0 END), 0) AS credit_total,
      COALESCE(SUM(CASE WHEN direction = 'DEBIT' THEN amount_minor ELSE 0 END), 0) AS debit_total,
      COALESCE(v_item->>'currency_code', p_currency_code)
      COALESCE(v_source_member.metadata, '{}'::jsonb) || jsonb_build_object(
      COUNT(*) AS posting_count,
      COUNT(*) FILTER (WHERE direction = 'CREDIT') AS credit_count
      COUNT(*) FILTER (WHERE direction = 'DEBIT') AS debit_count,
      COUNT(DISTINCT account_code) AS distinct_accounts,
      DELETE FROM payment_outbox_pending WHERE outbox_id = p_outbox_id;
      ELSE
      ELSE 'RESET'
      END IF;
      END IF;
      ERRCODE = 'P7803',
      ERRCODE = 'P7803',
      FROM payment_outbox_attempts a WHERE a.outbox_id = v_record.outbox_id;
      FROM payment_outbox_pending p
      FROM public.adapter_registrations ar
      FROM public.asset_batches ab
      FROM public.asset_batches ab
      FROM public.asset_batches ab
      FROM public.authority_decisions ad
      FROM public.authority_decisions ad
      FROM public.authority_decisions ad
      FROM public.authority_decisions ad
      FROM public.authority_decisions ad
      FROM public.evidence_nodes en
      FROM public.evidence_nodes en
      FROM public.evidence_nodes en
      FROM public.evidence_nodes en
      FROM public.evidence_nodes en
      FROM public.gf_verifier_read_tokens t
      FROM public.gf_verifier_read_tokens t
      FROM public.lifecycle_checkpoint_rules lcr
      FROM public.lifecycle_checkpoint_rules lcr
      FROM public.methodology_versions mv
      FROM public.monitoring_records mr
      FROM public.monitoring_records mr
      FROM public.projects p
      FROM public.projects p
      FROM public.projects p
      FROM public.projects p
      FROM public.projects p
      FROM public.projects p
      FROM public.projects p
      FROM public.regulatory_authorities ra
      FROM public.retirement_events re
      FROM public.supervisor_approval_queue
      FROM public.verifier_registry vr
      IF v_attempt > 0 THEN
      IF v_next_attempt_no >= v_retry_ceiling THEN
      INSERT INTO payment_outbox_pending (
      INSERT INTO public.dispatch_reference_collision_events(
      INSERT INTO public.dispatch_reference_registry(
      INTO existing_pending;
      INTO registry_id, allocated_reference, canonicalized_reference, strategy_used, policy_version_id, collision_retry_count;
      INTO v_adapter_registration_id
      INTO v_batch_status, v_batch_quantity
      INTO v_confidence
      INTO v_confidence_score
      INTO v_current_status
      INTO v_decision_count, v_approved_count
      INTO v_payload
      INTO v_project_status
      INTO v_total, v_approved
      INTO v_total_retired
      INTO v_unsatisfied_checkpoints
      INTO v_verifier_active, v_methodology_scope
      JOIN public.adapter_registrations ar
      LEFT JOIN public.evidence_edges ee
      LEFT JOIN public.retirement_events re ON re.asset_batch_id = ab.asset_batch_id
      LEFT JOIN public.retirement_events re ON re.asset_batch_id = ab.asset_batch_id
      MESSAGE = 'ACTIVE_REFERENCE_POLICY_IMMUTABLE';
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
      SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
      SELECT p.outbox_id, p.instruction_id, p.participant_id, p.sequence_id,
      SET next_sequence_id = participant_outbox_sequences.next_sequence_id + 1
      UPDATE payment_outbox_pending SET
      USING ERRCODE = '23503';
      USING ERRCODE = '23503';
      USING ERRCODE = '23505';
      USING ERRCODE = '23514';
      USING ERRCODE = '23514';
      USING ERRCODE = '23514';
      USING ERRCODE = '23514';
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
      WHEN 'ACKNOWLEDGE' THEN 'ACKNOWLEDGED'
      WHEN 'RESUME' THEN 'RESUMED'
      WHEN unique_violation THEN
      WHEN unique_violation THEN
      WHERE instruction_id = p_instruction_id
      WHERE outbox_id = p_outbox_id;
      WHERE p.claimed_by IS NOT NULL AND p.lease_token IS NOT NULL AND p.lease_expires_at <= NOW()
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
      decided_at = NULL,
      decided_at = p_now,
      decided_by = 'system_timeout',
      decided_by = NULL,
      decided_by = v_actor,
      decision_reason = COALESCE(decision_reason, 'timeout')
      decision_reason = NULL
      decision_reason = p_reason
      enrolled_at,
      entity_id,
      error_code, error_message, latency_ms, worker_id
      escalated_at = NOW(),
      expired_at = CASE WHEN v_to_state = 'EXPIRED' THEN COALESCE(expired_at, p_now) ELSE expired_at END
      formula_version_id
      from_program_id,
      hashtextextended(p_instruction_id || chr(31) || p_idempotency_key, 1)
      held_reason = COALESCE(p_reason, held_reason, 'missing_acknowledgement'),
      inquiry_state = 'SENT',
      instruction_id, adjustment_id, rail_id, reference_attempted,
      journal_id, tenant_id, account_code, direction, amount_minor, currency_code
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
      p_tenant_id,
      p_tenant_id, p_person_id, p_from_program_id, p_to_program_id
      p_to_program_id,
      p_to_program_id,
      p_to_state => 'EXPIRED',
      person_id,
      person_id,
      policy_version_id = p_policy_version_id
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
      upper(v_item->>'direction'),
      v_actor,
      v_candidate := p_parent_reference || '-' || lpad(v_attempt::text, 2, '0');
      v_candidate := p_parent_reference;
      v_candidate := substr(md5('reh:' || p_parent_reference || ':' || p_rail_id || ':' || v_attempt::text), 1, greatest(8, v_strategy.max_length));
      v_candidate := substr(md5(p_parent_reference || ':' || coalesce(p_adjustment_id::text,'none') || ':' || v_attempt::text), 1, greatest(8, v_strategy.max_length));
      v_effective_state := 'FAILED';
      v_formula_version_id
      v_item->>'account_code',
      v_journal_id,
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
     AND credit_count >= 1
     AND debit_count >= 1
     AND debit_total = credit_total
     AND distinct_accounts >= 2
     AND p_rail_a_status <> p_rail_b_status THEN
     AND p_rail_b_status IN ('SUCCESS','FAILED')
     AND purged_at IS NULL;
     GROUP BY ab.asset_batch_id, ab.batch_type, ab.quantity, ab.status, ab.created_at
     GROUP BY ab.asset_batch_id, ab.project_id, ab.batch_type,
     JOIN public.members m ON ((m.member_id = e.member_id)));
     LIMIT 1;
     LIMIT 1;
     OR NEW.activated_at IS DISTINCT FROM OLD.activated_at
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
     OR NEW.evidence_path IS DISTINCT FROM OLD.evidence_path
     OR NEW.policy_version_id IS DISTINCT FROM OLD.policy_version_id
     OR NEW.signed_at IS DISTINCT FROM OLD.signed_at
     OR NEW.signed_key_id IS DISTINCT FROM OLD.signed_key_id
     OR NEW.unsigned_reason IS DISTINCT FROM OLD.unsigned_reason
     ORDER BY ab.created_at DESC;
     ORDER BY ad.created_at ASC;
     ORDER BY en.created_at ASC;
     ORDER BY en.created_at ASC;
     ORDER BY lcr.created_at ASC;
     ORDER BY mr.created_at ASC;
     ORDER BY p.created_at DESC;
     ORDER BY t.created_at DESC;
     SET protected_payload = NULL,
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
     WHERE (ad.decision_payload_json->>'subject_type') = 'ASSET_BATCH'
     WHERE ab.asset_batch_id = p_asset_batch_id
     WHERE ab.asset_batch_id = p_asset_batch_id
     WHERE ab.project_id = p_project_id
     WHERE ad.jurisdiction_code = p_jurisdiction_code
     WHERE ar.adapter_registration_id = p_adapter_registration_id;
     WHERE en.evidence_node_id = p_evidence_node_id
     WHERE en.evidence_node_id = p_evidence_node_id;
     WHERE en.evidence_node_id = p_target_evidence_node_id;
     WHERE en.tenant_id  = p_tenant_id
     WHERE en.tenant_id  = p_tenant_id
     WHERE expires_at <= now()
     WHERE lcr.jurisdiction_code = p_jurisdiction_code
     WHERE lcr.jurisdiction_code = p_jurisdiction_code
     WHERE mr.monitoring_record_id = p_monitoring_record_id
     WHERE mr.tenant_id  = p_tenant_id
     WHERE mv.methodology_version_id = p_methodology_version_id
     WHERE p.project_id = p_project_id
     WHERE p.project_id = p_project_id
     WHERE p.project_id = p_project_id
     WHERE p.project_id = p_project_id
     WHERE p.project_id = p_project_id;
     WHERE p.project_id = p_subject_id AND p.tenant_id = p_tenant_id;
     WHERE p.tenant_id = p_tenant_id
     WHERE project_id = p_project_id
     WHERE ra.regulatory_authority_id = p_regulatory_authority_id;
     WHERE re.asset_batch_id = p_asset_batch_id;
     WHERE t.project_id = p_project_id
     WHERE t.tenant_id = p_tenant_id
     WHERE token_id = p_token_id
     WHERE vr.verifier_id = p_verifier_id
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
    'AWAITING_EXECUTION',
    'DETERMINISTIC_ALIAS',
    'DISPATCHED',
    'DISPATCHING',
    'DUPLICATE_DISPATCH',
    'EASK',
    'ESCALATED',
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
    'authoritative_signed',
    'blocked_legal_hold'
    'cooling_off',
    'denied',
    'derived_unverified',
    'draft',
    'eligible_execute',
    'executed',
    'invalidated'
    'non_reproducible',
    'pending_approval',
    'phase1_indicative_only',
    'policy_bound_unsigned',
    'requested',
    'superseded',
    'v1', 'signing-service-v1', 'trust-chain-main',
    (EXTRACT(year FROM enrolled_at))::integer AS program_year,
    (s->>'max_length')::integer,
    (s->>'nonce_retry_limit')::integer,
    (s->>'strategy_type')::public.reference_strategy_type_enum,
    (v_row.state = 'CREATED' AND v_to_state IN ('AUTHORIZED', 'CANCELED', 'EXPIRED'))
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
    ) INTO v_schema_exists;
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
    0,
    20
    ADD CONSTRAINT adapter_circuit_breakers_pkey PRIMARY KEY (adapter_id, rail_id);
    ADD CONSTRAINT adapter_registration_unique UNIQUE (tenant_id, adapter_code, methodology_code, version_code);
    ADD CONSTRAINT adapter_registrations_pkey PRIMARY KEY (adapter_registration_id);
    ADD CONSTRAINT adapter_registrations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
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
    ADD CONSTRAINT anchor_backfill_jobs_pkey PRIMARY KEY (job_id);
    ADD CONSTRAINT anchor_sync_operations_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.evidence_packs(pack_id);
    ADD CONSTRAINT anchor_sync_operations_pack_id_key UNIQUE (pack_id);
    ADD CONSTRAINT anchor_sync_operations_pkey PRIMARY KEY (operation_id);
    ADD CONSTRAINT archive_verification_runs_pkey PRIMARY KEY (run_id);
    ADD CONSTRAINT artifact_signing_batch_items_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.artifact_signing_batches(batch_id) ON DELETE CASCADE;
    ADD CONSTRAINT artifact_signing_batch_items_batch_id_leaf_index_key UNIQUE (batch_id, leaf_index);
    ADD CONSTRAINT artifact_signing_batch_items_pkey PRIMARY KEY (item_id);
    ADD CONSTRAINT artifact_signing_batches_pkey PRIMARY KEY (batch_id);
    ADD CONSTRAINT asset_batches_pkey PRIMARY KEY (asset_batch_id);
    ADD CONSTRAINT asset_batches_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;
    ADD CONSTRAINT asset_batches_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT asset_lifecycle_events_asset_batch_id_fkey FOREIGN KEY (asset_batch_id) REFERENCES public.asset_batches(asset_batch_id) ON DELETE RESTRICT;
    ADD CONSTRAINT asset_lifecycle_events_pkey PRIMARY KEY (lifecycle_event_id);
    ADD CONSTRAINT asset_lifecycle_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT audit_tamper_evident_chains_pkey PRIMARY KEY (chain_id);
    ADD CONSTRAINT authority_decisions_pkey PRIMARY KEY (authority_decision_id);
    ADD CONSTRAINT authority_decisions_regulatory_authority_id_fkey FOREIGN KEY (regulatory_authority_id) REFERENCES public.regulatory_authorities(regulatory_authority_id) ON DELETE RESTRICT;
    ADD CONSTRAINT billable_clients_client_key_required_new_rows_chk CHECK (((client_key IS NOT NULL) AND (length(btrim(client_key)) > 0))) NOT VALID;
    ADD CONSTRAINT billable_clients_pkey PRIMARY KEY (billable_client_id);
    ADD CONSTRAINT billing_usage_events_billable_client_id_fkey FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id);
    ADD CONSTRAINT billing_usage_events_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.tenant_clients(client_id);
    ADD CONSTRAINT billing_usage_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT billing_usage_events_subject_client_id_fkey FOREIGN KEY (subject_client_id) REFERENCES public.tenant_clients(client_id);
    ADD CONSTRAINT billing_usage_events_subject_member_id_fkey FOREIGN KEY (subject_member_id) REFERENCES public.tenant_members(member_id);
    ADD CONSTRAINT billing_usage_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT boz_operational_scenario_runs_pkey PRIMARY KEY (run_id);
    ADD CONSTRAINT canonicalization_archive_snap_canonicalization_version_snap_key UNIQUE (canonicalization_version, snapshot_sha256);
    ADD CONSTRAINT canonicalization_archive_snapshot_canonicalization_version_fkey FOREIGN KEY (canonicalization_version) REFERENCES public.canonicalization_registry(canonicalization_version) ON DELETE RESTRICT;
    ADD CONSTRAINT canonicalization_archive_snapshots_pkey PRIMARY KEY (snapshot_id);
    ADD CONSTRAINT canonicalization_registry_pkey PRIMARY KEY (canonicalization_version);
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
    ADD CONSTRAINT escrow_summary_projection_escrow_id_fkey FOREIGN KEY (escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_summary_projection_pkey PRIMARY KEY (escrow_id);
    ADD CONSTRAINT escrow_summary_projection_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT escrow_summary_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT evidence_bundle_projection_pkey PRIMARY KEY (instruction_id);
    ADD CONSTRAINT evidence_bundle_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT evidence_edges_pkey PRIMARY KEY (evidence_edge_id);
    ADD CONSTRAINT evidence_edges_source_node_id_fkey FOREIGN KEY (source_node_id) REFERENCES public.evidence_nodes(evidence_node_id) ON DELETE RESTRICT;
    ADD CONSTRAINT evidence_edges_target_node_id_fkey FOREIGN KEY (target_node_id) REFERENCES public.evidence_nodes(evidence_node_id) ON DELETE RESTRICT;
    ADD CONSTRAINT evidence_edges_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT evidence_nodes_monitoring_record_id_fkey FOREIGN KEY (monitoring_record_id) REFERENCES public.monitoring_records(monitoring_record_id) ON DELETE RESTRICT;
    ADD CONSTRAINT evidence_nodes_pkey PRIMARY KEY (evidence_node_id);
    ADD CONSTRAINT evidence_nodes_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;
    ADD CONSTRAINT evidence_nodes_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT evidence_pack_items_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES public.evidence_packs(pack_id);
    ADD CONSTRAINT evidence_pack_items_pkey PRIMARY KEY (item_id);
    ADD CONSTRAINT evidence_packs_pkey PRIMARY KEY (pack_id);
    ADD CONSTRAINT execution_records_interpretation_version_id_fkey FOREIGN KEY (interpretation_version_id) REFERENCES public.interpretation_packs(interpretation_pack_id) ON DELETE RESTRICT;
    ADD CONSTRAINT execution_records_pkey PRIMARY KEY (execution_id);
    ADD CONSTRAINT external_proofs_attestation_id_fkey FOREIGN KEY (attestation_id) REFERENCES public.ingress_attestations(attestation_id);
    ADD CONSTRAINT external_proofs_billable_client_fk FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id) NOT VALID;
    ADD CONSTRAINT external_proofs_billable_client_required_new_rows_chk CHECK ((billable_client_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT external_proofs_pkey PRIMARY KEY (proof_id);
    ADD CONSTRAINT external_proofs_subject_member_fk FOREIGN KEY (subject_member_id) REFERENCES public.tenant_members(member_id) NOT VALID;
    ADD CONSTRAINT external_proofs_tenant_fk FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) NOT VALID;
    ADD CONSTRAINT external_proofs_tenant_required_new_rows_chk CHECK ((tenant_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT factor_registry_pkey PRIMARY KEY (factor_id);
    ADD CONSTRAINT gf_verifier_read_tokens_pkey PRIMARY KEY (token_id);
    ADD CONSTRAINT gf_verifier_read_tokens_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;
    ADD CONSTRAINT gf_verifier_read_tokens_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT gf_verifier_read_tokens_verifier_id_fkey FOREIGN KEY (verifier_id) REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT;
    ADD CONSTRAINT global_rate_limit_policies_pkey PRIMARY KEY (policy_id);
    ADD CONSTRAINT historical_verification_runs_pkey PRIMARY KEY (verification_run_id);
    ADD CONSTRAINT hsm_fail_closed_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT incident_case_projection_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.regulatory_incidents(incident_id) ON DELETE RESTRICT;
    ADD CONSTRAINT incident_case_projection_pkey PRIMARY KEY (incident_id);
    ADD CONSTRAINT incident_case_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
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
    ADD CONSTRAINT instruction_status_projection_attestation_id_fkey FOREIGN KEY (attestation_id) REFERENCES public.ingress_attestations(attestation_id) ON DELETE RESTRICT;
    ADD CONSTRAINT instruction_status_projection_pkey PRIMARY KEY (instruction_id);
    ADD CONSTRAINT instruction_status_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT internal_ledger_journals_pkey PRIMARY KEY (journal_id);
    ADD CONSTRAINT internal_ledger_journals_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT internal_ledger_journals_tenant_id_idempotency_key_key UNIQUE (tenant_id, idempotency_key);
    ADD CONSTRAINT internal_ledger_postings_journal_id_fkey FOREIGN KEY (journal_id) REFERENCES public.internal_ledger_journals(journal_id) ON DELETE RESTRICT;
    ADD CONSTRAINT internal_ledger_postings_pkey PRIMARY KEY (posting_id);
    ADD CONSTRAINT internal_ledger_postings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT interpretation_packs_pkey PRIMARY KEY (interpretation_pack_id);
    ADD CONSTRAINT jurisdiction_profiles_pkey PRIMARY KEY (jurisdiction_profile_id);
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
    ADD CONSTRAINT lifecycle_checkpoint_rules_pkey PRIMARY KEY (lifecycle_checkpoint_rule_id);
    ADD CONSTRAINT lifecycle_checkpoint_rules_regulatory_checkpoint_id_fkey FOREIGN KEY (regulatory_checkpoint_id) REFERENCES public.regulatory_checkpoints(regulatory_checkpoint_id) ON DELETE RESTRICT;
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
    ADD CONSTRAINT methodology_versions_adapter_registration_id_fkey FOREIGN KEY (adapter_registration_id) REFERENCES public.adapter_registrations(adapter_registration_id) ON DELETE RESTRICT;
    ADD CONSTRAINT methodology_versions_pkey PRIMARY KEY (methodology_version_id);
    ADD CONSTRAINT methodology_versions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT mmo_reality_control_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT monitoring_records_pkey PRIMARY KEY (monitoring_record_id);
    ADD CONSTRAINT monitoring_records_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;
    ADD CONSTRAINT monitoring_records_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
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
    ADD CONSTRAINT penalty_defense_packs_pkey PRIMARY KEY (pack_id);
    ADD CONSTRAINT penalty_defense_packs_submission_attempt_ref_fkey FOREIGN KEY (submission_attempt_ref) REFERENCES public.regulatory_report_submission_attempts(attempt_id);
    ADD CONSTRAINT persons_pkey PRIMARY KEY (person_id);
    ADD CONSTRAINT persons_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT pii_erased_subject_placeholders_pkey PRIMARY KEY (placeholder_id);
    ADD CONSTRAINT pii_erased_subject_placeholders_placeholder_ref_key UNIQUE (placeholder_ref);
    ADD CONSTRAINT pii_erasure_journal_pkey PRIMARY KEY (erasure_id);
    ADD CONSTRAINT pii_purge_events_pkey PRIMARY KEY (purge_event_id);
    ADD CONSTRAINT pii_purge_events_purge_request_id_fkey FOREIGN KEY (purge_request_id) REFERENCES public.pii_purge_requests(purge_request_id);
    ADD CONSTRAINT pii_purge_requests_pkey PRIMARY KEY (purge_request_id);
    ADD CONSTRAINT pii_tokenization_registry_pkey PRIMARY KEY (token_id);
    ADD CONSTRAINT pii_tokenization_registry_token_value_key UNIQUE (token_value);
    ADD CONSTRAINT pii_vault_records_pkey PRIMARY KEY (vault_id);
    ADD CONSTRAINT pii_vault_records_purge_request_fk FOREIGN KEY (purge_request_id) REFERENCES public.pii_purge_requests(purge_request_id) DEFERRABLE;
    ADD CONSTRAINT policy_bundles_pkey PRIMARY KEY (policy_bundle_id);
    ADD CONSTRAINT policy_bundles_policy_id_policy_version_key UNIQUE (policy_id, policy_version);
    ADD CONSTRAINT policy_versions_pkey PRIMARY KEY (version);
    ADD CONSTRAINT program_member_summary_projection_pkey PRIMARY KEY (tenant_id, program_id);
    ADD CONSTRAINT program_member_summary_projection_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_member_summary_projection_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_formula_version_id_fkey FOREIGN KEY (formula_version_id) REFERENCES public.risk_formula_versions(formula_version_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_from_program_id_fkey FOREIGN KEY (from_program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_migrated_member_id_fkey FOREIGN KEY (migrated_member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_new_member_id_fkey FOREIGN KEY (new_member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.persons(person_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_pkey PRIMARY KEY (migration_event_id);
    ADD CONSTRAINT program_migration_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_migration_events_to_program_id_fkey FOREIGN KEY (to_program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_supplier_allowlist_pkey PRIMARY KEY (tenant_id, program_id, supplier_id);
    ADD CONSTRAINT program_supplier_allowlist_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_supplier_allowlist_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT program_supplier_allowlist_tenant_id_supplier_id_fkey FOREIGN KEY (tenant_id, supplier_id) REFERENCES public.supplier_registry(tenant_id, supplier_id) ON DELETE RESTRICT;
    ADD CONSTRAINT programme_policy_binding_pkey PRIMARY KEY (id);
    ADD CONSTRAINT programme_policy_binding_programme_id_fkey FOREIGN KEY (programme_id) REFERENCES public.programme_registry(id);
    ADD CONSTRAINT programme_policy_binding_programme_id_is_active_key UNIQUE (programme_id, is_active);
    ADD CONSTRAINT programme_policy_binding_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant_registry(tenant_id);
    ADD CONSTRAINT programme_registry_pkey PRIMARY KEY (id);
    ADD CONSTRAINT programme_registry_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenant_registry(tenant_id);
    ADD CONSTRAINT programme_registry_tenant_id_programme_key_key UNIQUE (tenant_id, programme_key);
    ADD CONSTRAINT programs_pkey PRIMARY KEY (program_id);
    ADD CONSTRAINT programs_program_escrow_id_fkey FOREIGN KEY (program_escrow_id) REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT;
    ADD CONSTRAINT programs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT programs_tenant_id_program_escrow_id_key UNIQUE (tenant_id, program_escrow_id);
    ADD CONSTRAINT programs_tenant_id_program_key_key UNIQUE (tenant_id, program_key);
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);
    ADD CONSTRAINT projects_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT proof_pack_batch_leaves_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.proof_pack_batches(batch_id) ON DELETE CASCADE;
    ADD CONSTRAINT proof_pack_batch_leaves_batch_id_leaf_index_key UNIQUE (batch_id, leaf_index);
    ADD CONSTRAINT proof_pack_batch_leaves_pkey PRIMARY KEY (leaf_id);
    ADD CONSTRAINT proof_pack_batches_canonicalization_version_fkey FOREIGN KEY (canonicalization_version) REFERENCES public.canonicalization_registry(canonicalization_version) ON DELETE RESTRICT;
    ADD CONSTRAINT proof_pack_batches_pkey PRIMARY KEY (batch_id);
    ADD CONSTRAINT rail_dispatch_truth_anchor_pkey PRIMARY KEY (anchor_id);
    ADD CONSTRAINT rail_truth_anchor_attempt_fk FOREIGN KEY (attempt_id) REFERENCES public.payment_outbox_attempts(attempt_id) DEFERRABLE;
    ADD CONSTRAINT redaction_audit_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT reference_strategy_policy_versions_pkey PRIMARY KEY (policy_version_id);
    ADD CONSTRAINT regulatory_authorities_pkey PRIMARY KEY (regulatory_authority_id);
    ADD CONSTRAINT regulatory_checkpoints_pkey PRIMARY KEY (regulatory_checkpoint_id);
    ADD CONSTRAINT regulatory_checkpoints_regulatory_authority_id_fkey FOREIGN KEY (regulatory_authority_id) REFERENCES public.regulatory_authorities(regulatory_authority_id) ON DELETE RESTRICT;
    ADD CONSTRAINT regulatory_incidents_pkey PRIMARY KEY (incident_id);
    ADD CONSTRAINT regulatory_incidents_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT regulatory_report_submission_attempts_pkey PRIMARY KEY (attempt_id);
    ADD CONSTRAINT regulatory_retraction_approva_report_id_approver_role_appro_key UNIQUE (report_id, approver_role, approval_stage);
    ADD CONSTRAINT regulatory_retraction_approvals_pkey PRIMARY KEY (approval_id);
    ADD CONSTRAINT resign_sweeps_pkey PRIMARY KEY (sweep_id);
    ADD CONSTRAINT retirement_events_asset_batch_id_fkey FOREIGN KEY (asset_batch_id) REFERENCES public.asset_batches(asset_batch_id) ON DELETE RESTRICT;
    ADD CONSTRAINT retirement_events_pkey PRIMARY KEY (retirement_event_id);
    ADD CONSTRAINT retirement_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT revoked_client_certs_pkey PRIMARY KEY (cert_fingerprint_sha256);
    ADD CONSTRAINT revoked_tokens_pkey PRIMARY KEY (token_jti);
    ADD CONSTRAINT risk_formula_versions_formula_key_key UNIQUE (formula_key);
    ADD CONSTRAINT risk_formula_versions_pkey PRIMARY KEY (formula_version_id);
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);
    ADD CONSTRAINT signing_audit_log_pkey PRIMARY KEY (sign_event_id);
    ADD CONSTRAINT signing_authorization_matrix_caller_id_key_class_key UNIQUE (caller_id, key_class);
    ADD CONSTRAINT signing_authorization_matrix_pkey PRIMARY KEY (matrix_id);
    ADD CONSTRAINT signing_throughput_runs_pkey PRIMARY KEY (run_id);
    ADD CONSTRAINT sim_swap_alerts_formula_version_id_fkey FOREIGN KEY (formula_version_id) REFERENCES public.risk_formula_versions(formula_version_id) ON DELETE RESTRICT;
    ADD CONSTRAINT sim_swap_alerts_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(member_id) ON DELETE RESTRICT;
    ADD CONSTRAINT sim_swap_alerts_pkey PRIMARY KEY (alert_id);
    ADD CONSTRAINT sim_swap_alerts_source_event_id_fkey FOREIGN KEY (source_event_id) REFERENCES public.member_device_events(event_id) ON DELETE RESTRICT;
    ADD CONSTRAINT sim_swap_alerts_source_event_id_key UNIQUE (source_event_id);
    ADD CONSTRAINT sim_swap_alerts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT state_current_pkey PRIMARY KEY (project_id);
    ADD CONSTRAINT state_transitions_pkey PRIMARY KEY (transition_id);
    ADD CONSTRAINT supervisor_access_policies_pkey PRIMARY KEY (scope);
    ADD CONSTRAINT supervisor_approval_queue_pkey PRIMARY KEY (instruction_id);
    ADD CONSTRAINT supervisor_approval_queue_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT supervisor_audit_tokens_pkey PRIMARY KEY (token_id);
    ADD CONSTRAINT supervisor_audit_tokens_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT supervisor_audit_tokens_token_hash_key UNIQUE (token_hash);
    ADD CONSTRAINT supervisor_interrupt_audit_events_pkey PRIMARY KEY (event_id);
    ADD CONSTRAINT supervisor_interrupt_audit_events_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(program_id) ON DELETE RESTRICT;
    ADD CONSTRAINT supplier_registry_pkey PRIMARY KEY (tenant_id, supplier_id);
    ADD CONSTRAINT supplier_registry_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    ADD CONSTRAINT tenant_clients_pkey PRIMARY KEY (client_id);
    ADD CONSTRAINT tenant_clients_tenant_id_client_key_key UNIQUE (tenant_id, client_key);
    ADD CONSTRAINT tenant_clients_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT tenant_members_pkey PRIMARY KEY (member_id);
    ADD CONSTRAINT tenant_members_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id);
    ADD CONSTRAINT tenant_members_tenant_id_member_ref_key UNIQUE (tenant_id, member_ref);
    ADD CONSTRAINT tenant_registry_pkey PRIMARY KEY (id);
    ADD CONSTRAINT tenant_registry_tenant_id_key UNIQUE (tenant_id);
    ADD CONSTRAINT tenant_registry_tenant_key_key UNIQUE (tenant_key);
    ADD CONSTRAINT tenants_billable_client_fk FOREIGN KEY (billable_client_id) REFERENCES public.billable_clients(billable_client_id) NOT VALID;
    ADD CONSTRAINT tenants_billable_client_required_new_rows_chk CHECK ((billable_client_id IS NOT NULL)) NOT VALID;
    ADD CONSTRAINT tenants_parent_tenant_fk FOREIGN KEY (parent_tenant_id) REFERENCES public.tenants(tenant_id) NOT VALID;
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (tenant_id);
    ADD CONSTRAINT tenants_tenant_key_key UNIQUE (tenant_key);
    ADD CONSTRAINT unique_factor_code UNIQUE (factor_code);
    ADD CONSTRAINT unique_interpretation_per_project_time UNIQUE (project_id, interpretation_pack_code, effective_from);
    ADD CONSTRAINT unique_unit_pair UNIQUE (from_unit, to_unit);
    ADD CONSTRAINT unit_conversions_pkey PRIMARY KEY (conversion_id);
    ADD CONSTRAINT ux_attempts_outbox_attempt_no UNIQUE (outbox_id, attempt_no);
    ADD CONSTRAINT ux_billable_clients_client_key UNIQUE (client_key);
    ADD CONSTRAINT ux_evidence_pack_items_pack_hash UNIQUE (pack_id, artifact_hash);
    ADD CONSTRAINT ux_instruction_settlement_finality_instruction UNIQUE (instruction_id);
    ADD CONSTRAINT ux_pending_idempotency UNIQUE (instruction_id, idempotency_key);
    ADD CONSTRAINT ux_pending_participant_sequence UNIQUE (participant_id, sequence_id);
    ADD CONSTRAINT ux_pii_purge_events_request_event UNIQUE (purge_request_id, event_type);
    ADD CONSTRAINT ux_pii_vault_records_subject_token UNIQUE (subject_token);
    ADD CONSTRAINT ux_rail_truth_anchor_attempt_id UNIQUE (attempt_id);
    ADD CONSTRAINT ux_rail_truth_anchor_sequence_scope UNIQUE (rail_sequence_ref, rail_participant_id, rail_profile);
    ADD CONSTRAINT verifier_project_assignments_pkey PRIMARY KEY (assignment_id);
    ADD CONSTRAINT verifier_project_assignments_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE RESTRICT;
    ADD CONSTRAINT verifier_project_assignments_verifier_id_fkey FOREIGN KEY (verifier_id) REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT;
    ADD CONSTRAINT verifier_project_role_unique UNIQUE (verifier_id, project_id, assigned_role);
    ADD CONSTRAINT verifier_registry_pkey PRIMARY KEY (verifier_id);
    ADD CONSTRAINT verifier_registry_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT;
    AND (p.lease_expires_at IS NULL OR p.lease_expires_at <= NOW())
    AND COALESCE(submitted_by, '') <> v_actor;
    AND e.event_type = 'PURGED'
    AND idempotency_key = p_idempotency_key;
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
    BEGIN
    CASE WHEN v_state='FINALITY_CONFLICT' THEN 'HOLD_RELEASE' ELSE NULL END
    CASE WHEN v_state='FINALITY_CONFLICT' THEN now() ELSE NULL END,
    CASE WHEN v_state='SUSPENDED' THEN now() ELSE NULL END
    CASE v_action
    COALESCE(p_metadata, '{}'::jsonb),
    COALESCE(v_event.observed_at, NOW())
    COALESCE(v_source_member.metadata, '{}'::jsonb) || jsonb_build_object(
    CONSTRAINT adapter_registrations_checklist_refs_check CHECK ((jsonb_typeof(checklist_refs) = 'array'::text)),
    CONSTRAINT adapter_registrations_entrypoint_refs_check CHECK ((jsonb_typeof(entrypoint_refs) = 'array'::text)),
    CONSTRAINT adapter_registrations_issuance_semantic_mode_check CHECK ((issuance_semantic_mode = ANY (ARRAY['STRICT'::text, 'LENIENT'::text, 'HYBRID'::text]))),
    CONSTRAINT adapter_registrations_jurisdiction_compatibility_check CHECK ((jsonb_typeof(jurisdiction_compatibility) = 'object'::text)),
    CONSTRAINT adapter_registrations_payload_schema_refs_check CHECK ((jsonb_typeof(payload_schema_refs) = 'array'::text)),
    CONSTRAINT adapter_registrations_retirement_semantic_mode_check CHECK ((retirement_semantic_mode = ANY (ARRAY['STRICT'::text, 'LENIENT'::text, 'HYBRID'::text])))
    CONSTRAINT anchor_backfill_jobs_status_check CHECK ((status = ANY (ARRAY['STARTED'::text, 'COMPLETED'::text, 'FAILED'::text])))
    CONSTRAINT anchor_sync_operations_attempt_count_check CHECK ((attempt_count >= 0)),
    CONSTRAINT anchor_sync_operations_state_check CHECK ((state = ANY (ARRAY['PENDING'::text, 'ANCHORING'::text, 'ANCHORED'::text, 'COMPLETED'::text, 'FAILED'::text]))),
    CONSTRAINT archive_verification_runs_outcome_check CHECK ((outcome = ANY (ARRAY['PASS'::text, 'FAIL'::text]))),
    CONSTRAINT archive_verification_runs_years_covered_check CHECK ((years_covered >= 1))
    CONSTRAINT artifact_signing_batch_items_leaf_index_check CHECK ((leaf_index >= 0))
    CONSTRAINT artifact_signing_batches_total_artifacts_check CHECK ((total_artifacts > 0))
    CONSTRAINT asset_batches_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT asset_batches_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'ACTIVE'::text, 'RETIRED'::text, 'CANCELLED'::text])))
    CONSTRAINT billable_clients_client_type_check CHECK ((client_type = ANY (ARRAY['BANK'::text, 'MMO'::text, 'NGO'::text, 'GOV_PROGRAM'::text, 'COOP_FEDERATION'::text, 'ENTERPRISE'::text]))),
    CONSTRAINT billable_clients_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT billing_usage_events_event_type_check CHECK ((event_type = ANY (ARRAY['EVIDENCE_BUNDLE'::text, 'CASE_PACK'::text, 'EXCEPTION_TRIAGE'::text, 'RETENTION_ANCHOR'::text, 'ESCROW_RELEASE'::text, 'DISPUTE_PACK'::text]))),
    CONSTRAINT billing_usage_events_member_requires_tenant_chk CHECK (((subject_member_id IS NULL) OR (tenant_id IS NOT NULL))),
    CONSTRAINT billing_usage_events_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT billing_usage_events_subject_zero_or_one_chk CHECK (((((subject_member_id IS NOT NULL))::integer + ((subject_client_id IS NOT NULL))::integer) <= 1)),
    CONSTRAINT billing_usage_events_units_check CHECK ((units = ANY (ARRAY['count'::text, 'bytes'::text, 'seconds'::text, 'events'::text])))
    CONSTRAINT boz_operational_scenario_runs_outcome_check CHECK ((outcome = ANY (ARRAY['PASS'::text, 'FAIL'::text])))
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
    CONSTRAINT global_rate_limit_policies_interval_seconds_check CHECK ((interval_seconds > 0)),
    CONSTRAINT global_rate_limit_policies_max_requests_check CHECK ((max_requests > 0))
    CONSTRAINT inquiry_state_machine_max_attempts_check CHECK ((max_attempts > 0))
    CONSTRAINT instruction_settlement_finality_final_state_check CHECK ((final_state = ANY (ARRAY['SETTLED'::text, 'REVERSED'::text]))),
    CONSTRAINT instruction_settlement_finality_is_final_true_chk CHECK ((is_final = true)),
    CONSTRAINT instruction_settlement_finality_rail_message_type_check CHECK ((rail_message_type = ANY (ARRAY['pacs.008'::text, 'camt.056'::text]))),
    CONSTRAINT instruction_settlement_finality_self_reversal_chk CHECK (((reversal_of_instruction_id IS NULL) OR (reversal_of_instruction_id <> instruction_id))),
    CONSTRAINT instruction_settlement_finality_shape_chk CHECK ((((final_state = 'SETTLED'::text) AND (reversal_of_instruction_id IS NULL) AND (rail_message_type = 'pacs.008'::text)) OR ((final_state = 'REVERSED'::text) AND (reversal_of_instruction_id IS NOT NULL) AND (rail_message_type = 'camt.056'::text))))
    CONSTRAINT internal_ledger_journals_currency_code_check CHECK ((currency_code ~ '^[A-Z]{3}$'::text))
    CONSTRAINT internal_ledger_postings_amount_minor_check CHECK ((amount_minor > 0)),
    CONSTRAINT internal_ledger_postings_currency_code_check CHECK ((currency_code ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT internal_ledger_postings_direction_check CHECK ((direction = ANY (ARRAY['DEBIT'::text, 'CREDIT'::text])))
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
    CONSTRAINT methodology_versions_status_check CHECK ((status = ANY (ARRAY['DRAFT'::text, 'ACTIVE'::text, 'DEPRECATED'::text])))
    CONSTRAINT no_self_loop CHECK ((source_node_id <> target_node_id))
    CONSTRAINT participant_outbox_sequences_next_sequence_id_check CHECK ((next_sequence_id >= 1))
    CONSTRAINT participants_participant_kind_check CHECK ((participant_kind = ANY (ARRAY['BANK'::text, 'MMO'::text, 'NGO'::text, 'GOV_PROGRAM'::text, 'COOP_FEDERATION'::text, 'ENTERPRISE'::text, 'INTERNAL'::text]))),
    CONSTRAINT participants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT payment_outbox_attempts_attempt_no_check CHECK ((attempt_no >= 1)),
    CONSTRAINT payment_outbox_attempts_latency_ms_check CHECK (((latency_ms IS NULL) OR (latency_ms >= 0)))
    CONSTRAINT payment_outbox_pending_attempt_count_check CHECK ((attempt_count >= 0))
    CONSTRAINT persons_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text, 'SUSPENDED'::text])))
    CONSTRAINT pii_erasure_journal_status_check CHECK ((status = ANY (ARRAY['REQUESTED'::text, 'APPROVED'::text, 'COMPLETED'::text, 'FAILED'::text])))
    CONSTRAINT pii_purge_events_event_type_check CHECK ((event_type = ANY (ARRAY['REQUESTED'::text, 'PURGED'::text]))),
    CONSTRAINT pii_purge_events_rows_affected_check CHECK ((rows_affected >= 0))
    CONSTRAINT pii_vault_records_purge_shape_chk CHECK ((((purged_at IS NULL) AND (protected_payload IS NOT NULL) AND (purge_request_id IS NULL)) OR ((purged_at IS NOT NULL) AND (protected_payload IS NULL) AND (purge_request_id IS NOT NULL))))
    CONSTRAINT program_migration_events_from_to_chk CHECK ((from_program_id <> to_program_id))
    CONSTRAINT programme_registry_status_check CHECK ((status = ANY (ARRAY['CREATED'::text, 'ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT programs_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT projects_status_check CHECK ((status = ANY (ARRAY['DRAFT'::text, 'ACTIVE'::text, 'SUSPENDED'::text, 'RETIRED'::text])))
    CONSTRAINT proof_pack_batch_leaves_leaf_index_check CHECK ((leaf_index >= 0))
    CONSTRAINT proof_pack_batches_leaf_count_check CHECK ((leaf_count > 0))
    CONSTRAINT rail_truth_anchor_state_chk CHECK ((state = 'DISPATCHED'::public.outbox_attempt_state))
    CONSTRAINT reference_strategy_policy_versions_version_status_check CHECK ((version_status = ANY (ARRAY['ACTIVE'::text, 'INACTIVE'::text])))
    CONSTRAINT regulatory_incidents_severity_check CHECK ((severity = ANY (ARRAY['LOW'::text, 'MEDIUM'::text, 'HIGH'::text, 'CRITICAL'::text]))),
    CONSTRAINT regulatory_incidents_status_check CHECK ((status = ANY (ARRAY['OPEN'::text, 'UNDER_INVESTIGATION'::text, 'REPORTED'::text, 'CLOSED'::text])))
    CONSTRAINT resign_sweeps_artifacts_resigned_count_check CHECK ((artifacts_resigned_count >= 0))
    CONSTRAINT retirement_events_retired_quantity_check CHECK ((retired_quantity > (0)::numeric))
    CONSTRAINT risk_formula_versions_tier_check CHECK ((tier = ANY (ARRAY['TIER1'::text, 'TIER2'::text, 'TIER3'::text])))
    CONSTRAINT signing_audit_log_outcome_check CHECK ((outcome = ANY (ARRAY['PASS'::text, 'REJECTED'::text, 'BLOCKED'::text]))),
    CONSTRAINT signing_audit_log_signing_path_check CHECK ((signing_path = ANY (ARRAY['HSM'::text, 'KMS'::text, 'SOFTWARE_BYPASS'::text])))
    CONSTRAINT signing_authorization_matrix_key_backend_check CHECK ((key_backend = ANY (ARRAY['HSM'::text, 'KMS'::text, 'SOFTWARE'::text])))
    CONSTRAINT signing_throughput_runs_achieved_tps_check CHECK ((achieved_tps >= 0)),
    CONSTRAINT signing_throughput_runs_p95_latency_ms_check CHECK ((p95_latency_ms >= 0)),
    CONSTRAINT signing_throughput_runs_target_tps_check CHECK ((target_tps > 0))
    CONSTRAINT sim_swap_alerts_alert_type_check CHECK ((alert_type = 'SIM_SWAP_DETECTED'::text)),
    CONSTRAINT sim_swap_alerts_iccid_diff_chk CHECK ((prior_iccid_hash <> new_iccid_hash))
    CONSTRAINT supervisor_access_policies_hold_timeout_minutes_check CHECK (((hold_timeout_minutes IS NULL) OR (hold_timeout_minutes > 0))),
    CONSTRAINT supervisor_access_policies_read_window_minutes_check CHECK (((read_window_minutes IS NULL) OR (read_window_minutes > 0))),
    CONSTRAINT supervisor_access_policies_scope_check CHECK ((scope = ANY (ARRAY['READ_ONLY'::text, 'AUDIT'::text, 'APPROVAL_REQUIRED'::text])))
    CONSTRAINT supervisor_approval_queue_status_check CHECK ((status = ANY (ARRAY['PENDING_SUPERVISOR_APPROVAL'::text, 'APPROVED'::text, 'REJECTED'::text, 'TIMED_OUT'::text, 'ESCALATED'::text, 'RESET'::text])))
    CONSTRAINT supervisor_audit_tokens_scope_check CHECK ((scope = 'AUDIT'::text))
    CONSTRAINT supervisor_interrupt_audit_events_action_check CHECK ((action = ANY (ARRAY['ESCALATED'::text, 'ACKNOWLEDGED'::text, 'RESUMED'::text, 'RESET'::text]))),
    CONSTRAINT supervisor_interrupt_audit_events_queue_status_check CHECK ((queue_status = ANY (ARRAY['PENDING_SUPERVISOR_APPROVAL'::text, 'APPROVED'::text, 'REJECTED'::text, 'TIMED_OUT'::text, 'ESCALATED'::text, 'RESET'::text])))
    CONSTRAINT tenant_clients_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'REVOKED'::text])))
    CONSTRAINT tenant_members_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'EXITED'::text])))
    CONSTRAINT tenant_registry_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text])))
    CONSTRAINT tenants_status_check CHECK ((status = ANY (ARRAY['ACTIVE'::text, 'SUSPENDED'::text, 'CLOSED'::text]))),
    CONSTRAINT tenants_tenant_type_check CHECK ((tenant_type = ANY (ARRAY['NGO'::text, 'COOPERATIVE'::text, 'GOVERNMENT'::text, 'COMMERCIAL'::text])))
    CONSTRAINT verifier_deactivation_consistency CHECK ((((is_active = true) AND (deactivated_at IS NULL) AND (deactivation_reason IS NULL)) OR ((is_active = false) AND (deactivated_at IS NOT NULL) AND (deactivation_reason IS NOT NULL)))),
    CONSTRAINT verifier_project_assignments_assigned_role_check CHECK ((assigned_role = ANY (ARRAY['VALIDATOR'::text, 'VERIFIER'::text])))
    CONSTRAINT verifier_registry_role_type_check CHECK ((role_type = ANY (ARRAY['VALIDATOR'::text, 'VERIFIER'::text, 'VALIDATOR_VERIFIER'::text])))
    DO UPDATE
    ELSE
    ELSE
    ELSE
    ELSE
    ELSE
    ELSE
    ELSE 'gen_random_uuid'
    ELSIF p_target_record_type = 'ASSET_BATCH' THEN
    ELSIF p_target_record_type = 'EVIDENCE_NODE' THEN
    ELSIF p_target_record_type = 'MONITORING_RECORD' THEN
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
    END,
    END;
    END;
    EXCEPTION
    EXCEPTION
    FOR UPDATE SKIP LOCKED
    FOR UPDATE;
    FOR v_record IN
    FROM jsonb_array_elements(p_postings)
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
    FROM public.internal_ledger_postings
    FROM public.interpretation_packs
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
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF (v_total_retired + v_retire_qty) >= v_batch_quantity THEN
    IF EXISTS (
    IF FOUND THEN
    IF FOUND THEN
    IF NEW.execution_id IS NULL THEN
    IF NEW.policy_decision_id IS NULL THEN
    IF NEW.signature IS NULL THEN
    IF NOT (p_edge_type = ANY(v_valid_edge_types)) THEN
    IF NOT (p_evidence_class = ANY(v_valid_classes)) THEN
    IF NOT (p_subject_type = ANY(v_valid_subject_types)) THEN
    IF NOT (p_subject_type = ANY(v_valid_subject_types)) THEN
    IF NOT (p_target_record_type = ANY(v_valid_target_types)) THEN
    IF NOT EXISTS (
    IF NOT FOUND THEN
    IF NOT v_collision THEN
    IF NOT v_payload_valid THEN
    IF TG_OP = 'DELETE' THEN
    IF TG_OP = 'DELETE' THEN
    IF TG_OP = 'DELETE' THEN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND (OLD.execution_id IS DISTINCT FROM NEW.execution_id OR OLD.signature IS DISTINCT FROM NEW.signature)) THEN
    IF TG_OP = 'UPDATE' AND OLD.data_authority IS DISTINCT FROM NEW.data_authority THEN
    IF TG_OP = 'UPDATE' AND OLD.data_authority IS DISTINCT FROM NEW.data_authority THEN
    IF TG_OP = 'UPDATE' AND OLD.data_authority IS DISTINCT FROM NEW.data_authority THEN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
    IF TG_OP = 'UPDATE' THEN
    IF TG_OP = 'UPDATE' THEN
    IF TG_OP = 'UPDATE' THEN
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
    IF current_setting('symphony.allow_pii_purge', true) = 'on' THEN
    IF jsonb_typeof(p_payload) != 'object' THEN
    IF p_adapter_registration_id IS NULL THEN
    IF p_asset_batch_id IS NULL THEN
    IF p_asset_batch_id IS NULL THEN
    IF p_asset_batch_id IS NULL THEN
    IF p_asset_batch_id IS NULL THEN
    IF p_asset_type IS NULL THEN
    IF p_decision_outcome IS NULL OR trim(p_decision_outcome) = '' THEN
    IF p_decision_type IS NULL OR trim(p_decision_type) = '' THEN
    IF p_document_type IS NULL OR trim(p_document_type) = '' THEN
    IF p_edge_type IS NULL OR trim(p_edge_type) = '' THEN
    IF p_event_timestamp IS NULL THEN
    IF p_event_type IS NULL THEN
    IF p_evidence_class IS NULL OR trim(p_evidence_class) = '' THEN
    IF p_evidence_node_id = p_target_evidence_node_id THEN
    IF p_evidence_node_id IS NULL THEN
    IF p_from_status IS NULL THEN
    IF p_from_status IS NULL THEN
    IF p_interpretation_pack_id IS NULL THEN
    IF p_interpretation_pack_id IS NULL THEN
    IF p_interpretation_pack_id IS NULL THEN
    IF p_jurisdiction_code IS NOT NULL THEN
    IF p_jurisdiction_code IS NULL OR trim(p_jurisdiction_code) = '' THEN
    IF p_jurisdiction_code IS NULL OR trim(p_jurisdiction_code) = '' THEN
    IF p_methodology_version_id IS NULL THEN
    IF p_methodology_version_id IS NULL THEN
    IF p_methodology_version_id IS NULL THEN
    IF p_monitoring_record_id IS NULL THEN
    IF p_payload_schema_reference_id IS NULL THEN
    IF p_payload_schema_reference_id IS NULL THEN
    IF p_project_id IS NULL THEN
    IF p_project_id IS NULL THEN
    IF p_project_id IS NULL THEN
    IF p_project_id IS NULL THEN
    IF p_project_id IS NULL THEN
    IF p_project_id IS NULL THEN
    IF p_project_id IS NULL THEN
    IF p_project_id IS NULL THEN
    IF p_project_name IS NULL OR trim(p_project_name) = '' THEN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
    IF p_record_payload_json IS NULL THEN
    IF p_record_type IS NULL OR trim(p_record_type) = '' THEN
    IF p_regulatory_authority_id IS NULL THEN
    IF p_requested_role = 'VERIFIER' THEN
    IF p_retirement_reason IS NULL THEN
    IF p_state = 'RETRYABLE' AND v_next_attempt_no >= public.outbox_retry_ceiling() THEN
    IF p_state NOT IN ('DISPATCHED', 'FAILED', 'RETRYABLE') THEN
    IF p_subject_id IS NULL THEN
    IF p_subject_id IS NULL THEN
    IF p_subject_id IS NULL THEN
    IF p_subject_type IS NULL OR trim(p_subject_type) = '' THEN
    IF p_subject_type IS NULL THEN
    IF p_target_evidence_node_id IS NULL THEN
    IF p_target_record_id IS NULL THEN
    IF p_target_record_type = 'PROJECT' THEN
    IF p_target_record_type IS NULL OR trim(p_target_record_type) = '' THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_tenant_id IS NULL THEN
    IF p_to_status IS NULL THEN
    IF p_to_status IS NULL THEN
    IF p_to_status IS NULL THEN
    IF p_token_hash IS NULL THEN
    IF p_token_id IS NULL THEN
    IF p_ttl_hours IS NULL OR p_ttl_hours <= 0 OR p_ttl_hours > 8760 THEN
    IF p_unit IS NULL THEN
    IF p_verifier_id IS NULL THEN
    IF p_verifier_id IS NULL THEN
    IF v_adapter_active != true THEN
    IF v_adapter_active IS NULL THEN
    IF v_adapter_registration_id IS NULL THEN
    IF v_approved_count = 0 THEN
    IF v_attempt > v_strategy.nonce_retry_limit THEN
    IF v_authority_jcode != p_jurisdiction_code THEN
    IF v_authority_jcode IS NULL THEN
    IF v_batch_status != 'ISSUED' THEN
    IF v_batch_status IS NULL THEN
    IF v_conditional_count > 0 THEN
    IF v_confidence_score < v_required_threshold THEN
    IF v_current_status != 'DRAFT' THEN
    IF v_current_status IS NULL THEN
    IF v_current_status IS NULL THEN
    IF v_decision_count = 0 THEN
    IF v_effective_state IN ('DISPATCHED', 'FAILED') THEN
    IF v_jurisdiction_code IS NOT NULL THEN
    IF v_project_status != 'ACTIVE' THEN
    IF v_project_status != 'ACTIVE' THEN
    IF v_project_status IS NULL THEN
    IF v_project_status IS NULL THEN
    IF v_retire_qty <= 0 THEN
    IF v_retire_qty > v_remaining_quantity THEN
    IF v_source_tenant != p_tenant_id THEN
    IF v_source_tenant IS NULL THEN
    IF v_strategy.strategy_type = 'SUFFIX' THEN
    IF v_target_tenant IS NULL OR v_target_tenant != p_tenant_id THEN
    IF v_to_status IS NULL OR v_to_status != 'ISSUED' THEN
    IF v_unsatisfied_checkpoints > 0 THEN
    IF v_verifier_active != true THEN
    IF v_verifier_active IS NULL THEN
    INSERT INTO asset_batches (
    INSERT INTO asset_lifecycle_events (
    INSERT INTO asset_lifecycle_events (
    INSERT INTO asset_lifecycle_events (
    INSERT INTO authority_decisions (
    INSERT INTO evidence_edges (
    INSERT INTO evidence_nodes (
    INSERT INTO monitoring_records (
    INSERT INTO participant_outbox_sequences(participant_id, next_sequence_id)
    INSERT INTO payment_outbox_attempts (
    INSERT INTO public.dispatch_reference_collision_events(
    INSERT INTO public.effect_seal_mismatch_events(instruction_id, stored_seal_hash, computed_dispatch_hash)
    INSERT INTO public.effect_seal_mismatch_events(instruction_id, stored_seal_hash, computed_dispatch_hash)
    INSERT INTO public.gf_verifier_read_tokens (
    INSERT INTO public.internal_ledger_postings(
    INSERT INTO public.members(
    INSERT INTO public.offline_safe_mode_windows(reason, policy_version_id, gap_marker_id)
    INSERT INTO public.program_migration_events(
    INSERT INTO public.projects (tenant_id, name, status)
    INSERT INTO retirement_events (
    INSERT INTO state_current (project_id, current_state, state_since)
    INTO derived_billable_client_id
    INTO derived_tenant_id
    INTO existing_attempt
    INTO existing_pending
    INTO v_alert_id
    INTO v_existing
    INTO v_existing_hash, v_existing_version
    INTO v_instruction_id, v_participant_id, v_sequence_id, v_idempotency_key, v_rail_type, v_payload
    INTO v_journal_tenant, v_journal_currency
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
    LANGUAGE sql STABLE
    LANGUAGE sql STABLE SECURITY DEFINER
    LIMIT 1
    LIMIT 1;
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
    ON CONFLICT (project_id) DO UPDATE SET
    ON CONFLICT (tenant_id, person_id, from_program_id, to_program_id) DO NOTHING;
    ON DELETE TO public.kyc_retention_policy DO INSTEAD NOTHING;
    ON UPDATE TO public.kyc_retention_policy DO INSTEAD NOTHING;
    OR (v_row.state = 'AUTHORIZED' AND v_to_state IN ('RELEASE_REQUESTED', 'CANCELED', 'EXPIRED'))
    OR (v_row.state = 'RELEASE_REQUESTED' AND v_to_state IN ('RELEASED', 'CANCELED', 'EXPIRED'))
    ORDER BY a.claimed_at DESC
    ORDER BY effective_from DESC
    ORDER BY o.updated_at, o.created_at
    PERFORM pg_advisory_xact_lock(
    PERFORM pg_notify('symphony_outbox', '');
    PERFORM public.check_reg26_separation(p_verifier_id, p_project_id, 'VERIFIER');
    PERFORM public.guard_settlement_requires_acknowledgement(NEW.instruction_id);
    PERFORM public.record_monitoring_record(
    PERFORM public.record_monitoring_record(
    PERFORM public.transition_asset_status(p_tenant_id, p_project_id, 'ACTIVE');
    PERFORM public.transition_asset_status(p_tenant_id, p_subject_id, p_to_status);
    PERFORM public.transition_escrow_state(
    RAISE EXCEPTION '% is append-only', TG_TABLE_NAME
    RAISE EXCEPTION 'ACKNOWLEDGEMENT_REQUIRED_BEFORE_SETTLEMENT' USING ERRCODE = 'P7301';
    RAISE EXCEPTION 'ADAPTER_SUSPENDED_CIRCUIT_BREAKER' USING ERRCODE = 'P7401';
    RAISE EXCEPTION 'ADJUSTMENT_CEILING_BREACH' USING ERRCODE = 'P7201';
    RAISE EXCEPTION 'ADJUSTMENT_COOLING_OFF_ACTIVE' USING ERRCODE = 'P7701';
    RAISE EXCEPTION 'ADJUSTMENT_FREEZE_BLOCK' USING ERRCODE = 'P7702';
    RAISE EXCEPTION 'ADJUSTMENT_TERMINAL_IMMUTABLE' USING ERRCODE = 'P7101';
    RAISE EXCEPTION 'INQUIRY_EXHAUSTED_AUTO_FINALIZE_BLOCKED' USING ERRCODE = 'P7301';
    RAISE EXCEPTION 'OFFLINE_SAFE_MODE_ACTIVE' USING ERRCODE = 'P7501';
    RAISE EXCEPTION 'acknowledgement_state_not_found' USING ERRCODE = 'P7300';
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
    RAISE EXCEPTION 'cross-tenant posting rejected'
    RAISE EXCEPTION 'dispatch requires rail sequence reference'
    RAISE EXCEPTION 'duplicate migration call for tenant %, person %, from %, to %',
    RAISE EXCEPTION 'effect_seal_immutable_violation' USING ERRCODE = 'P7102';
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
    RAISE EXCEPTION 'from_program_id % is not in tenant %', p_from_program_id, p_tenant_id
    RAISE EXCEPTION 'from_program_id % is not in tenant %', p_from_program_id, p_tenant_id
    RAISE EXCEPTION 'from_program_id and to_program_id must differ'
    RAISE EXCEPTION 'from_program_id and to_program_id must differ'
    RAISE EXCEPTION 'illegal escrow transition: % -> %', v_row.state, v_to_state
    RAISE EXCEPTION 'illegal_escalation_from_state:%', v_state USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'illegal_interrupt_resolution_state:%', v_state USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'illegal_transition_from_terminal_inquiry_state:%', v_state USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'illegal_transition_to_acknowledged_from:%', v_state USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'ingress_attestations is append-only'
    RAISE EXCEPTION 'inquiry_not_found' USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'instruction % is not pending supervisor approval', p_instruction_id;
    RAISE EXCEPTION 'instruction settlement rows must be final'
    RAISE EXCEPTION 'invalid decision %', p_decision;
    RAISE EXCEPTION 'invalid reservation amount %', v_amount
    RAISE EXCEPTION 'invalid target escrow state %', v_to_state
    RAISE EXCEPTION 'invalid_interrupt_action:%', p_action USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'invalid_max_attempts' USING ERRCODE = 'P7302';
    RAISE EXCEPTION 'journal is not balanced'
    RAISE EXCEPTION 'journal not found for posting'
    RAISE EXCEPTION 'lease seconds must be > 0' USING ERRCODE = 'P7210';
    RAISE EXCEPTION 'member-to-device linkage invalid'
    RAISE EXCEPTION 'member/tenant mismatch'
    RAISE EXCEPTION 'member_device_event % not found', p_event_id
    RAISE EXCEPTION 'member_id not found'
    RAISE EXCEPTION 'missing_effect_seal' USING ERRCODE = 'P7102';
    RAISE EXCEPTION 'missing_effect_seal' USING ERRCODE = 'P7102';
    RAISE EXCEPTION 'new_entity_id must equal to_program_id'
    RAISE EXCEPTION 'no program available for supervisor approval submission';
    RAISE EXCEPTION 'orphan_replay_containment_reject' USING ERRCODE = 'P7503';
    RAISE EXCEPTION 'p_postings must contain at least two postings'
    RAISE EXCEPTION 'pack_id is required' USING ERRCODE = 'P7210';
    RAISE EXCEPTION 'participant-to-program linkage invalid'
    RAISE EXCEPTION 'payment_outbox_attempts is append-only'
    RAISE EXCEPTION 'person_id % is not in tenant %', p_person_id, p_tenant_id
    RAISE EXCEPTION 'pii_vault_records updates require purge executor'
    RAISE EXCEPTION 'posting currency must match journal currency'
    RAISE EXCEPTION 'program-to-entity linkage invalid'
    RAISE EXCEPTION 'purge request not found: %', p_purge_request_id
    RAISE EXCEPTION 'reversal requires existing instruction %', NEW.reversal_of_instruction_id
    RAISE EXCEPTION 'reversal source instruction must be final and SETTLED: %', NEW.reversal_of_instruction_id
    RAISE EXCEPTION 'revocation tables are append-only'
    RAISE EXCEPTION 'source member not found for tenant %, person %, program %', p_tenant_id, p_person_id, p_from_program_id
    RAISE EXCEPTION 'source member not found for tenant %, person %, program %', p_tenant_id, p_person_id, p_from_program_id
    RAISE EXCEPTION 'supervisor_interrupt_not_found' USING ERRCODE = 'P7300';
    RAISE EXCEPTION 'tenant-to-participant linkage invalid for instruction'
    RAISE EXCEPTION 'tenant_id required when member_id is set'
    RAISE EXCEPTION 'to_program_id % is not in tenant %', p_to_program_id, p_tenant_id
    RAISE EXCEPTION 'to_program_id % is not in tenant %', p_to_program_id, p_tenant_id
    RAISE EXCEPTION 'unsupported_mmo_scenario' USING ERRCODE = 'P7502';
    RAISE EXCEPTION 'worker_id is required' USING ERRCODE = 'P7210';
    RAISE EXCEPTION USING
    RAISE EXCEPTION USING
    RAISE EXCEPTION USING ERRCODE='P7802', MESSAGE='REFERENCE_STRATEGY_POLICY_NOT_FOUND';
    RAISE EXCEPTION USING ERRCODE='P7802', MESSAGE='REFERENCE_STRATEGY_POLICY_NOT_FOUND';
    RAISE EXCEPTION USING ERRCODE='P7901', MESSAGE='REFERENCE_LENGTH_EXCEEDED';
    RAISE EXCEPTION USING ERRCODE='P8001', MESSAGE='REFERENCE_NOT_REGISTERED';
    RAISE EXCEPTION USING ERRCODE='P8101', MESSAGE='KEY_CLASS_UNAUTHORIZED';
    RAISE EXCEPTION USING ERRCODE='P8102', MESSAGE='HSM_BYPASS_BLOCKED';
    RAISE EXCEPTION USING ERRCODE='P8201', MESSAGE='POLICY_BUNDLE_UNSIGNED';
    RAISE EXCEPTION USING ERRCODE='P8202', MESSAGE='POLICY_BUNDLE_VERIFICATION_FAILED';
    RAISE EXCEPTION USING ERRCODE='P8301', MESSAGE='UNVERIFIABLE_MISSING_CANONICALIZER';
    RAISE EXCEPTION USING ERRCODE='P8302', MESSAGE='MERKLE_LEAF_NOT_FOUND';
    RAISE EXCEPTION USING ERRCODE='P8303', MESSAGE='MERKLE_LEAF_HASH_MISMATCH';
    RAISE EXCEPTION USING ERRCODE='P8303', MESSAGE='MERKLE_LEAF_HASH_MISMATCH';
    RAISE EXCEPTION USING ERRCODE='P8401', MESSAGE='HSM_FAIL_CLOSED_ENFORCED';
    RAISE EXCEPTION USING ERRCODE='P8402', MESSAGE='RATE_LIMIT_BREACH_BLOCKED';
    RAISE EXCEPTION USING ERRCODE='P8403', MESSAGE='RETRACTION_SECONDARY_APPROVAL_REQUIRED';
    RAISE EXCEPTION USING ERRCODE='P8404', MESSAGE='PII_PRESENT_IN_PENALTY_DEFENSE_PACK';
    RAISE NOTICE 'Transition state rules check: % -> %', NEW.from_state, NEW.to_state;
    RETURN 'EXHAUSTED';
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
    RETURN NEW;
    RETURN NEW;
    RETURN NEW;
    RETURN NEW;
    RETURN NULL;
    RETURN NULL;
    RETURN NULL;
    RETURN NULL;
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY
    RETURN QUERY SELECT existing_pending.outbox_id, existing_pending.sequence_id, existing_pending.created_at, 'PENDING';
    RETURN QUERY SELECT p_project_id, 'ACTIVE'::TEXT;
    RETURN QUERY SELECT p_purge_request_id, v_prior, TRUE;
    RETURN QUERY SELECT v_confidence, v_threshold, v_total, v_approved,
    RETURN QUERY SELECT v_next_attempt_no, v_effective_state;
    RETURN QUERY SELECT v_project_id, 'DRAFT'::TEXT;
    RETURN QUERY SELECT v_token_id, v_token_secret, v_expires_at;
    RETURN allocated;
    RETURN v::uuid;
    RETURN v_asset_batch_id;
    RETURN v_count;
    RETURN v_decision_id;
    RETURN v_edge_id;
    RETURN v_evidence_node_id;
    RETURN v_existing;
    RETURN v_hash;
    RETURN v_interpretation_pack_id;
    RETURN v_lifecycle_event_id;
    RETURN v_monitoring_record_id;
    RETURN v_payload;
    RETURN v_result_state;
    RETURN v_retirement_event_id;
    RETURN v_schema_exists;
    RETURN v_state;
    RETURN;
    RETURN;
    RETURNING (participant_outbox_sequences.next_sequence_id - 1) INTO allocated;
    RETURNING asset_batch_id INTO v_asset_batch_id;
    RETURNING authority_decision_id INTO v_decision_id;
    RETURNING evidence_edge_id INTO v_edge_id;
    RETURNING evidence_node_id INTO v_evidence_node_id;
    RETURNING gf_verifier_read_tokens.token_id INTO v_token_id;
    RETURNING lifecycle_event_id INTO v_lifecycle_event_id;
    RETURNING member_id INTO v_target_member_id;
    RETURNING monitoring_record_id INTO v_monitoring_record_id;
    RETURNING public.projects.project_id INTO v_project_id;
    RETURNING retirement_event_id INTO v_retirement_event_id;
    SELECT
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
    SELECT COALESCE(
    SELECT COALESCE(
    SELECT COALESCE(MAX(a.attempt_no), 0) + 1 INTO v_next_attempt_no
    SELECT COALESCE(SUM(re.retired_quantity), 0)
    SELECT COUNT(*)
    SELECT COUNT(*),
    SELECT COUNT(*),
    SELECT EXISTS(
    SELECT a.outbox_id, a.sequence_id, a.created_at, a.state
    SELECT ab.asset_batch_id, ab.batch_type, ab.quantity, ab.status,
    SELECT ab.asset_batch_id, ab.project_id, ab.batch_type,
    SELECT ab.status, ab.quantity
    SELECT ad.authority_decision_id,
    SELECT ar.is_active INTO v_adapter_active
    SELECT e.escrow_id
    SELECT en.evidence_node_id,
    SELECT en.evidence_node_id,
    SELECT en.evidence_node_id,
    SELECT en.tenant_id INTO v_source_tenant
    SELECT en.tenant_id INTO v_target_tenant
    SELECT interpretation_pack_id INTO v_interpretation_pack_id
    SELECT lcr.lifecycle_checkpoint_rule_id,
    SELECT mr.monitoring_record_id,
    SELECT mr.record_payload_json
    SELECT mv.adapter_registration_id
    SELECT o.operation_id
    SELECT operation_id INTO v_operation_id
    SELECT p.instruction_id, p.participant_id, p.sequence_id, p.idempotency_key, p.rail_type, p.payload
    SELECT p.jurisdiction_code INTO v_jurisdiction_code
    SELECT p.outbox_id, p.sequence_id, p.created_at
    SELECT p.project_id, p.name, p.status, p.created_at
    SELECT p.project_id, p.name, p.status, p.created_at
    SELECT p.status
    SELECT p.status
    SELECT p.status INTO v_current_status
    SELECT p.status INTO v_project_status
    SELECT ra.jurisdiction_code INTO v_authority_jcode
    SELECT s.alert_id
    SELECT t.token_id, t.project_id, t.scoped_tables,
    SELECT t.token_id, t.verifier_id, t.scoped_tables, t.expires_at
    SELECT value
    SELECT vr.is_active, vr.methodology_scope
    SET attempts = v_attempts,
    SET finality_state = EXCLUDED.finality_state,
    SET inquiry_state = 'ACKNOWLEDGED'
    SET inquiry_state = 'AWAITING_EXECUTION'
    SET inquiry_state = 'AWAITING_EXECUTION'
    SET inquiry_state = 'AWAITING_EXECUTION',
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
    SET status = 'APPROVED',
    SET status = 'APPROVED',
    SET status = 'RESET',
    UPDATE public.gf_verifier_read_tokens
    UPDATE public.gf_verifier_read_tokens
    UPDATE public.inquiry_state_machine
    UPDATE public.inquiry_state_machine
    UPDATE public.inquiry_state_machine
    UPDATE public.inquiry_state_machine
    UPDATE public.projects
    UPDATE public.supervisor_approval_queue
    UPDATE public.supervisor_approval_queue
    UPDATE public.supervisor_approval_queue
    USING ERRCODE = 'P0001';
    USING ERRCODE = 'P0001';
    USING ERRCODE = 'P7004';
    VALUES (NEW.project_id, NEW.to_state, NEW.transition_timestamp)
    VALUES (p_instruction_id, v_existing_hash, v_hash);
    VALUES (p_instruction_id, v_stored_hash, v_computed_hash);
    VALUES (p_participant_id, 2)
    VALUES (p_reason, p_policy_version_id, md5(p_reason || '|' || now()::text));
    VALUES (p_tenant_id, trim(p_project_name), 'DRAFT')
    WHEN to_regprocedure('public.uuidv7()') IS NOT NULL THEN 'uuidv7'
    WHERE
    WHERE a.instruction_id = p_instruction_id
    WHERE e.tenant_id = p_tenant_id
    WHERE ia.instruction_id = p_instruction_id
    WHERE instruction_id = p_instruction_id;
    WHERE instruction_id = p_instruction_id;
    WHERE instruction_id = p_instruction_id;
    WHERE instruction_id = p_instruction_id;
    WHERE instruction_id = p_instruction_id;
    WHERE instruction_id = p_instruction_id;
    WHERE instruction_id = p_instruction_id;
    WHERE journal_id = p_journal_id
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
    WHERE project_id = p_project_id
    WHERE r.rail_id = p_rail_id
    WHERE s.source_event_id = v_event.event_id;
    ];
    ];
    ];
    account_code text NOT NULL,
    accreditation_authority text NOT NULL,
    accreditation_expiry date NOT NULL,
    accreditation_reference text NOT NULL,
    achieved_tps integer NOT NULL,
    action text NOT NULL,
    action text NOT NULL,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    activated_at timestamp with time zone DEFAULT now() NOT NULL,
    activation_timestamp timestamp with time zone,
    active boolean DEFAULT true NOT NULL
    active boolean DEFAULT true NOT NULL,
    active_from date,
    active_member_count bigint DEFAULT 0 NOT NULL,
    active_to date,
    actor text NOT NULL,
    actor_id text DEFAULT CURRENT_USER NOT NULL,
    actor_id text DEFAULT CURRENT_USER NOT NULL,
    actor_id text NOT NULL,
    adapter_code text NOT NULL,
    adapter_id text NOT NULL,
    adapter_id text NOT NULL,
    adapter_id, rail_id, classification, truncation_applied, payload_hash,
    adapter_id, rail_id, state, trigger_threshold, observed_rate,
    adapter_registration_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    adapter_registration_id uuid NOT NULL,
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
    allowed boolean DEFAULT true NOT NULL,
    amount_minor bigint DEFAULT 0 NOT NULL,
    amount_minor bigint NOT NULL,
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
    approval_id uuid DEFAULT gen_random_uuid() NOT NULL,
    approval_stage text NOT NULL,
    approved_at timestamp with time zone DEFAULT now() NOT NULL
    approved_at timestamp with time zone,
    approved_at timestamp with time zone,
    approved_by text,
    approver_id text NOT NULL,
    approver_role text NOT NULL,
    archival_confirmed boolean DEFAULT false NOT NULL,
    archive_only boolean DEFAULT true NOT NULL,
    arrival_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    artifact_class text NOT NULL,
    artifact_hash text NOT NULL,
    artifact_id text NOT NULL,
    artifact_id text NOT NULL,
    artifact_path text,
    artifact_type text NOT NULL,
    artifacts_resigned_count integer NOT NULL,
    artifacts_with_pending_tier_assignment_cleared boolean DEFAULT false CONSTRAINT resign_sweeps_artifacts_with_pending_tier_assignment_c_not_null NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    as_of_utc timestamp with time zone DEFAULT now() NOT NULL,
    asset_batch_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    asset_batch_id uuid NOT NULL,
    asset_batch_id uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    assigned_role text NOT NULL,
    assignment_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    assurance_tier text NOT NULL,
    assurance_tier text,
    assurance_tier, signing_path, outcome
    attempt_count integer DEFAULT 0 NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    attempt_id uuid DEFAULT gen_random_uuid() NOT NULL,
    attempt_id uuid DEFAULT gen_random_uuid() NOT NULL,
    attempt_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    attempt_id uuid NOT NULL,
    attempt_id,
    attempt_no integer NOT NULL,
    attempt_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    attempted_at timestamp with time zone DEFAULT now() NOT NULL
    attempts integer DEFAULT 0 NOT NULL,
    attestation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    attestation_id uuid NOT NULL,
    attestation_id uuid NOT NULL,
    attestation_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    audit_grade boolean NOT NULL,
    audit_grade boolean NOT NULL,
    audit_grade boolean NOT NULL,
    authority_decision_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    authority_explanation text NOT NULL
    authority_explanation text NOT NULL
    authority_explanation text NOT NULL,
    authority_name text NOT NULL,
    authority_reference text NOT NULL,
    authority_type text NOT NULL,
    authorization_expires_at timestamp with time zone,
    authorized_amount_minor bigint DEFAULT 0 NOT NULL,
    authorized_amount_minor bigint NOT NULL,
    batch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    batch_id uuid NOT NULL,
    batch_type text NOT NULL,
    behavior_profile text NOT NULL,
    behavior_profile, evidence_artifact_type
    billable_client_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    billable_client_id uuid NOT NULL,
    billable_client_id uuid,
    billable_client_id uuid,
    block_end timestamp with time zone,
    block_start timestamp with time zone DEFAULT now() NOT NULL,
    blocked_action text NOT NULL,
    bound_at timestamp with time zone DEFAULT now() NOT NULL
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
    canonicalization_version text CONSTRAINT canonicalization_archive_snap_canonicalization_version_not_null NOT NULL,
    canonicalization_version text NOT NULL,
    canonicalization_version text NOT NULL,
    canonicalization_version text NOT NULL,
    canonicalization_version text,
    canonicalization_version, signing_service_id, trust_chain_ref,
    canonicalization_versions_covered text[] CONSTRAINT archive_verification_runs_canonicalization_versions_co_not_null NOT NULL,
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
    chain_id uuid DEFAULT gen_random_uuid() NOT NULL,
    checklist_refs jsonb DEFAULT '[]'::jsonb NOT NULL,
    checkpoint_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    checkpoint_type text NOT NULL,
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
    completed_at timestamp with time zone,
    completed_at timestamp with time zone,
    computed_dispatch_hash text NOT NULL,
    containment_action text,
    contains_raw_pii boolean DEFAULT false NOT NULL,
    contradiction_timestamp timestamp with time zone,
    contradiction_timestamp, containment_action
    conversion_factor numeric NOT NULL,
    conversion_id uuid DEFAULT gen_random_uuid() NOT NULL,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    correlation_id uuid,
    count(DISTINCT person_id) AS unique_beneficiaries
    created_at
    created_at timestamp with time zone DEFAULT now()
    created_at timestamp with time zone DEFAULT now()
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
    created_at timestamp with time zone DEFAULT now() NOT NULL
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
    created_by text DEFAULT CURRENT_USER NOT NULL,
    currency_code character(3) DEFAULT 'USD'::bpchar NOT NULL,
    currency_code character(3) DEFAULT 'ZMW'::bpchar NOT NULL,
    currency_code character(3) NOT NULL,
    currency_code character(3) NOT NULL,
    currency_code character(3),
    currency_code text NOT NULL,
    currency_code text NOT NULL,
    current_hash text NOT NULL,
    current_state character varying NOT NULL,
    current_user,
    data_authority public.data_authority_level NOT NULL,
    data_authority public.data_authority_level NOT NULL,
    data_authority public.data_authority_level NOT NULL,
    db_access boolean NOT NULL,
    deactivated_at timestamp with time zone,
    deactivation_reason text,
    decided_at timestamp with time zone,
    decided_at, decided_by, decision_reason, approved_by, approved_at
    decided_by text,
    decision_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    decision_reason text,
    decision_type text NOT NULL,
    department_at_time_of_signing text NOT NULL,
    deprecated_at timestamp with time zone,
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
    direction text NOT NULL,
    dispatch_attempted_at timestamp with time zone,
    dispatch_blocked boolean DEFAULT true NOT NULL,
    dispatch_reference text,
    display_name text NOT NULL,
    display_name text NOT NULL,
    display_name text NOT NULL,
    document_type text,
    domain text NOT NULL,
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
    edge_type text NOT NULL,
    effect_seal_hash text NOT NULL,
    effective_from date NOT NULL,
    effective_from timestamp with time zone,
    effective_to date,
    effective_to timestamp with time zone
    endpoint text NOT NULL,
    enrolled_at timestamp with time zone DEFAULT now() NOT NULL,
    enrolled_at,
    entity_id text,
    entity_id uuid NOT NULL,
    entity_id,
    entrypoint_refs jsonb DEFAULT '[]'::jsonb NOT NULL,
    erasure_id uuid DEFAULT gen_random_uuid() NOT NULL,
    error_code text NOT NULL,
    error_code text,
    error_code text,
    error_message text,
    escalated_at timestamp with time zone,
    escrow_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    escrow_id uuid NOT NULL,
    escrow_id uuid NOT NULL,
    escrow_id uuid NOT NULL,
    event_fingerprint
    event_fingerprint
    event_fingerprint text NOT NULL
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    event_payload jsonb NOT NULL,
    event_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    event_timestamp timestamp with time zone DEFAULT now() NOT NULL
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type text NOT NULL,
    event_type,
    event_type,
    evidence_artifact_type text NOT NULL,
    evidence_edge_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    evidence_node_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    evidence_path text,
    evidence_ref text NOT NULL,
    execution_id uuid DEFAULT gen_random_uuid() NOT NULL,
    execution_id uuid,
    execution_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    existing_attempt RECORD;
    existing_pending RECORD;
    expired_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone,
    expires_at timestamp with time zone,
    expires_at timestamp with time zone,
    exportable boolean DEFAULT false NOT NULL,
    factor_code character varying NOT NULL,
    factor_id uuid DEFAULT gen_random_uuid() NOT NULL,
    factor_name character varying NOT NULL,
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
    from_state character varying NOT NULL,
    from_unit character varying NOT NULL,
    gap_marker_id text NOT NULL,
    generated_at timestamp with time zone DEFAULT now() NOT NULL
    generated_at timestamp with time zone DEFAULT now() NOT NULL
    grace_expires_at timestamp with time zone,
    hash_algorithm text,
    held_at timestamp with time zone DEFAULT now() NOT NULL,
    held_reason text,
    high_risk boolean DEFAULT false NOT NULL,
    hold_timeout_minutes integer,
    hsm_key_ref text NOT NULL,
    iccid_hash text,
    iccid_hash text,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    idempotency_key text NOT NULL,
    idempotency_key text NOT NULL,
    idempotency_key text NOT NULL,
    idempotency_key text NOT NULL,
    idempotency_key text,
    identity_hash text NOT NULL,
    immutable boolean DEFAULT true NOT NULL,
    incident_event_id uuid NOT NULL,
    incident_id uuid NOT NULL,
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
    instruction_id, inquiry_state, attempts, max_attempts, policy_version_id
    instruction_id, program_id, action, queue_status, actor, reason
    instruction_id, program_id, action, queue_status, actor, reason
    instruction_id, program_id, status, held_at, held_reason, timeout_at, submitted_by,
    instruction_id, program_id, status, held_at, timeout_at, decided_at, decided_by, decision_reason
    instruction_id, scenario_type, fallback_posture, policy_version_id,
    instruction_state_at_arrival text CONSTRAINT orphaned_attestation_landin_instruction_state_at_arriv_not_null NOT NULL,
    instruction_state_at_arrival,
    instruction_state_at_arrival,
    interpretation_pack_code uuid,
    interpretation_pack_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    interpretation_version_id uuid,
    interval_seconds integer NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_active boolean GENERATED ALWAYS AS ((status = 'ACTIVE'::public.policy_version_status)) STORED,
    is_active boolean,
    is_final boolean DEFAULT true NOT NULL,
    issuance_semantic_mode text NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    issued_by text NOT NULL,
    item_id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    job_id uuid DEFAULT gen_random_uuid() NOT NULL,
    journal_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    journal_id uuid NOT NULL,
    journal_type text NOT NULL,
    jsonb_build_object('executor', p_executor)
    jsonb_build_object('subject_token', p_subject_token)
    jurisdiction_code character(2) NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    jurisdiction_code character(2) NOT NULL,
    jurisdiction_code character(2),
    jurisdiction_code character(2),
    jurisdiction_code text NOT NULL,
    jurisdiction_code text NOT NULL,
    jurisdiction_code text NOT NULL,
    jurisdiction_code text NOT NULL,
    jurisdiction_code text NOT NULL,
    jurisdiction_code text NOT NULL,
    jurisdiction_code text NOT NULL,
    jurisdiction_compatibility jsonb DEFAULT '{}'::jsonb NOT NULL,
    jurisdiction_profile_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    jurisdiction_scope jsonb DEFAULT '[]'::jsonb NOT NULL,
    justification text,
    justification_text text
    key_backend text NOT NULL,
    key_class public.key_class_enum NOT NULL,
    key_class public.key_class_enum NOT NULL,
    key_id text NOT NULL,
    key_used text NOT NULL,
    key_version text NOT NULL,
    key_versions_covered text[] NOT NULL,
    kyc_hold boolean,
    kyc_status text DEFAULT 'PENDING'::text NOT NULL,
    kyc_status,
    last_error text,
    latency_ms integer,
    leaf_count integer NOT NULL,
    leaf_hash text NOT NULL,
    leaf_hash text NOT NULL,
    leaf_id uuid DEFAULT gen_random_uuid() NOT NULL,
    leaf_index integer NOT NULL,
    leaf_index integer NOT NULL,
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
    lifecycle_checkpoint_rule_id uuid DEFAULT public.uuid_v7_or_random() CONSTRAINT lifecycle_checkpoint_rules_lifecycle_checkpoint_rule_i_not_null NOT NULL,
    lifecycle_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    matrix_id uuid DEFAULT gen_random_uuid() NOT NULL,
    max_attempts integer NOT NULL,
    max_requests integer NOT NULL,
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
    merkle_proof jsonb NOT NULL,
    merkle_root text NOT NULL,
    merkle_root text NOT NULL,
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
    methodology_authority text NOT NULL,
    methodology_code text NOT NULL,
    methodology_scope jsonb DEFAULT '[]'::jsonb NOT NULL,
    methodology_version_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    migrated_at timestamp with time zone DEFAULT now() NOT NULL,
    migrated_at,
    migrated_by text NOT NULL,
    migrated_by,
    migrated_member_id uuid NOT NULL,
    migrated_member_id,
    migration_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    mismatch_detected boolean DEFAULT true NOT NULL,
    monitoring_record_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    monitoring_record_id uuid,
    msisdn_hash bytea,
    name text NOT NULL,
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
    node_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    node_type text NOT NULL,
    observed_at timestamp with time zone DEFAULT now() NOT NULL
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
    outage_source text NOT NULL,
    outbox_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    outbox_id uuid NOT NULL,
    outbox_id uuid NOT NULL,
    outbox_id uuid NOT NULL,
    outbox_id,
    outcome text NOT NULL
    outcome text NOT NULL,
    outcome text NOT NULL,
    outcome text NOT NULL,
    outcome text NOT NULL,
    outcome text NOT NULL,
    outcome text,
    p95_latency_ms integer NOT NULL,
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
    p_instruction_id,
    p_instruction_id, 'AWAITING_EXECUTION', 0, 1, p_policy_version_id
    p_instruction_id, p_program_id, 'ESCALATED', 'ESCALATED', v_actor, p_reason
    p_instruction_id, p_program_id, 'PENDING_SUPERVISOR_APPROVAL', NOW(), NOW() + make_interval(mins => v_timeout), NULL, NULL, NULL
    p_instruction_id, p_scenario_type, p_fallback_posture, p_policy_version_id,
    p_instruction_id, v_program_id,
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
    p_program_id,
    p_purge_request_id,
    p_rail_id,
    p_reason
    p_reason => COALESCE(p_reason, 'reservation_authorized'),
    p_reason => p_reason,
    p_reason,
    p_reason,
    p_request_reason
    p_requested_by,
    p_state_at_arrival,
    p_subject_token,
    p_tenant_id,
    p_tenant_id, p_idempotency_key, p_journal_type, p_reference_id, p_currency_code
    p_timeout_minutes,
    p_to_program_id,
    p_to_state => 'AUTHORIZED',
    p_to_state => 'RELEASED',
    p_window_seconds, p_policy_version_id,
    pack_id uuid DEFAULT gen_random_uuid() NOT NULL,
    pack_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    pack_id uuid NOT NULL,
    pack_id uuid NOT NULL,
    pack_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    pack_type text NOT NULL,
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
    participant_id text NOT NULL,
    participant_id text,
    participant_id,
    participant_kind text NOT NULL,
    partition_strategy text NOT NULL,
    pass boolean NOT NULL,
    payload jsonb NOT NULL,
    payload jsonb NOT NULL,
    payload_capture text NOT NULL,
    payload_capture, retention_policy_version_id
    payload_hash text NOT NULL,
    payload_hash text NOT NULL,
    payload_hash text NOT NULL,
    payload_schema_refs jsonb DEFAULT '[]'::jsonb NOT NULL,
    payout_target text NOT NULL,
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
    placeholder_id uuid DEFAULT gen_random_uuid() NOT NULL,
    placeholder_ref text NOT NULL,
    policy_bundle_id uuid DEFAULT gen_random_uuid() NOT NULL,
    policy_code text NOT NULL,
    policy_decision_id uuid,
    policy_id text NOT NULL,
    policy_id uuid DEFAULT gen_random_uuid() NOT NULL,
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
    posting_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    previous_hash text,
    prior_iccid_hash text NOT NULL,
    prior_iccid_hash,
    profile_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    profile_type text NOT NULL,
    program_escrow_id uuid NOT NULL,
    program_escrow_id uuid NOT NULL,
    program_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    program_id uuid NOT NULL,
    program_id uuid NOT NULL,
    program_id uuid NOT NULL,
    program_id uuid NOT NULL,
    program_id uuid NOT NULL,
    program_id uuid,
    program_id uuid,
    program_key text NOT NULL,
    program_name text NOT NULL,
    programme_id uuid NOT NULL,
    programme_key text NOT NULL,
    project_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    project_id uuid NOT NULL,
    project_id uuid NOT NULL,
    project_id uuid NOT NULL,
    project_id uuid NOT NULL,
    project_id uuid NOT NULL,
    project_id uuid NOT NULL,
    project_id uuid NOT NULL,
    project_id uuid NOT NULL,
    project_id uuid,
    projection_payload jsonb NOT NULL,
    projection_payload jsonb NOT NULL,
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
    projection_version text DEFAULT 'phase1-cqrs-v1'::text NOT NULL
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
    published_at timestamp with time zone DEFAULT now() NOT NULL,
    purge_effective_at timestamp with time zone NOT NULL,
    purge_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    purge_request_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    purge_request_id uuid NOT NULL,
    purge_request_id uuid,
    purge_request_id,
    purge_request_id,
    purged_at timestamp with time zone,
    quantity bigint NOT NULL,
    quantity numeric NOT NULL,
    quarantine_id uuid DEFAULT gen_random_uuid() NOT NULL,
    queue_status text NOT NULL,
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
    rail_type text NOT NULL,
    rate_bps integer NOT NULL,
    re_sign_linked boolean DEFAULT false NOT NULL
    read_window_minutes integer,
    reason text NOT NULL,
    reason text,
    reason text,
    reason text,
    reason text,
    reason,
    reason_code text,
    reason_code text,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    recipient_ref text NOT NULL,
    recipient_ref, policy_version_id, justification
    record_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    record_type text NOT NULL,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    records_replayed integer DEFAULT 0 NOT NULL,
    redaction_scope text NOT NULL,
    reference_attempted text CONSTRAINT dispatch_reference_collision_event_reference_attempted_not_null NOT NULL,
    reference_id text,
    registered_latitude numeric,
    registered_longitude numeric,
    registry_id uuid DEFAULT gen_random_uuid() NOT NULL,
    regulator_ref text,
    regulatory_authority_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    regulatory_authority_id uuid NOT NULL,
    regulatory_authority_id uuid NOT NULL,
    regulatory_checkpoint_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    regulatory_checkpoint_id uuid NOT NULL,
    release_due_at timestamp with time zone,
    released_at timestamp with time zone,
    replay_day date NOT NULL,
    report_delivery boolean NOT NULL,
    report_id text NOT NULL,
    report_id text NOT NULL,
    report_id text NOT NULL,
    report_id text NOT NULL,
    reported_to_boz_at timestamp with time zone,
    reporting_period character(7),
    request_hash text NOT NULL,
    request_reason
    request_reason text NOT NULL,
    request_source text NOT NULL,
    requested_at timestamp with time zone DEFAULT now() NOT NULL
    requested_by text NOT NULL,
    requested_by,
    required_approver_count integer NOT NULL,
    reservation_escrow_id uuid NOT NULL,
    reservation_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    reserved_amount_minor bigint DEFAULT 0 NOT NULL,
    reset_at timestamp with time zone,
    resolved_at timestamp with time zone
    response_code integer,
    response_hash text NOT NULL,
    resumed_at timestamp with time zone,
    resumed_at timestamp with time zone,
    retention_class text DEFAULT 'FIC_AML_CUSTOMER_ID'::text NOT NULL,
    retention_class text NOT NULL,
    retention_policy_version_id text NOT NULL,
    retention_years integer NOT NULL,
    retired_at timestamp with time zone
    retired_quantity numeric NOT NULL,
    retirement_event_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    retirement_reason text NOT NULL,
    retirement_semantic_mode text NOT NULL,
    reversal_of_instruction_id text,
    revocation_reason text,
    revoked_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    revoked_at timestamp with time zone,
    revoked_by text
    revoked_by text
    role_at_time_of_signing text NOT NULL,
    role_type text NOT NULL,
    rolling_window_seconds integer NOT NULL,
    rolling_window_seconds, policy_version_id, suspended_at
    root_hash text,
    rotation_type text NOT NULL,
    rows_affected integer DEFAULT 0 NOT NULL,
    rows_affected,
    rows_affected,
    rule_payload_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    rule_type text NOT NULL,
    run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_scope text NOT NULL,
    s->>'collision_action',
    s->>'rail_id',
    scenario_name text NOT NULL,
    scenario_type text NOT NULL,
    scope text DEFAULT 'AUDIT'::text NOT NULL,
    scope text NOT NULL,
    scoped_tables jsonb DEFAULT '[]'::jsonb NOT NULL,
    sealed_at timestamp with time zone DEFAULT now() NOT NULL
    sequence_id bigint NOT NULL,
    sequence_id bigint NOT NULL,
    severity text NOT NULL,
    sign_event_id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text,
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
    snapshot_id uuid DEFAULT gen_random_uuid() NOT NULL,
    snapshot_path text NOT NULL,
    snapshot_sha256 text NOT NULL,
    source_event_id uuid NOT NULL,
    source_event_id,
    source_node_id uuid NOT NULL,
    source_stream text NOT NULL,
    spec_json jsonb NOT NULL,
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
    state text NOT NULL,
    state_since timestamp with time zone DEFAULT now() NOT NULL
    status character varying DEFAULT 'pending'::character varying NOT NULL,
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
    status text DEFAULT 'ACTIVE'::text NOT NULL,
    status text DEFAULT 'CREATED'::text NOT NULL,
    status text NOT NULL,
    status text NOT NULL,
    status text NOT NULL,
    status text NOT NULL,
    status text NOT NULL,
    status text NOT NULL,
    status text NOT NULL,
    status text NOT NULL,
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
    subject_ref text NOT NULL,
    subject_ref text NOT NULL,
    subject_ref text NOT NULL,
    subject_token text NOT NULL,
    subject_token text NOT NULL,
    subject_token,
    submission_attempt_ref uuid,
    submitted_by text,
    supplier_id text NOT NULL,
    supplier_id text NOT NULL,
    supplier_name text NOT NULL,
    supplier_type text
    suspended_at timestamp with time zone,
    sweep_completed_timestamp timestamp with time zone NOT NULL,
    sweep_id uuid DEFAULT gen_random_uuid() NOT NULL,
    target_node_id uuid NOT NULL,
    target_stream text NOT NULL,
    target_tps integer NOT NULL,
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
    tenant_id, idempotency_key, journal_type, reference_id, currency_code
    tenant_id, program_escrow_id, reservation_escrow_id, amount_minor, actor_id, reason, metadata, created_at
    tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at, release_due_at
    tenant_key text NOT NULL,
    tenant_key text NOT NULL,
    tenant_member_id uuid NOT NULL,
    tenant_member_id,
    tenant_name text NOT NULL,
    tenant_type text NOT NULL,
    test_vectors jsonb NOT NULL,
    tier text NOT NULL,
    timeout_at timestamp with time zone NOT NULL,
    to_program_id uuid NOT NULL,
    to_program_id,
    to_state character varying NOT NULL,
    to_unit character varying NOT NULL,
    token_hash text NOT NULL,
    token_hash text NOT NULL,
    token_id uuid DEFAULT gen_random_uuid() NOT NULL,
    token_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    token_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    token_jti text NOT NULL,
    token_jti_hash text,
    token_value text NOT NULL,
    total_artifacts integer NOT NULL,
    tpin_hash bytea,
    transition_id uuid DEFAULT gen_random_uuid() NOT NULL,
    transition_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    trigger_reason text,
    trigger_threshold numeric(8,6) NOT NULL,
    truncation_applied boolean NOT NULL,
    trust_chain_ref text,
    unit character varying NOT NULL,
    units text NOT NULL,
    unsigned_reason text
    unsigned_reason text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    updated_at_utc text NOT NULL
    updated_at_utc text NOT NULL,
    upstream_ref text,
    upstream_ref text,
    upstream_ref text,
    v_actor
    v_actor,
    v_actor,
    v_adapter_active          BOOLEAN;
    v_adapter_registration_id UUID;
    v_approved     INT;
    v_approved_count    INT;
    v_asset_batch_id          UUID;
    v_attempt := v_attempt + 1;
    v_authority_jcode     TEXT;
    v_batch_quantity      NUMERIC;
    v_batch_status        TEXT;
    v_canon := public.canonicalize_reference_for_rail(v_candidate, p_rail_id);
    v_capture,
    v_class := 'DUPLICATE_DISPATCH';
    v_class := 'LATE_CALLBACK';
    v_class := 'REPLAY_ATTEMPT';
    v_class := 'UNKNOWN_REFERENCE';
    v_class := 'UNKNOWN_REFERENCE';
    v_class,
    v_collision := false;
    v_conditional_count       INT;
    v_conditional_count       INT;
    v_confidence   NUMERIC;
    v_confidence_score  NUMERIC;
    v_count := v_count + 1;
    v_count INT;
    v_current_status TEXT;
    v_current_status TEXT;
    v_decision_count    INT;
    v_decision_id         UUID;
    v_edge_id          UUID;
    v_effective_state := p_state;
    v_env.tenant_id, NULL, NULL, 'CREATED', v_amount, v_env.currency_code, NOW() + interval '30 minutes', NOW() + interval '60 minutes'
    v_env.tenant_id, v_env.escrow_id, v_reservation_escrow_id, v_amount, v_actor, p_reason, COALESCE(p_metadata, '{}'::jsonb), NOW()
    v_event.event_id,
    v_event.iccid_hash,
    v_event.member_id,
    v_event.tenant_id,
    v_evidence_node_id      UUID;
    v_expires_at     TIMESTAMPTZ;
    v_expires_at := now() + (p_ttl_hours || ' hours')::INTERVAL;
    v_formula_version_id,
    v_formula_version_id,
    v_from_status       TEXT;
    v_from_status := NEW.event_payload_json->>'from_status';
    v_idempotency_key TEXT; v_rail_type TEXT; v_payload JSONB;
    v_instruction_id TEXT; v_participant_id TEXT; v_sequence_id BIGINT;
    v_interpretation_pack_id UUID;
    v_jurisdiction_code       TEXT;
    v_lifecycle_event_id UUID;
    v_methodology_scope JSONB;
    v_monitoring_record_id  UUID := NULL;
    v_monitoring_record_id UUID;
    v_mv_adapter_id        UUID;
    v_new_member_id,
    v_new_member_id,
    v_next_attempt_no INT;
    v_next_attempt_no INT; v_effective_state outbox_attempt_state;
    v_pack_jcode          TEXT;
    v_payload JSONB;
    v_payload_valid        BOOLEAN;
    v_payload_valid := public.validate_payload_against_schema(
    v_policy.policy_version_id
    v_prior_iccid_hash,
    v_profile,
    v_project_id            UUID;
    v_project_status          TEXT;
    v_project_status       TEXT;
    v_queue_status := 'APPROVED';
    v_queue_status := 'APPROVED';
    v_queue_status := 'RESET';
    v_queue_status,
    v_reason,
    v_recipient, p_policy_version_id, p_justification
    v_record RECORD;
    v_remaining_quantity  NUMERIC;
    v_remaining_quantity := v_batch_quantity - v_total_retired;
    v_request_id,
    v_required_threshold NUMERIC := 0.95;
    v_result_state            TEXT;
    v_retire_qty          NUMERIC;
    v_retire_qty := COALESCE(p_quantity, v_remaining_quantity);
    v_retirement_event_id UUID;
    v_retry_ceiling := public.outbox_retry_ceiling();
    v_retry_ceiling INT;
    v_row.escrow_id,
    v_row.tenant_id,
    v_rows,
    v_schema_exists BOOLEAN := false;
    v_sequence_ref,
    v_source_member.ceiling_amount_minor,
    v_source_member.ceiling_currency,
    v_source_member.kyc_status,
    v_source_member.person_id,
    v_source_member.status,
    v_source_member.tenant_id,
    v_source_member.tenant_member_id,
    v_source_tenant    UUID;
    v_state := 'ACKNOWLEDGED';
    v_state := 'AWAITING_EXECUTION';
    v_state := 'AWAITING_EXECUTION';
    v_state := 'FINALITY_CONFLICT';
    v_state := 'SUSPENDED';
    v_submitted_by,
    v_target_tenant    UUID;
    v_threshold    NUMERIC := 0.95;
    v_to_state,
    v_to_status         TEXT;
    v_to_status := NEW.event_payload_json->>'to_status';
    v_token_hash     TEXT;
    v_token_hash := public.crypt(v_token_secret, public.gen_salt('bf', 8));
    v_token_id       UUID;
    v_token_secret   TEXT;
    v_token_secret := encode(public.gen_random_bytes(32), 'hex');
    v_total        INT;
    v_total_retired       NUMERIC;
    v_unsatisfied_checkpoints INT;
    v_unsatisfied_checkpoints INT;
    v_unsatisfied_checkpoints INT;
    v_valid_classes         TEXT[] := ARRAY[
    v_valid_edge_types TEXT[] := ARRAY[
    v_valid_subject_types     TEXT[] := ARRAY['PROJECT', 'ASSET_BATCH', 'MONITORING_RECORD', 'EVIDENCE_NODE'];
    v_valid_subject_types TEXT[] := ARRAY['PROJECT', 'ASSET_BATCH', 'MONITORING_RECORD', 'EVIDENCE_NODE'];
    v_valid_target_types    TEXT[] := ARRAY[
    v_verifier_active BOOLEAN;
    vault_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    verification_hash text,
    verification_method text,
    verification_outcome text,
    verification_run_id uuid DEFAULT gen_random_uuid() NOT NULL,
    verified_artifact_id text NOT NULL,
    verified_at timestamp with time zone,
    verified_at_provider timestamp with time zone,
    verified_member_count bigint DEFAULT 0 CONSTRAINT program_member_summary_projectio_verified_member_count_not_null NOT NULL,
    verifier_id uuid DEFAULT public.uuid_v7_or_random() NOT NULL,
    verifier_id uuid NOT NULL,
    verifier_id uuid NOT NULL,
    verifier_name text NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    version text NOT NULL,
    version text NOT NULL,
    version text NOT NULL,
    version_code text NOT NULL,
    version_status text DEFAULT 'ACTIVE'::text NOT NULL,
    window_id uuid DEFAULT gen_random_uuid() NOT NULL,
    worker_id text,
    years_covered integer NOT NULL,
    zra_reference text,
   FROM (public.member_device_events e
   FROM due
   FROM public.asset_batches
   FROM public.asset_batches
   FROM public.evidence_nodes
   FROM public.evidence_nodes
   FROM public.members m
   FROM public.verifier_registry
   FROM public.verifier_registry
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
  ELSE
  ELSIF NEW.billable_client_id <> derived_billable_client_id THEN
  ELSIF NEW.tenant_id <> derived_tenant_id THEN
  ELSIF p_has_unknown_reference THEN
  ELSIF p_is_duplicate_dispatch THEN
  ELSIF p_is_replay THEN
  ELSIF v_action = 'RESUME' THEN
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
  FOR UPDATE;
  FOR UPDATE;
  FOR UPDATE;
  FOR v_escrow_id IN
  FOR v_item IN
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
  FROM public.inquiry_state_machine
  FROM public.inquiry_state_machine
  FROM public.inquiry_state_machine
  FROM public.instruction_effect_seals
  FROM public.instruction_effect_seals
  FROM public.instruction_settlement_finality
  FROM public.internal_ledger_journals
  FROM public.internal_ledger_journals
  FROM public.member_device_events e
  FROM public.member_devices md
  FROM public.members m
  FROM public.members m
  FROM public.members m
  FROM public.pii_purge_events e
  FROM public.pii_purge_requests r
  FROM public.programs
  FROM public.proof_pack_batch_leaves
  FROM public.reference_strategy_policy_versions
  FROM public.risk_formula_versions rf
  FROM public.risk_formula_versions rf
  FROM public.risk_formula_versions rf
  FROM public.signing_authorization_matrix
  FROM public.supervisor_approval_queue
  FROM public.tenant_members
  FROM public.transition_escrow_state(
  FROM public.transition_escrow_state(
  FROM sums;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  GROUP BY tenant_id, (EXTRACT(year FROM enrolled_at));
  IF COALESCE(v_allowed, false) IS NOT true THEN
  IF COALESCE(v_ok,false) IS NOT true THEN
  IF EXISTS (
  IF FOUND THEN
  IF FOUND THEN
  IF NEW.billable_client_id IS NULL THEN
  IF NEW.correlation_id IS NULL THEN
  IF NEW.currency_code IS DISTINCT FROM v_journal_currency THEN
  IF NEW.final_state = 'SETTLED' THEN
  IF NEW.is_final IS DISTINCT FROM TRUE THEN
  IF NEW.member_id IS NULL THEN
  IF NEW.policy_json IS DISTINCT FROM OLD.policy_json
  IF NEW.reversal_of_instruction_id IS NULL THEN
  IF NEW.state <> 'DISPATCHED' THEN
  IF NEW.tenant_id IS DISTINCT FROM v_journal_tenant THEN
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
  IF NOT EXISTS (SELECT 1 FROM public.canonicalization_registry WHERE canonicalization_version = p_version) THEN
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
  IF NOT p_ok THEN
  IF NOT public.verify_internal_ledger_journal_balance(v_journal_id) THEN
  IF NOT v_exists THEN
  IF NOT v_legal THEN
  IF NULLIF(BTRIM(p_anchor_ref), '') IS NULL THEN
  IF OLD.is_final IS TRUE THEN
  IF OLD.version_status = 'ACTIVE' AND NEW.version_status = 'ACTIVE' THEN
  IF TG_OP = 'UPDATE' THEN
  IF TG_OP='UPDATE' AND OLD.adjustment_state IN ('executed','denied','blocked_legal_hold') THEN
  IF derived_billable_client_id IS NULL THEN
  IF derived_tenant_id IS NULL THEN
  IF length(p_allocated_reference) > v_strategy.max_length THEN
  IF m_tenant <> NEW.tenant_id THEN
  IF m_tenant IS NULL THEN
  IF p_blocked THEN
  IF p_contains_raw_pii THEN
  IF p_current_state = 'cooling_off' THEN
  IF p_entity_id IS DISTINCT FROM p_program_id THEN
  IF p_expected_leaf_hash IS NULL OR btrim(p_expected_leaf_hash) = '' THEN
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
  IF p_postings IS NULL OR jsonb_typeof(p_postings) <> 'array' OR jsonb_array_length(p_postings) < 2 THEN
  IF p_rail_a_status IN ('SUCCESS','FAILED')
  IF p_scenario_type NOT IN ('ASYNC_CONTRADICTION', 'DELAYED_SETTLEMENT', 'DUAL_DEBIT_RISK', 'SILENT_REJECTION') THEN
  IF p_should_block THEN
  IF p_signing_path = 'SOFTWARE_BYPASS' THEN
  IF v IS NULL OR btrim(v) = '' THEN
  IF v_action = 'ACKNOWLEDGE' THEN
  IF v_action NOT IN ('ACKNOWLEDGE', 'RESUME', 'RESET') THEN
  IF v_alert_id IS NULL THEN
  IF v_amount <= 0 THEN
  IF v_attempts >= v_max THEN
  IF v_class IN ('DUPLICATE_DISPATCH', 'UNKNOWN_REFERENCE', 'REPLAY_ATTEMPT') THEN
  IF v_computed_hash <> v_stored_hash THEN
  IF v_decision NOT IN ('APPROVED', 'REJECTED') THEN
  IF v_env.reserved_amount_minor + v_amount > v_env.ceiling_amount_minor THEN
  IF v_event.event_type <> 'SIM_SWAP_DETECTED' OR v_event.iccid_hash IS NULL THEN
  IF v_existing IS NOT NULL THEN
  IF v_existing_hash <> v_hash OR v_existing_version <> p_canonicalization_version THEN
  IF v_existing_hash IS NULL THEN
  IF v_formula_version_id IS NULL THEN
  IF v_formula_version_id IS NULL THEN
  IF v_formula_version_id IS NULL THEN
  IF v_hash <> p_expected_leaf_hash THEN
  IF v_hash IS NULL THEN
  IF v_journal_tenant IS NULL THEN
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
  IF v_program_id IS NULL THEN
  IF v_row.state IN ('RELEASED', 'CANCELED', 'EXPIRED') THEN
  IF v_sequence_ref IS NULL THEN
  IF v_source_state <> 'SETTLED' OR v_source_final IS DISTINCT FROM TRUE THEN
  IF v_state <> 'AWAITING_EXECUTION' THEN
  IF v_state <> 'SENT' THEN
  IF v_state = 'EXHAUSTED' THEN
  IF v_state = 'FINALITY_CONFLICT' THEN
  IF v_state = 'SUSPENDED' THEN
  IF v_state IN ('ACKNOWLEDGED', 'EXHAUSTED') THEN
  IF v_state IS DISTINCT FROM 'ACKNOWLEDGED' THEN
  IF v_state IS NULL OR v_state NOT IN ('ESCALATED', 'AWAITING_EXECUTION') THEN
  IF v_state IS NULL THEN
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
  INSERT INTO public.inquiry_state_machine(
  INSERT INTO public.inquiry_state_machine(instruction_id, inquiry_state, attempts, max_attempts, policy_version_id)
  INSERT INTO public.instruction_effect_seals(instruction_id, effect_seal_hash, canonicalization_version, policy_version_id)
  INSERT INTO public.instruction_finality_conflicts(
  INSERT INTO public.internal_ledger_journals(
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
  INSERT INTO public.supervisor_interrupt_audit_events(
  INSERT INTO public.supervisor_interrupt_audit_events(
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
  PERFORM public.submit_for_supervisor_approval(
  PERFORM public.submit_for_supervisor_approval(p_instruction_id, v_program_id, 30, NULL, 'system');
  PERFORM set_config('symphony.allow_pii_purge', 'on', true);
  RAISE EXCEPTION 'ADJUSTMENT_RECIPIENT_NOT_PERMITTED' USING ERRCODE = 'P7601';
  RAISE EXCEPTION 'member_device_events is append-only'
  RAISE EXCEPTION 'pii_vault_records is non-deletable'
  RAISE EXCEPTION 'sim_swap_alerts is append-only'
  RETURN 'ACKNOWLEDGED';
  RETURN 'AWAITING_EXECUTION';
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
  RETURN NEW;
  RETURN NEW;
  RETURN OLD;
  RETURN QUERY
  RETURN QUERY
  RETURN QUERY
  RETURN QUERY SELECT p_purge_request_id, v_rows, FALSE;
  RETURN TRUE;
  RETURN md5(v_input);
  RETURN true;
  RETURN v_alert_id;
  RETURN v_class;
  RETURN v_count;
  RETURN v_count;
  RETURN v_count;
  RETURN v_event_id;
  RETURN v_event_id;
  RETURN v_existing_hash;
  RETURN v_id;
  RETURN v_id;
  RETURN v_id;
  RETURN v_id;
  RETURN v_journal_id;
  RETURN v_new_member_id;
  RETURN v_operation_id;
  RETURN v_request_id;
  RETURN v_reservation_escrow_id;
  RETURN v_state;
  RETURN v_state;
  RETURN v_state;
  RETURN v_target_member_id;
  RETURN v_truncated;
  RETURNING alert_id INTO v_alert_id;
  RETURNING escrow_accounts.escrow_id INTO v_reservation_escrow_id;
  RETURNING escrow_events.event_id INTO v_event_id;
  RETURNING journal_id INTO v_journal_id;
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
  SELECT current_setting('app.jurisdiction_code', true);
  SELECT e.*
  SELECT e.rows_affected
  SELECT effect_seal_hash, canonicalization_version
  SELECT effect_seal_hash, canonicalization_version
  SELECT final_state, is_final
  SELECT ia.tenant_id
  SELECT inquiry_state INTO v_state
  SELECT inquiry_state INTO v_state
  SELECT inquiry_state INTO v_state
  SELECT inquiry_state INTO v_state
  SELECT inquiry_state INTO v_state
  SELECT inquiry_state, attempts, max_attempts INTO v_state, v_attempts, v_max
  SELECT journal_id
  SELECT leaf_hash INTO v_hash
  SELECT m.*
  SELECT m.*
  SELECT m.member_id
  SELECT md.iccid_hash
  SELECT p.outbox_id
  SELECT parent_instruction_id INTO v_parent FROM public.adjustment_instructions WHERE adjustment_id = p_adjustment_id;
  SELECT policy_version_id, policy_json INTO v_policy
  SELECT posting_count >= 2
  SELECT program_id
  SELECT program_id INTO v_program_id
  SELECT r.subject_token
  SELECT rf.formula_version_id
  SELECT rf.formula_version_id
  SELECT rf.formula_version_id
  SELECT signature_valid INTO v_ok FROM public.policy_bundles WHERE policy_bundle_id = p_policy_bundle_id;
  SELECT t.billable_client_id
  SELECT t.event_id
  SELECT tenant_id INTO m_tenant
  SELECT tenant_id, currency_code
  SELECT true INTO v_allowed
  SELECT v_row.escrow_id, v_row.state, v_to_state, v_event_id;
  SET attempts = v_attempts,
  SET inquiry_state = 'ACKNOWLEDGED',
  SET inquiry_state = 'ESCALATED',
  SET reserved_amount_minor = reserved_amount_minor + v_amount,
  SET state = 'ANCHORED',
  SET state = 'COMPLETED',
  SET state = CASE WHEN o.state = 'ANCHORED' THEN 'ANCHORED' ELSE 'ANCHORING' END,
  SET state = CASE WHEN state = 'ANCHORED' THEN 'ANCHORED' ELSE 'PENDING' END,
  SET state = v_to_state,
  SET state='active', activation_timestamp=now(), verification_outcome='PASS', assurance_tier=COALESCE(assurance_tier,'HSM_BACKED')
  SET status = 'ESCALATED',
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
  UPDATE public.inquiry_state_machine
  UPDATE public.pii_vault_records
  UPDATE public.policy_bundles
  UPDATE public.supervisor_approval_queue
  UPDATE public.supervisor_approval_queue
  UPDATE public.supervisor_approval_queue
  VALUES (
  VALUES (
  VALUES (p_instruction_id, 'SCHEDULED', 0, p_max_attempts, p_policy_version_id)
  VALUES (p_instruction_id, v_hash, p_canonicalization_version, p_policy_version_id)
  VALUES (p_pack_id, COALESCE(NULLIF(BTRIM(p_anchor_provider), ''), 'GENERIC'))
  WHERE ((asset_batches.asset_batch_id = asset_lifecycle_events.asset_batch_id) AND (asset_batches.tenant_id = public.current_tenant_id_or_null()))))) WITH CHECK ((EXISTS ( SELECT 1
  WHERE ((asset_batches.asset_batch_id = asset_lifecycle_events.asset_batch_id) AND (asset_batches.tenant_id = public.current_tenant_id_or_null())))));
  WHERE ((evidence_nodes.evidence_node_id = evidence_edges.source_node_id) AND (evidence_nodes.tenant_id = public.current_tenant_id_or_null()))))) WITH CHECK ((EXISTS ( SELECT 1
  WHERE ((evidence_nodes.evidence_node_id = evidence_edges.source_node_id) AND (evidence_nodes.tenant_id = public.current_tenant_id_or_null())))));
  WHERE ((verifier_registry.verifier_id = verifier_project_assignments.verifier_id) AND (verifier_registry.tenant_id = public.current_tenant_id_or_null()))))) WITH CHECK ((EXISTS ( SELECT 1
  WHERE ((verifier_registry.verifier_id = verifier_project_assignments.verifier_id) AND (verifier_registry.tenant_id = public.current_tenant_id_or_null())))));
  WHERE a.parent_instruction_id=v_parent AND e.outcome='executed';
  WHERE batch_id = p_batch_id AND leaf_index = p_leaf_index;
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
  WHERE instruction_id = p_instruction_id
  WHERE instruction_id = p_instruction_id
  WHERE instruction_id = p_instruction_id
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE instruction_id = p_instruction_id;
  WHERE journal_id = NEW.journal_id;
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
  WHERE tenant_id = p_tenant_id
  WHERE version_status = 'ACTIVE'
  WITH candidate AS (
  WITH sums AS (
  derived_billable_client_id UUID;
  derived_tenant_id UUID;
  m_tenant uuid;
  v := current_setting('app.current_tenant_id', true);
  v text;
  v_action TEXT := UPPER(BTRIM(COALESCE(p_action, '')));
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
  v_actor TEXT := COALESCE(NULLIF(BTRIM(COALESCE(p_actor, '')), ''), 'system');
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
  v_existing UUID;
  v_existing_hash text;
  v_existing_version text;
  v_exists boolean;
  v_formula_version_id UUID;
  v_formula_version_id UUID;
  v_formula_version_id UUID;
  v_hash := public.compute_effect_seal_hash(p_instruction_id, p_payload, p_canonicalization_version);
  v_hash text;
  v_hash text;
  v_id uuid;
  v_id uuid;
  v_id uuid;
  v_id uuid;
  v_input := coalesce(p_instruction_id, '') || '|' || coalesce(p_canonicalization_version, '') || '|' || coalesce(p_payload::text, '{}');
  v_input text;
  v_item JSONB;
  v_journal_currency TEXT;
  v_journal_id UUID;
  v_journal_tenant UUID;
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
  v_program_id UUID;
  v_queue_status TEXT;
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
ALTER TABLE ONLY public.adapter_registrations
ALTER TABLE ONLY public.adapter_registrations
ALTER TABLE ONLY public.adapter_registrations
ALTER TABLE ONLY public.adapter_registrations FORCE ROW LEVEL SECURITY;
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
ALTER TABLE ONLY public.anchor_backfill_jobs
ALTER TABLE ONLY public.anchor_sync_operations
ALTER TABLE ONLY public.anchor_sync_operations
ALTER TABLE ONLY public.anchor_sync_operations
ALTER TABLE ONLY public.archive_verification_runs
ALTER TABLE ONLY public.artifact_signing_batch_items
ALTER TABLE ONLY public.artifact_signing_batch_items
ALTER TABLE ONLY public.artifact_signing_batch_items
ALTER TABLE ONLY public.artifact_signing_batches
ALTER TABLE ONLY public.asset_batches
ALTER TABLE ONLY public.asset_batches
ALTER TABLE ONLY public.asset_batches
ALTER TABLE ONLY public.asset_batches FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.asset_lifecycle_events
ALTER TABLE ONLY public.asset_lifecycle_events
ALTER TABLE ONLY public.asset_lifecycle_events
ALTER TABLE ONLY public.asset_lifecycle_events FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.audit_tamper_evident_chains
ALTER TABLE ONLY public.authority_decisions
ALTER TABLE ONLY public.authority_decisions
ALTER TABLE ONLY public.authority_decisions FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.billable_clients
ALTER TABLE ONLY public.billable_clients
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events
ALTER TABLE ONLY public.billing_usage_events FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.boz_operational_scenario_runs
ALTER TABLE ONLY public.canonicalization_archive_snapshots
ALTER TABLE ONLY public.canonicalization_archive_snapshots
ALTER TABLE ONLY public.canonicalization_archive_snapshots
ALTER TABLE ONLY public.canonicalization_registry
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
ALTER TABLE ONLY public.escrow_summary_projection
ALTER TABLE ONLY public.escrow_summary_projection
ALTER TABLE ONLY public.escrow_summary_projection
ALTER TABLE ONLY public.escrow_summary_projection
ALTER TABLE ONLY public.evidence_bundle_projection
ALTER TABLE ONLY public.evidence_bundle_projection
ALTER TABLE ONLY public.evidence_edges
ALTER TABLE ONLY public.evidence_edges
ALTER TABLE ONLY public.evidence_edges
ALTER TABLE ONLY public.evidence_edges
ALTER TABLE ONLY public.evidence_edges FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.evidence_nodes
ALTER TABLE ONLY public.evidence_nodes
ALTER TABLE ONLY public.evidence_nodes
ALTER TABLE ONLY public.evidence_nodes
ALTER TABLE ONLY public.evidence_nodes FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_pack_items
ALTER TABLE ONLY public.evidence_packs
ALTER TABLE ONLY public.execution_records
ALTER TABLE ONLY public.execution_records
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs
ALTER TABLE ONLY public.external_proofs FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.factor_registry
ALTER TABLE ONLY public.factor_registry
ALTER TABLE ONLY public.gf_verifier_read_tokens
ALTER TABLE ONLY public.gf_verifier_read_tokens
ALTER TABLE ONLY public.gf_verifier_read_tokens
ALTER TABLE ONLY public.gf_verifier_read_tokens
ALTER TABLE ONLY public.gf_verifier_read_tokens FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.global_rate_limit_policies
ALTER TABLE ONLY public.historical_verification_runs
ALTER TABLE ONLY public.hsm_fail_closed_events
ALTER TABLE ONLY public.incident_case_projection
ALTER TABLE ONLY public.incident_case_projection
ALTER TABLE ONLY public.incident_case_projection
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
ALTER TABLE ONLY public.instruction_status_projection
ALTER TABLE ONLY public.instruction_status_projection
ALTER TABLE ONLY public.instruction_status_projection
ALTER TABLE ONLY public.internal_ledger_journals
ALTER TABLE ONLY public.internal_ledger_journals
ALTER TABLE ONLY public.internal_ledger_journals
ALTER TABLE ONLY public.internal_ledger_postings
ALTER TABLE ONLY public.internal_ledger_postings
ALTER TABLE ONLY public.internal_ledger_postings
ALTER TABLE ONLY public.interpretation_packs
ALTER TABLE ONLY public.interpretation_packs
ALTER TABLE ONLY public.interpretation_packs FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.jurisdiction_profiles
ALTER TABLE ONLY public.jurisdiction_profiles FORCE ROW LEVEL SECURITY;
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
ALTER TABLE ONLY public.lifecycle_checkpoint_rules
ALTER TABLE ONLY public.lifecycle_checkpoint_rules
ALTER TABLE ONLY public.lifecycle_checkpoint_rules FORCE ROW LEVEL SECURITY;
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
ALTER TABLE ONLY public.methodology_versions
ALTER TABLE ONLY public.methodology_versions
ALTER TABLE ONLY public.methodology_versions
ALTER TABLE ONLY public.methodology_versions FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.mmo_reality_control_events
ALTER TABLE ONLY public.monitoring_records
ALTER TABLE ONLY public.monitoring_records
ALTER TABLE ONLY public.monitoring_records
ALTER TABLE ONLY public.monitoring_records FORCE ROW LEVEL SECURITY;
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
ALTER TABLE ONLY public.penalty_defense_packs
ALTER TABLE ONLY public.penalty_defense_packs
ALTER TABLE ONLY public.persons
ALTER TABLE ONLY public.persons
ALTER TABLE ONLY public.persons FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.pii_erased_subject_placeholders
ALTER TABLE ONLY public.pii_erased_subject_placeholders
ALTER TABLE ONLY public.pii_erasure_journal
ALTER TABLE ONLY public.pii_purge_events
ALTER TABLE ONLY public.pii_purge_events
ALTER TABLE ONLY public.pii_purge_events
ALTER TABLE ONLY public.pii_purge_requests
ALTER TABLE ONLY public.pii_tokenization_registry
ALTER TABLE ONLY public.pii_tokenization_registry
ALTER TABLE ONLY public.pii_vault_records
ALTER TABLE ONLY public.pii_vault_records
ALTER TABLE ONLY public.pii_vault_records
ALTER TABLE ONLY public.policy_bundles
ALTER TABLE ONLY public.policy_bundles
ALTER TABLE ONLY public.policy_versions
ALTER TABLE ONLY public.program_member_summary_projection
ALTER TABLE ONLY public.program_member_summary_projection
ALTER TABLE ONLY public.program_member_summary_projection
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events
ALTER TABLE ONLY public.program_migration_events FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.program_supplier_allowlist
ALTER TABLE ONLY public.program_supplier_allowlist
ALTER TABLE ONLY public.program_supplier_allowlist
ALTER TABLE ONLY public.program_supplier_allowlist
ALTER TABLE ONLY public.program_supplier_allowlist FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.programme_policy_binding
ALTER TABLE ONLY public.programme_policy_binding
ALTER TABLE ONLY public.programme_policy_binding
ALTER TABLE ONLY public.programme_policy_binding
ALTER TABLE ONLY public.programme_policy_binding FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.programme_registry
ALTER TABLE ONLY public.programme_registry
ALTER TABLE ONLY public.programme_registry
ALTER TABLE ONLY public.programme_registry FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs
ALTER TABLE ONLY public.programs FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.projects
ALTER TABLE ONLY public.projects
ALTER TABLE ONLY public.projects FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.proof_pack_batch_leaves
ALTER TABLE ONLY public.proof_pack_batch_leaves
ALTER TABLE ONLY public.proof_pack_batch_leaves
ALTER TABLE ONLY public.proof_pack_batches
ALTER TABLE ONLY public.proof_pack_batches
ALTER TABLE ONLY public.rail_dispatch_truth_anchor
ALTER TABLE ONLY public.rail_dispatch_truth_anchor
ALTER TABLE ONLY public.rail_dispatch_truth_anchor
ALTER TABLE ONLY public.rail_dispatch_truth_anchor
ALTER TABLE ONLY public.redaction_audit_events
ALTER TABLE ONLY public.reference_strategy_policy_versions
ALTER TABLE ONLY public.regulatory_authorities
ALTER TABLE ONLY public.regulatory_authorities FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.regulatory_checkpoints
ALTER TABLE ONLY public.regulatory_checkpoints
ALTER TABLE ONLY public.regulatory_checkpoints FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.regulatory_incidents
ALTER TABLE ONLY public.regulatory_incidents
ALTER TABLE ONLY public.regulatory_report_submission_attempts
ALTER TABLE ONLY public.regulatory_retraction_approvals
ALTER TABLE ONLY public.regulatory_retraction_approvals
ALTER TABLE ONLY public.resign_sweeps
ALTER TABLE ONLY public.retirement_events
ALTER TABLE ONLY public.retirement_events
ALTER TABLE ONLY public.retirement_events
ALTER TABLE ONLY public.retirement_events FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.revoked_client_certs
ALTER TABLE ONLY public.revoked_tokens
ALTER TABLE ONLY public.risk_formula_versions
ALTER TABLE ONLY public.risk_formula_versions
ALTER TABLE ONLY public.schema_migrations
ALTER TABLE ONLY public.signing_audit_log
ALTER TABLE ONLY public.signing_authorization_matrix
ALTER TABLE ONLY public.signing_authorization_matrix
ALTER TABLE ONLY public.signing_throughput_runs
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts
ALTER TABLE ONLY public.sim_swap_alerts FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.state_current
ALTER TABLE ONLY public.state_transitions
ALTER TABLE ONLY public.supervisor_access_policies
ALTER TABLE ONLY public.supervisor_approval_queue
ALTER TABLE ONLY public.supervisor_approval_queue
ALTER TABLE ONLY public.supervisor_audit_tokens
ALTER TABLE ONLY public.supervisor_audit_tokens
ALTER TABLE ONLY public.supervisor_audit_tokens
ALTER TABLE ONLY public.supervisor_interrupt_audit_events
ALTER TABLE ONLY public.supervisor_interrupt_audit_events
ALTER TABLE ONLY public.supplier_registry
ALTER TABLE ONLY public.supplier_registry
ALTER TABLE ONLY public.supplier_registry FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_clients
ALTER TABLE ONLY public.tenant_clients FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenant_members
ALTER TABLE ONLY public.tenant_members FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.tenant_registry
ALTER TABLE ONLY public.tenant_registry
ALTER TABLE ONLY public.tenant_registry
ALTER TABLE ONLY public.tenant_registry FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants
ALTER TABLE ONLY public.tenants FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.unit_conversions
ALTER TABLE ONLY public.unit_conversions
ALTER TABLE ONLY public.verifier_project_assignments
ALTER TABLE ONLY public.verifier_project_assignments
ALTER TABLE ONLY public.verifier_project_assignments
ALTER TABLE ONLY public.verifier_project_assignments
ALTER TABLE ONLY public.verifier_project_assignments FORCE ROW LEVEL SECURITY;
ALTER TABLE ONLY public.verifier_registry
ALTER TABLE ONLY public.verifier_registry
ALTER TABLE ONLY public.verifier_registry FORCE ROW LEVEL SECURITY;
ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asset_lifecycle_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authority_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billable_clients
ALTER TABLE public.billing_usage_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_envelopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.evidence_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.external_proofs
ALTER TABLE public.external_proofs
ALTER TABLE public.external_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gf_verifier_read_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingress_attestations
ALTER TABLE public.ingress_attestations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interpretation_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jurisdiction_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lifecycle_checkpoint_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.member_device_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.member_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.methodology_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monitoring_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_outbox_attempts
ALTER TABLE public.payment_outbox_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_outbox_pending
ALTER TABLE public.payment_outbox_pending ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_migration_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_supplier_allowlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programme_policy_binding ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programme_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regulatory_authorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regulatory_checkpoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retirement_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sim_swap_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifier_project_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifier_registry ENABLE ROW LEVEL SECURITY;
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
CREATE FUNCTION public.activate_project(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(project_id uuid, status text)
CREATE FUNCTION public.adapter_registrations_append_only_trigger() RETURNS trigger
CREATE FUNCTION public.allocate_dispatch_reference(p_instruction_id uuid, p_adjustment_id uuid, p_parent_reference text, p_rail_id text) RETURNS TABLE(registry_id uuid, allocated_reference text, canonicalized_reference text, strategy_used public.reference_strategy_type_enum, policy_version_id text, collision_retry_count integer)
CREATE FUNCTION public.anchor_dispatched_outbox_attempt() RETURNS trigger
CREATE FUNCTION public.apply_finality_signals(p_instruction_id text, p_rail_a_id text, p_rail_a_status public.finality_signal_status_enum, p_rail_b_id text, p_rail_b_status public.finality_signal_status_enum) RETURNS public.finality_resolution_state_enum
CREATE FUNCTION public.apply_inquiry_attempt(p_instruction_id text, p_policy_version_id text, p_max_attempts integer) RETURNS public.inquiry_state_enum
CREATE FUNCTION public.assert_adjustment_execution_allowed(p_adjustment_id uuid, p_current_state public.adjustment_state_enum, p_freeze_flag_type text DEFAULT NULL::text) RETURNS void
CREATE FUNCTION public.assert_canonicalization_version_exists(p_version text) RETURNS void
CREATE FUNCTION public.assert_hsm_fail_closed(p_should_block boolean) RETURNS void
CREATE FUNCTION public.assert_key_class_authorized(p_caller_id text, p_key_class public.key_class_enum) RETURNS void
CREATE FUNCTION public.assert_offline_safe_mode_dispatch_allowed(p_reason text, p_policy_version_id text, p_is_offline boolean) RETURNS void
CREATE FUNCTION public.assert_pii_absent_from_penalty_pack(p_contains_raw_pii boolean) RETURNS void
CREATE FUNCTION public.assert_rate_limit_blocked(p_blocked boolean) RETURNS void
CREATE FUNCTION public.assert_reference_registered(p_rail_id text, p_reference text, p_instruction_id uuid, p_adjustment_id uuid DEFAULT NULL::uuid) RETURNS void
CREATE FUNCTION public.assert_secondary_retraction_approval(p_ok boolean) RETURNS void
CREATE FUNCTION public.attach_evidence(p_tenant_id uuid, p_project_id uuid, p_evidence_class text, p_document_type text, p_target_record_type text, p_target_record_id uuid, p_node_payload_json jsonb DEFAULT '{}'::jsonb) RETURNS uuid
CREATE FUNCTION public.attempt_lifecycle_transition(p_tenant_id uuid, p_subject_type text, p_subject_id uuid, p_from_status text, p_to_status text, p_jurisdiction_code text DEFAULT NULL::text) RETURNS text
CREATE FUNCTION public.authority_decisions_append_only() RETURNS trigger
CREATE FUNCTION public.authorize_escrow_reservation(p_program_escrow_id uuid, p_amount_minor bigint, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS uuid
CREATE FUNCTION public.block_active_reference_policy_updates() RETURNS trigger
CREATE FUNCTION public.bump_participant_outbox_seq(p_participant_id text) RETURNS bigint
CREATE FUNCTION public.canonicalize_reference_for_rail(p_allocated_reference text, p_rail_id text) RETURNS text
CREATE FUNCTION public.check_reg26_separation(p_verifier_id uuid, p_project_id uuid, p_requested_role text) RETURNS void
CREATE FUNCTION public.claim_anchor_sync_operation(p_worker_id text, p_lease_seconds integer DEFAULT 30) RETURNS TABLE(operation_id uuid, pack_id uuid, lease_token uuid, state text, attempt_count integer)
CREATE FUNCTION public.claim_outbox_batch(p_batch_size integer, p_worker_id text, p_lease_seconds integer) RETURNS TABLE(outbox_id uuid, instruction_id text, participant_id text, sequence_id bigint, idempotency_key text, rail_type text, payload jsonb, attempt_count integer, lease_token uuid, lease_expires_at timestamp with time zone)
CREATE FUNCTION public.classify_orphan_or_replay(p_instruction_id text, p_event_fingerprint text, p_is_late_callback boolean, p_is_duplicate_dispatch boolean, p_has_unknown_reference boolean, p_is_replay boolean) RETURNS public.orphan_classification_enum
CREATE FUNCTION public.cleanup_expired_verifier_tokens() RETURNS integer
CREATE FUNCTION public.complete_anchor_sync_operation(p_operation_id uuid, p_lease_token uuid, p_worker_id text) RETURNS void
CREATE FUNCTION public.complete_outbox_attempt(p_outbox_id uuid, p_lease_token uuid, p_worker_id text, p_state public.outbox_attempt_state, p_rail_reference text DEFAULT NULL::text, p_rail_code text DEFAULT NULL::text, p_error_code text DEFAULT NULL::text, p_error_message text DEFAULT NULL::text, p_latency_ms integer DEFAULT NULL::integer, p_retry_delay_seconds integer DEFAULT 1) RETURNS TABLE(attempt_no integer, state public.outbox_attempt_state)
CREATE FUNCTION public.compute_effect_seal_hash(p_instruction_id text, p_payload jsonb, p_canonicalization_version text) RETURNS text
CREATE FUNCTION public.create_internal_ledger_journal(p_tenant_id uuid, p_idempotency_key text, p_journal_type text, p_currency_code text, p_postings jsonb, p_reference_id text DEFAULT NULL::text) RETURNS uuid
CREATE FUNCTION public.current_jurisdiction_code_or_null() RETURNS text
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
CREATE FUNCTION public.deny_state_transitions_mutation() RETURNS trigger
CREATE FUNCTION public.derive_sim_swap_alert(p_event_id uuid) RETURNS uuid
CREATE FUNCTION public.enforce_adjustment_terminal_immutability() RETURNS trigger
CREATE FUNCTION public.enforce_asset_batch_authority() RETURNS trigger
CREATE FUNCTION public.enforce_confidence_before_issuance() RETURNS trigger
CREATE FUNCTION public.enforce_execution_binding() RETURNS trigger
CREATE FUNCTION public.enforce_instruction_reversal_source() RETURNS trigger
CREATE FUNCTION public.enforce_internal_ledger_posting_context() RETURNS trigger
CREATE FUNCTION public.enforce_member_tenant_match() RETURNS trigger
CREATE FUNCTION public.enforce_monitoring_authority() RETURNS trigger
CREATE FUNCTION public.enforce_settlement_acknowledgement() RETURNS trigger
CREATE FUNCTION public.enforce_state_transition_authority() RETURNS trigger
CREATE FUNCTION public.enforce_transition_authority() RETURNS trigger
CREATE FUNCTION public.enforce_transition_signature() RETURNS trigger
CREATE FUNCTION public.enforce_transition_state_rules() RETURNS trigger
CREATE FUNCTION public.enqueue_payment_outbox(p_instruction_id text, p_participant_id text, p_idempotency_key text, p_rail_type text, p_payload jsonb) RETURNS TABLE(outbox_id uuid, sequence_id bigint, created_at timestamp with time zone, state text)
CREATE FUNCTION public.ensure_anchor_sync_operation(p_pack_id uuid, p_anchor_provider text DEFAULT 'GENERIC'::text) RETURNS uuid
CREATE FUNCTION public.escalate_missing_acknowledgement(p_instruction_id text, p_program_id uuid, p_policy_version_id text, p_actor text DEFAULT 'system'::text, p_reason text DEFAULT 'missing_acknowledgement'::text, p_timeout_minutes integer DEFAULT 30) RETURNS void
CREATE FUNCTION public.evaluate_adjustment_ceiling(p_adjustment_id uuid, p_parent_instruction_value numeric) RETURNS void
CREATE FUNCTION public.evaluate_circuit_breaker(p_adapter_id text, p_rail_id text, p_trigger_threshold numeric, p_observed_rate numeric, p_window_seconds integer, p_policy_version_id text) RETURNS text
CREATE FUNCTION public.execute_pii_purge(p_purge_request_id uuid, p_executor text) RETURNS TABLE(purge_request_id uuid, rows_affected integer, already_purged boolean)
CREATE FUNCTION public.expire_escrows(p_now timestamp with time zone DEFAULT now(), p_actor_id text DEFAULT 'escrow_expiry_worker'::text) RETURNS integer
CREATE FUNCTION public.expire_supervisor_approvals(p_now timestamp with time zone DEFAULT now()) RETURNS integer
CREATE FUNCTION public.get_checkpoint_requirements(p_jurisdiction_code text) RETURNS TABLE(lifecycle_checkpoint_rule_id uuid, regulatory_checkpoint_id uuid, rule_type text, rule_payload_json jsonb)
CREATE FUNCTION public.get_evidence_node(p_tenant_id uuid, p_evidence_node_id uuid) RETURNS TABLE(evidence_node_id uuid, project_id uuid, monitoring_record_id uuid, node_type text, node_payload_json jsonb, created_at timestamp with time zone)
CREATE FUNCTION public.get_monitoring_record_payload(p_tenant_id uuid, p_monitoring_record_id uuid) RETURNS jsonb
CREATE FUNCTION public.gf_verifier_read_tokens_append_only() RETURNS trigger
CREATE FUNCTION public.gf_verifier_tables_append_only() RETURNS trigger
CREATE FUNCTION public.guard_auto_finalize_when_inquiry_exhausted(p_instruction_id text) RETURNS void
CREATE FUNCTION public.guard_settlement_requires_acknowledgement(p_instruction_id text) RETURNS void
CREATE FUNCTION public.issue_adjustment(p_parent_instruction_id text, p_adjustment_type text, p_adjustment_value numeric, p_policy_version_id text, p_justification text DEFAULT NULL::text) RETURNS uuid
CREATE FUNCTION public.issue_adjustment_with_recipient(p_parent_instruction_id text, p_recipient text) RETURNS uuid
CREATE FUNCTION public.issue_asset_batch(p_tenant_id uuid, p_project_id uuid, p_methodology_version_id uuid, p_adapter_registration_id uuid, p_interpretation_pack_id uuid, p_asset_type text, p_quantity numeric, p_unit text, p_metadata_json jsonb DEFAULT '{}'::jsonb) RETURNS uuid
CREATE FUNCTION public.issue_verifier_read_token(p_tenant_id uuid, p_verifier_id uuid, p_project_id uuid, p_ttl_hours integer DEFAULT 720, p_scoped_tables jsonb DEFAULT '["evidence_nodes", "monitoring_records", "asset_batches", "verification_cases"]'::jsonb) RETURNS TABLE(token_id uuid, token_secret text, expires_at timestamp with time zone)
CREATE FUNCTION public.link_evidence_to_record(p_tenant_id uuid, p_evidence_node_id uuid, p_target_evidence_node_id uuid, p_edge_type text) RETURNS uuid
CREATE FUNCTION public.list_project_asset_batches(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(asset_batch_id uuid, batch_type text, quantity numeric, status text, total_retired numeric, remaining_quantity numeric, created_at timestamp with time zone)
CREATE FUNCTION public.list_project_evidence(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(evidence_node_id uuid, node_type text, monitoring_record_id uuid, created_at timestamp with time zone)
CREATE FUNCTION public.list_tenant_projects(p_tenant_id uuid) RETURNS TABLE(project_id uuid, name text, status text, created_at timestamp with time zone)
CREATE FUNCTION public.list_verifier_tokens(p_tenant_id uuid, p_verifier_id uuid) RETURNS TABLE(token_id uuid, project_id uuid, scoped_tables jsonb, issued_at timestamp with time zone, expires_at timestamp with time zone, revoked_at timestamp with time zone, is_valid boolean)
CREATE FUNCTION public.mark_anchor_sync_anchored(p_operation_id uuid, p_lease_token uuid, p_worker_id text, p_anchor_ref text, p_anchor_type text DEFAULT 'HYBRID_SYNC'::text) RETURNS void
CREATE FUNCTION public.mark_instruction_awaiting_execution(p_instruction_id text, p_program_id uuid, p_policy_version_id text, p_actor text DEFAULT 'system'::text) RETURNS public.inquiry_state_enum
CREATE FUNCTION public.migrate_person_to_program(p_tenant_id uuid, p_person_id uuid, p_from_program_id uuid, p_to_program_id uuid, p_migrated_by text DEFAULT CURRENT_USER, p_reason text DEFAULT 'program_migration'::text, p_formula_key text DEFAULT 'TIER1_DETERMINISTIC_DEFAULT'::text) RETURNS uuid
CREATE FUNCTION public.migrate_person_to_program(p_tenant_id uuid, p_person_id uuid, p_from_program_id uuid, p_to_program_id uuid, p_new_entity_id uuid, p_reason text DEFAULT NULL::text) RETURNS uuid
CREATE FUNCTION public.outbox_retry_ceiling() RETURNS integer
CREATE FUNCTION public.quarantine_malformed_response(p_adapter_id text, p_rail_id text, p_classification public.quarantine_classification_enum, p_payload text, p_truncate_kb integer, p_policy_version_id text) RETURNS uuid
CREATE FUNCTION public.query_asset_batch(p_tenant_id uuid, p_asset_batch_id uuid) RETURNS TABLE(asset_batch_id uuid, project_id uuid, batch_type text, quantity numeric, status text, total_retired numeric, remaining_quantity numeric, created_at timestamp with time zone)
CREATE FUNCTION public.query_authority_decisions(p_jurisdiction_code text, p_subject_id uuid DEFAULT NULL::uuid) RETURNS TABLE(authority_decision_id uuid, regulatory_authority_id uuid, decision_type text, decision_outcome text, subject_type text, subject_id text, from_status text, to_status text, created_at timestamp with time zone)
CREATE FUNCTION public.query_evidence_lineage(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(evidence_node_id uuid, node_type text, monitoring_record_id uuid, evidence_edge_id uuid, source_node_id uuid, target_node_id uuid, edge_type text)
CREATE FUNCTION public.query_monitoring_records(p_tenant_id uuid, p_project_id uuid, p_record_type text DEFAULT NULL::text) RETURNS TABLE(monitoring_record_id uuid, project_id uuid, record_type text, record_payload_json jsonb, created_at timestamp with time zone)
CREATE FUNCTION public.query_project_details(p_tenant_id uuid, p_project_id uuid) RETURNS TABLE(project_id uuid, name text, status text, created_at timestamp with time zone)
CREATE FUNCTION public.record_asset_lifecycle_event(p_tenant_id uuid, p_asset_batch_id uuid, p_event_type text, p_event_payload jsonb DEFAULT '{}'::jsonb) RETURNS uuid
CREATE FUNCTION public.record_authority_decision(p_regulatory_authority_id uuid, p_jurisdiction_code text, p_decision_type text, p_decision_outcome text, p_subject_type text, p_subject_id uuid, p_from_status text, p_to_status text, p_interpretation_pack_id uuid DEFAULT NULL::uuid, p_decision_payload_json jsonb DEFAULT '{}'::jsonb) RETURNS uuid
CREATE FUNCTION public.record_late_callback(p_instruction_id text, p_payload jsonb, p_state_at_arrival text, p_fingerprint text) RETURNS uuid
CREATE FUNCTION public.record_mmo_reality_control(p_instruction_id text, p_scenario_type text, p_fallback_posture text, p_policy_version_id text, p_behavior_profile text, p_evidence_artifact_type text) RETURNS uuid
CREATE FUNCTION public.record_monitoring_record(p_tenant_id uuid, p_project_id uuid, p_record_type text, p_record_payload_json jsonb, p_methodology_version_id uuid DEFAULT NULL::uuid, p_event_timestamp timestamp with time zone DEFAULT NULL::timestamp with time zone, p_payload_schema_reference_id uuid DEFAULT NULL::uuid) RETURNS uuid
CREATE FUNCTION public.register_project(p_tenant_id uuid, p_project_name text, p_jurisdiction_code text, p_methodology_version_id uuid) RETURNS TABLE(project_id uuid, status text)
CREATE FUNCTION public.release_escrow(p_escrow_id uuid, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS uuid
CREATE FUNCTION public.repair_expired_anchor_sync_leases(p_worker_id text DEFAULT 'anchor_repair'::text) RETURNS integer
CREATE FUNCTION public.repair_expired_leases(p_batch_size integer, p_worker_id text) RETURNS TABLE(outbox_id uuid, attempt_no integer)
CREATE FUNCTION public.request_pii_purge(p_subject_token text, p_requested_by text, p_request_reason text) RETURNS uuid
CREATE FUNCTION public.resolve_interpretation_pack(p_project_id uuid, p_effective_at timestamp with time zone) RETURNS uuid
CREATE FUNCTION public.resolve_missing_acknowledgement_interrupt(p_instruction_id text, p_action text, p_actor text, p_reason text DEFAULT NULL::text) RETURNS public.inquiry_state_enum
CREATE FUNCTION public.resolve_reference_strategy(p_rail_id text) RETURNS TABLE(strategy_type public.reference_strategy_type_enum, rail_id text, max_length integer, nonce_retry_limit integer, collision_action text, policy_version_id text)
CREATE FUNCTION public.retire_asset_batch(p_tenant_id uuid, p_asset_batch_id uuid, p_retirement_reason text, p_interpretation_pack_id uuid, p_quantity numeric DEFAULT NULL::numeric) RETURNS uuid
CREATE FUNCTION public.revoke_verifier_read_token(p_tenant_id uuid, p_token_id uuid, p_reason text DEFAULT 'manual_revocation'::text) RETURNS void
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
CREATE FUNCTION public.transition_asset_status(p_tenant_id uuid, p_subject_id uuid, p_to_status text) RETURNS void
CREATE FUNCTION public.transition_escrow_state(p_escrow_id uuid, p_to_state text, p_actor_id text DEFAULT 'system'::text, p_reason text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb, p_now timestamp with time zone DEFAULT now()) RETURNS TABLE(escrow_id uuid, previous_state text, new_state text, event_id uuid)
CREATE FUNCTION public.update_current_state() RETURNS trigger
CREATE FUNCTION public.upgrade_authority_on_execution_binding() RETURNS trigger
CREATE FUNCTION public.uuid_strategy() RETURNS text
CREATE FUNCTION public.uuid_v7_or_random() RETURNS uuid
CREATE FUNCTION public.validate_confidence_score(p_asset_batch_id uuid) RETURNS TABLE(confidence_score numeric, required_threshold numeric, decision_count integer, approved_count integer, is_sufficient boolean)
CREATE FUNCTION public.validate_payload_against_schema(p_payload jsonb, p_payload_schema_reference_id uuid) RETURNS boolean
CREATE FUNCTION public.verify_dispatch_effect_seal(p_instruction_id text, p_outbound_payload jsonb) RETURNS void
CREATE FUNCTION public.verify_instruction_hierarchy(p_instruction_id text, p_tenant_id uuid, p_participant_id text, p_program_id uuid, p_entity_id uuid, p_member_id uuid, p_device_id text) RETURNS boolean
CREATE FUNCTION public.verify_internal_ledger_journal_balance(p_journal_id uuid) RETURNS boolean
CREATE FUNCTION public.verify_merkle_leaf(p_batch_id uuid, p_leaf_index integer, p_expected_leaf_hash text) RETURNS boolean
CREATE FUNCTION public.verify_policy_bundle_runtime(p_policy_bundle_id uuid) RETURNS void
CREATE FUNCTION public.verify_verifier_read_token(p_token_hash text, p_project_id uuid) RETURNS TABLE(token_id uuid, verifier_id uuid, scoped_tables jsonb, expires_at timestamp with time zone)
CREATE INDEX idx_adapter_registrations_adapter_code ON public.adapter_registrations USING btree (adapter_code);
CREATE INDEX idx_adapter_registrations_methodology ON public.adapter_registrations USING btree (methodology_code, methodology_authority);
CREATE INDEX idx_adapter_registrations_tenant_id ON public.adapter_registrations USING btree (tenant_id);
CREATE INDEX idx_anchor_sync_operations_state_due ON public.anchor_sync_operations USING btree (state, lease_expires_at, updated_at);
CREATE INDEX idx_asset_batches_project_id ON public.asset_batches USING btree (project_id);
CREATE INDEX idx_asset_batches_tenant_id ON public.asset_batches USING btree (tenant_id);
CREATE INDEX idx_asset_lifecycle_events_batch_id ON public.asset_lifecycle_events USING btree (asset_batch_id);
CREATE INDEX idx_asset_lifecycle_events_tenant_id ON public.asset_lifecycle_events USING btree (tenant_id);
CREATE INDEX idx_attempts_instruction_idempotency ON public.payment_outbox_attempts USING btree (instruction_id, idempotency_key);
CREATE INDEX idx_attempts_outbox_id ON public.payment_outbox_attempts USING btree (outbox_id);
CREATE INDEX idx_authority_decisions_jurisdiction ON public.authority_decisions USING btree (jurisdiction_code);
CREATE INDEX idx_billing_usage_events_correlation_id ON public.billing_usage_events USING btree (correlation_id);
CREATE INDEX idx_dispatch_reference_collision_events_instruction ON public.dispatch_reference_collision_events USING btree (instruction_id, created_at DESC);
CREATE INDEX idx_dispatch_reference_registry_adjustment ON public.dispatch_reference_registry USING btree (adjustment_id, allocation_timestamp DESC);
CREATE INDEX idx_dispatch_reference_registry_instruction ON public.dispatch_reference_registry USING btree (instruction_id, allocation_timestamp DESC);
CREATE INDEX idx_escrow_accounts_program ON public.escrow_accounts USING btree (program_id) WHERE (program_id IS NOT NULL);
CREATE INDEX idx_escrow_accounts_tenant_state ON public.escrow_accounts USING btree (tenant_id, state, authorization_expires_at, release_due_at);
CREATE INDEX idx_escrow_envelopes_tenant ON public.escrow_envelopes USING btree (tenant_id);
CREATE INDEX idx_escrow_events_escrow_created ON public.escrow_events USING btree (escrow_id, created_at);
CREATE INDEX idx_escrow_reservations_tenant_program ON public.escrow_reservations USING btree (tenant_id, program_escrow_id, created_at);
CREATE INDEX idx_evidence_edges_source ON public.evidence_edges USING btree (source_node_id);
CREATE INDEX idx_evidence_edges_target ON public.evidence_edges USING btree (target_node_id);
CREATE INDEX idx_evidence_edges_tenant_id ON public.evidence_edges USING btree (tenant_id);
CREATE INDEX idx_evidence_nodes_project_id ON public.evidence_nodes USING btree (project_id);
CREATE INDEX idx_evidence_nodes_tenant_id ON public.evidence_nodes USING btree (tenant_id);
CREATE INDEX idx_evidence_packs_anchor_ref ON public.evidence_packs USING btree (anchor_ref) WHERE (anchor_ref IS NOT NULL);
CREATE INDEX idx_evidence_packs_correlation_id ON public.evidence_packs USING btree (correlation_id);
CREATE INDEX idx_execution_records_interpretation_version_id ON public.execution_records USING btree (interpretation_version_id);
CREATE INDEX idx_execution_records_project_id ON public.execution_records USING btree (project_id);
CREATE INDEX idx_execution_records_timestamp ON public.execution_records USING btree (execution_timestamp);
CREATE INDEX idx_external_proofs_attestation_id ON public.external_proofs USING btree (attestation_id);
CREATE INDEX idx_factor_registry_code ON public.factor_registry USING btree (factor_code);
CREATE INDEX idx_factor_registry_unit ON public.factor_registry USING btree (unit);
CREATE INDEX idx_gf_verifier_read_tokens_expires ON public.gf_verifier_read_tokens USING btree (expires_at);
CREATE INDEX idx_gf_verifier_read_tokens_hash ON public.gf_verifier_read_tokens USING btree (token_hash);
CREATE INDEX idx_gf_verifier_read_tokens_project ON public.gf_verifier_read_tokens USING btree (project_id);
CREATE INDEX idx_gf_verifier_read_tokens_tenant ON public.gf_verifier_read_tokens USING btree (tenant_id);
CREATE INDEX idx_gf_verifier_read_tokens_verifier ON public.gf_verifier_read_tokens USING btree (verifier_id);
CREATE INDEX idx_ingress_attestations_cert_fpr ON public.ingress_attestations USING btree (cert_fingerprint_sha256) WHERE (cert_fingerprint_sha256 IS NOT NULL);
CREATE INDEX idx_ingress_attestations_correlation_id ON public.ingress_attestations USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_ingress_attestations_instruction ON public.ingress_attestations USING btree (instruction_id);
CREATE INDEX idx_ingress_attestations_member_received ON public.ingress_attestations USING btree (member_id, received_at) WHERE (member_id IS NOT NULL);
CREATE INDEX idx_ingress_attestations_received_at ON public.ingress_attestations USING btree (received_at);
CREATE INDEX idx_ingress_attestations_tenant_correlation ON public.ingress_attestations USING btree (tenant_id, correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_ingress_attestations_tenant_received ON public.ingress_attestations USING btree (tenant_id, received_at) WHERE (tenant_id IS NOT NULL);
CREATE INDEX idx_instruction_settlement_finality_participant_finalized ON public.instruction_settlement_finality USING btree (participant_id, finalized_at DESC);
CREATE INDEX idx_internal_ledger_postings_journal ON public.internal_ledger_postings USING btree (journal_id, direction);
CREATE INDEX idx_interpretation_packs_code ON public.interpretation_packs USING btree (interpretation_pack_code);
CREATE INDEX idx_interpretation_packs_jurisdiction ON public.interpretation_packs USING btree (jurisdiction_code);
CREATE INDEX idx_interpretation_packs_project_time ON public.interpretation_packs USING btree (project_id, effective_from DESC, effective_to);
CREATE INDEX idx_jurisdiction_profiles_jurisdiction ON public.jurisdiction_profiles USING btree (jurisdiction_code);
CREATE INDEX idx_lifecycle_checkpoint_rules_jurisdiction ON public.lifecycle_checkpoint_rules USING btree (jurisdiction_code);
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
CREATE INDEX idx_methodology_versions_tenant_id ON public.methodology_versions USING btree (tenant_id);
CREATE INDEX idx_monitoring_records_project_id ON public.monitoring_records USING btree (project_id);
CREATE INDEX idx_monitoring_records_tenant_id ON public.monitoring_records USING btree (tenant_id);
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
CREATE INDEX idx_projects_tenant_id ON public.projects USING btree (tenant_id);
CREATE INDEX idx_rail_truth_anchor_participant_anchored ON public.rail_dispatch_truth_anchor USING btree (rail_participant_id, anchored_at DESC);
CREATE INDEX idx_regulatory_authorities_jurisdiction ON public.regulatory_authorities USING btree (jurisdiction_code);
CREATE INDEX idx_regulatory_checkpoints_jurisdiction ON public.regulatory_checkpoints USING btree (jurisdiction_code);
CREATE INDEX idx_retirement_events_batch_id ON public.retirement_events USING btree (asset_batch_id);
CREATE INDEX idx_retirement_events_tenant_id ON public.retirement_events USING btree (tenant_id);
CREATE INDEX idx_sim_swap_alerts_tenant_member_derived ON public.sim_swap_alerts USING btree (tenant_id, member_id, derived_at DESC);
CREATE INDEX idx_state_transitions_project_id ON public.state_transitions USING btree (project_id);
CREATE INDEX idx_state_transitions_transition_timestamp ON public.state_transitions USING btree (transition_timestamp);
CREATE INDEX idx_supervisor_approval_queue_status_timeout ON public.supervisor_approval_queue USING btree (status, timeout_at);
CREATE INDEX idx_supervisor_audit_tokens_program_expires ON public.supervisor_audit_tokens USING btree (program_id, expires_at DESC);
CREATE INDEX idx_supervisor_interrupt_audit_events_instruction_recorded ON public.supervisor_interrupt_audit_events USING btree (instruction_id, recorded_at DESC);
CREATE INDEX idx_tenant_clients_tenant ON public.tenant_clients USING btree (tenant_id);
CREATE INDEX idx_tenant_members_status ON public.tenant_members USING btree (status);
CREATE INDEX idx_tenant_members_tenant ON public.tenant_members USING btree (tenant_id);
CREATE INDEX idx_tenants_billable_client_id ON public.tenants USING btree (billable_client_id);
CREATE INDEX idx_tenants_parent_tenant_id ON public.tenants USING btree (parent_tenant_id);
CREATE INDEX idx_tenants_status ON public.tenants USING btree (status);
CREATE INDEX idx_unit_conversions_from ON public.unit_conversions USING btree (from_unit);
CREATE INDEX idx_unit_conversions_pair ON public.unit_conversions USING btree (from_unit, to_unit);
CREATE INDEX idx_unit_conversions_to ON public.unit_conversions USING btree (to_unit);
CREATE INDEX idx_verifier_project_assignments_project ON public.verifier_project_assignments USING btree (project_id);
CREATE INDEX idx_verifier_project_assignments_verifier ON public.verifier_project_assignments USING btree (verifier_id);
CREATE INDEX idx_verifier_registry_jurisdiction ON public.verifier_registry USING btree (jurisdiction_code);
CREATE INDEX idx_verifier_registry_tenant_id ON public.verifier_registry USING btree (tenant_id);
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
CREATE POLICY authority_decisions_jurisdiction_access ON public.authority_decisions USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));
CREATE POLICY gf_verifier_read_tokens_tenant_isolation ON public.gf_verifier_read_tokens USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_jurisdiction_isolation_interpretation_packs ON public.interpretation_packs USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));
CREATE POLICY rls_jurisdiction_isolation_jurisdiction_profiles ON public.jurisdiction_profiles USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));
CREATE POLICY rls_jurisdiction_isolation_lifecycle_checkpoint_rules ON public.lifecycle_checkpoint_rules USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));
CREATE POLICY rls_jurisdiction_isolation_regulatory_authorities ON public.regulatory_authorities USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));
CREATE POLICY rls_jurisdiction_isolation_regulatory_checkpoints ON public.regulatory_checkpoints USING ((jurisdiction_code = public.current_jurisdiction_code_or_null())) WITH CHECK ((jurisdiction_code = public.current_jurisdiction_code_or_null()));
CREATE POLICY rls_tenant_isolation_adapter_registrations ON public.adapter_registrations USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_asset_batches ON public.asset_batches USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_asset_lifecycle_events ON public.asset_lifecycle_events USING ((EXISTS ( SELECT 1
CREATE POLICY rls_tenant_isolation_billing_usage_events ON public.billing_usage_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_escrow_accounts ON public.escrow_accounts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_escrow_envelopes ON public.escrow_envelopes AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_escrow_events ON public.escrow_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_escrow_reservations ON public.escrow_reservations AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_evidence_edges ON public.evidence_edges USING ((EXISTS ( SELECT 1
CREATE POLICY rls_tenant_isolation_evidence_nodes ON public.evidence_nodes USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_external_proofs ON public.external_proofs AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_ingress_attestations ON public.ingress_attestations AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_member_device_events ON public.member_device_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_member_devices ON public.member_devices AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_members ON public.members AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_methodology_versions ON public.methodology_versions USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_monitoring_records ON public.monitoring_records USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_payment_outbox_attempts ON public.payment_outbox_attempts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_payment_outbox_pending ON public.payment_outbox_pending AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_persons ON public.persons AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_program_migration_events ON public.program_migration_events AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_program_supplier_allowlist ON public.program_supplier_allowlist AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_programme_policy_binding ON public.programme_policy_binding USING (((tenant_id = (NULLIF(current_setting('app.current_tenant_id'::text, true), ''::text))::uuid) OR (current_setting('app.bypass_rls'::text, true) = 'on'::text)));
CREATE POLICY rls_tenant_isolation_programme_registry ON public.programme_registry USING (((tenant_id = (NULLIF(current_setting('app.current_tenant_id'::text, true), ''::text))::uuid) OR (current_setting('app.bypass_rls'::text, true) = 'on'::text)));
CREATE POLICY rls_tenant_isolation_programs ON public.programs AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_projects ON public.projects USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_retirement_events ON public.retirement_events USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_sim_swap_alerts ON public.sim_swap_alerts AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_supplier_registry ON public.supplier_registry AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_tenant_clients ON public.tenant_clients AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_tenant_members ON public.tenant_members AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_tenant_registry ON public.tenant_registry USING (((tenant_id = (NULLIF(current_setting('app.current_tenant_id'::text, true), ''::text))::uuid) OR (current_setting('app.bypass_rls'::text, true) = 'on'::text)));
CREATE POLICY rls_tenant_isolation_tenants ON public.tenants AS RESTRICTIVE USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE POLICY rls_tenant_isolation_verifier_project_assignments ON public.verifier_project_assignments USING ((EXISTS ( SELECT 1
CREATE POLICY rls_tenant_isolation_verifier_registry ON public.verifier_registry USING ((tenant_id = public.current_tenant_id_or_null())) WITH CHECK ((tenant_id = public.current_tenant_id_or_null()));
CREATE RULE kyc_retention_policy_no_delete AS
CREATE RULE kyc_retention_policy_no_update AS
CREATE SCHEMA public;
CREATE TABLE public.adapter_circuit_breakers (
CREATE TABLE public.adapter_registrations (
CREATE TABLE public.adjustment_approval_stages (
CREATE TABLE public.adjustment_approvals (
CREATE TABLE public.adjustment_execution_attempts (
CREATE TABLE public.adjustment_freeze_flags (
CREATE TABLE public.adjustment_instructions (
CREATE TABLE public.anchor_backfill_jobs (
CREATE TABLE public.anchor_sync_operations (
CREATE TABLE public.archive_verification_runs (
CREATE TABLE public.artifact_signing_batch_items (
CREATE TABLE public.artifact_signing_batches (
CREATE TABLE public.asset_batches (
CREATE TABLE public.asset_lifecycle_events (
CREATE TABLE public.audit_tamper_evident_chains (
CREATE TABLE public.authority_decisions (
CREATE TABLE public.billable_clients (
CREATE TABLE public.billing_usage_events (
CREATE TABLE public.boz_operational_scenario_runs (
CREATE TABLE public.canonicalization_archive_snapshots (
CREATE TABLE public.canonicalization_registry (
CREATE TABLE public.dispatch_reference_collision_events (
CREATE TABLE public.dispatch_reference_registry (
CREATE TABLE public.effect_seal_mismatch_events (
CREATE TABLE public.escrow_accounts (
CREATE TABLE public.escrow_envelopes (
CREATE TABLE public.escrow_events (
CREATE TABLE public.escrow_reservations (
CREATE TABLE public.escrow_summary_projection (
CREATE TABLE public.evidence_bundle_projection (
CREATE TABLE public.evidence_edges (
CREATE TABLE public.evidence_nodes (
CREATE TABLE public.evidence_pack_items (
CREATE TABLE public.evidence_packs (
CREATE TABLE public.execution_records (
CREATE TABLE public.external_proofs (
CREATE TABLE public.factor_registry (
CREATE TABLE public.gf_verifier_read_tokens (
CREATE TABLE public.global_rate_limit_policies (
CREATE TABLE public.historical_verification_runs (
CREATE TABLE public.hsm_fail_closed_events (
CREATE TABLE public.incident_case_projection (
CREATE TABLE public.incident_events (
CREATE TABLE public.ingress_attestations (
CREATE TABLE public.inquiry_state_machine (
CREATE TABLE public.instruction_effect_seals (
CREATE TABLE public.instruction_finality_conflicts (
CREATE TABLE public.instruction_settlement_finality (
CREATE TABLE public.instruction_status_projection (
CREATE TABLE public.internal_ledger_journals (
CREATE TABLE public.internal_ledger_postings (
CREATE TABLE public.interpretation_packs (
CREATE TABLE public.jurisdiction_profiles (
CREATE TABLE public.key_rotation_drills (
CREATE TABLE public.kyc_provider_registry (
CREATE TABLE public.kyc_retention_policy (
CREATE TABLE public.kyc_verification_records (
CREATE TABLE public.levy_calculation_records (
CREATE TABLE public.levy_rates (
CREATE TABLE public.levy_remittance_periods (
CREATE TABLE public.lifecycle_checkpoint_rules (
CREATE TABLE public.malformed_quarantine_store (
CREATE TABLE public.member_device_events (
CREATE TABLE public.member_devices (
CREATE TABLE public.members (
CREATE TABLE public.methodology_versions (
CREATE TABLE public.mmo_reality_control_events (
CREATE TABLE public.monitoring_records (
CREATE TABLE public.offline_safe_mode_windows (
CREATE TABLE public.orphaned_attestation_landing_zone (
CREATE TABLE public.participant_outbox_sequences (
CREATE TABLE public.participants (
CREATE TABLE public.payment_outbox_attempts (
CREATE TABLE public.payment_outbox_pending (
CREATE TABLE public.penalty_defense_packs (
CREATE TABLE public.persons (
CREATE TABLE public.pii_erased_subject_placeholders (
CREATE TABLE public.pii_erasure_journal (
CREATE TABLE public.pii_purge_events (
CREATE TABLE public.pii_purge_requests (
CREATE TABLE public.pii_tokenization_registry (
CREATE TABLE public.pii_vault_records (
CREATE TABLE public.policy_bundles (
CREATE TABLE public.policy_versions (
CREATE TABLE public.program_member_summary_projection (
CREATE TABLE public.program_migration_events (
CREATE TABLE public.program_supplier_allowlist (
CREATE TABLE public.programme_policy_binding (
CREATE TABLE public.programme_registry (
CREATE TABLE public.programs (
CREATE TABLE public.projects (
CREATE TABLE public.proof_pack_batch_leaves (
CREATE TABLE public.proof_pack_batches (
CREATE TABLE public.rail_dispatch_truth_anchor (
CREATE TABLE public.redaction_audit_events (
CREATE TABLE public.reference_strategy_policy_versions (
CREATE TABLE public.regulatory_authorities (
CREATE TABLE public.regulatory_checkpoints (
CREATE TABLE public.regulatory_incidents (
CREATE TABLE public.regulatory_report_submission_attempts (
CREATE TABLE public.regulatory_retraction_approvals (
CREATE TABLE public.resign_sweeps (
CREATE TABLE public.retirement_events (
CREATE TABLE public.revoked_client_certs (
CREATE TABLE public.revoked_tokens (
CREATE TABLE public.risk_formula_versions (
CREATE TABLE public.schema_migrations (
CREATE TABLE public.signing_audit_log (
CREATE TABLE public.signing_authorization_matrix (
CREATE TABLE public.signing_throughput_runs (
CREATE TABLE public.sim_swap_alerts (
CREATE TABLE public.state_current (
CREATE TABLE public.state_transitions (
CREATE TABLE public.supervisor_access_policies (
CREATE TABLE public.supervisor_approval_queue (
CREATE TABLE public.supervisor_audit_tokens (
CREATE TABLE public.supervisor_interrupt_audit_events (
CREATE TABLE public.supplier_registry (
CREATE TABLE public.tenant_clients (
CREATE TABLE public.tenant_members (
CREATE TABLE public.tenant_registry (
CREATE TABLE public.tenants (
CREATE TABLE public.unit_conversions (
CREATE TABLE public.verifier_project_assignments (
CREATE TABLE public.verifier_registry (
CREATE TRIGGER adapter_registrations_append_only BEFORE DELETE OR UPDATE ON public.adapter_registrations FOR EACH ROW EXECUTE FUNCTION public.adapter_registrations_append_only_trigger();
CREATE TRIGGER asset_lifecycle_confidence_enforcement BEFORE INSERT ON public.asset_lifecycle_events FOR EACH ROW EXECUTE FUNCTION public.enforce_confidence_before_issuance();
CREATE TRIGGER authority_decisions_append_only BEFORE DELETE OR UPDATE ON public.authority_decisions FOR EACH ROW EXECUTE FUNCTION public.authority_decisions_append_only();
CREATE TRIGGER gf_verifier_read_tokens_append_only BEFORE DELETE OR UPDATE ON public.gf_verifier_read_tokens FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_read_tokens_append_only();
CREATE TRIGGER tr_deny_state_transitions_mutation BEFORE DELETE OR UPDATE ON public.state_transitions FOR EACH ROW EXECUTE FUNCTION public.deny_state_transitions_mutation();
CREATE TRIGGER tr_enforce_execution_binding BEFORE INSERT OR UPDATE ON public.state_transitions FOR EACH ROW EXECUTE FUNCTION public.enforce_execution_binding();
CREATE TRIGGER tr_enforce_transition_authority BEFORE INSERT OR UPDATE ON public.state_transitions FOR EACH ROW EXECUTE FUNCTION public.enforce_transition_authority();
CREATE TRIGGER tr_enforce_transition_signature BEFORE INSERT OR UPDATE ON public.state_transitions FOR EACH ROW EXECUTE FUNCTION public.enforce_transition_signature();
CREATE TRIGGER tr_enforce_transition_state_rules BEFORE INSERT OR UPDATE ON public.state_transitions FOR EACH ROW EXECUTE FUNCTION public.enforce_transition_state_rules();
CREATE TRIGGER tr_update_current_state AFTER INSERT ON public.state_transitions FOR EACH ROW EXECUTE FUNCTION public.update_current_state();
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
CREATE TRIGGER trg_deny_internal_ledger_journals_mutation BEFORE DELETE OR UPDATE ON public.internal_ledger_journals FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_internal_ledger_postings_mutation BEFORE DELETE OR UPDATE ON public.internal_ledger_postings FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_member_device_events_mutation BEFORE DELETE OR UPDATE ON public.member_device_events FOR EACH ROW EXECUTE FUNCTION public.deny_member_device_events_mutation();
CREATE TRIGGER trg_deny_outbox_attempts_mutation BEFORE DELETE OR UPDATE ON public.payment_outbox_attempts FOR EACH ROW EXECUTE FUNCTION public.deny_outbox_attempts_mutation();
CREATE TRIGGER trg_deny_pii_purge_events_mutation BEFORE DELETE OR UPDATE ON public.pii_purge_events FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_pii_purge_requests_mutation BEFORE DELETE OR UPDATE ON public.pii_purge_requests FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_pii_vault_mutation BEFORE DELETE OR UPDATE ON public.pii_vault_records FOR EACH ROW EXECUTE FUNCTION public.deny_pii_vault_mutation();
CREATE TRIGGER trg_deny_rail_dispatch_truth_anchor_mutation BEFORE DELETE OR UPDATE ON public.rail_dispatch_truth_anchor FOR EACH ROW EXECUTE FUNCTION public.deny_append_only_mutation();
CREATE TRIGGER trg_deny_revoked_client_certs_mutation BEFORE DELETE OR UPDATE ON public.revoked_client_certs FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();
CREATE TRIGGER trg_deny_revoked_tokens_mutation BEFORE DELETE OR UPDATE ON public.revoked_tokens FOR EACH ROW EXECUTE FUNCTION public.deny_revocation_mutation();
CREATE TRIGGER trg_deny_sim_swap_alerts_mutation BEFORE DELETE OR UPDATE ON public.sim_swap_alerts FOR EACH ROW EXECUTE FUNCTION public.deny_sim_swap_alerts_mutation();
CREATE TRIGGER trg_enforce_asset_batch_authority BEFORE INSERT OR UPDATE ON public.asset_batches FOR EACH ROW EXECUTE FUNCTION public.enforce_asset_batch_authority();
CREATE TRIGGER trg_enforce_instruction_reversal_source BEFORE INSERT ON public.instruction_settlement_finality FOR EACH ROW EXECUTE FUNCTION public.enforce_instruction_reversal_source();
CREATE TRIGGER trg_enforce_internal_ledger_posting_context BEFORE INSERT OR UPDATE ON public.internal_ledger_postings FOR EACH ROW EXECUTE FUNCTION public.enforce_internal_ledger_posting_context();
CREATE TRIGGER trg_enforce_monitoring_authority BEFORE INSERT OR UPDATE ON public.monitoring_records FOR EACH ROW EXECUTE FUNCTION public.enforce_monitoring_authority();
CREATE TRIGGER trg_enforce_settlement_acknowledgement BEFORE INSERT ON public.instruction_settlement_finality FOR EACH ROW EXECUTE FUNCTION public.enforce_settlement_acknowledgement();
CREATE TRIGGER trg_enforce_state_transition_authority BEFORE INSERT OR UPDATE ON public.state_transitions FOR EACH ROW EXECUTE FUNCTION public.enforce_state_transition_authority();
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
CREATE TRIGGER trg_upgrade_authority_on_execution_binding BEFORE INSERT OR UPDATE ON public.state_transitions FOR EACH ROW EXECUTE FUNCTION public.upgrade_authority_on_execution_binding();
CREATE TRIGGER verifier_project_assignments_no_mutate BEFORE DELETE OR UPDATE ON public.verifier_project_assignments FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tables_append_only();
CREATE TRIGGER verifier_registry_no_mutate BEFORE DELETE OR UPDATE ON public.verifier_registry FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tables_append_only();
CREATE TYPE public.adjustment_state_enum AS ENUM (
CREATE TYPE public.data_authority_level AS ENUM (
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
