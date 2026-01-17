-- Symphony Phase 7.1: Policy Profiles for Sandbox Controls
-- Phase Key: SYS-7-1
-- System of Record: Platform Orchestration Layer (Node.js)
--
-- Policy profiles do not constrain system capability.
-- They apply configurable, externally adjustable limits to existing
-- execution capability without requiring code changes or redeployment.

CREATE TABLE policy_profiles (
    policy_profile_id TEXT PRIMARY KEY DEFAULT generate_ulid(),
    name TEXT NOT NULL UNIQUE,
    
    -- Sandbox exposure limits (configurational, not infrastructural)
    max_transaction_amount NUMERIC(18,2),
    max_transactions_per_second INTEGER,
    daily_aggregate_limit NUMERIC(18,2),
    
    -- Message type whitelist
    allowed_message_types TEXT[] NOT NULL DEFAULT '{}',
    
    -- Additional policy constraints (extensible)
    constraints JSONB NOT NULL DEFAULT '{}',
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by TEXT NOT NULL,
    
    -- Constraints
    CONSTRAINT valid_constraints CHECK (jsonb_typeof(constraints) = 'object'),
    CONSTRAINT positive_limits CHECK (
        (max_transaction_amount IS NULL OR max_transaction_amount > 0) AND
        (max_transactions_per_second IS NULL OR max_transactions_per_second > 0) AND
        (daily_aggregate_limit IS NULL OR daily_aggregate_limit > 0)
    )
);

-- Index for active profile lookup
CREATE INDEX idx_policy_profiles_active ON policy_profiles(is_active) WHERE is_active = true;

-- Trigger for updated_at
CREATE TRIGGER update_policy_profiles_updated_at
    BEFORE UPDATE ON policy_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Documentation
COMMENT ON TABLE policy_profiles IS 'Sandbox policy configurations for participant limits. Orchestration Layer SoR. Phase 7.1.';
COMMENT ON COLUMN policy_profiles.max_transaction_amount IS 'Per-transaction limit. Used solely for sandbox exposure control, not financial correctness.';
COMMENT ON COLUMN policy_profiles.daily_aggregate_limit IS 'Daily aggregate cap. Used solely for sandbox exposure control, not financial correctness.';
COMMENT ON COLUMN policy_profiles.allowed_message_types IS 'Whitelist of ISO-20022 message types this profile may submit.';
