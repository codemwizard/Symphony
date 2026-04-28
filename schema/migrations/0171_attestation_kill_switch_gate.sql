-- Migration: 0171_attestation_kill_switch_gate.sql
-- Task: TSK-P2-PREAUTH-007-14
-- Description: Implement attestation-bound kill switch enforcing structural integrity and contract matching.
-- Work Item: tsk_p2_preauth_007_14_work_item_01
-- Depends on: 0163, 0170

-- Harden Schema (Explicit DDL)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'asset_batches'
          AND column_name = 'registry_snapshot_hash'
    ) THEN
        ALTER TABLE public.asset_batches
            ADD COLUMN registry_snapshot_hash VARCHAR(64) NULL;
    END IF;
END
$$;

-- symphony:pk_fk_type_change_waiver
-- Rationale: invariant_attestation_hash is not a PK/FK column; this type change aligns hash format with contract requirements.
ALTER TABLE public.asset_batches
    ALTER COLUMN invariant_attestation_hash TYPE VARCHAR(64);

ALTER TABLE public.asset_batches 
    DROP CONSTRAINT IF EXISTS registry_snapshot_hash_format;
ALTER TABLE public.asset_batches 
    ADD CONSTRAINT registry_snapshot_hash_format 
    CHECK (registry_snapshot_hash IS NULL OR registry_snapshot_hash ~ '^[0-9a-f]{64}$');

ALTER TABLE public.asset_batches 
    DROP CONSTRAINT IF EXISTS attestation_hash_format;
ALTER TABLE public.asset_batches 
    ADD CONSTRAINT attestation_hash_format 
    CHECK (invariant_attestation_hash IS NULL OR invariant_attestation_hash ~ '^[0-9a-f]{64}$');


-- Invariant Gate Function
CREATE OR REPLACE FUNCTION validate_attestation_gate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  live_snapshot_hash VARCHAR(64);
BEGIN
  -- 1. Structural Validation (Missing Fields)
  IF NEW.invariant_attestation_hash IS NULL OR
     NEW.invariant_attestation_version IS NULL OR
     NEW.invariant_attested_at IS NULL OR
     NEW.invariant_attestation_source IS NULL OR
     NEW.attestation_nonce IS NULL OR
     NEW.registry_snapshot_hash IS NULL THEN
    RAISE EXCEPTION 'Attestation rejection: structural integrity failed. All attestation fields and registry_snapshot_hash are strictly required.' USING ERRCODE = 'GF074';
  END IF;

  -- 2. Freshness Validation (Stale/Future Skew)
  IF NEW.invariant_attested_at < NOW() - INTERVAL '300 seconds' THEN
    RAISE EXCEPTION 'Attestation rejection: stale timestamp. Decision token is older than 300s TTL.' USING ERRCODE = 'GF075';
  END IF;

  IF NEW.invariant_attested_at > NOW() + INTERVAL '5 seconds' THEN
    RAISE EXCEPTION 'Attestation rejection: future timestamp skew.' USING ERRCODE = 'GF076';
  END IF;

  -- 3. Contract Matching (Live Snapshot Canonicalization)
  SELECT encode(digest(
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'invariant_id', invariant_id,
            'checksum', checksum,
            'is_blocking', is_blocking,
            'severity', severity,
            'execution_layer', execution_layer,
            'verifier_type', verifier_type
          ) ORDER BY invariant_id ASC
        )
        FROM invariant_registry 
        WHERE is_blocking = true
      ), 
      '[]'::jsonb
    )::text, 'sha256'), 'hex') INTO live_snapshot_hash;

  IF NEW.registry_snapshot_hash != live_snapshot_hash THEN
    RAISE EXCEPTION 'Attestation rejection: registry contract mismatch. Provided snapshot % does not match live contract %.', NEW.registry_snapshot_hash, live_snapshot_hash USING ERRCODE = 'GF077';
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger Binding on asset_batches
DROP TRIGGER IF EXISTS trg_attestation_gate_asset_batches ON public.asset_batches;
CREATE TRIGGER trg_attestation_gate_asset_batches
  BEFORE INSERT ON public.asset_batches
  FOR EACH ROW
  EXECUTE FUNCTION validate_attestation_gate();

-- Add comments
COMMENT ON FUNCTION public.validate_attestation_gate() IS
  'SECURITY DEFINER trigger function enforcing structural attestation integrity, temporal bounds, and registry contract matching on authoritative writes.';
COMMENT ON TRIGGER trg_attestation_gate_asset_batches ON public.asset_batches IS
  'DB attestation kill switch gate - aborts INSERT on missing/malformed/stale/contract-mismatched attestations';
