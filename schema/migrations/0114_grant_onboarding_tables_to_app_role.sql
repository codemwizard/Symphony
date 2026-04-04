-- Migration: 0114_grant_onboarding_tables_to_app_role.sql
-- Purpose: Grant necessary privileges to symphony_app_role for onboarding operations.
-- Task: TSK-P1-DEMO-031
-- Depends on: 0076 (onboarding_control_plane)

-- [ID tsk_p1_demo_031_work_item_06]
DO $$
BEGIN
  -- Create role if it does not already exist (CI parity: ephemeral DBs lack this role)
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_app_role') THEN
    CREATE ROLE symphony_app_role NOLOGIN;
  END IF;

  GRANT SELECT, INSERT, UPDATE ON public.tenant_registry TO symphony_app_role;
  GRANT SELECT, INSERT, UPDATE ON public.programme_registry TO symphony_app_role;
  GRANT SELECT, INSERT, UPDATE ON public.programme_policy_binding TO symphony_app_role;
END
$$;

-- Grant usage on sequence if any (though we use uuid v7)
-- None needed for uuid_v7_or_random()
