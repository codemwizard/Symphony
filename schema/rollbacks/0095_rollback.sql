-- 0095_rollback.sql - Manual use only — NOT run by migration runner
-- Rollback script for RLS architecture changes
-- Reference: docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md

-- 1. Drop ALL current policies on target tables
DO $$ DECLARE pol RECORD; BEGIN
  FOR pol IN
    SELECT p.polname, c.relname FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    WHERE c.relnamespace = 'public'::regnamespace
      AND c.relname IN (SELECT table_name FROM _rls_table_config WHERE isolation_type != 'GLOBAL')
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', pol.polname, pol.relname);
  END LOOP;
END $$;

-- 2. Restore pre-migration policies
\i schema/rollbacks/0095_pre_snapshot.sql

-- 3. Mark guard for re-run
UPDATE _migration_guards SET skip_guard = true
WHERE key = '0095_rls_dual_policy';
