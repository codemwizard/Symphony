-- ============================================================
-- 00-create-db.sql
-- Postgres initialization script for Docker entrypoint
-- ============================================================
-- This script runs automatically when the Postgres container starts
-- with a fresh data volume.

-- Create the symphony database if it doesn't exist
-- (Docker's POSTGRES_DB env var handles this, but we include for explicitness)

-- Ensure extensions are available
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Log successful initialization
DO $$
BEGIN
    RAISE NOTICE 'Symphony database initialized successfully';
END $$;
