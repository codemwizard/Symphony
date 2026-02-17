-- 0026_business_foundation_delta_tightening.sql
-- Phase-0 tightening (expand-first): new-row enforcement for auditably billable + stitchable hooks.
--
-- Constraints are added as NOT VALID to avoid scanning/backfilling historical rows in Phase-0.
-- NOT VALID constraints are still enforced for all new writes.

-- ------------------------------------------------------------
-- 1) Tenants: require billable client for new rows (auditably billable)
-- ------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'tenants_billable_client_required_new_rows_chk'
      AND conrelid = 'public.tenants'::regclass
  ) THEN
    ALTER TABLE public.tenants
      ADD CONSTRAINT tenants_billable_client_required_new_rows_chk
      CHECK (billable_client_id IS NOT NULL)
      NOT VALID;
  END IF;
END $$;

-- ------------------------------------------------------------
-- 2) Billable clients: stable payer key (human-governed) for new rows
-- ------------------------------------------------------------
ALTER TABLE public.billable_clients
  ADD COLUMN IF NOT EXISTS client_key TEXT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'billable_clients_client_key_required_new_rows_chk'
      AND conrelid = 'public.billable_clients'::regclass
  ) THEN
    ALTER TABLE public.billable_clients
      ADD CONSTRAINT billable_clients_client_key_required_new_rows_chk
      CHECK (client_key IS NOT NULL AND length(btrim(client_key)) > 0)
      NOT VALID;
  END IF;
END $$;

-- ------------------------------------------------------------
-- 3) Correlation IDs: allow app to supply, but DB guarantees presence (set-if-null)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_correlation_id_if_null()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.correlation_id IS NULL THEN
    NEW.correlation_id := public.uuid_v7_or_random();
  END IF;
  RETURN NEW;
END;
$$;

-- Triggers: enforce correlation_id presence for new rows without backfill.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_corr_id_ingress_attestations') THEN
    CREATE TRIGGER trg_set_corr_id_ingress_attestations
    BEFORE INSERT ON public.ingress_attestations
    FOR EACH ROW
    EXECUTE FUNCTION public.set_correlation_id_if_null();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_corr_id_payment_outbox_pending') THEN
    CREATE TRIGGER trg_set_corr_id_payment_outbox_pending
    BEFORE INSERT ON public.payment_outbox_pending
    FOR EACH ROW
    EXECUTE FUNCTION public.set_correlation_id_if_null();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_corr_id_payment_outbox_attempts') THEN
    CREATE TRIGGER trg_set_corr_id_payment_outbox_attempts
    BEFORE INSERT ON public.payment_outbox_attempts
    FOR EACH ROW
    EXECUTE FUNCTION public.set_correlation_id_if_null();
  END IF;
END $$;

-- NOT VALID CHECKs: enforced for new writes immediately; historical rows are deferred.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ingress_attestations_correlation_required_new_rows_chk'
      AND conrelid = 'public.ingress_attestations'::regclass
  ) THEN
    ALTER TABLE public.ingress_attestations
      ADD CONSTRAINT ingress_attestations_correlation_required_new_rows_chk
      CHECK (correlation_id IS NOT NULL)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'payment_outbox_pending_correlation_required_new_rows_chk'
      AND conrelid = 'public.payment_outbox_pending'::regclass
  ) THEN
    ALTER TABLE public.payment_outbox_pending
      ADD CONSTRAINT payment_outbox_pending_correlation_required_new_rows_chk
      CHECK (correlation_id IS NOT NULL)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'payment_outbox_attempts_correlation_required_new_rows_chk'
      AND conrelid = 'public.payment_outbox_attempts'::regclass
  ) THEN
    ALTER TABLE public.payment_outbox_attempts
      ADD CONSTRAINT payment_outbox_attempts_correlation_required_new_rows_chk
      CHECK (correlation_id IS NOT NULL)
      NOT VALID;
  END IF;
END $$;

