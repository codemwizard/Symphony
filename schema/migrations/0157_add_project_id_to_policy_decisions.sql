-- Migration 0157: Add project_id to policy_decisions
-- Phase 2: Wave 6 Remediation (TSK-P2-W6-REM-17a)
-- Column is nullable with no default, ready for deterministic backfill.

ALTER TABLE policy_decisions
ADD COLUMN IF NOT EXISTS project_id uuid;

COMMENT ON COLUMN policy_decisions.project_id IS
  'FK-candidate to projects; nullable until backfill (TSK-P2-W6-REM-17b-β)';
