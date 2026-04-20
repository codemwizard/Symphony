-- Migration 0133: execution_records triggers (append-only + temporal binding)
-- Task: TSK-P2-PREAUTH-003-REM-03
-- Casefile: REM-2026-04-20_execution-truth-anchor
-- Invariant: INV-EXEC-TRUTH-001 (enforcement surface #3 + #4)
--
-- Two BEFORE triggers on public.execution_records:
--   (1) execution_records_append_only_trigger (BEFORE UPDATE OR DELETE) -> GF056
--       mirrors the 0127 project_boundaries_append_only pattern.
--   (2) execution_records_temporal_binding_trigger (BEFORE INSERT) -> GF058
--       delegates to resolve_interpretation_pack() from 0116.
--
-- Both functions are SECURITY DEFINER with SET search_path = pg_catalog, public
-- (AGENTS.md hardening requirement) and have EXECUTE revoked from PUBLIC.
--
-- NOTE: do NOT add top-level BEGIN/COMMIT. scripts/db/migrate.sh wraps every
-- migration in its own transaction (see migrate.sh:158-166); a top-level
-- COMMIT here would prematurely close the outer transaction.

-- ─── Append-only enforcement (GF056) ────────────────────────────────
CREATE OR REPLACE FUNCTION public.execution_records_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'GF056: execution_records is append-only, UPDATE/DELETE not allowed'
        USING ERRCODE = 'GF056';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER execution_records_append_only_trigger
BEFORE UPDATE OR DELETE ON public.execution_records
FOR EACH ROW EXECUTE FUNCTION public.execution_records_append_only();

REVOKE ALL ON FUNCTION public.execution_records_append_only() FROM PUBLIC;

-- ─── Temporal-binding enforcement (GF058) ───────────────────────────
-- Delegates to resolve_interpretation_pack(project_id, at_ts) introduced in 0116.
CREATE OR REPLACE FUNCTION public.enforce_execution_interpretation_temporal_binding()
RETURNS TRIGGER AS $$
DECLARE
    v_expected UUID;
BEGIN
    SELECT public.resolve_interpretation_pack(NEW.project_id, NEW.execution_timestamp)
        INTO v_expected;

    IF v_expected IS DISTINCT FROM NEW.interpretation_version_id THEN
        RAISE EXCEPTION
            'GF058: execution_records.interpretation_version_id temporal mismatch; expected pack resolved at execution_timestamp'
            USING ERRCODE = 'GF058';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

CREATE TRIGGER execution_records_temporal_binding_trigger
BEFORE INSERT ON public.execution_records
FOR EACH ROW EXECUTE FUNCTION public.enforce_execution_interpretation_temporal_binding();

REVOKE ALL ON FUNCTION public.enforce_execution_interpretation_temporal_binding() FROM PUBLIC;

COMMENT ON FUNCTION public.execution_records_append_only() IS
    'INV-EXEC-TRUTH-001 enforcement #3: execution_records is append-only. Raises GF056 on UPDATE/DELETE.';
COMMENT ON FUNCTION public.enforce_execution_interpretation_temporal_binding() IS
    'INV-EXEC-TRUTH-001 enforcement #4: interpretation_version_id must equal resolve_interpretation_pack(project_id, execution_timestamp). Raises GF058 on mismatch.';
