-- ============================================================
-- 0003_roles.sql
-- Role definitions for CI/Development environments
-- ============================================================
-- In production, roles may be managed by infrastructure (Terraform/IAM).
-- This migration provides idempotent role creation for dev/CI.
--
-- Key: Roles are NOLOGIN and granted to the CI login user (symphony)
-- so that SET ROLE works correctly in queryAsRole() helpers.
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_control') THEN
    CREATE ROLE symphony_control NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_ingest') THEN
    CREATE ROLE symphony_ingest NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_executor') THEN
    CREATE ROLE symphony_executor NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_readonly') THEN
    CREATE ROLE symphony_readonly NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_auditor') THEN
    CREATE ROLE symphony_auditor NOLOGIN;
  END IF;
END
$$;

-- Allow the CI login role (symphony) to SET ROLE into these
GRANT symphony_control  TO symphony;
GRANT symphony_ingest   TO symphony;
GRANT symphony_executor TO symphony;
GRANT symphony_readonly TO symphony;
GRANT symphony_auditor  TO symphony;

-- Role comments
COMMENT ON ROLE symphony_control IS 'Control Plane administrator.';
COMMENT ON ROLE symphony_ingest IS 'Data Plane Ingest service.';
COMMENT ON ROLE symphony_executor IS 'Data Plane Executor worker.';
COMMENT ON ROLE symphony_readonly IS 'Read Plane for reporting.';
COMMENT ON ROLE symphony_auditor IS 'Read Plane for external auditors.';
