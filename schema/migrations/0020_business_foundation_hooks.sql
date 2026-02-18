-- 0020_business_foundation_hooks.sql
-- Phase-0 business foundation hooks (schema-only, forward-only)

CREATE OR REPLACE FUNCTION public.deny_append_only_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    RAISE EXCEPTION '% is append-only', TG_TABLE_NAME
      USING ERRCODE = 'P0001';
  END;
$$;

CREATE TABLE IF NOT EXISTS public.billable_clients (
  billable_client_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  legal_name TEXT NOT NULL,
  client_type TEXT NOT NULL CHECK (
    client_type IN ('BANK','MMO','NGO','GOV_PROGRAM','COOP_FEDERATION','ENTERPRISE')
  ),
  regulator_ref TEXT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS billable_client_id UUID NULL,
  ADD COLUMN IF NOT EXISTS parent_tenant_id UUID NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'tenants_billable_client_fk'
      AND conrelid = 'public.tenants'::regclass
  ) THEN
    ALTER TABLE public.tenants
      ADD CONSTRAINT tenants_billable_client_fk
      FOREIGN KEY (billable_client_id)
      REFERENCES public.billable_clients(billable_client_id)
      NOT VALID;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'tenants_parent_tenant_fk'
      AND conrelid = 'public.tenants'::regclass
  ) THEN
    ALTER TABLE public.tenants
      ADD CONSTRAINT tenants_parent_tenant_fk
      FOREIGN KEY (parent_tenant_id)
      REFERENCES public.tenants(tenant_id)
      NOT VALID;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tenants_billable_client_id
  ON public.tenants(billable_client_id);

CREATE INDEX IF NOT EXISTS idx_tenants_parent_tenant_id
  ON public.tenants(parent_tenant_id);

CREATE TABLE IF NOT EXISTS public.billing_usage_events (
  event_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  billable_client_id UUID NOT NULL REFERENCES public.billable_clients(billable_client_id),
  tenant_id UUID NULL REFERENCES public.tenants(tenant_id),
  client_id UUID NULL REFERENCES public.tenant_clients(client_id),
  subject_member_id UUID NULL REFERENCES public.tenant_members(member_id),
  subject_client_id UUID NULL REFERENCES public.tenant_clients(client_id),
  correlation_id UUID NULL,
  event_type TEXT NOT NULL CHECK (
    event_type IN (
      'EVIDENCE_BUNDLE',
      'CASE_PACK',
      'EXCEPTION_TRIAGE',
      'RETENTION_ANCHOR',
      'ESCROW_RELEASE',
      'DISPUTE_PACK'
    )
  ),
  units TEXT NOT NULL CHECK (units IN ('count','bytes','seconds','events')),
  quantity BIGINT NOT NULL CHECK (quantity > 0),
  metadata JSONB NULL,
  CONSTRAINT billing_usage_events_subject_zero_or_one_chk
    CHECK (((subject_member_id IS NOT NULL)::int + (subject_client_id IS NOT NULL)::int) <= 1),
  CONSTRAINT billing_usage_events_member_requires_tenant_chk
    CHECK (subject_member_id IS NULL OR tenant_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_billing_usage_events_correlation_id
  ON public.billing_usage_events(correlation_id);

DROP TRIGGER IF EXISTS trg_deny_billing_usage_events_mutation ON public.billing_usage_events;
CREATE TRIGGER trg_deny_billing_usage_events_mutation
BEFORE UPDATE OR DELETE ON public.billing_usage_events
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

CREATE TABLE IF NOT EXISTS public.external_proofs (
  proof_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  attestation_id UUID NOT NULL REFERENCES public.ingress_attestations(attestation_id),
  provider TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  response_hash TEXT NOT NULL,
  provider_ref TEXT NULL,
  verified_at TIMESTAMPTZ NULL,
  expires_at TIMESTAMPTZ NULL,
  metadata JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_external_proofs_attestation_id
  ON public.external_proofs(attestation_id);

DROP TRIGGER IF EXISTS trg_deny_external_proofs_mutation ON public.external_proofs;
CREATE TRIGGER trg_deny_external_proofs_mutation
BEFORE UPDATE OR DELETE ON public.external_proofs
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

CREATE TABLE IF NOT EXISTS public.evidence_packs (
  pack_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  pack_type TEXT NOT NULL CHECK (
    pack_type IN ('INSTRUCTION_BUNDLE','INCIDENT_PACK','DISPUTE_PACK')
  ),
  correlation_id UUID NULL,
  root_hash TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_evidence_packs_correlation_id
  ON public.evidence_packs(correlation_id);

DROP TRIGGER IF EXISTS trg_deny_evidence_packs_mutation ON public.evidence_packs;
CREATE TRIGGER trg_deny_evidence_packs_mutation
BEFORE UPDATE OR DELETE ON public.evidence_packs
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

CREATE TABLE IF NOT EXISTS public.evidence_pack_items (
  item_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  pack_id UUID NOT NULL REFERENCES public.evidence_packs(pack_id),
  artifact_path TEXT NULL,
  artifact_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT evidence_pack_items_path_or_hash_chk
    CHECK (artifact_path IS NOT NULL OR artifact_hash IS NOT NULL),
  CONSTRAINT ux_evidence_pack_items_pack_hash UNIQUE (pack_id, artifact_hash)
);

DROP TRIGGER IF EXISTS trg_deny_evidence_pack_items_mutation ON public.evidence_pack_items;
CREATE TRIGGER trg_deny_evidence_pack_items_mutation
BEFORE UPDATE OR DELETE ON public.evidence_pack_items
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

ALTER TABLE public.ingress_attestations
  ADD COLUMN IF NOT EXISTS correlation_id UUID NULL,
  ADD COLUMN IF NOT EXISTS signatures JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS upstream_ref TEXT NULL,
  ADD COLUMN IF NOT EXISTS downstream_ref TEXT NULL,
  ADD COLUMN IF NOT EXISTS nfs_sequence_ref TEXT NULL;

ALTER TABLE public.payment_outbox_pending
  ADD COLUMN IF NOT EXISTS correlation_id UUID NULL,
  ADD COLUMN IF NOT EXISTS upstream_ref TEXT NULL,
  ADD COLUMN IF NOT EXISTS downstream_ref TEXT NULL,
  ADD COLUMN IF NOT EXISTS nfs_sequence_ref TEXT NULL;

ALTER TABLE public.payment_outbox_attempts
  ADD COLUMN IF NOT EXISTS correlation_id UUID NULL,
  ADD COLUMN IF NOT EXISTS upstream_ref TEXT NULL,
  ADD COLUMN IF NOT EXISTS downstream_ref TEXT NULL,
  ADD COLUMN IF NOT EXISTS nfs_sequence_ref TEXT NULL;
