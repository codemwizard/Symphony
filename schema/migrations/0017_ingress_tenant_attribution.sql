-- 0017_ingress_tenant_attribution.sql
-- Tenant/client/member attribution for ingress attestations

-- Convert tenant_id to UUID and require it at ingress
ALTER TABLE public.ingress_attestations
  ALTER COLUMN tenant_id TYPE UUID USING tenant_id::uuid;

ALTER TABLE public.ingress_attestations
  ALTER COLUMN tenant_id SET NOT NULL;

ALTER TABLE public.ingress_attestations
  ADD COLUMN IF NOT EXISTS client_id UUID NULL REFERENCES public.tenant_clients(client_id),
  ADD COLUMN IF NOT EXISTS client_id_hash TEXT NULL,
  ADD COLUMN IF NOT EXISTS member_id UUID NULL REFERENCES public.tenant_members(member_id),
  ADD COLUMN IF NOT EXISTS participant_id TEXT NULL,
  ADD COLUMN IF NOT EXISTS cert_fingerprint_sha256 TEXT NULL,
  ADD COLUMN IF NOT EXISTS token_jti_hash TEXT NULL;

-- Prevent double-acceptance per tenant/instruction
CREATE UNIQUE INDEX IF NOT EXISTS ux_ingress_attestations_tenant_instruction
  ON public.ingress_attestations(tenant_id, instruction_id);

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_tenant_received
  ON public.ingress_attestations(tenant_id, received_at);

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_member_received
  ON public.ingress_attestations(member_id, received_at)
  WHERE member_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ingress_attestations_cert_fpr
  ON public.ingress_attestations(cert_fingerprint_sha256)
  WHERE cert_fingerprint_sha256 IS NOT NULL;
