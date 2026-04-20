-- backfill_execution_records_determinism.sql
-- Task: TSK-P2-PREAUTH-003-REM-02
-- Casefile: REM-2026-04-20_execution-truth-anchor
--
-- Precondition assertion for the contract-phase migration 0132.
-- Aborts migration if any pre-REM row on execution_records still carries a NULL
-- in any of the five columns about to be tightened to NOT NULL. Under the
-- two-strike rule (see DRD casefile PLAN.md §Two-Strike Rule), a second
-- non-convergent run opens REM-02b to perform the actual backfill. At first
-- application we expect COUNT(*) = 0 because migrations 0118 / 0131 introduced
-- no data rows; the assertion is idempotent.

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
