-- Migration 0132: execution_records determinism constraints (contract phase)
-- Task: TSK-P2-PREAUTH-003-REM-02
-- Casefile: REM-2026-04-20_execution-truth-anchor
-- Invariant: INV-EXEC-TRUTH-001 (enforcement surface #1 + #2)
--
-- Contract phase of the expand/contract pair. Tightens the four columns
-- added by 0131 plus the legacy-nullable interpretation_version_id to
-- NOT NULL, and adds the determinism UNIQUE over (input_hash,
-- interpretation_version_id, runtime_version). The backfill precondition
-- DO block is INLINED (B6 — do NOT use \i; scripts/db/migrate.sh
-- checksums only this file, so an external include would silently bypass
-- the immutability gate).
--
-- NOTE: do NOT add top-level BEGIN/COMMIT. migrate.sh wraps this file in
-- its own transaction; a top-level COMMIT here would prematurely close
-- the outer transaction.

-- ─── Step 1: inline backfill precondition (mirror of scripts/db/backfill_execution_records_determinism.sql) ──
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count
    FROM public.execution_records
    WHERE input_hash                IS NULL
       OR output_hash               IS NULL
       OR runtime_version           IS NULL
       OR tenant_id                 IS NULL
       OR interpretation_version_id IS NULL;

    IF null_count > 0 THEN
        RAISE EXCEPTION 'GF059: execution_records determinism backfill precondition failed — % NULL rows present', null_count
            USING ERRCODE = 'GF059';
    END IF;
END $$;

-- ─── Step 2: SET NOT NULL × 5 ─────────────────────────────────────────
ALTER TABLE public.execution_records ALTER COLUMN input_hash                SET NOT NULL;
ALTER TABLE public.execution_records ALTER COLUMN output_hash               SET NOT NULL;
ALTER TABLE public.execution_records ALTER COLUMN runtime_version           SET NOT NULL;
ALTER TABLE public.execution_records ALTER COLUMN tenant_id                 SET NOT NULL;
ALTER TABLE public.execution_records ALTER COLUMN interpretation_version_id SET NOT NULL;

-- ─── Step 3: UNIQUE determinism anchor ────────────────────────────────
-- NOT over execution_id (already PK); UNIQUE is the determinism claim.
ALTER TABLE public.execution_records
    ADD CONSTRAINT execution_records_determinism_unique
    UNIQUE (input_hash, interpretation_version_id, runtime_version);

COMMENT ON CONSTRAINT execution_records_determinism_unique ON public.execution_records
    IS 'INV-EXEC-TRUTH-001 determinism anchor: identical (input_hash, interpretation_version_id, runtime_version) is forbidden.';
