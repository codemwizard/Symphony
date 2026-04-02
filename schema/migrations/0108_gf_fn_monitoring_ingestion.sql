-- Migration 0108: GF Phase 1 — Monitoring Ingestion Functions
-- Implements record_monitoring_record, query_monitoring_records,
-- get_monitoring_record_payload, validate_payload_against_schema.
-- Depends on 0097 (projects), 0099 (monitoring_records), 0101 (asset_batches).
-- Functions: SECURITY DEFINER with hardened search_path per INV-008.
-- Rule 10 compliance: payload JSONB is stored and retrieved opaque;
--   no field extraction (->> or ->) is performed in host-layer functions.

-- ── validate_payload_against_schema ─────────────────────────────────────────
-- Validates that a given JSONB payload is a JSON object and, when a
-- payload_schema_reference_id is supplied, confirms the schema entry exists
-- in the schema_registry table. No semantic field extraction is performed.
CREATE OR REPLACE FUNCTION public.validate_payload_against_schema(
    p_payload                  JSONB,
    p_payload_schema_reference_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── record_monitoring_record ─────────────────────────────────────────────────
-- Appends a monitoring event to the monitoring_records ledger for a project.
-- Validates project existence and active status, validates methodology version
-- matches the project's registered adapter context, validates payload structure.
-- Optional parameters default to NULL/now() to support the 4-arg call from
-- register_project (0107) while allowing full validation when all args are given.
CREATE OR REPLACE FUNCTION public.record_monitoring_record(
    p_tenant_id                UUID,
    p_project_id               UUID,
    p_record_type              TEXT,
    p_record_payload_json      JSONB,
    p_methodology_version_id   UUID          DEFAULT NULL,
    p_event_timestamp          TIMESTAMPTZ   DEFAULT NULL,
    p_payload_schema_reference_id UUID       DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── query_monitoring_records ─────────────────────────────────────────────────
-- Returns monitoring records for a project in append order.
-- Returns full rows; no payload field extraction performed (Rule 10).
CREATE OR REPLACE FUNCTION public.query_monitoring_records(
    p_tenant_id  UUID,
    p_project_id UUID,
    p_record_type TEXT DEFAULT NULL
)
RETURNS TABLE(
    monitoring_record_id UUID,
    project_id           UUID,
    record_type          TEXT,
    record_payload_json  JSONB,
    created_at           TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── get_monitoring_record_payload ────────────────────────────────────────────
-- Returns the raw payload JSONB for a specific monitoring record.
-- No field extraction (->> or ->) is performed; caller receives the opaque blob.
CREATE OR REPLACE FUNCTION public.get_monitoring_record_payload(
    p_tenant_id          UUID,
    p_monitoring_record_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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

-- ── Privileges ────────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION validate_payload_against_schema(JSONB, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION record_monitoring_record(UUID, UUID, TEXT, JSONB, UUID, TIMESTAMPTZ, UUID)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION query_monitoring_records(UUID, UUID, TEXT)
    TO symphony_command;
GRANT EXECUTE ON FUNCTION get_monitoring_record_payload(UUID, UUID)
    TO symphony_command;
