-- Migration: 0168_attestation_seam_schema.sql
-- Task: TSK-P2-PREAUTH-007-12
-- Description: Add nullable attestation columns and enums to asset_batches with contract definitions
-- Work Item: tsk_p2_preauth_007_12_work_item_01
-- Depends on: 0101 (asset_batches table)

-- Create attestation source enum
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attestation_source_type') THEN
        CREATE TYPE attestation_source_type AS ENUM (
            'pre_ci_gate',
            'runtime_gate',
            'manual_audit',
            'deferred'
        );
    END IF;
END
$$;

-- Add attestation seam columns (all nullable — population deferred to Wave 8)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'asset_batches'
          AND column_name = 'invariant_attestation_hash'
    ) THEN
        ALTER TABLE public.asset_batches
            ADD COLUMN invariant_attestation_hash VARCHAR(128) NULL,
            ADD COLUMN invariant_attestation_version INTEGER NULL,
            ADD COLUMN invariant_attested_at TIMESTAMPTZ NULL,
            ADD COLUMN invariant_attestation_source attestation_source_type NULL;
    END IF;
END
$$;

-- Add check constraint on hash format (when populated)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'attestation_hash_format'
    ) THEN
        ALTER TABLE public.asset_batches
            ADD CONSTRAINT attestation_hash_format
                CHECK (invariant_attestation_hash IS NULL OR invariant_attestation_hash ~ '^[a-f0-9]{64,128}$');
    END IF;
END
$$;

-- Add check constraint on version (when populated, must be positive)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'attestation_version_positive'
    ) THEN
        ALTER TABLE public.asset_batches
            ADD CONSTRAINT attestation_version_positive
                CHECK (invariant_attestation_version IS NULL OR invariant_attestation_version > 0);
    END IF;
END
$$;

-- Document the contract definitions in comments
COMMENT ON COLUMN public.asset_batches.invariant_attestation_hash IS
    'SHA-256 hex digest over canonical JSON serialization of invariant evaluation result. Population deferred to Wave 8.';
COMMENT ON COLUMN public.asset_batches.invariant_attestation_version IS
    'Monotonic version of the invariant evaluation contract. Bumps on invariant set change, hash algo change, or serialization format change.';
COMMENT ON COLUMN public.asset_batches.invariant_attested_at IS
    'Timestamp of when invariant evaluation occurred (UTC). Population deferred to Wave 8.';
COMMENT ON COLUMN public.asset_batches.invariant_attestation_source IS
    'Source system that produced the attestation (pre_ci_gate, runtime_gate, manual_audit, deferred). Population deferred to Wave 8.';
COMMENT ON CONSTRAINT attestation_hash_format ON public.asset_batches IS
    'Enforces hex format: SHA-256 (64 chars) or SHA-512 (128 chars) when hash is populated';
COMMENT ON CONSTRAINT attestation_version_positive ON public.asset_batches IS
    'Enforces positive version numbers when version is populated';
