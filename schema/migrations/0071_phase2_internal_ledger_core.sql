CREATE TABLE IF NOT EXISTS public.internal_ledger_journals (
  journal_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  idempotency_key TEXT NOT NULL,
  journal_type TEXT NOT NULL,
  reference_id TEXT NULL,
  currency_code TEXT NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
  created_by TEXT NOT NULL DEFAULT CURRENT_USER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS public.internal_ledger_postings (
  posting_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  journal_id UUID NOT NULL REFERENCES public.internal_ledger_journals(journal_id) ON DELETE RESTRICT,
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  account_code TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('DEBIT', 'CREDIT')),
  amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
  currency_code TEXT NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_internal_ledger_postings_journal
  ON public.internal_ledger_postings (journal_id, direction);

CREATE OR REPLACE FUNCTION public.enforce_internal_ledger_posting_context()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_journal_tenant UUID;
  v_journal_currency TEXT;
BEGIN
  SELECT tenant_id, currency_code
    INTO v_journal_tenant, v_journal_currency
  FROM public.internal_ledger_journals
  WHERE journal_id = NEW.journal_id;

  IF v_journal_tenant IS NULL THEN
    RAISE EXCEPTION 'journal not found for posting'
      USING ERRCODE = '23503';
  END IF;

  IF NEW.tenant_id IS DISTINCT FROM v_journal_tenant THEN
    RAISE EXCEPTION 'cross-tenant posting rejected'
      USING ERRCODE = '23514';
  END IF;

  IF NEW.currency_code IS DISTINCT FROM v_journal_currency THEN
    RAISE EXCEPTION 'posting currency must match journal currency'
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_internal_ledger_posting_context ON public.internal_ledger_postings;
CREATE TRIGGER trg_enforce_internal_ledger_posting_context
BEFORE INSERT OR UPDATE ON public.internal_ledger_postings
FOR EACH ROW
EXECUTE FUNCTION public.enforce_internal_ledger_posting_context();

DROP TRIGGER IF EXISTS trg_deny_internal_ledger_journals_mutation ON public.internal_ledger_journals;
CREATE TRIGGER trg_deny_internal_ledger_journals_mutation
BEFORE UPDATE OR DELETE ON public.internal_ledger_journals
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

DROP TRIGGER IF EXISTS trg_deny_internal_ledger_postings_mutation ON public.internal_ledger_postings;
CREATE TRIGGER trg_deny_internal_ledger_postings_mutation
BEFORE UPDATE OR DELETE ON public.internal_ledger_postings
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

CREATE OR REPLACE FUNCTION public.verify_internal_ledger_journal_balance(p_journal_id UUID)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  WITH sums AS (
    SELECT
      COALESCE(SUM(CASE WHEN direction = 'DEBIT' THEN amount_minor ELSE 0 END), 0) AS debit_total,
      COALESCE(SUM(CASE WHEN direction = 'CREDIT' THEN amount_minor ELSE 0 END), 0) AS credit_total,
      COUNT(*) AS posting_count,
      COUNT(DISTINCT account_code) AS distinct_accounts,
      COUNT(*) FILTER (WHERE direction = 'DEBIT') AS debit_count,
      COUNT(*) FILTER (WHERE direction = 'CREDIT') AS credit_count
    FROM public.internal_ledger_postings
    WHERE journal_id = p_journal_id
  )
  SELECT posting_count >= 2
     AND debit_count >= 1
     AND credit_count >= 1
     AND distinct_accounts >= 2
     AND debit_total = credit_total
  FROM sums;
$$;

CREATE OR REPLACE FUNCTION public.create_internal_ledger_journal(
  p_tenant_id UUID,
  p_idempotency_key TEXT,
  p_journal_type TEXT,
  p_currency_code TEXT,
  p_postings JSONB,
  p_reference_id TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_existing UUID;
  v_journal_id UUID;
  v_item JSONB;
BEGIN
  IF p_postings IS NULL OR jsonb_typeof(p_postings) <> 'array' OR jsonb_array_length(p_postings) < 2 THEN
    RAISE EXCEPTION 'p_postings must contain at least two postings'
      USING ERRCODE = '23514';
  END IF;

  SELECT journal_id
    INTO v_existing
  FROM public.internal_ledger_journals
  WHERE tenant_id = p_tenant_id
    AND idempotency_key = p_idempotency_key;

  IF v_existing IS NOT NULL THEN
    RETURN v_existing;
  END IF;

  INSERT INTO public.internal_ledger_journals(
    tenant_id, idempotency_key, journal_type, reference_id, currency_code
  ) VALUES (
    p_tenant_id, p_idempotency_key, p_journal_type, p_reference_id, p_currency_code
  )
  RETURNING journal_id INTO v_journal_id;

  FOR v_item IN
    SELECT value
    FROM jsonb_array_elements(p_postings)
  LOOP
    INSERT INTO public.internal_ledger_postings(
      journal_id, tenant_id, account_code, direction, amount_minor, currency_code
    ) VALUES (
      v_journal_id,
      p_tenant_id,
      v_item->>'account_code',
      upper(v_item->>'direction'),
      (v_item->>'amount_minor')::BIGINT,
      COALESCE(v_item->>'currency_code', p_currency_code)
    );
  END LOOP;

  IF NOT public.verify_internal_ledger_journal_balance(v_journal_id) THEN
    RAISE EXCEPTION 'journal is not balanced'
      USING ERRCODE = '23514';
  END IF;

  RETURN v_journal_id;
END;
$$;

REVOKE ALL ON TABLE public.internal_ledger_journals FROM PUBLIC;
REVOKE ALL ON TABLE public.internal_ledger_postings FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enforce_internal_ledger_posting_context() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.verify_internal_ledger_journal_balance(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_internal_ledger_journal(UUID, TEXT, TEXT, TEXT, JSONB, TEXT) FROM PUBLIC;