-- ------------------------------------------------------------
-- 4) External proofs: direct billability (who paid for this proof?)
-- ------------------------------------------------------------
ALTER TABLE public.external_proofs
  ADD COLUMN IF NOT EXISTS tenant_id UUID NULL,
  ADD COLUMN IF NOT EXISTS billable_client_id UUID NULL,
  ADD COLUMN IF NOT EXISTS subject_member_id UUID NULL;

-- FKs are NOT VALID to avoid a validation scan in Phase-0 (columns are expand-first).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'external_proofs_tenant_fk'
      AND conrelid = 'public.external_proofs'::regclass
  ) THEN
    ALTER TABLE public.external_proofs
      ADD CONSTRAINT external_proofs_tenant_fk
      FOREIGN KEY (tenant_id)
      REFERENCES public.tenants(tenant_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'external_proofs_billable_client_fk'
      AND conrelid = 'public.external_proofs'::regclass
  ) THEN
    ALTER TABLE public.external_proofs
      ADD CONSTRAINT external_proofs_billable_client_fk
      FOREIGN KEY (billable_client_id)
      REFERENCES public.billable_clients(billable_client_id)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'external_proofs_subject_member_fk'
      AND conrelid = 'public.external_proofs'::regclass
  ) THEN
    ALTER TABLE public.external_proofs
      ADD CONSTRAINT external_proofs_subject_member_fk
      FOREIGN KEY (subject_member_id)
      REFERENCES public.tenant_members(member_id)
      NOT VALID;
  END IF;
END $$;

-- Derive attribution from attestation_id at insert time.
-- Behavior:
-- - if tenant_id/billable_client_id provided by app, verify they match derived values
-- - otherwise set them from ingress_attestations -> tenants.billable_client_id
-- - fail closed if attribution cannot be resolved
CREATE OR REPLACE FUNCTION public.set_external_proofs_attribution()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  derived_tenant_id UUID;
  derived_billable_client_id UUID;
BEGIN
  SELECT ia.tenant_id
    INTO derived_tenant_id
    FROM public.ingress_attestations ia
   WHERE ia.attestation_id = NEW.attestation_id;

  IF derived_tenant_id IS NULL THEN
    RAISE EXCEPTION 'external_proofs requires tenant attribution via ingress_attestations'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT t.billable_client_id
    INTO derived_billable_client_id
    FROM public.tenants t
   WHERE t.tenant_id = derived_tenant_id;

  IF derived_billable_client_id IS NULL THEN
    RAISE EXCEPTION 'external_proofs requires billable_client_id attribution via tenant'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id := derived_tenant_id;
  ELSIF NEW.tenant_id <> derived_tenant_id THEN
    RAISE EXCEPTION 'external_proofs tenant_id does not match derived tenant_id'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.billable_client_id IS NULL THEN
    NEW.billable_client_id := derived_billable_client_id;
  ELSIF NEW.billable_client_id <> derived_billable_client_id THEN
    RAISE EXCEPTION 'external_proofs billable_client_id does not match derived billable_client_id'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_set_external_proofs_attribution') THEN
    CREATE TRIGGER trg_set_external_proofs_attribution
    BEFORE INSERT ON public.external_proofs
    FOR EACH ROW
    EXECUTE FUNCTION public.set_external_proofs_attribution();
  END IF;
END $$;

-- Enforce direct billability for new proof rows.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'external_proofs_tenant_required_new_rows_chk'
      AND conrelid = 'public.external_proofs'::regclass
  ) THEN
    ALTER TABLE public.external_proofs
      ADD CONSTRAINT external_proofs_tenant_required_new_rows_chk
      CHECK (tenant_id IS NOT NULL)
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'external_proofs_billable_client_required_new_rows_chk'
      AND conrelid = 'public.external_proofs'::regclass
  ) THEN
    ALTER TABLE public.external_proofs
      ADD CONSTRAINT external_proofs_billable_client_required_new_rows_chk
      CHECK (billable_client_id IS NOT NULL)
      NOT VALID;
  END IF;
END $$;

