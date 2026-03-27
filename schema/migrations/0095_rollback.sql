-- ══════════════════════════════════════════════════════════════════════════════
-- 0095 Rollback: Restore pre-migration RLS state
-- TSK-RLS-ARCH-001 v10.1
--
-- MANUAL USE ONLY — NOT run by migration runner.
-- Steps:
--   1. Drop ALL current policies on target tables
--   2. Restore pre-migration policies from snapshot
--   3. Mark guard for re-run
-- ══════════════════════════════════════════════════════════════════════════════

BEGIN;

-- 1. Drop ALL current policies on target tables
DO $$ DECLARE pol RECORD; BEGIN
    FOR pol IN
        SELECT p.polname, c.relname
        FROM pg_policy p
        JOIN pg_class c ON c.oid = p.polrelid
        WHERE c.relnamespace = 'public'::regnamespace
          AND c.relname IN (
              SELECT table_name FROM _rls_table_config
              WHERE isolation_type NOT IN ('GLOBAL', 'JURISDICTION')
          )
    LOOP
        EXECUTE format('DROP POLICY %I ON public.%I', pol.polname, pol.relname);
    END LOOP;
END $$;

-- 2. Restore pre-migration policies
\i schema/migrations/0095_pre_snapshot.sql

-- 3. Mark guard for re-run
UPDATE _migration_guards SET skip_guard = true
WHERE key = '0095_rls_dual_policy';

COMMIT;
