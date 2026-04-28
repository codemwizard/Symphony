-- Migration: 0163_create_invariant_registry.sql
-- Task: TSK-P2-PREAUTH-007-06
-- Description: Create invariant_registry table with append-only trigger
-- Work Item: tsk_p2_preauth_007_06_work_item_01, tsk_p2_preauth_007_06_work_item_02

-- Create invariant_registry table
CREATE TABLE invariant_registry (
    id BIGSERIAL PRIMARY KEY,
    invariant_id VARCHAR(50) NOT NULL UNIQUE,
    verifier_type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    execution_layer VARCHAR(50) NOT NULL CHECK (execution_layer IN ('DB', 'API', 'CI')),
    is_blocking BOOLEAN NOT NULL DEFAULT false,
    checksum VARCHAR(64) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    superseded_by BIGINT REFERENCES invariant_registry(id) ON DELETE SET NULL,
    CONSTRAINT checksum_format CHECK (checksum ~ '^[a-f0-9]{64}$')
);

-- Create index on invariant_id for faster lookups
CREATE INDEX idx_invariant_registry_invariant_id ON invariant_registry(invariant_id);

-- Create index on execution_layer for filtering
CREATE INDEX idx_invariant_registry_execution_layer ON invariant_registry(execution_layer);

-- Create index on is_blocking for filtering active blocking invariants
CREATE INDEX idx_invariant_registry_is_blocking ON invariant_registry(is_blocking) WHERE is_blocking = true;

-- Create append-only trigger function
CREATE OR REPLACE FUNCTION invariant_registry_append_only()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'Cannot UPDATE invariant_registry - append-only table';
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Cannot DELETE from invariant_registry - append-only table';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public;

-- Create trigger to enforce append-only
CREATE TRIGGER invariant_registry_append_only_trigger
    BEFORE UPDATE OR DELETE ON invariant_registry
    FOR EACH ROW EXECUTE FUNCTION invariant_registry_append_only();

-- Add comment to table
COMMENT ON TABLE invariant_registry IS 'Registry of invariants with append-only topology for Wave 7 enforcement';

-- Add comment on trigger
COMMENT ON FUNCTION invariant_registry_append_only() IS 'Enforces append-only behavior on invariant_registry table';
