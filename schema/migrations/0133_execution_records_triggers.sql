-- Migration 0133: execution_records append-only + temporal-binding triggers
-- Task: TSK-P2-PREAUTH-003-REM-03
-- Casefile: REM-2026-04-20_execution-truth-anchor
-- Invariant (declared, not-yet-implemented until REM-05 emits evidence): INV-EXEC-TRUTH-001
--
-- Installs two BEFORE triggers on public.execution_records:
--   1. execution_records_append_only_trigger (BEFORE UPDATE OR DELETE)
--      Raises GF056 unconditionally. Mirrors the project_boundaries_append_only
--      pattern in migration 0127.
--   2. execution_records_temporal_binding_trigger (BEFORE INSERT)
--      Raises GF058 when the caller-supplied interpretation_version_id does
--      not equal resolve_interpretation_pack(NEW.project_id, NEW.execution_timestamp).
--      Enforces version-at-time-of-execution binding. Closes the temporal
--      correctness gap raised in the DRD casefile.
--
-- Both trigger functions are SECURITY DEFINER with SET search_path = pg_catalog,
-- public per AGENTS.md hardening. Forward-only: no edit to 0118 / 0131 / 0132.
-- No runtime DDL. REVOKE-first privilege posture.

-- ─── Append-only trigger (GF056) ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.execution_records_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    RAISE EXCEPTION 'GF056: execution_records is append-only, UPDATE/DELETE not allowed'
        USING ERRCODE = 'GF056';
    RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.execution_records_append_only() FROM PUBLIC;

DROP TRIGGER IF EXISTS execution_records_append_only_trigger ON public.execution_records;
CREATE TRIGGER execution_records_append_only_trigger
BEFORE UPDATE OR DELETE ON public.execution_records
FOR EACH ROW EXECUTE FUNCTION public.execution_records_append_only();

COMMENT ON FUNCTION public.execution_records_append_only() IS
    'Append-only guard for execution_records. Raises GF056 on UPDATE/DELETE. INV-EXEC-TRUTH-001.';

-- ─── Temporal-binding trigger (GF058) ─────────────────────────────
CREATE OR REPLACE FUNCTION public.enforce_execution_interpretation_temporal_binding()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_expected_pack_id UUID;
BEGIN
    -- Resolve the interpretation pack that was active for the row's project at
    -- its execution_timestamp. Callers MUST supply interpretation_version_id
    -- that matches this temporally-resolved identity, never a "latest active"
    -- pointer at query time.
    v_expected_pack_id := public.resolve_interpretation_pack(NEW.project_id, NEW.execution_timestamp);

    IF v_expected_pack_id IS NULL THEN
        RAISE EXCEPTION
            'GF058: no interpretation_pack resolvable for project_id=% at execution_timestamp=%; temporal binding violated',
            NEW.project_id, NEW.execution_timestamp
            USING ERRCODE = 'GF058';
    END IF;

    IF NEW.interpretation_version_id IS DISTINCT FROM v_expected_pack_id THEN
        RAISE EXCEPTION
            'GF058: interpretation_version_id=% does not match temporally-resolved pack=% for project_id=% at execution_timestamp=%',
            NEW.interpretation_version_id, v_expected_pack_id, NEW.project_id, NEW.execution_timestamp
            USING ERRCODE = 'GF058';
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_execution_interpretation_temporal_binding() FROM PUBLIC;

DROP TRIGGER IF EXISTS execution_records_temporal_binding_trigger ON public.execution_records;
CREATE TRIGGER execution_records_temporal_binding_trigger
BEFORE INSERT ON public.execution_records
FOR EACH ROW EXECUTE FUNCTION public.enforce_execution_interpretation_temporal_binding();

COMMENT ON FUNCTION public.enforce_execution_interpretation_temporal_binding() IS
    'Temporal-binding guard for execution_records. Raises GF058 when interpretation_version_id does not match resolve_interpretation_pack(project_id, execution_timestamp). INV-EXEC-TRUTH-001.';
