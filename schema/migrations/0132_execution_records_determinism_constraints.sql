-- Migration 0132: Tighten execution_records determinism columns (contract phase)
-- Task: TSK-P2-PREAUTH-003-REM-02
-- Casefile: REM-2026-04-20_execution-truth-anchor
-- Invariant (declared, not-yet-implemented until REM-05 emits evidence): INV-EXEC-TRUTH-001
--
-- CONTRACT phase of the expand/contract pair (INV-097). Runs the backfill
-- precondition (GF057), then SET NOT NULL on the five determinism columns,
-- then adds the UNIQUE (input_hash, interpretation_version_id, runtime_version)
-- determinism anchor.
--
-- FK target remains interpretation_packs(interpretation_pack_id). Child column
-- is historically named interpretation_version_id (naming quirk documented in
-- INV-EXEC-TRUTH-001 notes). Forward-only: no edit to 0118 or 0131. No DDL
-- outside this migration. No runtime DDL.

-- ---- 1. Backfill precondition (GF057)
DO $$
DECLARE
    null_row_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO null_row_count
    FROM public.execution_records
    WHERE input_hash IS NULL
       OR output_hash IS NULL
       OR runtime_version IS NULL
       OR tenant_id IS NULL
       OR interpretation_version_id IS NULL;

    IF null_row_count > 0 THEN
        RAISE EXCEPTION
            'GF057: execution_records determinism backfill precondition failed: % row(s) still NULL. Two-strike rule: a second non-convergent attempt opens REM-02b.', null_row_count
            USING ERRCODE = 'GF057';
    END IF;
END $$;

-- ---- 2. SET NOT NULL on the five determinism columns
ALTER TABLE public.execution_records
    ALTER COLUMN input_hash                SET NOT NULL;
ALTER TABLE public.execution_records
    ALTER COLUMN output_hash               SET NOT NULL;
ALTER TABLE public.execution_records
    ALTER COLUMN runtime_version           SET NOT NULL;
ALTER TABLE public.execution_records
    ALTER COLUMN tenant_id                 SET NOT NULL;
ALTER TABLE public.execution_records
    ALTER COLUMN interpretation_version_id SET NOT NULL;

-- ---- 3. Determinism UNIQUE anchor
-- Same logical inputs + same interpretation pack + same runtime MUST collapse
-- to a single execution_record. Without this, determinism violations are
-- undetectable. PK execution_id covers ROW identity; this covers SEMANTIC
-- determinism identity.
ALTER TABLE public.execution_records
    ADD CONSTRAINT execution_records_determinism_unique
    UNIQUE (input_hash, interpretation_version_id, runtime_version);

COMMENT ON CONSTRAINT execution_records_determinism_unique
    ON public.execution_records IS
    'Determinism anchor: (input_hash, interpretation_version_id, runtime_version) is the semantic-identity tuple. PK execution_id remains the row-identity key. INV-EXEC-TRUTH-001.';
