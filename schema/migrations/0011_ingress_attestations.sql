-- 0011_ingress_attestations.sql
-- Append-only ingress attestation ledger (hashes/identifiers only)

CREATE TABLE IF NOT EXISTS public.ingress_attestations (
  attestation_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  instruction_id TEXT NOT NULL,
  tenant_id TEXT,
  payload_hash TEXT NOT NULL,
  signature_hash TEXT,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_instruction
  ON public.ingress_attestations(instruction_id);

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_received_at
  ON public.ingress_attestations(received_at);

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_tenant_received
  ON public.ingress_attestations(tenant_id, received_at)
  WHERE tenant_id IS NOT NULL;

CREATE OR REPLACE FUNCTION deny_ingress_attestations_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    RAISE EXCEPTION 'ingress_attestations is append-only'
      USING ERRCODE = 'P0001';
  END;
$$;

DROP TRIGGER IF EXISTS trg_deny_ingress_attestations_mutation ON public.ingress_attestations;

CREATE TRIGGER trg_deny_ingress_attestations_mutation
BEFORE UPDATE OR DELETE ON public.ingress_attestations
FOR EACH ROW
EXECUTE FUNCTION deny_ingress_attestations_mutation();
