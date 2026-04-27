-- Migration: 0165_create_public_keys_registry.sql
-- Task: TSK-P2-PREAUTH-007-08
-- Description: Create public_keys_registry table with temporal validity constraints
-- Work Item: tsk_p2_preauth_007_08_work_item_01

-- Drop table if exists (for idempotent migration)
DROP TABLE IF EXISTS public_keys_registry CASCADE;

-- Create public_keys_registry table with temporal validity constraints
CREATE TABLE public_keys_registry (
    id BIGSERIAL PRIMARY KEY,
    key_id VARCHAR(100) NOT NULL UNIQUE,
    actor_id VARCHAR(100) NOT NULL,
    public_key TEXT NOT NULL,
    key_type VARCHAR(50) NOT NULL CHECK (key_type IN ('RSA', 'ECDSA', 'ED25519')),
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_until_after_valid_from CHECK (valid_until > valid_from)
);

-- Create exclusion constraint to prevent overlapping temporal bounds for the same actor
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE public_keys_registry 
ADD CONSTRAINT no_overlapping_keys 
EXCLUDE USING gist (
    actor_id WITH =,
    tstzrange(valid_from, valid_until) WITH &&
);

-- Create indexes for performance
CREATE INDEX idx_public_keys_registry_actor_id ON public_keys_registry(actor_id);
CREATE INDEX idx_public_keys_registry_validity ON public_keys_registry(valid_from, valid_until);
CREATE INDEX idx_public_keys_registry_key_id ON public_keys_registry(key_id);

-- Add comments
COMMENT ON TABLE public_keys_registry IS 'Registry of public keys with temporal validity constraints for Wave 7 trust architecture';
COMMENT ON CONSTRAINT no_overlapping_keys ON public_keys_registry IS 'Prevents overlapping key validity periods for the same actor';
COMMENT ON CONSTRAINT valid_until_after_valid_from ON public_keys_registry IS 'Ensures validity end is after validity start';
