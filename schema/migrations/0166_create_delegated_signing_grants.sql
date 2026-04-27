-- Migration: 0166_create_delegated_signing_grants.sql
-- Task: TSK-P2-PREAUTH-007-09
-- Description: Create delegated_signing_grants table to satisfy the non-masquerade invariant
-- Work Item: tsk_p2_preauth_007_09_work_item_01

-- Drop table if exists (for idempotent migration)
DROP TABLE IF EXISTS delegated_signing_grants CASCADE;

-- Create delegated_signing_grants table to map actor scope to payload
CREATE TABLE delegated_signing_grants (
    id BIGSERIAL PRIMARY KEY,
    grant_id VARCHAR(100) NOT NULL UNIQUE,
    actor_id VARCHAR(100) NOT NULL,
    scope JSONB NOT NULL,
    payload_hash VARCHAR(64) NOT NULL,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT expires_after_granted CHECK (expires_at > granted_at),
    CONSTRAINT payload_hash_format CHECK (payload_hash ~ '^[a-f0-9]{64}$')
);

-- Create indexes for performance
CREATE INDEX idx_delegated_signing_grants_actor_id ON delegated_signing_grants(actor_id);
CREATE INDEX idx_delegated_signing_grants_active ON delegated_signing_grants(is_active) WHERE is_active = true;
CREATE INDEX idx_delegated_signing_grants_expiry ON delegated_signing_grants(expires_at);
CREATE INDEX idx_delegated_signing_grants_payload_hash ON delegated_signing_grants(payload_hash);

-- Add comments
COMMENT ON TABLE delegated_signing_grants IS 'Registry of delegated signing grants mapping actor scope to payload for Wave 7 trust architecture';
COMMENT ON COLUMN delegated_signing_grants.scope IS 'JSONB defining the scope of delegated signing permissions';
COMMENT ON COLUMN delegated_signing_grants.payload_hash IS 'SHA256 hash of the payload for integrity verification';
COMMENT ON CONSTRAINT expires_after_granted ON delegated_signing_grants IS 'Ensures expiry time is after grant time';
COMMENT ON CONSTRAINT payload_hash_format ON delegated_signing_grants IS 'Ensures payload_hash is a valid SHA256 hex string';
