-- Symphony Phase 2: Role Definitions
-- No privileges granted here, just the existence of the roles.

-- Control Plane: Admin & Configuration
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_control') THEN
    CREATE ROLE symphony_control;
  END IF;
END $$;

-- Data Plane Ingest: Front-line instruction entry
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_ingest') THEN
    CREATE ROLE symphony_ingest;
  END IF;
END $$;

-- Data Plane Executor: Backend workers processing attempts
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_executor') THEN
    CREATE ROLE symphony_executor;
  END IF;
END $$;

-- Read Plane: General reporting
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_readonly') THEN
    CREATE ROLE symphony_readonly;
  END IF;
END $$;

-- Read Plane: External auditors
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'symphony_auditor') THEN
    CREATE ROLE symphony_auditor;
  END IF;
END $$;

COMMENT ON ROLE symphony_control IS 'Control Plane administrator. Manages configuration and routing policy.';
COMMENT ON ROLE symphony_ingest IS 'Data Plane Ingest service. Responsible for recording new instructions.';
COMMENT ON ROLE symphony_executor IS 'Data Plane Executor worker. Responsible for processing transaction attempts and state transitions.';
COMMENT ON ROLE symphony_readonly IS 'Read Plane access for reporting and internal observability.';
COMMENT ON ROLE symphony_auditor IS 'Read Plane access for external regulators and independent audits.';
