-- ============================================================
-- 0003_roles.sql
-- Required roles for DB role isolation + least privilege tests.
-- ============================================================

DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_control') THEN
      CREATE ROLE symphony_control NOLOGIN;
    END IF;
    ALTER ROLE symphony_control NOLOGIN;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_executor') THEN
      CREATE ROLE symphony_executor NOLOGIN;
    END IF;
    ALTER ROLE symphony_executor NOLOGIN;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_ingest') THEN
      CREATE ROLE symphony_ingest NOLOGIN;
    END IF;
    ALTER ROLE symphony_ingest NOLOGIN;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_readonly') THEN
      CREATE ROLE symphony_readonly NOLOGIN;
    END IF;
    ALTER ROLE symphony_readonly NOLOGIN;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_auditor') THEN
      CREATE ROLE symphony_auditor NOLOGIN;
    END IF;
    ALTER ROLE symphony_auditor NOLOGIN;

    -- NOTE: symphony_auth is intentionally NOT created yet.
    -- mTLS is enforced at the transport layer; DB onboarding can be handled
    -- by symphony_control until a dedicated auth role is needed.

    -- Test harness role used by unit tests (connects directly or via SET ROLE).
    -- Password is NOT set here. CI must set via ALTER ROLE if needed.
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'test_user') THEN
      CREATE ROLE test_user LOGIN;
    END IF;
    ALTER ROLE test_user LOGIN;
  END $$;
