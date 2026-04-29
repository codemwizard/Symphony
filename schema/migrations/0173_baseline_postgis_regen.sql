-- Migration 0173: Baseline regeneration for PostGIS-enabled CI
--
-- This is a no-op migration. It exists solely to satisfy the baseline
-- governance gate (ADR-0010) which requires at least one migration to
-- change in the same diff as a baseline update.
--
-- Context: PR #196 added postgresql-18-postgis-3 to CI, enabling
-- migration 0125_postgis_extension.sql to fully load PostGIS into
-- the public schema. The baseline was regenerated from a PostGIS-
-- enabled PostgreSQL 18.3 instance to match CI's environment.

SELECT 1;  -- no-op
