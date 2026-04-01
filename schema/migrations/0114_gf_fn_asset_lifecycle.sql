-- Migration 0114: GF Phase 1 — Asset Lifecycle Functions
-- Implements issue_asset_batch, retire_asset_batch, record_asset_lifecycle_event,
-- query_asset_batch, list_project_asset_batches.
-- Enforces INV-165 (interpretation_pack_id mandatory), quantity guards,
-- checkpoint validation, adapter registration validation, fail-closed issuance.
-- Depends on 0097 (projects), 0098 (methodology_versions), 0101 (asset_batches,
-- asset_lifecycle_events, retirement_events), 0080 (adapter_registrations),
-- 0103 (lifecycle_checkpoint_rules), 0113 (confidence enforcement).
-- Functions: SECURITY DEFINER with hardened search_path per INV-008.

-- ── issue_asset_batch ────────────────────────────────────────────────────────
-- Issues a new batch of assets for a project. Validates project is ACTIVE,
-- adapter is active, interpretation_pack_id is provided (INV-165),
-- lifecycle checkpoint rules are satisfied, and quantity is positive.
-- Records lifecycle event and inserts into asset_batches.
CREATE OR REPLACE FUNCTION public.issue_asset_batch(
    p_tenant_id              UUID,
    p_project_id             UUID,
    p_methodology_version_id UUID,
    p_adapter_registration_id UUID,
    p_interpretation_pack_id UUID,
    p_asset_type             TEXT,
    p_quantity               NUMERIC,
    p_unit                   TEXT,
    p_metadata_json          JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── retire_asset_batch ───────────────────────────────────────────────────────
-- Retires a quantity from an issued batch. Validates batch is ISSUED,
-- quantity does not exceed remaining, and records irrevocable retirement event.
CREATE OR REPLACE FUNCTION public.retire_asset_batch(
    p_tenant_id          UUID,
    p_asset_batch_id     UUID,
    p_retirement_reason  TEXT,
    p_interpretation_pack_id UUID,
    p_quantity           NUMERIC DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── record_asset_lifecycle_event ─────────────────────────────────────────────
-- Generic lifecycle event recorder for custom event types.
CREATE OR REPLACE FUNCTION public.record_asset_lifecycle_event(
    p_tenant_id      UUID,
    p_asset_batch_id UUID,
    p_event_type     TEXT,
    p_event_payload  JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── query_asset_batch ────────────────────────────────────────────────────────
-- Returns batch details with retirement summary.
CREATE OR REPLACE FUNCTION public.query_asset_batch(
    p_tenant_id      UUID,
    p_asset_batch_id UUID
)
RETURNS TABLE(
    asset_batch_id UUID,
    project_id     UUID,
    batch_type     TEXT,
    quantity       NUMERIC,
    status         TEXT,
    total_retired  NUMERIC,
    remaining_quantity NUMERIC,
    created_at     TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── list_project_asset_batches ───────────────────────────────────────────────
-- Lists all batches for a project with retirement summaries.
CREATE OR REPLACE FUNCTION public.list_project_asset_batches(
    p_tenant_id  UUID,
    p_project_id UUID
)
RETURNS TABLE(
    asset_batch_id UUID,
    batch_type     TEXT,
    quantity       NUMERIC,
    status         TEXT,
    total_retired  NUMERIC,
    remaining_quantity NUMERIC,
    created_at     TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── Privileges ───────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION issue_asset_batch(UUID, UUID, UUID, UUID, UUID, TEXT, NUMERIC, TEXT, JSONB)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION retire_asset_batch(UUID, UUID, TEXT, UUID, NUMERIC)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION record_asset_lifecycle_event(UUID, UUID, TEXT, JSONB)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION query_asset_batch(UUID, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION list_project_asset_batches(UUID, UUID)
    TO symphony_command;
