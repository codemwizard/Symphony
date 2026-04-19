-- Migration 0125: Install PostGIS extension
-- This migration installs PostGIS extension in the public schema to enable spatial data operations

CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;

-- Verify extension is loaded
SELECT PostGIS_version() AS postgis_version;
