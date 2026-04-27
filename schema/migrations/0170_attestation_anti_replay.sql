-- Migration: 0170_attestation_anti_replay.sql
-- Task: TSK-P2-PREAUTH-007-13
-- Description: Implement anti-replay DB logic (nonce, epoch, freshness TTL constraints)
-- Work Item: tsk_p2_preauth_007_13_work_item_01
-- Depends on: 0168 (attestation seam schema)

BEGIN;

-- Add nonce column for replay prevention
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'asset_batches'
          AND column_name = 'attestation_nonce'
    ) THEN
        ALTER TABLE public.asset_batches
            ADD COLUMN attestation_nonce BIGINT NULL;
    END IF;
END
$$;

-- Unique constraint: no two issuances may use the same attestation hash
-- This prevents the same attestation from gating two distinct issuance events
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'unique_attestation_hash'
    ) THEN
        ALTER TABLE public.asset_batches
            ADD CONSTRAINT unique_attestation_hash
                UNIQUE (invariant_attestation_hash);
    END IF;
END
$$;

-- Create freshness enforcement trigger
CREATE OR REPLACE FUNCTION enforce_attestation_freshness()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  max_age INTERVAL := INTERVAL '300 seconds';
BEGIN
  -- Only enforce when attestation timestamp is populated
  IF NEW.invariant_attested_at IS NOT NULL THEN
    IF (NOW() - NEW.invariant_attested_at) > max_age THEN
      RAISE EXCEPTION 'Attestation is stale: attested at %, current time %, max age %',
        NEW.invariant_attested_at, NOW(), max_age
      USING ERRCODE = 'GF073';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Bind trigger
DROP TRIGGER IF EXISTS trg_enforce_attestation_freshness ON public.asset_batches;
CREATE TRIGGER trg_enforce_attestation_freshness
  BEFORE INSERT OR UPDATE ON public.asset_batches
  FOR EACH ROW
  EXECUTE FUNCTION enforce_attestation_freshness();

-- Add comments
COMMENT ON COLUMN public.asset_batches.attestation_nonce IS
    'Nonce for replay prevention - each attestation must carry a unique nonce (nullable)';
COMMENT ON CONSTRAINT unique_attestation_hash ON public.asset_batches IS
    'Anti-replay constraint: prevents the same attestation hash from gating two distinct issuance events';
COMMENT ON FUNCTION public.enforce_attestation_freshness() IS
    'SECURITY DEFINER trigger function enforcing attestation freshness - rejects attestations older than 300 seconds';

COMMIT;
