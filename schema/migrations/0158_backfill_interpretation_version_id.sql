-- Migration 0158: Backfill state_transitions.interpretation_version_id
-- Phase 2: Wave 6 Remediation (TSK-P2-W6-REM-17b-alpha)
-- Three-phase contract: assert → mutate → reconcile
-- Idempotent: safe to rerun (predicate-scoped, non-overwriting)

-- Phase 1: Executable join-cardinality assertion
-- Every execution_id must resolve to exactly one interpretation_version_id
DO $$
DECLARE bad_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO bad_count
    FROM (
        SELECT st.execution_id
        FROM state_transitions st
        JOIN execution_records er ON st.execution_id = er.execution_id
        WHERE st.interpretation_version_id IS NULL
        GROUP BY st.execution_id
        HAVING COUNT(DISTINCT er.interpretation_version_id) <> 1
    ) ambiguous;
    IF bad_count > 0 THEN
        RAISE EXCEPTION 'CARDINALITY VIOLATION: % execution_ids resolve to != 1 interpretation_version_id', bad_count;
    END IF;
    RAISE NOTICE 'CARDINALITY OK: 0 ambiguous execution_ids';
END $$;

-- Temporarily disable append-only trigger for the backfill UPDATE
ALTER TABLE state_transitions DISABLE TRIGGER bd_01_deny_state_transitions_mutation;

-- Phase 2: Row mutation accounting
DO $$
DECLARE
    target_count INTEGER;
    updated_count INTEGER;
    remaining_null INTEGER;
BEGIN
    -- Pre-update: count rows that will be touched
    SELECT COUNT(*) INTO target_count
    FROM state_transitions WHERE interpretation_version_id IS NULL;

    -- Execute predicate-scoped backfill (no overwrite)
    UPDATE state_transitions st
    SET interpretation_version_id = er.interpretation_version_id
    FROM execution_records er
    WHERE st.execution_id = er.execution_id
      AND st.interpretation_version_id IS NULL;
    GET DIAGNOSTICS updated_count = ROW_COUNT;

    -- Post-update: count remaining NULLs
    SELECT COUNT(*) INTO remaining_null
    FROM state_transitions WHERE interpretation_version_id IS NULL;

    -- Reconciliation assertion
    IF remaining_null > 0 THEN
        RAISE EXCEPTION 'BACKFILL INCOMPLETE: % rows still NULL after update', remaining_null;
    END IF;
    IF updated_count <> target_count THEN
        RAISE EXCEPTION 'ROW ACCOUNTING MISMATCH: expected % updates, got %', target_count, updated_count;
    END IF;

    RAISE NOTICE 'BACKFILL OK: % rows updated, 0 remaining NULL', updated_count;
END $$;

-- Re-enable append-only trigger immediately
ALTER TABLE state_transitions ENABLE TRIGGER bd_01_deny_state_transitions_mutation;
