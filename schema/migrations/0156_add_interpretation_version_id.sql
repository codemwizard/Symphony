-- Migration 0156: Add interpretation_version_id to state_transitions
-- Phase 2: Wave 6 Remediation (TSK-P2-W6-REM-17a)
-- Column is nullable with no default, ready for deterministic backfill.

ALTER TABLE state_transitions
ADD COLUMN IF NOT EXISTS interpretation_version_id uuid;

COMMENT ON COLUMN state_transitions.interpretation_version_id IS
  'FK-candidate to interpretation_versions; nullable until backfill (TSK-P2-W6-REM-17b-α)';
