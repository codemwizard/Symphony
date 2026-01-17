-- Phase-7R: Kill Switch Schema
-- Provides global execution blocking capability for regulatory compliance.
-- 
-- When a kill_switch is active with scope = 'GLOBAL', 'INGEST', or 'EXECUTION',
-- all matching operations are blocked until the switch is deactivated.

CREATE TABLE IF NOT EXISTS kill_switches (
    id TEXT PRIMARY KEY,
    scope TEXT NOT NULL CHECK (scope IN ('GLOBAL', 'INGEST', 'EXECUTION', 'DISPATCH', 'PARTICIPANT')),
    reason TEXT NOT NULL,
    activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activated_by TEXT NOT NULL,
    policy_version TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    deactivated_at TIMESTAMPTZ,
    deactivated_by TEXT
);

-- Index for checking active kill switches
CREATE INDEX IF NOT EXISTS idx_kill_switches_active 
    ON kill_switches(is_active) 
    WHERE is_active = TRUE;

-- Index for scope-based lookups
CREATE INDEX IF NOT EXISTS idx_kill_switches_scope 
    ON kill_switches(scope, is_active);

COMMENT ON TABLE kill_switches IS 
    'Phase-7R: Kill switch registry for emergency execution blocking.';

-- Trigger function to block execution (applied separately based on table dependencies)
CREATE OR REPLACE FUNCTION block_execution_if_killed()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM kill_switches
        WHERE is_active = TRUE
          AND scope IN ('GLOBAL', 'INGEST', 'EXECUTION')
    ) THEN
        RAISE EXCEPTION 'Execution blocked by active kill-switch' 
            USING ERRCODE = 'P0001';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
