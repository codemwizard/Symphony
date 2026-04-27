-- 0161_enforce_policy_decisions_project_id_not_null.sql
-- Enforce NOT NULL on policy_decisions.project_id

-- 1. ASSERT: Verify no nulls exist before applying constraint
DO $$
DECLARE
    v_null_count INT;
BEGIN
    SELECT COUNT(*) INTO v_null_count FROM policy_decisions WHERE project_id IS NULL;
    IF v_null_count > 0 THEN
        RAISE EXCEPTION 'Cannot enforce NOT NULL on policy_decisions.project_id. % nulls found.', v_null_count;
    END IF;
END $$;

-- 2. MUTATE: Apply NOT NULL constraint
ALTER TABLE policy_decisions ALTER COLUMN project_id SET NOT NULL;

-- 3. RECONCILE: Verify schema constraint is active
DO $$
DECLARE
    v_is_nullable VARCHAR;
BEGIN
    SELECT is_nullable INTO v_is_nullable
    FROM information_schema.columns
    WHERE table_name = 'policy_decisions' AND column_name = 'project_id';

    IF v_is_nullable != 'NO' THEN
        RAISE EXCEPTION 'Constraint application failed. project_id is still nullable.';
    END IF;
END $$;
