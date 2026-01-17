-- Policy Versions Table (Production-Safe Version Windows)
-- 
-- Supports ACTIVE, GRACE, and RETIRED states to prevent "Thunderous Logout"
-- when policy versions are updated.
--
-- ACTIVE:  Current policy, always accepted
-- GRACE:   Previous policy, temporarily accepted during migration window
-- RETIRED: No longer accepted, tokens must re-authenticate

CREATE TABLE IF NOT EXISTS policy_versions (
    id TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'GRACE', 'RETIRED')),
    activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Legacy column for backwards compatibility (derived from status)
    active BOOLEAN GENERATED ALWAYS AS (status = 'ACTIVE') STORED
);

-- Index for fast lookup of accepted versions
CREATE INDEX IF NOT EXISTS idx_policy_versions_status 
    ON policy_versions(status) 
    WHERE status IN ('ACTIVE', 'GRACE');

-- Ensure only one ACTIVE version at a time
CREATE UNIQUE INDEX IF NOT EXISTS idx_policy_versions_unique_active 
    ON policy_versions(status) 
    WHERE status = 'ACTIVE';

COMMENT ON TABLE policy_versions IS 
    'Anchor table for policy-bound invariants and regulatory governance. Supports version windows for graceful transitions.';

COMMENT ON COLUMN policy_versions.status IS 
    'ACTIVE = current policy | GRACE = temporarily accepted | RETIRED = rejected';

