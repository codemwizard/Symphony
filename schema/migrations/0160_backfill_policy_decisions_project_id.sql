-- 0160_backfill_policy_decisions_project_id.sql
-- Backfill policy_decisions.project_id from execution_records lineage

BEGIN;

DO $$
DECLARE
    v_total_rows INT;
    v_rows_needing_update INT;
    v_rows_updated INT;
BEGIN
    -- 1. ASSERT: Count total and target rows
    SELECT COUNT(*) INTO v_total_rows FROM policy_decisions;
    
    SELECT COUNT(*) INTO v_rows_needing_update 
    FROM policy_decisions 
    WHERE project_id IS NULL;

    RAISE NOTICE 'Total policy_decisions rows: %', v_total_rows;
    RAISE NOTICE 'Rows needing project_id backfill: %', v_rows_needing_update;

    IF v_rows_needing_update > 0 THEN
        -- 2. MUTATE: Disable append-only trigger, update, re-enable
        ALTER TABLE policy_decisions DISABLE TRIGGER policy_decisions_append_only_trigger;

        UPDATE policy_decisions pd
        SET project_id = er.project_id
        FROM execution_records er
        WHERE pd.execution_id = er.execution_id
          AND pd.project_id IS NULL;
          
        GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

        ALTER TABLE policy_decisions ENABLE TRIGGER policy_decisions_append_only_trigger;

        RAISE NOTICE 'Rows backfilled: %', v_rows_updated;

        -- 3. RECONCILE: Verify all rows were updated
        IF v_rows_updated != v_rows_needing_update THEN
            RAISE EXCEPTION 'Backfill reconciliation failed. Expected %, Updated %', v_rows_needing_update, v_rows_updated;
        END IF;
    ELSE
        RAISE NOTICE 'Idempotent execution: 0 rows need backfill.';
    END IF;
END $$;

COMMIT;
