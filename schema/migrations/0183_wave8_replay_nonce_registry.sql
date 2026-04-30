-- Migration: 0183_wave8_replay_nonce_registry.sql
-- Task: TSK-P2-W8-DB-007c
-- Purpose: Isolate replay substrate creation into DB-007c-owned closure evidence
-- Dependencies: TSK-P2-W8-DB-007c
-- Type: Forward-only migration

-- Create replay nonce registry table (DB-007c)
-- This table enforces nonce uniqueness to prevent replay attacks
-- Uses CREATE TABLE IF NOT EXISTS for idempotency (may already exist from 0181)
CREATE TABLE IF NOT EXISTS public.wave8_attestation_nonces (
    nonce           text PRIMARY KEY,
    first_seen_at   timestamptz NOT NULL DEFAULT now(),
    batch_id        uuid REFERENCES public.asset_batches(id)
);

-- Add comment
COMMENT ON TABLE public.wave8_attestation_nonces IS
    'Wave 8 replay prevention table - tracks used attestation nonces to prevent replay attacks. Each nonce can only be used once. Created in 0183 as DB-007c-owned closure evidence, superseding mixed-domain 0181 implementation.';
